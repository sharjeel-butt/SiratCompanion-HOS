// entry/src/main/ets/utils/LocationUtils.ets

import { geoLocationManager } from '@kit.LocationKit';
import { abilityAccessCtrl, Permissions, PermissionRequestResult, Context } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';

export class LocationHelper {

  static async requestLocationPermission(context: Context): Promise<boolean> {
    const atManager = abilityAccessCtrl.createAtManager();
    const permissions: Array<Permissions> = [
      'ohos.permission.APPROXIMATELY_LOCATION',
      'ohos.permission.LOCATION'
    ];
    try {
      const result: PermissionRequestResult = await atManager.requestPermissionsFromUser(context, permissions);
      // Arrow function ensures no 'this' binding issue
      return result.authResults.every((grant) => grant === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED);
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Permission request failed: ${error.code}, ${error.message}`);
      return false;
    }
  }

  static async isLocationEnabled(): Promise<boolean> {
    try {
      return await geoLocationManager.isLocationEnabled();
    } catch (err) {
      console.error('Failed to check location status:', JSON.stringify(err));
      return false;
    }
  }

  static async fetchCityName(context: Context): Promise<string> {
    // 🔥 Use the CLASS NAME for static calls
    const enabled = await LocationHelper.isLocationEnabled();
    if (!enabled) {
      throw new Error('GPS_OFF');
    }

    const hasPermission = await LocationHelper.requestLocationPermission(context);
    if (!hasPermission) {
      throw new Error('PERMISSION_DENIED');
    }

    const request: geoLocationManager.CurrentLocationRequest = {
      priority: geoLocationManager.LocationRequestPriority.LOW_POWER,
      timeoutMs: 10000,
      maxAccuracy: 1000
    };
    const location = await geoLocationManager.getCurrentLocation(request);

    const reverseRequest: geoLocationManager.ReverseGeoCodeRequest = {
      latitude: location.latitude,
      longitude: location.longitude,
      maxItems: 1,
      locale: 'en'
    };
    const geocodeResults = await geoLocationManager.getAddressesFromLocation(reverseRequest);

    if (geocodeResults && geocodeResults.length > 0) {
      const address = geocodeResults[0];
      const city = address.locality || address.administrativeArea || 'Unknown location';
      return city.toUpperCase();
    }
    throw new Error('LOCATION_UNKNOWN');
  }

  static async showLocationDisabledDialog(): Promise<void> {
    try {
      await promptAction.showDialog({
        title: 'Location is disabled',
        message: 'Please enable location services to get prayer times for your city.',
        buttons: [{ text: 'OK', color: '#C9A96E' }]
      });
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Dialog error: ${error.code}, ${error.message}`);
    }
  }

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