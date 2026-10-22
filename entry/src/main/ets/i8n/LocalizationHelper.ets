// entry/src/main/ets/helper/LocalizationHelper.ets

import { i18n, resourceManager } from '@kit.LocalizationKit';
import { common } from '@kit.AbilityKit';
import { STORAGE_KEY_LANGUAGE } from '../common/StorageKeys';

export enum AppLanguage {
  ENGLISH = 'en',
  CHINESE = 'zh',
  ARABIC = 'ar',
  SYSTEM = 'system'
}

/**
 * Localization provider backed by HarmonyOS resources.
 *
 * Strings live in resources/{base,zh,ar}/element/string.json.
 * Arrays live in resources/{base,zh,ar}/element/strarray.json.
 *
 * Language resolution:
 *   - The app's own language setting (STORAGE_KEY_LANGUAGE) takes
 *     precedence over the system locale. This lets the user pick a
 *     language independently of the device setting.
 *   - The resource manager's override mechanism reads the correct
 *     resource table for the requested language on demand.
 *   - If a key is missing in the requested language, the OS falls
 *     through to the base/ table automatically. If a key is missing
 *     entirely, L.get returns the key itself so failures are visible
 *     rather than silently blank.
 */
export class L {
  /**
   * Fallback when the device locale does not match any of our
   * supported languages. English is the safe default — it is the
   * base resource set and every key is guaranteed to be defined.
   */
  static readonly DEFAULT_LANGUAGE = AppLanguage.ENGLISH;

  private static ctx: common.UIAbilityContext | null = null;
  private static readonly overrideCache: Map<string, resourceManager.ResourceManager>
    = new Map<string, resourceManager.ResourceManager>();

  /**
   * Call once at app startup (EntryAbility.onWindowStageCreate)
   * before any page renders. Required — L.get returns the raw key
   * if this has not been called.
   */
  static init(context: common.UIAbilityContext): void {
    L.ctx = context;
    L.overrideCache.clear();
  }

  /**
   * Resolve a raw override value to a concrete language code.
   *
   * - 'en' | 'zh' | 'ar'  → returned as-is
   * - 'system'            → matched against the device locale,
   *                          falling back to English
   * - anything else       → treated as 'system'
   *
   * Used by SettingsHelper.saveLanguage() and the migration path
   * in EntryAbility. Safe to call from any context.
   */
  static resolveOverride(override: string): string {
    if (override === AppLanguage.ENGLISH
      || override === AppLanguage.CHINESE
      || override === AppLanguage.ARABIC) {
      return override;
    }
    return L.matchSystemLocale();
  }

  /**
   * Return the language code matching the device's current locale,
   * or English when no match exists.
   *
   * Reads the primary subtag of the system locale (e.g. "en-US"
   * → "en", "zh-Hans-CN" → "zh") and compares against our
   * supported set. Any failure (thrown exception, empty result)
   * falls through to English.
   */
  static matchSystemLocale(): string {
    try {
      const sysLocale = i18n.System.getSystemLocale();
      if (sysLocale === undefined || sysLocale.length === 0) {
        return L.DEFAULT_LANGUAGE;
      }
      const sysLang = sysLocale.split('-')[0].toLowerCase();
      if (sysLang === 'zh') {
        return AppLanguage.CHINESE;
      }
      if (sysLang === 'ar') {
        return AppLanguage.ARABIC;
      }
      if (sysLang === 'en') {
        return AppLanguage.ENGLISH;
      }
      return L.DEFAULT_LANGUAGE;
    } catch (err) {
      return L.DEFAULT_LANGUAGE;
    }
  }

  // ============================================================
  // LANGUAGE STATE
  // ============================================================

  static current(): string {
    const v = AppStorage.get<string>(STORAGE_KEY_LANGUAGE);
    return v ? v : AppLanguage.ENGLISH;
  }

  static setLanguage(lang: string): void {
    AppStorage.setOrCreate(STORAGE_KEY_LANGUAGE, lang);
  }

  static isRtl(): boolean {
    return L.current() === AppLanguage.ARABIC;
  }

  static isRtlLang(lang: string): boolean {
    return lang === AppLanguage.ARABIC;
  }

  static getLanguageLabel(lang: string): string {
    return L.get(`lang_${lang}`);
  }

  // ============================================================
  // LOOKUPS
  // ============================================================

  static get(key: string, lang?: string): string {
    let language = (lang !== undefined && lang.length > 0)
      ? lang : L.current();
    if (language === AppLanguage.SYSTEM) {
      language = L.matchSystemLocale();
    }
    const mgr = L.mgrFor(language);
    if (mgr === null) {
      return key;
    }
    try {
      return mgr.getStringByNameSync(key);
    } catch (err) {
      try {
        const baseMgr = L.mgrFor(AppLanguage.ENGLISH);
        if (baseMgr !== null && baseMgr !== mgr) {
          return baseMgr.getStringByNameSync(key);
        }
      } catch (inner) {
        // Fall through to returning the key.
      }
      console.warn(`[L] missing string key: ${key}`);
      return key;
    }
  }

  static getArray(key: string, lang?: string): string[] {
    let language = (lang !== undefined && lang.length > 0)
      ? lang : L.current();
    if (language === AppLanguage.SYSTEM) {
      language = L.matchSystemLocale();
    }
    const mgr = L.mgrFor(language);
    if (mgr === null) {
      return [];
    }
    try {
      return mgr.getStringArrayByNameSync(key);
    } catch (err) {
      try {
        const baseMgr = L.mgrFor(AppLanguage.ENGLISH);
        if (baseMgr !== null && baseMgr !== mgr) {
          return baseMgr.getStringArrayByNameSync(key);
        }
      } catch (inner) {
        // Fall through to empty array.
      }
      console.warn(`[L] missing string-array key: ${key}`);
      return [];
    }
  }

  // ============================================================
  // RESOURCE MANAGER RESOLUTION
  // ============================================================

  /**
   * Returns a resource manager configured for the requested language.
   *
   * English uses the base resource manager directly — no override
   * needed. Every other language produces (and caches) an override
   * manager that reads from that language's resource table.
   */
  private static mgrFor(lang: string): resourceManager.ResourceManager | null {
    if (L.ctx === null) {
      return null;
    }

    const cached = L.overrideCache.get(lang);
    if (cached !== undefined) {
      return cached;
    }

    try {
      // Clone the current configuration instead of constructing
      // one from scratch. This preserves every qualifier the
      // system set (density, color mode, mcc/mnc, etc.) and only
      // changes the locale, which is exactly what we need.
      //
      // IMPORTANT: this path is taken for EVERY language including
      // English. The previous implementation short-circuited
      // English to L.ctx.resourceManager, which respects the
      // device locale — so on a Chinese device, picking English
      // rendered Chinese text. All languages now go through the
      // override path so the picked language always wins.
      const cfg: resourceManager.Configuration =
        L.ctx.resourceManager.getOverrideConfiguration();
      cfg.locale = lang;

      const mgr = L.ctx.resourceManager.getOverrideResourceManager(cfg);
      L.overrideCache.set(lang, mgr);
      return mgr;
    } catch (err) {
      console.warn(`[L] override manager for "${lang}" failed: ${JSON.stringify(err)}`);
      // Fall back to the base resource manager. This may return
      // device-locale text on non-English devices, but it
      // prevents a total failure.
      return L.ctx.resourceManager;
    }
  }
}