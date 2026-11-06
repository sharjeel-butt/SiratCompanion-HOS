// entry/src/main/ets/location/OfflineCityLookup.ets

import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { AppLogger } from '../core/AppLogger';

export enum DstRule {
  NONE = 'NONE',
  US = 'US',
  EU = 'EU',
  AU = 'AU',
  NZ = 'NZ',
  EGYPT = 'EGYPT',
  MOROCCO = 'MOROCCO',
  PALESTINE = 'PALESTINE',
  CHILE = 'CHILE',
  LORD_HOWE = 'LORD_HOWE'
}

export interface City {
  name: string;
  countryCode: string;
  timezoneId: string;
  lat: number;
  lng: number;
  standardOffsetMinutes: number;
  dstRule: DstRule;
}

const MAX_MATCH_KM_TIMEZONE = 200; // Tighter match for timezones
const MAX_MATCH_KM_NAME = 300; // Looser match for reverse-geocode display

export class OfflineCityLookup {
  private static cities: City[] = [];
  private static translations: Record<string, Record<string, string>> = {};
  private static isInitialized: boolean = false;

  static async init(context: common.Context): Promise<void> {
    if (OfflineCityLookup.isInitialized) {
      return;
    }
    try {
      const mgr = context.resourceManager;

      // 1. Load the new 6,000+ city dataset
      const cityData = await mgr.getRawFileContent('locations/offline-cities.json');
      const cityJsonStr = util.TextDecoder.create('utf-8').decodeToString(cityData);
      OfflineCityLookup.cities = JSON.parse(cityJsonStr) as City[];

      // 2. Load city translations
      const transData = await mgr.getRawFileContent('locations/city_translations.json');
      const transJsonStr = util.TextDecoder.create('utf-8').decodeToString(transData);
      OfflineCityLookup.translations = JSON.parse(transJsonStr) as Record<string, Record<string, string>>;

      OfflineCityLookup.isInitialized = true;
      AppLogger.info('OfflineCityLookup', `Loaded ${OfflineCityLookup.cities.length} cities and translations`);
    } catch (e) {
      AppLogger.error('OfflineCityLookup', `Failed to load city dataset: ${JSON.stringify(e)}`);
    }
  }

  static translateCityName(name: string, lang: string): string {
    if (!name || name.length === 0) {
      return name;
    }
    const upperName = name.toUpperCase();
    const translations = OfflineCityLookup.translations[upperName];

    if (translations && translations[lang]) {
      return translations[lang];
    }
    return name;
  }

  /**
   * Returns the English uppercase name of the nearest city for reverse-geocoding.
   */
  static nearest(latitude: number, longitude: number): string | null {
    const city = OfflineCityLookup.findNearest(latitude, longitude, MAX_MATCH_KM_NAME);
    return city !== null ? city.name.toUpperCase() : null;
  }

  /**
   * Returns the exact city object for timezone resolution.
   */
  static nearestCityForTimezone(latitude: number, longitude: number): City | null {
    return OfflineCityLookup.findNearest(latitude, longitude, MAX_MATCH_KM_TIMEZONE);
  }

  /**
   * High-performance nearest-neighbor search.
   * For 6,000-8,000 cities, a single loop with haversine is extremely fast (<2ms)
   * and avoids the complexity of maintaining an R-Tree or spatial grid in ArkTS.
   */
  private static findNearest(latitude: number, longitude: number, maxKm: number): City | null {
    if (OfflineCityLookup.cities.length === 0) {
      return null;
    }

    let best: City | null = null;
    let bestDist = Number.MAX_VALUE;

    for (const city of OfflineCityLookup.cities) {
      const d = OfflineCityLookup.haversineKm(latitude, longitude, city.lat, city.lng);
      if (d < bestDist) {
        bestDist = d;
        best = city;
      }
    }

    if (best !== null && bestDist <= maxKm) {
      return best;
    }
    return null;
  }

  private static haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
    const R = 6371;
    const toRad = Math.PI / 180;
    const dLat = (lat2 - lat1) * toRad;
    const dLng = (lng2 - lng1) * toRad;
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(lat1 * toRad) * Math.cos(lat2 * toRad) *
          Math.sin(dLng / 2) * Math.sin(dLng / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }
}