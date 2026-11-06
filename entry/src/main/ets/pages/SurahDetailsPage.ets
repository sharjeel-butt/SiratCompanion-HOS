// entry/src/main/ets/pages/SurahDetailsPage.ets

import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { ThemeColors, ThemeMode } from '../core/Theme';
import { PageTheme } from '../core/PageTheme';
import { L } from '../i18n/LocalizationHelper';
import { QuranService } from '../quran/QuranService';
import { CompleteSurah } from '../quran/QuranSurahModels';
import { TypographyHelper } from '../core/TypographyHelper';
import { STORAGE_KEY_LANGUAGE } from '../core/StorageKeys';

// --- FIX 1: Explicit interface instead of inline object literal type ---
interface SlicedContent {
  arabic: string;
  translation: string;
}

@Entry
@Component
struct SurahDetailsPage {
  @StorageLink(STORAGE_KEY_LANGUAGE) @Watch('onLangChanged') appLanguage: string = 'en';
  @State colors: ThemeColors = PageTheme.compute(ThemeMode.SYSTEM);
  @State allSurahs: CompleteSurah[] = [];
  @State currentIndex: number = 0;
  @State isLoading: boolean = true;
  // Pre-computed content for the current Surah (avoids multiple calls in render)
  @State currentArabic: string = '';
  @State currentTranslation: string = '';
  @State currentTitle: string = '';
  private startVerse: number = 1;
  private endVerse: number | null = null;

  async aboutToAppear() {
    await this.loadData();
  }

  onLangChanged() {
    this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    const params = router.getParams() as Record<string, Object>;

    const surahId = params ? (params['surahId'] as number || 1) : 1;
    this.startVerse = params ? (params['startVerse'] as number || 1) : 1;
    this.endVerse = params ? (params['endVerse'] as number || null) : null;

    const ctx = getContext(this) as common.UIAbilityContext;
    this.allSurahs = await QuranService.loadSurahs(ctx, this.appLanguage);

    const idx = this.allSurahs.findIndex((s: CompleteSurah): boolean => s.id === surahId);
    this.currentIndex = idx >= 0 ? idx : 0;

    this.updateContentForIndex(this.currentIndex, true);
    this.isLoading = false;
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

        Text(this.isLoading ? 'Loading...' : this.currentTitle)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textWhite)
          .layoutWeight(1)
          .textAlign(TextAlign.Start)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%').height(72).padding({ left: 16, right: 16 })
      .backgroundColor(this.colors.cardDark)

      if (this.isLoading) {
        LoadingProgress().width(40).height(40).color(this.colors.accentGold).margin({ top: 40 })
      } else {
        // Single page render using pre-computed state
        this.SurahPageContent()
      }
    }
    .width('100%').height('100%').backgroundColor(this.colors.primaryGreen)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  @Builder
  SurahPageContent() {
    Column() {
      // Surah Header
      Column() {
        Text(this.allSurahs[this.currentIndex].nameArabic)
          .fontSize(32).fontFamily(TypographyHelper.getQuranFont(this.appLanguage))
          .fontColor(this.colors.accentGold).margin({ bottom: 8 })
        Text(`${this.allSurahs[this.currentIndex].nameMeaning} · ${this.allSurahs[this.currentIndex].ayahCount} ${L.get(
          'ayahs', this.appLanguage)}`)
          .fontSize(14).fontColor(this.colors.textMuted)
      }
      .width('100%')
      .padding(24)
      .backgroundColor(this.colors.tintSubtle)
      .borderRadius(16)
      .margin({ bottom: 24 })

      Scroll() {
        Column() {
          // Arabic Text
          Text(this.currentArabic)
            .fontSize(TypographyHelper.getArabicFontSize(26))
            .fontFamily(TypographyHelper.getQuranFont(this.appLanguage))
            .fontColor(this.colors.textWhite)
            .lineHeight(TypographyHelper.getArabicLineHeight(50))
            .textAlign(TextAlign.Center)
            .width('100%')
            .padding({ bottom: 24 })

          Divider().color(this.colors.borderSoft).margin({ bottom: 24 })

          // Translation Text
          if (this.currentTranslation.trim().length > 0) {
            Text(this.currentTranslation)
              .fontSize(16)
              .fontFamily(TypographyHelper.getTranslationFont(this.appLanguage))
              .fontColor(this.colors.textLight)
              .lineHeight(28)
              .width('100%')
              .padding({ bottom: 40 })
          } else if (this.appLanguage === 'ar') {
            // Arabic users: no translation section at all — text is already Arabic
            // (Nothing rendered)
          } else {
            Text(L.get('translation_unavailable', this.appLanguage))
              .fontSize(14)
              .fontColor(this.colors.textMuted)
              .fontStyle(FontStyle.Italic)
              .width('100%')
              .padding({ bottom: 40 })
          }
        }
        .width('100%').padding({ left: 20, right: 20 })
      }
      .layoutWeight(1)

      // Paging Controls (Swipe alternative for reliability)
      Row({ space: 12 }) {
        // Previous
        Row({ space: 4 }) {
          Image($r('app.media.ic_chevron_right'))
            .width(14).height(14).fillColor(this.colors.accentGold)
            .rotate({ angle: 180 })
          Text(L.get('previous', this.appLanguage))
            .fontSize(13).fontColor(this.colors.accentGold).fontWeight(FontWeight.Medium)
        }
        .padding({
          left: 12,
          right: 12,
          top: 8,
          bottom: 8
        })
        .backgroundColor(this.colors.tintSubtle)
        .borderRadius(12)
        .opacity(this.currentIndex > 0 ? 1.0 : 0.3)
        .onClick(() => {
          if (this.currentIndex > 0) {
            this.currentIndex = this.currentIndex - 1;
            this.updateContentForIndex(this.currentIndex, false);
          }
        })

        Blank()

        // Next
        Row({ space: 4 }) {
          Text(L.get('next', this.appLanguage))
            .fontSize(13).fontColor(this.colors.accentGold).fontWeight(FontWeight.Medium)
          Image($r('app.media.ic_chevron_right'))
            .width(14).height(14).fillColor(this.colors.accentGold)
        }
        .padding({
          left: 12,
          right: 12,
          top: 8,
          bottom: 8
        })
        .backgroundColor(this.colors.tintSubtle)
        .borderRadius(12)
        .opacity(this.currentIndex < this.allSurahs.length - 1 ? 1.0 : 0.3)
        .onClick(() => {
          if (this.currentIndex < this.allSurahs.length - 1) {
            this.currentIndex = this.currentIndex + 1;
            this.updateContentForIndex(this.currentIndex, false);
          }
        })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(this.colors.cardDark)
    }
    .width('100%').height('100%')
  }

  // --- FIX 2: Explicit typed object literals, no shorthand, no inline types ---
  private getSlicedContent(surah: CompleteSurah): SlicedContent {
    const arArray: string[] = surah.arabicText.split('\n');
    const transArray: string[] = surah.translatedText ? surah.translatedText.split('\n') : [];

    if (this.startVerse > 1 || this.endVerse !== null) {
      const end = this.endVerse !== null ? this.endVerse : surah.ayahCount;
      const safeStart = Math.max(0, this.startVerse - 1);
      const safeEnd = Math.min(end, arArray.length);

      const arabic = arArray.slice(safeStart, safeEnd).join('\n');

      let translation = '';
      if (transArray.length > 0) {
        const safeTransEnd = Math.min(safeEnd, transArray.length);
        translation = transArray.slice(safeStart, safeTransEnd).join('\n');
      }

      const sliced: SlicedContent = {
        arabic: arabic,
        translation: translation
      };
      return sliced;
    }

    const full: SlicedContent = {
      arabic: surah.arabicText,
      translation: surah.translatedText || ''
    };
    return full;
  }

  private updateContentForIndex(index: number, isInitialLoad: boolean): void {
    if (index < 0 || index >= this.allSurahs.length) {
      return;
    }

    // If the user swiped to a different Surah, reset any verse-range slicing
    if (!isInitialLoad) {
      this.startVerse = 1;
      this.endVerse = null;
    }

    const surah = this.allSurahs[index];
    const sliced = this.getSlicedContent(surah);

    this.currentArabic = sliced.arabic;
    this.currentTranslation = sliced.translation;
    this.currentTitle = surah.nameTransliteration;
  }
}