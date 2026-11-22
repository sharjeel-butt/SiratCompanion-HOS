import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { RawPaths } from '../core/common/RawPaths';
import { AppLogger } from '../core/app/AppLogger';
import { QuranCollection, QuranEntityGraph, QuranGraphI18n, QuranProphet } from './QuranGraphModels';

export class QuranGraphService {
  private static graph: QuranEntityGraph | null = null;
  private static graphI18n: QuranGraphI18n | null = null;
  private static currentI18nLang: string = '';
  private static isLoading: boolean = false;

  static async init(ctx: common.Context, appLang: string): Promise<boolean> {
    if (QuranGraphService.graph !== null && QuranGraphService.currentI18nLang === appLang) {
      return true;
    }

    if (QuranGraphService.isLoading) {
      while (QuranGraphService.isLoading) {
        await new Promise<void>((resolve) => setTimeout(() => resolve(), 50));
      }
      return QuranGraphService.graph !== null;
    }

    QuranGraphService.isLoading = true;
    try {
      // 1. Load Entity Graph (structure)
      if (QuranGraphService.graph === null) {
        const graphData = await ctx.resourceManager.getRawFileContent(RawPaths.QURAN_ENTITY_GRAPH);
        QuranGraphService.graph =
          JSON.parse(util.TextDecoder.create('utf-8').decodeToString(graphData)) as QuranEntityGraph;
      }

      // 2. Load Graph i18n (UI labels for collections/prophets)
      if (QuranGraphService.currentI18nLang !== appLang) {
        try {
          const i18nData = await ctx.resourceManager.getRawFileContent(RawPaths.quranGraphI18n(appLang));
          QuranGraphService.graphI18n =
            JSON.parse(util.TextDecoder.create('utf-8').decodeToString(i18nData)) as QuranGraphI18n;
          QuranGraphService.currentI18nLang = appLang;
        } catch (e) {
          AppLogger.warn('QuranGraphService', `Graph i18n missing for ${appLang}, using English fallbacks.`);
          QuranGraphService.graphI18n = null;
        }
      }

      return true;
    } catch (e) {
      AppLogger.error('QuranGraphService', `Failed to load graph: ${JSON.stringify(e)}`);
      return false;
    } finally {
      QuranGraphService.isLoading = false;
    }
  }

  static getAllCollections(): QuranCollection[] {
    if (!QuranGraphService.graph) {
      return [];
    }
    return Object.values(QuranGraphService.graph.collections);
  }

  static getAllProphets(): QuranProphet[] {
    if (!QuranGraphService.graph) {
      return [];
    }
    return Object.values(QuranGraphService.graph.prophets).sort((a, b) => a.name.localeCompare(b.name));
  }

  static getDuaIdsForCollection(collectionId: string): string[] {
    if (!QuranGraphService.graph) {
      return [];
    }
    const col = QuranGraphService.graph.collections[collectionId];
    return col ? col.dua_ids : [];
  }

  static getDuaIdsForProphet(prophetId: string): string[] {
    if (!QuranGraphService.graph) {
      return [];
    }

    const prop = QuranGraphService.graph.prophets[prophetId];
    return prop ? prop.dua_ids : [];
  }

  static getRelatedDuaIds(duaId: string): string[] {
    if (!QuranGraphService.graph) {
      return [];
    }
    const dua = QuranGraphService.graph.duas[duaId];
    return dua ? dua.related_dua_ids : [];
  }

  static getCollectionIdsForDua(duaId: string): string[] {
    if (!QuranGraphService.graph) {
      return [];
    }
    const dua = QuranGraphService.graph.duas[duaId];
    return dua ? dua.collection_ids : [];
  }

  // --- Localization Helpers (App Language) ---
  static getCollectionTitle(id: string): string {
    if (QuranGraphService.graphI18n && QuranGraphService.graphI18n.collections[id]) {
      return QuranGraphService.graphI18n.collections[id].title;
    }
    if (QuranGraphService.graph && QuranGraphService.graph.collections[id]) {
      return QuranGraphService.graph.collections[id].title; // English fallback
    }
    return id;
  }

  static getProphetName(id: string): string {
    if (QuranGraphService.graphI18n && QuranGraphService.graphI18n.prophets[id]) {
      return QuranGraphService.graphI18n.prophets[id].name;
    }
    if (QuranGraphService.graph && QuranGraphService.graph.prophets[id]) {
      return QuranGraphService.graph.prophets[id].name; // English fallback
    }
    return id;
  }
}