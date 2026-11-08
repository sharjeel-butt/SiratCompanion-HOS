// entry/src/main/ets/quran/QuranSurahModels.ets

export interface Verse {
  ayah: number;
  arabic: string;
  translations: Record<string, string>;
}

export interface CompleteSurah {
  id: number;
  nameArabic: string;
  nameTransliteration: string;
  revelationPlace: string;
  ayahCount: number;
  verses: Verse[];
  isFavorite: boolean;
}

export interface EvidenceItem {
  collection: string;
  hadithNumber: string;
  grade: string;
  evidenceType: string;
  grader?: string;
  note?: string;
}

export interface VerseSelection {
  surahNumber: number;
  startVerse: number;
  endVerse: number;
}

export interface RawRecitationTask {
  id: string;
  contentType: 'surah' | 'verse_range';
  surahNumber: number;
  startVerse: number | null;
  endVerse: number | null;
  occasion: string;
  recitationContext: string;
  repeatCount: number;
  authenticity: string;
  reference: string;
  evidence?: EvidenceItem[];
  groupId?: string;
  rakAh?: number;
  verseSelections?: VerseSelection[];
  notes?: string;
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
  startVerse: number | null;
  endVerse: number | null;
  occasion: string;
  recitationContext: string;
  repeatCount: number;
  authenticity: string;
  reference: string;
  evidence?: EvidenceItem[];
  groupId?: string;
  rakAh?: number;
  verseSelections?: VerseSelection[];

  // Merged Localization
  name: string;
  notes: string;
  localizedReference: string;

  // Surah Info for UI
  surahNameTransliteration: string;
  surahNameArabic: string;
}