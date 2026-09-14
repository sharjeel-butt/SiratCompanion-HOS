// entry/src/main/ets/utils/LocationCache.ets

import { PreferencesHelper } from '../helper/PreferencesHelper';
import { STORAGE_KEY_LOCATION_VERSION } from '../common/StorageKeys';

export interface FallbackLocation {
  latitude: number;
  longitude: number;
  cityName: string;
}

export interface CachedLocation {
  latitude: number;
  longitude: number;
  cityName: string;
  lastRefreshTime: number;
}

export const FALLBACK_LOCATION: FallbackLocation = {
  latitude: 33.6844,
  longitude: 73.0479,
  cityName: 'DEFAULT LOCATION'
};

const KEY_LAT     = 'gps_lat';
const KEY_LNG     = 'gps_lng';
const KEY_CITY    = 'gps_city';
const KEY_REFRESH = 'gps_refresh';

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

  /**
   * Persist the cache AND bump a global version counter so any page
   * that observes the version (currently Home) reloads its state.
   *
   * This method is async — callers must await it before doing
   * anything that reads from the cache (e.g. navigating Home).
   */
  static async save(lat: number, lng: number, city: string): Promise<void> {
    await PreferencesHelper.setNumber(KEY_LAT, lat);
    await PreferencesHelper.setNumber(KEY_LNG, lng);
    await PreferencesHelper.setString(KEY_CITY, city);
    await PreferencesHelper.setNumber(KEY_REFRESH, Date.now());

    // Notify any observers that the location has changed.
    const prev = AppStorage.get<number>(STORAGE_KEY_LOCATION_VERSION);
    const next = (prev === undefined ? 0 : prev) + 1;
    AppStorage.setOrCreate(STORAGE_KEY_LOCATION_VERSION, next);
  }
}