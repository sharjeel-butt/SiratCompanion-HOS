// entry/src/main/ets/common/Theme.ets

export enum ThemeMode {
  LIGHT = 'Light',
  DARK = 'Dark',
  SYSTEM = 'System'
}

/**
 * App-level theme preset. Controls the overall colour identity
 * of the app, independent of light/dark mode.
 *
 * SIRAT is the default — a clean, minimal palette designed to sit
 * comfortably alongside the HarmonyOS 7 system aesthetic. The other
 * four presets remain available for users who prefer them.
 */
export enum ThemePreset {
  SIRAT = 'Sirat',
  CURRENT = 'Current',
  HARMONY_7 = 'Harmony7',
  HARMONY_6 = 'Harmony6',
  HARMONY_5 = 'Harmony5'
}

export class ThemeColors {
  primaryGreen: string = '#F0F4FA';
  cardDark: string = '#FFFFFF';
  cardMuted: string = '#EDF2F9';
  accentGold: string = '#3D7BF7';
  accentGoldLight: string = '#6B9BFF';
  textWhite: string = '#16181D';
  textLight: string = '#4A4F58';
  textMuted: string = '#7A8089';
  textOnAccent: string = '#FFFFFF';
  statusPray: string = '#3D7BF7';
  statusExpress: string = '#F5A623';
  tintSubtle: string = 'rgba(61,123,247,0.04)';
  tintSoft: string = 'rgba(61,123,247,0.07)';
  tintMedium: string = 'rgba(61,123,247,0.10)';
  tintStrong: string = 'rgba(61,123,247,0.14)';
  borderSoft: string = 'rgba(61,123,247,0.08)';
  borderMedium: string = 'rgba(61,123,247,0.12)';
  borderStrong: string = 'rgba(61,123,247,0.18)';
  overlayDim: string = 'rgba(22,24,29,0.38)';
  overlayDimSoft: string = 'rgba(0,0,0,0.10)';
  shadowCard: string = 'rgba(22,24,29,0.05)';
  shadowFloating: string = 'rgba(22,24,29,0.14)';
  placeholder: string = 'rgba(22,24,29,0.30)';
  dialogCancel: string = '#7A8089';
  categoryPrayerTimes: string = '#3D7BF7';
  categoryUICustomization: string = '#00A0C6';
  categoryAppearance: string = '#7C3AED';
  categoryCounter: string = '#3D7BF7';
  categoryAbout: string = '#F5A623';
  categoryHijriCalendar: string = '#06B6D4';
  categoryNotifications: string = '#F97316';
}

// ============================================================
// PALETTES
// ============================================================

class Palettes {
  // ----------------------------------------------------------
  // SIRAT — default. HarmonyOS 7 aesthetic.
  // Bright blue accent, near-black text, soft light-blue tinted
  // surfaces, minimal borders. Modelled on the system Data Clone
  // and Manage Storage screens.
  // ----------------------------------------------------------

  static siratLight(): ThemeColors {
    const c = new ThemeColors();
    c.primaryGreen = '#F0F4FA';
    c.cardDark = '#FFFFFF';
    c.cardMuted = '#EDF2F9';
    c.accentGold = '#3D7BF7';
    c.accentGoldLight = '#6B9BFF';
    c.textWhite = '#16181D';
    c.textLight = '#4A4F58';
    c.textMuted = '#7A8089';
    c.textOnAccent = '#FFFFFF';
    c.statusPray = '#3D7BF7';
    c.statusExpress = '#F5A623';
    c.tintSubtle = 'rgba(61,123,247,0.04)';
    c.tintSoft = 'rgba(61,123,247,0.07)';
    c.tintMedium = 'rgba(61,123,247,0.10)';
    c.tintStrong = 'rgba(61,123,247,0.14)';
    c.borderSoft = 'rgba(61,123,247,0.08)';
    c.borderMedium = 'rgba(61,123,247,0.12)';
    c.borderStrong = 'rgba(61,123,247,0.18)';
    c.overlayDim = 'rgba(22,24,29,0.38)';
    c.overlayDimSoft = 'rgba(0,0,0,0.10)';
    c.shadowCard = 'rgba(22,24,29,0.05)';
    c.shadowFloating = 'rgba(22,24,29,0.14)';
    c.placeholder = 'rgba(22,24,29,0.30)';
    c.dialogCancel = '#7A8089';
    c.categoryPrayerTimes = '#3D7BF7';
    c.categoryUICustomization = '#00A0C6';
    c.categoryAppearance = '#7C3AED';
    c.categoryCounter = '#3D7BF7';
    c.categoryAbout = '#F5A623';
    c.categoryHijriCalendar = '#06B6D4';
    c.categoryNotifications = '#F97316';
    return c;
  }

  static siratDark(): ThemeColors {
    const c = new ThemeColors();
    c.primaryGreen = '#0A0D14';
    c.cardDark = '#171D26';
    c.cardMuted = '#212A36';
    c.accentGold = '#6B9BFF';
    c.accentGoldLight = '#8FB6FF';
    c.textWhite = '#F5F7FA';
    c.textLight = '#B5BDC9';
    c.textMuted = '#7A8290';
    c.textOnAccent = '#0A0D14';
    c.statusPray = '#6B9BFF';
    c.statusExpress = '#FBBF24';
    c.tintSubtle = 'rgba(107,155,255,0.06)';
    c.tintSoft = 'rgba(107,155,255,0.10)';
    c.tintMedium = 'rgba(107,155,255,0.15)';
    c.tintStrong = 'rgba(107,155,255,0.20)';
    c.borderSoft = 'rgba(107,155,255,0.15)';
    c.borderMedium = 'rgba(107,155,255,0.22)';
    c.borderStrong = 'rgba(107,155,255,0.30)';
    c.overlayDim = 'rgba(0,0,0,0.68)';
    c.overlayDimSoft = 'rgba(255,255,255,0.14)';
    c.shadowCard = 'rgba(0,0,0,0.45)';
    c.shadowFloating = 'rgba(0,0,0,0.58)';
    c.placeholder = 'rgba(245,247,250,0.36)';
    c.dialogCancel = '#7A8290';
    c.categoryPrayerTimes = '#6B9BFF';
    c.categoryUICustomization = '#22D3EE';
    c.categoryAppearance = '#A78BFA';
    c.categoryCounter = '#38BDF8';
    c.categoryAbout = '#FBBF24';
    c.categoryHijriCalendar = '#22D3EE';
    c.categoryNotifications = '#FB923C';
    return c;
  }

  // ----------------------------------------------------------
  // SIRAT CLASSIC — warm cream + deep green
  // ----------------------------------------------------------

  static currentLight(): ThemeColors {
    const c = new ThemeColors();
    c.primaryGreen = '#F5F2EC';
    c.cardDark = '#FFFFFF';
    c.cardMuted = '#EAE6DE';
    c.accentGold = '#0F5132';
    c.accentGoldLight = '#1E7A4E';
    c.textWhite = '#1A1A1A';
    c.textLight = '#3F3F3F';
    c.textMuted = '#7A7A7A';
    c.textOnAccent = '#FFFFFF';
    c.statusPray = '#4CAF50';
    c.statusExpress = '#FF9800';
    c.tintSubtle = 'rgba(15,81,50,0.04)';
    c.tintSoft = 'rgba(15,81,50,0.06)';
    c.tintMedium = 'rgba(15,81,50,0.08)';
    c.tintStrong = 'rgba(15,81,50,0.10)';
    c.borderSoft = 'rgba(15,81,50,0.10)';
    c.borderMedium = 'rgba(15,81,50,0.12)';
    c.borderStrong = 'rgba(15,81,50,0.18)';
    c.overlayDim = 'rgba(0,0,0,0.35)';
    c.overlayDimSoft = 'rgba(0,0,0,0.15)';
    c.shadowCard = 'rgba(0,0,0,0.06)';
    c.shadowFloating = 'rgba(0,0,0,0.15)';
    c.placeholder = 'rgba(0,0,0,0.35)';
    c.dialogCancel = '#666666';
    c.categoryPrayerTimes = '#0F5132';
    c.categoryUICustomization = '#4CAF50';
    c.categoryAppearance = '#9C88FF';
    c.categoryCounter = '#4CC9F0';
    c.categoryAbout = '#F4A261';
    c.categoryHijriCalendar = '#06B6D4';
    c.categoryNotifications = '#F59E0B';
    return c;
  }

  static currentDark(): ThemeColors {
    const c = new ThemeColors();
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
    c.categoryHijriCalendar = '#22D3EE';
    c.categoryNotifications = '#FBBF24';
    return c;
  }

  // ----------------------------------------------------------
  // NOOR — vibrant violet
  // ----------------------------------------------------------

  static harmony7Light(): ThemeColors {
    const c = new ThemeColors();
    c.primaryGreen = '#F3F3F9';
    c.cardDark = '#FFFFFF';
    c.cardMuted = '#E7E7F2';
    c.accentGold = '#6D28D9';
    c.accentGoldLight = '#8B5CF6';
    c.textWhite = '#16111F';
    c.textLight = '#332B45';
    c.textMuted = '#6E6480';
    c.textOnAccent = '#FFFFFF';
    c.statusPray = '#6D28D9';
    c.statusExpress = '#F59E0B';
    c.tintSubtle = 'rgba(109,40,217,0.04)';
    c.tintSoft = 'rgba(109,40,217,0.06)';
    c.tintMedium = 'rgba(109,40,217,0.09)';
    c.tintStrong = 'rgba(109,40,217,0.12)';
    c.borderSoft = 'rgba(109,40,217,0.10)';
    c.borderMedium = 'rgba(109,40,217,0.14)';
    c.borderStrong = 'rgba(109,40,217,0.20)';
    c.overlayDim = 'rgba(22,17,31,0.38)';
    c.overlayDimSoft = 'rgba(0,0,0,0.12)';
    c.shadowCard = 'rgba(22,17,31,0.06)';
    c.shadowFloating = 'rgba(22,17,31,0.16)';
    c.placeholder = 'rgba(22,17,31,0.32)';
    c.dialogCancel = '#6E6480';
    c.categoryPrayerTimes = '#6D28D9';
    c.categoryUICustomization = '#06B6D4';
    c.categoryAppearance = '#DB2777';
    c.categoryCounter = '#0EA5E9';
    c.categoryAbout = '#F59E0B';
    c.categoryHijriCalendar = '#14B8A6';
    c.categoryNotifications = '#F97316';
    return c;
  }

  static harmony7Dark(): ThemeColors {
    const c = new ThemeColors();
    c.primaryGreen = '#0B0916';
    c.cardDark = '#181428';
    c.cardMuted = '#231D38';
    c.accentGold = '#A78BFA';
    c.accentGoldLight = '#C4B5FD';
    c.textWhite = '#F1ECFF';
    c.textLight = '#C8C0E0';
    c.textMuted = '#8981A0';
    c.textOnAccent = '#0B0916';
    c.statusPray = '#A78BFA';
    c.statusExpress = '#FBBF24';
    c.tintSubtle = 'rgba(167,139,250,0.06)';
    c.tintSoft = 'rgba(167,139,250,0.10)';
    c.tintMedium = 'rgba(167,139,250,0.15)';
    c.tintStrong = 'rgba(167,139,250,0.20)';
    c.borderSoft = 'rgba(167,139,250,0.15)';
    c.borderMedium = 'rgba(167,139,250,0.22)';
    c.borderStrong = 'rgba(167,139,250,0.30)';
    c.overlayDim = 'rgba(0,0,0,0.68)';
    c.overlayDimSoft = 'rgba(255,255,255,0.14)';
    c.shadowCard = 'rgba(0,0,0,0.45)';
    c.shadowFloating = 'rgba(0,0,0,0.58)';
    c.placeholder = 'rgba(241,236,255,0.36)';
    c.dialogCancel = '#8981A0';
    c.categoryPrayerTimes = '#A78BFA';
    c.categoryUICustomization = '#22D3EE';
    c.categoryAppearance = '#F472B6';
    c.categoryCounter = '#38BDF8';
    c.categoryAbout = '#FBBF24';
    c.categoryHijriCalendar = '#2DD4BF';
    c.categoryNotifications = '#FB923C';
    return c;
  }

  // ----------------------------------------------------------
  // SAHAR — golden amber
  // ----------------------------------------------------------

  static harmony6Light(): ThemeColors {
    const c = new ThemeColors();
    c.primaryGreen = '#F7F4EE';
    c.cardDark = '#FFFFFF';
    c.cardMuted = '#EDE6D9';
    c.accentGold = '#B45309';
    c.accentGoldLight = '#D97706';
    c.textWhite = '#1F1810';
    c.textLight = '#3F3423';
    c.textMuted = '#7A6E58';
    c.textOnAccent = '#FFFFFF';
    c.statusPray = '#B45309';
    c.statusExpress = '#DC2626';
    c.tintSubtle = 'rgba(180,83,9,0.04)';
    c.tintSoft = 'rgba(180,83,9,0.06)';
    c.tintMedium = 'rgba(180,83,9,0.09)';
    c.tintStrong = 'rgba(180,83,9,0.12)';
    c.borderSoft = 'rgba(180,83,9,0.10)';
    c.borderMedium = 'rgba(180,83,9,0.14)';
    c.borderStrong = 'rgba(180,83,9,0.20)';
    c.overlayDim = 'rgba(31,24,16,0.38)';
    c.overlayDimSoft = 'rgba(0,0,0,0.12)';
    c.shadowCard = 'rgba(31,24,16,0.06)';
    c.shadowFloating = 'rgba(31,24,16,0.16)';
    c.placeholder = 'rgba(31,24,16,0.32)';
    c.dialogCancel = '#7A6E58';
    c.categoryPrayerTimes = '#B45309';
    c.categoryUICustomization = '#EA580C';
    c.categoryAppearance = '#BE123C';
    c.categoryCounter = '#0284C7';
    c.categoryAbout = '#65A30D';
    c.categoryHijriCalendar = '#0D9488';
    c.categoryNotifications = '#DC2626';
    return c;
  }

  static harmony6Dark(): ThemeColors {
    const c = new ThemeColors();
    c.primaryGreen = '#14100A';
    c.cardDark = '#1F1A12';
    c.cardMuted = '#2A2318';
    c.accentGold = '#FBBF24';
    c.accentGoldLight = '#FCD34D';
    c.textWhite = '#FDF6E3';
    c.textLight = '#D4C5A8';
    c.textMuted = '#92815E';
    c.textOnAccent = '#14100A';
    c.statusPray = '#FBBF24';
    c.statusExpress = '#F87171';
    c.tintSubtle = 'rgba(251,191,36,0.06)';
    c.tintSoft = 'rgba(251,191,36,0.10)';
    c.tintMedium = 'rgba(251,191,36,0.15)';
    c.tintStrong = 'rgba(251,191,36,0.20)';
    c.borderSoft = 'rgba(251,191,36,0.15)';
    c.borderMedium = 'rgba(251,191,36,0.22)';
    c.borderStrong = 'rgba(251,191,36,0.30)';
    c.overlayDim = 'rgba(0,0,0,0.68)';
    c.overlayDimSoft = 'rgba(255,255,255,0.14)';
    c.shadowCard = 'rgba(0,0,0,0.45)';
    c.shadowFloating = 'rgba(0,0,0,0.58)';
    c.placeholder = 'rgba(253,246,227,0.36)';
    c.dialogCancel = '#92815E';
    c.categoryPrayerTimes = '#FBBF24';
    c.categoryUICustomization = '#FB923C';
    c.categoryAppearance = '#F472B6';
    c.categoryCounter = '#38BDF8';
    c.categoryAbout = '#A3E635';
    c.categoryHijriCalendar = '#2DD4BF';
    c.categoryNotifications = '#F87171';
    return c;
  }

  // ----------------------------------------------------------
  // BAHAR — cool teal
  // ----------------------------------------------------------

  static harmony5Light(): ThemeColors {
    const c = new ThemeColors();
    c.primaryGreen = '#F4F7F7';
    c.cardDark = '#FFFFFF';
    c.cardMuted = '#E8EEEE';
    c.accentGold = '#0D7878';
    c.accentGoldLight = '#14A0A0';
    c.textWhite = '#0D1A1A';
    c.textLight = '#2F3D3D';
    c.textMuted = '#647272';
    c.textOnAccent = '#FFFFFF';
    c.statusPray = '#0D7878';
    c.statusExpress = '#EA580C';
    c.tintSubtle = 'rgba(13,120,120,0.04)';
    c.tintSoft = 'rgba(13,120,120,0.06)';
    c.tintMedium = 'rgba(13,120,120,0.09)';
    c.tintStrong = 'rgba(13,120,120,0.12)';
    c.borderSoft = 'rgba(13,120,120,0.10)';
    c.borderMedium = 'rgba(13,120,120,0.14)';
    c.borderStrong = 'rgba(13,120,120,0.20)';
    c.overlayDim = 'rgba(13,26,26,0.38)';
    c.overlayDimSoft = 'rgba(0,0,0,0.12)';
    c.shadowCard = 'rgba(13,26,26,0.06)';
    c.shadowFloating = 'rgba(13,26,26,0.16)';
    c.placeholder = 'rgba(13,26,26,0.32)';
    c.dialogCancel = '#647272';
    c.categoryPrayerTimes = '#0D7878';
    c.categoryUICustomization = '#0891B2';
    c.categoryAppearance = '#6366F1';
    c.categoryCounter = '#0284C7';
    c.categoryAbout = '#D97706';
    c.categoryHijriCalendar = '#059669';
    c.categoryNotifications = '#EA580C';
    return c;
  }

  static harmony5Dark(): ThemeColors {
    const c = new ThemeColors();
    c.primaryGreen = '#0A1414';
    c.cardDark = '#132020';
    c.cardMuted = '#1C2A2A';
    c.accentGold = '#2DD4BF';
    c.accentGoldLight = '#5EEAD4';
    c.textWhite = '#EFFCFA';
    c.textLight = '#B8CCC8';
    c.textMuted = '#7A8D8A';
    c.textOnAccent = '#0A1414';
    c.statusPray = '#2DD4BF';
    c.statusExpress = '#FB923C';
    c.tintSubtle = 'rgba(45,212,191,0.06)';
    c.tintSoft = 'rgba(45,212,191,0.10)';
    c.tintMedium = 'rgba(45,212,191,0.15)';
    c.tintStrong = 'rgba(45,212,191,0.20)';
    c.borderSoft = 'rgba(45,212,191,0.15)';
    c.borderMedium = 'rgba(45,212,191,0.22)';
    c.borderStrong = 'rgba(45,212,191,0.30)';
    c.overlayDim = 'rgba(0,0,0,0.68)';
    c.overlayDimSoft = 'rgba(255,255,255,0.14)';
    c.shadowCard = 'rgba(0,0,0,0.45)';
    c.shadowFloating = 'rgba(0,0,0,0.58)';
    c.placeholder = 'rgba(239,252,250,0.36)';
    c.dialogCancel = '#7A8D8A';
    c.categoryPrayerTimes = '#2DD4BF';
    c.categoryUICustomization = '#22D3EE';
    c.categoryAppearance = '#A78BFA';
    c.categoryCounter = '#38BDF8';
    c.categoryAbout = '#FBBF24';
    c.categoryHijriCalendar = '#34D399';
    c.categoryNotifications = '#FB923C';
    return c;
  }
}

// ============================================================
// THEME
// ============================================================

export class Theme {
  static readonly radiusSmall = 8;
  static readonly radiusMedium = 16;
  static readonly radiusLarge = 24;
  static readonly paddingSmall = 8;
  static readonly paddingMedium = 16;
  static readonly paddingLarge = 24;

  /**
   * Resolve the effective ThemeColors for a mode + preset.
   *
   * @param mode          'Light' | 'Dark' | 'System'
   * @param isSystemDark  whether the OS is currently in dark mode
   * @param preset        ThemePreset string value
   */
  static getColors(
    mode: string,
    isSystemDark: boolean,
    preset: string
  ): ThemeColors {
    let effective = mode;
    if (mode === ThemeMode.SYSTEM) {
      effective = isSystemDark ? ThemeMode.DARK : ThemeMode.LIGHT;
    }
    const isDark = effective === ThemeMode.DARK;

    switch (preset) {
      case ThemePreset.CURRENT:
        return isDark ? Palettes.currentDark() : Palettes.currentLight();
      case ThemePreset.HARMONY_7:
        return isDark ? Palettes.harmony7Dark() : Palettes.harmony7Light();
      case ThemePreset.HARMONY_6:
        return isDark ? Palettes.harmony6Dark() : Palettes.harmony6Light();
      case ThemePreset.HARMONY_5:
        return isDark ? Palettes.harmony5Dark() : Palettes.harmony5Light();
      case ThemePreset.SIRAT:
      default:
        return isDark ? Palettes.siratDark() : Palettes.siratLight();
    }
  }
}