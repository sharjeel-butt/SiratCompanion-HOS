export interface BaseDua {
  id: string;
  category: string;
  arabic: string;
  reference: string;

  /** Optional phonetic transliteration, shown in the simple display card. */
  transliteration?: string;
}

export interface TranslatedDua {
  name: string;
  translation: string;
  reference: string;
  sources?: DuaSource[];
  reference_display?: string;
  migration_status?: string;
}

export interface DuaSource {
  type: 'hadith' | 'quran' | 'external';
  id?: string;
  surah?: number;
  ayah?: number;
  display?: string;
  role: 'primary' | 'supporting';
}

export interface CompleteDua extends BaseDua {
  translatedName: string;
  translatedText: string;
  translatedReference: string;
  isFavorite: boolean;
  boundPrayerIds: string[];
  sources?: DuaSource[];
  reference_display?: string;
  migration_status?: string;
}