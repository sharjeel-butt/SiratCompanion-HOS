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
 *
 * Listeners are cached as static fields and reused — the previous
 * implementation called matchMediaSync on every evaluate(), which
 * created a new MediaQueryListener each time and accumulated them
 * over the session.
 */
export class LayoutHelper {
  private static installed: boolean = false;
  private static smListener: mediaquery.MediaQueryListener | null = null;
  private static mdListener: mediaquery.MediaQueryListener | null = null;
  private static lgListener: mediaquery.MediaQueryListener | null = null;

  /** Install once at app startup. */
  static install(): void {
    if (LayoutHelper.installed) {
      return;
    }
    LayoutHelper.installed = true;

    try {
      LayoutHelper.smListener = mediaquery.matchMediaSync('(width >= 320vp)');
      LayoutHelper.mdListener = mediaquery.matchMediaSync('(width >= 600vp)');
      LayoutHelper.lgListener = mediaquery.matchMediaSync('(width >= 840vp)');
    } catch (err) {
      console.warn('[LayoutHelper] listener creation failed');
    }

    LayoutHelper.evaluate();

    const onChange = (): void => {
      LayoutHelper.evaluate();
    };

    if (LayoutHelper.smListener !== null) {
      LayoutHelper.smListener.on('change', onChange);
    }
    if (LayoutHelper.mdListener !== null) {
      LayoutHelper.mdListener.on('change', onChange);
    }
    if (LayoutHelper.lgListener !== null) {
      LayoutHelper.lgListener.on('change', onChange);
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
   * Re-evaluate the current breakpoint from the cached listeners.
   * Called at install time and whenever a threshold crosses.
   */
  private static evaluate(): void {
    let bp = Breakpoints.XS;

    if (LayoutHelper.lgListener !== null && LayoutHelper.lgListener.matches) {
      bp = Breakpoints.LG;
    } else if (LayoutHelper.mdListener !== null && LayoutHelper.mdListener.matches) {
      bp = Breakpoints.MD;
    } else if (LayoutHelper.smListener !== null && LayoutHelper.smListener.matches) {
      bp = Breakpoints.SM;
    }

    AppStorage.setOrCreate(STORAGE_KEY_BREAKPOINT, bp);
    console.info(`[LayoutHelper] breakpoint = ${bp}`);
  }
}