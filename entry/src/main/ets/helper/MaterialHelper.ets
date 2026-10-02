// entry/src/main/ets/helper/MaterialHelper.ets

import { uiMaterial } from '@kit.ArkUI';
import { deviceInfo } from '@kit.BasicServicesKit';
import { AppLogger } from './AppLogger';

/**
 * HarmonyOS immersive-material capability probe and material factory.
 *
 * ## API compatibility
 *
 *   API 26.0.0+  — uiMaterial and native Tabs.barFloatingStyle exist.
 *   API 20–25    — neither exists. Callers must use the fallback path
 *                  in MainTabs (barOverlap + barBackgroundBlurStyle).
 *
 * IMPORTANT: deviceInfo.apiAvailable() is itself @since 26.0.0 and is
 * NOT available on API 20. Use deviceInfo.sdkApiVersion, which exists
 * on every API level, for the runtime guard.
 *
 * ## ArkTS namespace rule (arkts-no-ns-as-obj)
 *
 * A namespace imported with `import { uiMaterial } from '@kit.ArkUI'`
 * can be used as:
 *   • a type qualifier        — uiMaterial.MaterialLevel
 *   • a constructor qualifier — new uiMaterial.ImmersiveMaterial(...)
 *   • a function call target  — uiMaterial.isImmersiveMaterialSupported()
 *   • an enum member access   — uiMaterial.ImmersiveStyle.THIN
 *
 * It must NOT be used as a value:
 *   ✗ uiMaterial !== undefined
 *   ✗ const x = uiMaterial;
 *   ✗ typeof uiMaterial === 'object'
 *
 * The version check below replaces the illegal `!== undefined` guard:
 * on API < 26 we never reach the namespace call at all.
 *
 * ## Host eligibility for immersive material
 *
 * The material only renders inside a supported host:
 *   • Navigation / NavDestination title bar
 *   • Bottom TabBar of a horizontal Tabs with barPosition.End
 *   • Dialog, popup, menu, sheet, Select
 *
 * If the host does not qualify, systemMaterial is silently ignored.
 */
export class MaterialHelper {
  /** Lowest SDK API level that provides uiMaterial and barFloatingStyle. */
  static readonly MIN_API_FOR_MATERIAL = 26;
  private static probed: boolean = false;
  private static supported: boolean = false;
  private static globalLevel: uiMaterial.MaterialLevel | null = null;
  private static levelProbed: boolean = false;

  // ============================================================
  // CAPABILITY PROBE
  // ============================================================

  /**
   * True when the OS can render immersive system material.
   *
   * Uses deviceInfo.sdkApiVersion (available on all API levels) rather
   * than apiAvailable() (API 26+ only), so this method is safe to call
   * on API 20 devices.
   */
  static isImmersiveSupported(): boolean {
    if (MaterialHelper.probed) {
      return MaterialHelper.supported;
    }
    MaterialHelper.probed = true;

    // Version guard — the namespace function is only reached on API 26+.
    // This replaces the illegal `uiMaterial !== undefined` check.
    if (deviceInfo.sdkApiVersion < MaterialHelper.MIN_API_FOR_MATERIAL) {
      MaterialHelper.supported = false;
      return MaterialHelper.supported;
    }

    try {
      MaterialHelper.supported = uiMaterial.isImmersiveMaterialSupported();
    } catch (err) {
      // Defensive: on a stripped system image the namespace may resolve
      // to undefined even when sdkApiVersion reports 26.
      MaterialHelper.supported = false;
    }
    return MaterialHelper.supported;
  }

  /**
   * The device's global material level — EXQUISITE / GENTLE / SMOOTH.
   * Returns null when the device does not support immersive material.
   */
  static getGlobalLevel(): uiMaterial.MaterialLevel | null {
    if (MaterialHelper.levelProbed) {
      return MaterialHelper.globalLevel;
    }
    MaterialHelper.levelProbed = true;

    if (!MaterialHelper.isImmersiveSupported()) {
      return null;
    }

    try {
      MaterialHelper.globalLevel = uiMaterial.getGlobalMaterialLevel();
    } catch (err) {
      MaterialHelper.globalLevel = null;
    }
    return MaterialHelper.globalLevel;
  }

  // ============================================================
  // MATERIAL FACTORY
  // ============================================================

  /**
   * The material for Tabs.barFloatingStyle().systemMaterial.
   *
   * MUST NOT be called on API < 26 — the constructor dereferences the
   * uiMaterial namespace, which is undefined on API 20. MainTabs guards
   * every call site with sdkApiVersion >= MIN_API_FOR_MATERIAL.
   */
  static tabBarMaterial(): uiMaterial.ImmersiveMaterial {
    return new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.THIN
    });
  }

  // ============================================================
  // DIAGNOSTICS
  // ============================================================

  /**
   * Logs the capability once per session. Called from EntryAbility so
   * the diagnostic log records which bar path is active on this device.
   *
   * Wrapped in try/catch so a missing diagnostic property can never
   * break startup.
   */
  static logCapability(): void {
    try {
      const sdk: number = deviceInfo.sdkApiVersion;
      const dist: number = deviceInfo.distributionOSApiVersion;
      const immersive: boolean = MaterialHelper.isImmersiveSupported();
      const level: string = MaterialHelper.levelToString(
        MaterialHelper.getGlobalLevel()
      );

      AppLogger.info(
        'MaterialHelper',
        `SDK=${sdk}, distOS=${dist}, ` +
          `immersiveMaterialSupported=${immersive}, ` +
          `globalMaterialLevel=${level}, ` +
          `materialPath=${sdk >= MaterialHelper.MIN_API_FOR_MATERIAL
            ? 'barFloatingStyle' : 'fallback-blur'}`
      );
    } catch (err) {
      // Never let diagnostics break startup.
    }
  }

  private static levelToString(
    level: uiMaterial.MaterialLevel | null
  ): string {
    if (level === null) {
      return 'unsupported';
    }
    switch (level) {
      case uiMaterial.MaterialLevel.EXQUISITE:
        return 'EXQUISITE';
      case uiMaterial.MaterialLevel.GENTLE:
        return 'GENTLE';
      case uiMaterial.MaterialLevel.SMOOTH:
        return 'SMOOTH';
      default:
        return `unknown(${level})`;
    }
  }
}