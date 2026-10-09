// entry/src/main/ets/common/PageTheme.ets

import { mediaquery } from '@kit.ArkUI';
import { Theme, ThemeColors, ThemeMode, ThemePreset } from './Theme';
import { STORAGE_KEY_APP_THEME, STORAGE_KEY_THEME_MODE } from './StorageKeys';

export class PageTheme {
  /**
   * True when the operating system itself is in dark mode.
   *
   * NOTE: This reports the OS setting only. It does NOT account for
   * the user's Light / Dark / System choice. Use isDarkFor(themeMode)
   * anywhere the UI needs to know which palette is actually in effect.
   */
  static isSystemDark(): boolean {
    try {
      return mediaquery.matchMediaSync('(dark-mode: true)').matches;
    } catch (err) {
      return false;
    }
  }

  /**
   * Resolve whether the effective theme is dark, honouring the user's
   * Light / Dark / System choice.
   *
   * Use this instead of isSystemDark() anywhere the UI needs to pick
   * a palette. A user who picked Light while the OS is Dark must
   * still see the light palette.
   */
  static isDarkFor(themeMode: string): boolean {
    if (themeMode === ThemeMode.DARK) {
      return true;
    }
    if (themeMode === ThemeMode.LIGHT) {
      return false;
    }
    return PageTheme.isSystemDark();
  }

  static compute(themeMode: string): ThemeColors {
    return Theme.getColors(
      themeMode,
      PageTheme.isSystemDark(),
      PageTheme.currentPreset()
    );
  }

  static installSystemListener(
    themeMode: string,
    onChange: (colors: ThemeColors) => void
  ): mediaquery.MediaQueryListener | null {
    try {
      const listener = mediaquery.matchMediaSync('(dark-mode: true)');
      listener.on('change', (result: mediaquery.MediaQueryResult) => {

        const live = AppStorage.get<string>(STORAGE_KEY_THEME_MODE);
        const effective = (live !== undefined && live.length > 0)
          ? live
          : themeMode;

        if (effective === ThemeMode.SYSTEM) {
          onChange(Theme.getColors(
            effective,
            result.matches,
            PageTheme.currentPreset()
          ));
        }
      });
      return listener;
    } catch (err) {
      return null;
    }
  }

  static uninstallSystemListener(listener: mediaquery.MediaQueryListener | null): void {
    if (!listener) {
      return;
    }
    try {
      listener.off('change');
    } catch (err) { /* ignore */
    }
  }

  /** Reads the current preset from AppStorage on every call. */
  private static currentPreset(): string {
    const v = AppStorage.get<string>(STORAGE_KEY_APP_THEME);
    return (v !== undefined && v.length > 0) ? v : ThemePreset.SIRAT;
  }
}