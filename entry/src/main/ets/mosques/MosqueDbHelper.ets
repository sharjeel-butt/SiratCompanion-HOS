import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';

export class MosqueDbHelper {
  private static store: relationalStore.RdbStore | null = null;
  private static currentCountry: string = '';

  static async openDatabase(context: common.Context, countryCode: string): Promise<boolean> {
    // Use the class name instead of 'this'
    if (MosqueDbHelper.store !== null && MosqueDbHelper.currentCountry === countryCode) {
      return true;
    }

    MosqueDbHelper.closeDatabase();

    try {
      const dbPath = `${countryCode}.db`;
      const config: relationalStore.StoreConfig = {
        name: dbPath,
        securityLevel: relationalStore.SecurityLevel.S1,
        customDir: 'mosques'
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
    const path = `${context.databaseDir}/mosques/${countryCode}.db`;
    try {
      // Use the imported fs module
      return fs.accessSync(path);
    } catch (err) {
      return false;
    }
  }
}