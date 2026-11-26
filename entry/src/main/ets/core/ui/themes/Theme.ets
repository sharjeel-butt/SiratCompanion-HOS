// Theme.ets

import { ThemeService } from './ThemeService'

export enum ThemeMode {
  LIGHT = 'Light', DARK = 'Dark', SYSTEM = 'System'
}

export class ThemeColors {
  primaryGreen: string = '#F0F4FA'
  cardDark: string = '#FFFFFF'
  cardMuted: string = '#EDF2F9'
  accentGold: string = '#3D7BF7'
  accentGoldLight: string = '#6B9BFF'
  textWhite: string = '#16181D'
  textLight: string = '#4A4F58'
  textMuted: string = '#7A8089'
  textOnAccent: string = '#FFFFFF'
  statusPray: string = '#3D7BF7'
  statusExpress: string = '#F5A623'
  tintSubtle: string = 'rgba(61,123,247,0.04)'
  tintSoft: string = 'rgba(61,123,247,0.07)'
  tintMedium: string = 'rgba(61,123,247,0.10)'
  tintStrong: string = 'rgba(61,123,247,0.14)'
  borderSoft: string = 'rgba(61,123,247,0.08)'
  borderMedium: string = 'rgba(61,123,247,0.12)'
  borderStrong: string = 'rgba(61,123,247,0.18)'
  overlayDim: string = 'rgba(22,24,29,0.38)'
  overlayDimSoft: string = 'rgba(0,0,0,0.10)'
  shadowCard: string = 'rgba(22,24,29,0.05)'
  shadowFloating: string = 'rgba(22,24,29,0.14)'
  placeholder: string = 'rgba(22,24,29,0.30)'
  dialogCancel: string = '#7A8089'
  categoryPrayerTimes: string = '#3D7BF7'
  categoryUICustomization: string = '#00A0C6'
  categoryAppearance: string = '#7C3AED'
  categoryCounter: string = '#3D7BF7'
  categoryAbout: string = '#F5A623'
  categoryHijriCalendar: string = '#06B6D4'
  categoryNotifications: string = '#F97316'
  colorGradeSahih: string = '#047857'
  bgGradeSahih: string = 'rgba(4,120,87,0.12)'
  colorGradeHasan: string = '#0284C7'
  bgGradeHasan: string = 'rgba(2,132,199,0.12)'
  colorGradeDaif: string = '#D97706'
  bgGradeDaif: string = 'rgba(217,119,6,0.12)'
  colorGradeMawdu: string = '#DC2626'
  bgGradeMawdu: string = 'rgba(220,38,38,0.12)'
  colorGradeUnverified: string = '#6B7280'
  bgGradeUnverified: string = 'rgba(107,114,128,0.12)'
}

export class Theme {
  static readonly radiusSmall = 8
  static readonly radiusMedium = 16
  static readonly radiusLarge = 24

  static getColors(mode: string, isSystemDark: boolean, themeId: string): ThemeColors {
    return ThemeService.generateColors(themeId, mode, isSystemDark)
  }
}
