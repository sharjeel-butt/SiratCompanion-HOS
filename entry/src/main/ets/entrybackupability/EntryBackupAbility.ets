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

/**
 * Current backup file format version.
 *
 * v1 (current — with header):
 *     #v1\t<count>\n
 *     <type>\t<key>\t<value>\n
 *     <type>\t<key>\t<value>\n
 *     ...
 *
 * v1 (legacy — v3.4.3 and earlier — no header):
 *     <type>\t<key>\t<value>\n
 *     <type>\t<key>\t<value>\n
 *     ...
 *
 * The header is a forward-compatibility marker. It records the
 * format version and the total number of data lines that follow.
 * Legacy files (no header) are still accepted and parsed with the
 * same v1 parser, but no truncation detection is possible for them
 * because the original line count is unknown.
 */
const BACKUP_FORMAT_VERSION = 1;

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
  { key: 'theme_mode_override', type: TYPE_STRING },
  { key: 'app_theme_preset', type: TYPE_STRING },
  { key: 'app_language', type: TYPE_STRING },
  { key: 'app_language_override', type: TYPE_STRING },
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

  // ---- Progress & Logs ----
  { key: 'prayer_state_map', type: TYPE_STRING },
  { key: 'ramadan_log', type: TYPE_STRING },

  // ---- Duas ----
  { key: 'dua_favorites', type: TYPE_STRING },
  { key: 'dua_bindings', type: TYPE_STRING }
];

/**
 * NOTE on `tasbihs_data`: it carries the JSON-serialized full tasbih
 * state — every tasbih, every dhikr, and up to 90 days of per-day
 * per-dhikr counts. For a heavy user this can reach 500 KB–2 MB of
 * JSON, which percent-encodes to 1.5–6 MB as a single line. This is
 * the largest single value in any backup. If backup failures are ever
 * reported for power users, this is the first item to check.
 */
const TASBIH_SPECS: PrefSpec[] = [
  { key: 'tasbihs_data', type: TYPE_STRING },
  { key: 'tasbih_active_id', type: TYPE_STRING },
  { key: 'tasbih_active_dhikr', type: TYPE_NUMBER }
];

/**
 * Backs up and restores the user's data across device migration.
 *
 * Each store is written to `<backupDir>/<storeName>.txt` in a
 * line-based format:
 *
 *   #v1\t<count>                       (header, one line)
 *   <type>\t<key>\t<value>             (one record per data line)
 *
 * Where `<type>` is one of `s` (string), `n` (number), `b` (boolean).
 * String values are percent-encoded so they can never contain a tab
 * or newline that would break the delimiter scheme.
 *
 * Legacy files (v3.4.3 and earlier) have no header. They are still
 * accepted on restore; the header is only used to detect truncation.
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

    // The backup version is logged so we have a record of what was
    // restored. (The minCompatibleVersionCode in app.json5 prevents
    // restoring from an older, incompatible version.)

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
      const encoded: string | null =
        await EntryBackupAbility.readAsString(store, spec);
      if (encoded === null) {
        // Key is absent from the store — do not write a line for it.
        // On restore, an absent key falls through to its default,
        // which matches the user's current (never-set) state.
        continue;
      }
      lines.push(spec.type + '\t' + spec.key + '\t' + encoded);
    }

    // Format v1: header declares version and total line count.
    const header: string =
      '#v' + BACKUP_FORMAT_VERSION + '\t' + lines.length;
    const content: string = lines.length > 0
      ? header + '\n' + lines.join('\n')
      : header;

    const path: string = backupDir + '/' + storeName + '.txt';
    const written: boolean =
      EntryBackupAbility.writeTextFile(path, content);

    if (written) {
      hilog.info(DOMAIN, TAG,
        'Backed up %{public}s: %{public}d entries',
        storeName, lines.length);
    } else {
      hilog.error(DOMAIN, TAG,
        'Write failed for %{public}s', storeName);
    }
  }

  /**
   * Read a key's value and percent-encode it for the file format.
   *
   * Returns:
   *   null   — the key is not present in the store (skip it)
   *   string — the encoded value; may be empty ('') if the key is
   *            present with an empty-string value
   *
   * The null vs empty-string distinction matters: an absent key must
   * be skipped on backup so restore falls back to the default. A
   * present-but-empty value must be written so the empty state
   * survives the round-trip.
   */
  private static async readAsString(
    store: preferences.Preferences, spec: PrefSpec
  ): Promise<string | null> {
    try {
      const exists: boolean = await store.has(spec.key);
      if (!exists) {
        return null;
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
      return null;
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

    // ---- Parse the header, if present ----
    const rawLines: string[] = content.split('\n');
    let startIdx = 0;
    let formatVersion = 1;
    let expectedCount = -1; // -1 = unknown (legacy file)

    if (rawLines.length > 0 && rawLines[0].startsWith('#')) {
      const headerLine = rawLines[0].trim();
      const headerParts = headerLine.split('\t');

      const versionMatch = headerParts[0].match(/^#v(\d+)$/);
      if (versionMatch) {
        formatVersion = parseInt(versionMatch[1], 10);
        if (headerParts.length >= 2) {
          const n = parseInt(headerParts[1], 10);
          if (!isNaN(n) && n >= 0) {
            expectedCount = n;
          }
        }
      } else {
        hilog.warn(DOMAIN, TAG,
          'Restore for %{public}s: unrecognized header "%{public}s"',
          storeName, headerLine);
      }
      startIdx = 1;
    }

    if (formatVersion > BACKUP_FORMAT_VERSION) {
      hilog.warn(DOMAIN, TAG,
        'Restore for %{public}s: backup is v%{public}d, parser is v%{public}d — proceeding with best effort',
        storeName, formatVersion, BACKUP_FORMAT_VERSION);
    }

    // ---- Open and clear the store ----
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

    // ---- Apply the data lines ----
    //
    // INTENTIONAL: restore applies ALL lines in the file, not just
    // those that appear in PrefSpec[]. This is what makes the backup
    // format forward- and backward-compatible across app versions:
    // a newer build's backup restores its extra keys harmlessly on
    // an older build, and an older build's backup restores cleanly
    // on a newer build (the newer build simply doesn't get its new
    // keys populated, which is fine — they default on first use).
    //
    // Do NOT change this to iterate PrefSpec[] without also bumping
    // BACKUP_FORMAT_VERSION and adding a migration in restoreStore.
    let restored = 0;
    let actualDataLines = 0;
    const presentKeys: Set<string> = new Set();

    for (let i = startIdx; i < rawLines.length; i++) {
      const line = rawLines[i];
      if (line.length === 0) {
        continue;
      }
      actualDataLines++;
      const appliedKey =
        await EntryBackupAbility.applyLine(store, line);
      if (appliedKey.length > 0) {
        restored++;
        presentKeys.add(appliedKey);
      }
    }

    await EntryBackupAbility.flushPrefs(store);

    // ---- Truncation detection ----
    //
    // If the header declared `expectedCount` data lines and we parsed
    // or applied fewer, the backup file was truncated mid-write —
    // storage full, process killed, or transfer interrupted. The
    // user's state is now partial. Log loudly so this is diagnosable.
    // We still restore what we have — a partial restore is better
    // than none.
    if (expectedCount >= 0) {
      if (actualDataLines < expectedCount) {
        hilog.warn(DOMAIN, TAG,
          'Restore for %{public}s: backup appears truncated — parsed %{public}d of %{public}d declared line(s)',
          storeName, actualDataLines, expectedCount);
      }
      if (restored < expectedCount) {
        hilog.warn(DOMAIN, TAG,
          'Restore for %{public}s: only %{public}d of %{public}d key(s) applied successfully',
          storeName, restored, expectedCount);
      }
    }

    // ---- Diagnostic: unknown keys ----
    //
    // A key that was applied but is not in this build's PrefSpec[]
    // list was written by a different app version. The value is now
    // sitting in the store harmlessly (nothing reads it), but the
    // breadcrumb is useful when a "my settings are wrong after
    // restore" report arrives.
    const specs = storeName === STORE_SETTINGS
      ? SETTINGS_SPECS : TASBIH_SPECS;
    const knownKeys: Set<string> = new Set(
      specs.map((s: PrefSpec): string => s.key)
    );
    const unknownKeys: string[] = [];
    for (const k of presentKeys) {
      if (!knownKeys.has(k)) {
        unknownKeys.push(k);
      }
    }
    if (unknownKeys.length > 0) {
      hilog.info(DOMAIN, TAG,
        'Restore for %{public}s: %{public}d key(s) present in backup but unknown to this build',
        storeName, unknownKeys.length);
      for (const k of unknownKeys) {
        hilog.info(DOMAIN, TAG, '  unknown key: %{public}s', k);
      }
    }

    hilog.info(DOMAIN, TAG,
      'Restored %{public}s: %{public}d entries',
      storeName, restored);
  }

  /**
   * Parse and apply one data line.
   *
   * @returns the key that was written, or '' on failure. Callers use
   *          the non-empty return value to track successful restores.
   */
  private static async applyLine(
    store: preferences.Preferences, line: string
  ): Promise<string> {
    const parts: string[] = line.split('\t');
    if (parts.length < 3) {
      hilog.warn(DOMAIN, TAG,
        'applyLine: malformed line (expected ≥3 fields, got %{public}d)',
        parts.length);
      return '';
    }

    const type: string = parts[0];
    const key: string = parts[1];

    // Percent-encoded string values can never contain a raw tab. If
    // one is present, the line was corrupted in transit. Reconstruct
    // the full value rather than dropping the remainder.
    if (parts.length > 3) {
      hilog.warn(DOMAIN, TAG,
        'applyLine: value for key %{public}s contains a raw tab; corruption?',
        key);
    }
    const raw: string = parts.slice(2).join('\t');

    try {
      if (type === TYPE_STRING) {
        await store.put(key, decodeURIComponent(raw));
        return key;
      }
      if (type === TYPE_NUMBER) {
        const num: number = Number(raw);
        if (Number.isNaN(num)) {
          hilog.warn(DOMAIN, TAG,
            'applyLine: invalid number for key %{public}s', key);
          return '';
        }
        await store.put(key, num);
        return key;
      }
      if (type === TYPE_BOOLEAN) {
        await store.put(key, raw === 'true');
        return key;
      }
      hilog.warn(DOMAIN, TAG,
        'applyLine: unknown type "%{public}s" for key %{public}s',
        type, key);
    } catch (err) {
      hilog.warn(DOMAIN, TAG,
        'applyLine failed for %{public}s', key);
    }
    return '';
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