// entry/src/main/ets/quran/QuranSurahModels.ets

export interface RawRecitationTask {
  id: string;
  contentType: 'surah' | 'verse_range';
  surahNumber: number;
  startVerse: number;
  endVerse: number | null;
  occasion: string;
  recitationContext: 'personal' | 'household' | 'prayer' | 'sermon';
  repeatCount: number;
  authenticity: string;
  reference: string;
  groupId?: string;
  rakAh?: number;
}

export interface SurahTranslationInfo {
  nameMeaning: string;
  translatedText: string;
}

export interface LocalizedRecitationInfo {
  name: string;
  notes: string;
  reference: string;
}

export interface RecitationTask {
  id: string;
  contentType: 'surah' | 'verse_range';
  surahNumber: number;
  startVerse: number;
  endVerse: number | null;
  occasion: string;
  recitationContext: string;
  repeatCount: number;
  authenticity: string;
  reference: string;
  groupId?: string;
  rakAh?: number;

  // Merged Localization
  name: string;
  notes: string;
  localizedReference: string;

  // Surah Info for UI
  surahNameTransliteration: string;
  surahNameArabic: string;
}

export interface CompleteSurah {
  id: number;
  nameArabic: string;
  nameTransliteration: string;
  revelationPlace: string;
  ayahCount: number;
  arabicText: string;
  nameMeaning: string;
  translatedText: string;
  isFavorite: boolean;
}