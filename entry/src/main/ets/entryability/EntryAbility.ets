// entry/src/main/ets/entryability/EntryAbility.ets

import { UIAbility, AbilityConstant, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { PreferencesHelper } from '../helper/PreferencesHelper';
import {
  STORAGE_KEY_THEME_MODE,
  STORAGE_KEY_HIJRI_OFFSET,
  STORAGE_KEY_LANGUAGE,
  STORAGE_KEY_WIZARD_COMPLETED,
  STORAGE_KEY_VIBRATION_ENABLED,
  STORAGE_KEY_APP_FOREGROUND_TICK
} from '../common/StorageKeys';
import { ThemeMode } from '../common/Theme';
import { AppLogger } from '../helper/AppLogger';
import { PrayerManager } from '../utils/PrayerManager';

/** How long the splash stays visible, in milliseconds. */
const SPLASH_DELAY_MS = 1500;

export default class EntryAbility extends UIAbility {

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'Sirat', '%{public}s', 'EntryAbility onCreate');

    // Pre-create the foreground tick so @StorageLink + @Watch
    // subscribers reliably receive updates from onForeground().
    AppStorage.setOrCreate(STORAGE_KEY_APP_FOREGROUND_TICK, 0);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    AppLogger.init(this.context);

    PreferencesHelper.init(this.context).then(async () => {
      const savedMode = await PreferencesHelper.getString(
        STORAGE_KEY_THEME_MODE, ThemeMode.SYSTEM
      );
      AppStorage.setOrCreate(STORAGE_KEY_THEME_MODE, savedMode);

      const savedHijriOffset = await PreferencesHelper.getNumber(
        STORAGE_KEY_HIJRI_OFFSET, 0
      );
      AppStorage.setOrCreate(STORAGE_KEY_HIJRI_OFFSET, savedHijriOffset);

      const savedLanguage = await PreferencesHelper.getString(
        STORAGE_KEY_LANGUAGE, 'en'
      );
      AppStorage.setOrCreate(STORAGE_KEY_LANGUAGE, savedLanguage);

      const vibrationEnabled = await PreferencesHelper.getBoolean(
        STORAGE_KEY_VIBRATION_ENABLED, true
      );
      AppStorage.setOrCreate(STORAGE_KEY_VIBRATION_ENABLED, vibrationEnabled);

      // Load the persisted prayer-state map into memory so every
      // subsequent read/write is synchronous.
      await PrayerManager.primeStateMap();

      const wizardDone = await PreferencesHelper.getBoolean(
        STORAGE_KEY_WIZARD_COMPLETED, false
      );
      const startPage = wizardDone ? 'pages/HomePage' : 'pages/WizardPage';

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

  onForeground(): void {
    const prev = AppStorage.get<number>(STORAGE_KEY_APP_FOREGROUND_TICK);
    const next = (prev === undefined ? 0 : prev) + 1;
    AppStorage.set(STORAGE_KEY_APP_FOREGROUND_TICK, next);
    hilog.info(0x0000, 'Sirat', 'onForeground tick=%{public}d', next);
  }
}