// entry/src/main/ets/prayer/PrayerManager.ets

import { ExtraTiming, PrayerModel } from './PrayerModel';
import { DailyPrayerTimes } from './PrayerTimeCalculator';
import { PrayerOffsets } from '../settings/SettingsHelper';
import { PreferencesHelper } from '../core/PreferencesHelper';
import { STORAGE_KEY_PRAYER_STATE_VERSION } from '../core/StorageKeys';

export interface PrayerCheckState {
  fajr: boolean;
  dhuhr: boolean;
  asr: boolean;
  maghrib: boolean;
  isha: boolean;
  fajrAt?: number;
  dhuhrAt?: number;
  asrAt?: number;
  maghribAt?: number;
  ishaAt?: number;
}

const DEFAULT_OFFSETS: PrayerOffsets = {
  fajr: 0,
  dhuhr: 0,
  asr: 0,
  maghrib: 0,
  isha: 0
};

export class PrayerManager {
  // ============================================================
  // TIME PARSING
  // ============================================================

  private static stateMap: Record<string, string> = {};
  // ============================================================
  // OFFSET
  // ============================================================
  private static readonly STATE_MAP_PREF_KEY = 'prayer_state_map';

  // ============================================================
  // DATE HELPERS
  // ============================================================

  static timeToMinutes(timeStr: string): number {
    const trimmed = timeStr.trim();
    if (trimmed === '' || trimmed === '--:--') {
      return 0;
    }

    const parts = trimmed.split(' ');
    if (parts.length !== 2) {
      return 0;
    }

    const timeParts = parts[0].split(':');
    if (timeParts.length !== 2) {
      return 0;
    }

    let hours = parseInt(timeParts[0], 10);
    const minutes = parseInt(timeParts[1], 10);
    const period = parts[1].toUpperCase();

    if (isNaN(hours) || isNaN(minutes)) {
      return 0;
    }

    if (period === 'PM' && hours !== 12) {
      hours += 12;
    }
    if (period === 'AM' && hours === 12) {
      hours = 0;
    }

    return hours * 60 + minutes;
  }

  static offsetTime(timeStr: string, offsetMinutes: number): string {
    if (offsetMinutes === 0) {
      return timeStr;
    }
    if (timeStr === '--:--' || timeStr.trim() === '') {
      return timeStr;
    }

    const parts = timeStr.trim().split(' ');
    if (parts.length !== 2) {
      return timeStr;
    }

    const timeParts = parts[0].split(':');
    if (timeParts.length !== 2) {
      return timeStr;
    }

    let hours = parseInt(timeParts[0], 10);
    const minutes = parseInt(timeParts[1], 10);
    const period = parts[1].toUpperCase();

    if (isNaN(hours) || isNaN(minutes)) {
      return timeStr;
    }

    if (period === 'PM' && hours !== 12) {
      hours += 12;
    }
    if (period === 'AM' && hours === 12) {
      hours = 0;
    }

    let total = hours * 60 + minutes + offsetMinutes;
    total = ((total % 1440) + 1440) % 1440;

    const newHours24 = Math.floor(total / 60);
    const newMinutes = total % 60;
    const newPeriod = newHours24 >= 12 ? 'PM' : 'AM';
    let displayHours = newHours24 % 12;
    if (displayHours === 0) {
      displayHours = 12;
    }

    return `${displayHours}:${newMinutes.toString().padStart(2, '0')} ${newPeriod}`;
  }

  // ============================================================
  // CHECKBOX ENABLING (date-aware)
  // ============================================================

  static getDateKeyForDate(date: Date): string {
    const y = date.getFullYear();
    const m = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    return `${y}-${m}-${day}`;
  }

  static getDateKey(): string {
    return PrayerManager.getDateKeyForDate(new Date());
  }

  // ============================================================
  // FRIDAY NAMING
  // ============================================================

  static isPrayerCheckable(
    prayer: PrayerModel,
    viewingDate?: Date,
    locationOffsetHours?: number
  ): boolean {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const view = viewingDate ? new Date(viewingDate) : new Date();
    view.setHours(0, 0, 0, 0);

    // Future date — never checkable.
    if (view.getTime() > today.getTime()) {
      return false;
    }

    // Already checked — always allows uncheck, regardless of time.
    if (prayer.checked) {
      return true;
    }

    // Past date — always checkable (catch-up logging).
    if (view.getTime() < today.getTime()) {
      return true;
    }

    // Today — checkable only once the prayer's time has arrived,
    // evaluated in the *location's* timezone. Comparing against
    // device-local time was wrong for a user whose manual location
    // is in a different zone from the device (e.g. Karachi device,
    // New York manual location — Fajr at 5:30 AM NY appears
    // "not yet" at 4:00 AM Karachi even though it happened hours ago).
    const trimmed = prayer.time.trim();
    if (trimmed.length === 0 || trimmed === '--:--') {
      return false;
    }

    const currentMinutes =
      PrayerManager.getCurrentMinutesInLocation(locationOffsetHours);
    const prayerMinutes = PrayerManager.timeToMinutes(prayer.time);

    // prayerMinutes can be 0 for a genuine 12:00 AM prayer — that is
    // a valid time and should be treated as "arrived". The string
    // check above rejects the "--:--" sentinel; here 0 <= current is
    // the correct comparison for both normal and midnight prayers.
    return prayerMinutes <= currentMinutes;
  }

  // ============================================================
  // APPLY TIMES + OFFSETS
  // ============================================================

  static applyDayNames(prayers: PrayerModel[], date?: Date): PrayerModel[] {
    const ref = date ? new Date(date) : new Date();
    const isFriday = ref.getDay() === 5;

    return prayers.map((p): PrayerModel => {
      if (p.id === 'dhuhr') {
        return {
          id: p.id,
          name: isFriday ? 'Jummah' : 'Dhuhr',
          arabicName: isFriday ? 'الجمعة' : 'الظهر',
          time: p.time,
          status: p.status,
          checked: p.checked
        } as PrayerModel;
      }
      return p;
    });
  }

  static applyTimesToPrayers(
    prayers: PrayerModel[],
    times: DailyPrayerTimes,
    offsets: PrayerOffsets = DEFAULT_OFFSETS,
    date?: Date
  ): PrayerModel[] {
    const mapped = prayers.map((prayer): PrayerModel => {
      let rawTime = prayer.time;
      let offset = 0;

      switch (prayer.id) {
        case 'fajr':
          rawTime = times.fajr;
          offset = offsets.fajr;
          break;
        case 'dhuhr':
          rawTime = times.dhuhr;
          offset = offsets.dhuhr;
          break;
        case 'asr':
          rawTime = times.asr;
          offset = offsets.asr;
          break;
        case 'maghrib':
          rawTime = times.maghrib;
          offset = offsets.maghrib;
          break;
        case 'isha':
          rawTime = times.isha;
          offset = offsets.isha;
          break;
      }

      const finalTime = PrayerManager.offsetTime(rawTime, offset);

      return {
        id: prayer.id,
        name: prayer.name,
        arabicName: prayer.arabicName,
        time: finalTime,
        status: prayer.status,
        checked: prayer.checked
      } as PrayerModel;
    });

    return PrayerManager.applyDayNames(mapped, date);
  }

  // ============================================================
  // STATUS RECALCULATION (date-aware, time-only)
  // ============================================================

  static applyTimesToExtraTimings(
    timings: ExtraTiming[],
    times: DailyPrayerTimes,
    offsets: PrayerOffsets = DEFAULT_OFFSETS
  ): ExtraTiming[] {
    return timings.map((timing): ExtraTiming => {
      let rawTime = timing.time;
      let offset = 0;

      switch (timing.id) {
        case 'imsak':
          rawTime = times.imsak;
          offset = offsets.fajr;
          break;
        case 'sunrise':
          rawTime = times.sunrise;
          offset = 0;
          break;
        case 'sunset':
          rawTime = times.sunset;
          offset = 0;
          break;
        case 'firstThird':
          rawTime = times.firstThird;
          offset = 0;
          break;
        case 'midnight':
          rawTime = times.midnight;
          offset = 0;
          break;
        case 'lastThird':
          rawTime = times.lastThird;
          offset = 0;
          break;
      }

      const finalTime = PrayerManager.offsetTime(rawTime, offset);

      return {
        id: timing.id,
        name: timing.name,
        arabicName: timing.arabicName,
        time: finalTime,
        status: timing.status,
        icon: timing.icon
      } as ExtraTiming;
    });
  }

  // ============================================================
  // PERSISTENCE — module static map + AppStorage mirror + disk
  // ============================================================
  //
  // A single source of truth keyed by date:
  //   { "2026-10-01": "{\"fajr\":true,\"dhuhr\":false,...}", ... }
  //
  // Lives as a module-level static, so it survives page destruction
  // and recreation. Mirrored to AppStorage for @StorageLink watchers.
  // Persisted to disk via PreferencesHelper so it survives restarts.

  static updateStatuses(
    prayers: PrayerModel[],
    viewingDate?: Date,
    locationOffsetHours?: number
  ): PrayerModel[] {
    if (viewingDate) {
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const view = new Date(viewingDate);
      view.setHours(0, 0, 0, 0);

      if (view.getTime() !== today.getTime()) {
        return prayers.map((p): PrayerModel => ({
          id: p.id,
          name: p.name,
          arabicName: p.arabicName,
          time: p.time,
          status: p.checked ? 'prayed' : 'abbreviation',
          checked: p.checked
        } as PrayerModel));
      }
    }

    const now = new Date();

    let currentMinutes: number;
    if (locationOffsetHours !== undefined) {
      const deviceOffset = -now.getTimezoneOffset() / 60;
      const deltaMinutes = Math.round((locationOffsetHours - deviceOffset) * 60);
      const deviceMinutes = now.getHours() * 60 + now.getMinutes();
      currentMinutes = (((deviceMinutes + deltaMinutes) % 1440) + 1440) % 1440;
    } else {
      currentMinutes = now.getHours() * 60 + now.getMinutes();
    }

    const times = prayers.map(p => PrayerManager.timeToMinutes(p.time));
    const n = times.length;
    if (n === 0) {
      return prayers;
    }

    // ---- Pre-Fajr window ----
    const fajrMinutes = times[0];
    if (fajrMinutes > 0 && currentMinutes < fajrMinutes) {
      return prayers.map((p, i): PrayerModel => {
        let status: string;
        if (p.checked) {
          status = 'prayed';
        } else if (i === 0) {
          status = 'next';
        } else {
          status = 'abbreviation';
        }
        return {
          id: p.id,
          name: p.name,
          arabicName: p.arabicName,
          time: p.time,
          status: status,
          checked: p.checked
        } as PrayerModel;
      });
    }

    // ---- Post-Isha window ----
    const ishaMinutes = times[n - 1];
    if (ishaMinutes > 0 && currentMinutes > ishaMinutes) {
      return prayers.map((p, i): PrayerModel => {
        let status: string;
        if (p.checked) {
          status = 'prayed';
        } else if (i === n - 1) {
          status = 'pray';
        } else {
          status = 'abbreviation';
        }
        return {
          id: p.id,
          name: p.name,
          arabicName: p.arabicName,
          time: p.time,
          status: status,
          checked: p.checked
        } as PrayerModel;
      });
    }

    // ---- Normal window ----
    let timePrayIndex = -1;
    for (let i = 0; i < n; i++) {
      if (times[i] > 0 && times[i] <= currentMinutes) {
        timePrayIndex = i;
      }
    }
    if (timePrayIndex === -1) {
      timePrayIndex = n - 1;
    }

    let timeNextIndex = -1;
    for (let i = 0; i < n; i++) {
      if (times[i] > currentMinutes) {
        timeNextIndex = i;
        break;
      }
    }

    const actualPrayIndex = timePrayIndex;
    const actualNextIndex = timeNextIndex;

    return prayers.map((p, i): PrayerModel => {
      let status: string;
      if (p.checked) {
        status = 'prayed';
      } else if (i === actualPrayIndex) {
        status = 'pray';
      } else if (i === actualNextIndex) {
        status =
          'next';
      } else {
        status = 'abbreviation';
      }

      return {
        id: p.id,
        name: p.name,
        arabicName: p.arabicName,
        time: p.time,
        status: status,
        checked: p.checked
      } as PrayerModel;
    });
  }

  /** Call once at app startup, after PreferencesHelper.init(). */
  static async primeStateMap(): Promise<void> {
    const raw = await PreferencesHelper.getString(
      PrayerManager.STATE_MAP_PREF_KEY, ''
    );

    if (raw && raw.length > 0) {
      try {
        PrayerManager.stateMap = JSON.parse(raw) as Record<string, string>;
        console.info(
          '[PrayerStore] primed with ' +
            Object.keys(PrayerManager.stateMap).length + ' days'
        );
      } catch (err) {
        console.error('[PrayerStore] prime parse failed');
        PrayerManager.stateMap = {};
      }
    } else {
      PrayerManager.stateMap = {};
      console.info('[PrayerStore] primed empty');
    }

    // Mirror into AppStorage.
    AppStorage.setOrCreate(
      PrayerManager.STATE_MAP_PREF_KEY,
      JSON.stringify(PrayerManager.stateMap)
    );
  }

  static saveStateForDate(dateKey: string, prayers: PrayerModel[]): void {
    const now = Date.now();
    const prev = PrayerManager.getCheckState(dateKey);

    const state: PrayerCheckState = {
      fajr: false,
      dhuhr: false,
      asr: false,
      maghrib: false,
      isha: false,
      fajrAt: undefined,
      dhuhrAt: undefined,
      asrAt: undefined,
      maghribAt: undefined,
      ishaAt: undefined
    };

    for (const p of prayers) {
      const checked = p.checked === true;
      // Preserve previous timestamp when re-saving an already-checked
      // prayer. Stamp `now` the moment a prayer transitions from
      // unchecked → checked. Clear on uncheck.
      switch (p.id) {
        case 'fajr':
          state.fajr = checked;
          state.fajrAt = checked ? (prev.fajr ? prev.fajrAt : now) : undefined;
          break;
        case 'dhuhr':
          state.dhuhr = checked;
          state.dhuhrAt = checked ? (prev.dhuhr ? prev.dhuhrAt : now) : undefined;
          break;
        case 'asr':
          state.asr = checked;
          state.asrAt = checked ? (prev.asr ? prev.asrAt : now) : undefined;
          break;
        case 'maghrib':
          state.maghrib = checked;
          state.maghribAt = checked ? (prev.maghrib ? prev.maghribAt : now) : undefined;
          break;
        case 'isha':
          state.isha = checked;
          state.ishaAt = checked ? (prev.isha ? prev.ishaAt : now) : undefined;
          break;
      }
    }

    const json = JSON.stringify(state);
    PrayerManager.stateMap[dateKey] = json;

    // Mirror to AppStorage.
    const mapJson = JSON.stringify(PrayerManager.stateMap);
    AppStorage.setOrCreate(PrayerManager.STATE_MAP_PREF_KEY, mapJson);

    // Disk write — fire-and-forget.
    PreferencesHelper.setString(PrayerManager.STATE_MAP_PREF_KEY, mapJson)
      .catch((e: Error) =>
      console.error('[PrayerStore] disk write failed: ' + e.message)
      );

    // Bump the version counter so any page observing it re-reads state.
    const prevVer = AppStorage.get<number>(STORAGE_KEY_PRAYER_STATE_VERSION);
    const nextVer = (prevVer === undefined ? 0 : prevVer) + 1;
    AppStorage.setOrCreate(STORAGE_KEY_PRAYER_STATE_VERSION, nextVer);
  }

  static loadStateForDate(
    dateKey: string,
    prayers: PrayerModel[],
    date?: Date
  ): PrayerModel[] {
    const resolvedDate = date !== undefined
      ? date
      : PrayerManager.dateFromKey(dateKey);

    const resetPrayers = prayers.map((p): PrayerModel => ({
      id: p.id,
      name: p.name,
      arabicName: p.arabicName,
      time: p.time,
      status: p.status,
      checked: false
    } as PrayerModel));

    const json = PrayerManager.stateMap[dateKey];
    if (!json || json === '') {
      return PrayerManager.applyDayNames(resetPrayers, resolvedDate);
    }

    try {
      const state = JSON.parse(json) as PrayerCheckState;
      const mapped = resetPrayers.map((p): PrayerModel => {
        let checked = false;
        switch (p.id) {
          case 'fajr':
            checked = state.fajr === true;
            break;
          case 'dhuhr':
            checked = state.dhuhr === true;
            break;
          case 'asr':
            checked = state.asr === true;
            break;
          case 'maghrib':
            checked = state.maghrib === true;
            break;
          case 'isha':
            checked = state.isha === true;
            break;
        }
        return {
          id: p.id,
          name: p.name,
          arabicName: p.arabicName,
          time: p.time,
          status: p.status,
          checked: checked
        } as PrayerModel;
      });
      return PrayerManager.applyDayNames(mapped, resolvedDate);
    } catch (err) {
      console.error('[PrayerStore] parse failed: ' + JSON.stringify(err));
      return PrayerManager.applyDayNames(resetPrayers, resolvedDate);
    }
  }

  /** Synchronous read of a single date's check state. */
  static getCheckState(dateKey: string): PrayerCheckState {
    const json = PrayerManager.stateMap[dateKey];
    const empty: PrayerCheckState = {
      fajr: false,
      dhuhr: false,
      asr: false,
      maghrib: false,
      isha: false,
      fajrAt: undefined,
      dhuhrAt: undefined,
      asrAt: undefined,
      maghribAt: undefined,
      ishaAt: undefined
    };
    if (!json || json === '') {
      return empty;
    }
    try {
      return JSON.parse(json) as PrayerCheckState;
    } catch (err) {
      console.error('[PrayerStore] getCheckState parse failed');
      return empty;
    }
  }

  /**
   * True when all five prayers for the given date are marked as prayed.
   *
   * Used by the reminder system to detect the completion of a day's
   * prayers and shift the rolling scheduling window forward.
   */
  static isDayFullyPrayed(dateKey: string): boolean {
    const state = PrayerManager.getCheckState(dateKey);
    return state.fajr === true
      && state.dhuhr === true
      && state.asr === true
      && state.maghrib === true
      && state.isha === true;
  }

  static getCurrentPrayer(
    prayers: PrayerModel[],
    locationOffsetHours?: number
  ): PrayerModel | null {
    if (prayers.length === 0) {
      return null;
    }
    const currentMinutes = PrayerManager.getCurrentMinutesInLocation(locationOffsetHours);

    let currentIdx = -1;
    for (let i = 0; i < prayers.length; i++) {
      const t = PrayerManager.timeToMinutes(prayers[i].time);
      if (t > 0 && t <= currentMinutes) {
        currentIdx = i;
      }
    }
    if (currentIdx === -1) {
      return null;
    }
    return prayers[currentIdx];
  }

  // ============================================================
  // HEADER HELPERS
  // ============================================================

  /**
   * Reconstruct a local-midnight Date from a 'YYYY-MM-DD' key.
   * Used to derive the day-of-week for Jummah naming when a
   * caller passes a key without a matching Date.
   */
  private static dateFromKey(dateKey: string): Date {
    const parts = dateKey.split('-');
    if (parts.length !== 3) {
      return new Date();
    }
    const y = parseInt(parts[0], 10);
    const m = parseInt(parts[1], 10) - 1;
    const d = parseInt(parts[2], 10);
    if (isNaN(y) || isNaN(m) || isNaN(d)) {
      return new Date();
    }
    const result = new Date(y, m, d);
    result.setHours(0, 0, 0, 0);
    return result;
  }

  private static getCurrentMinutesInLocation(locationOffsetHours?: number): number {
    const now = new Date();
    if (locationOffsetHours === undefined) {
      return now.getHours() * 60 + now.getMinutes();
    }
    const deviceOffset = -now.getTimezoneOffset() / 60;
    const deltaMinutes = Math.round((locationOffsetHours - deviceOffset) * 60);
    const deviceMinutes = now.getHours() * 60 + now.getMinutes();
    return (((deviceMinutes + deltaMinutes) % 1440) + 1440) % 1440;
  }

  /**
   * Return the epoch-ms timestamp at which a specific prayer was marked
   * checked for a given date. Returns undefined when the prayer is not
   * marked, or when the record predates v4.0.7 (no *At fields yet).
   *
   * Synchronous. Reads through getCheckState() so the caller never has
   * to know about the stateMap layout.
   */
  static getMarkedAt(dateKey: string, prayerId: string): number | undefined {
    const state = PrayerManager.getCheckState(dateKey);
    switch (prayerId) {
      case 'fajr':
        return state.fajrAt;
      case 'dhuhr':
        return state.dhuhrAt;
      case 'asr':
        return state.asrAt;
      case 'maghrib':
        return state.maghribAt;
      case 'isha':
        return state.ishaAt;
      default:
        return undefined;
    }
  }
}