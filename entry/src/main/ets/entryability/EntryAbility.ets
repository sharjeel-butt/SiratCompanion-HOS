// entry/src/main/ets/entryability/EntryAbility.ets

import { UIAbility, AbilityConstant, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { PreferencesHelper } from '../utils/PreferencesHelper';
import { STORAGE_KEY_THEME_MODE } from '../common/StorageKeys';
import { ThemeMode } from '../common/Theme';

export default class EntryAbility extends UIAbility {

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'Sirat', '%{public}s', 'EntryAbility onCreate');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Initialize the preferences store and load the persisted theme mode
    // BEFORE loading the UI — this avoids a flash of the wrong theme.
    PreferencesHelper.init(this.context).then(async () => {
      const savedMode = await PreferencesHelper.getString(STORAGE_KEY_THEME_MODE, ThemeMode.SYSTEM);
      AppStorage.setOrCreate(STORAGE_KEY_THEME_MODE, savedMode);

      windowStage.loadContent('pages/Index', (err) => {
        if (err.code) {
          hilog.error(0x0000, 'Sirat', 'Failed to load content: %{public}s', JSON.stringify(err));
          return;
        }
        hilog.info(0x0000, 'Sirat', '%{public}s', 'UI loaded');
      });
    });
  }
}