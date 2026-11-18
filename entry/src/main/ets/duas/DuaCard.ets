// entry/src/main/ets/components/DuaCard.ets

import { ThemeColors } from '../core/Theme';
import { CompleteDua, DuaSource } from './DuaModels';
import { TypographyHelper } from '../core/TypographyHelper';
import { NavHelper } from '../core/NavHelper';
import { router } from '@kit.ArkUI';

/**
 * Renders a single Dua for display: optional name header, then
 * Arabic, transliteration, and translation.
 *
 * This is the canonical display component. Used by the Home
 * LiveCountdownBanner (during Ramadan) and by the Ramadan details
 * page's Duas section. The full DuasPage uses a richer builder that
 * adds favorite toggles and prayer bindings.
 *
 * Reactivity: `currentLanguage` is passed as a @Prop rather than
 * read from AppStorage so the component re-renders reliably when
 * the language changes.
 */
@Component
export struct DuaCard {
  @Prop dua: CompleteDua;
  @Prop colors: ThemeColors;
  @Prop currentLanguage: string = 'en';
  @Prop showName: boolean = true;

  build() {
    Column() {
      if (this.showName) {
        Text(this.dua.translatedName)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.accentGold)
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ bottom: 12 })
      }

      // ---- Arabic ----
      Text(this.dua.arabic)

        .fontSize(TypographyHelper.getArabicFontSize(22))
        .fontFamily(TypographyHelper.getFont('ar', false))
        .fontColor(this.colors.textWhite)
        .textAlign(TextAlign.Center)
        .lineHeight(TypographyHelper.getArabicLineHeight(38))
        .width('100%')

      // ---- Transliteration + translation ----
      if (this.currentLanguage !== 'ar') {
        if (this.dua.transliteration &&
          this.dua.transliteration.length > 0) {
          Text(this.dua.transliteration)
            .fontSize(12)
            .fontColor(this.colors.accentGold)
            .fontStyle(FontStyle.Italic)
            .textAlign(TextAlign.Center)
            .lineHeight(18)
            .margin({ top: 10 })
            .width('100%')
        }

        Text(this.dua.translatedText)
          .fontSize(12)
          .fontColor(this.colors.textMuted)
          .textAlign(TextAlign.Center)
          .lineHeight(18)
          .margin({ top: 8 })
          .width('100%')
      }

      if (this.dua.sources && this.dua.sources.length > 0) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.dua.sources, (src: DuaSource, i: number) => {
            Text(this.sourceLabel(src))
              .fontSize(10)
              .fontColor(this.colors.accentGold)
              .backgroundColor(this.colors.tintSoft)
              .padding({
                left: 8,
                right: 8,
                top: 3,
                bottom: 3
              })
              .borderRadius(4)
              .margin({ right: 4, top: 4 })
              .onClick(() => this.onSourceTap(src))
          }, (src: DuaSource, i: number) => `src-${this.dua.id}-${i}`)
        }
        .width('100%')
        .margin({ top: 10 })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  private sourceLabel(src: DuaSource): string {
    if (src.type === 'external') {
      return src.display ?? '';
    }
    if (src.type === 'quran') {
      return `Quran ${src.surah}:${src.ayah}`;
    }
    // hadith
    return src.id ?? '';
  }

  private onSourceTap(src: DuaSource): void {
    if (src.type === 'external') {
      return;
    }
    if (src.type === 'quran' && src.surah !== undefined && src.ayah !== undefined) {
      NavHelper.prepareForward();
      router.pushUrl({
        url: 'pages/SurahDetailsPage',
        params: { surahId: src.surah, startVerse: src.ayah, endVerse: src.ayah }
      }).catch((e: Error) => console.error(JSON.stringify(e)));
    } else if (src.type === 'hadith' && src.id !== undefined) {
      NavHelper.prepareForward();
      router.pushUrl({
        url: 'pages/HadithDetailsPage',
        params: { id: src.id }
      }).catch((e: Error) => console.error(JSON.stringify(e)));
    }
  }
}