// entry/src/main/ets/helper/AppInfoHelper.ets

import { bundleManager, common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { L } from './LocalizationHelper';

export interface AppInfoSnapshot {
  /** Localized app name from AppScope's $string:app_name. */
  name: string;

  /** From AppScope/app.json5 → "versionName". e.g. "1.4.1". */
  versionName: string;

  /** From AppScope/app.json5 → "versionCode". e.g. 1000005. */
  versionCode: number;

  /** Bundle identifier. e.g. "com.siratcompanion.hos.app". */
  bundleName: string;
}

/**
 * Resolves the app's identity from the installed bundle, so no
 * version string is ever hard-coded in the UI.
 *
 * Results are cached for the lifetime of the process — the bundle
 * info cannot change while the app is running.
 */
export class AppInfoHelper {
  private static cached: AppInfoSnapshot | null = null;

  /**
   * @param context  A UIAbilityContext — required to resolve the
   *                 localized app name via the resource manager.
   *                 The version info itself comes from bundleManager
   *                 and does not need the context.
   */
  static get(context: common.UIAbilityContext): AppInfoSnapshot {
    if (AppInfoHelper.cached !== null) {
      return AppInfoHelper.cached;
    }

    let versionName = '—';
    let versionCode = 0;
    let bundleName = '—';

    // ---- Version + bundle name ----
    try {
      const info = bundleManager.getBundleInfoForSelfSync(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT
      );
      versionName = info.versionName;
      versionCode = info.versionCode;
      bundleName = info.name;
    } catch (err) {
      const e = err as BusinessError;
      console.error(
        `[AppInfoHelper] getBundleInfoForSelfSync failed: ` +
          `${e.code} ${e.message}`
      );
    }

    // ---- App name (localized) ----
    // Pulled from AppScope/resources/*/element/string.json → app_name.
    // Falls back to the LocalizationHelper's own app_name if the
    // resource lookup fails.
    let name = '';
    try {
      name = context.resourceManager.getStringSync(
        $r('app.string.app_name').id
      );
    } catch (err) {
      const e = err as BusinessError;
      console.warn(
        `[AppInfoHelper] app_name lookup failed: ${e.code} ${e.message}`
      );
      name = L.get('app_name');
    }

    const snapshot: AppInfoSnapshot = {
      name,
      versionName,
      versionCode,
      bundleName
    };
    AppInfoHelper.cached = snapshot;
    return snapshot;
  }

  /** "1.4.1 (1000005)" — a compact version+build string for the UI. */
  static formattedVersion(context: common.UIAbilityContext): string {
    const info = AppInfoHelper.get(context);
    return `${info.versionName} (${info.versionCode})`;
  }
}