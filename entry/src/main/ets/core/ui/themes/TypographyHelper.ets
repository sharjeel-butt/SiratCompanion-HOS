// entry/src/main/ets/helper/TypographyHelper.ets

import { font } from '@kit.ArkUI'
import { AppLogger } from '../../app/AppLogger'
import { FontPaths } from '../../common/FontPaths'

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
  lineHeightScale: number
  fontSizeScale: number
}

const LANGUAGE_METRICS: Record<string, LanguageMetrics> = {
  // ---- Latin / Cyrillic / Greek (baseline) ----
  'en': { lineHeightScale: 1.0, fontSizeScale: 1.0 },
  'fr': { lineHeightScale: 1.0, fontSizeScale: 1.0 },
  'de': { lineHeightScale: 1.0, fontSizeScale: 1.0 },
  'es': { lineHeightScale: 1.0, fontSizeScale: 1.0 },
  'it': { lineHeightScale: 1.0, fontSizeScale: 1.0 },
  'id': { lineHeightScale: 1.0, fontSizeScale: 1.0 },
  'ms': { lineHeightScale: 1.0, fontSizeScale: 1.0 },
  'tr': { lineHeightScale: 1.0, fontSizeScale: 1.0 },
  'sw': { lineHeightScale: 1.0, fontSizeScale: 1.0 },
  'ha': { lineHeightScale: 1.0, fontSizeScale: 1.0 },
  'az': { lineHeightScale: 1.0, fontSizeScale: 1.0 },
  'uz': { lineHeightScale: 1.0, fontSizeScale: 1.0 },
  'ru': { lineHeightScale: 1.02, fontSizeScale: 1.0 },

  // ---- Arabic script ----
  // Arabic diacritics (fatha, kasra, shadda, sukun) extend above
  // and below the baseline. Urdu Nastaliq additionally hangs below.
  'ar': { lineHeightScale: 1.15, fontSizeScale: 1.0 },
  'fa': { lineHeightScale: 1.15, fontSizeScale: 1.0 },
  'ur': { lineHeightScale: 1.2, fontSizeScale: 1.0 },
  'ps': { lineHeightScale: 1.2, fontSizeScale: 1.0 },

  // ---- CJK ----
  // Ideographs fill the em-square fully. Slightly smaller font size
  // matches Latin visual weight; slightly taller line prevents the
  // glyphs from touching.
  'zh': { lineHeightScale: 1.05, fontSizeScale: 0.95 },
  'ja': { lineHeightScale: 1.05, fontSizeScale: 0.95 },
  'ko': { lineHeightScale: 1.1, fontSizeScale: 0.95 },

  // ---- Indic ----
  // Matras extend above and below; conjuncts stack horizontally at
  // the same baseline, so the line must be tall enough not to clip
  // either the top matra or the bottom vowel stroke.
  'hi': { lineHeightScale: 1.2, fontSizeScale: 1.0 },
  'mr': { lineHeightScale: 1.2, fontSizeScale: 1.0 },
  'bn': { lineHeightScale: 1.25, fontSizeScale: 1.0 },
  'ta': { lineHeightScale: 1.3, fontSizeScale: 1.0 },
  'te': { lineHeightScale: 1.28, fontSizeScale: 1.0 },
  'kn': { lineHeightScale: 1.28, fontSizeScale: 1.0 },
  'ml': { lineHeightScale: 1.25, fontSizeScale: 1.0 },
  'si': { lineHeightScale: 1.25, fontSizeScale: 1.0 },

  // ---- Southeast Asian ----
  'th': { lineHeightScale: 1.2, fontSizeScale: 1.0 },
  'lo': { lineHeightScale: 1.2, fontSizeScale: 1.0 },
  'km': { lineHeightScale: 1.25, fontSizeScale: 1.0 }
}

const DEFAULT_METRICS: LanguageMetrics = {
  lineHeightScale: 1.0, fontSizeScale: 1.0
}

/** Arabic font metrics — used for Arabic glyphs rendered inside a
 *  non-Arabic UI (e.g. the Dua card showing Arabic text under an
 *  English title). The GLYPHS are Arabic regardless of UI language,
 *  so Arabic metrics apply. */
const ARABIC_METRICS: LanguageMetrics = {
  lineHeightScale: 1.15, fontSizeScale: 1.0
}

export class TypographyHelper {
  /** Font size for verse-by-verse text (Reading/Translation modes). */
  static readonly QURAN_FONT_SIZE_VERSE: number = 32
  /** Base line height for verse-by-verse text. */
  static readonly QURAN_LINE_HEIGHT_VERSE: number = 60
  /** Font size for continuous Mushaf text (Increased for readability). */
  static readonly QURAN_FONT_SIZE_MUSHAF: number = 32
  /** Base line height for continuous Mushaf text. */
  static readonly QURAN_LINE_HEIGHT_MUSHAF: number = 75
  /** Font size for the Bismillah header. */
  static readonly BISMILLAH_FONT_SIZE: number = 26
  /** Base line height for the Bismillah header. */
  static readonly BISMILLAH_LINE_HEIGHT: number = 60
  /** Font size for the Surah header ornament in Mushaf view. */
  static readonly SURAH_HEADER_FONT_SIZE: number = 26
  static readonly FONT_AUTO = 'auto'
  static readonly FONT_AMIRI = 'Amiri'
  static readonly FONT_AMIRI_QURAN = 'AmiriQuran'
  static readonly FONT_HAFS = 'HafsArabic'
  static readonly FONT_NASTALIQ = 'JameelNoori'
  static readonly FONT_NOTO_NASTALIQ = 'NotoNastaliqUrdu'
  static readonly FONT_QPC_HAFS = 'QPC_Hafs'
  static readonly FONT_KEMENAG = 'LPMQIsepMisbah'
  static readonly FONT_WARSH = 'KFGQPCWarsh'
  static readonly FONT_SCHEHERAZADE = 'ScheherazadeNew'
  static readonly FONT_NOTONASKH = 'NotoNaskh'

  /**
   * Register custom fonts. Call this once in EntryAbility.
   */
  static init(): void {
    try {
      const fonts: font.FontOptions[] = [
        // ========================================================// LATIN// ========================================================

        {
          familyName: 'Outfit', familySrc: $rawfile(FontPaths.OUTFIT)
        }, {
        familyName: 'Outfit-Bold', familySrc: $rawfile(FontPaths.OUTFIT_BOLD)
      },

        // ========================================================
        // BENGALI
        // ========================================================

        {
          familyName: 'NotoSansBengali', familySrc: $rawfile(FontPaths.NOTO_SANS_BENGALI)
        },

        // ========================================================
        // CHINESE
        // ========================================================

        {
          familyName: 'NotoSansSC', familySrc: $rawfile(FontPaths.NOTO_SANS_SC)
        },

        // ========================================================
        // URDU
        // ========================================================

        {
          familyName: 'NotoNastaliqUrdu', familySrc: $rawfile(FontPaths.NOTO_NASTALIQ_URDU)
        },

        {
          familyName: 'JameelNoori', familySrc: $rawfile(FontPaths.JAMEEL_NOORI)
        },

        // ========================================================
        // ARABIC
        // ========================================================

        {
          familyName: 'Amiri', familySrc: $rawfile(FontPaths.AMIRI)
        },

        {
          familyName: 'Amiri-Bold', familySrc: $rawfile(FontPaths.AMIRI_BOLD)
        },

        {
          familyName: 'AmiriQuran', familySrc: $rawfile(FontPaths.AMIRI_QURAN)
        },

        {
          familyName: 'ScheherazadeNew', familySrc: $rawfile(FontPaths.SCHEHERAZADE_NEW)
        },

        {
          familyName: 'NotoNaskh', familySrc: $rawfile(FontPaths.NOTO_NASKH_ARABIC)
        },

        {
          familyName: 'HafsArabic', familySrc: $rawfile(FontPaths.HAFS_ARABIC)
        },

        {
          familyName: 'LPMQIsepMisbah', familySrc: $rawfile(FontPaths.LPMQ_ISEP_MISBAH)
        },

        {
          familyName: 'KFGQPCWarsh', familySrc: $rawfile(FontPaths.KFGQPC_WARSH)
        },

        {
          familyName: 'QPC_Hafs', familySrc: $rawfile(FontPaths.QPC_HAFS)
        }]

      fonts.forEach((fontOption: font.FontOptions) => {
        font.registerFont(fontOption)
      })

      AppLogger.info('TypographyHelper', `Registered ${fonts.length} fonts successfully.`)
    } catch (err) {
      AppLogger.error('TypographyHelper', `Font registration failed: ${JSON.stringify(err)}`)
    }
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
    const metrics = LANGUAGE_METRICS[lang] || DEFAULT_METRICS
    return baseVp * metrics.lineHeightScale
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
    const metrics = LANGUAGE_METRICS[lang] || DEFAULT_METRICS
    return baseFp * metrics.fontSizeScale
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
    return baseVp * ARABIC_METRICS.lineHeightScale
  }

  /**
   * Scale a fontSize for Arabic glyphs shown inside a non-Arabic UI.
   */
  static getArabicFontSize(baseFp: number): number {
    return baseFp * ARABIC_METRICS.fontSizeScale
  }

  // ============================================================
  // DIAGNOSTICS
  // ============================================================

  /** Return the raw metrics for a language. Useful for tests. */
  static metricsFor(lang: string): LanguageMetrics {
    return LANGUAGE_METRICS[lang] || DEFAULT_METRICS
  }

  /** All languages with a tuned baseline. */
  static supportedBaselines(): string[] {
    return Object.keys(LANGUAGE_METRICS)
  }

  // ============================================================
  // TRANSLATION FONTS
  // ============================================================

  static getTranslationFont(lang: string, isBold: boolean = false): string {
    const pref = AppStorage.get<string>('translation_font_family') ?? 'auto'

    if (pref !== 'auto') {
      return isBold ? `${pref}-Bold, ${pref}, sans-serif` : `${pref}, sans-serif`
    }

    // Auto-Detect logic
    if (lang === 'bn') {
      return 'NotoSansBengali, sans-serif'
    }
    if (lang === 'zh') {
      return 'NotoSansSC, sans-serif'
    }
    if (lang === 'ur') {
      return 'NotoNastaliqUrdu, sans-serif'
    }

    return isBold ? 'Outfit-Bold, sans-serif' : 'Outfit, sans-serif'
  }

  // ============================================================
  // ARABIC FONTS
  // ============================================================

  static getArabicFont(isQuran: boolean = false, activeScript: string = ''): string {
    const pref = AppStorage.get<string>('arabic_font_family') ?? 'auto'

    if (pref !== 'auto') {
      return `${pref}, AmiriQuran, Amiri, sans-serif`
    }

    // Auto-Detect logic based on language and context
    const lang = AppStorage.get<string>('app_language') ?? 'en'

    if (isQuran) {
      if (activeScript === 'indopak') {
        return 'JameelNoori, NotoNastaliqUrdu, sans-serif'
      }
      if (activeScript === 'kemenag') {
        return 'LPMQIsepMisbah, sans-serif'
      }
      if (activeScript === 'warsh') {
        return 'KFGQPCWarsh, AmiriQuran, sans-serif'
      }
      if (activeScript === 'uthmani' || activeScript === 'qpc-hafs') {
        return 'QPC_Hafs, AmiriQuran, sans-serif'
      }
      return 'AmiriQuran, sans-serif'
    }

    if (lang === 'ur') {
      return 'JameelNoori, NotoNastaliqUrdu, sans-serif'
    }
    if (lang === 'id') {
      return 'LPMQIsepMisbah, Amiri, sans-serif'
    }

    return 'Amiri, HafsArabic, sans-serif'
  }

  /**
   * Legacy wrapper to prevent breaking existing calls.
   */
  static getFont(lang: string, isBold: boolean = false): string {
    if (lang === 'ar' || lang === 'ur') {
      return TypographyHelper.getArabicFont(false)
    }
    return TypographyHelper.getTranslationFont(lang, isBold)
  }

  /**
   * Legacy wrapper for Quran scripts.
   */
  static getQuranFontByScript(script: string): string {
    return TypographyHelper.getArabicFont(true, script)
  }

  /**
   * Resolves the user's preferred Arabic font.
   * If 'auto', falls back to a script-appropriate default based on the UI language.
   */
  static getActiveArabicFont(isQuran: boolean = false, activeScript: string = ''): string {
    const pref = AppStorage.get<string>('arabic_font_family') ?? 'auto'

    if (pref !== 'auto') { // User manually selected a font. Ensure fallbacks are appended.
      return `${pref}, AmiriQuran, Amiri, sans-serif`
    }

    // --- AUTO DETECT LOGIC ---
    const lang = AppStorage.get<string>('app_language') ?? 'en'

    // 1. Region-specific defaults
    if (lang === 'ur') { // Urdu users default to Nastaliq for general text, Naskh for Quran
      return isQuran ? 'AmiriQuran, sans-serif' : 'JameelNoori, NotoNastaliqUrdu, sans-serif'
    }
    if (lang === 'id') {
      return isQuran ? 'AmiriQuran, LPMQIsepMisbah, sans-serif' : 'LPMQIsepMisbah, Amiri, sans-serif'
    }

    // 2. Context-specific defaults for everyone else
    if (isQuran) { // Respect the specific Quran script setting if provided
      if (activeScript === 'indopak') {
        return 'JameelNoori, NotoNastaliqUrdu, sans-serif'
      }
      if (activeScript === 'kemenag') {
        return 'LPMQIsepMisbah, sans-serif'
      }
      if (activeScript === 'warsh') {
        return 'KFGQPCWarsh, AmiriQuran, sans-serif'
      }
      if (activeScript === 'uthmani' || activeScript === 'qpc-hafs') {
        return 'QPC_Hafs, AmiriQuran, sans-serif'
      }
      return 'AmiriQuran, sans-serif' // Standard fallback
    }

    // General Arabic text (Hadith, Duas, UI)
    return 'Amiri, HafsArabic, sans-serif'
  }
}
