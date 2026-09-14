// entry/src/main/ets/utils/NavHelper.ets

import { STORAGE_KEY_NAV_DIRECTION } from '../common/StorageKeys';

/**
 * Decides the slide direction for tab-to-tab navigation.
 *
 *   Tapping a tab to the RIGHT of the current one → 'forward'
 *   Tapping a tab to the LEFT  of the current one → 'backward'
 *   router.back() is always 'backward'
 *
 * The chosen direction is written to AppStorage before navigation so
 * every page's pageTransition() can read it.
 */
export class NavHelper {

  static readonly HOME     = 0;
  static readonly TASBIH   = 1;
  static readonly COMPASS  = 2;
  static readonly CALENDAR = 3;

  static indexOf(tabId: string): number {
    switch (tabId) {
      case 'home':     return NavHelper.HOME;
      case 'tasbih':   return NavHelper.TASBIH;
      case 'compass':  return NavHelper.COMPASS;
      case 'calendar': return NavHelper.CALENDAR;
      default:         return NavHelper.HOME;
    }
  }

  static prepare(targetTab: string, currentTab: string): void {
    const targetIdx = NavHelper.indexOf(targetTab);
    const currentIdx = NavHelper.indexOf(currentTab);
    const dir: string = targetIdx >= currentIdx ? 'forward' : 'backward';
    AppStorage.setOrCreate(STORAGE_KEY_NAV_DIRECTION, dir);
  }

  static prepareBackward(): void {
    AppStorage.setOrCreate(STORAGE_KEY_NAV_DIRECTION, 'backward');
  }

  static prepareForward(): void {
    AppStorage.setOrCreate(STORAGE_KEY_NAV_DIRECTION, 'forward');
  }

  static current(): string {
    const v = AppStorage.get<string>(STORAGE_KEY_NAV_DIRECTION);
    return v ? v : 'forward';
  }

  static isForward(): boolean {
    return NavHelper.current() === 'forward';
  }
}