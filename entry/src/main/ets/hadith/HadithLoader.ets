import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { HadithRecord } from './HadithModels';
import { AppLogger } from '../core/AppLogger';

export class HadithLoader {
  private static masterList: HadithRecord[] = [];
  private static masterMap: Map<string, HadithRecord> = new Map();
  private static isLoaded: boolean = false;
  private static isLoading: boolean = false;

  static async load(ctx: common.Context): Promise<boolean> {
    // FIX: Use 'HadithLoader.' instead of 'this.' inside static methods
    if (HadithLoader.isLoaded) {
      return true;
    }

    if (HadithLoader.isLoading) {
      // FIX: Explicitly type the Promise and the callback
      while (HadithLoader.isLoading) {
        await new Promise<void>((resolve: () => void) => {
          setTimeout(() => {
            resolve();
          }, 100);
        });
      }
      return HadithLoader.isLoaded;
    }

    HadithLoader.isLoading = true;
    try {
      AppLogger.info('HadithLoader', 'Loading hadiths.json...');
      const data = await ctx.resourceManager.getRawFileContent('hadith/collection/hadiths.json');
      const jsonStr = util.TextDecoder.create('utf-8').decodeToString(data);

      HadithLoader.masterList = JSON.parse(jsonStr) as HadithRecord[];
      HadithLoader.masterMap.clear();

      for (const item of HadithLoader.masterList) {
        HadithLoader.masterMap.set(item.id, item);
      }

      HadithLoader.isLoaded = true;
      AppLogger.info('HadithLoader', `Loaded ${HadithLoader.masterList.length} hadiths successfully.`);
      return true;
    } catch (e) {
      AppLogger.error('HadithLoader', `Failed to load hadiths: ${JSON.stringify(e)}`);
      return false;
    } finally {
      HadithLoader.isLoading = false;
    }
  }

  static getById(id: string): HadithRecord | null {
    return HadithLoader.masterMap.get(id) || null;
  }

  static getAll(): HadithRecord[] {
    return HadithLoader.masterList;
  }

  // Temporary basic search until the Query Router is added
  static basicSearch(query: string): HadithRecord[] {
    if (!query || query.trim().length === 0) {
      return [];
    }
    const q = query.toLowerCase();

    // FIX: Explicitly type the filter callback parameter and return type
    return HadithLoader.masterList.filter((h: HadithRecord): boolean =>
    h.section.toLowerCase().includes(q) ||
      h.collection_name.toLowerCase().includes(q) ||
      h.id.toLowerCase().includes(q)
    ).slice(0, 50);
  }
}