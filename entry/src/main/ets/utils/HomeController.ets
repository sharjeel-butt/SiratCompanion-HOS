// entry/src/main/ets/utils/HomeController.ets

import { ExtraTiming, PrayerModel } from '../prayer/PrayerModel';
import {
  AsrShadowRule,
  CalculationMethod,
  DailyPrayerTimes,
  HighLatitudeRule,
  PrayerTimeCalculator
} from '../prayer/PrayerTimeCalculator';
import { PrayerManager } from '../prayer/PrayerManager';
import { PrayerOffsets, SettingsHelper } from '../helper/SettingsHelper';
import { LocationMode } from '../models/SettingsModels';
import { CachedLocation, FALLBACK_LOCATION, LocationCache } from './LocationCache';
import { L } from '../helper/LocalizationHelper';
import { TimezoneResolver } from './TimezoneResolver';
import {
  AdvancedCalcSettings, DEFAULT_ADVANCED_CALC
} from '../models/AdvancedCalcModels';

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

export interface NextEventInfo {
  name: string;
  time: string;
}

interface TimelineEvent {
  name: string;
  time: Date;
}

const MS_PER_DAY = 86400000;

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
    template: PrayerModel[],
    advanced: AdvancedCalcSettings = DEFAULT_ADVANCED_CALC
  ): HomePrayerSnapshot | null {
    if (latitude === 0 && longitude === 0) {
      return null;
    }

    try {
      const anchor = HomeController.getLocationAnchor(latitude, longitude, date);

      const times: DailyPrayerTimes =
        PrayerTimeCalculator.calculateWithDeviceTimezone(
          anchor, latitude, longitude, method, asrRule, highLatRule,
          advanced
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
    template: ExtraTiming[],
    advanced: AdvancedCalcSettings = DEFAULT_ADVANCED_CALC
  ): ExtraTiming[] {
    if (latitude === 0 && longitude === 0) {
      return template;
    }
    try {
      const anchor = HomeController.getLocationAnchor(latitude, longitude, date);
      const times: DailyPrayerTimes =
        PrayerTimeCalculator.calculateWithDeviceTimezone(
          anchor, latitude, longitude, method, asrRule, highLatRule,
          advanced
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
    template: PrayerModel[],
    advanced: AdvancedCalcSettings = DEFAULT_ADVANCED_CALC
  ): HomeHeaderSnapshot | null {
    if (latitude === 0 && longitude === 0) {
      return null;
    }
    const today = new Date();
    const anchor = HomeController.getLocationAnchor(latitude, longitude, today);
    try {
      const times: DailyPrayerTimes =
        PrayerTimeCalculator.calculateWithDeviceTimezone(
          anchor, latitude, longitude, method, asrRule, highLatRule,
          advanced
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

      let current: PrayerModel | null = PrayerManager.getCurrentPrayer(
        withStatus, offsetHours
      );

      // Before Fajr, no prayer has occurred yet today. The logical
      // "current" prayer is the previous day's Isha, whose window
      // runs from Maghrib through to the next Fajr.
      if (current === null) {
        current = HomeController.buildPreviousIsha(
          today, latitude, longitude, method, asrRule, highLatRule,
          offsets, advanced
        );
      }

      const nextEvent: NextEventInfo | null = HomeController.computeNextEvent(
        today, latitude, longitude, method, asrRule, highLatRule, offsets,
        advanced
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

  /**
   * Before Fajr, the app has no current prayer for today. The
   * correct display is the previous day's Isha — its window runs
   * from Maghrib through the next Fajr.
   *
   * Returns a minimal PrayerModel carrying only the fields the
   * header needs. The result is not added to any persistent state.
   */
  private static buildPreviousIsha(
    today: Date,
    latitude: number,
    longitude: number,
    method: CalculationMethod,
    asrRule: AsrShadowRule,
    highLatRule: HighLatitudeRule,
    offsets: PrayerOffsets,
    advanced: AdvancedCalcSettings
  ): PrayerModel | null {
    const yesterday = new Date(today.getTime() - MS_PER_DAY);
    const anchor = HomeController.getLocationAnchor(
      latitude, longitude, yesterday
    );

    try {
      const yTimes: DailyPrayerTimes =
        PrayerTimeCalculator.calculateWithDeviceTimezone(
          anchor, latitude, longitude, method, asrRule, highLatRule,
          advanced
        );
      const yIsha = PrayerManager.offsetTime(yTimes.isha, offsets.isha);

      const result: PrayerModel = {
        id: 'isha',
        name: 'Isha',
        arabicName: 'العشاء',
        time: yIsha,
        status: 'pray',
        checked: false
      };
      return result;
    } catch (err) {
      return null;
    }
  }

  // ============================================================
  // TIMELINE — next event including extras after Isha
  // ============================================================

  static computeNextEvent(
    now: Date,
    latitude: number,
    longitude: number,
    method: CalculationMethod,
    asrRule: AsrShadowRule,
    highLatRule: HighLatitudeRule,
    offsets: PrayerOffsets,
    advanced: AdvancedCalcSettings = DEFAULT_ADVANCED_CALC
  ): NextEventInfo | null {
    const events: TimelineEvent[] = [];

    const anchor = HomeController.getLocationAnchor(latitude, longitude, now);
    anchor.setHours(0, 0, 0, 0);

    for (let delta = -1; delta <= 1; delta++) {
      const day = new Date(anchor);
      day.setDate(day.getDate() + delta);

      try {
        const times: DailyPrayerTimes =
          PrayerTimeCalculator.calculateWithDeviceTimezone(
            day, latitude, longitude, method, asrRule, highLatRule,
            advanced
          );
        HomeController.appendDayEvents(events, day, times, offsets);
      } catch (err) {
        // Skip this day silently; the other two days cover "next".
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

  static async loadLocationForMode(mode: LocationMode): Promise<HomeLocationSnapshot> {
    const manualLabel = L.get('manual_location');

    if (mode === LocationMode.MANUAL) {
      const coords = await SettingsHelper.getManualCoords();
      if (coords.lat !== 0 || coords.lng !== 0) {
        const city: string = coords.cityName.length > 0 ? coords.cityName : manualLabel;
        const snapshot: HomeLocationSnapshot = {
          latitude: coords.lat,
          longitude: coords.lng,
          displayName: `${city} (${manualLabel})`,
          isManual: true
        };
        return snapshot;
      }
      const snapshot: HomeLocationSnapshot = {
        latitude: 0,
        longitude: 0,
        displayName: L.get('set_manual_location'),
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
      displayName: L.get('default_location'),
      isManual: false
    };
    return fallback;
  }

  private static appendDayEvents(
    events: TimelineEvent[],
    prayerDay: Date,
    times: DailyPrayerTimes,
    offsets: PrayerOffsets
  ): void {
    const isFriday = prayerDay.getDay() === 5;
    const dhuhrName = isFriday ? 'Jummah' : 'Dhuhr';

    const fajrEv: TimelineEvent = {
      name: 'Fajr',
      time: HomeController.parseToDate(
        PrayerManager.offsetTime(times.fajr, offsets.fajr), prayerDay, false)
    };
    events.push(fajrEv);

    const dhuhrEv: TimelineEvent = {
      name: dhuhrName,
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

    const imsakEv: TimelineEvent = {
      name: 'Imsak',
      time: HomeController.parseToDate(
        PrayerManager.offsetTime(times.imsak, offsets.fajr), prayerDay, false)
    };
    events.push(imsakEv);
  }

  private static parseToDate(
    timeStr: string,
    prayerDay: Date,
    isEveningEvent: boolean
  ): Date {
    const result = new Date(prayerDay);
    result.setHours(0, 0, 0, 0);

    const trimmed: string = timeStr.trim();
    if (trimmed === '' || trimmed === '--:--') {
      return result;
    }

    const parts: string[] = trimmed.split(' ');
    if (parts.length !== 2) {
      return result;
    }

    const timeParts: string[] = parts[0].split(':');
    if (timeParts.length !== 2) {
      return result;
    }

    let hours: number = parseInt(timeParts[0], 10);
    const minutes: number = parseInt(timeParts[1], 10);
    const period: string = parts[1].toUpperCase();

    if (isNaN(hours) || isNaN(minutes)) {
      return result;
    }

    if (period === 'PM' && hours !== 12) {
      hours += 12;
    }
    if (period === 'AM' && hours === 12) {
      hours = 0;
    }

    result.setHours(hours, minutes, 0, 0);

    if (isEveningEvent && hours < 6) {
      result.setDate(result.getDate() + 1);
    }
    return result;
  }

  private static getLocationAnchor(
    latitude: number,
    longitude: number,
    now: Date
  ): Date {
    if (latitude === 0 && longitude === 0) {
      return new Date(now);
    }

    const locationOffset = TimezoneResolver.effectiveOffsetForLocation(
      latitude, longitude, now
    );
    const deviceOffset = -now.getTimezoneOffset() / 60;
    const deltaMs = (locationOffset - deviceOffset) * 3600 * 1000;
    return new Date(now.getTime() + deltaMs);
  }

  private static formatEventTime(date: Date): string {
    let hours: number = date.getHours();
    const minutes: number = date.getMinutes();
    const ampm: string = hours >= 12 ? 'PM' : 'AM';
    hours = hours % 12;
    if (hours === 0) {
      hours = 12;
    }
    const minutesStr: string = minutes.toString().padStart(2, '0');
    return `${hours}:${minutesStr} ${ampm}`;
  }
}