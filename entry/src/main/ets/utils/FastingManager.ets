import { PreferencesHelper } from '../helper/PreferencesHelper';
import { STORAGE_KEY_FASTING_MAP, STORAGE_KEY_FASTING_STATE_VERSION } from '../common/StorageKeys';

export interface FastingRecord {
  status: 'fasted' | 'missed';
  reason: string;
}

// Add this new interface and export it
export interface MissedRecord {
  dateKey: string;
  reason: string;
}

export interface FastingStats {
  fasted: number;
  missed: number;
  missedRecords: MissedRecord[];
}

export interface HistoryRecord {
  dateKey: string;
  status: 'fasted' | 'missed';
  reason: string;
}

export class FastingManager {
  private static stateMap: Record<string, FastingRecord> = {};

  static getDateKey(date: Date): string {
    const y = date.getFullYear();
    const m = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    return `${y}-${m}-${day}`;
  }

  /**
   * Retrieves all fasting records that occurred before the
   * current Ramadan's start date, sorted descending (newest first).
   */
  static getPastHistory(currentStartKey: string): HistoryRecord[] {
    const records: HistoryRecord[] = [];
    const keys = Object.keys(FastingManager.stateMap);

    for (let i = 0; i < keys.length; i++) {
      const k = keys[i];
      // Anything strictly before the current Ramadan is "past"
      if (k < currentStartKey) {
        const rec = FastingManager.stateMap[k];
        records.push({
          dateKey: k,
          status: rec.status,
          reason: rec.reason
        });
      }
    }

    // Sort descending (newest first)
    records.sort((a: HistoryRecord, b: HistoryRecord): number => {
      return a.dateKey > b.dateKey ? -1 : 1;
    });

    return records;
  }

  static async primeStateMap(): Promise<void> {
    const raw = await PreferencesHelper.getString(STORAGE_KEY_FASTING_MAP, '{}');
    try {
      FastingManager.stateMap = JSON.parse(raw) as Record<string, FastingRecord>;
    } catch (err) {
      FastingManager.stateMap = {};
    }
  }

  static getRecord(dateKey: string): FastingRecord | null {
    return FastingManager.stateMap[dateKey] || null;
  }

  static saveRecord(dateKey: string, status: 'fasted' | 'missed', reason: string): void {
    FastingManager.stateMap[dateKey] = { status, reason };
    FastingManager.persist();
  }

  static clearRecord(dateKey: string): void {
    const newMap: Record<string, FastingRecord> = {};
    const keys = Object.keys(FastingManager.stateMap);
    for (let i = 0; i < keys.length; i++) {
      const k = keys[i];
      if (k !== dateKey) {
        newMap[k] = FastingManager.stateMap[k];
      }
    }
    FastingManager.stateMap = newMap;
    FastingManager.persist();
  }

  static getStats(ramadanStart: Date, ramadanEnd: Date): FastingStats {
    let fasted = 0;
    let missed = 0;
    const missedRecords: MissedRecord[] = [];

    // Get the YYYY-MM-DD string keys for the start and end of THIS Ramadan
    const startKey = FastingManager.getDateKey(ramadanStart);
    const endKey = FastingManager.getDateKey(ramadanEnd);

    const keys = Object.keys(FastingManager.stateMap);
    for (let i = 0; i < keys.length; i++) {
      const k = keys[i];

      // String comparison works for YYYY-MM-DD formats.
      // This ensures we ONLY count records from the current Ramadan's year.
      if (k >= startKey && k <= endKey) {
        const rec = FastingManager.stateMap[k];
        if (rec.status === 'fasted') {
          fasted++;
        } else if (rec.status === 'missed') {
          missed++;
          missedRecords.push({ dateKey: k, reason: rec.reason });
        }
      }
    }
    return { fasted, missed, missedRecords };
  }

  private static persist(): void {
    const json = JSON.stringify(FastingManager.stateMap);
    PreferencesHelper.setString(STORAGE_KEY_FASTING_MAP, json)
      .catch((e: Error) => console.error('[FastingManager] disk write failed: ' + e.message));

    const prev = AppStorage.get<number>(STORAGE_KEY_FASTING_STATE_VERSION);
    const next = (prev === undefined ? 0 : prev) + 1;
    AppStorage.setOrCreate(STORAGE_KEY_FASTING_STATE_VERSION, next);
  }
}