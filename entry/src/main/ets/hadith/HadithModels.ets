export interface HadithRef {
  id: string;
  importance_score: number;
  section?: string;
  life_contexts?: string[];
  topics?: string[];
}

export interface QueryRouter {
  contexts: Record<string, string[]>;
  topics: Record<string, string[]>;
}

export interface CatalogItem {
  id: string;
  name: string;
}

export interface Catalog {
  contexts: string[];
  topics: string[];
  collections?: string[]; // Not in the JSON, but we'll populate it manually
}

// NEW: Explicit interface instead of inline object type
export interface RouteResult {
  contexts: string[];
  topics: string[];
}

export interface HadithDbRecord {
  hadith_id: string;
  collection: string;
  hadith_number: string;
  text: string;
}

export interface BilingualHadith {
  id: string;
  collection: string;
  section: string;
  section_localized: string;
  hadith_number: string;
  arabic_text: string;
  translated_text: string;
  translated_language: string;
  life_contexts?: string[];
  topics?: string[];
}

export interface HadithMetadata {
  section: string;
  life_contexts: string[];
  topics: string[];
}