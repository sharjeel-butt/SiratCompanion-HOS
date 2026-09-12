// entry/src/main/ets/utils/LocationCache.ets

import { PreferencesHelper } from './PreferencesHelper';

// ---- Interfaces ----

/**
 * Fallback location coordinates (used when no GPS fix and no cache exist).
 */
export interface FallbackLocation {
  latitude: number;
  longitude: number;
  cityName: string;
}

/**
 * Full cached location including the time of last refresh.
 */
export interface CachedLocation {
  latitude: number;
  longitude: number;
  cityName: string;
  lastRefreshTime: number;
}

// ---- Constants ----

export const FALLBACK_LOCATION: FallbackLocation = {
  latitude: 33.6844,
  longitude: 73.0479,
  cityName: 'DEFAULT LOCATION'
};

// ---- Storage keys ----
const KEY_LAT     = 'gps_lat';
const KEY_LNG     = 'gps_lng';
const KEY_CITY    = 'gps_city';
const KEY_REFRESH = 'gps_refresh';

// ---- Class ----

export class LocationCache {

  static async load(): Promise<CachedLocation | null> {
    const lat     = await PreferencesHelper.getNumber(KEY_LAT, NaN);
    const lng     = await PreferencesHelper.getNumber(KEY_LNG, NaN);
    const city    = await PreferencesHelper.getString(KEY_CITY, '');
    const refresh = await PreferencesHelper.getNumber(KEY_REFRESH, 0);

    if (!isNaN(lat) && !isNaN(lng) && city.length > 0) {
      const result: CachedLocation = {
        latitude: lat,
        longitude: lng,
        cityName: city,
        lastRefreshTime: refresh
      };
      return result;
    }
    return null;
  }

  static save(lat: number, lng: number, city: string): void {
    PreferencesHelper.setNumber(KEY_LAT, lat);
    PreferencesHelper.setNumber(KEY_LNG, lng);
    PreferencesHelper.setString(KEY_CITY, city);
    PreferencesHelper.setNumber(KEY_REFRESH, Date.now());
  }
}