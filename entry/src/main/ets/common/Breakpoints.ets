// entry/src/main/ets/common/Breakpoints.ets

/**
 * Breakpoint system — width classes for responsive layouts.
 *
 * Values follow the HarmonyOS / ArkUI GridRow convention so any
 * built-in components that use the same breakpoints stay in sync.
 *
 *   xs  : 0   – 320 vp   (small phones)
 *   sm  : 320 – 600 vp   (phones)
 *   md  : 600 – 840 vp   (small tablets, unfolded foldables)
 *   lg  : 840 – ∞        (large tablets, 2-in-1)
 */
export class Breakpoints {
  static readonly XS = 'xs';
  static readonly SM = 'sm';
  static readonly MD = 'md';
  static readonly LG = 'lg';

  /** True for tablet-class layouts (md or lg). */
  static isTablet(bp: string): boolean {
    return bp === Breakpoints.MD || bp === Breakpoints.LG;
  }

  /** True for the widest layouts (lg only). */
  static isLarge(bp: string): boolean {
    return bp === Breakpoints.LG;
  }

  /** True for phone-class layouts (xs or sm). */
  static isPhone(bp: string): boolean {
    return bp === Breakpoints.XS || bp === Breakpoints.SM;
  }
}