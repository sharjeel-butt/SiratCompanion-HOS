import { http } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { relationalStore } from '@kit.ArkData'; // MUST be at the top
import { AppLogger } from '../core/AppLogger';
import { ManifestData, MosqueModel } from './MosqueModels';
import { MosqueDbHelper } from './MosqueDbHelper';
import { MosqueStorage } from './MosqueStorage';
import { buffer } from '@kit.ArkTS';

export class MosqueService {
  private static readonly CDN_BASE_URL =
    'https://cdn.jsdelivr.net/gh/sharjeel-butt/SiratCompanion-HOS@master/mosques-data/';

  static async fetchManifest(context: common.Context): Promise<ManifestData | null> {
    try {
      const req = http.createHttp();
      const response = await req.request(`${MosqueService.CDN_BASE_URL}manifest.json`, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING
      });
      req.destroy();

      if (response.responseCode === 200) {
        return JSON.parse(response.result as string) as ManifestData;
      }
      return null;
    } catch (e) {
      AppLogger.error('MosqueService', `Manifest fetch failed: ${JSON.stringify(e)}`);
      return null;
    }
  }

  static async downloadPack(context: common.Context, countryCode: string, expectedSize: number): Promise<boolean> {
    // ✅ CORRECTED PATH: Match the rdb directory used by relationalStore
    const dirPath = `${context.databaseDir}/rdb/mosques`;
    const filePath = `${dirPath}/${countryCode}.db`;
    let file: fs.File | null = null;

    try {
      // 1. Ensure the correct rdb directory exists
      if (!fs.accessSync(dirPath)) {
        fs.mkdirSync(dirPath, true); // Use recursive mkdir to create nested folders if needed
      }

      // 2. Clean up any old files at the correct path and the old (wrong) path
      const oldWrongPath = `${context.databaseDir}/mosques/${countryCode}.db`;
      try {
        fs.unlinkSync(oldWrongPath);
      } catch (e) {
      }
      try {
        fs.unlinkSync(filePath);
      } catch (e) {
      }
      try {
        fs.unlinkSync(`${filePath}-wal`);
      } catch (e) {
      }
      try {
        fs.unlinkSync(`${filePath}-shm`);
      } catch (e) {
      }

      // 3. Download the file (using the same HTTP logic as before)
      const req = http.createHttp();
      const response = await req.request(`${MosqueService.CDN_BASE_URL}${countryCode}.db`, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.ARRAY_BUFFER
      });
      req.destroy();

      if (response.responseCode === 200 && response.result instanceof ArrayBuffer) {
        file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
        fs.writeSync(file.fd, response.result);
        fs.closeSync(file);
        file = null;

        // 4a. Validate size
        const stat = fs.statSync(filePath);
        if (stat.size < 10240) {
          AppLogger.error('MosqueService',
            `File too small (${stat.size} bytes). Deleting.`);
          try {
            fs.unlinkSync(filePath);
          } catch (err) { /* ignore */
          }
          return false;
        }

        // 4b. Validate SQLite header — first 16 bytes must be "SQLite format 3\0"
        let headerOk = false;
        try {
          const headerFile = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
          const headerBuf = new ArrayBuffer(16);
          fs.readSync(headerFile.fd, headerBuf);
          fs.closeSync(headerFile);
          const headerStr = buffer
            .from(new Uint8Array(headerBuf))
            .toString('utf8');
          // The magic is exactly "SQLite format 3\0"
          headerOk = headerStr === 'SQLite format 3\u0000';
          if (!headerOk) {
            AppLogger.error('MosqueService',
              `Invalid SQLite header (got "${headerStr.slice(0, 16)}"). ` +
                `Deleting ${countryCode}.db.`);
          }
        } catch (readErr) {
          AppLogger.error('MosqueService',
            `Header read failed for ${countryCode}.db: ${JSON.stringify(readErr)}`);
          headerOk = false;
        }

        if (!headerOk) {
          try {
            fs.unlinkSync(filePath);
          } catch (err) { /* ignore */
          }
          try {
            fs.unlinkSync(`${filePath}-wal`);
          } catch (err) { /* ignore */
          }
          try {
            fs.unlinkSync(`${filePath}-shm`);
          } catch (err) { /* ignore */
          }
          return false;
        }

        AppLogger.info('MosqueService',
          `Successfully downloaded and verified ${countryCode}.db`);
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('MosqueService', `Download exception: ${JSON.stringify(e)}`);
      if (file) {
        try {
          fs.closeSync(file);
        } catch (err) {
        }
      }
      try {
        fs.unlinkSync(filePath);
      } catch (err) {
      }
      return false;
    }
  }

  static async searchNearby(
    context: common.Context,
    countryCode: string,
    userLat: number,
    userLng: number,
    radiusKm: number = 15
  ): Promise<MosqueModel[]> {
    const results: MosqueModel[] = [];

    // 1. Fetch Custom Mosques
    const customMosques = await MosqueStorage.load();
    for (const cm of customMosques) {
      cm.distanceKm = MosqueService.haversineKm(userLat, userLng, cm.lat, cm.lng);
      if (cm.distanceKm <= radiusKm) {
        results.push(cm);
      }
    }

    // 2. Fetch OSM Mosques (Only if the DB is downloaded)
    if (MosqueDbHelper.isDownloaded(context, countryCode)) {
      const open = await MosqueDbHelper.openDatabase(context, countryCode);
      if (open) {
        const store = MosqueDbHelper.getStore();
        if (store) {
          try {
            const latDelta = radiusKm / 111.0;
            const lngDelta = radiusKm / (111.0 * Math.cos(userLat * Math.PI / 180));

            const predicates = new relationalStore.RdbPredicates('mosques');
            predicates.between('lat', userLat - latDelta, userLat + latDelta);
            predicates.and();
            predicates.between('lng', userLng - lngDelta, userLng + lngDelta);

            const resultSet = await store.query(predicates, [
              'id', 'osm_id', 'name', 'name_ar', 'name_ur', 'name_tr', 'name_id', 'name_bn', 'name_zh',
              'lat', 'lng', 'city_name', 'address', 'phone', 'website'
            ]);

            while (resultSet.goToNextRow()) {
              const lat = resultSet.getDouble(resultSet.getColumnIndex('lat'));
              const lng = resultSet.getDouble(resultSet.getColumnIndex('lng'));

              const m: MosqueModel = {
                id: resultSet.getLong(resultSet.getColumnIndex('id')),
                osmId: resultSet.getString(resultSet.getColumnIndex('osm_id')),
                name: resultSet.getString(resultSet.getColumnIndex('name')),
                nameAr: resultSet.getString(resultSet.getColumnIndex('name_ar')),
                nameUr: resultSet.getString(resultSet.getColumnIndex('name_ur')),
                nameTr: resultSet.getString(resultSet.getColumnIndex('name_tr')),
                nameId: resultSet.getString(resultSet.getColumnIndex('name_id')),
                nameBn: resultSet.getString(resultSet.getColumnIndex('name_bn')),
                nameZh: resultSet.getString(resultSet.getColumnIndex('name_zh')),
                lat: lat,
                lng: lng,
                cityName: resultSet.getString(resultSet.getColumnIndex('city_name')),
                address: resultSet.getString(resultSet.getColumnIndex('address')),
                phone: resultSet.getString(resultSet.getColumnIndex('phone')) || '',
                website: resultSet.getString(resultSet.getColumnIndex('website')) || '',
                distanceKm: MosqueService.haversineKm(userLat, userLng, lat, lng),
                isCustom: false
              };
              results.push(m);
            }
            resultSet.close();
          } catch (e) {
            AppLogger.error('MosqueService', `Query failed: ${JSON.stringify(e)}`);
          }
        }
      }
    }

    // 3. Sort combined results
    results.sort((a, b) => a.distanceKm - b.distanceKm);
    return results;
  }

  static getLocalizedName(mosque: MosqueModel, lang: string): string {
    let localized = '';
    if (lang === 'ar') {
      localized = mosque.nameAr;
    } else if (lang === 'ur') {
      localized = mosque.nameUr;
    } else if (lang ===
      'tr') {
      localized = mosque.nameTr;
    } else if (lang === 'id') {
      localized = mosque.nameId;
    } else if (lang ===
      'bn') {
      localized = mosque.nameBn;
    } else if (lang === 'zh') {
      localized = mosque.nameZh;
    }

    return (localized && localized.trim().length > 0) ? localized : mosque.name;
  }

  private static haversineKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371;
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }
}