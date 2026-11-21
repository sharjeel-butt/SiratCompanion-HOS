// entry/src/main/ets/core/RawPaths.ets
//
// Central registry for every rawfile path. No file outside this class
// may contain a rawfile path literal. Path strings mirror the v4.1
// bundle layout exactly.

export class RawPaths {
  static readonly BUNDLE_MANIFEST: string = 'bundle_manifest.json';
  static readonly FEATURED: string = 'featured.json';
  static readonly DATABASE_VERSION: string = 'database/VERSION';
  static readonly CORE_VERSION: string = 'core/VERSION';
  static readonly CORE_DB: string = 'core/core.db.gz';
  static readonly QURAN_VERSION: string = 'quran/VERSION';
  static readonly QURAN_DB: string = 'quran/quran.db.gz';
  static readonly QURAN_RECITATIONS_RAW: string = 'quran/recitations_raw.json';
  static readonly DUA_KEYWORD_MAP: string = 'duas/dua_keyword_map.json';
  static readonly DUA_BASE: string = 'duas/duas_base.json';
  static readonly DUA_CATEGORIES: string = 'duas/categories.json';
  static readonly EVENTS: string = 'events/islamic_events.json';
  static readonly MASTER_SECTIONS: string = 'metadata/master_sections.json';
  static readonly SECTION_ALIASES: string = 'metadata/section_aliases_v2.json';
  static readonly CATALOG: string = 'lookup/catalog.json';
  static readonly QUERY_ROUTER: string = 'routing/query_router.json';
  static readonly OFFLINE_CITIES: string = 'locations/offline-cities.json';
  static readonly CITY_TRANSLATIONS: string = 'locations/city_translations.json';
  static readonly QURAN_LICENSES: string = 'licenses/quran_licenses.json';
  static readonly HADITH_LICENSES: string = 'licenses/hadith_licenses.json';
  static readonly QURAN_ENTITY_GRAPH: string = 'quran/quranic_entity_graph.json';
  static readonly QURAN_MERGED_CATALOG: string = 'quran/quranic_merged_dua_catalog.json';

  static quranGraphI18n(lang: string): string {
    return `quran/i18n/quran_graph_${lang}.json`;
  }

  static hadithDb(lang: string): string {
    return `database/${lang}/hadith.db.gz`;
  }

  static quranRecitations(lang: string): string {
    return `quran/recitations_${lang}.json`;
  }

  static duas(lang: string): string {
    return `duas/duas_${lang}.json`;
  }

  static i18n(lang: string): string {
    return `i18n/${lang}.json`;
  }

  static langSections(lang: string): string {
    return `metadata/${lang}_sections.json`;
  }

  static context(id: string): string {
    return `contexts/${id}.json`;
  }

  static topic(id: string): string {
    return `topics/${id}.json`;
  }

  static privacy(lang: string): string {
    return `privacy/privacy_${lang}.json`;
  }
}