// entry/src/main/ets/utils/UserBackupService.ets

import { fileIo as fs, picker, ReadOptions } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { buffer } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { PreferencesHelper } from '../helper/PreferencesHelper';
import { PrayerManager } from '../prayer/PrayerManager';
import { TasbihStorage } from '../tasbih/TasbihStorage';
import { TasbihManager } from '../tasbih/TasbihManager';
import { RamadanStorage } from '../helper/RamadanStorage';
import { AppLogger } from '../helper/AppLogger';
import {
  STORAGE_KEY_APP_FOREGROUND_TICK,
  STORAGE_KEY_APP_THEME,
  STORAGE_KEY_AUTO_SHOW_RAMADAN_VIEW,
  STORAGE_KEY_CALC_SETTINGS_VERSION,
  STORAGE_KEY_EVENT_PERSPECTIVE,
  STORAGE_KEY_EVENT_SETTINGS_VERSION,
  STORAGE_KEY_HIJRI_CALENDAR_TYPE,
  STORAGE_KEY_HIJRI_CALENDAR_VERSION,
  STORAGE_KEY_HIJRI_OFFSET,
  STORAGE_KEY_LANGUAGE,
  STORAGE_KEY_LOCATION_VERSION,
  STORAGE_KEY_PRAYER_STATE_VERSION,
  STORAGE_KEY_RAMADAN_STATE_VERSION,
  STORAGE_KEY_SHOW_FIRST_THIRD_LIST,
  STORAGE_KEY_SHOW_FIRST_THIRD_SUNPATH,
  STORAGE_KEY_SHOW_IMSAK_LIST,
  STORAGE_KEY_SHOW_IMSAK_SUNPATH,
  STORAGE_KEY_SHOW_ISLAMIC_EVENTS,
  STORAGE_KEY_SHOW_LAST_THIRD_LIST,
  STORAGE_KEY_SHOW_LAST_THIRD_SUNPATH,
  STORAGE_KEY_SHOW_MIDNIGHT_LIST,
  STORAGE_KEY_SHOW_MIDNIGHT_SUNPATH,
  STORAGE_KEY_SOUND_ENABLED,
  STORAGE_KEY_TASBIH_SOUND,
  STORAGE_KEY_TASBIH_STATE_VERSION,
  STORAGE_KEY_THEME_MODE,
  STORAGE_KEY_TIME_FORMAT,
  STORAGE_KEY_VIBRATION_ENABLED,
  STORAGE_KEY_WIZARD_COMPLETED
} from '../common/StorageKeys';

// ============================================================
// Public result shapes
// ============================================================

export interface BackupResult {
  ok: boolean;
  message: string;
  path?: string;
}

export interface RestoreResult {
  ok: boolean;
  message: string;
  backedUpVersion?: string;
}

interface ValidationResult {
  ok: boolean;
  message: string;
}

// ============================================================
// Internal types
// ============================================================

/**
 * Every value in preferences is one of these three primitives.
 * Structured data (`prayer_state_map`, `tasbihs_data`) is stored
 * as a JSON-in-string and therefore also lands here as `string`.
 */
type BackupValue = string | number | boolean;

type PrefType = 'string' | 'number' | 'boolean';

interface PrefSpec {
  key: string;
  type: PrefType;
}

interface BackupFileShape {
  app: string;
  formatVersion: number;
  backupVersion: string;
  createdAt: string;
  createdAtEpochMs: number;
  language: string;
  settings: Record<string, BackupValue>;
  tasbih: Record<string, BackupValue>;
}

// ============================================================
// Schema constants
// ============================================================

const BACKUP_APP_MARKER = 'SiratCompanion';
const BACKUP_FORMAT_VERSION = 1;

// These mirror PreferencesHelper (sirat_settings) and
// TasbihStorage (tasbih_prefs).
const STORE_SETTINGS = 'sirat_settings';
const STORE_TASBIH = 'tasbih_prefs';

// ------------------------------------------------------------
// The complete set of keys that can appear in a backup. Must be
// kept in sync with EntryBackupAbility's SETTINGS_SPECS and
// TASBIH_SPECS. Unknown keys in a restored file are logged and
// dropped, so adding a new key to a future build is safe.
// ------------------------------------------------------------

const SETTINGS_SPECS: PrefSpec[] = [
  // ---- Calculation & Location ----
  { key: 'calc_method', type: 'string' },
  { key: 'asr_rule', type: 'number' },
  { key: 'calc_source', type: 'string' },
  { key: 'location_mode', type: 'string' },
  { key: 'manual_lat', type: 'number' },
  { key: 'manual_lng', type: 'number' },
  { key: 'manual_refresh', type: 'number' },
  { key: 'manual_city', type: 'string' },
  { key: 'high_lat_rule', type: 'string' },
  { key: 'calc_rounding_method', type: 'string' },
  { key: 'calc_midnight_method', type: 'string' },
  { key: 'calc_polar_resolution', type: 'string' },
  { key: 'calc_shafaq', type: 'string' },
  { key: 'calc_custom_fajr', type: 'number' },
  { key: 'calc_custom_isha', type: 'number' },
  { key: 'calc_custom_isha_interval', type: 'number' },
  { key: 'offset_fajr', type: 'number' },
  { key: 'offset_dhuhr', type: 'number' },
  { key: 'offset_asr', type: 'number' },
  { key: 'offset_maghrib', type: 'number' },
  { key: 'offset_isha', type: 'number' },

  // ---- GPS Cache ----
  { key: 'gps_lat', type: 'number' },
  { key: 'gps_lng', type: 'number' },
  { key: 'gps_city', type: 'string' },
  { key: 'gps_refresh', type: 'number' },

  // ---- App Settings ----
  { key: 'theme_mode', type: 'string' },
  { key: 'app_theme_preset', type: 'string' },
  { key: 'app_language', type: 'string' },
  { key: 'time_format', type: 'string' },
  { key: 'wizard_completed', type: 'boolean' },
  { key: 'hijri_offset', type: 'number' },
  { key: 'hijri_calendar_type', type: 'string' },
  { key: 'event_perspective', type: 'string' },
  { key: 'auto_show_ramadan_view', type: 'boolean' },
  { key: 'show_islamic_events', type: 'boolean' },

  // ---- Extra Timings (Legacy & Current) ----
  { key: 'show_extra_timings', type: 'boolean' },
  { key: 'show_extra_timings_list', type: 'boolean' },
  { key: 'show_extra_timings_sunpath', type: 'boolean' },
  { key: 'show_imsak', type: 'boolean' },
  { key: 'show_first_third', type: 'boolean' },
  { key: 'show_midnight', type: 'boolean' },
  { key: 'show_last_third', type: 'boolean' },
  { key: 'show_imsak_list', type: 'boolean' },
  { key: 'show_first_third_list', type: 'boolean' },
  { key: 'show_midnight_list', type: 'boolean' },
  { key: 'show_last_third_list', type: 'boolean' },
  { key: 'show_imsak_sunpath', type: 'boolean' },
  { key: 'show_first_third_sunpath', type: 'boolean' },
  { key: 'show_midnight_sunpath', type: 'boolean' },
  { key: 'show_last_third_sunpath', type: 'boolean' },

  // ---- Notifications ----
  { key: 'notif_master_enabled', type: 'boolean' },
  { key: 'notif_before_minutes', type: 'number' },
  { key: 'notif_fajr', type: 'boolean' },
  { key: 'notif_dhuhr', type: 'boolean' },
  { key: 'notif_asr', type: 'boolean' },
  { key: 'notif_maghrib', type: 'boolean' },
  { key: 'notif_isha', type: 'boolean' },

  // ---- Sound & Haptics ----
  { key: 'vibration_enabled', type: 'boolean' },
  { key: 'sound_enabled', type: 'boolean' },
  { key: 'tasbih_sound', type: 'string' },
  { key: 'tasbih_render_style', type: 'string' },
  { key: 'tasbih_theme_preset', type: 'string' },

  // ---- Prayer Progress (CRITICAL) ----
  // Stored as a JSON string: { "<date>": "<json-check-state>" }.
  // Kept as-is in the backup so it round-trips through both this
  // service and EntryBackupAbility without type gymnastics.
  { key: 'prayer_state_map', type: 'string' },
  // ---- Ramadan Tracker ----
  // JSON-serialized RamadanLogStore covering fasting, taraweeh,
  // and qada data for every year the user has tracked.
  { key: 'ramadan_log', type: 'string' }
];

const TASBIH_SPECS: PrefSpec[] = [
  // Stored as a JSON string of the full tasbih array.
  { key: 'tasbihs_data', type: 'string' },
  { key: 'tasbih_active_id', type: 'string' },
  { key: 'tasbih_active_dhikr', type: 'number' }
];

// ============================================================
// UserBackupService
// ============================================================

export class UserBackupService {
  // ============================================================
  // BACKUP
  // ============================================================

  static async backupToFile(
    context: common.UIAbilityContext,
    appVersion: string
  ): Promise<BackupResult> {
    try {
      // 1. Build the backup payload.
      const backup = await UserBackupService.buildBackupObject(
        context, appVersion
      );
      const json = JSON.stringify(backup, null, 2);

      // 2. Let the user pick a save location.
      const uri = await UserBackupService.pickSaveLocation(context, backup);
      if (uri.length === 0) {
        return { ok: false, message: 'cancelled' };
      }

      // 3. Write.
      const written = UserBackupService.writeTextToUri(uri, json);
      if (!written) {
        return { ok: false, message: 'write_failed' };
      }

      AppLogger.info('UserBackupService',
        `Backup saved: ${uri} (${json.length} bytes, ` +
          `${Object.keys(backup.settings).length} settings, ` +
          `${Object.keys(backup.tasbih).length} tasbih keys)`);

      return { ok: true, message: 'saved', path: uri };
    } catch (err) {
      const e = err as BusinessError;
      AppLogger.error('UserBackupService',
        `backupToFile failed: ${e.code ?? ''} ${e.message ?? ''}`);
      return { ok: false, message: e.message ?? 'unknown_error' };
    }
  }

  private static async buildBackupObject(
    context: common.UIAbilityContext,
    appVersion: string
  ): Promise<BackupFileShape> {
    const settings = await UserBackupService.collectStore(
      context, STORE_SETTINGS, SETTINGS_SPECS
    );
    const tasbih = await UserBackupService.collectStore(
      context, STORE_TASBIH, TASBIH_SPECS
    );
    const lang = AppStorage.get<string>(STORAGE_KEY_LANGUAGE) ?? 'en';

    return {
      app: BACKUP_APP_MARKER,
      formatVersion: BACKUP_FORMAT_VERSION,
      backupVersion: appVersion,
      createdAt: new Date().toISOString(),
      createdAtEpochMs: Date.now(),
      language: lang,
      settings,
      tasbih
    };
  }

  private static async collectStore(
    context: common.UIAbilityContext,
    storeName: string,
    specs: PrefSpec[]
  ): Promise<Record<string, BackupValue>> {
    const store = await preferences.getPreferences(context, storeName);
    const out: Record<string, BackupValue> = {};

    for (const spec of specs) {
      try {
        const has = await store.has(spec.key);
        if (!has) {
          // Absent — skip. On restore, the key falls through to its
          // default, which matches the current (never-set) state.
          continue;
        }

        if (spec.type === 'string') {
          const v = await store.get(spec.key, '');
          out[spec.key] = String(v);
        } else if (spec.type === 'number') {
          const v = await store.get(spec.key, 0);
          out[spec.key] = Number(v);
        } else {
          const v = await store.get(spec.key, false);
          out[spec.key] = v === true;
        }
      } catch (err) {
        AppLogger.warn('UserBackupService',
          `${storeName}.${spec.key}: read failed, skipping`);
      }
    }
    return out;
  }

  private static async pickSaveLocation(
    context: common.UIAbilityContext,
    backup: BackupFileShape
  ): Promise<string> {
    try {
      const documentPicker = new picker.DocumentViewPicker(context);
      const options = new picker.DocumentSaveOptions();
      const datePart = backup.createdAt.substring(0, 10); // YYYY-MM-DD
      options.newFileNames = [`SiratBackup_${datePart}.json`];
      const uris = await documentPicker.save(options);
      if (!uris || uris.length === 0) {
        return '';
      }
      return uris[0];
    } catch (err) {
      // User cancel is often surfaced as a thrown BusinessError on
      // some SDK builds — treat as a silent cancellation.
      AppLogger.info('UserBackupService',
        'save picker dismissed by user or unavailable');
      return '';
    }
  }

  private static writeTextToUri(uri: string, content: string): boolean {
    let file: fs.File | null = null;
    try {
      // The picker has already created the file. TRUNC clears any
      // pre-existing content before we write.
      file = fs.openSync(uri, fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
    } catch (err) {
      try {
        file = fs.openSync(
          uri,
          fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE | fs.OpenMode.TRUNC
        );
      } catch (err2) {
        AppLogger.warn('UserBackupService',
          `writeTextToUri: open failed for ${uri}`);
        return false;
      }
    }
    try {
      fs.writeSync(file.fd, content);
      fs.closeSync(file);
      return true;
    } catch (err) {
      try {
        fs.closeSync(file);
      } catch (ignore) {
      }
      return false;
    }
  }

  // ============================================================
  // RESTORE
  // ============================================================

  static async restoreFromFile(
    context: common.UIAbilityContext
  ): Promise<RestoreResult> {
    try {
      // 1. Let the user pick a file.
      const uri = await UserBackupService.pickOpenLocation(context);
      if (uri.length === 0) {
        return { ok: false, message: 'cancelled' };
      }

      // 2. Read.
      const content = UserBackupService.readTextFromUri(uri);
      if (content.length === 0) {
        return { ok: false, message: 'read_failed' };
      }

      // 3. Parse.
      let backup: BackupFileShape;
      try {
        backup = JSON.parse(content) as BackupFileShape;
      } catch {
        return { ok: false, message: 'invalid_json' };
      }

      // 4. Validate.
      const validation = UserBackupService.validateBackup(backup);
      if (!validation.ok) {
        return { ok: false, message: validation.message };
      }

      // 5. Apply — full replacement.
      await UserBackupService.applyBackup(context, backup);

      // 6. Reload everything so the UI reflects the new state.
      await UserBackupService.reloadAllAfterRestore(context);

      AppLogger.info('UserBackupService',
        `Restore complete: backup from v${backup.backupVersion} ` +
          `created ${backup.createdAt}`);
      return {
        ok: true,
        message: 'restored',
        backedUpVersion: backup.backupVersion
      };
    } catch (err) {
      const e = err as BusinessError;
      AppLogger.error('UserBackupService',
        `restoreFromFile failed: ${e.code ?? ''} ${e.message ?? ''}`);
      return { ok: false, message: e.message ?? 'unknown_error' };
    }
  }

  private static async pickOpenLocation(
    context: common.UIAbilityContext
  ): Promise<string> {
    try {
      const documentPicker = new picker.DocumentViewPicker(context);
      const options = new picker.DocumentSelectOptions();
      options.fileSuffixFilters = ['.json'];
      options.maxSelectNumber = 1;
      const uris = await documentPicker.select(options);
      if (!uris || uris.length === 0) {
        return '';
      }
      return uris[0];
    } catch (err) {
      AppLogger.info('UserBackupService',
        'open picker dismissed by user or unavailable');
      return '';
    }
  }

  private static readTextFromUri(uri: string): string {
    let stat: fs.Stat;
    try {
      stat = fs.statSync(uri);
    } catch (err) {
      return '';
    }
    if (stat.size === 0) {
      return '';
    }

    let file: fs.File | null = null;
    try {
      file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
    } catch (err) {
      return '';
    }

    try {
      const buf = new ArrayBuffer(stat.size);
      const opts: ReadOptions = { offset: 0, length: stat.size };
      const bytesRead = fs.readSync(file.fd, buf, opts);
      fs.closeSync(file);
      const u8 = new Uint8Array(buf, 0, bytesRead);
      return buffer.from(u8).toString('utf8');
    } catch (err) {
      try {
        fs.closeSync(file);
      } catch (ignore) {
      }
      return '';
    }
  }

  private static validateBackup(
    backup: BackupFileShape
  ): ValidationResult {
    if (!backup || typeof backup !== 'object') {
      return { ok: false, message: 'not_an_object' };
    }
    if (typeof backup.app !== 'string' || backup.app !== BACKUP_APP_MARKER) {
      return { ok: false, message: 'wrong_app' };
    }
    if (typeof backup.formatVersion !== 'number' || backup.formatVersion < 1) {
      return { ok: false, message: 'invalid_format' };
    }
    if (backup.formatVersion > BACKUP_FORMAT_VERSION) {
      return { ok: false, message: 'newer_format' };
    }
    if (!backup.settings || typeof backup.settings !== 'object') {
      return { ok: false, message: 'missing_settings' };
    }
    if (!backup.tasbih || typeof backup.tasbih !== 'object') {
      return { ok: false, message: 'missing_tasbih' };
    }
    return { ok: true, message: 'ok' };
  }

  private static async applyBackup(
    context: common.UIAbilityContext,
    backup: BackupFileShape
  ): Promise<void> {
    await UserBackupService.applyStore(
      context, STORE_SETTINGS, backup.settings, SETTINGS_SPECS
    );
    await UserBackupService.applyStore(
      context, STORE_TASBIH, backup.tasbih, TASBIH_SPECS
    );
    // Defensive flush so the subsequent reload reads the new values.
    await PreferencesHelper.flushNow();
  }

  private static async applyStore(
    context: common.UIAbilityContext,
    storeName: string,
    data: Record<string, BackupValue>,
    specs: PrefSpec[]
  ): Promise<void> {
    const store = await preferences.getPreferences(context, storeName);

    // Full replacement — clear first.
    await store.clear();

    let applied = 0;
    let dropped = 0;

    for (const spec of specs) {
      const value: BackupValue | undefined = data[spec.key];
      if (value === undefined) {
        continue;
      }

      let ok = false;
      try {
        if (spec.type === 'string' && typeof value === 'string') {
          await store.put(spec.key, value);
          ok = true;
        } else if (spec.type === 'number' && typeof value === 'number') {
          await store.put(spec.key, value);
          ok = true;
        } else if (spec.type === 'boolean' && typeof value === 'boolean') {
          await store.put(spec.key, value);
          ok = true;
        } else {
          AppLogger.warn('UserBackupService',
            `${storeName}.${spec.key}: type mismatch (expected ${spec.type}), dropped`);
        }
      } catch (err) {
        AppLogger.warn('UserBackupService',
          `${storeName}.${spec.key}: put failed, dropped`);
      }

      if (ok) {
        applied++;
      } else {
        dropped++;
      }
    }

    // Log any keys in the file that this build doesn't know about.
    const knownKeys = new Set<string>();
    for (const spec of specs) {
      knownKeys.add(spec.key);
    }
    for (const key of Object.keys(data)) {
      if (!knownKeys.has(key)) {
        dropped++;
        AppLogger.warn('UserBackupService',
          `${storeName}.${key}: unknown key in backup, dropped`);
      }
    }

    await store.flush();
    AppLogger.info('UserBackupService',
      `${storeName}: applied ${applied}, dropped ${dropped}`);
  }

  // ============================================================
  // RELOAD AFTER RESTORE
  // ============================================================

  private static async reloadAllAfterRestore(
    context: common.UIAbilityContext
  ): Promise<void> {
    // 1. Re-prime module-level caches.
    await PrayerManager.primeStateMap();
    await TasbihStorage.init(context);
    await TasbihStorage.load(TasbihManager.createDefaults());

    // 2. RamadanStorage.doLoad() runs schema migrations inline if
    //    the restored backup was written by an older build (e.g.
    //    pre-v3.5.0 backups that carry a `qadaMadeUp` counter
    //    instead of per-day `madeUp` flags). Loading here
    //    guarantees the migration persists before the version
    //    bump wakes any UI — no page ever sees the pre-migration
    //    schema. The returned store is discarded: pages read it
    //    fresh via RamadanStorage.load() on the version bump.
    await RamadanStorage.load();

    // 3. Re-seed AppStorage from the restored preferences.
    await UserBackupService.seedAppStorageFromPrefs();

    // 4. Bump every version counter — this triggers @Watch on every
    //    subscribed page, forcing a fresh load via SettingsHelper.
    UserBackupService.bumpVersion(STORAGE_KEY_PRAYER_STATE_VERSION);
    UserBackupService.bumpVersion(STORAGE_KEY_CALC_SETTINGS_VERSION);
    UserBackupService.bumpVersion(STORAGE_KEY_EVENT_SETTINGS_VERSION);
    UserBackupService.bumpVersion(STORAGE_KEY_HIJRI_CALENDAR_VERSION);
    UserBackupService.bumpVersion(STORAGE_KEY_LOCATION_VERSION);
    UserBackupService.bumpVersion(STORAGE_KEY_TASBIH_STATE_VERSION);
    UserBackupService.bumpVersion(STORAGE_KEY_RAMADAN_STATE_VERSION);
    UserBackupService.bumpVersion(STORAGE_KEY_APP_FOREGROUND_TICK);
  }

  private static async seedAppStorageFromPrefs(): Promise<void> {
    AppStorage.setOrCreate(STORAGE_KEY_THEME_MODE,
      await PreferencesHelper.getString(STORAGE_KEY_THEME_MODE, 'System'));
    AppStorage.setOrCreate(STORAGE_KEY_APP_THEME,
      await PreferencesHelper.getString(STORAGE_KEY_APP_THEME, 'Sirat'));
    AppStorage.setOrCreate(STORAGE_KEY_LANGUAGE,
      await PreferencesHelper.getString(STORAGE_KEY_LANGUAGE, 'en'));
    AppStorage.setOrCreate(STORAGE_KEY_TIME_FORMAT,
      await PreferencesHelper.getString(STORAGE_KEY_TIME_FORMAT, 'System'));
    AppStorage.setOrCreate(STORAGE_KEY_HIJRI_OFFSET,
      await PreferencesHelper.getNumber(STORAGE_KEY_HIJRI_OFFSET, 0));
    AppStorage.setOrCreate(STORAGE_KEY_HIJRI_CALENDAR_TYPE,
      await PreferencesHelper.getString(
        STORAGE_KEY_HIJRI_CALENDAR_TYPE, 'UmmAlQura'));
    AppStorage.setOrCreate(STORAGE_KEY_EVENT_PERSPECTIVE,
      await PreferencesHelper.getString(
        STORAGE_KEY_EVENT_PERSPECTIVE, 'universal'));
    AppStorage.setOrCreate(STORAGE_KEY_AUTO_SHOW_RAMADAN_VIEW,
      await PreferencesHelper.getBoolean(
        STORAGE_KEY_AUTO_SHOW_RAMADAN_VIEW, true));
    AppStorage.setOrCreate(STORAGE_KEY_SOUND_ENABLED,
      await PreferencesHelper.getBoolean(STORAGE_KEY_SOUND_ENABLED, true));
    AppStorage.setOrCreate(STORAGE_KEY_VIBRATION_ENABLED,
      await PreferencesHelper.getBoolean(STORAGE_KEY_VIBRATION_ENABLED, true));
    AppStorage.setOrCreate(STORAGE_KEY_TASBIH_SOUND,
      await PreferencesHelper.getString(STORAGE_KEY_TASBIH_SOUND, 'soft_click'));
    AppStorage.setOrCreate(STORAGE_KEY_WIZARD_COMPLETED,
      await PreferencesHelper.getBoolean(STORAGE_KEY_WIZARD_COMPLETED, false));

    AppStorage.setOrCreate(STORAGE_KEY_SHOW_ISLAMIC_EVENTS,
      await PreferencesHelper.getBoolean(
        STORAGE_KEY_SHOW_ISLAMIC_EVENTS, true));
    AppStorage.setOrCreate(STORAGE_KEY_SHOW_IMSAK_LIST,
      await PreferencesHelper.getBoolean(STORAGE_KEY_SHOW_IMSAK_LIST, true));
    AppStorage.setOrCreate(STORAGE_KEY_SHOW_FIRST_THIRD_LIST,
      await PreferencesHelper.getBoolean(
        STORAGE_KEY_SHOW_FIRST_THIRD_LIST, true));
    AppStorage.setOrCreate(STORAGE_KEY_SHOW_MIDNIGHT_LIST,
      await PreferencesHelper.getBoolean(STORAGE_KEY_SHOW_MIDNIGHT_LIST, true));
    AppStorage.setOrCreate(STORAGE_KEY_SHOW_LAST_THIRD_LIST,
      await PreferencesHelper.getBoolean(
        STORAGE_KEY_SHOW_LAST_THIRD_LIST, true));
    AppStorage.setOrCreate(STORAGE_KEY_SHOW_IMSAK_SUNPATH,
      await PreferencesHelper.getBoolean(
        STORAGE_KEY_SHOW_IMSAK_SUNPATH, true));
    AppStorage.setOrCreate(STORAGE_KEY_SHOW_FIRST_THIRD_SUNPATH,
      await PreferencesHelper.getBoolean(
        STORAGE_KEY_SHOW_FIRST_THIRD_SUNPATH, true));
    AppStorage.setOrCreate(STORAGE_KEY_SHOW_MIDNIGHT_SUNPATH,
      await PreferencesHelper.getBoolean(
        STORAGE_KEY_SHOW_MIDNIGHT_SUNPATH, true));
    AppStorage.setOrCreate(STORAGE_KEY_SHOW_LAST_THIRD_SUNPATH,
      await PreferencesHelper.getBoolean(
        STORAGE_KEY_SHOW_LAST_THIRD_SUNPATH, true));
  }

  private static bumpVersion(key: string): void {
    const prev = AppStorage.get<number>(key);
    const next = (prev === undefined ? 0 : prev) + 1;
    AppStorage.setOrCreate(key, next);
  }
}