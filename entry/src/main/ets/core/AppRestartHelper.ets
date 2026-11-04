// entry/src/main/ets/core/AppRestartHelper.ets

import { common, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
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

    const isLarge = deviceInfo.deviceType === '2in1'
      || deviceInfo.deviceType === 'tablet';

    AppLogger.info('AppRestartHelper',
      `restart start (deviceType=${deviceInfo.deviceType}, large=${isLarge})`);

    // 1. Close window first on tablet / PC (mirrors exitApp pattern)
    if (isLarge) {
      try {
        const win = await window.getLastWindow(context);
        await win.destroyWindow();
        AppLogger.info('AppRestartHelper', 'window destroyed');
      } catch (e) {
        const err = e as Error;
        AppLogger.warn('AppRestartHelper',
          `window destroy failed: ${err.message}`);
      }
    }

    // 2. Fire terminateSelf — DO NOT await. The JS thread must
    //    continue immediately so startAbility fires while the
    //    context is still valid.
    context.terminateSelf().catch((err: BusinessError) => {
      AppLogger.warn('AppRestartHelper',
        `terminateSelf failed: code=${err.code ?? ''} msg=${err.message ?? ''}`);
    });

    // 3. Fire startAbility immediately — the intent is queued in
    //    the system before the current instance finishes teardown.
    try {
      await context.startAbility(want);
      AppLogger.info('AppRestartHelper', 'restart dispatched');
      return true;
    } catch (err) {
      const e = err as BusinessError;
      AppLogger.error('AppRestartHelper',
        `startAbility failed: code=${e.code ?? ''} msg=${e.message ?? ''}`);
      // Ability is already queued for teardown — return true so
      // the caller doesn't offer a misleading "restart failed"
      // dialog. User will land on the restored state on manual
      // relaunch.
      return true;
    }
  }
}