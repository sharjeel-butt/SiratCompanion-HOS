// entry/src/main/ets/entrybackupability/EntryBackupAbility.ets

import { hilog } from '@kit.PerformanceAnalysisKit';
import { BackupExtensionAbility, BundleVersion, fileIo as fs, ReadOptions } from '@kit.CoreFileKit';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { buffer } from '@kit.ArkTS';

const DOMAIN = 0x0000;
const TAG = 'SiratBackup';

const TYPE_STRING = 's';
const TYPE_NUMBER = 'n';
const TYPE_BOOLEAN = 'b';

const STORE_SETTINGS = 'sirat_settings';
const STORE_TASBIH = 'tasbih_prefs';

interface PrefSpec {
  key: string;
  type: string;
}

const SETTINGS_SPECS: PrefSpec[] = [
  // ---- Calculation & Location ----
  { key: 'calc_method', type: TYPE_STRING },
  { key: 'asr_rule', type: TYPE_NUMBER },
  { key: 'calc_source', type: TYPE_STRING },
  { key: 'location_mode', type: TYPE_STRING },
  { key: 'manual_lat', type: TYPE_NUMBER },
  { key: 'manual_lng', type: TYPE_NUMBER },
  { key: 'manual_refresh', type: TYPE_NUMBER },
  { key: 'manual_city', type: TYPE_STRING },
  { key: 'high_lat_rule', type: TYPE_STRING },
  { key: 'calc_rounding_method', type: TYPE_STRING },
  { key: 'calc_midnight_method', type: TYPE_STRING },
  { key: 'calc_polar_resolution', type: TYPE_STRING },
  { key: 'calc_shafaq', type: TYPE_STRING },
  { key: 'calc_custom_fajr', type: TYPE_NUMBER },
  { key: 'calc_custom_isha', type: TYPE_NUMBER },
  { key: 'calc_custom_isha_interval', type: TYPE_NUMBER },
  { key: 'offset_fajr', type: TYPE_NUMBER },
  { key: 'offset_dhuhr', type: TYPE_NUMBER },
  { key: 'offset_asr', type: TYPE_NUMBER },
  { key: 'offset_maghrib', type: TYPE_NUMBER },
  { key: 'offset_isha', type: TYPE_NUMBER },

  // ---- GPS Cache ----
  { key: 'gps_lat', type: TYPE_NUMBER },
  { key: 'gps_lng', type: TYPE_NUMBER },
  { key: 'gps_city', type: TYPE_STRING },
  { key: 'gps_refresh', type: TYPE_NUMBER },

  // ---- App Settings ----
  { key: 'theme_mode', type: TYPE_STRING },
  { key: 'app_theme_preset', type: TYPE_STRING },
  { key: 'app_language', type: TYPE_STRING },
  { key: 'time_format', type: TYPE_STRING },
  { key: 'wizard_completed', type: TYPE_BOOLEAN },
  { key: 'hijri_offset', type: TYPE_NUMBER },
  { key: 'hijri_calendar_type', type: TYPE_STRING },
  { key: 'event_perspective', type: TYPE_STRING },
  { key: 'auto_show_ramadan_view', type: TYPE_BOOLEAN },
  { key: 'show_islamic_events', type: TYPE_BOOLEAN },

  // ---- Extra Timings (Legacy & Current) ----
  { key: 'show_extra_timings', type: TYPE_BOOLEAN },
  { key: 'show_extra_timings_list', type: TYPE_BOOLEAN },
  { key: 'show_extra_timings_sunpath', type: TYPE_BOOLEAN },
  { key: 'show_imsak', type: TYPE_BOOLEAN },
  { key: 'show_first_third', type: TYPE_BOOLEAN },
  { key: 'show_midnight', type: TYPE_BOOLEAN },
  { key: 'show_last_third', type: TYPE_BOOLEAN },
  { key: 'show_imsak_list', type: TYPE_BOOLEAN },
  { key: 'show_first_third_list', type: TYPE_BOOLEAN },
  { key: 'show_midnight_list', type: TYPE_BOOLEAN },
  { key: 'show_last_third_list', type: TYPE_BOOLEAN },
  { key: 'show_imsak_sunpath', type: TYPE_BOOLEAN },
  { key: 'show_first_third_sunpath', type: TYPE_BOOLEAN },
  { key: 'show_midnight_sunpath', type: TYPE_BOOLEAN },
  { key: 'show_last_third_sunpath', type: TYPE_BOOLEAN },

  // ---- Notifications ----
  { key: 'notif_master_enabled', type: TYPE_BOOLEAN },
  { key: 'notif_before_minutes', type: TYPE_NUMBER },
  { key: 'notif_fajr', type: TYPE_BOOLEAN },
  { key: 'notif_dhuhr', type: TYPE_BOOLEAN },
  { key: 'notif_asr', type: TYPE_BOOLEAN },
  { key: 'notif_maghrib', type: TYPE_BOOLEAN },
  { key: 'notif_isha', type: TYPE_BOOLEAN },

  // ---- Sound & Haptics ----
  { key: 'vibration_enabled', type: TYPE_BOOLEAN },
  { key: 'sound_enabled', type: TYPE_BOOLEAN },
  { key: 'tasbih_sound', type: TYPE_STRING },
  { key: 'tasbih_render_style', type: TYPE_STRING },
  { key: 'tasbih_theme_preset', type: TYPE_STRING },

  // ---- Prayer & Fasting Progress (CRITICAL) ----
  { key: 'prayer_state_map', type: TYPE_STRING },
  { key: 'fasting_state_map', type: TYPE_STRING },
  { key: 'qada_done_count', type: TYPE_NUMBER },
  { key: 'taraweeh_state_map', type: TYPE_STRING }
];

const TASBIH_SPECS: PrefSpec[] = [
  { key: 'tasbihs_data', type: TYPE_STRING },
  { key: 'tasbih_active_id', type: TYPE_STRING },
  { key: 'tasbih_active_dhikr', type: TYPE_NUMBER }
];

/**
 * Backs up and restores the user's data across device migration.
 *
 * Each store is written to `<backupDir>/<storeName>.txt` in a
 * line-based format. One record per line:
 *   <type>\t<key>\t<value>
 */
export default class EntryBackupAbility extends BackupExtensionAbility {
  async onBackup(): Promise<void> {
    hilog.info(DOMAIN, TAG, 'onBackup start');
    const backupDir: string = this.safeBackupDir();
    if (backupDir.length === 0) {
      hilog.error(DOMAIN, TAG, 'backupDir unavailable');
      return;
    }
    await this.backupStore(STORE_SETTINGS, SETTINGS_SPECS, backupDir);
    await this.backupStore(STORE_TASBIH, TASBIH_SPECS, backupDir);
    hilog.info(DOMAIN, TAG, 'onBackup complete');
  }

  async onRestore(bundleVersion: BundleVersion): Promise<void> {
    hilog.info(DOMAIN, TAG,
      'onRestore start: %{public}s', JSON.stringify(bundleVersion));

    const backupDir: string = this.safeBackupDir();
    if (backupDir.length === 0) {
      hilog.error(DOMAIN, TAG, 'backupDir unavailable');
      return;
    }
    await this.restoreStore(STORE_SETTINGS, backupDir);
    await this.restoreStore(STORE_TASBIH, backupDir);
    hilog.info(DOMAIN, TAG, 'onRestore complete');
  }

  // ============================================================
  // BACKUP
  // ============================================================

  private async backupStore(
    storeName: string, specs: PrefSpec[], backupDir: string
  ): Promise<void> {
    const store = await EntryBackupAbility.openPrefs(
      this.context, storeName
    );
    if (store === null) {
      hilog.warn(DOMAIN, TAG,
        'Cannot open %{public}s for backup', storeName);
      return;
    }

    const lines: string[] = [];
    for (const spec of specs) {
      const encoded: string =
        await EntryBackupAbility.readAsString(store, spec);
      if (encoded.length === 0) {
        continue;
      }
      lines.push(spec.type + '\t' + spec.key + '\t' + encoded);
    }

    const path: string = backupDir + '/' + storeName + '.txt';
    const written: boolean =
      EntryBackupAbility.writeTextFile(path, lines.join('\n'));

    if (written) {
      hilog.info(DOMAIN, TAG,
        'Backed up %{public}s: %{public}d entries',
        storeName, lines.length);
    } else {
      hilog.error(DOMAIN, TAG,
        'Write failed for %{public}s', storeName);
    }
  }

  private static async readAsString(
    store: preferences.Preferences, spec: PrefSpec
  ): Promise<string> {
    try {
      const exists: boolean = await store.has(spec.key);
      if (!exists) {
        return '';
      }
      if (spec.type === TYPE_STRING) {
        const v = await store.get(spec.key, '');
        return encodeURIComponent(String(v));
      }
      if (spec.type === TYPE_NUMBER) {
        const v = await store.get(spec.key, 0);
        return String(v);
      }
      const v = await store.get(spec.key, false);
      return String(v);
    } catch (err) {
      hilog.warn(DOMAIN, TAG,
        'read failed for %{public}s', spec.key);
      return '';
    }
  }

  // ============================================================
  // RESTORE
  // ============================================================

  private async restoreStore(
    storeName: string, backupDir: string
  ): Promise<void> {
    const path: string = backupDir + '/' + storeName + '.txt';
    const content: string = EntryBackupAbility.readTextFile(path);
    if (content.length === 0) {
      hilog.info(DOMAIN, TAG,
        'No backup content for %{public}s', storeName);
      return;
    }

    const store = await EntryBackupAbility.openPrefs(
      this.context, storeName
    );
    if (store === null) {
      hilog.error(DOMAIN, TAG,
        'Cannot open %{public}s for restore', storeName);
      return;
    }

    const cleared: boolean =
      await EntryBackupAbility.clearPrefs(store);
    if (!cleared) {
      hilog.warn(DOMAIN, TAG,
        'clear failed for %{public}s; restoring anyway', storeName);
    }

    const lines: string[] = content.split('\n');
    let restored: number = 0;
    for (const line of lines) {
      if (line.length === 0) {
        continue;
      }
      const ok: boolean =
        await EntryBackupAbility.applyLine(store, line);
      if (ok) {
        restored++;
      }
    }

    await EntryBackupAbility.flushPrefs(store);

    hilog.info(DOMAIN, TAG,
      'Restored %{public}s: %{public}d entries',
      storeName, restored);
  }

  private static async applyLine(
    store: preferences.Preferences, line: string
  ): Promise<boolean> {
    const parts: string[] = line.split('\t');
    if (parts.length < 3) {
      return false;
    }
    const type: string = parts[0];
    const key: string = parts[1];
    const raw: string = parts[2];

    try {
      if (type === TYPE_STRING) {
        await store.put(key, decodeURIComponent(raw));
        return true;
      }
      if (type === TYPE_NUMBER) {
        const num: number = Number(raw);
        if (Number.isNaN(num)) {
          return false;
        }
        await store.put(key, num);
        return true;
      }
      if (type === TYPE_BOOLEAN) {
        await store.put(key, raw === 'true');
        return true;
      }
    } catch (err) {
      hilog.warn(DOMAIN, TAG,
        'applyLine failed for %{public}s', key);
    }
    return false;
  }

  // ============================================================
  // GUARDED WRAPPERS
  // ============================================================

  private safeBackupDir(): string {
    try {
      return this.context.backupDir;
    } catch (err) {
      return '';
    }
  }

  private static async openPrefs(
    context: common.Context, storeName: string
  ): Promise<preferences.Preferences | null> {
    try {
      return await preferences.getPreferences(context, storeName);
    } catch (err) {
      return null;
    }
  }

  private static async clearPrefs(
    store: preferences.Preferences
  ): Promise<boolean> {
    try {
      await store.clear();
      return true;
    } catch (err) {
      return false;
    }
  }

  private static async flushPrefs(
    store: preferences.Preferences
  ): Promise<boolean> {
    try {
      await store.flush();
      return true;
    } catch (err) {
      return false;
    }
  }

  private static writeTextFile(path: string, content: string): boolean {
    let file: fs.File | null = null;
    try {
      file = fs.openSync(
        path,
        fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC
      );
    } catch (err) {
      return false;
    }

    try {
      fs.writeSync(file.fd, content);
    } catch (err) {
      EntryBackupAbility.closeFile(file);
      return false;
    }

    return EntryBackupAbility.closeFile(file);
  }

  private static readTextFile(path: string): string {
    let stat: fs.Stat;
    try {
      stat = fs.statSync(path);
    } catch (err) {
      return '';
    }
    if (stat.size === 0) {
      return '';
    }

    let file: fs.File | null = null;
    try {
      file = fs.openSync(path, fs.OpenMode.READ_ONLY);
    } catch (err) {
      return '';
    }

    let text: string = '';
    try {
      const buf = new ArrayBuffer(stat.size);
      const opts: ReadOptions = { offset: 0, length: stat.size };
      const bytesRead: number = fs.readSync(file.fd, buf, opts);
      const u8 = new Uint8Array(buf, 0, bytesRead);
      text = buffer.from(u8).toString('utf8');
    } catch (err) {
      text = '';
    }

    EntryBackupAbility.closeFile(file);
    return text;
  }

  private static closeFile(file: fs.File): boolean {
    try {
      fs.closeSync(file);
      return true;
    } catch (err) {
      return false;
    }
  }
}