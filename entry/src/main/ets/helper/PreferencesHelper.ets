// entry/src/main/ets/utils/PreferencesHelper.ets

import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const PREF_STORE_NAME = 'sirat_settings';

/**
 * Delay before an automatic flush after the last write, in ms.
 *
 * Longer than a burst of related writes (a 4-key location save, a
 * 5-key offset reset) but short enough that a write is durable well
 * before the user can act on it.
 */
const FLUSH_DEBOUNCE_MS = 250;

/**
 * Async persistence helper backed by @ohos.data.preferences.
 *
 * ## Write model
 *
 * `put()` updates the in-memory map immediately, so any reader
 * sees the new value on its next `get()`. It does *not* touch disk.
 *
 * `flush()` writes the whole store to disk. Calling it after every
 * `put()` would multiply disk I/O by the number of keys in a single
 * logical save — the location save writes 4 keys, the offset reset
 * writes 5, and each would trigger its own full-store flush.
 *
 * Instead, every write schedules a debounced flush. A burst of
 * related writes within FLUSH_DEBOUNCE_MS coalesces into one disk
 * write. A lifecycle hook (`EntryAbility.onBackground`) forces an
 * immediate flush so nothing is lost when the process is suspended.
 *
 * ## Read model
 *
 * `getString` / `getNumber` / `getBoolean` await the store's
 * initialization, so callers that run before `EntryAbility` has
 * finished setting up see a correct default rather than throwing.
 */
export class PreferencesHelper {
  private static store: preferences.Preferences | null = null;

  private static initResolve: (() => void) | null = null;
  private static initPromise: Promise<void> = new Promise<void>((resolve) => {
    PreferencesHelper.initResolve = resolve;
  });
  /** Timer id for the debounced flush. -1 when none pending. */
  private static flushTimerId: number = -1;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  static async init(context: common.UIAbilityContext): Promise<void> {
    if (PreferencesHelper.store) {
      return;
    }

    try {
      PreferencesHelper.store = await preferences.getPreferences(
        context, PREF_STORE_NAME
      );
      console.info('[PreferencesHelper] Store initialized');
    } catch (err) {
      console.error(
        `[PreferencesHelper] Init failed: ${JSON.stringify(err)}`
      );
    } finally {
      if (PreferencesHelper.initResolve) {
        PreferencesHelper.initResolve();
        PreferencesHelper.initResolve = null;
      }
    }
  }

  // ============================================================
  // READS
  // ============================================================

  static async getString(key: string, def: string): Promise<string> {
    await PreferencesHelper.ensureReady();
    if (!PreferencesHelper.store) {
      return def;
    }
    try {
      return (await PreferencesHelper.store.get(key, def)) as string;
    } catch (err) {
      console.error(
        `[PreferencesHelper] getString(${key}) failed: ${JSON.stringify(err)}`
      );
      return def;
    }
  }

  static async getNumber(key: string, def: number): Promise<number> {
    await PreferencesHelper.ensureReady();
    if (!PreferencesHelper.store) {
      return def;
    }
    try {
      return (await PreferencesHelper.store.get(key, def)) as number;
    } catch (err) {
      console.error(
        `[PreferencesHelper] getNumber(${key}) failed: ${JSON.stringify(err)}`
      );
      return def;
    }
  }

  static async getBoolean(key: string, def: boolean): Promise<boolean> {
    await PreferencesHelper.ensureReady();
    if (!PreferencesHelper.store) {
      return def;
    }
    try {
      return (await PreferencesHelper.store.get(key, def)) as boolean;
    } catch (err) {
      console.error(
        `[PreferencesHelper] getBoolean(${key}) failed: ${JSON.stringify(err)}`
      );
      return def;
    }
  }

  // ============================================================
  // WRITES — put immediately, flush debounced
  // ============================================================

  static async setString(key: string, value: string): Promise<void> {
    await PreferencesHelper.ensureReady();
    if (!PreferencesHelper.store) {
      console.warn(
        `[PreferencesHelper] setString(${key}) – store not ready, skipping`
      );
      return;
    }
    try {
      await PreferencesHelper.store.put(key, value);
      PreferencesHelper.scheduleFlush();
    } catch (err) {
      console.error(
        `[PreferencesHelper] setString(${key}) failed: ${JSON.stringify(err)}`
      );
    }
  }

  static async setNumber(key: string, value: number): Promise<void> {
    await PreferencesHelper.ensureReady();
    if (!PreferencesHelper.store) {
      console.warn(
        `[PreferencesHelper] setNumber(${key}) – store not ready, skipping`
      );
      return;
    }
    try {
      await PreferencesHelper.store.put(key, value);
      PreferencesHelper.scheduleFlush();
    } catch (err) {
      console.error(
        `[PreferencesHelper] setNumber(${key}) failed: ${JSON.stringify(err)}`
      );
    }
  }

  static async setBoolean(key: string, value: boolean): Promise<void> {
    await PreferencesHelper.ensureReady();
    if (!PreferencesHelper.store) {
      console.warn(
        `[PreferencesHelper] setBoolean(${key}) – store not ready, skipping`
      );
      return;
    }
    try {
      await PreferencesHelper.store.put(key, value);
      PreferencesHelper.scheduleFlush();
    } catch (err) {
      console.error(
        `[PreferencesHelper] setBoolean(${key}) failed: ${JSON.stringify(err)}`
      );
    }
  }

  /**
   * Delete a key from the store and schedule a debounced flush.
   * Succeeds silently if the key doesn't exist.
   */
  static async remove(key: string): Promise<void> {
    await PreferencesHelper.ensureReady();
    if (!PreferencesHelper.store) {
      return;
    }
    try {
      await PreferencesHelper.store.delete(key);
      PreferencesHelper.scheduleFlush();
    } catch (err) {
      // Missing key — treat as success.
      console.info(`[PreferencesHelper] remove(${key}) — key absent`);
    }
  }

  // ============================================================
  // FLUSH
  // ============================================================

  /**
   * Force an immediate flush to disk and cancel any pending
   * debounced flush.
   *
   * Called from `EntryAbility.onBackground` so that a write made
   * within the last debounce window is durable before the process
   * is suspended. Also usable directly by any caller that needs to
   * guarantee persistence before a critical step.
   *
   * Replaces the old `flush()` (same behaviour, clearer name —
   * the old one was documented as "already flushed by setters",
   * which is no longer true).
   */
  static async flushNow(): Promise<void> {
    PreferencesHelper.cancelFlush();
    if (!PreferencesHelper.store) {
      return;
    }
    try {
      await PreferencesHelper.store.flush();
    } catch (err) {
      console.error(
        `[PreferencesHelper] flushNow failed: ${JSON.stringify(err)}`
      );
    }
  }

  // ============================================================
  // INTERNALS
  // ============================================================

  private static scheduleFlush(): void {
    if (PreferencesHelper.flushTimerId !== -1) {
      clearTimeout(PreferencesHelper.flushTimerId);
    }
    PreferencesHelper.flushTimerId = setTimeout(() => {
      PreferencesHelper.flushTimerId = -1;
      PreferencesHelper.flushNow();
    }, FLUSH_DEBOUNCE_MS);
  }

  private static cancelFlush(): void {
    if (PreferencesHelper.flushTimerId !== -1) {
      clearTimeout(PreferencesHelper.flushTimerId);
      PreferencesHelper.flushTimerId = -1;
    }
  }

  private static async ensureReady(): Promise<void> {
    if (PreferencesHelper.store) {
      return;
    }
    await PreferencesHelper.initPromise;
  }
}