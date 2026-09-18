// entry/src/main/ets/utils/HomeController.ets

import { PrayerModel, ExtraTiming } from '../models/PrayerModel';
import {
  DailyPrayerTimes,
  PrayerTimeCalculator,
  CalculationMethod,
  AsrShadowRule,
  HighLatitudeRule
} from './PrayerTimeCalculator';
import { PrayerManager } from './PrayerManager';
import { PrayerOffsets } from '../helper/SettingsHelper';
import { LocationMode } from '../models/SettingsModels';
import { LocationCache, CachedLocation, FALLBACK_LOCATION } from './LocationCache';
import { SettingsHelper } from '../helper/SettingsHelper';
import { TimezoneResolver } from './TimezoneResolver';

export interface HomePrayerSnapshot {
  prayers: PrayerModel[];
  extras: ExtraTiming[];
}

export interface HomeHeaderSnapshot {
  currentName: string;
  currentTime: string;
  nextName: string;
  nextTime: string;
}

export interface HomeLocationSnapshot {
  latitude: number;
  longitude: number;
  displayName: string;
  isManual: boolean;
}

/** What the header will show in the "Next" slot. */
export interface NextEventInfo {
  name: string;
  time: string;
}

/** Internal — a single entry in the timeline. */
interface TimelineEvent {
  name: string;
  time: Date;
}

export class HomeController {

  // ============================================================
  // PRAYER TIME COMPUTATION
  // ============================================================

  static buildPrayersForDate(
    date: Date,
    latitude: number,
    longitude: number,
    method: CalculationMethod,
    asrRule: AsrShadowRule,
    highLatRule: HighLatitudeRule,
    offsets: PrayerOffsets,
    template: PrayerModel[]
  ): HomePrayerSnapshot | null {
    if (latitude === 0 && longitude === 0) return null;

    try {
      const times: DailyPrayerTimes = PrayerTimeCalculator.calculateWithDeviceTimezone(
        date, latitude, longitude, method, asrRule, highLatRule
      );
      const withOffsets: PrayerModel[] = PrayerManager.applyTimesToPrayers(
        template, times, offsets, date
      );
      const offsetHours: number = TimezoneResolver.effectiveOffsetForLocation(
        latitude, longitude, date
      );
      const withStatus: PrayerModel[] = PrayerManager.updateStatuses(
        withOffsets, date, offsetHours
      );
      const emptyExtras: ExtraTiming[] = [];
      const snapshot: HomePrayerSnapshot = {
        prayers: withStatus,
        extras: emptyExtras
      };
      return snapshot;
    } catch (err) {
      const error = err as Error;
      console.error(`[HomeController] build failed: ${error.message}`);
      return null;
    }
  }

  static buildExtraTimings(
    date: Date,
    latitude: number,
    longitude: number,
    method: CalculationMethod,
    asrRule: AsrShadowRule,
    highLatRule: HighLatitudeRule,
    offsets: PrayerOffsets,
    template: ExtraTiming[]
  ): ExtraTiming[] {
    if (latitude === 0 && longitude === 0) return template;
    try {
      const times: DailyPrayerTimes = PrayerTimeCalculator.calculateWithDeviceTimezone(
        date, latitude, longitude, method, asrRule, highLatRule
      );
      return PrayerManager.applyTimesToExtraTimings(template, times, offsets);
    } catch (err) {
      return template;
    }
  }

  // ============================================================
  // TODAY HEADER
  // ============================================================

  static buildTodayHeader(
    latitude: number,
    longitude: number,
    method: CalculationMethod,
    asrRule: AsrShadowRule,
    highLatRule: HighLatitudeRule,
    offsets: PrayerOffsets,
    template: PrayerModel[]
  ): HomeHeaderSnapshot | null {
    if (latitude === 0 && longitude === 0) return null;
    const today = new Date();
    try {
      const times: DailyPrayerTimes = PrayerTimeCalculator.calculateWithDeviceTimezone(
        today, latitude, longitude, method, asrRule, highLatRule
      );
      const withOffsets: PrayerModel[] = PrayerManager.applyTimesToPrayers(
        template, times, offsets, today
      );
      const offsetHours: number = TimezoneResolver.effectiveOffsetForLocation(
        latitude, longitude, today
      );
      const withStatus: PrayerModel[] = PrayerManager.updateStatuses(
        withOffsets, today, offsetHours
      );

      const current: PrayerModel | null = PrayerManager.getCurrentPrayer(
        withStatus, offsetHours
      );
      const nextEvent: NextEventInfo | null = HomeController.computeNextEvent(
        today, latitude, longitude, method, asrRule, highLatRule, offsets
      );

      const snapshot: HomeHeaderSnapshot = {
        currentName: current ? current.name : '—',
        currentTime: current ? current.time : '--:--',
        nextName: nextEvent ? nextEvent.name : '—',
        nextTime: nextEvent ? nextEvent.time : '--:--'
      };
      return snapshot;
    } catch (err) {
      return null;
    }
  }

  // ============================================================
  // TIMELINE — next event including extras after Isha
  // ============================================================
  //
  // The event sequence is:
  //   Fajr -> Dhuhr -> Asr -> Maghrib -> Isha
  //        -> First Third -> Midnight -> Last Third -> Imsak
  //        -> (next day) Fajr -> ...
  //
  // We build events for yesterday, today, and tomorrow, then pick
  // the first one strictly after `now`. Including yesterday covers
  // the "just past midnight" window where yesterday's Last Third is
  // still ahead.

  static computeNextEvent(
    now: Date,
    latitude: number,
    longitude: number,
    method: CalculationMethod,
    asrRule: AsrShadowRule,
    highLatRule: HighLatitudeRule,
    offsets: PrayerOffsets
  ): NextEventInfo | null {
    const events: TimelineEvent[] = [];

    const anchor = new Date(now);
    anchor.setHours(0, 0, 0, 0);

    for (let delta = -1; delta <= 1; delta++) {
      const day = new Date(anchor);
      day.setDate(day.getDate() + delta);

      try {
        const times: DailyPrayerTimes = PrayerTimeCalculator.calculateWithDeviceTimezone(
          day, latitude, longitude, method, asrRule, highLatRule
        );
        HomeController.appendDayEvents(events, day, times, offsets);
      } catch (err) {
        // Skip this day silently; the other two days will cover "next".
      }
    }

    events.sort((a: TimelineEvent, b: TimelineEvent): number =>
    a.time.getTime() - b.time.getTime()
    );

    const nowMs: number = now.getTime();
    for (let i = 0; i < events.length; i++) {
      const e: TimelineEvent = events[i];
      if (e.time.getTime() > nowMs) {
        const info: NextEventInfo = {
          name: e.name,
          time: HomeController.formatEventTime(e.time)
        };
        return info;
      }
    }
    return null;
  }

  private static appendDayEvents(
    events: TimelineEvent[],
    prayerDay: Date,
    times: DailyPrayerTimes,
    offsets: PrayerOffsets
  ): void {
    // ---- 5 prayers ----
    const fajrEv: TimelineEvent = {
      name: 'Fajr',
      time: HomeController.parseToDate(
        PrayerManager.offsetTime(times.fajr, offsets.fajr), prayerDay, false)
    };
    events.push(fajrEv);

    const dhuhrEv: TimelineEvent = {
      name: 'Dhuhr',
      time: HomeController.parseToDate(
        PrayerManager.offsetTime(times.dhuhr, offsets.dhuhr), prayerDay, false)
    };
    events.push(dhuhrEv);

    const asrEv: TimelineEvent = {
      name: 'Asr',
      time: HomeController.parseToDate(
        PrayerManager.offsetTime(times.asr, offsets.asr), prayerDay, false)
    };
    events.push(asrEv);

    const maghribEv: TimelineEvent = {
      name: 'Maghrib',
      time: HomeController.parseToDate(
        PrayerManager.offsetTime(times.maghrib, offsets.maghrib), prayerDay, false)
    };
    events.push(maghribEv);

    const ishaEv: TimelineEvent = {
      name: 'Isha',
      time: HomeController.parseToDate(
        PrayerManager.offsetTime(times.isha, offsets.isha), prayerDay, false)
    };
    events.push(ishaEv);

    // ---- 3 night events — no user offset applied ----
    const firstThirdEv: TimelineEvent = {
      name: 'First Third',
      time: HomeController.parseToDate(times.firstThird, prayerDay, true)
    };
    events.push(firstThirdEv);

    const midnightEv: TimelineEvent = {
      name: 'Midnight',
      time: HomeController.parseToDate(times.midnight, prayerDay, true)
    };
    events.push(midnightEv);

    const lastThirdEv: TimelineEvent = {
      name: 'Last Third',
      time: HomeController.parseToDate(times.lastThird, prayerDay, true)
    };
    events.push(lastThirdEv);

    // ---- Imsak — inherits the Fajr offset ----
    const imsakEv: TimelineEvent = {
      name: 'Imsak',
      time: HomeController.parseToDate(
        PrayerManager.offsetTime(times.imsak, offsets.fajr), prayerDay, false)
    };
    events.push(imsakEv);
  }

  /**
   * Parse "5:24 AM" into an absolute Date.
   *
   * @param isEveningEvent When true, an early-morning (0-5 AM) result
   *        means the event actually happens on the following calendar
   *        day. Needed for First Third / Midnight / Last Third, which
   *        can spill past midnight of the prayer day.
   */
  private static parseToDate(
    timeStr: string,
    prayerDay: Date,
    isEveningEvent: boolean
  ): Date {
    const result = new Date(prayerDay);
    result.setHours(0, 0, 0, 0);

    const trimmed: string = timeStr.trim();
    if (trimmed === '' || trimmed === '--:--') return result;

    const parts: string[] = trimmed.split(' ');
    if (parts.length !== 2) return result;

    const timeParts: string[] = parts[0].split(':');
    if (timeParts.length !== 2) return result;

    let hours: number = parseInt(timeParts[0], 10);
    const minutes: number = parseInt(timeParts[1], 10);
    const period: string = parts[1].toUpperCase();

    if (isNaN(hours) || isNaN(minutes)) return result;

    if (period === 'PM' && hours !== 12) hours += 12;
    if (period === 'AM' && hours === 12) hours = 0;

    result.setHours(hours, minutes, 0, 0);

    if (isEveningEvent && hours < 6) {
      result.setDate(result.getDate() + 1);
    }
    return result;
  }

  private static formatEventTime(date: Date): string {
    let hours: number = date.getHours();
    const minutes: number = date.getMinutes();
    const ampm: string = hours >= 12 ? 'PM' : 'AM';
    hours = hours % 12;
    if (hours === 0) hours = 12;
    const minutesStr: string = minutes.toString().padStart(2, '0');
    return `${hours}:${minutesStr} ${ampm}`;
  }

  // ============================================================
  // LOCATION ORCHESTRATION
  // ============================================================

  static async loadLocationForMode(mode: LocationMode): Promise<HomeLocationSnapshot> {
    if (mode === LocationMode.MANUAL) {
      const coords = await SettingsHelper.getManualCoords();
      if (coords.lat !== 0 || coords.lng !== 0) {
        const city: string = coords.cityName.length > 0 ? coords.cityName : 'Manual Location';
        const snapshot: HomeLocationSnapshot = {
          latitude: coords.lat,
          longitude: coords.lng,
          displayName: `${city} (Manual)`,
          isManual: true
        };
        return snapshot;
      }
      const snapshot: HomeLocationSnapshot = {
        latitude: 0,
        longitude: 0,
        displayName: 'Set Manual Location in Settings',
        isManual: true
      };
      return snapshot;
    }

    const cached: CachedLocation | null = await LocationCache.load();
    if (cached) {
      const snapshot: HomeLocationSnapshot = {
        latitude: cached.latitude,
        longitude: cached.longitude,
        displayName: cached.cityName,
        isManual: false
      };
      return snapshot;
    }
    const fallback: HomeLocationSnapshot = {
      latitude: FALLBACK_LOCATION.latitude,
      longitude: FALLBACK_LOCATION.longitude,
      displayName: FALLBACK_LOCATION.cityName,
      isManual: false
    };
    return fallback;
  }
}