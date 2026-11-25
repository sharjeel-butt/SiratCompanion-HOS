import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { ThemeColors, ThemeMode } from '../core/ui/themes/Theme';
import { PageTheme } from '../core/ui/PageTheme';
import { L } from '../i18n/LocalizationHelper';
import {
  STORAGE_KEY_DUA_TRANSLATION_LANG,
  STORAGE_KEY_LANGUAGE,
  STORAGE_KEY_THEME_MODE
} from '../core/common/StorageKeys';
import { QuranGraphService } from '../quran/QuranGraphService';
import { DuaService } from '../duas/DuaService';
import { CompleteDua } from '../duas/DuaModels';
import { DuaCard } from '../duas/DuaCard';
import { NavHelper } from '../core/util/NavHelper';

@Entry
@Component
struct QuranCollectionPage {
  @StorageLink(STORAGE_KEY_THEME_MODE) @Watch('onThemeModeChanged') themeMode: string = ThemeMode.SYSTEM;
  @StorageLink(STORAGE_KEY_LANGUAGE) @Watch('onLangChanged') appLanguage: string = 'en';
  @StorageLink(STORAGE_KEY_DUA_TRANSLATION_LANG) @Watch('onDuaLangChanged') duaTransLang: string = 'default';
  @State colors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);
  @State title: string = '';
  @State duas: CompleteDua[] = [];
  @State isLoading: boolean = true;

  async aboutToAppear() {
    this.colors = PageTheme.compute(this.themeMode);
    const params = router.getParams() as Record<string, string>;
    this.title = params['title'] || 'Collection';
    console.log('QuranCollectionPage Router params: ' + JSON.stringify(params, null, 2));
    const ctx = getContext(this) as common.UIAbilityContext;
    await QuranGraphService.init(ctx, this.appLanguage);

    let duaIds: string[] = [];
    if (params['collectionId']) {
      duaIds = QuranGraphService.getDuaIdsForCollection(params['collectionId']);
    } else if (params['prophetId']) {
      duaIds = QuranGraphService.getDuaIdsForProphet(params['prophetId']);
    }

    // 👈 Respect the independent Translation Language setting here
    const transLang = this.duaTransLang === 'default' ? this.appLanguage : this.duaTransLang;
    const allDuas = await DuaService.loadDuas(ctx, transLang, this.appLanguage);

    this.duas = allDuas.filter((d: CompleteDua) => duaIds.includes(d.id));
    this.isLoading = false;
  }

  onDuaLangChanged() {
    this.aboutToAppear(); // Reload data immediately when the setting changes
  }

  async onPageShow() { // Reload when navigating back from Customize or DuaDetailsPage
    await this.aboutToAppear();
  }

  onThemeModeChanged() {
    this.colors = PageTheme.compute(this.themeMode);
  }

  onLangChanged() {
    this.aboutToAppear();
  }

  build() {
    Column() {
      Row({ space: 16 }) {
        Row() {
          Image($r('app.media.ic_chevron_right'))
            .width(20)
            .height(20)
            .fillColor(this.colors.textWhite)
            .rotate({ angle: L.isRtlLang(this.appLanguage) ? 0 : 180 })
        }
        .width(40)
        .height(40)
        .justifyContent(FlexAlign.Center)
        .borderRadius(20)
        .backgroundColor(this.colors.tintSoft)
        .onClick(() => router.back())

        Text(this.title)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textWhite)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }.width('100%').height(72).padding({ left: 16, right: 16 }).backgroundColor(this.colors.cardDark)

      if (this.isLoading) {
        LoadingProgress().width(40).height(40).color(this.colors.accentGold).margin({ top: 40 })
      } else if (this.duas.length === 0) {
        Text(L.get('hadith_no_results', this.appLanguage))
          .fontSize(16)
          .fontColor(this.colors.textMuted)
          .margin({ top: 40 })
      } else {
        List({ space: 12 }) {
          ForEach(this.duas, (dua: CompleteDua) => {
            ListItem() {
              Column() {
                DuaCard({
                  dua: dua,
                  colors: this.colors,
                  currentLanguage: this.appLanguage,
                  showName: true
                })
              }
              .width('100%')
              .padding(16)
              .backgroundColor(this.colors.cardDark)
              .borderRadius(12)
              .onClick(() => {
                NavHelper.prepareForward();
                router.pushUrl({
                  url: 'pages/DuaDetailsPage', params: { id: dua.id }
                });
              })
            }
          }, (dua: CompleteDua) => `dua-${dua.id}-${this.appLanguage}-${this.duaTransLang}`)
        }.layoutWeight(1).padding(16)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.primaryGreen)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }
}