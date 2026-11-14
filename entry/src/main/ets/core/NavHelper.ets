// entry/src/main/ets/core/NavHelper.ets

import { STORAGE_KEY_NAV_DIRECTION } from './StorageKeys';

/**
 * Decides the slide direction for routed navigation.
 *
 * The direction is written to `STORAGE_KEY_NAV_DIRECTION` and is
 * reserved for a future page-transition implementation — no page
 * currently reads the value. The rulebook (§H) mandates that
 * `prepareForward()` be called before every `router.pushUrl()` so
 * that when the transition animation is added, the direction is
 * already correct on all existing call sites.
 *
 * `router.back()` is always a "backward" navigation — call
 * `prepareBackward()` before it if you add a transition that cares.
 */
export class NavHelper {
  static prepareForward(): void {
    AppStorage.setOrCreate(STORAGE_KEY_NAV_DIRECTION, 'forward');
  }

  static prepareBackward(): void {
    AppStorage.setOrCreate(STORAGE_KEY_NAV_DIRECTION, 'backward');
  }
}