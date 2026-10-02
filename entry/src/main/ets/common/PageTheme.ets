// entry/src/main/ets/common/PageTheme.ets

import { mediaquery } from '@kit.ArkUI';
import { Theme, ThemeColors, ThemeMode, ThemePreset } from './Theme';
import { STORAGE_KEY_APP_THEME } from './StorageKeys';

export class PageTheme {

  static isSystemDark(): boolean {
    try {
      return mediaquery.matchMediaSync('(dark-mode: true)').matches;
    } catch (err) {
      return false;
    }
  }

  /** Reads the current preset from AppStorage on every call. */
  private static currentPreset(): string {
    const v = AppStorage.get<string>(STORAGE_KEY_APP_THEME);
    return (v !== undefined && v.length > 0) ? v : ThemePreset.CURRENT;
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
        if (themeMode === ThemeMode.SYSTEM) {
          onChange(Theme.getColors(
            themeMode,
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
    if (!listener) return;
    try { listener.off('change'); } catch (err) { /* ignore */ }
  }
}