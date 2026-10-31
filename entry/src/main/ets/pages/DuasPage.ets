import { common } from '@kit.AbilityKit';
import { ThemeColors, ThemeMode } from '../common/Theme';
import { PageTheme } from '../common/PageTheme';
import { L } from '../i18n/LocalizationHelper';
import { DuaService } from '../helper/DuaService';
import { CompleteDua } from '../models/DuaModels';
import { TypographyHelper } from '../helper/TypographyHelper';
import { router } from '@kit.ArkUI';

@Entry
@Component
struct DuasPage {
  @StorageLink('app_language') @Watch('onLangChanged') appLanguage: string = 'en';
  @State colors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);
  @State duas: CompleteDua[] = [];
  @State filteredDuas: CompleteDua[] = [];
  @State searchQuery: string = '';
  @State activeCategory: string = 'all';
  @State isLoading: boolean = true;
  @State filterPrayer: string = '';
  @State filterCategory: string = '';
  private categories: string[] = ['all', 'favorites', 'forgiveness', 'distress', 'travel'];

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

  async loadData() {
    this.isLoading = true;
    const ctx = getContext(this) as common.UIAbilityContext;
    this.duas = await DuaService.loadDuas(ctx, this.appLanguage);

    // Dynamic categories — extract all unique categories from JSON
    const uniqueCategories = new Set<string>();
    uniqueCategories.add('all');
    uniqueCategories.add('favorites');

    this.duas.forEach((d: CompleteDua) => {
      uniqueCategories.add(d.category);
    });

    this.categories = Array.from(uniqueCategories);

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
          // Active prayer filter pill
          if (this.filterPrayer.length > 0) {
            Row({ space: 4 }) {
              Text(`${L.get('duas_for', this.appLanguage)} ${this.getPrayerLabel(this.filterPrayer)}`)
                .fontSize(TypographyHelper.getFontSize(this.appLanguage, 13))
                .fontColor(this.colors.textOnAccent)
              Text('✕').fontSize(12).fontColor(this.colors.textOnAccent).margin({ left: 4 })
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
          ForEach(this.categories, (cat: string) => {
            Text(L.get('dua_cat_' + cat, this.appLanguage))
              .fontSize(TypographyHelper.getFontSize(this.appLanguage, 13))
              .fontColor(this.activeCategory === cat ? this.colors.textOnAccent : this.colors.textMuted)
              .backgroundColor(this.activeCategory === cat ? this.colors.accentGold : this.colors.cardDark)
              .padding({
                left: 16,
                right: 16,
                top: 6,
                bottom: 6
              })
              .borderRadius(16)
              .onClick(() => {
                this.activeCategory = cat;
                this.applyFilters();
              })
          })
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
          })
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
          .width(20).height(20)
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
        Text(dua.translatedReference)
          .fontSize(TypographyHelper.getFontSize(this.appLanguage, 11))
          .fontColor(this.colors.textMuted)
          .fontStyle(FontStyle.Italic)
          .lineHeight(TypographyHelper.getLineHeight(this.appLanguage, 16))
          .layoutWeight(1)

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
          .bindMenu(this.buildPrayerMenu(dua))
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

  // ============================================================
  // Prayer bindings
  // ============================================================

  async toggleBind(dua: CompleteDua, prayerId: string) {
    const isBound = dua.boundPrayerIds.includes(prayerId);
    await DuaService.bindToPrayer(dua.id, prayerId, !isBound);
    this.loadData();
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
}