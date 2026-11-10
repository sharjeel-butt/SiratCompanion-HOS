import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';

export class MosqueDbHelper {
  private static store: relationalStore.RdbStore | null = null;
  private static currentCountry: string = '';

  static async openDatabase(context: common.Context, countryCode: string): Promise<boolean> {
    if (MosqueDbHelper.store !== null && MosqueDbHelper.currentCountry === countryCode) {
      return true;
    }

    MosqueDbHelper.closeDatabase();

    try {
      const dbPath = `${countryCode}.db`;
      const config: relationalStore.StoreConfig = {
        name: dbPath,
        securityLevel: relationalStore.SecurityLevel.S1,
        customDir: 'mosques',
        isReadOnly: true // Prevents SQLite from modifying the downloaded file
      };

      MosqueDbHelper.store = await relationalStore.getRdbStore(context, config);
      MosqueDbHelper.currentCountry = countryCode;
      return true;
    } catch (err) {
      console.error(`[MosqueDbHelper] Failed to open ${countryCode}.db: ${JSON.stringify(err)}`);
      MosqueDbHelper.store = null;
      MosqueDbHelper.currentCountry = '';
      return false;
    }
  }

  static closeDatabase(): void {
    if (MosqueDbHelper.store !== null) {
      MosqueDbHelper.store.close();
      MosqueDbHelper.store = null;
      MosqueDbHelper.currentCountry = '';
    }
  }

  static getStore(): relationalStore.RdbStore | null {
    return MosqueDbHelper.store;
  }

  static isDownloaded(context: common.Context, countryCode: string): boolean {
    // ✅ CORRECTED PATH
    const path = `${context.databaseDir}/rdb/mosques/${countryCode}.db`;
    try {
      if (!fs.accessSync(path)) {
        return false;
      }

      const stat = fs.statSync(path);
      if (stat.size < 10240) {
        console.warn(`[MosqueDbHelper] ${countryCode}.db is corrupted (${stat.size} bytes). Deleting.`);
        try {
          fs.unlinkSync(path);
        } catch (e) {
        }
        try {
          fs.unlinkSync(`${path}-wal`);
        } catch (e) {
        }
        try {
          fs.unlinkSync(`${path}-shm`);
        } catch (e) {
        }
        return false;
      }
      return true;
    } catch (err) {
      return false;
    }
  }
}