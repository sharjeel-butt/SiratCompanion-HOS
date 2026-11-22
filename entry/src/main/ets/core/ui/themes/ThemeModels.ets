export interface AppThemeJson {
  id: string;
  nameKey: string;
  descKey: string;
  isDefault?: boolean;
  light: ThemeConfig;
  dark: ThemeConfig;
}

export interface ThemeConfig {
  bg: string;
  surface: string;
  accent: string;
  text: string;
}