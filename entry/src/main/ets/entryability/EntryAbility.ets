// entry/src/main/ets/entryability/EntryAbility.ets

import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { PreferencesHelper } from '../helper/PreferencesHelper';
import { ClockFormat } from '../common/ClockFormat';
import {
  STORAGE_KEY_APP_FOREGROUND_TICK,
  STORAGE_KEY_APP_THEME,
  STORAGE_KEY_HIJRI_CALENDAR_TYPE,
  STORAGE_KEY_HIJRI_OFFSET,
  STORAGE_KEY_LANGUAGE,
  STORAGE_KEY_SOUND_ENABLED,
  STORAGE_KEY_TASBIH_SOUND,
  STORAGE_KEY_THEME_MODE,
  STORAGE_KEY_TIME_FORMAT,
  STORAGE_KEY_VIBRATION_ENABLED,
  STORAGE_KEY_WIZARD_COMPLETED
} from '../common/StorageKeys';
import { SoundHelper } from '../helper/SoundHelper';
import { SoundOptions } from '../common/SoundOptions';
import { SystemFeedbackHelper } from '../helper/SystemFeedbackHelper';
import { ThemeMode, ThemePreset } from '../common/Theme';
import { AppLogger } from '../helper/AppLogger';
import { PrayerManager } from '../utils/PrayerManager';
import { LayoutHelper } from '../helper/LayoutHelper';
import { MaterialHelper } from '../helper/MaterialHelper';
import { SettingsHelper } from '../helper/SettingsHelper';
import { NotificationHelper } from '../helper/NotificationHelper';
import { CalendarReminderHelper } from '../helper/CalendarReminderHelper';
import { CALENDAR_REMINDERS_ENABLED } from '../common/FeatureFlags';
import { HijriCalendarType } from '../common/HijriCalendarType';

/** How long the splash stays visible, in milliseconds. */
const SPLASH_DELAY_MS = 1500;

export default class EntryAbility extends UIAbility {
  // ============================================================
  // LIFECYCLE — onCreate
  // ============================================================

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'Sirat', '%{public}s', 'EntryAbility onCreate');

    // Pre-create the foreground tick so @StorageLink + @Watch
    // subscribers reliably receive updates from onForeground().
    AppStorage.setOrCreate(STORAGE_KEY_APP_FOREGROUND_TICK, 0);
  }

  // ============================================================
  // LIFECYCLE — onWindowStageCreate
  // ============================================================

  onWindowStageCreate(windowStage: window.WindowStage): void {
    AppLogger.init(this.context);
    LayoutHelper.install();

    PreferencesHelper.init(this.context).then(async () => {
      // ---- Load persisted preferences into AppStorage ----
      const savedMode = await PreferencesHelper.getString(
        STORAGE_KEY_THEME_MODE, ThemeMode.SYSTEM
      );
      AppStorage.setOrCreate(STORAGE_KEY_THEME_MODE, savedMode);

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

      const savedLanguage = await PreferencesHelper.getString(
        STORAGE_KEY_LANGUAGE, 'en'
      );
      AppStorage.setOrCreate(STORAGE_KEY_LANGUAGE, savedLanguage);

      const vibrationEnabled = await PreferencesHelper.getBoolean(
        STORAGE_KEY_VIBRATION_ENABLED, true
      );
      AppStorage.setOrCreate(STORAGE_KEY_VIBRATION_ENABLED, vibrationEnabled);

      // ---- Time format ----
      const savedTimeFormat = await PreferencesHelper.getString(
        STORAGE_KEY_TIME_FORMAT, ClockFormat.SYSTEM
      );
      AppStorage.setOrCreate(STORAGE_KEY_TIME_FORMAT, savedTimeFormat);

      // ---- Log material capability once per session ----
      MaterialHelper.logCapability();

      // ---- Load the persisted prayer-state map into memory so every
      //      subsequent read/write is synchronous ----
      await PrayerManager.primeStateMap();

      // ---- Read system sound & haptics state, start listening for
      //      changes ----
      SystemFeedbackHelper.init(this.context);

      // ---- Decide the start page ----
      const wizardDone = await PreferencesHelper.getBoolean(
        STORAGE_KEY_WIZARD_COMPLETED, false
      );
      const startPage = wizardDone ? 'pages/MainTabs' : 'pages/WizardPage';

      // ---- Tasbih sound player (non-blocking) ----
      SoundHelper.init(this.context).catch((e: Error) => {
        AppLogger.warn(
          'EntryAbility', `SoundHelper init failed: ${e.message}`
        );
      });

      // ---- Calendar reminder backend (non-blocking) ----
      // Only initialised when CALENDAR_REMINDERS_ENABLED is true. The
      // helper requests its two permissions on first use and creates
      // the app's calendar account. Failing here is non-fatal — the
      // user will simply not have reminders until permissions are
      // granted from Settings.
      if (CALENDAR_REMINDERS_ENABLED) {
        CalendarReminderHelper.init(this.context).catch((e: Error) => {
          AppLogger.warn('EntryAbility',
            `CalendarReminderHelper init failed: ${e.message}`);
        });
      }

      // ---- Renew the prayer-reminder window on app start ----
      // Fire-and-forget. The method swallows its own errors, so the
      // trailing .catch() is a safety net only.
      this.renewRemindersOnStart().catch(() => {
        // Never reached — renewRemindersOnStart never throws.
      });

      // ---- Show splash, then load the start page ----
      setTimeout(() => {
        windowStage.loadContent(startPage, (err) => {
          if (err.code) {
            hilog.error(0x0000, 'Sirat',
              'Failed to load content: %{public}s', JSON.stringify(err));
            return;
          }
          hilog.info(0x0000, 'Sirat', 'Loaded %{public}s', startPage);
        });
      }, SPLASH_DELAY_MS);
    }).catch((err: Error) => {
      AppLogger.error('EntryAbility', `init failed: ${err.message}`);
      windowStage.loadContent('pages/HomePage');
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

    hilog.info(0x0000, 'Sirat', 'onForeground tick=%{public}d', next);
  }

  // ============================================================
  // REMINDER RENEWAL
  // ============================================================

  /**
   * Renew the prayer-reminder window on app start.
   *
   * Rescheduling cancels existing reminders and re-creates them for
   * the next 3 days from the current settings, location, and
   * calculation parameters. Runs only when the user has the master
   * toggle enabled.
   *
   * Never throws — any failure is logged and swallowed so that a
   * broken calendar or notification service cannot block startup.
   */
  private async renewRemindersOnStart(): Promise<void> {
    try {
      const ns = await SettingsHelper.getNotificationSettings();
      if (!ns.masterEnabled) {
        AppLogger.info('EntryAbility',
          'Reminder renewal skipped — master toggle off');
        return;
      }
      await NotificationHelper.rescheduleAll();
      AppLogger.info('EntryAbility', 'Reminder renewal complete');
    } catch (e) {
      const err = e as Error;
      AppLogger.warn('EntryAbility',
        `Reminder reschedule on start failed: ${err.message}`);
    }
  }
}