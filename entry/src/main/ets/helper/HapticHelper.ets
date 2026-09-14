// entry/src/main/ets/utils/HapticHelper.ets

import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * Thin wrapper around the vibrator API.
 *
 * All methods are fire-and-forget and never throw — if the device
 * has no vibrator, or the user denied vibration, we silently ignore
 * the failure so the UI flow is never blocked.
 *
 * Requires `ohos.permission.VIBRATE` in module.json5.
 */
export class HapticHelper {

  /** Short, crisp tick — for a step / press. ~15 ms. */
  static tick(): void {
    HapticHelper.vibrate(15);
  }

  /** Slightly longer pulse — for confirmations (completion, reset). ~30 ms. */
  static confirm(): void {
    HapticHelper.vibrate(30);
  }

  private static vibrate(durationMs: number): void {
    try {
      vibrator.startVibration(
        {
          type: 'time',
          duration: durationMs
        },
        {
          id: 0,
          usage: 'unknown'
        }
      ).catch((err: BusinessError) => {
        // 14600101 = device has no vibrator
        // 201      = permission denied
        // Both are non-fatal for the UX; log at warn level only.
        console.warn(`[HapticHelper] vibrate(${durationMs}ms) failed: ${err.code}, ${err.message}`);
      });
    } catch (err) {
      // Some builds throw synchronously if the API is unavailable.
      console.warn('[HapticHelper] vibrate threw synchronously');
    }
  }
}