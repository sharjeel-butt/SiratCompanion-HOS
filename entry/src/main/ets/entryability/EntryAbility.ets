// entry/src/main/ets/entryability/EntryAbility.ets

import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { Configuration } from '@ohos.app.ability.Configuration'; // Direct import fixes fontScale error
import { router, window } from '@kit.ArkUI';
import { CustomEventStorage } from '../hijricalendar/CustomEventStorage';
import { CustomEventNotifier } from '../hijricalendar/CustomEventNotifier';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { PreferencesHelper } from '../core/PreferencesHelper';
import { AppLogger } from '../core/AppLogger';
import { AppLanguage, L } from '../i18n/LocalizationHelper';
import {
  STORAGE_KEY_APP_FOREGROUND_TICK,
  STORAGE_KEY_APP_THEME,
  STORAGE_KEY_AUTO_SHOW_RAMADAN_VIEW,
  STORAGE_KEY_CALC_SETTINGS_VERSION,
  STORAGE_KEY_EVENT_PERSPECTIVE,
  STORAGE_KEY_EVENT_SETTINGS_VERSION,
  STORAGE_KEY_HIJRI_CALENDAR_TYPE,
  STORAGE_KEY_HIJRI_OFFSET,
  STORAGE_KEY_LANGUAGE,
  STORAGE_KEY_LANGUAGE_OVERRIDE,
  STORAGE_KEY_RAMADAN_STATE_VERSION,
  STORAGE_KEY_SHOW_EXTRA_TIMINGS,
  STORAGE_KEY_SHOW_FIRST_THIRD,
  STORAGE_KEY_SHOW_FIRST_THIRD_LIST,
  STORAGE_KEY_SHOW_FIRST_THIRD_SUNPATH,
  STORAGE_KEY_SHOW_IMSAK,
  STORAGE_KEY_SHOW_IMSAK_LIST,
  STORAGE_KEY_SHOW_IMSAK_SUNPATH,
  STORAGE_KEY_SHOW_ISLAMIC_EVENTS,
  STORAGE_KEY_SHOW_LAST_THIRD,
  STORAGE_KEY_SHOW_LAST_THIRD_LIST,
  STORAGE_KEY_SHOW_LAST_THIRD_SUNPATH,
  STORAGE_KEY_SHOW_MIDNIGHT,
  STORAGE_KEY_SHOW_MIDNIGHT_LIST,
  STORAGE_KEY_SHOW_MIDNIGHT_SUNPATH,
  STORAGE_KEY_SOUND_ENABLED,
  STORAGE_KEY_TASBIH_SOUND,
  STORAGE_KEY_THEME_MODE,
  STORAGE_KEY_THEME_OVERRIDE,
  STORAGE_KEY_TIME_FORMAT,
  STORAGE_KEY_VIBRATION_ENABLED,
  STORAGE_KEY_WIZARD_COMPLETED
} from '../core/StorageKeys';
import { SoundHelper } from '../tasbih/SoundHelper';
import { SoundOptions } from '../tasbih/SoundOptions';
import { SystemFeedbackHelper } from '../core/SystemFeedbackHelper';
import { ThemeMode, ThemePreset } from '../core/Theme';
import { PrayerManager } from '../prayer/PrayerManager';
import { LayoutHelper } from '../core/LayoutHelper';
import { MaterialHelper } from '../core/MaterialHelper';
import { SettingsHelper } from '../settings/SettingsHelper';
import { NotificationHelper } from '../prayer/NotificationHelper';
import { CalendarReminderHelper } from '../hijricalendar/CalendarReminderHelper';
import { CALENDAR_REMINDERS_ENABLED } from '../core/FeatureFlags';
import { ClockFormat } from '../core/ClockFormat';
import { HijriCalendarType } from '../hijricalendar/HijriCalendarType';
import { LocationCache } from '../location/LocationCache';
import { TypographyHelper } from '../core/TypographyHelper';
import { PageTheme } from '../core/PageTheme';
import { PrivacyPolicyProvider } from '../legal/PrivacyPolicy';
import { WidgetHelper } from '../widgets/WidgetHelper';
import { OfflineCityLookup } from '../location/OfflineCityLookup';
import { IslamicEventService } from '../hijricalendar/IslamicEventService';

/** How long the splash stays visible, in milliseconds. */
const SPLASH_DELAY_MS = 1500;

/** Shorter splash on 2-in-1 — desktop users expect near-instant launch. */
const SPLASH_DELAY_2IN1_MS = 400;

/** Preferred starting window size on 2-in-1 devices, in vp. */
const PREFERRED_WINDOW_WIDTH_2IN1 = 800;
const PREFERRED_WINDOW_HEIGHT_2IN1 = 1100;


/**
 * AppStorage key for the last-known device timezone offset. Not a
 * persisted preference — it lives in memory only, so it is cleared
 * when the process restarts. When the current offset differs from
 * this, the location cache is invalidated.
 */
const APP_STORAGE_LAST_TZ_OFFSET = 'last_device_tz_offset';

export default class EntryAbility extends UIAbility {
  /**
   * Whitelist of pages that widgets may deep-link into via
   * targetPage. Anything else is ignored with a warning — this
   * prevents a misconfigured postCardAction from opening an
   * unexpected page in a cold-start context, where the router stack
   * is empty and there is no back button to escape.
   *
   * Extend this list when a new widget needs a new destination.
   */
  private static readonly WIDGET_TARGET_PAGES: string[] = [
    'pages/RamadanDetailsPage',
    'pages/QuranPage',
    'pages/SurahDetailsPage',
    'pages/DuasPage',
    'pages/PrayerProgressPage',
    'pages/TasbihProgressPage',
    'pages/SettingsPage',
    'pages/CustomizePage',
    'pages/AdvancedCalcPage',
    'pages/RecitationsPage',
    'pages/LicensesPage'
  ];

  // ============================================================
  // LIFECYCLE — onCreate
  // ============================================================

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'Sirat', '%{public}s', 'EntryAbility onCreate');

    AppStorage.setOrCreate(STORAGE_KEY_APP_FOREGROUND_TICK, 0);
    AppStorage.setOrCreate(STORAGE_KEY_EVENT_SETTINGS_VERSION, 0);
    AppStorage.setOrCreate(STORAGE_KEY_CALC_SETTINGS_VERSION, 0);
    AppStorage.setOrCreate(STORAGE_KEY_RAMADAN_STATE_VERSION, 0);

    // NEW: handle widget click navigation (cold start)
    this.handleWidgetNavWant(want);
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    AppLogger.info('EntryAbility', 'onNewWant fired');
    this.handleWidgetNavWant(want);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    AppLogger.init(this.context);
    L.init(this.context);
    LayoutHelper.install();
    TypographyHelper.init();

    OfflineCityLookup.init(this.context).then(() => {
      PreferencesHelper.init(this.context).then(async () => {
        // ========================================================
        // LOAD PERSISTED PREFERENCES INTO APPSTORAGE
        // ========================================================

        // ---- Theme Override ----
        let savedThemeOverride = await PreferencesHelper.getString(
          STORAGE_KEY_THEME_OVERRIDE, ''
        );
        await IslamicEventService.init(this.context);
        if (savedThemeOverride.length === 0) {
          // Migrate from previous versions (which only had THEME_MODE)
          const legacyTheme = await PreferencesHelper.getString(
            STORAGE_KEY_THEME_MODE, ThemeMode.SYSTEM
          );
          savedThemeOverride = legacyTheme;
          PreferencesHelper.setString(STORAGE_KEY_THEME_OVERRIDE, savedThemeOverride);
          AppLogger.info('EntryAbility', `Theme override migrated → '${savedThemeOverride}'`);
        }

        AppStorage.setOrCreate(STORAGE_KEY_THEME_OVERRIDE, savedThemeOverride);
        AppStorage.setOrCreate(STORAGE_KEY_THEME_MODE, savedThemeOverride);
        PageTheme.applyColorMode(savedThemeOverride, this.context);

        // ---- Language Override ----
        let savedOverride = await PreferencesHelper.getString(
          STORAGE_KEY_LANGUAGE_OVERRIDE, ''
        );
        if (savedOverride.length === 0) {
          const legacyLang = await PreferencesHelper.getString(
            STORAGE_KEY_LANGUAGE, ''
          );
          if (legacyLang.length > 0 && legacyLang !== AppLanguage.SYSTEM) {
            savedOverride = legacyLang;
          } else {
            savedOverride = AppLanguage.SYSTEM;
          }
          PreferencesHelper.setString(STORAGE_KEY_LANGUAGE_OVERRIDE, savedOverride);
          AppLogger.info('EntryAbility', `Language override migrated → '${savedOverride}'`);
        }

        const resolvedLanguage = L.resolveOverride(savedOverride);
        AppStorage.setOrCreate(STORAGE_KEY_LANGUAGE_OVERRIDE, savedOverride);
        AppStorage.setOrCreate(STORAGE_KEY_LANGUAGE, resolvedLanguage);
        PreferencesHelper.setString(STORAGE_KEY_LANGUAGE, resolvedLanguage);
        L.applySystemLanguage(savedOverride);
        PrivacyPolicyProvider.preload(this.context, resolvedLanguage);

        // ---- Other Preferences ----
        const tasbihSound = await PreferencesHelper.getString(
          STORAGE_KEY_TASBIH_SOUND, SoundOptions.DEFAULT_ID
        );
        AppStorage.setOrCreate(STORAGE_KEY_TASBIH_SOUND, tasbihSound);

        const soundEnabled = await PreferencesHelper.getBoolean(
          STORAGE_KEY_SOUND_ENABLED, true
        );
        AppStorage.setOrCreate(STORAGE_KEY_SOUND_ENABLED, soundEnabled);

        const savedAppTheme = await PreferencesHelper.getString(
          STORAGE_KEY_APP_THEME, ThemePreset.SIRAT
        );
        AppStorage.setOrCreate(STORAGE_KEY_APP_THEME, savedAppTheme);

        const savedHijriOffset = await PreferencesHelper.getNumber(
          STORAGE_KEY_HIJRI_OFFSET, 0
        );
        AppStorage.setOrCreate(STORAGE_KEY_HIJRI_OFFSET, savedHijriOffset);

        const savedHijriCalendarType = await PreferencesHelper.getString(
          STORAGE_KEY_HIJRI_CALENDAR_TYPE, HijriCalendarType.UMM_AL_QURA
        );
        AppStorage.setOrCreate(
          STORAGE_KEY_HIJRI_CALENDAR_TYPE, savedHijriCalendarType
        );

        const savedShowIslamicEvents = await PreferencesHelper.getBoolean(
          STORAGE_KEY_SHOW_ISLAMIC_EVENTS, true
        );
        AppStorage.setOrCreate(
          STORAGE_KEY_SHOW_ISLAMIC_EVENTS, savedShowIslamicEvents
        );

        const savedAutoShowRamadanView = await PreferencesHelper.getBoolean(
          STORAGE_KEY_AUTO_SHOW_RAMADAN_VIEW, true
        );
        AppStorage.setOrCreate(STORAGE_KEY_AUTO_SHOW_RAMADAN_VIEW, savedAutoShowRamadanView);

        // ---- Event perspective ----
        const savedEventPerspective = await PreferencesHelper.getString(
          STORAGE_KEY_EVENT_PERSPECTIVE, 'universal'
        );
        AppStorage.setOrCreate(
          STORAGE_KEY_EVENT_PERSPECTIVE, savedEventPerspective
        );

        const vibrationEnabled = await PreferencesHelper.getBoolean(
          STORAGE_KEY_VIBRATION_ENABLED, true
        );
        AppStorage.setOrCreate(STORAGE_KEY_VIBRATION_ENABLED, vibrationEnabled);

        const savedTimeFormat = await PreferencesHelper.getString(
          STORAGE_KEY_TIME_FORMAT, ClockFormat.SYSTEM
        );
        AppStorage.setOrCreate(STORAGE_KEY_TIME_FORMAT, savedTimeFormat);

        const savedQuranScript = await PreferencesHelper.getString(
          'active_quran_script', 'indopak'
        );
        AppStorage.setOrCreate('active_quran_script', savedQuranScript);

        // ========================================================
        // PER-TIMING VISIBILITY — MIGRATION
        // ========================================================
        const legacyGroup = await PreferencesHelper.getBoolean(
          STORAGE_KEY_SHOW_EXTRA_TIMINGS, true
        );

        const legacyImsak = await PreferencesHelper.getBoolean(
          STORAGE_KEY_SHOW_IMSAK, legacyGroup
        );
        const legacyFirstThird = await PreferencesHelper.getBoolean(
          STORAGE_KEY_SHOW_FIRST_THIRD, legacyGroup
        );
        const legacyMidnight = await PreferencesHelper.getBoolean(
          STORAGE_KEY_SHOW_MIDNIGHT, legacyGroup
        );
        const legacyLastThird = await PreferencesHelper.getBoolean(
          STORAGE_KEY_SHOW_LAST_THIRD, legacyGroup
        );

        AppStorage.setOrCreate(
          STORAGE_KEY_SHOW_IMSAK_LIST,
          await PreferencesHelper.getBoolean(STORAGE_KEY_SHOW_IMSAK_LIST, legacyImsak)
        );
        AppStorage.setOrCreate(
          STORAGE_KEY_SHOW_IMSAK_SUNPATH,
          await PreferencesHelper.getBoolean(STORAGE_KEY_SHOW_IMSAK_SUNPATH, legacyImsak)
        );

        AppStorage.setOrCreate(
          STORAGE_KEY_SHOW_FIRST_THIRD_LIST,
          await PreferencesHelper.getBoolean(STORAGE_KEY_SHOW_FIRST_THIRD_LIST, legacyFirstThird)
        );
        AppStorage.setOrCreate(
          STORAGE_KEY_SHOW_FIRST_THIRD_SUNPATH,
          await PreferencesHelper.getBoolean(STORAGE_KEY_SHOW_FIRST_THIRD_SUNPATH, legacyFirstThird)
        );

        AppStorage.setOrCreate(
          STORAGE_KEY_SHOW_MIDNIGHT_LIST,
          await PreferencesHelper.getBoolean(STORAGE_KEY_SHOW_MIDNIGHT_LIST, legacyMidnight)
        );
        AppStorage.setOrCreate(
          STORAGE_KEY_SHOW_MIDNIGHT_SUNPATH,
          await PreferencesHelper.getBoolean(STORAGE_KEY_SHOW_MIDNIGHT_SUNPATH, legacyMidnight)
        );

        AppStorage.setOrCreate(
          STORAGE_KEY_SHOW_LAST_THIRD_LIST,
          await PreferencesHelper.getBoolean(STORAGE_KEY_SHOW_LAST_THIRD_LIST, legacyLastThird)
        );
        AppStorage.setOrCreate(
          STORAGE_KEY_SHOW_LAST_THIRD_SUNPATH,
          await PreferencesHelper.getBoolean(STORAGE_KEY_SHOW_LAST_THIRD_SUNPATH, legacyLastThird)
        );

        // ========================================================
        // REMAINING STARTUP
        // ========================================================

        MaterialHelper.logCapability();

        try {
          const deviceOffset = -new Date().getTimezoneOffset() / 60;
          const tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
          AppLogger.info('EntryAbility',
            `Device timezone = ${tz}, offset = ${deviceOffset} h`);
        } catch (err) {
          AppLogger.info('EntryAbility', 'Device timezone lookup failed');
        }

        await PrayerManager.primeStateMap();
        SystemFeedbackHelper.init(this.context);

        // ---- Decide the start page ----
        const wizardDone = await PreferencesHelper.getBoolean(
          STORAGE_KEY_WIZARD_COMPLETED, false
        );
        const startPage = wizardDone ? 'pages/MainTabs' : 'pages/WizardPage';

        // ---- Tasbih sound player (non-blocking) ----
        SoundHelper.init(this.context).catch((e: Error) => {
          AppLogger.warn('EntryAbility', `SoundHelper init failed: ${e.message}`);
        });

        // ---- Calendar reminder backend (silent check on startup) ----
        if (CALENDAR_REMINDERS_ENABLED) {
          CalendarReminderHelper.init(this.context, false).catch((e: Error) => {
            AppLogger.warn('EntryAbility', `CalendarReminderHelper init failed: ${e.message}`);
          });
        }

        // ---- Renew the prayer-reminder window on app start ----
        this.renewRemindersOnStart().catch(() => {
          // Never reached — renewRemindersOnStart never throws.
        });

        // ---- Show splash, then load the start page ----
        const splashMs = deviceInfo.deviceType === '2in1'
          ? SPLASH_DELAY_2IN1_MS
          : SPLASH_DELAY_MS;

        setTimeout(() => {
          windowStage.loadContent(startPage, (err) => {
            if (err.code) {
              hilog.error(0x0000, 'Sirat', 'Failed to load content: %{public}s', JSON.stringify(err));
              return;
            }
            hilog.info(0x0000, 'Sirat', 'Loaded %{public}s', startPage);
            this.installSplitModeListener(windowStage);

            this.resizeWindowFor2in1(windowStage);

            // --- ADD THIS BLOCK ---
            const targetPage = AppStorage.get<string>('nav_target_page');
            if (targetPage && targetPage.length > 0) {
              if (targetPage === 'pages/RamadanDetailsPage') {
                router.pushUrl({ url: targetPage }).catch((e: Error) => {
                  AppLogger.warn('EntryAbility', `Cold start page nav failed: ${e.message}`);
                });
              }
              AppStorage.setOrCreate('nav_target_page', '');
            }
            // ----------------------
          });
        }, splashMs);
      }).catch((err: Error) => {
        AppLogger.error('EntryAbility', `init failed: ${err.message}`);
        windowStage.loadContent('pages/MainTabs', () => {
          // Fallback load — apply the 2-in-1 resize on the same
          // post-paint schedule as the primary path.
          this.resizeWindowFor2in1(windowStage);
        });
      });
    }).catch((err: Error) => {
      // Fallback if OfflineCityLookup fails (though its internal try/catch should prevent this)
      AppLogger.error('EntryAbility', `OfflineCityLookup init failed: ${err.message}`);
      windowStage.loadContent('pages/MainTabs', () => {
        this.resizeWindowFor2in1(windowStage);
      });
    });
  }

  /**
   * Track whether the current window is in a split arrangement and
   * mirror that into LayoutHelper so pages can consult it.
   *
   * Called once after loadContent succeeds. Queries the initial
   * window status and subscribes to future status changes. Non-fatal
   * — a failure here only means pages cannot distinguish split from
   * full-screen, which is the current (pre-fix) behaviour.
   */
  private installSplitModeListener(windowStage: window.WindowStage): void {
    windowStage.getMainWindow()
      .then((win: window.Window) => {
        // Initial state.
        try {
          const status: window.WindowStatusType = win.getWindowStatus();
          LayoutHelper.setSplitMode(status === window.WindowStatusType.SPLIT_SCREEN);
        } catch (e) {
          // getWindowStatus unavailable on some SDK builds — fall
          // through to the change listener below.
        }

        // Future changes.
        try {
          win.on('windowStatusChange', (status: window.WindowStatusType) => {
            LayoutHelper.setSplitMode(status === window.WindowStatusType.SPLIT_SCREEN);
          });
        } catch (e) {
          AppLogger.warn('EntryAbility',
            `windowStatusChange listener failed: ${(e as Error).message}`);
        }
      })
      .catch((err: Error) => {
        AppLogger.warn('EntryAbility',
          `installSplitModeListener: getMainWindow failed: ${err.message}`);
      });
  }

  onForeground(): void {
    const prev = AppStorage.get<number>(STORAGE_KEY_APP_FOREGROUND_TICK);
    const next = (prev === undefined ? 0 : prev) + 1;
    AppStorage.set(STORAGE_KEY_APP_FOREGROUND_TICK, next);

    SystemFeedbackHelper.refresh();
    LayoutHelper.install(); // re-install if needed (idempotent)

    this.checkTimezoneChange();
    this.reResolveSystemLanguage();

    hilog.info(0x0000, 'Sirat', 'onForeground tick=%{public}d', next);
  }

  // ============================================================
  // LIFECYCLE — onWindowStageCreate
  // ============================================================

  onBackground(): void {
    PreferencesHelper.flushNow().catch((err: Error) => {
      AppLogger.warn('EntryAbility', `Flush on background failed: ${err.message}`);
    });

    // NEW: push settings changes to any installed widgets
    WidgetHelper.refreshAll().catch((): void => {
      // swallow
    });
  }


  // ============================================================
  // LIFECYCLE — onForeground
  // ============================================================

  onConfigurationUpdate(newConfig: Configuration): void {
    AppLogger.info('EntryAbility', 'onConfigurationUpdate fired');
    this.reResolveSystemLanguage();
  }

  // ============================================================
  // LIFECYCLE — onBackground
  // ============================================================

  private handleWidgetNavWant(want: Want): void {
    const params: Record<string, Object> | undefined = want.parameters;
    if (params === undefined) {
      return;
    }

    let hasTarget = false;
    const pageRaw = params['targetPage'];
    const tabRaw = params['targetTab'];

    if (typeof pageRaw === 'string' && pageRaw.length > 0) {
      if (EntryAbility.WIDGET_TARGET_PAGES.indexOf(pageRaw) !== -1) {
        AppStorage.setOrCreate('widget_target_page', pageRaw);
        hasTarget = true;
      }
    }

    if (typeof tabRaw === 'string' && tabRaw.length > 0) {
      AppStorage.setOrCreate('widget_target_tab', tabRaw);
      hasTarget = true;
    }

    // NEW: Handle deep-linking to a specific Hijri date
    const targetHijriYear = params['targetHijriYear'];
    const targetHijriMonth = params['targetHijriMonth'];
    const targetHijriDay = params['targetHijriDay'];

    if (typeof targetHijriYear === 'number' && targetHijriYear > 0 &&
      typeof targetHijriMonth === 'number' && targetHijriMonth > 0 &&
      typeof targetHijriDay === 'number' && targetHijriDay > 0) {

      // Clear old targets first to ensure @Watch fires
      AppStorage.setOrCreate('nav_target_hijri_year', 0);
      AppStorage.setOrCreate('nav_target_hijri_month', 0);
      AppStorage.setOrCreate('nav_target_hijri_day', 0);

      AppStorage.setOrCreate('nav_target_hijri_year', targetHijriYear);
      AppStorage.setOrCreate('nav_target_hijri_month', targetHijriMonth);
      AppStorage.setOrCreate('nav_target_hijri_day', targetHijriDay);
    }

    if (hasTarget) {
      const currentTop = this.getCurrentPagePath();
      if (currentTop !== 'pages/MainTabs' && currentTop.length > 0) {
        // FIX: router.back() returns void, so we wrap it in try/catch instead of .catch()
        try {
          router.back({ url: 'pages/MainTabs' });
        } catch (e) {
          const err = e as Error;
          AppLogger.warn('EntryAbility', `Widget nav back failed: ${err.message}`);
        }
      }
    }
  }

  // ============================================================
  // CONFIGURATION UPDATE (OS Language Change)
  // ============================================================

  /**
   * Return the current top-of-stack page path, or '' when the router
   * isn't ready (cold start) or the state can't be read.
   */
  private getCurrentPagePath(): string {
    try {
      const stateRaw: Object = router.getState() as Object;
      const stateRec: Record<string, Object> = stateRaw as Record<string, Object>;
      const pathRaw: Object | undefined = stateRec['path'];
      if (typeof pathRaw === 'string') {
        return pathRaw as string;
      }
    } catch (e) {
      // Router not ready (cold start) or getState unavailable
    }
    return '';
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /**
   * If the user picked "Auto Detect" as their language, re-check
   * the device locale every time the app foregrounds or the OS
   * configuration changes.
   */
  private reResolveSystemLanguage(): void {
    const override = AppStorage.get<string>(STORAGE_KEY_LANGUAGE_OVERRIDE);
    if (override !== AppLanguage.SYSTEM) {
      return;
    }
    const current = AppStorage.get<string>(STORAGE_KEY_LANGUAGE);
    const resolved = L.matchSystemLocale();

    if (current !== resolved) {
      AppLogger.info('EntryAbility', `System language changed → '${resolved}'`);
      AppStorage.setOrCreate(STORAGE_KEY_LANGUAGE, resolved);
      PreferencesHelper.setString(STORAGE_KEY_LANGUAGE, resolved);
      L.applySystemLanguage(override);
      NotificationHelper.scheduleRescheduleNow();
    }
  }

  /**
   * Request the preferred 2-in-1 starting window size.
   *
   * Must be called AFTER loadContent has completed. If it runs
   * before, the routerSplit evaluator can see a wide window with
   * a pending navigation and briefly render a split view with an
   * empty secondary pane before MainTabs paints.
   *
   * No-op on phone / tablet / foldable. Failures are non-fatal —
   * the system default window size applies.
   */
  private resizeWindowFor2in1(windowStage: window.WindowStage): void {
    if (deviceInfo.deviceType !== '2in1') {
      return;
    }
    windowStage.getMainWindow()
      .then((win: window.Window) => {
        win.resize(
          PREFERRED_WINDOW_WIDTH_2IN1,
          PREFERRED_WINDOW_HEIGHT_2IN1
        ).catch((err: Error) => {
          AppLogger.info('EntryAbility',
            `Window resize skipped: ${err.message}`);
        });
      })
      .catch((err: Error) => {
        AppLogger.info('EntryAbility',
          `getMainWindow failed: ${err.message}`);
      });
  }

  /**
   * If the device's timezone offset has changed since the last
   * foreground, invalidate the cache so times are recomputed.
   */
  private checkTimezoneChange(): void {
    try {
      const currentOffset = -new Date().getTimezoneOffset() / 60;
      const lastOffset = AppStorage.get<number>(APP_STORAGE_LAST_TZ_OFFSET);

      if (lastOffset !== undefined &&
        Math.abs(lastOffset - currentOffset) > 0.25) {
        AppLogger.info('EntryAbility',
          `Timezone changed ${lastOffset}h → ${currentOffset}h; clearing location cache`);
        LocationCache.clear().catch(() => { /* non-fatal */
        });
      }

      AppStorage.setOrCreate(APP_STORAGE_LAST_TZ_OFFSET, currentOffset);
    } catch (err) {
      // Never let this break foreground handling.
    }
  }

  /**
   * Renew the prayer-reminder window on app start.
   */
  private async renewRemindersOnStart(): Promise<void> {
    try {
      const ns = await SettingsHelper.getNotificationSettings();
      if (!ns.masterEnabled) {
        AppLogger.info('EntryAbility', 'Reminder renewal skipped — master toggle off');
        return;
      }
      await NotificationHelper.rescheduleAll();

      // Custom event reminders were wiped by cancelAll() inside
      // rescheduleAll(). Re-add them now so they survive the launch.
      try {
        const customEvents = await CustomEventStorage.load();
        if (customEvents.length > 0) {
          const hijriOffset = await SettingsHelper.getHijriOffset();
          await CustomEventNotifier.reschedule(customEvents, hijriOffset);
          AppLogger.info('EntryAbility',
            `Rescheduled ${customEvents.length} custom event reminder(s)`);
        }
      } catch (e) {
        AppLogger.warn('EntryAbility',
          `Custom event reschedule failed: ${(e as Error).message}`);
      }

      AppLogger.info('EntryAbility', 'Reminder renewal complete');
    } catch (e) {
      const err = e as Error;
      AppLogger.warn('EntryAbility',
        `Reminder reschedule on start failed: ${err.message}`);
    }
  }
}