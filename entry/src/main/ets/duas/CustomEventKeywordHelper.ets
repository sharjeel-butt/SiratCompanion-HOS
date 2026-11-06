// entry/src/main/ets/duas/CustomEventKeywordHelper.ets

import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { AppLogger } from '../core/AppLogger';

interface KeywordMap {
  category: string;
  duaId: string;
  keywords: Record<string, string[]>;
}

export class CustomEventKeywordHelper {
  private static mappings: KeywordMap[] = [];
  private static isLoaded: boolean = false;

  static async init(context: common.Context): Promise<void> {
    if (CustomEventKeywordHelper.isLoaded) {
      return;
    }

    try {
      const mgr = context.resourceManager;
      const data = await mgr.getRawFileContent('duas/dua_keyword_map.json');
      const jsonStr = util.TextDecoder.create('utf-8').decodeToString(data);
      CustomEventKeywordHelper.mappings = JSON.parse(jsonStr) as KeywordMap[];
      CustomEventKeywordHelper.isLoaded = true;
      AppLogger.info('CustomEventKeywordHelper',
        `Loaded ${CustomEventKeywordHelper.mappings.length} keyword categories`);
    } catch (e) {
      AppLogger.error('CustomEventKeywordHelper', `Failed to load keyword map: ${JSON.stringify(e)}`);
    }
  }

  /**
   * Scans a given text for keywords in the specified language and returns mapped Dua IDs.
   */
  static getDuaIdsForText(text: string, lang: string): string[] {
    const lowerText = text.toLowerCase();
    const resultIds: string[] = [];

    for (const map of CustomEventKeywordHelper.mappings) {
      // Get keywords for the current language, fallback to English
      const keywords = map.keywords[lang] || map.keywords['en'] || [];

      for (const kw of keywords) {
        if (lowerText.includes(kw.toLowerCase())) {
          resultIds.push(map.duaId);
          break; // Found a match in this category, move to the next category
        }
      }
    }

    return resultIds;
  }
}