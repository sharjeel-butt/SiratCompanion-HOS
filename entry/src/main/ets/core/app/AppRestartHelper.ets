// entry/src/main/ets/core/AppRestartHelper.ets

import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AppLogger } from './AppLogger';

/**
 * Restart the app.
 *
 * HarmonyOS has no single "restart this ability" API. The portable
 * pattern is: queue `startAbility()` targeting our own entry ability,
 * then tear the current instance down. The system relaunches the app
 * from the queued intent.
 *
 * Ordering is critical:
 *
 *   1. On tablet / 2-in-1, destroy the window first — matches the
 *      pattern used by MainTabs.exitApp() and is required for
 *      terminateSelf() to complete cleanly.
 *
 *   2. Fire terminateSelf() WITHOUT awaiting it. If we await, the
 *      context is torn down before startAbility() runs, and the
 *      restart silently fails on tablet / PC (works on phone by
 *      accident of timing).
 *
 *   3. Fire startAbility() immediately after terminateSelf() is
 *      queued. The context is still alive for the duration of this
 *      synchronous block, so the intent makes it into the system
 *      queue before teardown completes.
 */
export class AppRestartHelper {
  static async restart(context: common.UIAbilityContext): Promise<boolean> {
    const want: Want = {
      bundleName: 'com.siratcompanion.hos.app',
      abilityName: 'EntryAbility'
    };

    AppLogger.info('AppRestartHelper', 'restart start');

    // Fire terminateSelf — DO NOT await. The JS thread must
    // continue immediately so startAbility fires while the
    // context is still valid.
    context.terminateSelf().catch((err: BusinessError) => {
      AppLogger.warn('AppRestartHelper',
        `terminateSelf failed: code=${err.code ?? ''} msg=${err.message ?? ''}`);
    });

    // Fire startAbility immediately — the intent is queued in
    // the system before the current instance finishes teardown.
    try {
      await context.startAbility(want);
      AppLogger.info('AppRestartHelper', 'restart dispatched');
      return true;
    } catch (err) {
      const e = err as BusinessError;
      AppLogger.error('AppRestartHelper',
        `startAbility failed: code=${e.code ?? ''} msg=${e.message ?? ''}`);
      return true;
    }
  }
}