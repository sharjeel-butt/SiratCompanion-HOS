// entry/src/main/ets/bootstrap/BundleBootstrap.ets

import { common } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { zlib } from '@kit.BasicServicesKit';
import { relationalStore } from '@kit.ArkData';
import { PreferencesHelper } from '../core/util/PreferencesHelper';
import { AppLogger } from '../core/app/AppLogger';
import { RawPaths } from '../core/common/RawPaths';
import {
  STORAGE_KEY_CORE_DB_VERSION, STORAGE_KEY_QURAN_DB_VERSION
} from '../core/common/StorageKeys';

/**
 * Eagerly extracts core.db and quran.db from rawfile on first launch
 * after install or version bump. Per-language hadith DBs stay lazy
 * in HadithDbHelper.openDatabase().
 *
 * Uses the GZip stream API from @kit.BasicServicesKit — the zip-file
 * decompressor (zlib.decompressFile) is for .zip archives and
 * rejects .gz files with BusinessError 900002.
 *
 * Atomic pattern: temp file -> validate header + size -> rename.
 * A failed extraction never corrupts a previously-working DB.
 */
export class BundleBootstrap {
  static async init(context: common.Context): Promise<void> {
    try {
      await BundleBootstrap.extractIfNeeded(context, RawPaths.CORE_DB, 'core/core.db', STORAGE_KEY_CORE_DB_VERSION,
        RawPaths.CORE_VERSION);
      await BundleBootstrap.extractIfNeeded(context, RawPaths.QURAN_DB, 'quran/quran.db', STORAGE_KEY_QURAN_DB_VERSION,
        RawPaths.QURAN_VERSION);
    } catch (err) {
      const e: Error = err as Error;
      AppLogger.warn('BundleBootstrap', `bootstrap failed: ${e.message}`);
    }
  }

  private static async readVersion(context: common.Context, versionFile: string): Promise<string> {
    try {
      const data: Uint8Array = await context.resourceManager.getRawFileContent(versionFile);
      const text: string = util.TextDecoder.create('utf-8').decodeToString(data).trim();
      return text.length > 0 ? text : '0';
    } catch (err) {
      return '0';
    }
  }

  private static async extractIfNeeded(context: common.Context, rawfilePath: string, sandboxRelative: string,
    versionKey: string, versionFile: string): Promise<void> {
    const bundledVersion: string = await BundleBootstrap.readVersion(context, versionFile);
    const storedVersion: string = await PreferencesHelper.getString(versionKey, '0');

    const dirName: string = sandboxRelative.split('/')[0];
    const dirPath: string = `${context.databaseDir}/rdb/${dirName}`;
    const dbPath: string = `${context.databaseDir}/rdb/${sandboxRelative}`;
    const tmpPath: string = `${dbPath}.extracttmp`;
    const tempGzPath: string = `${context.cacheDir}/${sandboxRelative.replace(/\//g, '_')}.gz`;

    if (!fs.accessSync(dirPath)) {
      fs.mkdirSync(dirPath, true);
    }

    let hasValidExisting: boolean = false;
    if (fs.accessSync(dbPath)) {
      const stat: fs.Stat = fs.statSync(dbPath);
      if (stat.size > 10240) {
        hasValidExisting = true;
      }
    }

    const versionMatches: boolean = (storedVersion === bundledVersion);
    const needsExtract: boolean = !hasValidExisting || !versionMatches;
    if (!needsExtract) {
      return;
    }

    AppLogger.info('BundleBootstrap', `Extracting ${sandboxRelative} (v${storedVersion} -> v${bundledVersion})`);

    try { // Clean any leftover temp file from a previous failed run.
      if (fs.accessSync(tmpPath)) {
        try {
          fs.unlinkSync(tmpPath);
        } catch (cleanupErr) { // Best-effort; not fatal.
        }
      }

      // 1. Copy .gz to cache
      const rawData: Uint8Array = await context.resourceManager.getRawFileContent(rawfilePath);
      const gzFile: fs.File = fs.openSync(tempGzPath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
      const gzBuffer: ArrayBuffer = new ArrayBuffer(rawData.length);
      new Uint8Array(gzBuffer).set(rawData);
      fs.writeSync(gzFile.fd, gzBuffer);
      fs.closeSync(gzFile);

      // 2. Decompress via GZip stream
      const gzip: zlib.GZip = zlib.createGZipSync();
      const dbFile: fs.File = fs.openSync(tmpPath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
      try {
        await gzip.gzopen(tempGzPath, 'rb');
        const CHUNK: number = 65536;
        while (true) {
          const chunk: ArrayBuffer = new ArrayBuffer(CHUNK);
          const readLen: number = await gzip.gzread(chunk);
          if (readLen <= 0) {
            break;
          }
          const out: ArrayBuffer = new ArrayBuffer(readLen);
          new Uint8Array(out).set(new Uint8Array(chunk, 0, readLen));
          fs.writeSync(dbFile.fd, out);
        }
      } finally {
        try {
          await gzip.gzclose();
        } catch (closeErr) {
          const ce: Error = closeErr as Error;
          AppLogger.warn('BundleBootstrap', `gzclose: ${ce.message}`);
        }
        fs.closeSync(dbFile);
      }

      // 3. Validate size
      const stat: fs.Stat = fs.statSync(tmpPath);
      if (stat.size <= 10240) {
        throw new Error(`Decompressed db too small: ${stat.size} bytes`);
      }

      // 4. Validate SQLite header
      const headerBuffer: ArrayBuffer = new ArrayBuffer(16);
      const readFile: fs.File = fs.openSync(tmpPath, fs.OpenMode.READ_ONLY);
      fs.readSync(readFile.fd, headerBuffer);
      fs.closeSync(readFile);

      const headerBytes: Uint8Array = new Uint8Array(headerBuffer);
      let headerString: string = '';
      for (let i: number = 0; i < headerBytes.length; i++) {
        headerString += String.fromCharCode(headerBytes[i]);
      }
      if (!headerString.startsWith('SQLite format 3')) {
        throw new Error('Invalid SQLite header');
      }

      // 5. Atomic commit
      if (fs.accessSync(dbPath)) {
        try {
          fs.unlinkSync(dbPath);
        } catch (unlinkErr) { // ignore — best-effort
        }
      }
      fs.renameSync(tmpPath, dbPath);

      // 6. Persist version
      await PreferencesHelper.setString(versionKey, bundledVersion);
      await PreferencesHelper.flushNow();
      AppLogger.info('BundleBootstrap', `Extracted ${sandboxRelative} at v${bundledVersion}`);

      // 7. Post-extraction sanity check (dev-only, non-fatal)
      if (sandboxRelative === 'core/core.db') {
        await BundleBootstrap.logCoreCounts(context);
      }
    } catch (err) {
      const e: Error = err as Error;
      AppLogger.warn('BundleBootstrap', `Extraction failed for ${sandboxRelative}: ${e.message}`);

      // Clean the temp file — live dbPath is untouched.
      if (fs.accessSync(tmpPath)) {
        try {
          fs.unlinkSync(tmpPath);
        } catch (cleanupErr) { // ignore
        }
      }

      if (!hasValidExisting) {
        throw e; // e is typed Error — passes arkts-limited-throw
      }
      AppLogger.info('BundleBootstrap', `Using existing ${sandboxRelative} (v${storedVersion})`);
    } finally {
      if (fs.accessSync(tempGzPath)) {
        try {
          fs.unlinkSync(tempGzPath);
        } catch (cleanupErr) { // ignore
        }
      }
    }
  }

  private static async logCoreCounts(context: common.Context): Promise<void> {
    try {
      const config: relationalStore.StoreConfig = {
        name: 'core.db',
        securityLevel: relationalStore.SecurityLevel.S1,
        customDir: 'core',
        isReadOnly: true
      };
      const store: relationalStore.RdbStore = await relationalStore.getRdbStore(context, config);
      const rs: relationalStore.ResultSet = await store.querySql(
        'SELECT (SELECT COUNT(*) FROM hadiths) AS h, ' + '(SELECT COUNT(*) FROM narrators) AS n, ' +
          '(SELECT COUNT(*) FROM hadith_narrators) AS l, ' + '(SELECT COUNT(*) FROM hadith_gradings) AS g');
      if (rs.goToFirstRow()) {
        AppLogger.info('BundleBootstrap', `core.db counts: hadiths=${rs.getLong(0)} narrators=${rs.getLong(1)} ` +
          `links=${rs.getLong(2)} gradings=${rs.getLong(3)}`);
      }
      rs.close();
      store.close();
    } catch (err) { // Silent — dev diagnostic only
      const e: Error = err as Error;
      AppLogger.info('BundleBootstrap', `counts check skipped: ${e.message}`);
    }
  }
}