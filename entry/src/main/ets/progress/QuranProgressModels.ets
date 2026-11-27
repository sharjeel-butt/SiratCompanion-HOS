export interface QuranReadingPosition {
  surahId: number
  ayahId: number
  timestamp: number
}

export interface RecentSurah {
  surahId: number
  timestamp: number
}

export interface QuranStreak {
  current: number
  best: number
}