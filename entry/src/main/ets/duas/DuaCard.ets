// entry/src/main/ets/components/DuaCard.ets

import { ThemeColors } from '../core/Theme';
import { CompleteDua, DuaSource } from './DuaModels';
import { TypographyHelper } from '../core/TypographyHelper';
import { NavHelper } from '../core/NavHelper';
import { promptAction, router } from '@kit.ArkUI';
import { SourceParser } from '../core/SourceParser';
import { L } from '../i18n/LocalizationHelper';

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
          .fontFamily(TypographyHelper.getTranslationFont(this.currentLanguage))
          .fontColor(this.colors.textMuted)
          .textAlign(TextAlign.Center)
          .lineHeight(18)
          .margin({ top: 8 })
          .width('100%')
      }

      if (this.dua.sources && this.dua.sources.length > 0) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.dua.sources, (src: DuaSource, i: number) => {
            Row({ space: 4 }) {
              Image($r('app.media.ic_link')) // Using globe icon as a link indicator
                .width(10).height(10)
                .fillColor(this.colors.accentGold)
              Text(SourceParser.getLabel(src, this.currentLanguage))
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
            .border({ width: 1, color: this.colors.borderSoft })
            .margin({ right: 6, top: 8 })
            .onClick(() => this.onSourceTap(src))
          }, (src: DuaSource, i: number) => `src-${this.dua?.id}-${i}`)
        }
        .width('100%').margin({ top: 4 })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  private sourceLabel(src: DuaSource): string {
    return SourceParser.getLabel(src, this.currentLanguage);
  }

  private onSourceTap(src: DuaSource): void {
    // 1. Handle Hadith Sources (Navigate to Hadith Details)
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

    // 2. Handle Quran Sources (Navigate to Surah Details)
    if (src.type === 'quran' && src.surah !== undefined && src.ayah !== undefined) {
      NavHelper.prepareForward();
      router.pushUrl({
        url: 'pages/SurahDetailsPage',
        params: { surahId: src.surah, startVerse: src.ayah, endVerse: src.ayah }
      }).catch((e: Error) => console.error(JSON.stringify(e)));
      return;
    }

    // 3. Fallback for External/Malformed Sources (Show Localized Dialog)
    const title = L.get('hadith_evidence_title', this.currentLanguage);
    const msg = src.display || src.id || 'Unknown Source';

    promptAction.showDialog({
      title: title,
      message: msg,
      buttons: [{ text: L.get('ok', this.currentLanguage), color: this.colors.accentGold }]
    });
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
}