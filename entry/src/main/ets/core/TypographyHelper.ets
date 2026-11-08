// entry/src/main/ets/helper/TypographyHelper.ets

import { font } from '@kit.ArkUI';
import { AppLogger } from './AppLogger';

/**
 * Per-language typography metrics.
 *
 * Two independent scale factors, applied at the call site instead of
 * hard-coded per page:
 *
 *   lineHeightScale  — multiplier on the caller's base lineHeight.
 *                      Non-Latin scripts extend above and/or below
 *                      the em-square (Arabic diacritics, Indic
 *                      matras, CJK ideographs filling the square),
 *                      so they need a taller line to prevent glyph
 *                      clipping and cramped-looking text.
 *
 *   fontSizeScale    — multiplier on the caller's base fontSize.
 *                      Used to match visual weight across scripts —
 *                      CJK ideographs occupy more of the em-square
 *                      than Latin at the same point size, so a
 *                      slightly smaller value reads as visually
 *                      "the same size".
 *
 * When adding a new language to the app, add its entry here. No page
 * needs editing — every Text that uses getLineHeight() / getFontSize()
 * automatically picks up the new baseline.
 *
 * Values were chosen from HarmonyOS typography guidance plus the
 * published metrics for each script family. Adjust the individual
 * numbers freely — the framework does not depend on specific values,
 * only on the map being non-empty and returning sane multipliers.
 */
interface LanguageMetrics {
  lineHeightScale: number;
  fontSizeScale: number;
}


const LANGUAGE_METRICS: Record<string, LanguageMetrics> = {
  // ---- Latin / Cyrillic / Greek (baseline) ----
  'en': { lineHeightScale: 1.00, fontSizeScale: 1.00 },
  'fr': { lineHeightScale: 1.00, fontSizeScale: 1.00 },
  'de': { lineHeightScale: 1.00, fontSizeScale: 1.00 },
  'es': { lineHeightScale: 1.00, fontSizeScale: 1.00 },
  'it': { lineHeightScale: 1.00, fontSizeScale: 1.00 },
  'id': { lineHeightScale: 1.00, fontSizeScale: 1.00 },
  'ms': { lineHeightScale: 1.00, fontSizeScale: 1.00 },
  'tr': { lineHeightScale: 1.00, fontSizeScale: 1.00 },
  'sw': { lineHeightScale: 1.00, fontSizeScale: 1.00 },
  'ha': { lineHeightScale: 1.00, fontSizeScale: 1.00 },
  'az': { lineHeightScale: 1.00, fontSizeScale: 1.00 },
  'uz': { lineHeightScale: 1.00, fontSizeScale: 1.00 },
  'ru': { lineHeightScale: 1.02, fontSizeScale: 1.00 },

  // ---- Arabic script ----
  // Arabic diacritics (fatha, kasra, shadda, sukun) extend above
  // and below the baseline. Urdu Nastaliq additionally hangs below.
  'ar': { lineHeightScale: 1.15, fontSizeScale: 1.00 },
  'fa': { lineHeightScale: 1.15, fontSizeScale: 1.00 },
  'ur': { lineHeightScale: 1.20, fontSizeScale: 1.00 },
  'ps': { lineHeightScale: 1.20, fontSizeScale: 1.00 },

  // ---- CJK ----
  // Ideographs fill the em-square fully. Slightly smaller font size
  // matches Latin visual weight; slightly taller line prevents the
  // glyphs from touching.
  'zh': { lineHeightScale: 1.05, fontSizeScale: 0.95 },
  'ja': { lineHeightScale: 1.05, fontSizeScale: 0.95 },
  'ko': { lineHeightScale: 1.10, fontSizeScale: 0.95 },

  // ---- Indic ----
  // Matras extend above and below; conjuncts stack horizontally at
  // the same baseline, so the line must be tall enough not to clip
  // either the top matra or the bottom vowel stroke.
  'hi': { lineHeightScale: 1.20, fontSizeScale: 1.00 },
  'mr': { lineHeightScale: 1.20, fontSizeScale: 1.00 },
  'bn': { lineHeightScale: 1.25, fontSizeScale: 1.00 },
  'ta': { lineHeightScale: 1.30, fontSizeScale: 1.00 },
  'te': { lineHeightScale: 1.28, fontSizeScale: 1.00 },
  'kn': { lineHeightScale: 1.28, fontSizeScale: 1.00 },
  'ml': { lineHeightScale: 1.25, fontSizeScale: 1.00 },
  'si': { lineHeightScale: 1.25, fontSizeScale: 1.00 },

  // ---- Southeast Asian ----
  'th': { lineHeightScale: 1.20, fontSizeScale: 1.00 },
  'lo': { lineHeightScale: 1.20, fontSizeScale: 1.00 },
  'km': { lineHeightScale: 1.25, fontSizeScale: 1.00 },
};


const DEFAULT_METRICS: LanguageMetrics = {
  lineHeightScale: 1.00,
  fontSizeScale: 1.00
};

/** Arabic font metrics — used for Arabic glyphs rendered inside a
 *  non-Arabic UI (e.g. the Dua card showing Arabic text under an
 *  English title). The GLYPHS are Arabic regardless of UI language,
 *  so Arabic metrics apply. */
const ARABIC_METRICS: LanguageMetrics = {
  lineHeightScale: 1.15,
  fontSizeScale: 1.00
};

export class TypographyHelper {
  /** Font size for verse-by-verse text (Reading/Translation modes). */
  static readonly QURAN_FONT_SIZE_VERSE: number = 26;
  /** Base line height for verse-by-verse text. */
  static readonly QURAN_LINE_HEIGHT_VERSE: number = 60;
  /** Font size for continuous Mushaf text (Increased for readability). */
  static readonly QURAN_FONT_SIZE_MUSHAF: number = 32;
  /** Base line height for continuous Mushaf text. */
  static readonly QURAN_LINE_HEIGHT_MUSHAF: number = 75;
  /** Font size for the Bismillah header. */
  static readonly BISMILLAH_FONT_SIZE: number = 26;
  /** Base line height for the Bismillah header. */
  static readonly BISMILLAH_LINE_HEIGHT: number = 60;
  /** Font size for the Surah header ornament in Mushaf view. */
  static readonly SURAH_HEADER_FONT_SIZE: number = 22;
  /**
   * Register custom fonts. Call this once in EntryAbility.
   */
  static init(): void {
    try {
      // Explicitly typing the objects to satisfy ArkTS strict mode (Rulebook §C)
      const outfit: font.FontOptions = { familyName: 'Outfit', familySrc: $rawfile('fonts/Outfit-Regular.ttf') };
      const outfitBold: font.FontOptions = { familyName: 'Outfit-Bold', familySrc: $rawfile('fonts/Outfit-Bold.ttf') };
      const amiri: font.FontOptions = { familyName: 'Amiri', familySrc: $rawfile('fonts/Amiri-Regular.ttf') };
      const amiriBold: font.FontOptions = { familyName: 'Amiri-Bold', familySrc: $rawfile('fonts/Amiri-Bold.ttf') };

      const nastaliq: font.FontOptions = { familyName: 'NotoNastaliqUrdu', familySrc: $rawfile('fonts/NotoNastaliqUrdu-Regular.ttf') };
      const amiriQuran: font.FontOptions = { familyName: 'AmiriQuran', familySrc: $rawfile('fonts/AmiriQuran-Regular.ttf') };
      const kemenag: font.FontOptions = { familyName: 'LPMQIsepMisbah', familySrc: $rawfile('fonts/LPMQ-Regular.ttf') };
      const kfgqpcWarsh: font.FontOptions = { familyName: 'KFGQPCWarsh', familySrc: $rawfile('fonts/KFGQPC-Regular.ttf') };
      const bengali: font.FontOptions = { familyName: 'NotoSansBengali', familySrc: $rawfile('fonts/NotoSansBengali-Regular.ttf') };
      const chinese: font.FontOptions = { familyName: 'NotoSansSC', familySrc: $rawfile('fonts/NotoSansSC-Regular.ttf') };

      const hafsArabic: font.FontOptions = {familyName: 'HafsArabic', familySrc: $rawfile('fonts/HafsArabic-Regular.ttf') };
      const jameelNoori: font.FontOptions =
        { familyName: 'JameelNoori', familySrc: $rawfile('fonts/JameelNooriNastaleeq.ttf') };
      const qpcHafs: font.FontOptions = { familyName: 'QPC_Hafs', familySrc: $rawfile('fonts/QPC-Hafs.ttf') };
      font.registerFont(qpcHafs);
      font.registerFont(jameelNoori);
      font.registerFont(hafsArabic);
      font.registerFont(outfit);
      font.registerFont(outfitBold);
      font.registerFont(amiri);
      font.registerFont(amiriBold);
      font.registerFont(nastaliq);
      font.registerFont(amiriQuran);
      font.registerFont(kemenag);
      font.registerFont(kfgqpcWarsh);
      font.registerFont(bengali);
      font.registerFont(chinese);

      AppLogger.info('TypographyHelper', 'All fonts registered successfully.');
    } catch (err) {
      AppLogger.error('TypographyHelper', `Font registration failed: ${JSON.stringify(err)}`);
    }
  }

  /**
   * Returns the appropriate font family string.
   *
   * Amiri (Naskh) is used for both Arabic and Urdu. Traditional
   * Urdu Nastaliq would require a separate font (~600 KB) which is
   * not bundled; Naskh is fully legible and standard on screen.
   * Bengali relies on the system's Noto Sans Bengali via the
   * `sans-serif` fallback suffix.
   */
  static getFont(lang: string, isBold: boolean = false): string {
    if (lang === 'ar' || lang === 'ur') {
      return isBold ? 'Amiri-Bold, sans-serif' : 'Amiri, sans-serif';
    }
    return isBold ? 'Outfit-Bold, sans-serif' : 'Outfit, sans-serif';
  }

  // ============================================================
  // SCALING — use these instead of hard-coded lineHeight / fontSize
  // ============================================================

  /**
   * Scale a base lineHeight for the given UI language.
   *
   *   // Before:
   *   .lineHeight(18)
   *
   *   // After:
   *   .lineHeight(TypographyHelper.getLineHeight(this.currentLanguage, 18))
   *
   * For Latin UI languages this returns the base unchanged (×1.0),
   * so the current pixel-perfect layout is preserved. For scripts
   * that need more vertical room the value is increased automatically.
   */
  static getLineHeight(lang: string, baseVp: number): number {
    const metrics = LANGUAGE_METRICS[lang] || DEFAULT_METRICS;
    return baseVp * metrics.lineHeightScale;
  }

  /**
   * Scale a base fontSize for the given UI language.
   *
   * For most languages this returns the base unchanged. CJK returns
   * a slightly smaller value so ideographs don't look larger than
   * Latin text at the same nominal point size.
   *
   *   // Before:
   *   .fontSize(14)
   *
   *   // After:
   *   .fontSize(TypographyHelper.getFontSize(this.currentLanguage, 14))
   */
  static getFontSize(lang: string, baseFp: number): number {
    const metrics = LANGUAGE_METRICS[lang] || DEFAULT_METRICS;
    return baseFp * metrics.fontSizeScale;
  }

  /**
   * Scale a lineHeight for Arabic glyphs shown inside a non-Arabic UI.
   *
   * Use this for the ARABIC text in a Dua card, a Quranic verse, or
   * any religious text whose glyphs are Arabic regardless of the UI
   * language. Always applies Arabic metrics, even when the UI is
   * English or Chinese.
   *
   *   .lineHeight(TypographyHelper.getArabicLineHeight(38))
   */
  static getArabicLineHeight(baseVp: number): number {
    return baseVp * ARABIC_METRICS.lineHeightScale;
  }

  /**
   * Scale a fontSize for Arabic glyphs shown inside a non-Arabic UI.
   */
  static getArabicFontSize(baseFp: number): number {
    return baseFp * ARABIC_METRICS.fontSizeScale;
  }

  // ============================================================
  // DIAGNOSTICS
  // ============================================================

  /** Return the raw metrics for a language. Useful for tests. */
  static metricsFor(lang: string): LanguageMetrics {
    return LANGUAGE_METRICS[lang] || DEFAULT_METRICS;
  }

  /** All languages with a tuned baseline. */
  static supportedBaselines(): string[] {
    return Object.keys(LANGUAGE_METRICS);
  }


  /**
   * Returns the font based on the ACTIVE SCRIPT loaded from the JSON data.
   */
  static getQuranFontByScript(script: string): string {
    switch (script) {
      case 'indopak':
      case 'hafs-nastaliq':
        return 'JameelNoori, NotoNastaliqUrdu, sans-serif';

      case 'kemenag':
        return 'LPMQIsepMisbah, sans-serif';

      case 'warsh':
        return 'KFGQPCWarsh, AmiriQuran, sans-serif';

      case 'qalun':
      case 'duri':
      case 'shubah':
      case 'susi':
        return 'AmiriQuran, sans-serif';

      case 'simple':
      case 'simple-clean':
      case 'simple-min':
      case 'simple-plain':
        return 'Outfit, sans-serif';

      case 'uthmani':
      case 'uthmani-min':
      case 'qpc-hafs':
        return 'QPC_Hafs, AmiriQuran, sans-serif';
      default:
        return 'HafsArabic, AmiriQuran, sans-serif';
    }
  }

  /**
   * Fallback if the active script isn't explicitly loaded in AppStorage.
   */
  static getQuranFont(lang: string): string {
    if (lang === 'id') return 'LPMQIsepMisbah, sans-serif';
    if (lang === 'ur') return 'JameelNoori, NotoNastaliqUrdu, sans-serif';
    return 'HafsArabic, AmiriQuran, sans-serif';
  }

  /**
   * Returns the appropriate font for translation text.
   */
  static getTranslationFont(lang: string): string {
    switch (lang) {
      case 'bn': return 'NotoSansBengali, sans-serif';
      case 'zh': return 'NotoSansSC, sans-serif';
      case 'ur': return 'NotoNastaliqUrdu, sans-serif';
      default: return 'Outfit, sans-serif';
    }
  }
}