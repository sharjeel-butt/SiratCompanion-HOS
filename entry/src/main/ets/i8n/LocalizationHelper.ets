// entry/src/main/ets/helper/LocalizationHelper.ets

import { resourceManager } from '@kit.LocalizationKit';
import { common } from '@kit.AbilityKit';
import { STORAGE_KEY_LANGUAGE } from '../common/StorageKeys';

export enum AppLanguage {
  ENGLISH = 'en',
  CHINESE = 'zh',
  ARABIC = 'ar'
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
    const language = (lang !== undefined && lang.length > 0)
      ? lang : L.current();
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
    const language = (lang !== undefined && lang.length > 0)
      ? lang : L.current();
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

    if (lang === AppLanguage.ENGLISH) {
      return L.ctx.resourceManager;
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
      const cfg: resourceManager.Configuration =
        L.ctx.resourceManager.getOverrideConfiguration();
      cfg.locale = lang;

      const mgr = L.ctx.resourceManager.getOverrideResourceManager(cfg);
      L.overrideCache.set(lang, mgr);
      return mgr;
    } catch (err) {
      console.warn(`[L] override manager for "${lang}" failed: ${JSON.stringify(err)}`);
      return null;
    }
  }
}