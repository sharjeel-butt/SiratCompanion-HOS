// entry/src/main/ets/data/PrivacyPolicy.ets

import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { AppLogger } from '../core/AppLogger';

export interface PrivacyPolicyMetadata {
  title: string;
  lastUpdated: string;
  effectiveDate: string;
  appliesTo: string;
  fullUrl: string;
}

export interface PrivacyPolicyDocument {
  metadata: PrivacyPolicyMetadata;
  body: string;
}

/**
 * Privacy policy provider — JSON-backed.
 *
 * Content lives in `resources/rawfile/privacy/privacy_<lang>.json`
 * (one file per locale). Editing the policy text is a JSON edit,
 * not a code change.
 *
 * Lifecycle:
 *   • `preload(ctx, lang)` — called once at app startup. Reads
 *     the current language and English fallback. Cache is warm
 *     by the time the wizard's privacy step is reached.
 *   • `get(lang)` — synchronous. Returns cached text for the
 *     requested locale, or cached English, or `''`. Safe to call
 *     from `build()` and every render path.
 *   • `load(lang)` — async. Reads rawfile + parse + cache. Used
 *     by `preload` and by callers that need to guarantee the
 *     cache is populated for a specific language before
 *     rendering.
 *
 * Fallback chain: requested → English → empty. Matches the
 * historical behaviour where id/ur/tr/bn inherited English.
 *
 * Adding a locale: drop `privacy_<lang>.json` into
 * `rawfile/privacy/` and append the code to SUPPORTED below.
 */
export class PrivacyPolicyProvider {
  static readonly BASE_URL =
    'https://sharjeel-butt.github.io/SiratCompanion-HOS/';
  static readonly LAST_UPDATED = 'October 27, 2026';
  static readonly APPLIES_TO = '3.5.0 and later';
  /** Locales with a bundled translation. */
  private static readonly SUPPORTED: string[] = ['en', 'zh', 'ar', 'ur', 'tr', 'bn', 'id'];
  private static ctx: common.UIAbilityContext | null = null;
  private static cache: Map<string, PrivacyPolicyDocument> =
    new Map<string, PrivacyPolicyDocument>();
  private static loading: Map<string, Promise<PrivacyPolicyDocument>> =
    new Map<string, Promise<PrivacyPolicyDocument>>();

  // ============================================================
  // PUBLIC API
  // ============================================================

  /**
   * Warm the cache. Called once at app startup with the current
   * language. Also preloads English because it is the fallback
   * for locales without a translation.
   */
  static preload(ctx: common.UIAbilityContext, lang: string): void {
    PrivacyPolicyProvider.ctx = ctx;
    PrivacyPolicyProvider.load(lang).catch((e: Error) => {
      AppLogger.warn('PrivacyPolicyProvider',
        `preload(${lang}) failed: ${e.message}`);
    });
    if (lang !== 'en') {
      PrivacyPolicyProvider.load('en').catch((e: Error) => {
        AppLogger.warn('PrivacyPolicyProvider',
          `preload(en) failed: ${e.message}`);
      });
    }
  }

  /**
   * Dynamically resolves the localized Privacy Policy URL.
   * English is at the root. Other languages use subdirectories (e.g., /ar/).
   */
  static getFullUrl(lang: string): string {
    if (!lang || lang === 'en' || lang === 'system') {
      return PrivacyPolicyProvider.BASE_URL;
    }
    // Extract primary language code (e.g., 'zh-CN' -> 'zh')
    const cleanLang = lang.split('-')[0].toLowerCase();
    return `${PrivacyPolicyProvider.BASE_URL}${cleanLang}/`;
  }

  /**
   * Synchronous body accessor. Returns empty string if the cache
   * is not yet warm. Callers should render a loading placeholder
   * when the return value is ''.
   */
  static get(lang: string): string {
    const doc = PrivacyPolicyProvider.lookup(lang);
    return doc !== null ? doc.body : '';
  }

  /** Synchronous metadata accessor with the same fallback chain. */
  static getMetadata(lang: string): PrivacyPolicyMetadata | null {
    const doc = PrivacyPolicyProvider.lookup(lang);
    return doc !== null ? doc.metadata : null;
  }

  /**
   * Async loader. Reads rawfile, parses JSON, caches.
   * Concurrent calls for the same language share one in-flight
   * promise — no duplicate disk reads.
   */
  static async load(lang: string): Promise<PrivacyPolicyDocument> {
    const cached = PrivacyPolicyProvider.cache.get(lang);
    if (cached !== undefined) {
      return cached;
    }
    const inFlight = PrivacyPolicyProvider.loading.get(lang);
    if (inFlight !== undefined) {
      return inFlight;
    }

    const promise = PrivacyPolicyProvider.doLoad(lang);
    PrivacyPolicyProvider.loading.set(lang, promise);
    try {
      const doc = await promise;
      PrivacyPolicyProvider.cache.set(lang, doc);
      return doc;
    } finally {
      PrivacyPolicyProvider.loading.delete(lang);
    }
  }

  // ============================================================
  // INTERNALS
  // ============================================================

  private static lookup(lang: string): PrivacyPolicyDocument | null {
    const direct = PrivacyPolicyProvider.cache.get(lang);
    if (direct !== undefined) {
      return direct;
    }
    const en = PrivacyPolicyProvider.cache.get('en');
    return en !== undefined ? en : null;
  }

  private static async doLoad(lang: string): Promise<PrivacyPolicyDocument> {
    const effective = PrivacyPolicyProvider.SUPPORTED.includes(lang)
      ? lang : 'en';

    if (PrivacyPolicyProvider.ctx === null) {
      return PrivacyPolicyProvider.emptyDoc();
    }

    try {
      const mgr = PrivacyPolicyProvider.ctx.resourceManager;
      const rawData = await mgr.getRawFileContent(
        `privacy/privacy_${effective}.json`
      );
      const jsonStr = util.TextDecoder.create('utf-8')
        .decodeToString(rawData);
      const parsed = JSON.parse(jsonStr) as PrivacyPolicyDocument;
      return PrivacyPolicyProvider.normalize(parsed);
    } catch (e) {
      AppLogger.warn('PrivacyPolicyProvider',
        `load(${effective}) failed: ${JSON.stringify(e)}`);
      if (effective !== 'en') {
        try {
          const mgr = PrivacyPolicyProvider.ctx.resourceManager;
          const rawData = await mgr.getRawFileContent(
            'privacy/privacy_en.json'
          );
          const jsonStr = util.TextDecoder.create('utf-8')
            .decodeToString(rawData);
          const parsed = JSON.parse(jsonStr) as PrivacyPolicyDocument;
          return PrivacyPolicyProvider.normalize(parsed);
        } catch (e2) {
          AppLogger.warn('PrivacyPolicyProvider',
            `load(en) fallback failed: ${JSON.stringify(e2)}`);
        }
      }
      return PrivacyPolicyProvider.emptyDoc();
    }
  }

  // NEW: Map the current app language to the correct GitHub Pages URL
  static getUrlForLanguage(lang: string): string {
    switch (lang) {
      case 'ar':
        return 'https://sharjeel-butt.github.io/SiratCompanion-HOS/ar/';
      case 'bn':
        return 'https://sharjeel-butt.github.io/SiratCompanion-HOS/bn/';
      case 'id':
        return 'https://sharjeel-butt.github.io/SiratCompanion-HOS/id/';
      case 'tr':
        return 'https://sharjeel-butt.github.io/SiratCompanion-HOS/tr/';
      case 'ur':
        return 'https://sharjeel-butt.github.io/SiratCompanion-HOS/ur/';
      case 'zh':
        return 'https://sharjeel-butt.github.io/SiratCompanion-HOS/zh/';
      case 'en':
      default:
        return PrivacyPolicyProvider.BASE_URL;
    }
  }

  private static normalize(
    doc: PrivacyPolicyDocument
  ): PrivacyPolicyDocument {
    if (doc === null || doc === undefined) {
      return PrivacyPolicyProvider.emptyDoc();
    }
    if (typeof doc.body !== 'string') {
      return PrivacyPolicyProvider.emptyDoc();
    }
    const meta: PrivacyPolicyMetadata =
      doc.metadata !== undefined && doc.metadata !== null
        ? doc.metadata
        : PrivacyPolicyProvider.emptyMetadata();
    const normalized: PrivacyPolicyDocument = {
      metadata: meta,
      body: doc.body
    };
    return normalized;
  }

  private static emptyDoc(): PrivacyPolicyDocument {
    const result: PrivacyPolicyDocument = {
      metadata: PrivacyPolicyProvider.emptyMetadata(),
      body: ''
    };
    return result;
  }

  private static emptyMetadata(): PrivacyPolicyMetadata {
    const result: PrivacyPolicyMetadata = {
      title: 'Privacy Policy',
      lastUpdated: PrivacyPolicyProvider.LAST_UPDATED,
      effectiveDate: PrivacyPolicyProvider.LAST_UPDATED,
      appliesTo: PrivacyPolicyProvider.APPLIES_TO,
      fullUrl: PrivacyPolicyProvider.BASE_URL
    };
    return result;
  }
}