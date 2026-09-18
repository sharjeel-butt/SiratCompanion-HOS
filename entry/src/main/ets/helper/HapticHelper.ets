// entry/src/main/ets/helper/HapticHelper.ets

import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { STORAGE_KEY_VIBRATION_ENABLED } from '../common/StorageKeys';

/**
 * Thin wrapper around the vibrator API.
 *
 * All methods are fire-and-forget and never throw. If the device has
 * no vibrator, or the user disabled vibration in Settings, the call
 * is silently skipped.
 *
 * Requires `ohos.permission.VIBRATE` in module.json5.
 *
 * The enabled/disabled flag is stored in AppStorage under
 * STORAGE_KEY_VIBRATION_ENABLED so this helper can read it
 * synchronously. SettingsHelper writes it; EntryAbility primes it at
 * cold start.
 */
export class HapticHelper {

  // ---- Durations (ms) ----
  private static readonly TICK_MS = 15;      // light — for each count
  private static readonly CONFIRM_MS = 80;   // strong — for dhikr completion

  /** Short, crisp tick — for a single count. ~15 ms. */
  static tick(): void {
    if (!HapticHelper.isEnabled()) return;
    HapticHelper.vibrate(HapticHelper.TICK_MS);
  }

  /**
   * Strong, unmistakable pulse — for completion of a dhikr target.
   * ~80 ms so it clearly reads as "you're done" rather than another tick.
   */
  static confirm(): void {
    if (!HapticHelper.isEnabled()) return;
    HapticHelper.vibrate(HapticHelper.CONFIRM_MS);
  }

  /**
   * Double pulse — for the very last dhikr in a Tasbih (all done).
   * Two 60 ms pulses with a 60 ms gap reads as a distinct "finished"
   * pattern separate from the single confirm pulse.
   */
  static complete(): void {
    if (!HapticHelper.isEnabled()) return;
    // Fire two pulses back to back. The second one is scheduled
    // 120 ms after the first — enough separation to feel like two
    // distinct beats rather than one long buzz.
    HapticHelper.vibrate(60);
    setTimeout(() => { HapticHelper.vibrate(60); }, 120);
  }

  private static isEnabled(): boolean {
    const v = AppStorage.get<boolean>(STORAGE_KEY_VIBRATION_ENABLED);
    // Default to true when the flag hasn't been primed yet.
    return v === undefined ? true : v;
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
        console.warn(`[HapticHelper] vibrate(${durationMs}ms) failed: ${err.code}, ${err.message}`);
      });
    } catch (err) {
      console.warn('[HapticHelper] vibrate threw synchronously');
    }
  }
}