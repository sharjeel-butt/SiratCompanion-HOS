// entry/src/main/ets/utils/PrayerManager.ets

import { ExtraTiming, PrayerModel } from '../models/PrayerModel';
import { DailyPrayerTimes } from './PrayerTimeCalculator';
import { PrayerOffsets } from '../helper/SettingsHelper';

export interface PrayerCheckState {
  fajr: boolean;
  dhuhr: boolean;
  asr: boolean;
  maghrib: boolean;
  isha: boolean;
}

const DEFAULT_OFFSETS: PrayerOffsets = {
  fajr: 0, dhuhr: 0, asr: 0, maghrib: 0, isha: 0
};

export class PrayerManager {

  // ============================================================
  // TIME PARSING
  // ============================================================

  static timeToMinutes(timeStr: string): number {
    const trimmed = timeStr.trim();
    if (trimmed === '' || trimmed === '--:--') return 0;

    const parts = trimmed.split(' ');
    if (parts.length !== 2) return 0;

    const timeParts = parts[0].split(':');
    if (timeParts.length !== 2) return 0;

    let hours = parseInt(timeParts[0], 10);
    const minutes = parseInt(timeParts[1], 10);
    const period = parts[1].toUpperCase();

    if (isNaN(hours) || isNaN(minutes)) return 0;

    if (period === 'PM' && hours !== 12) hours += 12;
    if (period === 'AM' && hours === 12) hours = 0;

    return hours * 60 + minutes;
  }

  // ============================================================
  // OFFSET
  // ============================================================

  static offsetTime(timeStr: string, offsetMinutes: number): string {
    if (offsetMinutes === 0) return timeStr;
    if (timeStr === '--:--' || timeStr.trim() === '') return timeStr;

    const parts = timeStr.trim().split(' ');
    if (parts.length !== 2) return timeStr;

    const timeParts = parts[0].split(':');
    if (timeParts.length !== 2) return timeStr;

    let hours = parseInt(timeParts[0], 10);
    const minutes = parseInt(timeParts[1], 10);
    const period = parts[1].toUpperCase();

    if (isNaN(hours) || isNaN(minutes)) return timeStr;

    if (period === 'PM' && hours !== 12) hours += 12;
    if (period === 'AM' && hours === 12) hours = 0;

    let total = hours * 60 + minutes + offsetMinutes;
    total = ((total % 1440) + 1440) % 1440;

    const newHours24 = Math.floor(total / 60);
    const newMinutes = total % 60;
    const newPeriod = newHours24 >= 12 ? 'PM' : 'AM';
    let displayHours = newHours24 % 12;
    if (displayHours === 0) displayHours = 12;

    return `${displayHours}:${newMinutes.toString().padStart(2, '0')} ${newPeriod}`;
  }

  // ============================================================
  // DATE HELPERS
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
  // CHECKBOX ENABLING (date-aware)
  // ============================================================

  /**
   * - Today: enabled only for prayers whose time has passed
   * - Past dates: all enabled
   * - Future dates: all disabled
   * - Already checked: always enabled (so user can uncheck)
   */
  static isPrayerCheckable(prayer: PrayerModel, viewingDate?: Date): boolean {
    // Normalize today and viewing date to midnight
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const view = viewingDate ? new Date(viewingDate) : new Date();
    view.setHours(0, 0, 0, 0);

    // ---- FUTURE: always disabled, even if somehow already checked ----
    if (view.getTime() > today.getTime()) {
      return false;
    }

    // ---- Already checked: allow unchecking ----
    if (prayer.checked) {
      return true;
    }

    // ---- PAST: always enabled ----
    if (view.getTime() < today.getTime()) {
      return true;
    }

    // ---- TODAY: only enabled if the prayer's time has passed ----
    const now = new Date();
    const currentMinutes = now.getHours() * 60 + now.getMinutes();
    const prayerMinutes = PrayerManager.timeToMinutes(prayer.time);
    return prayerMinutes > 0 && prayerMinutes <= currentMinutes;
  }

  // ============================================================
  // FRIDAY NAMING
  // ============================================================

  static applyDayNames(prayers: PrayerModel[], date?: Date): PrayerModel[] {
    const ref = date ? new Date(date) : new Date();
    const isFriday = ref.getDay() === 5;   // 0=Sun, 5=Fri

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
  // APPLY TIMES + OFFSETS
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
        case 'fajr':    rawTime = times.fajr;    offset = offsets.fajr;    break;
        case 'dhuhr':   rawTime = times.dhuhr;   offset = offsets.dhuhr;   break;
        case 'asr':     rawTime = times.asr;     offset = offsets.asr;     break;
        case 'maghrib': rawTime = times.maghrib; offset = offsets.maghrib; break;
        case 'isha':    rawTime = times.isha;    offset = offsets.isha;    break;
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

  static applyTimesToExtraTimings(
    timings: ExtraTiming[],
    times: DailyPrayerTimes,
    offsets: PrayerOffsets = DEFAULT_OFFSETS
  ): ExtraTiming[] {
    return timings.map((timing): ExtraTiming => {
      let rawTime = timing.time;
      let offset = 0;

      switch (timing.id) {
        case 'imsak':      rawTime = times.imsak;      offset = offsets.fajr; break;
        case 'sunrise':    rawTime = times.sunrise;    offset = 0; break;
        case 'sunset':     rawTime = times.sunset;     offset = 0; break;
        case 'firstThird': rawTime = times.firstThird; offset = 0; break;
        case 'midnight':   rawTime = times.midnight;   offset = 0; break;
        case 'lastThird':  rawTime = times.lastThird;  offset = 0; break;
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
  // STATUS RECALCULATION (date-aware)
  // ============================================================

  /**
   * Recompute prayer statuses.
   *
   * @param prayers               PrayerModel list (already carries times + checked flags)
   * @param viewingDate           The date being viewed. If omitted, assumes today.
   * @param locationOffsetHours   Effective offset of the *location* being shown
   *                              (hours east of UTC). When provided, "current time"
   *                              is computed in the location's local time, so
   *                              statuses stay correct even when the user is
   *                              viewing a distant city.
   */
  static updateStatuses(
    prayers: PrayerModel[],
    viewingDate?: Date,
    locationOffsetHours?: number
  ): PrayerModel[] {
    // Non-today dates: no NEXT/Pray highlighting, but keep the "Prayed" badge
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

    // Compute "current minutes" in the location's local time.
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
    if (n === 0) return prayers;

    // ---- Pre-Fajr window ----
    const fajrMinutes = times[0];
    if (fajrMinutes > 0 && currentMinutes < fajrMinutes) {
      return prayers.map((p, i): PrayerModel => {
        let status: string;
        if (p.checked) status = 'prayed';
        else if (i === 0) status = 'next';
        else status = 'abbreviation';
        return {
          id: p.id, name: p.name, arabicName: p.arabicName,
          time: p.time, status: status, checked: p.checked
        } as PrayerModel;
      });
    }

    // ---- Post-Isha window ----
    // Past the last prayer of the day (Isha) but before midnight.
    // Isha stays "current" if unchecked; otherwise no current prayer.
    // The header computes tomorrow's Fajr as "next" when there is
    // no next prayer in today's array.
    const ishaMinutes = times[n - 1];
    if (ishaMinutes > 0 && currentMinutes > ishaMinutes) {
      return prayers.map((p, i): PrayerModel => {
        let status: string;
        if (p.checked) status = 'prayed';
        else if (i === n - 1) status = 'pray';  // Isha still current
        else status = 'abbreviation';
        return {
          id: p.id, name: p.name, arabicName: p.arabicName,
          time: p.time, status: status, checked: p.checked
        } as PrayerModel;
      });
    }

    // ---- Normal window (between Fajr and Isha inclusive) ----

    let timePrayIndex = -1;
    for (let i = 0; i < n; i++) {
      if (times[i] > 0 && times[i] <= currentMinutes) timePrayIndex = i;
    }
    if (timePrayIndex === -1) timePrayIndex = n - 1;

    let timeNextIndex = -1;
    for (let i = 0; i < n; i++) {
      if (times[i] > currentMinutes) { timeNextIndex = i; break; }
    }
    // No fallback — the post-Isha window already returned above, so
    // timeNextIndex will always be found here.

    // Current and next are decided by time ONLY — not by which
    // prayers are already checked. A prayer remains "current" for
    // its whole window even after the user marks it as prayed.
    const actualPrayIndex = timePrayIndex;
    const actualNextIndex = timeNextIndex;

    return prayers.map((p, i): PrayerModel => {
      let status: string;
      if (p.checked) status = 'prayed';
      else if (i === actualPrayIndex && i === actualNextIndex) status = 'both';
      else if (i === actualPrayIndex) status = 'pray';
      else if (i === actualNextIndex) status = 'next';
      else status = 'abbreviation';

      return {
        id: p.id, name: p.name, arabicName: p.arabicName,
        time: p.time, status: status, checked: p.checked
      } as PrayerModel;
    });
  }

  // ============================================================
  // DATE-WISE PERSISTENCE (per-date storage)
  // ============================================================

  static saveStateForDate(dateKey: string, prayers: PrayerModel[]): void {
    const storageKey = `prayer_state_${dateKey}`;

    const state: PrayerCheckState = {
      fajr: false, dhuhr: false, asr: false, maghrib: false, isha: false
    };

    for (const p of prayers) {
      const checked = p.checked === true;
      switch (p.id) {
        case 'fajr':     state.fajr = checked; break;
        case 'dhuhr':    state.dhuhr = checked; break;
        case 'asr':      state.asr = checked; break;
        case 'maghrib':  state.maghrib = checked; break;
        case 'isha':     state.isha = checked; break;
      }
    }

    PersistentStorage.persistProp(storageKey, '');
    AppStorage.setOrCreate(storageKey, JSON.stringify(state));
  }

  static loadStateForDate(dateKey: string, prayers: PrayerModel[], date?: Date): PrayerModel[] {
    const storageKey = `prayer_state_${dateKey}`;
    PersistentStorage.persistProp(storageKey, '');

    // ✅ Reset all checkboxes to false FIRST
    const resetPrayers = prayers.map((p): PrayerModel => ({
      id: p.id,
      name: p.name,
      arabicName: p.arabicName,
      time: p.time,
      status: p.status,
      checked: false
    } as PrayerModel));

    const json = AppStorage.get<string>(storageKey);

    // No saved state → everything stays unchecked
    if (!json || json === '') {
      return PrayerManager.applyDayNames(resetPrayers, date);
    }

    try {
      const state = JSON.parse(json) as PrayerCheckState;

      const mapped = resetPrayers.map((p): PrayerModel => {
        let checked = false;
        switch (p.id) {
          case 'fajr':     checked = state.fajr === true; break;
          case 'dhuhr':    checked = state.dhuhr === true; break;
          case 'asr':      checked = state.asr === true; break;
          case 'maghrib':  checked = state.maghrib === true; break;
          case 'isha':     checked = state.isha === true; break;
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
      console.error(`Failed to parse state for ${dateKey}: ${JSON.stringify(err)}`);
      return PrayerManager.applyDayNames(resetPrayers, date);
    }
  }

  // ============================================================
  // HEADER HELPERS
  // ============================================================

  /**
   * The current prayer is the last prayer whose time has already
   * passed — regardless of whether it has been marked as prayed.
   * Returns null in the pre-Fajr window (nothing today has passed).
   */
  static getCurrentPrayer(
    prayers: PrayerModel[],
    locationOffsetHours?: number
  ): PrayerModel | null {
    if (prayers.length === 0) return null;
    const currentMinutes = PrayerManager.getCurrentMinutesInLocation(locationOffsetHours);

    let currentIdx = -1;
    for (let i = 0; i < prayers.length; i++) {
      const t = PrayerManager.timeToMinutes(prayers[i].time);
      if (t > 0 && t <= currentMinutes) currentIdx = i;
    }
    if (currentIdx === -1) return null;
    return prayers[currentIdx];
  }

  /**
   * The next prayer is the first prayer whose time has NOT yet
   * passed. Returns null when all prayers today have passed
   * (caller falls back to the extended timeline for night extras).
   */
  static getNextPrayer(
    prayers: PrayerModel[],
    locationOffsetHours?: number
  ): PrayerModel | null {
    if (prayers.length === 0) return null;
    const currentMinutes = PrayerManager.getCurrentMinutesInLocation(locationOffsetHours);

    for (let i = 0; i < prayers.length; i++) {
      const t = PrayerManager.timeToMinutes(prayers[i].time);
      if (t > currentMinutes) return prayers[i];
    }
    return null;
  }

  /**
   * "Now" in the location's local time, expressed as minutes from
   * midnight. Falls back to the device clock when no offset is given.
   */
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