// entry/src/main/ets/helper/AppRestartHelper.ets

import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AppLogger } from './AppLogger';

/**
 * Restart the app.
 *
 * HarmonyOS does not expose a single-shot "restart this ability"
 * API that works on every shipped SDK level. The portable pattern
 * used by the platform's own sample apps is:
 *
 *   1. Construct a Want targeting the app's entry ability.
 *   2. Call terminateSelf() to tear down the current instance.
 *   3. Call startAbility() with that Want. The system queues the
 *      launch before the ability finishes tearing down, so the
 *      process restarts cleanly on the same device surface.
 *
 * Return contract:
 *
 *   true  — terminateSelf() succeeded; the ability is committed
 *           to teardown. Any subsequent startAbility() failure is
 *           logged but does not change the answer, because the
 *           caller can no longer interact with the process.
 *
 *   false — terminateSelf() failed; the ability is still alive.
 *           The caller can safely fall back to router navigation
 *           to present the restored state without a hard restart.
 *
 * No exceptions are thrown. ArkTS's arkts-limited-throw rule
 * forbids throwing values that are not provably Error subclasses,
 * and the boolean result already carries every signal the caller
 * needs.
 */
export class AppRestartHelper {
  static async restart(context: common.UIAbilityContext): Promise<boolean> {
    const want: Want = {
      bundleName: 'com.siratcompanion.hos.app',
      abilityName: 'EntryAbility'
    };

    try {
      await context.terminateSelf();
    } catch (err) {
      const e = err as BusinessError;
      AppLogger.warn('AppRestartHelper',
        `terminateSelf failed: code=${e.code ?? ''} msg=${e.message ?? ''}`);
      // Ability is still alive — caller may fall back safely.
      return false;
    }

    try {
      await context.startAbility(want);
      AppLogger.info('AppRestartHelper', 'restart dispatched');
    } catch (err) {
      const e = err as BusinessError;
      AppLogger.error('AppRestartHelper',
        `startAbility failed: code=${e.code ?? ''} msg=${e.message ?? ''}`);
      // Ability is already terminating — no fallback possible.
      // The user relaunches manually and lands on the same state.
    }

    // terminateSelf succeeded → committed to teardown regardless
    // of what startAbility did.
    return true;
  }
}