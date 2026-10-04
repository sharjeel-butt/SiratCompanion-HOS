// entry/src/main/ets/utils/LocationUtils.ets

import { abilityAccessCtrl, bundleManager, Context, PermissionRequestResult, Permissions } from '@kit.AbilityKit';
import { L } from '../helper/LocalizationHelper';
import { OfflineCityLookup } from './OfflineCityLookup';
import { geoLocationManager } from '@kit.LocationKit';
import { promptAction } from '@kit.ArkUI';
import { STORAGE_KEY_LANGUAGE } from '../common/StorageKeys';
import { i18n } from '@kit.LocalizationKit';

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
   * Check the location permission state without prompting the user.
   * Returns true only when both APPROXIMATELY_LOCATION and LOCATION
   * are currently granted. Used by silent refreshes so background
   * fetches never trigger a permission dialog.
   */
  private static async checkLocationPermission(): Promise<boolean> {
    try {
      const bundleInfo = bundleManager.getBundleInfoForSelfSync(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
      );
      const tokenId = bundleInfo.appInfo.accessTokenId;

      const atManager = abilityAccessCtrl.createAtManager();
      const status1 = await atManager.checkAccessToken(
        tokenId, 'ohos.permission.APPROXIMATELY_LOCATION'
      );
      const status2 = await atManager.checkAccessToken(
        tokenId, 'ohos.permission.LOCATION'
      );

      return status1 === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
        && status2 === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (err) {
      const error = err as BusinessError;
      console.warn(
        `[LocationHelper] checkLocationPermission failed: ` +
          `${error.code} ${error.message}`
      );
      return false;
    }
  }

  static async reverseGeocode(latitude: number, longitude: number): Promise<string> {
    const offline = OfflineCityLookup.nearest(latitude, longitude);
    if (offline !== null) {
      console.info(`[LocationHelper] reverseGeocode offline match: ${offline}`);
      return offline;
    }

    const locales = LocationHelper.buildLocaleCandidates();
    let lastCountry: string | null = null;

    for (const locale of locales) {
      const result = await LocationHelper.tryReverseGeocode(latitude, longitude, locale);
      if (result !== null) {
        if (result.kind === 'city') {
          return result.value;
        }
        if (result.kind === 'country') {
          lastCountry = result.value;
        }
      }
    }

    if (lastCountry !== null) {
      console.info(`[LocationHelper] reverseGeocode country-only fallback: ${lastCountry}`);
      return lastCountry;
    }

    console.warn('[LocationHelper] reverseGeocode: no data at all');
    return L.get('unknown_location', LocationHelper.currentLang());
  }

  static async isLocationEnabled(): Promise<boolean> {
    try {
      return await geoLocationManager.isLocationEnabled();
    } catch (err) {
      console.error('Failed to check location status:', JSON.stringify(err));
      return false;
    }
  }

  /**
   * Fetch the current device location.
   *
   * @param context  UIAbilityContext
   * @param mode     'interactive' — prompts for permissions if not granted
   *                 'silent'      — checks permission state only, never
   *                                 prompts. Used for background refreshes
   *                                 on page load and foreground.
   */
  static async fetchLocationData(
    context: Context,
    mode: 'interactive' | 'silent' = 'interactive'
  ): Promise<LocationData> {
    const enabled = await LocationHelper.isLocationEnabled();
    if (!enabled) {
      throw new Error('GPS_OFF');
    }

    let hasPermission: boolean;
    if (mode === 'interactive') {
      hasPermission = await LocationHelper.requestLocationPermission(context);
    } else {
      hasPermission = await LocationHelper.checkLocationPermission();
    }
    if (!hasPermission) {
      throw new Error('PERMISSION_DENIED');
    }

    const request: geoLocationManager.CurrentLocationRequest = {
      priority: geoLocationManager.LocationRequestPriority.LOW_POWER,
      timeoutMs: 10000,
      maxAccuracy: 1000
    };
    const location = await geoLocationManager.getCurrentLocation(request);

    const cityName = await LocationHelper.reverseGeocode(location.latitude, location.longitude);

    return {
      latitude: location.latitude,
      longitude: location.longitude,
      cityName: cityName
    };
  }

  static async showLocationDisabledDialog(): Promise<void> {
    const lang = LocationHelper.currentLang();
    try {
      await promptAction.showDialog({
        title: L.get('dialog_gps_off_title', lang),
        message: L.get('dialog_gps_off_message', lang),
        buttons: [{ text: L.get('ok', lang), color: '#C9A96E' }]
      });
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Dialog error: ${error.code}, ${error.message}`);
    }
  }

  static async showPermissionDeniedDialog(): Promise<void> {
    const lang = LocationHelper.currentLang();
    try {
      await promptAction.showDialog({
        title: L.get('dialog_permission_title', lang),
        message: L.get('dialog_permission_message', lang),
        buttons: [{ text: L.get('ok', lang), color: '#C9A96E' }]
      });
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Dialog error: ${error.code}, ${error.message}`);
    }
  }

  /** Current app language, read directly from AppStorage. */
  private static currentLang(): string {
    const v = AppStorage.get<string>(STORAGE_KEY_LANGUAGE);
    return v ? v : 'en';
  }

  private static buildLocaleCandidates(): string[] {
    const out: string[] = [];

    try {
      const sysLocale = i18n.System.getSystemLocale();
      const lang = sysLocale.split('-')[0];
      if (lang.length > 0) {
        out.push(lang);
      }
    } catch (err) { /* ignore */
    }

    const fallbacks = ['en', 'zh', 'ur', 'ar'];
    for (const f of fallbacks) {
      if (out.indexOf(f) === -1) {
        out.push(f);
      }
    }
    return out;
  }

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
        return null;
      }

      const addr = results[0];

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
}