import { ThemeColors, ThemeMode } from '../core/Theme';
import { PageTheme } from '../core/PageTheme';
import { CompleteDua, DuaSource } from '../duas/DuaModels';
import { STORAGE_KEY_DUA_TRANSLATION_LANG, STORAGE_KEY_LANGUAGE } from '../core/StorageKeys';
import { RawPaths } from '../core/RawPaths';
import { util } from '@kit.ArkTS';
import { AppLogger } from '../core/AppLogger';
import { promptAction, router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { DuaService } from '../duas/DuaService';
import { HadithSearchService } from '../hadith/HadithSearchService';
import { L } from '../i18n/LocalizationHelper';
import { TypographyHelper } from '../core/TypographyHelper';
import { SourceParser } from '../core/SourceParser';
import { NavHelper } from '../core/NavHelper';

interface CategoryEntry {
  name: string;
  count: number;
}

@Entry
@Component
struct DuasPage {
  @StorageLink(STORAGE_KEY_DUA_TRANSLATION_LANG) @Watch('onLangChanged') duaTransLang: string = 'default';
  @StorageLink(STORAGE_KEY_LANGUAGE)
  @Watch('onLangChanged')
  appLanguage: string = 'en';
  @State colors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);
  @State duas: CompleteDua[] = [];
  @State filteredDuas: CompleteDua[] = [];
  @State searchQuery: string = '';
  @State activeCategory: string = 'all';
  @State isLoading: boolean = true;
  @State filterPrayer: string = '';
  @State filterCategory: string = '';
  private categories: string[] = ['all', 'favorites', 'forgiveness', 'distress', 'travel'];
  @State private categoryChips: CategoryEntry[] = [];

  async aboutToAppear() {
    this.colors = PageTheme.compute(ThemeMode.SYSTEM);

    const params = router.getParams() as Record<string, Object>;
    if (params && params['filterCategory']) {
      this.filterCategory = params['filterCategory'] as string;
      this.activeCategory = this.filterCategory;
    }
    if (params && params['filterPrayer']) {
      this.filterPrayer = params['filterPrayer'] as string;
    }

    await this.loadData();
  }

  onLangChanged() {
    this.loadData();
  }

  async loadData(): Promise<void> {
    this.isLoading = true;
    const ctx = getContext(this) as common.UIAbilityContext;

    // 1. Load duas
    this.duas = await DuaService.loadDuas(ctx, this.getDuaTranslationLang(), this.appLanguage);

    // 2. Load canonical categories (for stable ordering)
    let canonical: string[] = [];
    try {
      const bytes = await ctx.resourceManager.getRawFileContent(RawPaths.DUA_CATEGORIES);
      const parsed = JSON.parse(util.TextDecoder.create('utf-8').decodeToString(bytes)) as CategoryEntry[];
      for (const c of parsed) {
        canonical.push(c.name);
      }
    } catch (e) {
      AppLogger.warn('DuasPage', 'categories.json not found');
    }

    // 3. Build per-language counts from actual duas
    const actualCounts: Record<string, number> = {};
    for (const d of this.duas) {
      actualCounts[d.category] = (actualCounts[d.category] || 0) + 1;
    }

    // 4. Ensure HadithSearchService i18n is loaded for category labels
    await HadithSearchService.loadI18n(ctx, this.appLanguage);

    // 5. Build chips — canonical order, filter to non-empty
    const chips: CategoryEntry[] = [];
    // Always show "all" and "favorites" first
    chips.push({ name: 'all', count: this.duas.length });
    chips.push({ name: 'favorites', count: this.duas.filter(d => d.isFavorite).length });
    for (const cat of canonical) {
      const cnt = actualCounts[cat] || 0;
      if (cnt > 0) {
        chips.push({ name: cat, count: cnt });
      }
    }
    this.categoryChips = chips;

    // 6. Restore active filter if still valid
    if (this.activeCategory !== 'all' && this.activeCategory !== 'favorites') {
      if (!canonical.includes(this.activeCategory)) {
        this.activeCategory = 'all';
      }
    }

    this.applyFilters();
    this.isLoading = false;
  }

  applyFilters() {
    let result = this.duas;

    if (this.filterPrayer.length > 0) {
      result = result.filter((d: CompleteDua) => d.boundPrayerIds.includes(this.filterPrayer));
    }

    if (this.activeCategory === 'favorites') {
      result = result.filter((d: CompleteDua) => d.isFavorite);
    } else if (this.activeCategory !== 'all') {
      result = result.filter((d: CompleteDua) => d.category === this.activeCategory);
    }

    if (this.searchQuery.trim().length > 0) {
      const q = this.searchQuery.toLowerCase();
      result = result.filter((d: CompleteDua) =>
      d.arabic.includes(q) ||
        d.translatedName.toLowerCase().includes(q) ||
        d.translatedText.toLowerCase().includes(q)
      );
    }
    this.filteredDuas = result;
  }

  build() {
    Column() {
      // ===== Top Bar =====
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
        .alignItems(VerticalAlign.Center)
        .borderRadius(20)
        .backgroundColor(this.colors.tintSoft)
        .flexShrink(0)
        .onClick(() => router.back())

        Text(L.get('duas', this.appLanguage))
          .fontSize(TypographyHelper.getFontSize(this.appLanguage, 22))
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textWhite)
          .lineHeight(TypographyHelper.getLineHeight(this.appLanguage, 30))
          .layoutWeight(1)
          .textAlign(TextAlign.Start)
      }
      .width('100%')
      .height(72)
      .padding({ left: 16, right: 16 })
      .backgroundColor(this.colors.cardDark)
      .alignItems(VerticalAlign.Center)

      // ===== Search Bar =====
      Search({
        value: this.searchQuery,
        placeholder: L.get('search_duas', this.appLanguage)
      })
        .onChange((val: string) => {
          this.searchQuery = val;
          this.applyFilters();
        })
        .margin({
          left: 16,
          right: 16,
          top: 16,
          bottom: 12
        })
        .backgroundColor(this.colors.cardDark)
        .placeholderColor(this.colors.textMuted)

      // ===== Categories Scroll =====
      Scroll() {
        Row({ space: 8 }) {
          // Active prayer filter pill — clear button
          if (this.filterPrayer.length > 0) {
            Row({ space: 4 }) {
              Text(`${L.get('duas_for', this.appLanguage)} ${this.getPrayerLabel(this.filterPrayer)}`)
                .fontSize(TypographyHelper.getFontSize(this.appLanguage, 13))
                .fontColor(this.colors.textOnAccent)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .flexShrink(1)

              Image($r('app.media.ic_close'))
                .width(12)
                .height(12)
                .fillColor(this.colors.textOnAccent)
                .flexShrink(0)
            }
            .backgroundColor(this.colors.accentGold)
            .padding({
              left: 16,
              right: 12,
              top: 6,
              bottom: 6
            })
            .borderRadius(16)
            .onClick(() => {
              this.filterPrayer = '';
              this.applyFilters();
            })
          }

          // Category chips
          ForEach(this.categoryChips, (chip: CategoryEntry) => {
            Text(`${this.categoryLabel(chip.name)} (${chip.count})`)
              .fontSize(TypographyHelper.getFontSize(this.appLanguage, 13))
              .fontColor(this.activeCategory === chip.name
                ? this.colors.textOnAccent : this.colors.textMuted)
              .backgroundColor(this.activeCategory === chip.name
                ? this.colors.accentGold : this.colors.cardDark)
              .padding({
                left: 16,
                right: 16,
                top: 6,
                bottom: 6
              })
              .borderRadius(16)
              .onClick(() => {
                this.activeCategory = chip.name;
                this.applyFilters();
              })
          }, (chip: CategoryEntry) =>
          `cat-${chip.name}-${chip.count}-${this.activeCategory}-${this.appLanguage}`)
        }
        .padding({ left: 16, right: 16 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .margin({ bottom: 16 })

      // ===== Dua List =====
      if (this.isLoading) {
        LoadingProgress().width(40).height(40).color(this.colors.accentGold).margin({ top: 40 })
      } else {
        List({ space: 12 }) {
          ForEach(this.filteredDuas, (dua: CompleteDua) => {
            ListItem() {
              this.DuaCard(dua)
            }
          }, (dua: CompleteDua) => `dua-${dua.id}-${dua.isFavorite}-${this.appLanguage}`)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
      }
    }
    .width('100%').height('100%')
    .backgroundColor(this.colors.primaryGreen)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  /**
   * Renders one dua card.
   *
   * `dua` is the @Builder parameter — never `this.dua`.
   * Language is `this.appLanguage` — never `this.currentLanguage`.
   * There is no `showName` toggle in this builder; the name is
   * always rendered in the header row.
   *
   * Typography: Arabic glyphs use Arabic metrics (via getArabic*),
   * the name / translation / reference use UI-language metrics.
   */
  @Builder
  DuaCard(dua: CompleteDua) {
    Column() {
      // ---- Header: Name + Favorite ----
      Row() {
        Text(dua.translatedName)
          .fontSize(TypographyHelper.getFontSize(this.appLanguage, 16))
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.accentGold)
          .lineHeight(TypographyHelper.getLineHeight(this.appLanguage, 22))
          .layoutWeight(1)

        Image($r('app.media.ic_heart'))
          .width(20)
          .height(20)
          .fillColor(dua.isFavorite ? this.colors.statusExpress : this.colors.textMuted)
          .flexShrink(0)
          .onClick(async () => {
            await DuaService.toggleFavorite(
              dua.id,
              this.duas
                .filter((d: CompleteDua) => d.isFavorite)
                .map((d: CompleteDua) => d.id)
            );
            this.loadData();
          })
      }
      .width('100%').margin({ bottom: 12 })
      .alignItems(VerticalAlign.Center)

      // ---- Arabic text — always Arabic metrics ----
      Text(dua.arabic)
        .fontSize(TypographyHelper.getArabicFontSize(26))
        .fontFamily(TypographyHelper.getFont('ar', false))
        .fontColor(this.colors.textWhite)
        .textAlign(TextAlign.Center)
        .lineHeight(TypographyHelper.getArabicLineHeight(42))
        .width('100%')
        .margin({ top: 8, bottom: 16 })

      // ---- Translation — UI-language metrics ----
      Text(dua.translatedText)
        .fontSize(TypographyHelper.getFontSize(this.appLanguage, 14))
        .fontColor(this.colors.textMuted)
        .lineHeight(TypographyHelper.getLineHeight(this.appLanguage, 20))
        .width('100%')
        .margin({ bottom: 12 })

      // ---- Footer: Reference + Bind menu ----
      Row() {
        // Text(dua.translatedReference)
        //   .fontSize(TypographyHelper.getFontSize(this.appLanguage, 11))
        //   .fontColor(this.colors.textMuted)
        //   .fontStyle(FontStyle.Italic)
        //   .lineHeight(TypographyHelper.getLineHeight(this.appLanguage, 16))
        //   .layoutWeight(1)

        if (dua.sources && dua.sources.length > 0) {
          Row() {

            // Left side - sources
            Flex({
              wrap: FlexWrap.Wrap,
              justifyContent: FlexAlign.Start
            }) {
              ForEach(dua.sources, (src: DuaSource, i: number) => {
                Row({ space: 4 }) {
                  Image($r('app.media.ic_link'))
                    .width(10)
                    .height(10)
                    .fillColor(this.colors.accentGold)

                  Text(SourceParser.getLabel(src, this.appLanguage))
                    .fontSize(10)
                    .fontColor(this.colors.accentGold)
                    .fontWeight(FontWeight.Medium)
                }
                .padding({
                  left: 8,
                  right: 8,
                  top: 4,
                  bottom: 4
                })
                .backgroundColor(this.colors.tintSoft)
                .borderRadius(12)
                .border({
                  width: 1,
                  color: this.colors.borderSoft
                })
                .margin({
                  right: 6,
                  top: 6
                })
                .onClick(() => this.onSourceTap(src))
              }, (src: DuaSource, i: number) => `dsrc-${dua.id}-${i}`)
            }
            .layoutWeight(1)

            // Right side - bind prayer
            Text(L.get('bind_prayer', this.appLanguage))
              .fontSize(TypographyHelper.getFontSize(this.appLanguage, 11))
              .fontColor(this.colors.accentGold)
              .padding({
                left: 8,
                right: 8,
                top: 4,
                bottom: 4
              })
              .backgroundColor(this.colors.tintSoft)
              .borderRadius(8)
              .margin({ left: 8, top: 6 })
              .bindMenu(this.buildPrayerMenu(dua))
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Top)
          .margin({ top: 4 })
        }
      }
      .width('100%').alignItems(VerticalAlign.Center)

    }
    .width('100%')
    .padding(20)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(16)
    .border({ width: 1, color: this.colors.borderSoft })
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.05)', offsetY: 4 })
  }

  async toggleBind(dua: CompleteDua, prayerId: string) {
    const isBound = dua.boundPrayerIds.includes(prayerId);
    await DuaService.bindToPrayer(dua.id, prayerId, !isBound);
    this.loadData();
  }

  // ============================================================
  // Prayer bindings
  // ============================================================

  private categoryLabel(cat: string): string {
    if (cat === 'all') {
      return L.get('dua_cat_all', this.appLanguage);
    }
    if (cat === 'favorites') {
      return L.get('dua_cat_favorites', this.appLanguage);
    }
    return HadithSearchService.translate('category_' + cat, this.appLanguage);
  }

  private isFriday(): boolean {
    return new Date().getDay() === 5;
  }

  private getPrayerLabel(prayerId: string): string {
    if (prayerId === 'dhuhr' && this.isFriday()) {
      return L.get('prayer_jummah', this.appLanguage);
    }
    return L.get('prayer_' + prayerId, this.appLanguage);
  }

  private buildPrayerMenu(dua: CompleteDua): MenuElement[] {
    const prayerIds = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

    return prayerIds.map((id: string) => {
      const isBound = dua.boundPrayerIds.includes(id);
      const label = this.getPrayerLabel(id);
      // Prefix with checkmark if bound, else spaces for alignment
      const displayValue = isBound ? `✓  ${label}` : `     ${label}`;

      const item: MenuElement = {
        value: displayValue,
        action: () => {
          this.toggleBind(dua, id);
        }
      };
      return item;
    });
  }

  private getDuaTranslationLang(): string {
    if (this.duaTransLang === 'default' || this.duaTransLang === '') {
      return this.appLanguage;
    }
    return this.duaTransLang;
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
          url: 'pages/HadithDetailsPage',
          params: { id: hadithId }
        }).catch((e: Error) => console.error(JSON.stringify(e)));
        return;
      }
    }
    if (src.type === 'quran' && src.surah !== undefined && src.ayah !== undefined) {
      NavHelper.prepareForward();
      router.pushUrl({
        url: 'pages/SurahDetailsPage',
        params: { surahId: src.surah, startVerse: src.ayah, endVerse: src.ayah }
      }).catch((e: Error) => console.error(JSON.stringify(e)));
      return;
    }
    const title = L.get('hadith_evidence_title', this.appLanguage);
    const msg = src.display || src.id || 'Unknown Source';
    promptAction.showDialog({
      title: title,
      message: msg,
      buttons: [{ text: L.get('ok', this.appLanguage), color: this.colors.accentGold }]
    });
  }
}