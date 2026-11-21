export interface QuranCollection {
  id: string;
  title: string; // English fallback
  dua_ids: string[];
}

export interface QuranDuaNode {
  id: string;
  collection_ids: string[];
  prophet_ids: string[];
  related_dua_ids: string[];
}

export interface QuranProphet {
  id: string;
  name: string; // English fallback
  dua_ids: string[];
  collection_ids: string[];
}

export interface QuranEntityGraph {
  version: number;
  collections: Record<string, QuranCollection>;
  duas: Record<string, QuranDuaNode>;
  prophets: Record<string, QuranProphet>;
}

// 👇 FIX: Extract inline object into a named interface
export interface MergedDuaMetadata {
  title: string;
  reference: string;
}

export interface MergedDuaCatalog {
  duas: Record<string, MergedDuaMetadata>;
}

// 👇 FIX: Extract inline object into a named interface
export interface GraphCollectionI18n {
  title: string;
  description: string;
}

export interface QuranGraphI18n {
  collections: Record<string, GraphCollectionI18n>;
  prophets: Record<string, ProphetI18n>;
}

export interface ProphetI18n {
  name: string;
}
