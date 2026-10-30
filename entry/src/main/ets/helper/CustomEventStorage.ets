// entry/src/main/ets/helper/CustomEventStorage.ets

import { PreferencesHelper } from './PreferencesHelper';
import { CustomEvent, RecurrenceType } from '../models/CustomEventModels';
import { STORAGE_KEY_CUSTOM_EVENTS_VERSION } from '../common/StorageKeys';

const KEY_CUSTOM_EVENTS = 'custom_events';

export class CustomEventStorage {
  static async load(): Promise<CustomEvent[]> {
    try {
      const json = await PreferencesHelper.getString(KEY_CUSTOM_EVENTS, '[]');
      const events = JSON.parse(json) as CustomEvent[];

      // Migration: ensure every event has an explicit recurrence
      return events.map((ev: CustomEvent): CustomEvent => {
        if (!ev.recurrence) {
          // Explicit construction — no spread operator
          const migrated: CustomEvent = {
            id: ev.id,
            title: ev.title,
            hijriYear: ev.hijriYear,
            hijriMonth: ev.hijriMonth,
            hijriDay: ev.hijriDay,
            notificationEnabled: ev.notificationEnabled,
            inputType: ev.inputType,
            recurrence: ev.hijriYear === -1
              ? RecurrenceType.YEARLY
              : RecurrenceType.NONE,
            gregorianDayOfWeek: ev.gregorianDayOfWeek
          };
          return migrated;
        }
        return ev;
      });
    } catch (e) {
      return [];
    }
  }

  static async save(events: CustomEvent[]): Promise<void> {
    await PreferencesHelper.setString(KEY_CUSTOM_EVENTS, JSON.stringify(events));

    // Bump so any page bound to STORAGE_KEY_CUSTOM_EVENTS_VERSION
    // (Home's CustomEventsCard) refreshes immediately rather than
    // waiting for the next foreground tick.
    const prev = AppStorage.get<number>(STORAGE_KEY_CUSTOM_EVENTS_VERSION);
    const next = (prev === undefined ? 0 : prev) + 1;
    AppStorage.setOrCreate(STORAGE_KEY_CUSTOM_EVENTS_VERSION, next);
  }

  static generateId(): string {
    return `evt_${Date.now()}_${Math.floor(Math.random() * 10000)}`;
  }
}