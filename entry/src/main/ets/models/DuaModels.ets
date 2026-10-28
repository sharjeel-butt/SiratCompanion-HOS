export interface BaseDua {
  id: string;
  category: string;
  arabic: string;
  reference: string; // Default reference if translation fails
}

export interface TranslatedDua {
  name: string;
  translation: string;
  reference: string;
}

export interface CompleteDua extends BaseDua {
  translatedName: string;
  translatedText: string;
  translatedReference: string;
  isFavorite: boolean;
  boundPrayerIds: string[];
}