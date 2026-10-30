import { ThemeColors } from '../common/Theme';
import { STORAGE_KEY_TASBIH_STATE_VERSION } from '../common/StorageKeys';
import { TasbihStorage } from '../tasbih/TasbihStorage';
import { TasbihManager } from '../tasbih/TasbihManager';
import { Tasbih } from '../tasbih/TasbihModels';
import { common } from '@kit.AbilityKit';

@Component
export struct TasbihIndicator {
  @Prop colors: ThemeColors;
  @Prop prayerId: string;
  @Prop currentLanguage: string = 'en';
  @StorageLink(STORAGE_KEY_TASBIH_STATE_VERSION)
  @Watch('loadData')
  version: number = 0;
  @State private count: number = 0;
  @State private firstTasbihId: string = '';
  @State private firstPendingDhikrIndex: number = 0;

  aboutToAppear(): void {
    this.loadData();
  }

  async loadData(): Promise<void> {
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      await TasbihStorage.init(ctx);
      const loaded = await TasbihStorage.load(TasbihManager.createDefaults());

      const bound = loaded.tasbihs.filter((t: Tasbih) =>
      t.boundPrayerIds?.includes(this.prayerId)
      );

      this.count = bound.length;

      if (this.count > 0) {
        // Pick the first Tasbih to determine navigation target
        const t = bound[0];
        this.firstTasbihId = t.id;

        // Find the first incomplete dhikr
        const pendingIdx = t.dhikrs.findIndex(d => (d.dailyTotal ?? d.count) < d.target);
        this.firstPendingDhikrIndex = pendingIdx >= 0 ? pendingIdx : 0;
      }
    } catch (e) {
      this.count = 0;
    }
  }

  build() {
    if (this.count > 0) {
      Row({ space: 4 }) {
        Image($r('app.media.ic_nav_tasbih')).width(12).height(12).fillColor(this.colors.accentGold).flexShrink(0)
        Text(`${this.count}`)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.accentGold)
      }
      .padding({
        left: 8,
        right: 8,
        top: 4,
        bottom: 4
      })
      .backgroundColor(this.colors.tintSoft)
      .borderRadius(12)
      .border({ width: 1, color: this.colors.borderSoft })
      .onClick(() => {
        // Navigate to the Tasbih Tab and pass the target context
        AppStorage.setOrCreate('nav_target_tasbih', this.firstTasbihId);
        AppStorage.setOrCreate('nav_target_dhikr', this.firstPendingDhikrIndex);
        AppStorage.setOrCreate('nav_target_prayer', this.prayerId);
        AppStorage.setOrCreate('nav_target_tab', 'tasbih');
      })
    }
  }
}