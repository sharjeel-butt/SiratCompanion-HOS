import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { Theme, ThemeColors, ThemeMode } from '../core/Theme';
import { PageTheme } from '../core/PageTheme';
import { L } from '../i18n/LocalizationHelper';
import { STORAGE_KEY_LANGUAGE, STORAGE_KEY_THEME_MODE } from '../core/StorageKeys';
import { BilingualHadith, HadithDbRecord, HadithRef } from '../hadith/HadithModels';
import { HadithSearchService } from '../hadith/HadithSearchService';
import { HadithDbHelper } from '../hadith/HadithDbHelper';
import { NavHelper } from '../core/NavHelper';
import { util } from '@kit.ArkTS';

@Entry
@Component
struct HadithBrowsePage {
  @StorageLink(STORAGE_KEY_THEME_MODE) @Watch('onThemeModeChanged') themeMode: string = ThemeMode.SYSTEM;
  @StorageLink(STORAGE_KEY_LANGUAGE) @Watch('onLangChanged') appLanguage: string = 'en';
  @State colors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);

  @State hadiths: BilingualHadith[] = [];
  @State filteredHadiths: BilingualHadith[] = [];
  @State isLoading: boolean = true;
  @State pageTitle: string = 'Browse';
  @State searchQuery: string = '';
  @State totalCount: number = 0;

  private browseType: string = '';
  private browseId: string = '';
  private pageOffset: number = 0;
  private readonly PAGE_SIZE: number = 50;
  private allIds: string[] = []; // For contexts/topics

  async aboutToAppear() {
    this.colors = PageTheme.compute(this.themeMode);
    const params = router.getParams() as Record<string, string>;
    if (params && params['type'] && params['id']) {
      this.browseType = params['type'];
      this.browseId = params['id'];

      if (this.browseType === 'book') {
        const baseTitle = HadithSearchService.translate('collection_' + this.browseId, this.appLanguage);
        this.totalCount = await HadithDbHelper.getCollectionCount(this.browseId);
        this.pageTitle = this.totalCount > 0 ? `${baseTitle} (${this.totalCount})` : baseTitle;
      } else if (this.browseType === 'context') {
        const baseTitle = HadithSearchService.translate('context_' + this.browseId, this.appLanguage);
        this.pageTitle = baseTitle; // Context length is handled in loadData
      } else {
        const baseTitle = HadithSearchService.translate('topic_' + this.browseId, this.appLanguage);
        this.pageTitle = baseTitle;
      }

      await this.loadData();
    }
  }

  onThemeModeChanged() {
    this.colors = PageTheme.compute(this.themeMode);
  }

  async onLangChanged() {
    await this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    const ctx = getContext(this) as common.UIAbilityContext;
    await HadithSearchService.setLanguage(ctx, this.appLanguage);

    this.hadiths = [];
    this.pageOffset = 0;

    if (this.browseType === 'book') {
      const recs = await HadithDbHelper.getByCollection(this.browseId, this.PAGE_SIZE, this.pageOffset);
      for (const r of recs) {
        const bi = await HadithDbHelper.getBilingualById(ctx, r.hadith_id, this.appLanguage);
        if (bi) {
          this.hadiths.push(bi);
        }
      }
      this.pageOffset += this.PAGE_SIZE;
    } else {
      const fileType = this.browseType === 'context' ? 'contexts' : 'topics';
      try {
        const data = await ctx.resourceManager.getRawFileContent(`hadith/${fileType}/${this.browseId}.json`);
        const parsed = JSON.parse(util.TextDecoder.create('utf-8').decodeToString(data)) as HadithRef[];

        this.allIds = parsed.map((p: HadithRef) => p.id);

        // 👇 FIX: Update title with count for contexts/topics
        const baseTitle = this.browseType === 'context'
          ? HadithSearchService.translate('context_' + this.browseId, this.appLanguage)
          : HadithSearchService.translate('topic_' + this.browseId, this.appLanguage);
        this.pageTitle = `${baseTitle} (${this.allIds.length})`;

        for (let i = 0; i < Math.min(this.allIds.length, this.PAGE_SIZE); i++) {
          const bi = await HadithDbHelper.getBilingualById(ctx, this.allIds[i], this.appLanguage);
          if (bi) {
            bi.section = HadithDbHelper.translateSection(parsed[i].section || '', this.appLanguage);
            bi.life_contexts = parsed[i].life_contexts;
            bi.topics = parsed[i].topics;
            this.hadiths.push(bi);
          }
        }
        this.pageOffset = Math.min(this.allIds.length, this.PAGE_SIZE);
      } catch (e) {
      }
    }

    this.applyFilter();
    this.isLoading = false;
  }

  async loadMore() {
    if (this.isLoading) {
      return;
    }
    if (this.searchQuery.length > 0) {
      return;
    } // Disable load more while searching

    this.isLoading = true;
    const ctx = getContext(this) as common.UIAbilityContext;

    if (this.browseType === 'book') {
      const recs = await HadithDbHelper.getByCollection(this.browseId, this.PAGE_SIZE, this.pageOffset);
      for (const r of recs) {
        const bi = await HadithDbHelper.getBilingualById(ctx, r.hadith_id, this.appLanguage);
        if (bi) {
          this.hadiths.push(bi);
        }
      }
      this.pageOffset += this.PAGE_SIZE;
    } else {
      const fileType = this.browseType === 'context' ? 'contexts' : 'topics';
      try {
        // Reload JSON to get the metadata (could be cached, but this is safe)
        const data = await ctx.resourceManager.getRawFileContent(`hadith/${fileType}/${this.browseId}.json`);
        const parsed = JSON.parse(util.TextDecoder.create('utf-8').decodeToString(data)) as HadithRef[];

        for (let i = this.pageOffset; i < Math.min(this.allIds.length, this.pageOffset + this.PAGE_SIZE); i++) {
          const bi = await HadithDbHelper.getBilingualById(ctx, this.allIds[i], this.appLanguage);
          if (bi) {
            bi.section = HadithDbHelper.translateSection(parsed[i].section || '', this.appLanguage);
            bi.life_contexts = parsed[i].life_contexts;
            bi.topics = parsed[i].topics;
            this.hadiths.push(bi);
          }
        }
        this.pageOffset += this.PAGE_SIZE;
      } catch (e) {
      }
    }

    this.applyFilter();
    this.isLoading = false;
  }

  private applyFilter() {
    if (this.searchQuery.trim().length === 0) {
      this.filteredHadiths = this.hadiths;
    } else {
      const q = this.searchQuery.toLowerCase();
      this.filteredHadiths = this.hadiths.filter((h: BilingualHadith) =>
      h.arabic_text.includes(q) ||
        h.translated_text.toLowerCase().includes(q) ||
        h.section.toLowerCase().includes(q) ||
        h.hadith_number.includes(q)
      );
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

        Text(this.pageTitle)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textWhite)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%').height(72).padding({ left: 16, right: 16 })
      .backgroundColor(this.colors.cardDark)

      // 👇 NEW: Search Bar for local filtering
      Search({ value: this.searchQuery, placeholder: 'Search in ' + this.pageTitle })
        .onChange((v: string) => {
          this.searchQuery = v;
          this.applyFilter();
        })
        .margin({
          left: 16,
          right: 16,
          top: 16,
          bottom: 8
        })
        .backgroundColor(this.colors.cardDark)
        .placeholderColor(this.colors.textMuted)
        .textFont({ size: 15 })

      if (this.isLoading && this.hadiths.length === 0) {
        LoadingProgress().width(40).height(40).color(this.colors.accentGold).margin({ top: 40 })
      } else if (this.filteredHadiths.length === 0) {
        Column() {
          Image($r('app.media.ic_hadith_book'))
            .width(40)
            .height(40)
            .fillColor(this.colors.textMuted)
            .margin({ bottom: 12 })
          Text(L.get('hadith_no_results', this.appLanguage)).fontSize(16).fontColor(this.colors.textMuted)
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List({ space: 12 }) {
          ForEach(this.filteredHadiths, (hadith: BilingualHadith) => {
            ListItem() {
              Column() {
                Row() {
                  Text(hadith.collection)
                    .fontSize(12)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.colors.accentGold)
                    .layoutWeight(1)
                  Text(`#${hadith.hadith_number}`).fontSize(11).fontColor(this.colors.textMuted)
                }.width('100%').margin({ bottom: 8 })

                Text(hadith.arabic_text)
                  .fontSize(22)
                  .fontFamily('AmiriQuran, sans-serif')
                  .fontColor(this.colors.textWhite)
                  .direction(Direction.Rtl)
                  .textAlign(TextAlign.Start)
                  .maxLines(3)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%')
                  .margin({ bottom: 10 })

                if (this.appLanguage !== 'ar' && hadith.translated_text.length > 0) {
                  Divider().color(this.colors.borderSoft).margin({ bottom: 10 })
                  Text(hadith.translated_text)
                    .fontSize(14)
                    .fontColor(this.colors.textMuted)
                    .textAlign(TextAlign.Start)
                    .maxLines(3)
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
            }
          }, (h: BilingualHadith) => `browse-${h.id}-${this.appLanguage}`)

          // Show Load More only if not searching
          if (!this.isLoading && this.searchQuery.length === 0 && this.hadiths.length > 0) {
            ListItem() {
              Button(L.get('load_more', this.appLanguage) || 'Load More')
                .width('100%')
                .height(48)
                .backgroundColor(this.colors.tintSoft)
                .fontColor(this.colors.accentGold)
                .onClick(() => this.loadMore())
            }
          }
        }
        .padding({
          left: 16,
          right: 16,
          top: 8,
          bottom: 40
        })
        .layoutWeight(1)
      }
    }
    .width('100%').height('100%').backgroundColor(this.colors.primaryGreen)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }
}