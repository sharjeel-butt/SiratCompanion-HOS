import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { zlib } from '@kit.BasicServicesKit'; // Rule §C: Native modules imported at top
import { BilingualHadith, HadithDbRecord } from './HadithModels';
import { AppLogger } from '../core/AppLogger';
import { L } from '../i18n/LocalizationHelper';
import { PreferencesHelper } from '../core/PreferencesHelper';

export class HadithDbHelper {
  private static store: relationalStore.RdbStore | null = null;
  private static currentLang: string = '';

  private static sectionAliases: Record<string, string> | null = null;
  private static localizedSectionsMap: Map<string, Record<string, string>> = new Map();

  // 👇 Dynamic schema variables
  private static idCol: string = 'hadith_id';
  private static textCol: string = 'text';

  static async openDatabase(context: common.Context, lang: string): Promise<boolean> {
    if (HadithDbHelper.store !== null && HadithDbHelper.currentLang === lang) {
      return true;
    }
    HadithDbHelper.closeDatabase();

    try {
      const dirPath: string = `${context.databaseDir}/rdb/hadith_v2`;
      const dbPath: string = `${dirPath}/${lang}.db`;
      const tmpPath: string = `${dirPath}/${lang}.db.extracttmp`;

      if (!fs.accessSync(dirPath)) {
        fs.mkdirSync(dirPath, true);
      }

      // ---- M-N2: read bundle version + tracked version ----
      const bundledVersion = await HadithDbHelper.readBundledVersion(context);
      const versionKey = HadithDbHelper.versionKeyFor(lang);
      const storedVersion = await PreferencesHelper.getString(versionKey, '0');
      const versionMatches = (storedVersion === bundledVersion);

      // ---- Decide whether extraction is required ----
      let hasValidExisting: boolean = false;
      if (fs.accessSync(dbPath)) {
        const stat = fs.statSync(dbPath);
        if (stat.size > 10240) {
          hasValidExisting = true;
        }
      }

      const needsExtract: boolean = !hasValidExisting || !versionMatches;

      if (needsExtract) {
        if (hasValidExisting && !versionMatches) {
          AppLogger.info('HadithDbHelper',
            `Re-extracting ${lang}.db: bundle version ` +
              `${storedVersion} -> ${bundledVersion}`);
        } else {
          AppLogger.info('HadithDbHelper',
            `Extracting ${lang}.db.gz to sandbox...`);
        }

        const rawfilePath = `hadith/database/${lang}/hadith.db.gz`;
        const tempGzPath = `${context.cacheDir}/${lang}.db.gz`;

        try {
          // Clean any leftover temp file from a previous failed run.
          if (fs.accessSync(tmpPath)) {
            try {
              fs.unlinkSync(tmpPath);
            } catch (e) { /* ignore */
            }
          }

          // 1. Copy .gz from rawfile to cacheDir
          const rawData: Uint8Array = await context.resourceManager.getRawFileContent(rawfilePath);
          const file: fs.File =
            fs.openSync(tempGzPath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
          const buffer = new ArrayBuffer(rawData.length);
          const view = new Uint8Array(buffer);
          view.set(rawData);
          fs.writeSync(file.fd, buffer);
          fs.closeSync(file);

          // 2. Decompress .gz to a TEMP path using the GZip stream API.
          //
          // zlib.decompressFile is for .zip archives — it parses the
          // ZIP header and rejects .gz with error 900002/900003.
          // zlib.uncompressFile does not exist in HarmonyOS.
          // The GZip stream API is the correct path for .gz:
          //   createGZipSync() -> gzopen('rb') -> gzread loop -> gzclose()
          //
          // Writing to a temp path (not dbPath) ensures a mid-stream
          // failure cannot corrupt a previously-working DB.
          const gzip = zlib.createGZipSync();
          const dbFile = fs.openSync(
            tmpPath,
            fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC
          );
          try {
            await gzip.gzopen(tempGzPath, 'rb');
            const bufSize = 65536; // 64 KB chunks
            while (true) {
              const chunk = new ArrayBuffer(bufSize);
              const readLen = await gzip.gzread(chunk);
              if (readLen <= 0) {
                break;
              }
              const out = new Uint8Array(chunk, 0, readLen);
              fs.writeSync(dbFile.fd, out.buffer);
            }
          } finally {
            await gzip.gzclose().catch((e: Error) => {
              AppLogger.warn('HadithDbHelper',
                `gzclose failed for ${lang}: ${e.message}`);
            });
            fs.closeSync(dbFile);
          }

          // 3. Rule §M: Download Validation (Size) — on the temp file
          const stat = fs.statSync(tmpPath);
          if (stat.size <= 10240) {
            throw new Error(`Decompressed database too small: ${stat.size} bytes`);
          }

          // 4. Rule §M: Download Validation (Header) — on the temp file
          const headerBuffer = new ArrayBuffer(16);
          const readFile = fs.openSync(tmpPath, fs.OpenMode.READ_ONLY);
          fs.readSync(readFile.fd, headerBuffer);
          fs.closeSync(readFile);

          const headerBytes = new Uint8Array(headerBuffer);
          let headerString = '';
          for (let i = 0; i < headerBytes.length; i++) {
            headerString += String.fromCharCode(headerBytes[i]);
          }

          if (!headerString.startsWith('SQLite format 3')) {
            throw new Error('Invalid SQLite header');
          }

          // 5. Commit: replace live dbPath with validated temp file.
          if (fs.accessSync(dbPath)) {
            try {
              fs.unlinkSync(dbPath);
            } catch (e) { /* ignore */
            }
          }
          fs.renameSync(tmpPath, dbPath);

          // 6. Version persisted only on full success.
          await PreferencesHelper.setString(versionKey, bundledVersion);
          await PreferencesHelper.flushNow();
          AppLogger.info('HadithDbHelper',
            `Extracted ${lang}.db at bundle version ${bundledVersion}`);

        } catch (extractErr) {
          const e = extractErr as Error;
          AppLogger.warn('HadithDbHelper',
            `Extraction failed for ${lang}: ${e.message}`);

          // Clean temp file — live dbPath is untouched.
          if (fs.accessSync(tmpPath)) {
            try {
              fs.unlinkSync(tmpPath);
            } catch (cleanupErr) { /* ignore */
            }
          }

          if (!hasValidExisting) {
            throw e;
          }
          // Fall through: old dbPath is still valid.
          AppLogger.info('HadithDbHelper',
            `Using existing ${lang}.db (version ${storedVersion})`);
        } finally {
          // Always clean temp .gz.
          if (fs.accessSync(tempGzPath)) {
            try {
              fs.unlinkSync(tempGzPath);
            } catch (cleanupErr) { /* ignore */
            }
          }
        }
      }

      // ---- Open the DB ----
      const config: relationalStore.StoreConfig = {
        name: `${lang}.db`,
        securityLevel: relationalStore.SecurityLevel.S1,
        customDir: 'hadith_v2',
        isReadOnly: true
      };

      HadithDbHelper.store = await relationalStore.getRdbStore(context, config);
      HadithDbHelper.currentLang = lang;

      await HadithDbHelper.discoverSchema();
      await HadithDbHelper.loadMetadata(context, lang);

      AppLogger.info('HadithDbHelper',
        `Opened ${lang}.db (version ${bundledVersion})`);
      return true;

    } catch (error) {
      const err: Error = error as Error;
      AppLogger.error('HadithDbHelper', `Failed to open ${lang} db: ${err.message}`);
      HadithDbHelper.store = null;
      return false;
    }
  }

  // 👇 Dynamically find whether the DB uses 'id' or 'hadith_id'
  private static async discoverSchema(): Promise<void> {
    if (HadithDbHelper.store === null) {
      return;
    }
    try {
      const resultSet = await HadithDbHelper.store.querySql('PRAGMA table_info(hadiths)');
      while (resultSet.goToNextRow()) {
        const colName = resultSet.getString(1);
        if (colName === 'id' || colName === 'hadith_id') {
          HadithDbHelper.idCol = colName;
        } else if (colName === 'text' || colName === 'arabic_text' || colName === 'raw_text') {
          HadithDbHelper.textCol = colName;
        }
      }
      resultSet.close();
      AppLogger.info('HadithDbHelper',
        `Schema mapped: idCol=${HadithDbHelper.idCol}, textCol=${HadithDbHelper.textCol}`);
    } catch (e) {
      AppLogger.warn('HadithDbHelper', `Schema discovery failed, using defaults.`);
    }
  }

  static closeDatabase(): void {
    if (HadithDbHelper.store !== null) {
      HadithDbHelper.store.close();
      HadithDbHelper.store = null;
      HadithDbHelper.currentLang = '';
    }
  }

  private static async loadMetadata(ctx: common.Context, lang: string): Promise<void> {
    try {
      if (HadithDbHelper.sectionAliases === null) {
        const data: Uint8Array = await ctx.resourceManager.getRawFileContent('hadith/metadata/section_aliases_v2.json');
        const str: string = util.TextDecoder.create('utf-8').decodeToString(data);
        HadithDbHelper.sectionAliases = JSON.parse(str) as Record<string, string>;
      }

      // 👇 FIX: Only load from disk if not already in the Map
      if (!HadithDbHelper.localizedSectionsMap.has(lang)) {
        let langFile: string = `${lang}_sections.json`;
        try {
          const langData: Uint8Array = await ctx.resourceManager.getRawFileContent(`hadith/metadata/${langFile}`);
          const langStr: string = util.TextDecoder.create('utf-8').decodeToString(langData);
          HadithDbHelper.localizedSectionsMap.set(lang, JSON.parse(langStr) as Record<string, string>);
        } catch (e) {
          if (lang !== 'en') {
            const masterData: Uint8Array =
              await ctx.resourceManager.getRawFileContent('hadith/metadata/master_sections.json');
            const masterStr: string = util.TextDecoder.create('utf-8').decodeToString(masterData);
            HadithDbHelper.localizedSectionsMap.set(lang, JSON.parse(masterStr) as Record<string, string>);
          }
        }
      }
    } catch (error) {
      const err: Error = error as Error;
      console.warn(`[HadithDbHelper] Metadata load failed for ${lang}: ${err.message}`);
    }
  }

  private static expandCollectionAlias(baseId: string): string {
    const parts = baseId.split(':');
    if (parts.length !== 2) {
      return baseId;
    }
    const col = parts[0].toLowerCase();
    const num = parts[1];

    if (col === 'bukh') {
      return `bukhari:${num}`;
    }
    if (col === 'musl') {
      return `muslim:${num}`;
    }
    if (col === 'abud') {
      return `abudawud:${num}`;
    }
    if (col === 'tirm') {
      return `tirmidhi:${num}`;
    }
    if (col === 'nasa') {
      return `nasai:${num}`;
    }
    if (col === 'ibnm') {
      return `ibnmajah:${num}`;
    }
    if (col === 'mali') {
      return `malik:${num}`;
    }
    return baseId;
  }

  private static getIdVariants(rawId: string, lang: string): string[] {
    const variants: string[] = [];
    variants.push(rawId);

    let baseId = rawId;
    if (rawId.includes('-')) {
      baseId = rawId.substring(rawId.indexOf('-') + 1);
    }
    if (baseId !== rawId) {
      variants.push(baseId);
    }

    const expandedId = HadithDbHelper.expandCollectionAlias(baseId);
    if (expandedId !== baseId) {
      variants.push(expandedId);
    }

    let prefix = '';
    if (lang === 'ar') {
      prefix = 'ara-';
    } else if (lang === 'ur') {
      prefix = 'urd-';
    } else if (lang === 'en') {
      prefix =
        'eng-';
    } else if (lang === 'bn') {
      prefix = 'ben-';
    } else if (lang === 'tr') {
      prefix = 'tur-';
    } else if (lang ===
      'id') {
      prefix = 'ind-';
    }

    if (prefix) {
      if (!rawId.startsWith(prefix)) {
        variants.push(prefix + baseId);
      }
      if (!expandedId.startsWith(prefix) && expandedId !== baseId) {
        variants.push(prefix + expandedId);
      }
    }

    return variants;
  }

  static async getById(id: string): Promise<HadithDbRecord | null> {
    if (HadithDbHelper.store === null) {
      return null;
    }

    try {
      const predicates = new relationalStore.RdbPredicates('hadiths');
      predicates.equalTo(HadithDbHelper.idCol, id);

      const columns: string[] = [HadithDbHelper.idCol, 'collection', 'hadith_number', HadithDbHelper.textCol];
      const resultSet: relationalStore.ResultSet = await HadithDbHelper.store.query(predicates, columns);

      if (resultSet.goToFirstRow()) {
        const record: HadithDbRecord = {
          hadith_id: resultSet.getString(0),
          collection: resultSet.getString(1),
          hadith_number: resultSet.getString(2),
          text: resultSet.getString(3)
        };
        resultSet.close();
        return record;
      }
      resultSet.close();
      return null;
    } catch (error) {
      return null;
    }
  }

  static async getBilingualById(ctx: common.Context, id: string, targetLang: string): Promise<BilingualHadith | null> {
    try {
      const transVariants = HadithDbHelper.getIdVariants(id, targetLang);
      const arVariants = HadithDbHelper.getIdVariants(id, 'ar');

      // 1. Fetch Translation
      let transRecord: HadithDbRecord | null = null;
      if (targetLang !== 'ar') {
        await HadithDbHelper.openDatabase(ctx, targetLang);
        for (const v of transVariants) {
          transRecord = await HadithDbHelper.getById(v);
          if (transRecord !== null) {
            break;
          }
        }
      }

      // 2. Fetch Arabic
      let arRecord: HadithDbRecord | null = null;
      await HadithDbHelper.openDatabase(ctx, 'ar');
      for (const v of arVariants) {
        arRecord = await HadithDbHelper.getById(v);
        if (arRecord !== null) {
          break;
        }
      }

      if (arRecord === null && transRecord === null) {
        return null;
      }

      const metaSource: HadithDbRecord | null = (targetLang !== 'ar' && transRecord !== null) ? transRecord : arRecord;

      let rawCollection: string = metaSource ? metaSource.collection : '';
      let baseCol = rawCollection.toLowerCase();

      if (baseCol.includes('-')) {
        baseCol = baseCol.substring(baseCol.indexOf('-') + 1);
      }

      baseCol = HadithDbHelper.expandCollectionAlias(baseCol + ':1').split(':')[0];

      const locKey = 'collection_' + baseCol;
      const translated = L.get(locKey, targetLang);

      let localizedCollection: string;
      if (translated !== locKey) {
        localizedCollection = translated;
      } else {
        localizedCollection = baseCol.charAt(0).toUpperCase() + baseCol.slice(1);
      }

      const result: BilingualHadith = {
        id: id,
        collection: localizedCollection,
        section: '',
        section_localized: '',
        hadith_number: metaSource ? metaSource.hadith_number : '',
        arabic_text: arRecord ? arRecord.text : '',
        translated_text: (targetLang !== 'ar' && transRecord) ? transRecord.text : '',
        translated_language: targetLang
      };

      return result;
    } catch (error) {
      const err: Error = error as Error;
      AppLogger.error('HadithDbHelper', `getBilingualById failed: ${err.message}`);
      return null;
    }
  }

  static async getByCollection(collectionId: string, limit: number, offset: number): Promise<HadithDbRecord[]> {
    if (HadithDbHelper.store === null) {
      return [];
    }

    try {
      const predicates = new relationalStore.RdbPredicates('hadiths');
      predicates.like('collection', `%${collectionId}%`);
      predicates.limitAs(limit);
      predicates.offsetAs(offset);

      // 👇 Use the discovered column names
      const cols = [HadithDbHelper.idCol, 'collection', 'hadith_number', HadithDbHelper.textCol];
      const resultSet = await HadithDbHelper.store.query(predicates, cols);

      const records: HadithDbRecord[] = [];
      while (resultSet.goToNextRow()) {
        records.push({
          hadith_id: resultSet.getString(0),
          collection: resultSet.getString(1),
          hadith_number: resultSet.getString(2),
          text: resultSet.getString(3)
        });
      }
      resultSet.close();
      return records;
    } catch (error) {
      AppLogger.error('HadithDbHelper', `getByCollection failed: ${JSON.stringify(error)}`);
      return [];
    }
  }

  static async getAnyFeatured(limit: number): Promise<HadithDbRecord[]> {
    if (HadithDbHelper.store === null) {
      return [];
    }

    try {
      const predicates = new relationalStore.RdbPredicates('hadiths');
      predicates.limitAs(limit);

      const cols = [HadithDbHelper.idCol, 'collection', 'hadith_number', HadithDbHelper.textCol];
      const resultSet = await HadithDbHelper.store.query(predicates, cols);

      const records: HadithDbRecord[] = [];
      while (resultSet.goToNextRow()) {
        records.push({
          hadith_id: resultSet.getString(0),
          collection: resultSet.getString(1),
          hadith_number: resultSet.getString(2),
          text: resultSet.getString(3)
        });
      }
      resultSet.close();
      return records;
    } catch (error) {
      return [];
    }
  }

  static async searchByText(query: string, limit: number = 100): Promise<HadithDbRecord[]> {
    if (HadithDbHelper.store === null) {
      return [];
    }

    try {
      const predicates = new relationalStore.RdbPredicates('hadiths');
      predicates.like(HadithDbHelper.textCol, `%${query}%`);
      predicates.limitAs(limit);

      const cols = [HadithDbHelper.idCol, 'collection', 'hadith_number', HadithDbHelper.textCol];
      const resultSet = await HadithDbHelper.store.query(predicates, cols);

      const records: HadithDbRecord[] = [];
      while (resultSet.goToNextRow()) {
        records.push({
          hadith_id: resultSet.getString(0),
          collection: resultSet.getString(1),
          hadith_number: resultSet.getString(2),
          text: resultSet.getString(3)
        });
      }
      resultSet.close();
      return records;
    } catch (error) {
      return [];
    }
  }

  public static translateSection(rawSection: string, lang: string): string {
    if (!rawSection) {
      return '';
    }

    let canonical = rawSection;
    if (HadithDbHelper.sectionAliases && HadithDbHelper.sectionAliases[rawSection]) {
      canonical = HadithDbHelper.sectionAliases[rawSection];
    }

    // 👇 FIX: Look up the Map using the requested language
    const localizedSections = HadithDbHelper.localizedSectionsMap.get(lang);
    if (localizedSections && localizedSections[canonical]) {
      return localizedSections[canonical];
    }

    return rawSection;
  }

  static async getCollectionCount(collectionId: string): Promise<number> {
    if (HadithDbHelper.store === null) {
      return 0;
    }

    try {
      // We use LIKE because the collection column might be "urd-bukhari" or "bukhari"
      const resultSet = await HadithDbHelper.store.querySql(
        'SELECT COUNT(*) FROM hadiths WHERE collection LIKE ?',
        [`%${collectionId}%`]
      );

      let count = 0;
      if (resultSet.goToFirstRow()) {
        count = resultSet.getLong(0);
      }
      resultSet.close();
      return count;
    } catch (error) {
      console.error(`[HadithDbHelper] Count failed for ${collectionId}: ${JSON.stringify(error)}`);
      return 0;
    }
  }

  /**
   * Read the bundled hadith-data version from the rawfile manifest.
   * Returns "0" if the manifest is absent — that's the pre-4.1.0
   * behaviour, which relies only on file-size validation.
   *
   * The manifest is a plain text file containing a single integer.
   * Pipeline bumps it whenever hadith content changes; apps ship the
   * new manifest alongside the new DBs.
   */
  private static async readBundledVersion(
    context: common.Context
  ): Promise<string> {
    try {
      const data: Uint8Array = await context.resourceManager.getRawFileContent(
        'hadith/database/VERSION'
      );
      const version = util.TextDecoder.create('utf-8')
        .decodeToString(data)
        .trim();
      return version.length > 0 ? version : '0';
    } catch (e) {
      return '0';
    }
  }

  /**
   * Preference key for one language's last-extracted bundle version.
   * Per-language tracking means a language the user never opens is
   * never re-extracted — only what they actually use costs the disk
   * I/O of the re-extract.
   */
  private static versionKeyFor(lang: string): string {
    return `hadith_db_version_${lang}`;
  }
}