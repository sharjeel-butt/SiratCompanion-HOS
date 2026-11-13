import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { Theme, ThemeColors, ThemeMode } from '../core/Theme';
import { PageTheme } from '../core/PageTheme';
import { L } from '../i18n/LocalizationHelper';
import { STORAGE_KEY_LANGUAGE, STORAGE_KEY_THEME_MODE } from '../core/StorageKeys';
// 👇 Added CatalogItem to imports
import { BilingualHadith, Catalog, CatalogItem, HadithDbRecord, HadithRef } from '../hadith/HadithModels';
import { HadithSearchService } from '../hadith/HadithSearchService';
import { HadithDbHelper } from '../hadith/HadithDbHelper';
import { NavHelper } from '../core/NavHelper';
import { util } from '@kit.ArkTS';

@Entry
@Component
struct HadithHomePage {
  @StorageLink(STORAGE_KEY_THEME_MODE) @Watch('onThemeModeChanged') themeMode: string = ThemeMode.SYSTEM;
  @StorageLink(STORAGE_KEY_LANGUAGE) @Watch('onLangChanged') appLanguage: string = 'en';
  @State colors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);
  @State featuredHadiths: BilingualHadith[] = [];
  @State searchResults: BilingualHadith[] = [];
  @State searchQuery: string = '';
  @State isLoading: boolean = true;
  @State errorMsg: string = '';
  @State hasSearched: boolean = false;
  @State catalog: Catalog | null = null;

  async aboutToAppear(): Promise<void> {
    this.colors = PageTheme.compute(this.themeMode);
    await this.loadData();
  }

  async onLangChanged(): Promise<void> {
    await this.loadData();
  }

  onThemeModeChanged(): void {
    this.colors = PageTheme.compute(this.themeMode);
  }

  private tr(key: string): string {
    return L.get(key, this.appLanguage);
  }

  async loadData(): Promise<void> {
    this.isLoading = true;
    this.errorMsg = '';
    const ctx = getContext(this) as common.UIAbilityContext;

    const dbSuccess: boolean = await HadithSearchService.setLanguage(ctx, this.appLanguage);
    if (!dbSuccess) {
      this.errorMsg = "Failed to open the database.";
      this.isLoading = false;
      return;
    }

    // Load Catalog for browsing
    try {
      const data = await ctx.resourceManager.getRawFileContent('hadith/lookup/catalog.json');
      this.catalog = JSON.parse(util.TextDecoder.create('utf-8').decodeToString(data)) as Catalog;
    } catch (e) {
    }

    const featuredRefs: HadithRef[] = await HadithSearchService.getFeatured(ctx);
    this.featuredHadiths = [];

    // Shuffle the featured refs
    for (let i: number = featuredRefs.length - 1; i > 0; i--) {
      const j: number = Math.floor(Math.random() * (i + 1));
      const temp = featuredRefs[i];
      featuredRefs[i] = featuredRefs[j];
      featuredRefs[j] = temp;
    }

    if (featuredRefs.length > 0) {
      for (let i: number = 0; i < Math.min(featuredRefs.length, 30); i++) {
        const ref = featuredRefs[i];
        const rec: BilingualHadith | null = await HadithDbHelper.getBilingualById(ctx, ref.id, this.appLanguage);

        if (rec !== null) {
          rec.section = HadithDbHelper.translateSection(ref.section || '', this.appLanguage);
          rec.life_contexts = ref.life_contexts;
          rec.topics = ref.topics;
          this.featuredHadiths.push(rec);
        }
      }
    }

    // Fallback
    if (this.featuredHadiths.length === 0) {
      const fallbackRecs: HadithDbRecord[] = await HadithDbHelper.getAnyFeatured(30);
      for (let i: number = 0; i < fallbackRecs.length; i++) {
        const biRec: BilingualHadith | null =
          await HadithDbHelper.getBilingualById(ctx, fallbackRecs[i].hadith_id, this.appLanguage);
        if (biRec !== null) {
          this.featuredHadiths.push(biRec);
        }
      }
    }

    if (this.featuredHadiths.length === 0) {
      this.errorMsg = "The database is completely empty or table name is wrong.";
    }
    this.isLoading = false;
  }

  async performSearch(): Promise<void> {
    if (this.searchQuery.trim().length === 0) {
      this.searchResults = [];
      this.hasSearched = false;
      return;
    }
    this.isLoading = true;
    this.hasSearched = true;
    const ctx = getContext(this) as common.UIAbilityContext;

    const searchRefs: HadithRef[] = await HadithSearchService.search(ctx, this.searchQuery);
    this.searchResults = [];

    for (let i: number = 0; i < searchRefs.length; i++) {
      const ref = searchRefs[i];
      const rec: BilingualHadith | null = await HadithDbHelper.getBilingualById(ctx, ref.id, this.appLanguage);
      if (rec !== null) {
        rec.section = HadithDbHelper.translateSection(ref.section || '', this.appLanguage);
        rec.life_contexts = ref.life_contexts;
        rec.topics = ref.topics;
        this.searchResults.push(rec);
      }
    }

    // Fallback to text search
    if (this.searchResults.length === 0) {
      const fallbackRecs: HadithDbRecord[] = await HadithDbHelper.searchByText(this.searchQuery, 50);
      for (let i: number = 0; i < fallbackRecs.length; i++) {
        const rec = fallbackRecs[i];
        let rawCol = rec.collection.toLowerCase();
        if (rawCol.includes('-')) {
          rawCol = rawCol.substring(rawCol.indexOf('-') + 1);
        }

        const locKey = 'collection_' + rawCol;
        const translated = L.get(locKey, this.appLanguage);
        const localizedCollection =
          translated !== locKey ? translated : rawCol.charAt(0).toUpperCase() + rawCol.slice(1);

        const biRec: BilingualHadith = {
          id: rec.hadith_id,
          collection: localizedCollection,
          section: '',
          section_localized: '',
          hadith_number: rec.hadith_number,
          arabic_text: '',
          translated_text: rec.text,
          translated_language: this.appLanguage
        };
        this.searchResults.push(biRec);
      }
    }

    this.isLoading = false;
  }

  @Builder
  HadithCard(hadith: BilingualHadith) {
    Column() {
      Row() {
        Text(hadith.collection)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.accentGold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
        Text(`#${hadith.hadith_number}`)
          .fontSize(11).fontColor(this.colors.textMuted)
      }.width('100%').margin({ bottom: 8 })

      Text(hadith.arabic_text.length > 0 ? hadith.arabic_text : hadith.translated_text)
        .fontSize(hadith.arabic_text.length > 0 ? 22 : 16)
        .fontFamily(hadith.arabic_text.length > 0 ? 'AmiriQuran, sans-serif' : 'Outfit, sans-serif')
        .fontColor(this.colors.textWhite)
        .direction(hadith.arabic_text.length > 0 ? Direction.Rtl : Direction.Ltr)
        .textAlign(TextAlign.Start)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .margin({ bottom: 10 })

      if (hadith.arabic_text.length > 0 && this.appLanguage !== 'ar' && hadith.translated_text.length > 0) {
        Divider().color(this.colors.borderSoft).margin({ bottom: 10 })
        Text(hadith.translated_text)
          .fontSize(14)
          .fontColor(this.colors.textMuted)
          .textAlign(TextAlign.Start)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(Theme.radiusLarge)
    .border({ width: 1, color: this.colors.borderSoft })
    .shadow({
      radius: 8,
      color: this.colors.shadowCard,
      offsetX: 0,
      offsetY: 2
    })
  }

  @Builder
  BrowseCatalogUI() {
    if (this.catalog !== null) {
      Column({ space: 20 }) {

        // 1. Books (Hardcoded since they aren't in catalog.json)
        Column() {
          Text(this.tr('hadith_books') || 'Books')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.colors.textWhite)
            .margin({ bottom: 8 })
            .width('100%')
          Scroll() {
            Row({ space: 8 }) {
              ForEach(['bukhari', 'muslim', 'abudawud', 'tirmidhi', 'nasai', 'ibnmajah', 'malik'], (colId: string) => {
                Text(HadithSearchService.translate('collection_' + colId, this.appLanguage))
                  .fontSize(14)
                  .fontColor(this.colors.accentGold)
                  .backgroundColor(this.colors.tintSubtle)
                  .padding({
                    left: 16,
                    right: 16,
                    top: 8,
                    bottom: 8
                  })
                  .borderRadius(20)
                  .border({ width: 1, color: this.colors.borderSoft })
                  .onClick(() => this.navigateToBrowse('book', colId))
              })
            }.padding({ right: 16 })
          }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
        }.width('100%')

        // 2. Life Contexts
        if (this.catalog.contexts && this.catalog.contexts.length > 0) {
          Column() {
            Text(this.tr('hadith_contexts') || 'Life Contexts')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.colors.textWhite)
              .margin({ bottom: 8 })
              .width('100%')
            Scroll() {
              Row({ space: 8 }) {
                // 👇 FIX: Loop through strings directly
                ForEach(this.catalog.contexts, (ctxId: string) => {
                  Text(HadithSearchService.translate('context_' + ctxId, this.appLanguage))
                    .fontSize(14)
                    .fontColor(this.colors.textWhite)
                    .backgroundColor(this.colors.tintSoft)
                    .padding({
                      left: 16,
                      right: 16,
                      top: 8,
                      bottom: 8
                    })
                    .borderRadius(20)
                    .onClick(() => this.navigateToBrowse('context', ctxId))
                })
              }.padding({ right: 16 })
            }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
          }.width('100%')
        }

        // 3. Topics
        if (this.catalog.topics && this.catalog.topics.length > 0) {
          Column() {
            Text(this.tr('hadith_topics') || 'Topics')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.colors.textWhite)
              .margin({ bottom: 8 })
              .width('100%')
            Scroll() {
              Row({ space: 8 }) {
                // 👇 FIX: Loop through strings directly
                ForEach(this.catalog.topics, (topicId: string) => {
                  Text(HadithSearchService.translate('topic_' + topicId, this.appLanguage))
                    .fontSize(14)
                    .fontColor(this.colors.textWhite)
                    .backgroundColor(this.colors.tintMedium)
                    .padding({
                      left: 16,
                      right: 16,
                      top: 8,
                      bottom: 8
                    })
                    .borderRadius(20)
                    .onClick(() => this.navigateToBrowse('topic', topicId))
                })
              }.padding({ right: 16 })
            }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
          }.width('100%')
        }
      }
      .width('100%')
      .margin({ bottom: 24 })
    }
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

        Text(this.tr('hadith_title'))
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textWhite)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%').height(72).padding({ left: 16, right: 16 })
      .backgroundColor(this.colors.cardDark)

      // Search Bar
      Search({ value: this.searchQuery, placeholder: this.tr('hadith_search_hint') })
        .onChange((v: string) => {
          this.searchQuery = v;
          this.performSearch();
        })
        .margin({
          left: 16,
          right: 16,
          top: 16,
          bottom: 16
        })
        .backgroundColor(this.colors.cardDark)
        .placeholderColor(this.colors.textMuted)
        .textFont({ size: 15 })

      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40).color(this.colors.accentGold)
          Text(this.tr('hadith_searching')).fontSize(12).fontColor(this.colors.textMuted).margin({ top: 12 })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.errorMsg.length > 0) {
        Column() {
          Image($r('app.media.ic_warning')).width(40).height(40).fillColor(this.colors.statusExpress)
          Text(this.errorMsg)
            .fontSize(14)
            .fontColor(this.colors.textWhite)
            .margin({ top: 12 })
            .textAlign(TextAlign.Center)
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).padding(20)
      } else if (this.hasSearched && this.searchResults.length === 0) {
        Column() {
          Image($r('app.media.ic_hadith_book'))
            .width(40)
            .height(40)
            .fillColor(this.colors.textMuted)
            .margin({ bottom: 12 })
          Text(this.tr('hadith_no_results')).fontSize(16).fontColor(this.colors.textMuted)
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List() {

          // 👇 INSERT THE BROWSE UI HERE (Only if not searching)
          if (this.searchQuery.length === 0) {
            ListItem() {
              this.BrowseCatalogUI()
            }
          }

          ListItem() {
            Text(this.searchQuery.length > 0 ? this.tr('hadith_search_results') : this.tr('hadith_featured'))
              .fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
              .margin({ top: 8, bottom: 12 })
          }

          ForEach(this.searchQuery.length > 0 ? this.searchResults : this.featuredHadiths,
            (hadith: BilingualHadith) => {
              ListItem() {
                this.HadithCard(hadith)
              }
              .margin({ bottom: 12 }) // Added margin so cards don't touch
              .onClick(() => {
                NavHelper.prepareForward();

                const params: Record<string, string> = {};
                params['id'] = hadith.id;

                const metaObj: Record<string, Object> = {};
                if (hadith.section) {
                  metaObj['section'] = hadith.section;
                }
                if (hadith.life_contexts) {
                  metaObj['contexts'] = hadith.life_contexts;
                }
                if (hadith.topics) {
                  metaObj['topics'] = hadith.topics;
                }

                params['meta'] = JSON.stringify(metaObj);

                router.pushUrl({ url: 'pages/HadithDetailsPage', params: params });
              })
            }, (h: BilingualHadith) => `hadith-${h.id}-${this.appLanguage}`)

          ListItem() {
            Column().height(40)
          }
        }
        .padding({ left: 16, right: 16 })
        .layoutWeight(1)
      }
    }
    .width('100%').height('100%').backgroundColor(this.colors.primaryGreen)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  private navigateToBrowse(type: string, id: string) {
    NavHelper.prepareForward();

    const params: Record<string, string> = {};
    params['type'] = type;
    params['id'] = id;

    router.pushUrl({ url: 'pages/HadithBrowsePage', params: params });
  }
}