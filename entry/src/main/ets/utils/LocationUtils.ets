// entry/src/main/ets/utils/LocationUtils.ets

import { geoLocationManager } from '@kit.LocationKit';
import { abilityAccessCtrl, Context, PermissionRequestResult, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { i18n } from '@kit.LocalizationKit';
import { OfflineCityLookup } from './OfflineCityLookup';

// ----- Interface for location result -----
export interface LocationData {
  latitude: number;
  longitude: number;
  cityName: string;
}

interface ReverseResult {
  kind: 'city' | 'country';
  value: string;
}

export class LocationHelper {

  /**
   * Request location permissions from the user.
   */
  static async requestLocationPermission(context: Context): Promise<boolean> {
    const atManager = abilityAccessCtrl.createAtManager();
    const permissions: Array<Permissions> = [
      'ohos.permission.APPROXIMATELY_LOCATION',
      'ohos.permission.LOCATION'
    ];
    try {
      const result: PermissionRequestResult = await atManager.requestPermissionsFromUser(context, permissions);
      return result.authResults.every((grant) => grant === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED);
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Permission request failed: ${error.code}, ${error.message}`);
      return false;
    }
  }

  /**
   * Reverse-geocode coordinates into a city name.
   *
   * Order of resolution:
   *   1. Offline city table (instant, no network, top ~60 cities)
   *   2. System geocoder — tries the device locale then fallbacks
   *   3. countryName as a last resort
   *   4. 'Unknown location'
   */
  static async reverseGeocode(latitude: number, longitude: number): Promise<string> {
    // 1. Offline nearest-city match
    const offline = OfflineCityLookup.nearest(latitude, longitude);
    if (offline !== null) {
      console.info(`[LocationHelper] reverseGeocode offline match: ${offline}`);
      return offline;
    }

    // 2. System geocoder, several locales
    const locales = LocationHelper.buildLocaleCandidates();
    let lastCountry: string | null = null;

    for (const locale of locales) {
      const result = await LocationHelper.tryReverseGeocode(latitude, longitude, locale);
      if (result !== null) {
        if (result.kind === 'city') return result.value;
        if (result.kind === 'country') lastCountry = result.value;
      }
    }

    // 3. Country as a fallback when no city was found
    if (lastCountry !== null) {
      console.info(`[LocationHelper] reverseGeocode country-only fallback: ${lastCountry}`);
      return lastCountry;
    }

    console.warn('[LocationHelper] reverseGeocode: no data at all');
    return 'Unknown location';
  }

  /**
   * Build a de-duplicated list of locale strings to try, in order.
   * The device's system language goes first.
   */
  private static buildLocaleCandidates(): string[] {
    const out: string[] = [];

    // Device language (e.g. "zh", "ur", "ar")
    try {
      const sysLocale = i18n.System.getSystemLocale();      // "zh-Hans-CN"
      const lang = sysLocale.split('-')[0];
      if (lang.length > 0) out.push(lang);
    } catch (err) {
      // ignore — fall through to defaults
    }

    // Common fallbacks. Order matters: 'en' first because most
    // geocoding services return Latin script by default, then the
    // languages most likely to unlock region-restricted data.
    const fallbacks = ['en', 'zh', 'ur', 'ar'];
    for (const f of fallbacks) {
      if (out.indexOf(f) === -1) out.push(f);
    }

    return out;
  }

  /**
   * Single-locale reverse geocode attempt.
   * Returns null if nothing usable was found, otherwise an object
   * describing whether we got a city-level or country-level result.
   */
  private static async tryReverseGeocode(
    latitude: number,
    longitude: number,
    locale: string
  ): Promise<ReverseResult | null> {
    try {
      const request: geoLocationManager.ReverseGeoCodeRequest = {
        latitude: latitude,
        longitude: longitude,
        maxItems: 1,
        locale: locale
      };

      const results = await geoLocationManager.getAddressesFromLocation(request);
      if (!results || results.length === 0) {
        console.info(`[LocationHelper] reverseGeocode locale='${locale}': no results`);
        return null;
      }

      const addr = results[0];

      console.info(
        `[LocationHelper] reverseGeocode locale='${locale}' raw: ` +
          `placeName="${addr.placeName}", ` +
          `locality="${addr.locality}", ` +
          `subLocality="${addr.subLocality}", ` +
          `adminArea="${addr.administrativeArea}", ` +
          `subAdminArea="${addr.subAdministrativeArea}", ` +
          `countryName="${addr.countryName}"`
      );

      // City-level fields, most specific first
      const cityCandidates: Array<string | undefined> = [
        addr.locality,
        addr.subAdministrativeArea,
        addr.administrativeArea,
        addr.subLocality,
        addr.placeName
      ];

      for (const s of cityCandidates) {
        if (typeof s === 'string' && s.length > 0) {
          const r: ReverseResult = { kind: 'city', value: s.toUpperCase() };
          return r;
        }
      }

      // Nothing city-level — remember the country for a possible
      // later fallback.
      if (typeof addr.countryName === 'string' && addr.countryName.length > 0) {
        const r: ReverseResult = { kind: 'country', value: addr.countryName.toUpperCase() };
        return r;
      }

      return null;
    } catch (err) {
      const error = err as BusinessError;
      console.warn(
        `[LocationHelper] reverseGeocode locale='${locale}' failed: ` +
          `${error.code}, ${error.message}`
      );
      return null;
    }
  }

  /**
   * Check if the system location master switch is ON.
   */
  static async isLocationEnabled(): Promise<boolean> {
    try {
      return await geoLocationManager.isLocationEnabled();
    } catch (err) {
      console.error('Failed to check location status:', JSON.stringify(err));
      return false;
    }
  }

  /**
   * Fetch the user's current location: coordinates AND city name.
   * Throws errors: 'GPS_OFF', 'PERMISSION_DENIED', or generic.
   */
  static async fetchLocationData(context: Context): Promise<LocationData> {
    const enabled = await LocationHelper.isLocationEnabled();
    if (!enabled) throw new Error('GPS_OFF');

    const hasPermission = await LocationHelper.requestLocationPermission(context);
    if (!hasPermission) throw new Error('PERMISSION_DENIED');

    const request: geoLocationManager.CurrentLocationRequest = {
      priority: geoLocationManager.LocationRequestPriority.LOW_POWER,
      timeoutMs: 10000,
      maxAccuracy: 1000
    };
    const location = await geoLocationManager.getCurrentLocation(request);

    // Reuse the new method
    const cityName = await LocationHelper.reverseGeocode(location.latitude, location.longitude);

    return {
      latitude: location.latitude,
      longitude: location.longitude,
      cityName: cityName
    };
  }

  /**
   * Show a dialog informing the user that GPS is off.
   */
  static async showLocationDisabledDialog(): Promise<void> {
    try {
      await promptAction.showDialog({
        title: 'Location is disabled',
        message: 'Please enable location services to get accurate prayer times for your city.',
        buttons: [{ text: 'OK', color: '#C9A96E' }]
      });
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Dialog error: ${error.code}, ${error.message}`);
    }
  }

  /**
   * Show a dialog informing the user that permission was denied.
   */
  static async showPermissionDeniedDialog(): Promise<void> {
    try {
      await promptAction.showDialog({
        title: 'Permission required',
        message: 'Location permission is required to show prayer times for your city.\nPlease grant it in system settings.',
        buttons: [{ text: 'OK', color: '#C9A96E' }]
      });
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Dialog error: ${error.code}, ${error.message}`);
    }
  }
}