import { common } from '@kit.AbilityKit'
import { util } from '@kit.ArkTS'
import { ThemeColors, ThemeMode } from './Theme'
import { AppThemeJson } from './ThemeModels'
import { AppLogger } from '../../app/AppLogger'
import { RawPaths } from '../../common/RawPaths'

export class ThemeService {
  private static themes: AppThemeJson[] = []
  private static isLoaded: boolean = false

  static async init(ctx: common.Context): Promise<void> {
    if (ThemeService.isLoaded) {
      return
    }
    try {
      const data = await ctx.resourceManager.getRawFileContent(RawPaths.APP_THEMES)
      ThemeService.themes = JSON.parse(util.TextDecoder.create('utf-8').decodeToString(data)) as AppThemeJson[]
      ThemeService.isLoaded = true
    } catch (e) {
      AppLogger.error('ThemeService', `Failed to load themes: ${JSON.stringify(e)}`)
    }
  }

  static getAllThemes(): AppThemeJson[] {
    return ThemeService.themes
  }

  static generateColors(themeId: string, mode: string, isSystemDark: boolean): ThemeColors {
    let effectiveMode = mode
    if (mode === ThemeMode.SYSTEM) {
      effectiveMode = isSystemDark ? ThemeMode.DARK : ThemeMode.LIGHT
    }
    const isDark = effectiveMode === ThemeMode.DARK

    // Fallback to default if not found
    const safeThemeId = ThemeService.ensureValidThemeId(themeId)

    const theme = ThemeService.themes.find((t: AppThemeJson) => t.id === safeThemeId) ?? ThemeService.getDefaultTheme()

    const cfg = isDark ? theme.dark : theme.light

    const c = new ThemeColors()
    c.primaryGreen = cfg.bg
    c.cardDark = cfg.surface
    c.accentGold = cfg.accent
    c.textWhite = cfg.text

    // Auto-generate derived colors based on the accent hex
    c.accentGoldLight = isDark ? ThemeService.lighten(cfg.accent, 20) : ThemeService.lighten(cfg.accent, 10)
    c.textMuted = isDark ? 'rgba(255,255,255,0.5)' : 'rgba(0,0,0,0.5)'
    c.textOnAccent = isDark ? '#000000' : '#FFFFFF'

    c.tintSubtle = isDark ? 'rgba(255,255,255,0.04)' : 'rgba(0,0,0,0.03)'
    c.tintSoft = isDark ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.06)'
    c.tintMedium = isDark ? 'rgba(255,255,255,0.12)' : 'rgba(0,0,0,0.10)'
    c.tintStrong = isDark ? 'rgba(255,255,255,0.16)' : 'rgba(0,0,0,0.15)'

    c.borderSoft = isDark ? 'rgba(255,255,255,0.10)' : 'rgba(0,0,0,0.08)'
    c.borderMedium = isDark ? 'rgba(255,255,255,0.15)' : 'rgba(0,0,0,0.12)'
    c.borderStrong = isDark ? 'rgba(255,255,255,0.20)' : 'rgba(0,0,0,0.18)'

    return c
  }

  static lighten(hex: string, percent: number): string {
    let h = hex.replace('#', '')
    let r = parseInt(h.substring(0, 2), 16)
    let g = parseInt(h.substring(2, 4), 16)
    let b = parseInt(h.substring(4, 6), 16)
    r = Math.min(255, Math.max(0, r + Math.round(255 * (percent / 100))))
    g = Math.min(255, Math.max(0, g + Math.round(255 * (percent / 100))))
    b = Math.min(255, Math.max(0, b + Math.round(255 * (percent / 100))))
    return `#${r.toString(16).padStart(2, '0')}${g.toString(16).padStart(2, '0')}${b.toString(16).padStart(2, '0')}`
  }

  static getDefaultTheme(): AppThemeJson {
    const themes = ThemeService.getAllThemes()

    const defaultTheme = themes.find((t: AppThemeJson) => t.isDefault === true)

    if (defaultTheme !== undefined) {
      return defaultTheme
    }

    if (themes.length > 0) {
      return themes[0]
    }

    // Bootstrap fallback before themes load
    return {
      id: 'sirat',
      nameKey: 'theme_emerald',
      descKey: 'theme_emerald_desc',
      isDefault: true,
      light: {
        bg: '#F0F4FA',
        surface: '#FFFFFF',
        accent: '#1DB954',
        text: '#16181D'
      },
      dark: {
        bg: '#0A0D14',
        surface: '#171D26',
        accent: '#1DB954',
        text: '#F5F7FA'
      }
    }
  }

  static getDefaultThemeId(): string {
    return ThemeService.getDefaultTheme().id
  }

  static isValidThemeId(themeId: string): boolean {
    return ThemeService.themes.some((t: AppThemeJson) => t.id === themeId)
  }

  static ensureValidThemeId(themeId?: string): string {
    // Themes not loaded yet
    if (!ThemeService.isLoaded) {
      return themeId ?? 'sirat'
    }

    if (themeId !== undefined && themeId.length > 0 && ThemeService.isValidThemeId(themeId)) {
      return themeId
    }

    return ThemeService.getDefaultThemeId()
  }
}
