// entry/src/main/ets/helper/HapticHelper.ets

import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { STORAGE_KEY_VIBRATION_ENABLED } from '../common/StorageKeys';
import { SystemFeedbackHelper } from './SystemFeedbackHelper';

/**
 * Thin wrapper around the vibrator API.
 *
 * Two gates before any vibration fires:
 *   1. The user's in-app preference (Settings → UI Customization)
 *   2. The system's haptics toggle — mirrors the OS rule that
 *      usage types 'unknown'/'touch'/'media' are governed by the
 *      系统触感反馈 switch
 *
 * Additionally, we suppress vibration when the phone is in a
 * fully silent state, matching the user's intuitive expectation
 * that silent mode means "nothing at all".
 *
 * All methods are fire-and-forget and never throw.
 *
 * Requires `ohos.permission.VIBRATE` in module.json5.
 */
export class HapticHelper {
  private static readonly TICK_MS = 15; // light — per count
  private static readonly CONFIRM_MS = 80; // strong — dhikr completion

  /** Short, crisp tick — for a single count. ~15 ms. */
  static tick(): void {
    if (!HapticHelper.allowed()) {
      return;
    }
    HapticHelper.vibrate(HapticHelper.TICK_MS);
  }

  /** Strong, unmistakable pulse — for completion of a dhikr target. */
  static confirm(): void {
    if (!HapticHelper.allowed()) {
      return;
    }
    HapticHelper.vibrate(HapticHelper.CONFIRM_MS);
  }

  /** Double pulse — for the very last dhikr in a Tasbih. */
  static complete(): void {
    if (!HapticHelper.allowed()) {
      return;
    }
    HapticHelper.vibrate(60);
    setTimeout(() => {
      if (HapticHelper.allowed()) {
        HapticHelper.vibrate(60);
      }
    }, 120);
  }

  // ============================================================
  // GATE
  // ============================================================

  private static allowed(): boolean {
    // Gate 1 — the user's in-app preference.
    const userPref = AppStorage.get<boolean>(STORAGE_KEY_VIBRATION_ENABLED);
    const inAppEnabled = userPref === undefined ? true : userPref;
    if (!inAppEnabled) {
      return false;
    }

    // Gate 2 — the system's haptics toggle.
    if (!SystemFeedbackHelper.isSystemHapticsEnabled()) {
      return false;
    }

    return true;
  }

  // ============================================================
  // LOW-LEVEL
  // ============================================================

  private static vibrate(durationMs: number): void {
    try {
      vibrator.startVibration(
        { type: 'time', duration: durationMs },
        { id: 0, usage: 'unknown' }
      ).catch((err: BusinessError) => {
        console.warn(`[HapticHelper] vibrate(${durationMs}ms) failed: ${err.code}, ${err.message}`);
      });
    } catch (err) {
      console.warn('[HapticHelper] vibrate threw synchronously');
    }
  }
}