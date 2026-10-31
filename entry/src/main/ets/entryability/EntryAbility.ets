// entry/src/main/ets/entryability/EntryAbility.ets

import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { Configuration } from '@ohos.app.ability.Configuration'; // Direct import fixes fontScale error
import { window } from '@kit.ArkUI';
import { CustomEventStorage } from '../helper/CustomEventStorage';
import { CustomEventNotifier } from '../helper/CustomEventNotifier';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { PreferencesHelper } from '../helper/PreferencesHelper';
import { AppLogger } from '../helper/AppLogger';
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
} from '../common/StorageKeys';
import { SoundHelper } from '../helper/SoundHelper';
import { SoundOptions } from '../common/SoundOptions';
import { SystemFeedbackHelper } from '../helper/SystemFeedbackHelper';
import { ThemeMode, ThemePreset } from '../common/Theme';
import { PrayerManager } from '../prayer/PrayerManager';
import { LayoutHelper } from '../helper/LayoutHelper';
import { MaterialHelper } from '../helper/MaterialHelper';
import { SettingsHelper } from '../helper/SettingsHelper';
import { NotificationHelper } from '../helper/NotificationHelper';
import { CalendarReminderHelper } from '../hijricalendar/CalendarReminderHelper';
import { CALENDAR_REMINDERS_ENABLED } from '../common/FeatureFlags';
import { ClockFormat } from '../common/ClockFormat';
import { HijriCalendarType } from '../hijricalendar/HijriCalendarType';
import { LocationCache } from '../utils/LocationCache';
import { TypographyHelper } from '../helper/TypographyHelper';
import { PageTheme } from '../common/PageTheme';

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

  // ============================================================
  // LIFECYCLE — onCreate
  // ============================================================

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'Sirat', '%{public}s', 'EntryAbility onCreate');

    // Pre-create AppStorage keys that pages bind to via
    // @StorageLink + @Watch. If a key does not exist when the
    // first subscriber attaches, its initial value can be created
    // without firing a change notification on some SDK builds.
    // Seeding them here guarantees a stable value from the start.
    AppStorage.setOrCreate(STORAGE_KEY_APP_FOREGROUND_TICK, 0);
    AppStorage.setOrCreate(STORAGE_KEY_EVENT_SETTINGS_VERSION, 0);
    AppStorage.setOrCreate(STORAGE_KEY_CALC_SETTINGS_VERSION, 0);
    AppStorage.setOrCreate(STORAGE_KEY_RAMADAN_STATE_VERSION, 0);
  }

  // ============================================================
  // LIFECYCLE — onWindowStageCreate
  // ============================================================

  onWindowStageCreate(windowStage: window.WindowStage): void {
    AppLogger.init(this.context);
    L.init(this.context);
    LayoutHelper.install();
    TypographyHelper.init();

    PreferencesHelper.init(this.context).then(async () => {
      // ========================================================
      // LOAD PERSISTED PREFERENCES INTO APPSTORAGE
      // ========================================================

      // ---- Theme Override ----
      let savedThemeOverride = await PreferencesHelper.getString(
        STORAGE_KEY_THEME_OVERRIDE, ''
      );
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
            hilog.error(0x0000, 'Sirat',
              'Failed to load content: %{public}s', JSON.stringify(err));
            return;
          }
          hilog.info(0x0000, 'Sirat', 'Loaded %{public}s', startPage);

          // Resize AFTER the initial page has painted. Doing this
          // here (instead of at the top of onWindowStageCreate)
          // prevents the routerSplit evaluator from seeing a wide
          // window with a pending navigation event — which on some
          // 2-in-1 hardware briefly shows a split view with an
          // empty secondary pane before MainTabs renders.
          this.resizeWindowFor2in1(windowStage);
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
  }

  // ============================================================
  // LIFECYCLE — onForeground
  // ============================================================

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
  // LIFECYCLE — onBackground
  // ============================================================

  onBackground(): void {
    // Flush any pending debounced preference write before the
    // process is suspended. Fire-and-forget.
    PreferencesHelper.flushNow().catch((err: Error) => {
      AppLogger.warn('EntryAbility', `Flush on background failed: ${err.message}`);
    });
  }

  // ============================================================
  // CONFIGURATION UPDATE (OS Language Change)
  // ============================================================

  onConfigurationUpdate(newConfig: Configuration): void {
    AppLogger.info('EntryAbility', 'onConfigurationUpdate fired');
    this.reResolveSystemLanguage();
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