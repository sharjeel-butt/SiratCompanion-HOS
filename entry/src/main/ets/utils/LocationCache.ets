// entry/src/main/ets/utils/LocationCache.ets

import { STORAGE_KEY_CACHED_LAT, STORAGE_KEY_CACHED_LNG, STORAGE_KEY_CACHED_CITY } from '../common/StorageKeys';

export interface CachedLocation {
  latitude: number;
  longitude: number;
  cityName: string;
}

export const FALLBACK_LOCATION: CachedLocation = {
  latitude: 33.6844,
  longitude: 73.0479,
  cityName: 'DEFAULT LOCATION'
};

export class LocationCache {

  static load(): CachedLocation | null {
    const lat = AppStorage.get<number>(STORAGE_KEY_CACHED_LAT);
    const lng = AppStorage.get<number>(STORAGE_KEY_CACHED_LNG);
    const city = AppStorage.get<string>(STORAGE_KEY_CACHED_CITY);

    if (lat !== undefined && lng !== undefined && city) {
      return { latitude: lat, longitude: lng, cityName: city };
    }
    return null;
  }

  static save(lat: number, lng: number, city: string): void {
    AppStorage.setOrCreate(STORAGE_KEY_CACHED_LAT, lat);
    AppStorage.setOrCreate(STORAGE_KEY_CACHED_LNG, lng);
    AppStorage.setOrCreate(STORAGE_KEY_CACHED_CITY, city);
  }
}