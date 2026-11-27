import { PreferencesHelper } from '../core/util/PreferencesHelper'
import {
  STORAGE_KEY_QURAN_BEST_STREAK,
  STORAGE_KEY_QURAN_CURRENT_STREAK,
  STORAGE_KEY_QURAN_LAST_AYAH,
  STORAGE_KEY_QURAN_LAST_READ,
  STORAGE_KEY_QURAN_LAST_STREAK_DAY,
  STORAGE_KEY_QURAN_LAST_SURAH,
  STORAGE_KEY_QURAN_PROGRESS_VERSION,
  STORAGE_KEY_QURAN_RECENT_SURAHS
} from '../core/common/StorageKeys'
import { QuranReadingPosition, QuranStreak, RecentSurah } from './QuranProgressModels'

export class QuranProgressService {
  static async savePosition(surahId: number, ayahId: number): Promise<void> {
    await PreferencesHelper.setNumber(STORAGE_KEY_QURAN_LAST_SURAH, surahId)
    AppStorage.setOrCreate(STORAGE_KEY_QURAN_PROGRESS_VERSION, Date.now())
    await PreferencesHelper.setNumber(STORAGE_KEY_QURAN_LAST_READ, Date.now())
    await QuranProgressService.saveRecentSurah(surahId)
    await QuranProgressService.updateStreak()
  }

  private static async saveRecentSurah(surahId: number): Promise<void> {
    const json = await PreferencesHelper.getString(STORAGE_KEY_QURAN_RECENT_SURAHS, '[]')

    let items: RecentSurah[] = []

    try {
      items = JSON.parse(json) as RecentSurah[]
    } catch {
    }

    items = items.filter((s: RecentSurah): boolean => s.surahId !== surahId)

    items.unshift({
      surahId, timestamp: Date.now()
    })

    items = items.slice(0, 6)

    await PreferencesHelper.setString(STORAGE_KEY_QURAN_RECENT_SURAHS, JSON.stringify(items))
  }

  static async getRecentSurahs(): Promise<RecentSurah[]> {
    const json = await PreferencesHelper.getString(STORAGE_KEY_QURAN_RECENT_SURAHS, '[]')

    try {
      return JSON.parse(json) as RecentSurah[]
    } catch {
      return []
    }
  }

  static async getPosition(): Promise<QuranReadingPosition | null> {
    const timestamp = await PreferencesHelper.getNumber(STORAGE_KEY_QURAN_LAST_READ, 0)

    if (timestamp === 0) {
      return null
    }

    return {
      surahId: await PreferencesHelper.getNumber(STORAGE_KEY_QURAN_LAST_SURAH, 1),
      ayahId: await PreferencesHelper.getNumber(STORAGE_KEY_QURAN_LAST_AYAH, 1),
      timestamp
    }
  }

  static async clear(): Promise<void> {
    await PreferencesHelper.remove(STORAGE_KEY_QURAN_LAST_SURAH)
    await PreferencesHelper.remove(STORAGE_KEY_QURAN_LAST_AYAH)
    await PreferencesHelper.remove(STORAGE_KEY_QURAN_LAST_READ)
  }

  private static getDayKey(date: Date): string {
    const y = date.getFullYear()
    const m = `${date.getMonth() + 1}`.padStart(2, '0')
    const d = `${date.getDate()}`.padStart(2, '0')

    return `${y}-${m}-${d}`
  }

  private static async updateStreak(): Promise<void> {
    const today = QuranProgressService.getDayKey(new Date())

    const lastDay = await PreferencesHelper.getString(STORAGE_KEY_QURAN_LAST_STREAK_DAY, '')

    if (lastDay === today) {
      return
    }

    const current = await PreferencesHelper.getNumber(STORAGE_KEY_QURAN_CURRENT_STREAK, 0)

    let nextCurrent = 1

    if (lastDay.length > 0) {
      const yesterday = new Date()

      yesterday.setDate(yesterday.getDate() - 1)

      if (lastDay === QuranProgressService.getDayKey(yesterday)) {
        nextCurrent = current + 1
      }
    }

    const best = await PreferencesHelper.getNumber(STORAGE_KEY_QURAN_BEST_STREAK, 0)

    await PreferencesHelper.setNumber(STORAGE_KEY_QURAN_CURRENT_STREAK, nextCurrent)

    await PreferencesHelper.setNumber(STORAGE_KEY_QURAN_BEST_STREAK, Math.max(best, nextCurrent))

    await PreferencesHelper.setString(STORAGE_KEY_QURAN_LAST_STREAK_DAY, today)
  }

  static async getStreak(): Promise<QuranStreak> {
    return {
      current: await PreferencesHelper.getNumber(STORAGE_KEY_QURAN_CURRENT_STREAK, 0),
      best: await PreferencesHelper.getNumber(STORAGE_KEY_QURAN_BEST_STREAK, 0)
    }
  }
}