import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { BaseDua, CompleteDua, TranslatedDua } from '../models/DuaModels';
import { PreferencesHelper } from './PreferencesHelper';
import { RamadanInfo } from './RamadanHelper';
import { STORAGE_KEY_DUA_BINDINGS_VERSION } from '../common/StorageKeys';

const KEY_DUA_FAVORITES = 'dua_favorites';
const KEY_DUA_BINDINGS = 'dua_bindings';

export class DuaService {
  private static cachedDuas: CompleteDua[] | null = null;

  /**
   * Clear the in-memory Dua cache. Called by UserBackupService
   * after a successful restore so that the freshly restored
   * favorites and bindings take effect on the next load without
   * requiring a language change or app restart.
   */
  static invalidateCache(): void {
    DuaService.cachedDuas = null;
    AppStorage.setOrCreate('dua_cache_lang', '');
  }

  static async loadDuas(context: common.UIAbilityContext, lang: string): Promise<CompleteDua[]> {
    if (DuaService.cachedDuas) {
      const cachedLang = AppStorage.get<string>('dua_cache_lang');
      if (cachedLang === lang) {
        return DuaService.cachedDuas;
      }
    }

    try {
      const mgr = context.resourceManager;

      // 1. Load base (Arabic text + category + reference)
      const baseData = await mgr.getRawFileContent('duas/duas_base.json');
      const baseJsonStr = util.TextDecoder.create('utf-8').decodeToString(baseData);
      const baseDuas: BaseDua[] = JSON.parse(baseJsonStr);

      // 2. Load English — guaranteed complete. This is the per-ID
      //    fallback so a partial locale file never shows raw IDs.
      const enData = await mgr.getRawFileContent('duas/duas_en.json');
      const englishDuas: Record<string, TranslatedDua> =
        JSON.parse(util.TextDecoder.create('utf-8').decodeToString(enData));

      // 3. Load requested language — optional. If the file is absent
      //    entirely, we fall back per-ID to English below.
      let translatedDuas: Record<string, TranslatedDua> = {};
      if (lang === 'en') {
        translatedDuas = englishDuas;
      } else {
        try {
          const langFile = `duas/duas_${lang}.json`;
          const langData = await mgr.getRawFileContent(langFile);
          translatedDuas = JSON.parse(util.TextDecoder.create('utf-8').decodeToString(langData));
        } catch (e) {
          translatedDuas = {};
        }
      }

      // 4. Load user state
      const favorites = await DuaService.safeLoadStringArray(KEY_DUA_FAVORITES);
      const bindings = await DuaService.safeLoadRecord(KEY_DUA_BINDINGS);

      // 5. Merge with three-level fallback: requested → English → base
      const merged: CompleteDua[] = baseDuas.map((base: BaseDua): CompleteDua => {
        const target = translatedDuas[base.id];
        const english = englishDuas[base.id];
        const t: TranslatedDua = target || english || {
          name: base.id,
          translation: '',
          reference: base.reference
        };

        const complete: CompleteDua = {
          id: base.id,
          category: base.category,
          arabic: base.arabic,
          reference: base.reference,
          transliteration: base.transliteration,
          translatedName: t.name,
          translatedText: t.translation,
          translatedReference: t.reference || base.reference,
          isFavorite: favorites.includes(base.id),
          boundPrayerIds: bindings[base.id] || []
        };
        return complete;
      });

      DuaService.cachedDuas = merged;
      AppStorage.setOrCreate('dua_cache_lang', lang);
      return merged;
    } catch (e) {
      console.error('Failed to load duas:', JSON.stringify(e));
      return [];
    }
  }

  /**
   * Read a string[] from preferences. Returns [] on any failure —
   * missing key, malformed JSON, non-array value, or null. Isolating
   * this parse from the main loadDuas try/catch means a single
   * corrupt favorites file no longer wipes every dua from the app.
   *
   * No any/unknown: uses Object + Array.isArray + a type assertion,
   * which is the ArkTS-legal pattern for defensive JSON handling.
   */
  private static async safeLoadStringArray(key: string): Promise<string[]> {
    try {
      const raw = await PreferencesHelper.getString(key, '[]');
      if (raw.length === 0) {
        return [];
      }
      const parsed: Object = JSON.parse(raw);
      // Array.isArray returns false for null, primitives, and
      // plain objects — all of which we must reject here.
      if (!Array.isArray(parsed)) {
        console.warn(`[DuaService] ${key} is not an array — ignoring`);
        return [];
      }
      return parsed as string[];
    } catch (e) {
      const err = e as Error;
      console.warn(`[DuaService] ${key} parse failed: ${err.message}`);
      return [];
    }
  }

  /**
   * Read a Record<string, string[]> from preferences. Returns {} on
   * any failure — missing key, malformed JSON, array value, null, or
   * primitive. Same isolation rationale as safeLoadStringArray.
   */
  private static async safeLoadRecord(key: string): Promise<Record<string, string[]>> {
    try {
      const raw = await PreferencesHelper.getString(key, '{}');
      if (raw.length === 0) {
        return {};
      }
      const parsed: Object = JSON.parse(raw);
      if (Array.isArray(parsed)) {
        console.warn(`[DuaService] ${key} is not an object — ignoring`);
        return {};
      }
      const rec = parsed as Record<string, string[]>;
      // Object.keys throws on null — that routes us into the
      // catch below and returns {}. Primitive values (string,
      // number, boolean) don't throw here and are harmless
      // downstream: bindings[id] returns undefined, which
      // loadDuas maps to [] via `bindings[base.id] || []`.
      Object.keys(rec);
      return rec;
    } catch (e) {
      const err = e as Error;
      console.warn(`[DuaService] ${key} parse failed: ${err.message}`);
      return {};
    }
  }

  static async toggleFavorite(id: string, currentFavs: string[]): Promise<string[]> {
    // Replace array spread with concat
    const newFavs: string[] = currentFavs.includes(id)
      ? currentFavs.filter((f: string) => f !== id)
      : currentFavs.concat(id);

    await PreferencesHelper.setString(KEY_DUA_FAVORITES, JSON.stringify(newFavs));

    // Replace object spread with explicit construction
    if (DuaService.cachedDuas) {
      DuaService.cachedDuas = DuaService.cachedDuas.map((d: CompleteDua): CompleteDua => {
        if (d.id === id) {
          const updated: CompleteDua = {
            id: d.id,
            category: d.category,
            arabic: d.arabic,
            reference: d.reference,
            translatedName: d.translatedName,
            translatedText: d.translatedText,
            translatedReference: d.translatedReference,
            isFavorite: !d.isFavorite,
            boundPrayerIds: d.boundPrayerIds
          };
          return updated;
        }
        return d;
      });
    }
    return newFavs;
  }

  static async bindToPrayer(id: string, prayerId: string, isBound: boolean): Promise<void> {
    const bindJson = await PreferencesHelper.getString(KEY_DUA_BINDINGS, '{}');
    const bindings: Record<string, string[]> = JSON.parse(bindJson);

    let prayers = bindings[id] || [];
    if (isBound && !prayers.includes(prayerId)) {
      prayers = prayers.concat(prayerId);
    } else if (!isBound) {
      prayers = prayers.filter((p: string) => p !== prayerId);
    }
    bindings[id] = prayers;

    await PreferencesHelper.setString(KEY_DUA_BINDINGS, JSON.stringify(bindings));
    const prev = AppStorage.get<number>(STORAGE_KEY_DUA_BINDINGS_VERSION);
    AppStorage.setOrCreate(STORAGE_KEY_DUA_BINDINGS_VERSION, (prev === undefined ? 0 : prev) + 1);

    // Replace object spread with explicit construction
    if (DuaService.cachedDuas) {
      DuaService.cachedDuas = DuaService.cachedDuas.map((d: CompleteDua): CompleteDua => {
        if (d.id === id) {
          const updated: CompleteDua = {
            id: d.id,
            category: d.category,
            arabic: d.arabic,
            reference: d.reference,
            translatedName: d.translatedName,
            translatedText: d.translatedText,
            translatedReference: d.translatedReference,
            isFavorite: d.isFavorite,
            boundPrayerIds: prayers
          };
          return updated;
        }
        return d;
      });
    }
  }

  static getDailyDuas(
    allDuas: CompleteDua[],
    ramadanInfo: RamadanInfo | null,
    isFriday: boolean
  ): CompleteDua[] {
    const result: CompleteDua[] = [];
    const idsToFind: string[] = [];

    // 1. Contextual based on Ramadan
    if (ramadanInfo && ramadanInfo.isRamadanNow) {
      idsToFind.push('dua_breaking_the_fast');
      if (ramadanInfo.currentDayNumber >= 21) {
        idsToFind.push('dua_laylatul_qadr');
      }
    }

    // 2. Contextual based on Friday
    if (isFriday) {
      idsToFind.push('dua_after_the_adhan');
      idsToFind.push('dua_opening_supplication_in_prayer');
    }

    // 3. General Day-to-Day
    idsToFind.push('dua_morning'); // Morning
    idsToFind.push('dua_before_sleeping'); // Night
    idsToFind.push('dua_travel'); // Travel
    idsToFind.push('dua_guidance_to_the_straight_path'); // Core

    // Deduplicate and limit to 3
    const seen = new Set<string>();
    for (const id of idsToFind) {
      if (result.length >= 3) {
        break;
      }
      if (seen.has(id)) {
        continue;
      }

      const found = allDuas.find((d: CompleteDua) => d.id === id);
      if (found) {
        result.push(found);
        seen.add(id);
      }
    }

    return result;
  }
}