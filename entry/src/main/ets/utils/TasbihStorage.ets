// entry/src/main/ets/utils/TasbihStorage.ets

import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { Tasbih } from '../models/TasbihModels';

const PREF_STORE     = 'tasbih_prefs';
const KEY_TASBIHS    = 'tasbihs_data';
const KEY_ACTIVE     = 'tasbih_active_id';
const KEY_ACTIVE_DHK = 'tasbih_active_dhikr';

export interface TasbihLoadResult {
  tasbihs: Tasbih[];
  activeTasbihId: string;
  activeDhikrIndex: number;
}

export class TasbihStorage {

  private static store: preferences.Preferences | null = null;

  static async init(context: common.UIAbilityContext): Promise<void> {
    if (TasbihStorage.store) return;
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
      if (tasbihs.length === 0) tasbihs = defaults;

      // Migration: older stored tasbihs have no lifetimeCount field.
      // Default it to 0 so downstream code never has to guard against
      // undefined.
      tasbihs = tasbihs.map((t: Tasbih): Tasbih => {
        const fixed: Tasbih = {
          id: t.id,
          name: t.name,
          dhikrs: t.dhikrs,
          createdAt: t.createdAt,
          lifetimeCount: typeof t.lifetimeCount === 'number' ? t.lifetimeCount : 0
        };
        return fixed;
      });

      const activeId = await TasbihStorage.store.get(KEY_ACTIVE, '') as string;
      const found = tasbihs.find((t): boolean => t.id === activeId);
      const activeTasbihId = found ? activeId : tasbihs[0].id;

      // Restore the dhikr index, clamped to whatever the current
      // tasbih actually contains.
      const rawIdx = await TasbihStorage.store.get(KEY_ACTIVE_DHK, 0) as number;
      const tasbih = tasbihs.find((t): boolean => t.id === activeTasbihId);
      const maxIdx = tasbih && tasbih.dhikrs.length > 0
        ? tasbih.dhikrs.length - 1
        : 0;
      const activeDhikrIndex = Math.min(Math.max(0, rawIdx), maxIdx);

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
    if (!TasbihStorage.store) return;
    try {
      await TasbihStorage.store.put(KEY_TASBIHS, JSON.stringify(tasbihs));
      await TasbihStorage.store.put(KEY_ACTIVE, activeTasbihId);
      await TasbihStorage.store.put(KEY_ACTIVE_DHK, activeDhikrIndex);
      await TasbihStorage.store.flush();
    } catch (err) {
      console.warn('[TasbihStorage] save failed');
    }
  }
}