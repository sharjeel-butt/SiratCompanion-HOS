// entry/src/main/ets/utils/PrayerManager.ets

import { ExtraTiming, PrayerModel } from '../models/PrayerModel';
import { DailyPrayerTimes } from './PrayerTimeCalculator';
import { PrayerOffsets } from '../helper/SettingsHelper';
import { PreferencesHelper } from '../helper/PreferencesHelper';

export interface PrayerCheckState {
  fajr: boolean;
  dhuhr: boolean;
  asr: boolean;
  maghrib: boolean;
  isha: boolean;
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

  // ============================================================
  // FRIDAY NAMING
  // ============================================================

  static getDateKey(): string {
    return PrayerManager.getDateKeyForDate(new Date());
  }

  // ============================================================
  // APPLY TIMES + OFFSETS
  // ============================================================

  static isPrayerCheckable(prayer: PrayerModel, viewingDate?: Date): boolean {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const view = viewingDate ? new Date(viewingDate) : new Date();
    view.setHours(0, 0, 0, 0);

    if (view.getTime() > today.getTime()) {
      return false;
    }

    if (prayer.checked) {
      return true;
    }

    if (view.getTime() < today.getTime()) {
      return true;
    }

    const now = new Date();
    const currentMinutes = now.getHours() * 60 + now.getMinutes();
    const prayerMinutes = PrayerManager.timeToMinutes(prayer.time);
    return prayerMinutes > 0 && prayerMinutes <= currentMinutes;
  }

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

  // ============================================================
  // STATUS RECALCULATION (date-aware, time-only)
  // ============================================================

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
  // PERSISTENCE — module static map + AppStorage mirror + disk
  // ============================================================
  //
  // A single source of truth keyed by date:
  //   { "2026-10-01": "{\"fajr\":true,\"dhuhr\":false,...}", ... }
  //
  // Lives as a module-level static, so it survives page destruction
  // and recreation. Mirrored to AppStorage for @StorageLink watchers.
  // Persisted to disk via PreferencesHelper so it survives restarts.

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
      } else if (i === actualPrayIndex && i === actualNextIndex) {
        status =
          'both';
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
    const state: PrayerCheckState = {
      fajr: false,
      dhuhr: false,
      asr: false,
      maghrib: false,
      isha: false
    };

    for (const p of prayers) {
      const checked = p.checked === true;
      switch (p.id) {
        case 'fajr':
          state.fajr = checked;
          break;
        case 'dhuhr':
          state.dhuhr = checked;
          break;
        case 'asr':
          state.asr = checked;
          break;
        case 'maghrib':
          state.maghrib = checked;
          break;
        case 'isha':
          state.isha = checked;
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
  }

  static loadStateForDate(
    dateKey: string,
    prayers: PrayerModel[],
    date?: Date
  ): PrayerModel[] {
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
      return PrayerManager.applyDayNames(resetPrayers, date);
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
      return PrayerManager.applyDayNames(mapped, date);
    } catch (err) {
      console.error('[PrayerStore] parse failed: ' + JSON.stringify(err));
      return PrayerManager.applyDayNames(resetPrayers, date);
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
      isha: false
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

  /** Diagnostic: JSON dump of the entire in-memory state map. */
  static debugDump(): string {
    return JSON.stringify(PrayerManager.stateMap);
  }

  // ============================================================
  // HEADER HELPERS
  // ============================================================

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

  static getNextPrayer(
    prayers: PrayerModel[],
    locationOffsetHours?: number
  ): PrayerModel | null {
    if (prayers.length === 0) {
      return null;
    }
    const currentMinutes = PrayerManager.getCurrentMinutesInLocation(locationOffsetHours);

    for (let i = 0; i < prayers.length; i++) {
      const t = PrayerManager.timeToMinutes(prayers[i].time);
      if (t > currentMinutes) {
        return prayers[i];
      }
    }
    return null;
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
}