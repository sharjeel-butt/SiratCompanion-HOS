// entry/src/main/ets/utils/QiblaSensorHelper.ets

import { sensor } from '@kit.SensorServiceKit';

export interface OrientationReading {
  heading: number;   // 0–360, clockwise from North
  isFlat: boolean;
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
          isFlat: Math.abs(data.beta) < 25 && Math.abs(data.gamma) < 25
        });
      }, { interval: 100_000_000 });
      return true;
    } catch (err) {
      return QiblaSensorHelper.registerMagnetometerFallback(onReading);
    }
  }

  static unregister(): void {
    try { sensor.off(sensor.SensorId.ORIENTATION); } catch (err) { /* ignore */ }
    try { sensor.off(sensor.SensorId.MAGNETIC_FIELD); } catch (err) { /* ignore */ }
  }

  private static registerMagnetometerFallback(onReading: (r: OrientationReading) => void): boolean {
    try {
      sensor.on(sensor.SensorId.MAGNETIC_FIELD, (data: sensor.MagneticFieldResponse) => {
        let heading = Math.atan2(data.y, data.x) * 180 / Math.PI;
        heading = (heading + 360) % 360;
        onReading({ heading, isFlat: true });
      }, { interval: 100_000_000 });
      return true;
    } catch (err) {
      return false;
    }
  }
}