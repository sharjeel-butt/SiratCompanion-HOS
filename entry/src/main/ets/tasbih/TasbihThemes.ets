// TasbihThemes.ets

import { ThemeService } from '../core/ui/themes/ThemeService'
import { AppThemeJson } from '../core/ui/themes/ThemeModels'
import { ThemeColors } from '../core/ui/themes/Theme'

export interface BeadColors {
  hi: string
  base: string
  lo: string
}

export class TasbihThemes {
  static readonly DEFAULT_PRESET_ID = 'emerald'

  static getAllThemes(): AppThemeJson[] {
    return ThemeService.getAllThemes()
  }

  static getSwatch(themeId: string, appColors: ThemeColors): string {
    const theme = ThemeService.getAllThemes().find((t: AppThemeJson) => t.id === themeId)

    return theme ? theme.light.accent : appColors.accentGold
  }

  static getBeadColors(themeId: string, isDark: boolean): BeadColors {
    const theme = ThemeService.getAllThemes().find((t: AppThemeJson) => t.id === themeId)

    if (!theme) {
      return {
        hi: '#4ADE80', base: '#1E7A4E', lo: '#0B3B26'
      }
    }

    const cfg = isDark ? theme.dark : theme.light

    return {
      hi: ThemeService.lighten(cfg.accent, 25), base: cfg.accent, lo: ThemeService.lighten(cfg.accent, -25)
    }
  }
}
