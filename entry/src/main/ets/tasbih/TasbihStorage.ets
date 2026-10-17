// entry/src/main/ets/tasbih/TasbihStorage.ets

import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { Dhikr, Tasbih } from './TasbihModels';
import { TasbihManager } from './TasbihManager';
import { STORAGE_KEY_TASBIH_STATE_VERSION } from '../common/StorageKeys';

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
    if (!TasbihStorage.store) {
      return {
        tasbihs: defaults,
        activeTasbihId: defaults.length > 0 ? defaults[0].id : '',
        activeDhikrIndex: 0
      };
    }
    try {
      const json = await TasbihStorage.store.get(KEY_TASBIHS, '') as string;
      let tasbihs: Tasbih[] = json && json.length > 0
        ? JSON.parse(json) as Tasbih[]
        : [];
      if (tasbihs.length === 0) {
        tasbihs = defaults;
      }

      // ---- Migration ----
      // Older stores may be missing lifetimeCount, themePresetId,
      // history, or per-dhikr lastCountDate. Fill in safe defaults.
      tasbihs = tasbihs.map((t: Tasbih): Tasbih => {
        const dhikrs: Dhikr[] = (t.dhikrs || []).map(
          (d: Dhikr): Dhikr => {
            const fixed: Dhikr = {
              id: d.id,
              arabic: d.arabic,
              transliteration: d.transliteration,
              translation: d.translation,
              target: d.target,
              count: d.count,
              lastCountDate: d.lastCountDate,
              dailyTotal: d.dailyTotal
            };
            return fixed;
          }
        );
        const fixed: Tasbih = {
          id: t.id,
          name: t.name,
          dhikrs: dhikrs,
          createdAt: t.createdAt,
          lifetimeCount: typeof t.lifetimeCount === 'number'
            ? t.lifetimeCount : 0,
          theme: t.theme,
          themePresetId: (typeof t.themePresetId === 'string'
            && t.themePresetId.length > 0)
            ? t.themePresetId : undefined,
          history: Array.isArray(t.history) ? t.history : []
        };
        return fixed;
      });

      // ---- Day rollover ----
      // If any dhikr's lastCountDate is stale, roll its count into
      // history and reset the live counter. Persist if anything
      // changed so the next launch is a no-op.
      const rolled = TasbihManager.rollOverStaleCounts(tasbihs);
      const rolloverHappened = rolled !== tasbihs;
      if (rolloverHappened) {
        tasbihs = rolled;
      }

      const activeId = await TasbihStorage.store.get(KEY_ACTIVE, '') as string;
      const found = tasbihs.find((t): boolean => t.id === activeId);
      const activeTasbihId = found ? activeId : tasbihs[0].id;

      const rawIdx = await TasbihStorage.store.get(KEY_ACTIVE_DHK, 0) as number;
      const tasbih = tasbihs.find((t): boolean => t.id === activeTasbihId);
      const maxIdx = tasbih && tasbih.dhikrs.length > 0
        ? tasbih.dhikrs.length - 1
        : 0;
      const activeDhikrIndex = Math.min(Math.max(0, rawIdx), maxIdx);

      if (rolloverHappened) {
        // Save the normalized state so the next launch skips the
        // rollover entirely.
        TasbihStorage.save(tasbihs, activeTasbihId, activeDhikrIndex)
          .catch(() => { /* non-fatal */
          });
      }

      return { tasbihs, activeTasbihId, activeDhikrIndex };
    } catch (err) {
      return {
        tasbihs: defaults,
        activeTasbihId: defaults.length > 0 ? defaults[0].id : '',
        activeDhikrIndex: 0
      };
    }
  }

  static async save(
    tasbihs: Tasbih[],
    activeTasbihId: string,
    activeDhikrIndex: number
  ): Promise<void> {
    if (!TasbihStorage.store) {
      return;
    }
    try {
      await TasbihStorage.store.put(KEY_TASBIHS, JSON.stringify(tasbihs));
      await TasbihStorage.store.put(KEY_ACTIVE, activeTasbihId);
      await TasbihStorage.store.put(KEY_ACTIVE_DHK, activeDhikrIndex);
      await TasbihStorage.store.flush();

      // Broadcast the change so HomePage and TasbihDetailsPage update.
      const prev = AppStorage.get<number>(STORAGE_KEY_TASBIH_STATE_VERSION);
      const next = (prev === undefined ? 0 : prev) + 1;
      AppStorage.setOrCreate(STORAGE_KEY_TASBIH_STATE_VERSION, next);
    } catch (err) {
      console.warn('[TasbihStorage] save failed');
    }
  }
}