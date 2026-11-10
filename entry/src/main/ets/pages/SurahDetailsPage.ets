// entry/src/main/ets/pages/SurahDetailsPage.ets

import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { ThemeColors, ThemeMode } from '../core/Theme';
import { PageTheme } from '../core/PageTheme';
import { L } from '../i18n/LocalizationHelper';
import { QuranService } from '../quran/QuranService';
import { CompleteSurah, Verse } from '../quran/QuranSurahModels';
import { TypographyHelper } from '../core/TypographyHelper';
import { STORAGE_KEY_LANGUAGE } from '../core/StorageKeys';

type ReadingMode = 'translation' | 'reading' | 'mushaf';

@Entry
@Component
struct SurahDetailsPage {
  @StorageLink(STORAGE_KEY_LANGUAGE) @Watch('onLangChanged') appLanguage: string = 'en';
  @State colors: ThemeColors = PageTheme.compute(ThemeMode.SYSTEM);

  @State allSurahs: CompleteSurah[] = [];
  @State currentIndex: number = 0;
  @State surah: CompleteSurah | null = null;

  // The filtered list of verses currently being displayed
  @State displayVerses: Verse[] = [];

  @State readingMode: ReadingMode = 'translation';
  @State isLoading: boolean = true;
  @State mushafCurrentPage: number = 1;
  @State currentMushafSurahName: string = '';
  private allPages: number[] = [];

  private startVerse: number = 1;
  private endVerse: number | null = null;
  // Aligned with the canonical default used everywhere else in the
  // app — QuranPage falls back to 'indopak' for the same field, and
  // UserBackupService.seedAppStorageFromPrefs() uses 'indopak' as the
  // default when re-seeding after a restore. Before this change the
  // cold-start experience showed 'uthmani' (QPC Hafs) in the verse
  // reader and 'indopak' (JameelNoori Nastaliq) in the surah list.
  private activeScript: string = AppStorage.get<string>('active_quran_script') ?? 'indopak';


  async aboutToAppear() {
    await this.loadInitialData();
  }

  onLangChanged() {
    this.loadInitialData();
  }

  private async loadInitialData(): Promise<void> {
    this.isLoading = true;
    const params = router.getParams() as Record<string, Object>;

    const targetId = params ? (params['surahId'] as number || 1) : 1;

    // Safely parse nulls (for Recitation Guide tasks like Al-Imran 52 or 64)
    const paramStart = params ? params['startVerse'] : null;
    const paramEnd = params ? params['endVerse'] : null;

    this.startVerse = typeof paramStart === 'number' ? paramStart : 1;
    this.endVerse = typeof paramEnd === 'number' ? paramEnd : null;

    const ctx = getContext(this) as common.UIAbilityContext;

    // Load all Surahs from the JSON file
    this.allSurahs = await QuranService.loadSurahs(ctx, this.appLanguage);

    // Find the requested Surah
    const idx = this.allSurahs.findIndex((s: CompleteSurah): boolean => s.id === targetId);
    this.currentIndex = idx >= 0 ? idx : 0;

    // Process the verses for the current Surah
    this.processCurrentSurah(true);

    this.isLoading = false;
  }

  private processCurrentSurah(isInitial: boolean): void {
    if (this.currentIndex < 0 || this.currentIndex >= this.allSurahs.length) return;

    this.surah = this.allSurahs[this.currentIndex];

    // FIX: Assign the Mushaf title so the top bar isn't blank in Mushaf mode
    this.currentMushafSurahName = this.appLanguage === 'ar'
      ? `سورة ${this.surah.nameArabic}`
      : this.surah.nameTransliteration;

    // Reset verse limits if paging to a new Surah manually
    if (!isInitial) {
      this.startVerse = 1;
      this.endVerse = null;
    }

    // Filter verses based on startVerse and endVerse (for Recitation Guide)
    if (this.startVerse > 1 || this.endVerse !== null) {
      const end = this.endVerse !== null ? this.endVerse : this.surah.ayahCount;
      this.displayVerses = this.surah.verses.filter(v => v.ayah >= this.startVerse && v.ayah <= end);
    } else {
      // Standard full Surah reading
      // If it's Surah 1 (Al-Fatihah), hide verse 1 (Bismillah) because it's shown as a header
      if (this.surah.id === 1) {
        this.displayVerses = this.surah.verses.filter(v => v.ayah !== 1);
      } else {
        this.displayVerses = this.surah.verses;
      }
    }
  }

  private goToNext(): void {
    if (this.currentIndex < this.allSurahs.length - 1) {
      this.currentIndex++;
      this.processCurrentSurah(false);
    }
  }

  private goToPrevious(): void {
    if (this.currentIndex > 0) {
      this.currentIndex--;
      this.processCurrentSurah(false);
    }
  }

  private stripTrailingArabicNumber(text: string): string {
    return text
      .replace(/[\u0660-\u0669]+$/, '') // Remove Arabic numbers
      .replace(/[\r\n]+/g, ' ')         // Remove hidden newlines
      .replace(/\s+/g, ' ')             // Collapse multiple spaces
      .trim();
  }

  private toArabicNumerals(num: number): string {
    const arabicDigits: string[] = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return num.toString().split('').map((d: string): string => arabicDigits[parseInt(d, 10)]).join('');
  }

  private isRtl(): boolean {
    return L.isRtlLang(this.appLanguage);
  }



  build() {
    Column() {
      // ==========================================
      // 1. TOP BAR
      // ==========================================
      Row({ space: 12 }) {
        Row() {
          Image($r('app.media.ic_chevron_right')).width(20).height(20)
            .fillColor(this.colors.textWhite)
            .rotate({ angle: this.isRtl() ? 0 : 180 })
        }
        .width(40).height(40).justifyContent(FlexAlign.Center)
        .borderRadius(20).backgroundColor(this.colors.tintSubtle) // Note: fixed tintSoft -> tintSubtle
        .onClick(() => router.back())

        Column() {
          Text(this.isLoading ? '...' :
            (this.readingMode === 'mushaf' ? this.currentMushafSurahName : this.getSurahTitle()))
            .fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontFamily(this.appLanguage === 'ar' ? TypographyHelper.getQuranFontByScript(this.activeScript) : 'Outfit')

          if (this.readingMode === 'mushaf') {
            Text(`Page ${this.mushafCurrentPage} / 604`)
              .fontSize(10).fontColor(this.colors.accentGold).margin({ top: 2 })
          } else {
            Text(this.isLoading ? '' : `${this.tr('juz_label')} ${Math.ceil(
              this.surah!.id / 2)} · ${this.surah!.revelationPlace} · ${this.surah!.ayahCount} ${this.tr('ayahs')}`)
              .fontSize(10).fontColor(this.colors.textMuted).margin({ top: 2 })
          }
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)

      }
      .width('100%').height(64).padding({ left: 16, right: 16 })
      .backgroundColor(this.colors.cardDark)
      .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)

      // ==========================================
      // 2. MODE TOGGLE
      // ==========================================
      Row() {
        this.ModeTab('translation', this.tr('mode_translation'))
        this.ModeTab('reading', this.tr('mode_reading'))
        this.ModeTab('mushaf', this.tr('mode_mushaf'))
      }
      .width('95%').height(40)
      .backgroundColor(this.colors.tintSubtle)
      .borderRadius(20)
      .margin({ top: 16, bottom: 8 })
      .alignSelf(ItemAlign.Center)
      .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)

      // ==========================================
      // 3. CONTENT AREA
      // ==========================================
      if (this.isLoading || this.surah === null) {
        LoadingProgress().width(40).height(40).color(this.colors.accentGold).margin({ top: 40 })
      } else {
        if (this.readingMode === 'mushaf') {
          this.MushafView()
        } else {
          this.VerseByVerseView()
        }
      }

      // ==========================================
      // 4. PAGING CONTROLS
      // ==========================================
      if (!this.isLoading && this.surah !== null) {
        Row() {
          Row({ space: 6 }) {
            Image($r('app.media.ic_chevron_right'))
              .width(14).height(14).fillColor(this.colors.accentGold)
              .rotate({ angle: this.isRtl() ? 0 : 180 })
            Text(this.tr('previous_surah'))
              .fontSize(13).fontColor(this.colors.accentGold).fontWeight(FontWeight.Medium)
          }
          .layoutWeight(1).height(44).justifyContent(FlexAlign.Center)
          .opacity(this.currentIndex > 0 ? 1.0 : 0.3)
          .onClick(() => this.goToPrevious())

          Row({ space: 6 }) {
            Text(this.tr('next_surah'))
              .fontSize(13).fontColor(this.colors.accentGold).fontWeight(FontWeight.Medium)
            Image($r('app.media.ic_chevron_right'))
              .width(14).height(14).fillColor(this.colors.accentGold)
              .rotate({ angle: this.isRtl() ? 180 : 0 })
          }
          .layoutWeight(1).height(44).justifyContent(FlexAlign.Center)
          .opacity(this.currentIndex < this.allSurahs.length - 1 ? 1.0 : 0.3)
          .onClick(() => this.goToNext())
        }
        .width('100%').padding({ left: 16, right: 16, bottom: 8 })
        .backgroundColor(this.colors.cardDark)
        .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
      }
    }
    .width('100%').height('100%').backgroundColor(this.colors.primaryGreen)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  // ==========================================
  // UI BUILDERS
  // ==========================================

  @Builder
  ModeTab(mode: ReadingMode, label: string) {
    Text(label)
      .fontSize(12).fontWeight(FontWeight.Medium)
      .fontColor(this.readingMode === mode ? this.colors.textWhite : this.colors.textMuted)
      .backgroundColor(this.readingMode === mode ? this.colors.cardDark : Color.Transparent)
      .layoutWeight(1).height(36).textAlign(TextAlign.Center)
      .borderRadius(18).margin(2)
      .onClick(() => this.readingMode = mode)
  }

  @Builder
  VerseByVerseView() {
    Scroll() {
      Column() {
        // 1. Bismillah Header (Show for ALL surahs except Surah 9)
        if (this.surah!.id !== 9) {
          Text("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ")
            .fontSize(TypographyHelper.getArabicFontSize(26))
            .fontFamily(TypographyHelper.getQuranFontByScript(this.activeScript))
            .fontColor(this.colors.accentGold)
            .textAlign(TextAlign.Center)
            .width('100%').padding({ top: 20, bottom: 20 })
        }

        // 2. Verses
        ForEach(this.displayVerses, (verse: Verse, index: number) => {
          Column() {
            // Arabic Text
            Text(this.getFormattedVerseForReading(verse))
              .fontSize(TypographyHelper.getArabicFontSize(26))
              .fontFamily(TypographyHelper.getQuranFontByScript(this.activeScript))
              .fontColor(this.colors.textWhite)
              .lineHeight(TypographyHelper.getArabicLineHeight(60))
              .textAlign(TextAlign.Start) // Aligns to Right in RTL
              .direction(Direction.Rtl)   // Forces RTL layout
              .width('100%')
              .padding({ top: 12, bottom: 12 })

            // Translation (Only in 'translation' mode)
            if (this.readingMode === 'translation' && this.getTranslationForVerse(verse).trim().length > 0) {
              Text(this.getTranslationForVerse(verse))
                .fontSize(15)
                .fontFamily(TypographyHelper.getTranslationFont(this.appLanguage))
                .fontColor(this.colors.textMuted)
                .lineHeight(22)
                .textAlign(TextAlign.Center)
                .width('100%')
                .padding({ top: 4, bottom: 20 })
            }
          }
          .width('100%')
        }, (verse: Verse) => `v-${this.surah?.id}-${verse.ayah}`)

        Column().height(40)
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Auto)
  }

  private getFormattedVerseForReading(verse: Verse): string {
    // 1. Clean the Arabic text
    const cleanArabic = this.stripTrailingArabicNumber(verse.arabic);
    const arabicNum = this.toArabicNumerals(verse.ayah);

    // 2. Add the Rub el Hizb star with non-breaking spaces (Exactly like Mushaf)
    const marker = `\u00A0\u200F۞`;

    return cleanArabic + marker;
  }

  @Builder
  VerseItem(verse: Verse, index: number) {
    Column() {
      if (index > 0) {
        Divider().color(this.colors.borderSoft).margin({ top: 16, bottom: 16 })
      }

      // Use Stack to overlay the number circle, while giving the Text 100% width.
      // This is the EXACT same layout logic used in the Mushaf view.
      Stack({ alignContent: Alignment.TopStart }) {

        // 1. Arabic Text (Exact properties as MushafView)
        Text(this.stripTrailingArabicNumber(verse.arabic))
          .fontSize(TypographyHelper.getArabicFontSize(
            TypographyHelper.QURAN_FONT_SIZE_VERSE))
          .fontFamily(TypographyHelper.getQuranFontByScript(this.activeScript))
          .fontColor(this.colors.textWhite)
          .lineHeight(TypographyHelper.getArabicLineHeight(
            TypographyHelper.QURAN_LINE_HEIGHT_VERSE))
          .textAlign(TextAlign.Start) // Aligns to Right in RTL
          .direction(Direction.Rtl)   // Forces RTL layout
          .width('100%')
          // Add padding on the left so the text doesn't overlap the circle
          .padding({ left: 48, right: 0 })

        // 2. Verse Number Circle (Floating on the left)
        Stack({ alignContent: Alignment.Center }) {
          Circle()
            .width(28).height(28)
            .fill(Color.Transparent)
            .stroke(this.colors.textMuted)
            .strokeWidth(1)

          Text(`${verse.ayah}`)
            .fontSize(12)
            .fontColor(this.colors.textMuted)
            .fontWeight(FontWeight.Medium)
            .textAlign(TextAlign.Center)
            .translate({ y: -1.5 })
        }
        .width(28).height(28)
        .margin({ top: 8, left: 8 }) // Position on the left
      }
      .width('100%')

      // 3. Translation (Only in 'translation' mode)
      if (this.readingMode === 'translation' && this.getTranslationForVerse(verse).trim().length > 0) {
        Text(this.getTranslationForVerse(verse))
          .fontSize(15)
          .fontFamily(TypographyHelper.getTranslationFont(this.appLanguage))
          .fontColor(this.colors.textMuted)
          .lineHeight(22)
          .textAlign(TextAlign.Center)
          .width('100%')
          .padding({ top: 20, bottom: 16 })
      }
    }
    .width('100%').padding({ left: 20, right: 20 })
  }

  private getTranslationForVerse(verse: Verse): string {
    if (!verse.translations) return '';
    return verse.translations[this.appLanguage] || verse.translations['en'] || '';
  }

  @Builder
  MushafView() {
    Scroll() {
      Column() {
        // Ornate Header
        Stack() {
          Column()
            .width('100%').height(50)
            .border({ width: 1, color: this.colors.accentGold })
            .borderRadius(8)
            .backgroundColor(this.colors.tintSubtle)
          Text(this.surah?.nameArabic || '')
            .fontSize(TypographyHelper.getArabicFontSize(TypographyHelper.SURAH_HEADER_FONT_SIZE))
            .fontFamily(TypographyHelper.getQuranFontByScript(this.activeScript))
            .fontColor(this.colors.accentGold)
        }
        .width('95%').margin({ top: 16, bottom: 24 })

        // Bismillah (Show for ALL surahs except Surah 9)
        if (this.surah && this.surah.id !== 9) {
          Text("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ")
            .fontSize(TypographyHelper.getArabicFontSize(TypographyHelper.BISMILLAH_FONT_SIZE))
            .fontFamily(TypographyHelper.getQuranFontByScript(this.activeScript))
            .lineHeight(TypographyHelper.getArabicLineHeight(TypographyHelper.BISMILLAH_LINE_HEIGHT))
            .fontColor(this.colors.textWhite)
            .textAlign(TextAlign.Center)
            .width('100%').margin({ bottom: 24 })
        }

        // Continuous Text
        Text(this.buildMushafText())
        // FIX: Uses the new increased MUSHAF font size and line height
          .fontSize(TypographyHelper.getArabicFontSize(TypographyHelper.QURAN_FONT_SIZE_MUSHAF))
          .fontFamily(TypographyHelper.getQuranFontByScript(this.activeScript))
          .fontColor(this.colors.textWhite)
          .lineHeight(TypographyHelper.getArabicLineHeight(TypographyHelper.QURAN_LINE_HEIGHT_MUSHAF))
          .textAlign(TextAlign.Start) // Aligns to the Right in RTL
          .direction(Direction.Rtl)   // Forces RTL layout
          .width('100%').padding({ left: 20, right: 20 })

        Column().height(40)
      }
      .width('100%')
    }
    .layoutWeight(1)
    .scrollBar(BarState.Auto)
  }

  private tr(key: string): string {
    return L.get(key, this.appLanguage);
  }

  private buildMushafText(): string {
    if (!this.surah || this.displayVerses.length === 0) {
      return '';
    }
    let text = '';
    for (const v of this.displayVerses) {
      // Remove the embedded Arabic numbers from the JSON text
      const cleanArabic = this.stripTrailingArabicNumber(v.arabic);
      const arabicNum = this.toArabicNumerals(v.ayah);

      // Add the Rub el Hizb star with non-breaking spaces
      const marker = `\u00A0\u200F۞ ${arabicNum}\u200F\u00A0`;

      text += cleanArabic + marker;
    }
    return text;
  }

  private getSurahTitle(): string {
    if (!this.surah) return '';
    if (this.appLanguage === 'ar') {
      return `سورة ${this.surah.nameArabic}`; // e.g., "سورة الفاتحة"
    }
    return this.surah.nameTransliteration; // e.g., "Al-Fatihah"
  }
}