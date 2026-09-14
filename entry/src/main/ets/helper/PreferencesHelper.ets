// entry/src/main/ets/utils/PreferencesHelper.ets

import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const PREF_STORE_NAME = 'sirat_settings';

/**
 * Async persistence helper backed by @ohos.data.preferences.
 *
 * Guarantees that reads/writes will wait until the underlying store
 * has been initialized, even if a page accesses them before
 * EntryAbility's loadContent callback has fired.
 */
export class PreferencesHelper {

  private static store: preferences.Preferences | null = null;

  // Promise machinery to await init completion
  private static initResolve: (() => void) | null = null;
  private static initPromise: Promise<void> = new Promise<void>((resolve) => {
    PreferencesHelper.initResolve = resolve;
  });

  // ============================================================
  // INITIALIZATION
  // ============================================================

  /**
   * Initialize the preferences store. Call once at app startup
   * (after UI context is available, e.g. inside EntryAbility's
   * loadContent callback).
   */
  static async init(context: common.UIAbilityContext): Promise<void> {
    if (PreferencesHelper.store) {
      // Already initialized – nothing to do
      return;
    }

    try {
      PreferencesHelper.store = await preferences.getPreferences(context, PREF_STORE_NAME);
      console.info('[PreferencesHelper] Store initialized');
    } catch (err) {
      console.error(`[PreferencesHelper] Init failed: ${JSON.stringify(err)}`);
    } finally {
      // Release any readers that were waiting for the store
      if (PreferencesHelper.initResolve) {
        PreferencesHelper.initResolve();
        PreferencesHelper.initResolve = null;
      }
    }
  }

  /**
   * Ensures the store is ready before any operation.
   * If init() hasn't finished yet, wait for it.
   */
  private static async ensureReady(): Promise<void> {
    if (PreferencesHelper.store) return;
    await PreferencesHelper.initPromise;
  }

  // ============================================================
  // READS
  // ============================================================

  static async getString(key: string, def: string): Promise<string> {
    await PreferencesHelper.ensureReady();
    if (!PreferencesHelper.store) return def;

    try {
      return (await PreferencesHelper.store.get(key, def)) as string;
    } catch (err) {
      console.error(`[PreferencesHelper] getString(${key}) failed: ${JSON.stringify(err)}`);
      return def;
    }
  }

  static async getNumber(key: string, def: number): Promise<number> {
    await PreferencesHelper.ensureReady();
    if (!PreferencesHelper.store) return def;

    try {
      return (await PreferencesHelper.store.get(key, def)) as number;
    } catch (err) {
      console.error(`[PreferencesHelper] getNumber(${key}) failed: ${JSON.stringify(err)}`);
      return def;
    }
  }

  static async getBoolean(key: string, def: boolean): Promise<boolean> {
    await PreferencesHelper.ensureReady();
    if (!PreferencesHelper.store) return def;

    try {
      return (await PreferencesHelper.store.get(key, def)) as boolean;
    } catch (err) {
      console.error(`[PreferencesHelper] getBoolean(${key}) failed: ${JSON.stringify(err)}`);
      return def;
    }
  }

  // ============================================================
  // WRITES (immediately flushed to disk)
  // ============================================================

  static async setString(key: string, value: string): Promise<void> {
    await PreferencesHelper.ensureReady();
    if (!PreferencesHelper.store) {
      console.warn(`[PreferencesHelper] setString(${key}) – store not ready, skipping`);
      return;
    }

    try {
      await PreferencesHelper.store.put(key, value);
      await PreferencesHelper.store.flush();
      console.info(`[PreferencesHelper] Saved ${key}=${value}`);
    } catch (err) {
      console.error(`[PreferencesHelper] setString(${key}) failed: ${JSON.stringify(err)}`);
    }
  }

  static async setNumber(key: string, value: number): Promise<void> {
    await PreferencesHelper.ensureReady();
    if (!PreferencesHelper.store) {
      console.warn(`[PreferencesHelper] setNumber(${key}) – store not ready, skipping`);
      return;
    }

    try {
      await PreferencesHelper.store.put(key, value);
      await PreferencesHelper.store.flush();
      console.info(`[PreferencesHelper] Saved ${key}=${value}`);
    } catch (err) {
      console.error(`[PreferencesHelper] setNumber(${key}) failed: ${JSON.stringify(err)}`);
    }
  }

  static async setBoolean(key: string, value: boolean): Promise<void> {
    await PreferencesHelper.ensureReady();
    if (!PreferencesHelper.store) {
      console.warn(`[PreferencesHelper] setBoolean(${key}) – store not ready, skipping`);
      return;
    }

    try {
      await PreferencesHelper.store.put(key, value);
      await PreferencesHelper.store.flush();
      console.info(`[PreferencesHelper] Saved ${key}=${value}`);
    } catch (err) {
      console.error(`[PreferencesHelper] setBoolean(${key}) failed: ${JSON.stringify(err)}`);
    }
  }

  // ============================================================
  // UTILITY
  // ============================================================

  /**
   * Explicitly flush any pending writes to disk.
   * All setters already flush, so this is provided for completeness.
   */
  static async flush(): Promise<void> {
    await PreferencesHelper.ensureReady();
    if (!PreferencesHelper.store) return;

    try {
      await PreferencesHelper.store.flush();
    } catch (err) {
      console.error(`[PreferencesHelper] flush failed: ${JSON.stringify(err)}`);
    }
  }
}