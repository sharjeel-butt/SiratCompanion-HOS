// entry/src/main/ets/helper/MaterialHelper.ets

import { deviceInfo } from '@kit.BasicServicesKit';
import { AppLogger } from './AppLogger';

/**
 * Material capability probe and factory.
 *
 * ## Status in this build
 *
 * The ArkUI `uiMaterial` namespace is a native module that ships only
 * on devices whose system image includes the immersive-material
 * runtime (API 26+, and even then only on some SKUs). Importing it at
 * module scope causes the loader to fail on older devices and leaves
 * the export in an undefined state — any later reference then throws
 * "undefined is not callable" during a render pass.
 *
 * To avoid that class of failure, this file does not import
 * `uiMaterial` at all. Where material would have been constructed,
 * the app instead relies on:
 *
 *   • module.json5's "ohos.arkui.UIMaterial.state": "enable"
 *     — framework-applied material on Dialog, Toast, bindSheet,
 *       and other popup-class components on API 26+.
 *
 *   • hdsMaterial from @kit.UIDesignKit on HdsTabs and HdsNavigation
 *     — the HDS immersive light tier, available from API 23+.
 *
 *   • BlurStyle.COMPONENT_THICK on any bindSheet that needs a
 *     translucent fallback on pre-API-26 devices.
 *
 * When the app raises its minimum supported API to 26, `uiMaterial`
 * construction can be reintroduced here safely.
 */
export class MaterialHelper {
  /** Lowest SDK API level that provides uiMaterial. */
  static readonly MIN_API_FOR_MATERIAL = 26;

  /**
   * Always false in this build. The app-level UIMaterial.state flag
   * handles popup material instead, and hdsMaterial handles HDS
   * surfaces. No code path in the app constructs a uiMaterial.
   */
  static isImmersiveSupported(): boolean {
    return false;
  }

  /** Always null in this build. */
  static getGlobalLevel(): null {
    return null;
  }

  /** True when the current device could use explicit uiMaterial. */
  static shouldUseSystemMaterial(): boolean {
    return false;
  }

  /** Fallback blur for bindSheet on pre-API-26 devices. */
  static fallbackBlurStyle(): BlurStyle {
    return BlurStyle.COMPONENT_THICK;
  }

  /**
   * Build SheetOptions for a bindSheet call.
   *
   * Always returns the translucent-blur form. On API 26+ the
   * framework still applies material to the sheet surface because
   * the app declares UIMaterial.state = enable in module.json5.
   */
  static buildSheetOptions(
    height: number,
    dragBar: boolean,
    fallbackBackground: string,
    maskColor: string,
    onDisappear?: () => void
  ): SheetOptions {
    const opts: SheetOptions = {
      height: height,
      dragBar: dragBar,
      showClose: false,
      backgroundColor: fallbackBackground,
      blurStyle: MaterialHelper.fallbackBlurStyle(),
      maskColor: maskColor,
      onDisappear: onDisappear
    };
    return opts;
  }

  /**
   * One-line diagnostic for the app log, called once per session
   * from EntryAbility. Wrapped in try/catch so a missing property
   * can never affect startup.
   */
  static logCapability(): void {
    try {
      AppLogger.info(
        'MaterialHelper',
        `SDK=${deviceInfo.sdkApiVersion}, ` +
          `distOS=${deviceInfo.distributionOSApiVersion}, ` +
          `uiMaterial=disabled-in-this-build, ` +
          `hdsMaterial=${deviceInfo.sdkApiVersion >= 23 ? 'available' : 'unavailable'}`
      );
    } catch (err) {
      // Never let diagnostics break startup.
    }
  }
}