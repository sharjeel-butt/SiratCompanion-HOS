// entry/src/main/ets/utils/LocationUtils.ets

import { geoLocationManager } from '@kit.LocationKit';
import { abilityAccessCtrl, Permissions, PermissionRequestResult, Context } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';

// ----- Interface for location result -----
export interface LocationData {
  latitude: number;
  longitude: number;
  cityName: string;
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
    // 1. Check if location master switch is ON
    const enabled = await LocationHelper.isLocationEnabled();
    if (!enabled) {
      throw new Error('GPS_OFF');
    }

    // 2. Check permission
    const hasPermission = await LocationHelper.requestLocationPermission(context);
    if (!hasPermission) {
      throw new Error('PERMISSION_DENIED');
    }

    // 3. Get the coordinates
    const request: geoLocationManager.CurrentLocationRequest = {
      priority: geoLocationManager.LocationRequestPriority.LOW_POWER,
      timeoutMs: 10000,
      maxAccuracy: 1000
    };
    const location = await geoLocationManager.getCurrentLocation(request);

    // 4. Reverse geocode to get the city name
    const reverseRequest: geoLocationManager.ReverseGeoCodeRequest = {
      latitude: location.latitude,
      longitude: location.longitude,
      maxItems: 1,
      locale: 'en'
    };
    const geocodeResults = await geoLocationManager.getAddressesFromLocation(reverseRequest);

    let cityName = 'Unknown location';
    if (geocodeResults && geocodeResults.length > 0) {
      const address = geocodeResults[0];
      cityName = address.locality || address.administrativeArea || 'Unknown location';
    }

    return {
      latitude: location.latitude,
      longitude: location.longitude,
      cityName: cityName.toUpperCase()
    };
  }

  /**
   * Legacy method: keep for backward compatibility (only returns city).
   */
  static async fetchCityName(context: Context): Promise<string> {
    const data = await LocationHelper.fetchLocationData(context);
    return data.cityName;
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