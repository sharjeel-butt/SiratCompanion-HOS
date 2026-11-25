import { common } from '@kit.AbilityKit';
import { promptAction, router } from '@kit.ArkUI';
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
import { CompleteDua, DuaSource } from '../duas/DuaModels';
import { TypographyHelper } from '../core/ui/themes/TypographyHelper';
import { NavHelper } from '../core/util/NavHelper';
import { QuranCollection } from '../quran/QuranGraphModels';
import { SourceParser } from '../i18n/SourceParser';

@Entry
@Component
struct DuaDetailsPage {
  @StorageLink(STORAGE_KEY_THEME_MODE) @Watch('onThemeModeChanged') themeMode: string = ThemeMode.SYSTEM;
  @StorageLink(STORAGE_KEY_LANGUAGE) @Watch('onLangChanged') appLanguage: string = 'en';
  @StorageLink(STORAGE_KEY_DUA_TRANSLATION_LANG) @Watch('onDuaLangChanged') duaTransLang: string = 'default';
  @State colors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);
  @State dua: CompleteDua | null = null;
  @State relatedDuas: CompleteDua[] = [];
  @State collections: QuranCollection[] = [];
  @State isLoading: boolean = true;
  private duaId: string = '';

  async aboutToAppear() {
    this.colors = PageTheme.compute(this.themeMode);
    const params = router.getParams() as Record<string, string>;
    this.duaId = params['id'];
    await this.loadData();
  }

  onDuaLangChanged() {
    this.loadData();
  }

  async onPageShow() {
    await this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    const ctx = getContext(this) as common.UIAbilityContext;
    await QuranGraphService.init(ctx, this.appLanguage);

    // 👈 Respect Translation Language for Dua Text
    const transLang = this.duaTransLang === 'default' ? this.appLanguage : this.duaTransLang;
    const allDuas = await DuaService.loadDuas(ctx, transLang, this.appLanguage);

    this.dua = allDuas.find(d => d.id === this.duaId) ?? null;

    if (this.dua !== null) {
      const relatedIds = QuranGraphService.getRelatedDuaIds(this.duaId);
      this.relatedDuas = allDuas.filter(d => relatedIds.includes(d.id)).slice(0, 3);

      const colIds = QuranGraphService.getCollectionIdsForDua(this.duaId);
      const allCols = QuranGraphService.getAllCollections();
      this.collections = allCols.filter(c => colIds.includes(c.id));
    }

    this.isLoading = false;
  }

  onThemeModeChanged() {
    this.colors = PageTheme.compute(this.themeMode);
  }

  onLangChanged() {
    this.loadData();
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

        Text(this.dua?.translatedName || 'Dua')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textWhite)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }.width('100%').height(72).padding({ left: 16, right: 16 }).backgroundColor(this.colors.cardDark)

      if (this.isLoading || this.dua === null) {
        LoadingProgress().width(40).height(40).color(this.colors.accentGold).margin({ top: 40 })
      } else {
        Scroll() {
          Column() { // Main Dua Content
            Column() {
              Text(this.dua.translatedName)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.colors.accentGold)
                .textAlign(TextAlign.Center)
                .width('100%')
                .margin({ bottom: 16 })

              Text(this.dua.arabic)
                .fontSize(TypographyHelper.getArabicFontSize(28))
                .fontFamily(TypographyHelper.getFont('ar', false))
                .fontColor(this.colors.textWhite)
                .textAlign(TextAlign.Center)
                .lineHeight(TypographyHelper.getArabicLineHeight(46))
                .width('100%')
                .margin({ bottom: 20 })

              Text(this.dua.translatedText)
                .fontSize(16)
                .fontColor(this.colors.textMuted)
                .textAlign(TextAlign.Center)
                .lineHeight(24)
                .width('100%')
                .margin({ bottom: 20 })

              Text(this.dua.translatedReference)
                .fontSize(12)
                .fontColor(this.colors.accentGold)
                .fontStyle(FontStyle.Italic)
                .textAlign(TextAlign.Center)
                .width('100%')
            }
            .width('100%')
            .padding(20)
            .backgroundColor(this.colors.cardDark)
            .borderRadius(16)
            .margin({ bottom: 20 })

            // Appears in Collections
            this.CollectionsSection()

            // Related Duas
            if (this.relatedDuas.length > 0) {
              Column() {
                Text(L.get('dua_related', this.appLanguage))
                  .fontSize(13)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.colors.textMuted)
                  .width('100%')
                  .margin({ bottom: 10 })

                if (this.dua.sources && this.dua.sources.length > 0) {
                  Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center }) {
                    ForEach(this.dua.sources, (src: DuaSource, i: number) => {
                      Row({ space: 4 }) {
                        Image($r('app.media.ic_link')).width(12).height(12).fillColor(this.colors.accentGold)
                        Text(SourceParser.getLabel(src, this.appLanguage))
                          .fontSize(11)
                          .fontColor(this.colors.accentGold)
                          .fontWeight(FontWeight.Medium)
                      }
                      .padding({
                        left: 10,
                        right: 10,
                        top: 6,
                        bottom: 6
                      })
                      .backgroundColor(this.colors.tintSoft)
                      .borderRadius(16)
                      .border({ width: 1, color: this.colors.borderSoft })
                      .margin({ right: 8, top: 12 })
                      .onClick(() => this.onSourceTap(src))
                    }, (rel: CompleteDua) => `rel-${rel.id}-${this.appLanguage}-${this.duaTransLang}`)
                  }.width('100%').margin({ top: 4 })
                }
              }
              .width('100%')
              .padding(20)
              .backgroundColor(this.colors.cardDark)
              .borderRadius(16)
              .margin({ bottom: 20 })
            }
          }.width('100%').padding(16)
        }.layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.primaryGreen)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  @Builder
  CollectionsSection() {
    if (this.collections.length > 0) {
      Column() {
        Text(L.get('dua_appears_in', this.appLanguage))
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textMuted)
          .width('100%')
          .margin({ bottom: 10 })

        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.collections, (col: QuranCollection) => {
            Text(QuranGraphService.getCollectionTitle(col.id)) // 👈 Localized Title
              .fontSize(12)
              .fontColor(this.colors.accentGold)
              .backgroundColor(this.colors.tintSoft)
              .padding({
                left: 10,
                right: 10,
                top: 6,
                bottom: 6
              })
              .borderRadius(8)
              .margin({ right: 8, bottom: 8 })
              .onClick(() => {
                NavHelper.prepareForward();
                router.pushUrl({
                  url: 'pages/QuranCollectionPage',
                  params: { collectionId: col.id, title: QuranGraphService.getCollectionTitle(col.id) }
                });
              })
          }, (col: QuranCollection) => `col-${col.id}`)
        }.width('100%')
      }
      .width('100%')
      .padding(16)
      .backgroundColor(this.colors.cardDark)
      .borderRadius(12)
      .margin({ bottom: 20 })
    }
  }

  // Add this helper to DuaDetailsPage
  private getCollectionTitle(col: QuranCollection): string {
    const key = 'qkg_collection_' + col.id;
    const localized = L.get(key, this.appLanguage);
    return localized !== key ? localized : col.title;
  }

  private getCanonicalCollection(col: string): string {
    const c = col.toLowerCase();
    if (c.includes('bukhari') || c === 'bukh') {
      return 'bukhari';
    }
    if (c.includes('muslim') || c === 'musl') {
      return 'muslim';
    }
    if (c.includes('abu dawud') || c.includes('abudawud') || c === 'abud') {
      return 'abudawud';
    }
    if (c.includes('tirmidhi') || c === 'tirm') {
      return 'tirmidhi';
    }
    if (c.includes('nasai') || c === 'nasa') {
      return 'nasai';
    }
    if (c.includes('ibn majah') || c.includes('ibnmajah') || c === 'ibnm') {
      return 'ibnmajah';
    }
    if (c.includes('malik') || c === 'mali') {
      return 'malik';
    }
    return c;
  }

  private onSourceTap(src: DuaSource): void {
    if (src.type === 'hadith' && src.id) {
      const parts = src.id.split(':');
      if (parts.length === 2) {
        const col = this.getCanonicalCollection(parts[0]);
        const hadithId = `${col}:${parts[1]}`;
        NavHelper.prepareForward();
        router.pushUrl({
          url: 'pages/HadithDetailsPage', params: { id: hadithId }
        }).catch((e: Error) => console.error(JSON.stringify(e)));
        return;
      }
    }

    if (src.type === 'quran' && src.surah !== undefined && src.ayah !== undefined) {
      NavHelper.prepareForward();
      router.pushUrl({
        url: 'pages/SurahDetailsPage', params: { surahId: src.surah, startVerse: src.ayah, endVerse: src.ayah }
      }).catch((e: Error) => console.error(JSON.stringify(e)));
      return;
    }

    const title = L.get('hadith_evidence_title', this.appLanguage);
    const msg = src.display || src.id || 'Unknown Source';
    promptAction.showDialog({
      title: title, message: msg, buttons: [{ text: L.get('ok', this.appLanguage), color: this.colors.accentGold }]
    });
  }
}