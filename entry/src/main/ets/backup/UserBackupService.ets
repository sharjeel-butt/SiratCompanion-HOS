// entry/src/main/ets/utils/UserBackupService.ets

import { fileIo as fs, picker, ReadOptions } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { buffer } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { PreferencesHelper } from '../core/PreferencesHelper';
import { PrayerManager } from '../prayer/PrayerManager';
import { TasbihStorage } from '../tasbih/TasbihStorage';
import { TasbihManager } from '../tasbih/TasbihManager';
import { RamadanStorage } from '../ramadan/RamadanStorage';
import { CustomEventStorage } from '../hijricalendar/CustomEventStorage';
import { CustomEventNotifier } from '../hijricalendar/CustomEventNotifier';
import { AppLogger } from '../core/AppLogger';
import {
  STORAGE_KEY_APP_FOREGROUND_TICK,
  STORAGE_KEY_APP_THEME,
  STORAGE_KEY_AUTO_SHOW_RAMADAN_VIEW,
  STORAGE_KEY_CALC_SETTINGS_VERSION,
  STORAGE_KEY_CUSTOM_EVENTS_VERSION,
  STORAGE_KEY_DUA_BINDINGS_VERSION,
  STORAGE_KEY_EVENT_PERSPECTIVE,
  STORAGE_KEY_EVENT_SETTINGS_VERSION,
  STORAGE_KEY_HIJRI_CALENDAR_TYPE,
  STORAGE_KEY_HIJRI_CALENDAR_VERSION,
  STORAGE_KEY_HIJRI_OFFSET,
  STORAGE_KEY_LANGUAGE,
  STORAGE_KEY_LANGUAGE_OVERRIDE,
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
  STORAGE_KEY_THEME_OVERRIDE,
  STORAGE_KEY_TIME_FORMAT,
  STORAGE_KEY_VIBRATION_ENABLED,
  STORAGE_KEY_WIZARD_COMPLETED
} from '../core/StorageKeys';
import { SettingsHelper } from '../settings/SettingsHelper';
import { DuaService } from '../duas/DuaService';

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
 * Structured data (`prayer_state_map`, `tasbihs_data`, `ramadan_log`)
 * is stored as a JSON-in-string and therefore also lands here as `string`.
 */
type BackupValue = string | number | boolean;

type PrefType = 'string' | 'number' | 'boolean';

interface PrefSpec {
  key: string;
  type: PrefType;
  defaultValue: BackupValue;
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
  { key: 'calc_method', type: 'string', defaultValue: 'Karachi' },
  { key: 'asr_rule', type: 'number', defaultValue: 1 }, // 1 = STANDARD
  { key: 'calc_source', type: 'string', defaultValue: 'Local' },
  { key: 'location_mode', type: 'string', defaultValue: 'GPS' },
  { key: 'manual_lat', type: 'number', defaultValue: 0 },
  { key: 'manual_lng', type: 'number', defaultValue: 0 },
  { key: 'manual_refresh', type: 'number', defaultValue: 0 },
  { key: 'manual_city', type: 'string', defaultValue: '' },
  { key: 'high_lat_rule', type: 'string', defaultValue: 'None' },
  { key: 'calc_rounding_method', type: 'string', defaultValue: 'Nearest' },
  { key: 'calc_midnight_method', type: 'string', defaultValue: 'Standard' },
  { key: 'calc_polar_resolution', type: 'string', defaultValue: 'Unresolved' },
  { key: 'calc_shafaq', type: 'string', defaultValue: 'General' },
  { key: 'offset_fajr', type: 'number', defaultValue: 0 },
  { key: 'offset_dhuhr', type: 'number', defaultValue: 0 },
  { key: 'offset_asr', type: 'number', defaultValue: 0 },
  { key: 'offset_maghrib', type: 'number', defaultValue: 0 },
  { key: 'offset_isha', type: 'number', defaultValue: 0 },

  // ---- GPS Cache ----
  { key: 'gps_lat', type: 'number', defaultValue: 0 },
  { key: 'gps_lng', type: 'number', defaultValue: 0 },
  { key: 'gps_city', type: 'string', defaultValue: '' },
  { key: 'gps_refresh', type: 'number', defaultValue: 0 },

  // ---- App Settings ----
  { key: 'theme_mode', type: 'string', defaultValue: 'System' },
  { key: 'theme_mode_override', type: 'string', defaultValue: 'System' },
  { key: 'app_theme_preset', type: 'string', defaultValue: 'Sirat' },
  { key: 'app_language', type: 'string', defaultValue: 'en' },
  { key: 'app_language_override', type: 'string', defaultValue: 'system' },
  { key: 'time_format', type: 'string', defaultValue: 'System' },
  { key: 'wizard_completed', type: 'boolean', defaultValue: false },
  { key: 'hijri_offset', type: 'number', defaultValue: 0 },
  { key: 'hijri_calendar_type', type: 'string', defaultValue: 'UmmAlQura' },
  { key: 'event_perspective', type: 'string', defaultValue: 'universal' },
  { key: 'auto_show_ramadan_view', type: 'boolean', defaultValue: true },
  { key: 'show_islamic_events', type: 'boolean', defaultValue: true },

  // ---- Extra Timings (Legacy & Current) ----
  { key: 'show_extra_timings', type: 'boolean', defaultValue: true },
  { key: 'show_extra_timings_list', type: 'boolean', defaultValue: true },
  { key: 'show_extra_timings_sunpath', type: 'boolean', defaultValue: true },
  { key: 'show_imsak', type: 'boolean', defaultValue: true },
  { key: 'show_first_third', type: 'boolean', defaultValue: true },
  { key: 'show_midnight', type: 'boolean', defaultValue: true },
  { key: 'show_last_third', type: 'boolean', defaultValue: true },
  { key: 'show_imsak_list', type: 'boolean', defaultValue: true },
  { key: 'show_first_third_list', type: 'boolean', defaultValue: true },
  { key: 'show_midnight_list', type: 'boolean', defaultValue: true },
  { key: 'show_last_third_list', type: 'boolean', defaultValue: true },
  { key: 'show_imsak_sunpath', type: 'boolean', defaultValue: true },
  { key: 'show_first_third_sunpath', type: 'boolean', defaultValue: true },
  { key: 'show_midnight_sunpath', type: 'boolean', defaultValue: true },
  { key: 'show_last_third_sunpath', type: 'boolean', defaultValue: true },

  // ---- Notifications ----
  { key: 'notif_master_enabled', type: 'boolean', defaultValue: false },
  { key: 'notif_before_minutes', type: 'number', defaultValue: 10 },
  { key: 'notif_fajr', type: 'boolean', defaultValue: true },
  { key: 'notif_dhuhr', type: 'boolean', defaultValue: true },
  { key: 'notif_asr', type: 'boolean', defaultValue: true },
  { key: 'notif_maghrib', type: 'boolean', defaultValue: true },
  { key: 'notif_isha', type: 'boolean', defaultValue: true },

  // ---- Sound & Haptics ----
  { key: 'vibration_enabled', type: 'boolean', defaultValue: true },
  { key: 'sound_enabled', type: 'boolean', defaultValue: true },
  { key: 'tasbih_sound', type: 'string', defaultValue: 'soft_click' },
  { key: 'tasbih_render_style', type: 'string', defaultValue: 'premium' },
  { key: 'tasbih_theme_preset', type: 'string', defaultValue: 'amber' },

  // ---- Progress & Logs ----
  { key: 'prayer_state_map', type: 'string', defaultValue: '{}' },
  { key: 'ramadan_log', type: 'string', defaultValue: '{"years":[]}' },

  // ---- Duas ----
  { key: 'dua_favorites', type: 'string', defaultValue: '[]' },
  { key: 'dua_bindings', type: 'string', defaultValue: '{}' },

  // ---- Custom Calendar Events ----
  { key: 'custom_events', type: 'string', defaultValue: '[]' },

  // ---- Quran & Prayer Prompts ----
  { key: 'active_quran_script', type: 'string', defaultValue: 'indopak' },
  { key: 'dismissed_prayers', type: 'string', defaultValue: '[]' },

  // ---- Custom Mosques ----
  { key: 'custom_mosques_data', type: 'string', defaultValue: '[]' }
];

const TASBIH_SPECS: PrefSpec[] = [
  { key: 'tasbihs_data', type: 'string', defaultValue: '[]' },
  { key: 'tasbih_active_id', type: 'string', defaultValue: '' },
  { key: 'tasbih_active_dhikr', type: 'number', defaultValue: 0 }
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
      const backup = await UserBackupService.buildBackupObject(context, appVersion);
      const json = JSON.stringify(backup, null, 2);

      const uri = await UserBackupService.pickSaveLocation(context, backup);
      if (uri.length === 0) {
        return { ok: false, message: 'cancelled' };
      }

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

  static async restoreFromFile(
    context: common.UIAbilityContext
  ): Promise<RestoreResult> {
    try {
      const uri = await UserBackupService.pickOpenLocation(context);
      if (uri.length === 0) {
        return { ok: false, message: 'cancelled' };
      }

      const content = UserBackupService.readTextFromUri(uri);
      if (content.length === 0) {
        return { ok: false, message: 'read_failed' };
      }

      let backup: BackupFileShape;
      try {
        backup = JSON.parse(content) as BackupFileShape;
      } catch {
        return { ok: false, message: 'invalid_json' };
      }

      const validation = UserBackupService.validateBackup(backup);
      if (!validation.ok) {
        return { ok: false, message: validation.message };
      }

      await UserBackupService.applyBackup(context, backup);
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
      const datePart = backup.createdAt.substring(0, 10);
      options.newFileNames = [`SiratBackup_${datePart}.json`];
      const uris = await documentPicker.save(options);
      if (!uris || uris.length === 0) {
        return '';
      }
      return uris[0];
    } catch (err) {
      AppLogger.info('UserBackupService',
        'save picker dismissed by user or unavailable');
      return '';
    }
  }

  // ============================================================
  // RESTORE
  // ============================================================

  private static writeTextToUri(uri: string, content: string): boolean {
    let file: fs.File | null = null;
    try {
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
      const bytesRead: number = fs.readSync(file.fd, buf, opts);
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
  }

  private static async applyStore(
    context: common.UIAbilityContext,
    storeName: string,
    data: Record<string, BackupValue>,
    specs: PrefSpec[]
  ): Promise<void> {
    const store = await preferences.getPreferences(context, storeName);
    await store.clear();

    for (const spec of specs) {
      const value: BackupValue | undefined = data[spec.key];

      // FIX: If the key is missing from the backup (e.g. it's from an older version),
      // apply the default value instead of leaving it wiped.
      let finalValue = value;
      if (finalValue === undefined) {
        finalValue = spec.defaultValue;
      }

      try {
        if (spec.type === 'string' && typeof finalValue === 'string') {
          await store.put(spec.key, finalValue);
        } else if (spec.type === 'number' && typeof finalValue === 'number') {
          await store.put(spec.key, finalValue);
        } else if (spec.type === 'boolean' && typeof finalValue === 'boolean') {
          await store.put(spec.key, finalValue);
        }
      } catch (err) { /* ... */
      }
    }
    await store.flush();
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

    // 2. RamadanStorage.doLoad() runs schema migrations inline.
    await RamadanStorage.load();

    // 3. Invalidate the in-memory Dua cache so restored favorites
    //    and bindings take effect immediately.
    DuaService.invalidateCache();

    // 4. Re-seed AppStorage from the restored preferences.
    await UserBackupService.seedAppStorageFromPrefs();

    // 5. Bump every version counter — triggers @Watch on every
    //    subscribed page.
    UserBackupService.bumpVersion(STORAGE_KEY_PRAYER_STATE_VERSION);
    UserBackupService.bumpVersion(STORAGE_KEY_CALC_SETTINGS_VERSION);
    UserBackupService.bumpVersion(STORAGE_KEY_EVENT_SETTINGS_VERSION);
    UserBackupService.bumpVersion(STORAGE_KEY_HIJRI_CALENDAR_VERSION);
    UserBackupService.bumpVersion(STORAGE_KEY_LOCATION_VERSION);
    UserBackupService.bumpVersion(STORAGE_KEY_TASBIH_STATE_VERSION);
    UserBackupService.bumpVersion(STORAGE_KEY_RAMADAN_STATE_VERSION);
    UserBackupService.bumpVersion(STORAGE_KEY_APP_FOREGROUND_TICK);
    UserBackupService.bumpVersion(STORAGE_KEY_DUA_BINDINGS_VERSION);
    UserBackupService.bumpVersion(STORAGE_KEY_CUSTOM_EVENTS_VERSION);

    // 6. Reschedule custom event notifications (unchanged) ...
    try {
      const customEvents = await CustomEventStorage.load();
      if (customEvents.length > 0) {
        const hijriOffset = await SettingsHelper.getHijriOffset();
        await CustomEventNotifier.reschedule(customEvents, hijriOffset);
        AppLogger.info('UserBackupService',
          `Rescheduled ${customEvents.length} custom event notification(s)`);
      }
    } catch (e) {
      AppLogger.warn('UserBackupService',
        `Custom event reschedule after restore failed: ${(e as Error).message}`);
    }
  }

  private static async seedAppStorageFromPrefs(): Promise<void> {
    AppStorage.setOrCreate(STORAGE_KEY_THEME_MODE,
      await PreferencesHelper.getString(STORAGE_KEY_THEME_MODE, 'System'));

    AppStorage.setOrCreate(STORAGE_KEY_THEME_OVERRIDE,
      await PreferencesHelper.getString(STORAGE_KEY_THEME_OVERRIDE, 'System'));

    AppStorage.setOrCreate(STORAGE_KEY_APP_THEME,
      await PreferencesHelper.getString(STORAGE_KEY_APP_THEME, 'Sirat'));

    AppStorage.setOrCreate(STORAGE_KEY_LANGUAGE,
      await PreferencesHelper.getString(STORAGE_KEY_LANGUAGE, 'en'));

    AppStorage.setOrCreate(STORAGE_KEY_LANGUAGE_OVERRIDE,
      await PreferencesHelper.getString(STORAGE_KEY_LANGUAGE_OVERRIDE, 'system'));

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

    AppStorage.setOrCreate('active_quran_script',
      await PreferencesHelper.getString('active_quran_script', 'indopak'));

    AppStorage.setOrCreate('dismissed_prayers',
      await PreferencesHelper.getString('dismissed_prayers', '[]'));

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

    AppStorage.setOrCreate(STORAGE_KEY_CUSTOM_EVENTS_VERSION, 0);
  }

  private static bumpVersion(key: string): void {
    const prev = AppStorage.get<number>(key);
    const next = (prev === undefined ? 0 : prev) + 1;
    AppStorage.setOrCreate(key, next);
  }
}