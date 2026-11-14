import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { Dhikr, Tasbih } from './TasbihModels';
import { TasbihManager } from './TasbihManager';
import { STORAGE_KEY_TASBIH_STATE_VERSION } from '../core/StorageKeys';

const PREF_STORE = 'tasbih_prefs';
const KEY_TASBIHS = 'tasbihs_data';
const KEY_ACTIVE = 'tasbih_active_id';
const KEY_ACTIVE_DHK = 'tasbih_active_dhikr';

export interface TasbihLoadResult {
  tasbihs: Tasbih[];
  activeTasbihId: string;
  activeDhikrIndex: number;
}

export class TasbihStorage {
  // ADD MEMORY CACHE to prevent UI freeze on fast flicking
  public static cachedTasbihs: Tasbih[] | null = null;
  public static cachedActiveTasbihId: string = '';
  public static cachedActiveDhikrIndex: number = 0;
  /**
   * The YYYY-MM-DD key on which rollOverStaleCounts() last completed
   * for the current cache. Empty string means "never run this
   * session" — the next load() always scans.
   *
   * rollOverStaleCounts is O(tasbihs × dhikrs × history) and only
   * has work to do once per calendar day. Without this gate, every
   * TasbihStorage.load() call — including the one fired by
   * TasbihIndicator on every count increment — re-walks the entire
   * state tree. On a heavy user this is hundreds of thousands of
   * discarded objects per counting session.
   *
   * Also invalidated implicitly by date comparison: if the clock
   * crosses midnight (or the device clock is changed), the next
   * todayKey() will differ from this and the scan re-runs.
   */
  private static lastRolloverDateKey: string = '';

  private static store: preferences.Preferences | null = null;

  static async init(context: common.UIAbilityContext): Promise<void> {
    if (TasbihStorage.store) {
      return;
    }
    try {
      TasbihStorage.store = await preferences.getPreferences(context, PREF_STORE);
    } catch (err) {
      console.warn('[TasbihStorage] init failed');
    }
  }

  static async load(defaults: Tasbih[]): Promise<TasbihLoadResult> {
    const today = TasbihManager.todayKey();
    const needsRollover = TasbihStorage.lastRolloverDateKey !== today;

    // 1. Return from cache instantly
    if (TasbihStorage.cachedTasbihs) {
      if (needsRollover) {
        const rolled = TasbihManager.rollOverStaleCounts(
          TasbihStorage.cachedTasbihs
        );
        TasbihStorage.lastRolloverDateKey = today;
        if (rolled !== TasbihStorage.cachedTasbihs) {
          TasbihStorage.cachedTasbihs = rolled;
          TasbihStorage.save(
            rolled,
            TasbihStorage.cachedActiveTasbihId,
            TasbihStorage.cachedActiveDhikrIndex
          ).catch(() => {
          });
        }
      }
      return {
        tasbihs: TasbihStorage.cachedTasbihs,
        activeTasbihId: TasbihStorage.cachedActiveTasbihId,
        activeDhikrIndex: TasbihStorage.cachedActiveDhikrIndex
      };
    }

    // 2. Load from disk if cache is empty
    if (!TasbihStorage.store) {
      return { tasbihs: defaults, activeTasbihId: defaults.length > 0 ? defaults[0].id : '', activeDhikrIndex: 0 };
    }
    try {
      const json = await TasbihStorage.store.get(KEY_TASBIHS, '') as string;
      let tasbihs: Tasbih[] = json && json.length > 0 ? JSON.parse(json) as Tasbih[] : [];
      if (tasbihs.length === 0) {
        tasbihs = defaults;
      }

      tasbihs = tasbihs.map((t: Tasbih): Tasbih => {
        let nameKey = t.nameKey;
        if (!nameKey) {
          if (t.name === 'Classic 33') {
            nameKey = 'tasbih_default_classic_name';
          } else if (t.name ===
            'Tahlil 100') {
            nameKey = 'tasbih_default_tahlil_name';
          } else if (t.name === 'Istighfar') {
            nameKey =
              'tasbih_default_istighfar_name';
          }
        }

        const dhikrs: Dhikr[] = (t.dhikrs || []).map((d: Dhikr): Dhikr => {
          let tKey = d.transliterationKey;
          let trKey = d.translationKey;
          if (!tKey) {
            if (d.transliteration === 'SubhanAllah') {
              tKey = 'dhikr_subhanallah_translit';
            } else if (d.transliteration ===
              'Alhamdulillah') {
              tKey = 'dhikr_alhamdulillah_translit';
            } else if (d.transliteration ===
              'Allahu Akbar') {
              tKey = 'dhikr_allahuakbar_translit';
            } else if (d.transliteration ===
              'La ilaha illallahu wahdahu la sharika lah') {
              tKey =
                'dhikr_tahlil_translit';
            } else if (d.transliteration === 'Astaghfirullah') {
              tKey =
                'dhikr_istighfar_translit';
            }
          }
          if (!trKey) {
            if (d.translation === 'Glory be to Allah') {
              trKey = 'dhikr_subhanallah_trans';
            } else if (d.translation ===
              'All praise is for Allah') {
              trKey = 'dhikr_alhamdulillah_trans';
            } else if (d.translation ===
              'Allah is the Greatest') {
              trKey = 'dhikr_allahuakbar_trans';
            } else if (d.translation ===
              'There is no god but Allah, alone, without partner') {
              trKey =
                'dhikr_tahlil_trans';
            } else if (d.translation === 'I seek forgiveness from Allah') {
              trKey =
                'dhikr_istighfar_trans';
            }
          }
          return {
            id: d.id,
            arabic: d.arabic,
            transliteration: d.transliteration,
            translation: d.translation,
            transliterationKey: tKey,
            translationKey: trKey,
            target: d.target,
            count: d.count,
            lastCountDate: d.lastCountDate,
            dailyTotal: d.dailyTotal,
            liveCounts: d.liveCounts
          };
        });

        return {
          id: t.id,
          name: t.name,
          nameKey: nameKey,
          dhikrs: dhikrs,
          createdAt: t.createdAt,
          lifetimeCount: typeof t.lifetimeCount === 'number' ? t.lifetimeCount : 0,
          theme: t.theme,
          themePresetId: (typeof t.themePresetId === 'string' && t.themePresetId.length > 0) ? t.themePresetId :
            undefined,
          history: Array.isArray(t.history) ? t.history : [],
          boundPrayerIds: Array.isArray(t.boundPrayerIds) ? t.boundPrayerIds : [],
          prayerCompletions: (typeof t.prayerCompletions === 'object' && t.prayerCompletions !== null) ?
            t.prayerCompletions as Record<string, string> : {}
        };
      });

      if (needsRollover) {
        const rolled = TasbihManager.rollOverStaleCounts(tasbihs);
        if (rolled !== tasbihs) {
          tasbihs = rolled;
        }
        TasbihStorage.lastRolloverDateKey = today;
      }

      const activeId = await TasbihStorage.store.get(KEY_ACTIVE, '') as string;
      const found = tasbihs.find((t): boolean => t.id === activeId);
      const activeTasbihId = found ? activeId : tasbihs[0].id;

      const rawIdx = await TasbihStorage.store.get(KEY_ACTIVE_DHK, 0) as number;
      const tasbih = tasbihs.find((t): boolean => t.id === activeTasbihId);
      const maxIdx = tasbih && tasbih.dhikrs.length > 0 ? tasbih.dhikrs.length - 1 : 0;
      const activeDhikrIndex = Math.min(Math.max(0, rawIdx), maxIdx);

      // 3. Save to cache
      TasbihStorage.cachedTasbihs = tasbihs;
      TasbihStorage.cachedActiveTasbihId = activeTasbihId;
      TasbihStorage.cachedActiveDhikrIndex = activeDhikrIndex;

      if (needsRollover) {
        // Cold load always persists the (possibly rolled) state so
        // migrations from older builds take effect even if the
        // user does nothing else today.
        TasbihStorage.save(tasbihs, activeTasbihId, activeDhikrIndex)
          .catch(() => {
          });
      }

      return { tasbihs, activeTasbihId, activeDhikrIndex };
    } catch (err) {
      return { tasbihs: defaults, activeTasbihId: defaults.length > 0 ? defaults[0].id : '', activeDhikrIndex: 0 };
    }
  }

  static async save(tasbihs: Tasbih[], activeTasbihId: string, activeDhikrIndex: number): Promise<void> {
    // 1. Update the in-memory cache — this is the source of truth for
    //    every UI subscriber that reads through TasbihStorage.load().
    TasbihStorage.cachedTasbihs = tasbihs;
    TasbihStorage.cachedActiveTasbihId = activeTasbihId;
    TasbihStorage.cachedActiveDhikrIndex = activeDhikrIndex;

    // 2. Bump the version counter BEFORE the disk write.
    //
    //    The counter signals every @StorageLink(STORAGE_KEY_TASBIH_
    //    STATE_VERSION) subscriber (HomePage BoundTasbihsCard,
    //    TasbihIndicator) to re-read from the cache. It must fire
    //    even if the subsequent disk write fails — the UI is already
    //    showing the new state (from the cache), and a silent
    //    divergence between UI and any disk state is worse than a
    //    logged write failure.
    //
    //    This also runs when `store` is null (init failed) for the
    //    same reason — the cache updated above is authoritative for
    //    the current session.
    const prev = AppStorage.get<number>(STORAGE_KEY_TASBIH_STATE_VERSION);
    const next = (prev === undefined ? 0 : prev) + 1;
    AppStorage.setOrCreate(STORAGE_KEY_TASBIH_STATE_VERSION, next);

    // 3. Persist to disk in the background.
    if (!TasbihStorage.store) {
      return;
    }
    try {
      await TasbihStorage.store.put(KEY_TASBIHS, JSON.stringify(tasbihs));
      await TasbihStorage.store.put(KEY_ACTIVE, activeTasbihId);
      await TasbihStorage.store.put(KEY_ACTIVE_DHK, activeDhikrIndex);
      await TasbihStorage.store.flush();
    } catch (err) {
      console.warn('[TasbihStorage] save failed — cache/disk may diverge');
    }
  }
}