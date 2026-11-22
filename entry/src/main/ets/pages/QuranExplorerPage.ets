import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { ThemeColors, ThemeMode } from '../core/ui/themes/Theme';
import { PageTheme } from '../core/ui/PageTheme';
import { L } from '../i18n/LocalizationHelper';
import { STORAGE_KEY_LANGUAGE, STORAGE_KEY_THEME_MODE } from '../core/common/StorageKeys';
import { QuranGraphService } from '../quran/QuranGraphService';
import { QuranCollection, QuranProphet } from '../quran/QuranGraphModels';
import { NavHelper } from '../core/util/NavHelper';

@Entry
@Component
struct QuranExplorerPage {
  @StorageLink(STORAGE_KEY_THEME_MODE) @Watch('onThemeModeChanged') themeMode: string = ThemeMode.SYSTEM;
  @StorageLink(STORAGE_KEY_LANGUAGE) @Watch('onLangChanged') appLanguage: string = 'en';
  @State colors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);
  @State collections: QuranCollection[] = [];
  @State prophets: QuranProphet[] = [];
  @State activeTab: number = 0;
  @State isLoading: boolean = true;

  async aboutToAppear() {
    this.colors = PageTheme.compute(this.themeMode);
    const ctx = getContext(this) as common.UIAbilityContext;
    await QuranGraphService.init(ctx, this.appLanguage);
    this.collections = QuranGraphService.getAllCollections();
    this.prophets = QuranGraphService.getAllProphets();
    this.isLoading = false;
  }

  onThemeModeChanged() {
    this.colors = PageTheme.compute(this.themeMode);
  }

  onLangChanged() {
    this.aboutToAppear();
  }

  build() {
    Column() {
      // Top Bar
      Row({ space: 16 }) {
        Row() {
          Image($r('app.media.ic_chevron_right')).width(20).height(20)
            .fillColor(this.colors.textWhite)
            .rotate({ angle: L.isRtlLang(this.appLanguage) ? 0 : 180 })
        }
        .width(40)
        .height(40)
        .justifyContent(FlexAlign.Center)
        .borderRadius(20)
        .backgroundColor(this.colors.tintSoft)
        .onClick(() => router.back())

        Text(L.get('quran_explorer', this.appLanguage))
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textWhite)
          .layoutWeight(1)
          .textAlign(TextAlign.Start)
      }
      .width('100%').height(72).padding({ left: 16, right: 16 })
      .backgroundColor(this.colors.cardDark)

      if (this.isLoading) {
        LoadingProgress().width(40).height(40).color(this.colors.accentGold).margin({ top: 40 })
      } else {
        Scroll() {
          Column() {
            // Featured Section
            this.FeaturedSection()

            // Tabs
            Row() {
              this.TabButton(0, L.get('quran_topics', this.appLanguage))
              this.TabButton(1, L.get('quran_prophets', this.appLanguage))
            }
            .width('100%')
            .height(48)
            .backgroundColor(this.colors.cardDark)
            .padding({ left: 16, right: 16 })
            .margin({ top: 16 })

            if (this.activeTab === 0) {
              this.TopicsList()
            } else {
              this.ProphetsList()
            }
          }
          .width('100%')
        }
        .layoutWeight(1)
      }
    }
    .width('100%').height('100%')
    .backgroundColor(this.colors.primaryGreen)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  @Builder
  FeaturedSection() {
    Row({ space: 12 }) {
      // Rabbana Hero Card
      Column() {
        Image($r('app.media.ic_dua')).width(24).height(24).fillColor(this.colors.accentGold).margin({ bottom: 8 })
        Text(L.get('rabbana_title', this.appLanguage))
          .fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
        Text(L.get('rabbana_desc', this.appLanguage))
          .fontSize(11).fontColor(this.colors.textMuted).margin({ top: 4 }).maxLines(2)
      }
      .layoutWeight(1)
      .padding(16)
      .backgroundColor(this.colors.cardDark)
      .borderRadius(12)
      .onClick(() => {
        NavHelper.prepareForward();
        router.pushUrl({
          url: 'pages/QuranCollectionPage',
          params: { collectionId: 'rabbana', title: L.get('rabbana_title', this.appLanguage) }
        });
      })

      // Prophetic Duas Card
      Column() {
        Image($r('app.media.ic_prophetic_dua'))
          .width(24)
          .height(24)
          .fillColor(this.colors.accentGold)
          .margin({ bottom: 8 })
        Text(L.get('prophetic_duas', this.appLanguage))
          .fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
        Text(L.get('prophetic_desc', this.appLanguage))
          .fontSize(11).fontColor(this.colors.textMuted).margin({ top: 4 }).maxLines(2)
      }
      .layoutWeight(1)
      .padding(16)
      .backgroundColor(this.colors.cardDark)
      .borderRadius(12)
      .onClick(() => {
        NavHelper.prepareForward();
        router.pushUrl({
          url: 'pages/QuranCollectionPage',
          params: { collectionId: 'prophets', title: L.get('prophetic_duas', this.appLanguage) }
        });
      })
    }
    .width('100%').padding({ left: 16, right: 16, top: 16 })
  }

  @Builder
  TabButton(index: number, label: string) {
    Text(label)
      .fontSize(15)
      .fontWeight(this.activeTab === index ? FontWeight.Bold : FontWeight.Normal)
      .fontColor(this.activeTab === index ? this.colors.accentGold : this.colors.textMuted)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .height(48)
      .border({ width: { bottom: this.activeTab === index ? 3 : 0 }, color: this.colors.accentGold })
      .onClick(() => {
        this.activeTab = index;
      })
  }

  @Builder
  TopicsList() {
    Column() {
      ForEach(this.collections, (col: QuranCollection) => {
        Row() {
          Column() {
            Text(QuranGraphService.getCollectionTitle(col.id))
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.colors.textWhite)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(`${col.dua_ids.length} ${L.get('duas', this.appLanguage)}`)
              .fontSize(12).fontColor(this.colors.textMuted).margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start).layoutWeight(1)

          Image($r('app.media.ic_chevron_right'))
            .width(16).height(16).fillColor(this.colors.accentGold)
            .rotate({ angle: L.isRtlLang(this.appLanguage) ? 180 : 0 })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(this.colors.cardDark)
        .borderRadius(12)
        .border({ width: 1, color: this.colors.borderSoft })
        .margin({ bottom: 8 })
        .onClick(() => {
          NavHelper.prepareForward();
          router.pushUrl({
            url: 'pages/QuranCollectionPage',
            params: { collectionId: col.id, title: QuranGraphService.getCollectionTitle(col.id) }
          });
        })
      }, (col: QuranCollection) => `col-${col.id}-${this.appLanguage}`)
    }
    .width('100%').padding(16)
  }

  @Builder
  ProphetsList() {
    Column() {
      ForEach(this.prophets, (prop: QuranProphet) => {
        Row() {
          Text(QuranGraphService.getProphetName(prop.id))
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
            .layoutWeight(1)
          Image($r('app.media.ic_chevron_right'))
            .width(16).height(16).fillColor(this.colors.accentGold)
            .rotate({ angle: L.isRtlLang(this.appLanguage) ? 180 : 0 })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(this.colors.cardDark)
        .borderRadius(12)
        .border({ width: 1, color: this.colors.borderSoft })
        .margin({ bottom: 8 })
        .onClick(() => {
          NavHelper.prepareForward();
          router.pushUrl({
            url: 'pages/QuranCollectionPage',
            params: { prophetId: prop.id, title: QuranGraphService.getProphetName(prop.id) }
          });
        })
      }, (prop: QuranProphet) => `prop-${prop.id}-${this.appLanguage}`)
    }
    .width('100%').padding(16)
  }
}