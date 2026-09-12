// entry/src/main/ets/common/Theme.ets

export enum ThemeMode {
  LIGHT = 'Light',
  DARK = 'Dark',
  SYSTEM = 'System'
}

/**
 * A snapshot of every color used in the app.
 * Pages hold this in @State so theme changes re-render reliably.
 */
export class ThemeColors {
  primaryGreen: string = '#F5F2EC';
  cardDark: string = '#FFFFFF';
  cardMuted: string = '#EAE6DE';
  accentGold: string = '#0F5132';
  accentGoldLight: string = '#1E7A4E';
  textWhite: string = '#1A1A1A';
  textLight: string = '#3F3F3F';
  textMuted: string = '#7A7A7A';
  textOnAccent: string = '#FFFFFF';
  statusPray: string = '#4CAF50';
  statusExpress: string = '#FF9800';
  tintSubtle: string = 'rgba(15,81,50,0.04)';
  tintSoft: string = 'rgba(15,81,50,0.06)';
  tintMedium: string = 'rgba(15,81,50,0.08)';
  tintStrong: string = 'rgba(15,81,50,0.10)';
  borderSoft: string = 'rgba(15,81,50,0.10)';
  borderMedium: string = 'rgba(15,81,50,0.12)';
  borderStrong: string = 'rgba(15,81,50,0.18)';
  overlayDim: string = 'rgba(0,0,0,0.35)';
  overlayDimSoft: string = 'rgba(0,0,0,0.15)';
  shadowCard: string = 'rgba(0,0,0,0.06)';
  shadowFloating: string = 'rgba(0,0,0,0.15)';
  placeholder: string = 'rgba(0,0,0,0.35)';
  dialogCancel: string = '#666666';
  categoryPrayerTimes: string = '#0F5132';
  categoryUICustomization: string = '#4CAF50';
  categoryAppearance: string = '#9C88FF';
  categoryCounter: string = '#4CC9F0';
  categoryAbout: string = '#F4A261';
}

export class Theme {

  // ---- Layout constants (theme-independent) ----
  static readonly radiusSmall = 8;
  static readonly radiusMedium = 16;
  static readonly radiusLarge = 24;
  static readonly paddingSmall = 8;
  static readonly paddingMedium = 16;
  static readonly paddingLarge = 24;

  /**
   * Return a fresh ThemeColors instance for the given mode.
   * @param mode "Light" | "Dark" | "System"
   * @param isSystemDark true if the OS is in dark mode
   */
  static getColors(mode: string, isSystemDark: boolean): ThemeColors {
    let effective = mode;
    if (mode === ThemeMode.SYSTEM) {
      effective = isSystemDark ? ThemeMode.DARK : ThemeMode.LIGHT;
    }

    const c = new ThemeColors();

    if (effective === ThemeMode.DARK) {
      c.primaryGreen = '#0B1220';
      c.cardDark = '#141B2E';
      c.cardMuted = '#1E2840';
      c.accentGold = '#4ADE80';
      c.accentGoldLight = '#86EFAC';
      c.textWhite = '#F1F5F9';
      c.textLight = '#CBD5E1';
      c.textMuted = '#94A3B8';
      c.textOnAccent = '#0B1220';
      c.statusPray = '#4ADE80';
      c.statusExpress = '#FBBF24';
      c.tintSubtle = 'rgba(74,222,128,0.06)';
      c.tintSoft = 'rgba(74,222,128,0.10)';
      c.tintMedium = 'rgba(74,222,128,0.14)';
      c.tintStrong = 'rgba(74,222,128,0.18)';
      c.borderSoft = 'rgba(74,222,128,0.15)';
      c.borderMedium = 'rgba(74,222,128,0.20)';
      c.borderStrong = 'rgba(74,222,128,0.28)';
      c.overlayDim = 'rgba(0,0,0,0.65)';
      c.overlayDimSoft = 'rgba(255,255,255,0.15)';
      c.shadowCard = 'rgba(0,0,0,0.40)';
      c.shadowFloating = 'rgba(0,0,0,0.55)';
      c.placeholder = 'rgba(255,255,255,0.40)';
      c.dialogCancel = '#94A3B8';
      c.categoryPrayerTimes = '#4ADE80';
      c.categoryUICustomization = '#4ADE80';
      c.categoryAppearance = '#A78BFA';
      c.categoryCounter = '#38BDF8';
      c.categoryAbout = '#FBBF24';
    }
    // Light is the default (already set in the constructor)

    return c;
  }
}