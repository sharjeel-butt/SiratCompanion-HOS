// entry/src/main/ets/mosques/MosqueService.ets

import { http } from '@kit.NetworkKit';
import { rcp } from '@kit.RemoteCommunicationKit'; // Import RCP
import { common } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { AppLogger } from '../core/AppLogger';
import { ManifestData, MosqueModel } from './MosqueModels';
import { MosqueDbHelper } from './MosqueDbHelper';
import { relationalStore } from '@kit.ArkData';

export class MosqueService {
  // Use the jsDelivr CDN URL with your specific tag
  private static readonly CDN_BASE_URL =
    'https://cdn.jsdelivr.net/gh/sharjeel-butt/SiratCompanion-HOS@v1.0.0/mosques-data/';

  static async fetchManifest(context: common.Context): Promise<ManifestData | null> {
    try {
      const req = http.createHttp();
      const response = await req.request(`${MosqueService.CDN_BASE_URL}manifest.json`, {
        method: http.RequestMethod.GET
      });
      req.destroy();

      if (response.responseCode === 200) {
        const jsonString: string = response.result as string;
        const data = JSON.parse(jsonString) as ManifestData;

        if (!data.countries) {
          AppLogger.error('MosqueService', 'Manifest missing "countries" map');
          return null;
        }
        return data;
      }
      return null;
    } catch (e) {
      AppLogger.error('MosqueService', `Manifest fetch failed: ${JSON.stringify(e)}`);
      return null;
    }
  }

  static async downloadPack(context: common.Context, countryCode: string): Promise<boolean> {
    const dirPath = `${context.databaseDir}/mosques`;
    const filePath = `${dirPath}/${countryCode}.db`;

    try {
      // 1. Ensure directory exists
      if (!fs.accessSync(dirPath)) {
        fs.mkdirSync(dirPath);
      }

      // 2. Use RCP for reliable file download
      const session = rcp.createSession();
      const downloadUrl = `${MosqueService.CDN_BASE_URL}${countryCode}.db`;

      const downloadToFile: rcp.DownloadToFile = {
        kind: 'file',
        file: filePath,
        keepLocal: false
      } as rcp.DownloadToFile;

      await session.downloadToFile(downloadUrl, downloadToFile);
      session.close();

      return true;
    } catch (e) {
      AppLogger.error('MosqueService', `Download failed for ${countryCode}: ${JSON.stringify(e)}`);
      // Cleanup partial download
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
    radiusKm: number = 10
  ): Promise<MosqueModel[]> {
    const open = await MosqueDbHelper.openDatabase(context, countryCode);
    if (!open) {
      return [];
    }

    const store = MosqueDbHelper.getStore();
    if (!store) {
      return [];
    }

    const latDelta = radiusKm / 111.0;
    const lngDelta = radiusKm / (111.0 * Math.cos(userLat * Math.PI / 180));

    const predicates = new relationalStore.RdbPredicates('mosques');
    predicates.between('lat', userLat - latDelta, userLat + latDelta);
    predicates.and();
    predicates.between('lng', userLng - lngDelta, userLng + lngDelta);

    const resultSet = await store.query(predicates, [
      'id', 'osm_id', 'name', 'name_ar', 'name_ur', 'name_tr', 'name_id', 'name_bn', 'name_zh',
      'lat', 'lng', 'city_name', 'address'
    ]);

    const results: MosqueModel[] = [];
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
        // FIXED: Use MosqueService instead of this
        distanceKm: MosqueService.haversineKm(userLat, userLng, lat, lng)
      };
      results.push(m);
    }
    resultSet.close();

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