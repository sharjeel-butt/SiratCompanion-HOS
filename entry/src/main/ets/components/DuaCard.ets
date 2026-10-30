// entry/src/main/ets/components/DuaCard.ets

import { ThemeColors } from '../common/Theme';
import { CompleteDua } from '../models/DuaModels';
import { TypographyHelper } from '../helper/TypographyHelper';

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
        .fontSize(22)
        .fontFamily(TypographyHelper.getFont('ar', false))
        .fontColor(this.colors.textWhite)
        .textAlign(TextAlign.Center)
        .lineHeight(38)
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
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }
}