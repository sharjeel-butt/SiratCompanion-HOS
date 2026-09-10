// entry/src/main/ets/utils/PrayerManager.ets

import { Prayer, ExtraTiming } from '../models/Prayer';
import { DailyPrayerTimes } from './PrayerTimeCalculator';

// ---- Interface for daily check state ----
export interface PrayerCheckState {
  fajr: boolean;
  dhuhr: boolean;
  asr: boolean;
  maghrib: boolean;
  isha: boolean;
}

export class PrayerManager {

  // ---- Time parsing ----
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

  // ---- Checkbox enabling ----
  static isPrayerCheckable(prayer: Prayer): boolean {
    if (prayer.checked) return true;

    const now = new Date();
    const currentMinutes = now.getHours() * 60 + now.getMinutes();
    const prayerMinutes = PrayerManager.timeToMinutes(prayer.time);

    return prayerMinutes > 0 && prayerMinutes <= currentMinutes;
  }

  // ---- Apply calculated times ----
  static applyTimesToPrayers(prayers: Prayer[], times: DailyPrayerTimes): Prayer[] {
    return prayers.map((prayer): Prayer => {
      let newTime = prayer.time;
      switch (prayer.id) {
        case 'fajr':    newTime = times.fajr;    break;
        case 'dhuhr':   newTime = times.dhuhr;   break;
        case 'asr':     newTime = times.asr;     break;
        case 'maghrib': newTime = times.maghrib; break;
        case 'isha':    newTime = times.isha;    break;
      }
      return {
        id: prayer.id,
        name: prayer.name,
        arabicName: prayer.arabicName,
        time: newTime,
        status: prayer.status,
        checked: prayer.checked
      } as Prayer;
    });
  }

  static applyTimesToExtraTimings(timings: ExtraTiming[], times: DailyPrayerTimes): ExtraTiming[] {
    return timings.map((timing): ExtraTiming => {
      let newTime = timing.time;
      switch (timing.id) {
        case 'imsak':      newTime = times.imsak;      break;
        case 'sunrise':    newTime = times.sunrise;    break;
        case 'sunset':     newTime = times.sunset;     break;
        case 'firstThird': newTime = times.firstThird; break;
        case 'midnight':   newTime = times.midnight;   break;
        case 'lastThird':  newTime = times.lastThird;  break;
      }
      return {
        id: timing.id,
        name: timing.name,
        arabicName: timing.arabicName,
        time: newTime,
        status: timing.status,
        icon: timing.icon
      } as ExtraTiming;
    });
  }

  // ---- Status recalculation ----
  static updateStatuses(prayers: Prayer[]): Prayer[] {
    const now = new Date();
    const currentMinutes = now.getHours() * 60 + now.getMinutes();
    const times = prayers.map(p => PrayerManager.timeToMinutes(p.time));
    const n = times.length;
    if (n === 0) return prayers;

    let timePrayIndex = -1;
    for (let i = 0; i < n; i++) {
      if (times[i] > 0 && times[i] <= currentMinutes) timePrayIndex = i;
    }
    if (timePrayIndex === -1) timePrayIndex = n - 1;

    let timeNextIndex = -1;
    for (let i = 0; i < n; i++) {
      if (times[i] > currentMinutes) { timeNextIndex = i; break; }
    }
    if (timeNextIndex === -1) timeNextIndex = 0;

    let actualPrayIndex = -1;
    for (let i = 0; i < n; i++) {
      const idx = (timePrayIndex + i) % n;
      if (!prayers[idx].checked) { actualPrayIndex = idx; break; }
    }

    let actualNextIndex = -1;
    for (let i = 0; i < n; i++) {
      const idx = (timeNextIndex + i) % n;
      if (!prayers[idx].checked) { actualNextIndex = idx; break; }
    }

    return prayers.map((p, i): Prayer => {
      let status: string;
      if (p.checked) status = 'prayed';
      else if (i === actualPrayIndex && i === actualNextIndex) status = 'both';
      else if (i === actualPrayIndex) status = 'pray';
      else if (i === actualNextIndex) status = 'next';
      else status = 'abbreviation';

      return {
        id: p.id,
        name: p.name,
        arabicName: p.arabicName,
        time: p.time,
        status: status,
        checked: p.checked
      } as Prayer;
    });
  }

  // ---- Date key helpers ----
  static getDateKey(): string {
    const d = new Date();
    const y = d.getFullYear();
    const m = (d.getMonth() + 1).toString().padStart(2, '0');
    const day = d.getDate().toString().padStart(2, '0');
    return `${y}-${m}-${day}`;
  }

  // ---- Date-wise persistence ----
  static saveTodayState(prayers: Prayer[]): void {
    const storageKey = `prayer_state_${PrayerManager.getDateKey()}`;

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

  static loadTodayState(prayers: Prayer[]): Prayer[] {
    const storageKey = `prayer_state_${PrayerManager.getDateKey()}`;
    PersistentStorage.persistProp(storageKey, '');

    const json = AppStorage.get<string>(storageKey);
    if (!json || json === '') return prayers;

    try {
      const state = JSON.parse(json) as PrayerCheckState;
      return prayers.map((p): Prayer => {
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
        } as Prayer;
      });
    } catch (err) {
      console.error(`Failed to parse today's prayer state: ${JSON.stringify(err)}`);
      return prayers;
    }
  }

  // ---- Query helpers for the header ----
  static getCurrentPrayer(prayers: Prayer[]): Prayer | null {
    const p = prayers.find(x => x.status === 'pray' || x.status === 'both');
    return p ? p : null;
  }

  static getNextPrayer(prayers: Prayer[]): Prayer | null {
    const p = prayers.find(x => x.status === 'next' || x.status === 'both');
    return p ? p : null;
  }
}