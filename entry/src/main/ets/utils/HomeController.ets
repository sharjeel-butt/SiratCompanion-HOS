// entry/src/main/ets/utils/HomeController.ets

import { ExtraTiming, Prayer } from '../models/PrayerModel';
import { AsrShadowRule, CalculationMethod, DailyPrayerTimes, PrayerTimeCalculator } from './PrayerTimeCalculator';
import { PrayerManager } from './PrayerManager';
import { PrayerOffsets, SettingsHelper } from '../helper/SettingsHelper';
import { LocationMode } from '../models/SettingsModels';
import { CachedLocation, FALLBACK_LOCATION, LocationCache } from './LocationCache';
import { TimezoneResolver } from './TimezoneResolver';

export interface HomePrayerSnapshot {
  prayers: Prayer[];
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

/**
 * Pure computations and orchestration used by Index (Home).
 * Anything here must run without access to a @Component instance.
 */
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
    offsets: PrayerOffsets,
    template: Prayer[]
  ): HomePrayerSnapshot | null {
    if (latitude === 0 && longitude === 0) return null;

    try {
      const times: DailyPrayerTimes = PrayerTimeCalculator.calculateWithDeviceTimezone(
        date, latitude, longitude, method, asrRule
      );
      const withOffsets = PrayerManager.applyTimesToPrayers(template, times, offsets, date);
      const offsetHours = TimezoneResolver.effectiveOffsetForLocation(
        latitude, longitude, date
      );
      const withStatus = PrayerManager.updateStatuses(withOffsets, date, offsetHours);
      return { prayers: withStatus, extras: [] as ExtraTiming[] };
    } catch (err) {
      console.error(`[HomeController] build failed: ${(err as Error).message}`);
      return null;
    }
  }

  static buildExtraTimings(
    date: Date,
    latitude: number,
    longitude: number,
    method: CalculationMethod,
    asrRule: AsrShadowRule,
    offsets: PrayerOffsets,
    template: ExtraTiming[]
  ): ExtraTiming[] {
    if (latitude === 0 && longitude === 0) return template;
    try {
      const times = PrayerTimeCalculator.calculateWithDeviceTimezone(
        date, latitude, longitude, method, asrRule
      );
      return PrayerManager.applyTimesToExtraTimings(template, times, offsets);
    } catch (err) {
      return template;
    }
  }

  static buildTodayHeader(
    latitude: number,
    longitude: number,
    method: CalculationMethod,
    asrRule: AsrShadowRule,
    offsets: PrayerOffsets,
    template: Prayer[]
  ): HomeHeaderSnapshot | null {
    if (latitude === 0 && longitude === 0) return null;
    const today = new Date();
    try {
      const times = PrayerTimeCalculator.calculateWithDeviceTimezone(
        today, latitude, longitude, method, asrRule
      );
      const withOffsets = PrayerManager.applyTimesToPrayers(template, times, offsets, today);
      const offsetHours = TimezoneResolver.effectiveOffsetForLocation(
        latitude, longitude, today
      );
      const withStatus = PrayerManager.updateStatuses(withOffsets, today, offsetHours);
      const current = PrayerManager.getCurrentPrayer(withStatus);
      const next = PrayerManager.getNextPrayer(withStatus);
      return {
        currentName: current ? current.name : '—',
        currentTime: current ? current.time : '--:--',
        nextName: next ? next.name : '—',
        nextTime: next ? next.time : '--:--'
      };
    } catch (err) {
      return null;
    }
  }

  // ============================================================
  // LOCATION ORCHESTRATION
  // ============================================================

  static async loadLocationForMode(mode: LocationMode): Promise<HomeLocationSnapshot> {
    if (mode === LocationMode.MANUAL) {
      const coords = await SettingsHelper.getManualCoords();
      if (coords.lat !== 0 || coords.lng !== 0) {
        const city = coords.cityName.length > 0 ? coords.cityName : 'Manual Location';
        return {
          latitude: coords.lat, longitude: coords.lng,
          displayName: `${city} (Manual)`,
          isManual: true
        };
      }
      return { latitude: 0, longitude: 0, displayName: 'Set Manual Location in Settings', isManual: true };
    }

    const cached: CachedLocation | null = await LocationCache.load();
    if (cached) {
      return {
        latitude: cached.latitude, longitude: cached.longitude,
        displayName: cached.cityName,
        isManual: false
      };
    }
    return {
      latitude: FALLBACK_LOCATION.latitude,
      longitude: FALLBACK_LOCATION.longitude,
      displayName: FALLBACK_LOCATION.cityName,
      isManual: false
    };
  }
}