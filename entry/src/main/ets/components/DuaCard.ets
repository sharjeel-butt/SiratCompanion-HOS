// entry/src/main/ets/components/DuaCard.ets

import { ThemeColors } from '../common/Theme';
import { L } from '../helper/LocalizationHelper';
import { DuaEntry } from '../data/Duas';

/**
 * Renders a single Dua: optional name header, then Arabic,
 * transliteration, and translation.
 *
 * Used by the LiveCountdownBanner when a fast starts or ends, and
 * ready to be reused by a future dedicated Duas tab.
 *
 * Reactivity: `currentLanguage` is passed as a @Prop rather than
 * read from AppStorage so the component re-renders reliably when
 * the language changes.
 */
@Component
export struct DuaCard {
  @Prop dua: DuaEntry;
  @Prop colors: ThemeColors;
  @Prop currentLanguage: string = 'en';
  /** Show the dua's name as a centered header. Default true. */
  @Prop showName: boolean = true;

  build() {
    Column() {
      if (this.showName) {
        Text(L.get(this.dua.nameKey, this.currentLanguage))
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.accentGold)
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ bottom: 12 })
      }

      // ---- Arabic (always shown) ----
      Text(this.dua.arabic)
        .fontSize(20)
        .fontColor(this.colors.textWhite)
        .textAlign(TextAlign.Center)
        .lineHeight(34)
        .width('100%')

      // ---- Transliteration + translation ----
      // Skipped when the UI is already Arabic — they would be
      // redundant with the source text.
      if (this.currentLanguage !== 'ar') {
        Text(this.dua.transliteration)
          .fontSize(12)
          .fontColor(this.colors.accentGold)
          .fontStyle(FontStyle.Italic)
          .textAlign(TextAlign.Center)
          .lineHeight(18)
          .margin({ top: 10 })
          .width('100%')

        Text(L.get(this.dua.translationKey, this.currentLanguage))
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