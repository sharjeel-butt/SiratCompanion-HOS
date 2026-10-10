// entry/src/main/ets/utils/QiblaSensorHelper.ets

import { sensor } from '@kit.SensorServiceKit';

/**
 * Accuracy levels reported by the orientation sensor.
 * Mirrors the C enum Sensor_Accuracy from oh_sensor_type.h:
 *   SENSOR_ACCURACY_UNRELIABLE = 0
 *   SENSOR_ACCURACY_LOW        = 1
 *   SENSOR_ACCURACY_MEDIUM     = 2
 *   SENSOR_ACCURACY_HIGH       = 3
 */
export enum SensorAccuracy {
  UNRELIABLE = 0,
  LOW = 1,
  MEDIUM = 2,
  HIGH = 3
}

export interface OrientationReading {
  heading: number; // 0–360, clockwise from North
  isFlat: boolean;
  accuracy: SensorAccuracy; // NEW — drives the calibration overlay
}

export class QiblaSensorHelper {
  /**
   * Registers the orientation sensor. Falls back to the raw
   * magnetometer if orientation isn't available.
   *
   * @returns true if a sensor was successfully registered
   */
  static register(onReading: (r: OrientationReading) => void): boolean {
    try {
      sensor.on(sensor.SensorId.ORIENTATION, (data: sensor.OrientationResponse) => {
        onReading({
          heading: data.alpha,
          isFlat: Math.abs(data.beta) < 25 && Math.abs(data.gamma) < 25,
          accuracy: QiblaSensorHelper.readAccuracy(data)
        });
      }, { interval: 100_000_000 });
      return true;
    } catch (err) {
      return QiblaSensorHelper.registerMagnetometerFallback(onReading);
    }
  }

  static unregister(): void {
    try {
      sensor.off(sensor.SensorId.ORIENTATION);
    } catch (err) { /* ignore */
    }
    try {
      sensor.off(sensor.SensorId.MAGNETIC_FIELD);
    } catch (err) { /* ignore */
    }
  }

  /**
   * Read the sensor's accuracy field. HarmonyOS exposes `accuracy`
   * on OrientationResponse since API 11, so on our API 22+ target
   * it's a first-class field.
   */
  private static readAccuracy(data: sensor.OrientationResponse): SensorAccuracy {
    const raw: number = data.accuracy;

    if (raw <= 0) {
      return SensorAccuracy.UNRELIABLE;
    }
    if (raw >= 3) {
      return SensorAccuracy.HIGH;
    }
    return raw as SensorAccuracy;
  }

  private static registerMagnetometerFallback(onReading: (r: OrientationReading) => void): boolean {
    try {
      sensor.on(sensor.SensorId.MAGNETIC_FIELD, (data: sensor.MagneticFieldResponse) => {
        let heading = Math.atan2(data.y, data.x) * 180 / Math.PI;
        heading = (heading + 360) % 360;
        // The raw magnetometer reports no accuracy — assume HIGH so
        // the calibration overlay doesn't appear on devices without
        // an orientation sensor.
        onReading({ heading, isFlat: true, accuracy: SensorAccuracy.HIGH });
      }, { interval: 100_000_000 });
      return true;
    } catch (err) {
      return false;
    }
  }
}