import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { HadithRef, QueryRouter, Catalog, RouteResult, HadithMetadata } from './HadithModels';
import { AppLogger } from '../core/AppLogger';
import { HadithDbHelper } from './HadithDbHelper';

export class HadithSearchService {
  private static router: QueryRouter | null = null;
  private static catalog: Catalog | null = null;

  private static metadataCache: Map<string, HadithMetadata> = new Map();
  private static isCacheBuilt: boolean = false;
  private static i18nCache: Map<string, Record<string, string>> = new Map();

  static async init(ctx: common.Context): Promise<void> {
    if (HadithSearchService.router === null) {
      try {
        const data: Uint8Array = await ctx.resourceManager.getRawFileContent('hadith/routing/query_router.json');
        const jsonStr: string = util.TextDecoder.create('utf-8').decodeToString(data);
        const parsed: Object = JSON.parse(jsonStr);
        HadithSearchService.router = parsed as QueryRouter;
        AppLogger.info('SearchService', 'Query Router loaded successfully.');
      } catch (error) {
        const err: Error = error as Error;
        AppLogger.error('SearchService', `Router load failed: ${err.message}`);
      }
    }
  }

  static async loadI18n(ctx: common.Context, lang: string): Promise<void> {
    if (HadithSearchService.i18nCache.has(lang)) {
      return;
    }
    try {
      const data: Uint8Array = await ctx.resourceManager.getRawFileContent(`hadith/i18n/${lang}.json`);
      const jsonStr: string = util.TextDecoder.create('utf-8').decodeToString(data);
      const parsed: Object = JSON.parse(jsonStr);
      HadithSearchService.i18nCache.set(lang, parsed as Record<string, string>);
      AppLogger.info('SearchService', `i18n loaded for ${lang}`);
    } catch (e) {
      AppLogger.warn('SearchService', `Failed to load i18n for ${lang}`);
      HadithSearchService.i18nCache.set(lang, {}); // Prevent repeated failed loads
    }
  }

  static translate(key: string, lang: string): string {
    if (!key) {
      return '';
    }

    const dictionary = HadithSearchService.i18nCache.get(lang);
    if (dictionary && dictionary[key]) {
      return dictionary[key];
    }

    // Fallback: clean up the key (e.g., "context_financial_stress" -> "Financial Stress")
    let raw = key;
    if (raw.startsWith('context_')) {
      raw = raw.replace('context_', '');
    }
    if (raw.startsWith('topic_')) {
      raw = raw.replace('topic_', '');
    }
    if (raw.startsWith('collection_')) {
      raw = raw.replace('collection_', '');
    }

    raw = raw.replace(/_/g, ' ');
    // Capitalize the first letter of every word
    return raw.replace(/\b\w/g, (c: string) => c.toUpperCase());
  }

  static async setLanguage(ctx: common.Context, lang: string): Promise<boolean> {
    const dbSuccess = await HadithDbHelper.openDatabase(ctx, lang);
    if (dbSuccess) {
      await HadithSearchService.loadI18n(ctx, lang);
    }
    return dbSuccess;
  }

  static async buildMetadataCache(ctx: common.Context): Promise<void> {
    if (HadithSearchService.isCacheBuilt) {
      return;
    }
    await HadithSearchService.init(ctx);

    if (HadithSearchService.catalog === null) {
      const data = await ctx.resourceManager.getRawFileContent('hadith/lookup/catalog.json');
      HadithSearchService.catalog = JSON.parse(util.TextDecoder.create('utf-8').decodeToString(data)) as Catalog;
    }

    const loadFile = async (path: string) => {
      try {
        const data = await ctx.resourceManager.getRawFileContent(path);
        const parsed = JSON.parse(util.TextDecoder.create('utf-8').decodeToString(data)) as HadithRef[];
        for (let i = 0; i < parsed.length; i++) {
          const ref = parsed[i];
          if (typeof ref === 'string') {
            continue;
          } // Safety check
          if (!HadithSearchService.metadataCache.has(ref.id)) {
            HadithSearchService.metadataCache.set(ref.id, {
              section: ref.section || '',
              life_contexts: ref.life_contexts || [],
              topics: ref.topics || []
            });
          }
        }
      } catch (e) { /* Ignore missing files */
      }
    };

    // Load all contexts
    if (HadithSearchService.catalog && HadithSearchService.catalog.contexts) {
      for (const c of HadithSearchService.catalog.contexts) {
        // 👇 FIX: c is a string, not an object
        await loadFile(`hadith/contexts/${c}.json`);
      }
    }
    // Load all topics
    if (HadithSearchService.catalog && HadithSearchService.catalog.topics) {
      for (const t of HadithSearchService.catalog.topics) {
        // 👇 FIX: t is a string, not an object
        await loadFile(`hadith/topics/${t}.json`);
      }
    }

    HadithSearchService.isCacheBuilt = true;
    AppLogger.info('SearchService', `Metadata cache built for ${HadithSearchService.metadataCache.size} hadiths.`);
  }

  static async getMetadataForId(ctx: common.Context, id: string): Promise<HadithMetadata | null> {
    await HadithSearchService.buildMetadataCache(ctx);
    return HadithSearchService.metadataCache.get(id) || null;
  }

  static routeQuery(query: string): RouteResult {
    if (HadithSearchService.router === null) {
      return { contexts: [], topics: [] };
    }

    const cleanQuery: string = query.toLowerCase().replace(/[.,\/#!$%\^&\*;:{}=\-_`~()]/g, " ");
    const matchedContexts: string[] = [];
    const matchedTopics: string[] = [];

    if (HadithSearchService.router.contexts) {
      const ctxIds: string[] = Object.keys(HadithSearchService.router.contexts);
      for (let i: number = 0; i < ctxIds.length; i++) {
        const ctxId: string = ctxIds[i];
        const keywords: string[] = HadithSearchService.router.contexts[ctxId];

        if (keywords && Array.isArray(keywords)) {
          for (let j: number = 0; j < keywords.length; j++) {
            if (cleanQuery.includes(keywords[j].toLowerCase())) {
              if (!matchedContexts.includes(ctxId)) {
                matchedContexts.push(ctxId);
              }
              break;
            }
          }
        }
      }
    }

    if (HadithSearchService.router.topics) {
      const topicIds: string[] = Object.keys(HadithSearchService.router.topics);
      for (let i: number = 0; i < topicIds.length; i++) {
        const topicId: string = topicIds[i];
        const keywords: string[] = HadithSearchService.router.topics[topicId];

        if (keywords && Array.isArray(keywords)) {
          for (let j: number = 0; j < keywords.length; j++) {
            if (cleanQuery.includes(keywords[j].toLowerCase())) {
              if (!matchedTopics.includes(topicId)) {
                matchedTopics.push(topicId);
              }
              break;
            }
          }
        }
      }
    }

    return { contexts: matchedContexts, topics: matchedTopics };
  }

  static async search(ctx: common.Context, query: string): Promise<HadithRef[]> {
    await HadithSearchService.init(ctx);
    const routes: RouteResult = HadithSearchService.routeQuery(query);

    const refs: HadithRef[] = [];

    for (const c of routes.contexts) {
      try {
        const data: Uint8Array = await ctx.resourceManager.getRawFileContent(`hadith/contexts/${c}.json`);
        const jsonStr: string = util.TextDecoder.create('utf-8').decodeToString(data);
        const parsed = JSON.parse(jsonStr) as HadithRef[];
        for (let i: number = 0; i < parsed.length; i++) {
          refs.push(parsed[i]);
        }
      } catch (error) {
      }
    }

    for (const t of routes.topics) {
      try {
        const data: Uint8Array = await ctx.resourceManager.getRawFileContent(`hadith/topics/${t}.json`);
        const jsonStr: string = util.TextDecoder.create('utf-8').decodeToString(data);
        const parsed = JSON.parse(jsonStr) as HadithRef[];
        for (let i: number = 0; i < parsed.length; i++) {
          refs.push(parsed[i]);
        }
      } catch (error) {
      }
    }

    const uniqueMap: Map<string, HadithRef> = new Map<string, HadithRef>();
    for (let i: number = 0; i < refs.length; i++) {
      const r: HadithRef = refs[i];
      const current = uniqueMap.get(r.id);
      if (current === undefined || r.importance_score > current.importance_score) {
        uniqueMap.set(r.id, r);
      }
    }

    const results: HadithRef[] = [];
    uniqueMap.forEach((val: HadithRef) => {
      results.push(val);
    });
    results.sort((a: HadithRef, b: HadithRef): number => b.importance_score - a.importance_score);

    return results.slice(0, 50);
  }

  static async getFeatured(ctx: common.Context): Promise<HadithRef[]> {
    try {
      const data: Uint8Array = await ctx.resourceManager.getRawFileContent('hadith/featured.json');
      const jsonStr: string = util.TextDecoder.create('utf-8').decodeToString(data);
      const parsed: Object = JSON.parse(jsonStr);
      return parsed as HadithRef[];
    } catch (error) {
      return [];
    }
  }
}