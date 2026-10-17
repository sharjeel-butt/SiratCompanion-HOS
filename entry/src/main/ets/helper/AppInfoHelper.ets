// entry/src/main/ets/helper/AppInfoHelper.ets

import { bundleManager } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { L } from '../i8n/LocalizationHelper';

export interface AppInfoSnapshot {
  /**
   * Localized app name, resolved from the app's own language tables
   * so it tracks STORAGE_KEY_LANGUAGE rather than the system locale.
   */
  name: string;

  /** From AppScope/app.json5 → "versionName". e.g. "3.0.1". */
  versionName: string;

  /** From AppScope/app.json5 → "versionCode". e.g. 3000001. */
  versionCode: number;

  /** Bundle identifier. e.g. "com.siratcompanion.hos.app". */
  bundleName: string;
}

/** Bundle-derived fields — invariant for the process lifetime. */
interface VersionInfo {
  versionName: string;
  versionCode: number;
  bundleName: string;
}

/**
 * Resolves the app's identity for display.
 *
 * The name is resolved from LocalizationHelper on every call, so it
 * follows the in-app language setting. The version fields come from
 * a process-lifetime cache because bundle metadata cannot change
 * while the app is running.
 *
 * Callers that render `name` must re-invoke `get()` when the
 * language changes — SettingsPage does so from its existing
 * onLanguageChanged watcher.
 */
export class AppInfoHelper {
  private static versionInfo: VersionInfo | null = null;

  /**
   * Build an app-info snapshot for display.
   *
   * `L.get('app_name')` reads the current language from AppStorage,
   * falling through to English and then to the key itself, so the
   * result is always a non-empty string.
   */
  static get(): AppInfoSnapshot {
    const version = AppInfoHelper.loadVersionInfo();
    const snapshot: AppInfoSnapshot = {
      name: L.get('app_name'),
      versionName: version.versionName,
      versionCode: version.versionCode,
      bundleName: version.bundleName
    };
    return snapshot;
  }

  /** "3.0.1 (3000001)" — compact version+build string for the UI. */
  static formattedVersion(): string {
    const info = AppInfoHelper.get();
    return `${info.versionName} (${info.versionCode})`;
  }

  // ============================================================
  // INTERNAL
  // ============================================================

  private static loadVersionInfo(): VersionInfo {
    if (AppInfoHelper.versionInfo !== null) {
      return AppInfoHelper.versionInfo;
    }

    let versionName = '—';
    let versionCode = 0;
    let bundleName = '—';

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

    const result: VersionInfo = { versionName, versionCode, bundleName };
    AppInfoHelper.versionInfo = result;
    return result;
  }
}