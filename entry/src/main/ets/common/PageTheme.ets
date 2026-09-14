// entry/src/main/ets/common/PageTheme.ets

import { mediaquery } from '@kit.ArkUI';
import { Theme, ThemeColors, ThemeMode } from './Theme';

/**
 * Theme orchestration shared by every page.
 *
 * Pages keep their own `@State colors` for reactivity, but the
 * "system dark-mode listener" lifecycle and the `Theme.getColors`
 * call live here so they aren't copy-pasted five times.
 */
export class PageTheme {

  static isSystemDark(): boolean {
    try {
      return mediaquery.matchMediaSync('(dark-mode: true)').matches;
    } catch (err) {
      return false;
    }
  }

  static compute(themeMode: string): ThemeColors {
    return Theme.getColors(themeMode, PageTheme.isSystemDark());
  }

  /**
   * Installs a listener that fires when the OS dark-mode setting
   * changes. The callback only fires when `themeMode` is SYSTEM —
   * the listener is harmless otherwise.
   */
  static installSystemListener(
    themeMode: string,
    onChange: (colors: ThemeColors) => void
  ): mediaquery.MediaQueryListener | null {
    try {
      const listener = mediaquery.matchMediaSync('(dark-mode: true)');
      listener.on('change', (result: mediaquery.MediaQueryResult) => {
        if (themeMode === ThemeMode.SYSTEM) {
          onChange(Theme.getColors(themeMode, result.matches));
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