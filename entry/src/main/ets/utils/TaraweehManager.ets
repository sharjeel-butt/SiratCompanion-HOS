// entry/src/main/ets/utils/TaraweehManager.ets

import { PreferencesHelper } from '../helper/PreferencesHelper';
import { STORAGE_KEY_TARAWEEH_MAP, STORAGE_KEY_TARAWEEH_STATE_VERSION } from '../common/StorageKeys';

export class TaraweehManager {
  private static stateMap: Record<string, boolean> = {};

  static getDateKey(date: Date): string {
    const y = date.getFullYear();
    const m = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    return `${y}-${m}-${day}`;
  }

  static async primeStateMap(): Promise<void> {
    const raw = await PreferencesHelper.getString(STORAGE_KEY_TARAWEEH_MAP, '{}');
    try {
      TaraweehManager.stateMap = JSON.parse(raw) as Record<string, boolean>;
    } catch (err) {
      TaraweehManager.stateMap = {};
    }
  }

  static isTaraweeh(dateKey: string): boolean {
    return TaraweehManager.stateMap[dateKey] === true;
  }

  static toggleTaraweeh(dateKey: string, isDone: boolean): void {
    if (isDone) {
      TaraweehManager.stateMap[dateKey] = true;
    } else {
      // ArkTS forbids 'delete', rebuild the object
      const newMap: Record<string, boolean> = {};
      const keys = Object.keys(TaraweehManager.stateMap);
      for (let i = 0; i < keys.length; i++) {
        const k = keys[i];
        if (k !== dateKey) {
          newMap[k] = TaraweehManager.stateMap[k];
        }
      }
      TaraweehManager.stateMap = newMap;
    }

    const json = JSON.stringify(TaraweehManager.stateMap);
    PreferencesHelper.setString(STORAGE_KEY_TARAWEEH_MAP, json)
      .catch((e: Error) => console.error('[TaraweehManager] disk write failed: ' + e.message));

    const prev = AppStorage.get<number>(STORAGE_KEY_TARAWEEH_STATE_VERSION);
    AppStorage.setOrCreate(STORAGE_KEY_TARAWEEH_STATE_VERSION, (prev === undefined ? 0 : prev) + 1);
  }
}