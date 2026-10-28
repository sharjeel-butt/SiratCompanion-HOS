import { router } from '@kit.ArkUI';
import { ThemeColors } from '../common/Theme';
import { PreferencesHelper } from '../helper/PreferencesHelper';
import { STORAGE_KEY_DUA_BINDINGS_VERSION } from '../common/StorageKeys';
import { L } from '../i8n/LocalizationHelper';

@Component
export struct DuaIndicator {
  @Prop colors: ThemeColors;
  @Prop prayerId: string;
  @Prop currentLanguage: string = 'en';
  @StorageLink(STORAGE_KEY_DUA_BINDINGS_VERSION)
  @Watch('loadData')
  version: number = 0;
  @State private count: number = 0;

  aboutToAppear(): void {
    this.loadData();
  }

  async loadData(): Promise<void> {
    try {
      const bindJson = await PreferencesHelper.getString('dua_bindings', '{}');
      const bindings: Record<string, string[]> = JSON.parse(bindJson);

      let c = 0;
      const keys = Object.keys(bindings);
      for (let i = 0; i < keys.length; i++) {
        if (bindings[keys[i]].includes(this.prayerId)) {
          c++;
        }
      }
      this.count = c;
    } catch (e) {
      this.count = 0;
    }
  }

  build() {
    if (this.count > 0) {
      Row({ space: 4 }) {
        Text('🤲').fontSize(12)
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
        // Pass filterPrayer so DuasPage shows only the ones for this prayer
        router.pushUrl({
          url: 'pages/DuasPage',
          params: { filterPrayer: this.prayerId }
        }).catch((e: Error) => console.error(JSON.stringify(e)));
      })
    }
  }
}