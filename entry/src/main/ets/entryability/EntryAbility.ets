// entry/src/main/ets/entryability/EntryAbility.ets

import { UIAbility, AbilityConstant, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { PreferencesHelper } from '../helper/PreferencesHelper';
import {
  STORAGE_KEY_THEME_MODE,
  STORAGE_KEY_HIJRI_OFFSET,
  STORAGE_KEY_LANGUAGE,
  STORAGE_KEY_WIZARD_COMPLETED
} from '../common/StorageKeys';
import { ThemeMode } from '../common/Theme';

/** How long the splash stays visible, in milliseconds. */
const SPLASH_DELAY_MS = 1500;

export default class EntryAbility extends UIAbility {

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'Sirat', '%{public}s', 'EntryAbility onCreate');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Initialize preferences and load persisted values BEFORE the UI
    // loads, so the app opens with the right theme, language, and
    // Hijri offset — no flash of the wrong state.
    PreferencesHelper.init(this.context).then(async () => {
      const savedMode = await PreferencesHelper.getString(STORAGE_KEY_THEME_MODE, ThemeMode.SYSTEM);
      AppStorage.setOrCreate(STORAGE_KEY_THEME_MODE, savedMode);

      const savedHijriOffset = await PreferencesHelper.getNumber(STORAGE_KEY_HIJRI_OFFSET, 0);
      AppStorage.setOrCreate(STORAGE_KEY_HIJRI_OFFSET, savedHijriOffset);

      const savedLanguage = await PreferencesHelper.getString(STORAGE_KEY_LANGUAGE, 'en');
      AppStorage.setOrCreate(STORAGE_KEY_LANGUAGE, savedLanguage);

      const wizardDone = await PreferencesHelper.getBoolean(STORAGE_KEY_WIZARD_COMPLETED, false);
      const startPage = wizardDone ? 'pages/Index' : 'pages/WizardPage';

      // Hold the system splash for a fixed duration so the branding
      // is actually visible rather than flashing past in ~100ms.
      setTimeout(() => {
        windowStage.loadContent(startPage, (err) => {
          if (err.code) {
            hilog.error(0x0000, 'Sirat', 'Failed to load content: %{public}s', JSON.stringify(err));
            return;
          }
          hilog.info(0x0000, 'Sirat', 'Loaded %{public}s', startPage);
        });
      }, SPLASH_DELAY_MS);
    });
  }
}