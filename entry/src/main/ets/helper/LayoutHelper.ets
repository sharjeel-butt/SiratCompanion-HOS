// entry/src/main/ets/helper/LayoutHelper.ets

import { mediaquery } from '@kit.ArkUI';
import { Breakpoints } from '../common/Breakpoints';
import { STORAGE_KEY_BREAKPOINT } from '../common/StorageKeys';

/**
 * Reactive breakpoint tracking for the whole app.
 *
 * Listens to a set of width thresholds and stores the currently
 * active breakpoint in AppStorage. Any page can subscribe via
 * @StorageLink(STORAGE_KEY_BREAKPOINT) and re-layout accordingly.
 */
export class LayoutHelper {
  private static listeners: mediaquery.MediaQueryListener[] = [];
  private static installed: boolean = false;

  /** Install once at app startup. */
  static install(): void {
    if (LayoutHelper.installed) {
      return;
    }
    LayoutHelper.installed = true;

    LayoutHelper.evaluate();

    // Thresholds. Each threshold fires when the viewport crosses it.
    const queries = [
      '(width >= 320vp)',
      '(width >= 600vp)',
      '(width >= 840vp)'
    ];

    for (const q of queries) {
      try {
        const listener = mediaquery.matchMediaSync(q);
        listener.on('change', () => {
          LayoutHelper.evaluate();
        });
        LayoutHelper.listeners.push(listener);
      } catch (err) {
        console.warn(`[LayoutHelper] listener for "${q}" failed`);
      }
    }
  }

  /** Current breakpoint from AppStorage. */
  static current(): string {
    const v = AppStorage.get<string>(STORAGE_KEY_BREAKPOINT);
    return (v !== undefined && v.length > 0) ? v : Breakpoints.SM;
  }

  static isTablet(): boolean {
    return Breakpoints.isTablet(LayoutHelper.current());
  }

  static isLarge(): boolean {
    return Breakpoints.isLarge(LayoutHelper.current());
  }

  /**
   * Re-evaluate the current breakpoint from the live viewport.
   * Called at install time and whenever a threshold crosses.
   */
  private static evaluate(): void {
    let bp = Breakpoints.XS;

    try {
      if (mediaquery.matchMediaSync('(width >= 840vp)').matches) {
        bp = Breakpoints.LG;
      } else if (mediaquery.matchMediaSync('(width >= 600vp)').matches) {
        bp = Breakpoints.MD;
      } else if (mediaquery.matchMediaSync('(width >= 320vp)').matches) {
        bp = Breakpoints.SM;
      }
    } catch (err) {
      bp = Breakpoints.SM;
    }

    AppStorage.setOrCreate(STORAGE_KEY_BREAKPOINT, bp);
    console.info(`[LayoutHelper] breakpoint = ${bp}`);
  }
}