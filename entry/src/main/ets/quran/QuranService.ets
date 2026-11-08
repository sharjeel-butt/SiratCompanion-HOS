// entry/src/main/ets/quran/QuranService.ets

import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { AppLogger } from '../core/AppLogger';
import {
  CompleteSurah, LocalizedRecitationInfo, RawRecitationTask, RecitationTask,
} from './QuranSurahModels';
import { UpcomingCustomEvent } from '../pages/HomePage';

export class QuranService {
  private static cachedSurahs: CompleteSurah[] = [];
  private static cachedLang: string = '';

  static async loadSurahs(context: common.UIAbilityContext, lang: string): Promise<CompleteSurah[]> {
    if (QuranService.cachedSurahs.length > 0 && QuranService.cachedLang === lang) {
      return QuranService.cachedSurahs;
    }

    try {
      const mgr = context.resourceManager;
      // We no longer need separate script/translation files. It's all in one!
      const fileName = `quran/quran_qul_verses.json`;

      const data = await mgr.getRawFileContent(fileName);
      const surahs = JSON.parse(util.TextDecoder.create('utf-8').decodeToString(data)) as CompleteSurah[];

      QuranService.cachedSurahs = surahs;
      QuranService.cachedLang = lang;
      return surahs;
    } catch (e) {
      AppLogger.error('QuranService', `Failed to load QUL data: ${JSON.stringify(e)}`);
      return [];
    }
  }

  static async getRecommendedRecitations(
    context: common.UIAbilityContext,
    lang: string,
    isFriday: boolean,
    customEvents: UpcomingCustomEvent[],
    showAll: boolean = false // <--- NEW PARAMETER
  ): Promise<RecitationTask[]> {
    const mgr = context.resourceManager;

    try {
      const rawData = await mgr.getRawFileContent('quran/quran_recitations_raw.json');
      const rawTasks = JSON.parse(util.TextDecoder.create('utf-8').decodeToString(rawData)) as RawRecitationTask[];

      const enData = await mgr.getRawFileContent('quran/quran_recitations_en.json');
      const englishLoc =
        JSON.parse(util.TextDecoder.create('utf-8').decodeToString(enData)) as Record<string, LocalizedRecitationInfo>;

      let targetLoc: Record<string, LocalizedRecitationInfo> = {};
      if (lang === 'en') {
        targetLoc = englishLoc;
      } else {
        try {
          const langData = await mgr.getRawFileContent(`quran/quran_recitations_${lang}.json`);
          targetLoc = JSON.parse(util.TextDecoder.create('utf-8').decodeToString(langData)) as
            Record<string, LocalizedRecitationInfo>;
        } catch (e) {
          targetLoc = {};
        }
      }

      const activeOccasions: string[] = ['general_virtue'];
      const hour = new Date().getHours();

      if (hour >= 4 && hour < 12) {
        activeOccasions.push('morning_evening', 'fajr_prayer');
      }
      if (hour >= 12 && hour < 16) {
        activeOccasions.push('dhuhr_prayer');
      }
      if (hour >= 16 && hour < 19) {
        activeOccasions.push('maghrib_prayer');
      }
      if (hour >= 19 || hour < 4) {
        activeOccasions.push('bedtime', 'night');
      }

      if (isFriday) {
        activeOccasions.push('friday', 'friday_fajr', 'friday_prayer', 'friday_sermon');
      }

      for (const ce of customEvents) {
        const title = ce.ev.title.toLowerCase();
        if (title.includes('sick') || title.includes('illness')) {
          activeOccasions.push('illness_ruqyah');
        }
        if (title.includes('protect') || title.includes('safe')) {
          activeOccasions.push('home_protection',
            'protection_dajjal');
        }
        if (title.includes('eid')) {
          activeOccasions.push('eid_prayer');
        }
      }

      const results: RecitationTask[] = [];
      const seenGroups = new Set<string>();
      const allSurahs = await QuranService.loadSurahs(context, lang);

      for (const task of rawTasks) {
        // NEW: If showAll is true, we skip the occasion filter
        if (showAll || activeOccasions.includes(task.occasion)) {
          if (task.groupId) {
            if (seenGroups.has(task.groupId)) {
              continue;
            }
            seenGroups.add(task.groupId);
          }

          const trans = targetLoc[task.id] || englishLoc[task.id];
          const surah = allSurahs.find(s => s.id === task.surahNumber);

          const merged: RecitationTask = {
            id: task.id,
            contentType: task.contentType,
            surahNumber: task.surahNumber,
            startVerse: task.startVerse,
            endVerse: task.endVerse,
            occasion: task.occasion,
            recitationContext: task.recitationContext,
            repeatCount: task.repeatCount,
            authenticity: task.authenticity,
            reference: task.reference,
            groupId: task.groupId,
            rakAh: task.rakAh,
            evidence: task.evidence,
            verseSelections: task.verseSelections,

            name: trans ? trans.name : `Surah ${task.surahNumber}`,
            notes: trans ? trans.notes : (task.notes || ''),
            localizedReference: trans ? trans.reference : task.reference,

            surahNameTransliteration: surah ? surah.nameTransliteration : `Surah ${task.surahNumber}`,
            surahNameArabic: surah ? surah.nameArabic : ''
          };

          results.push(merged);
        }
      }

      return results;
    } catch (e) {
      AppLogger.error('QuranService', `Failed to get recommendations: ${JSON.stringify(e)}`);
      return [];
    }
  }

  public static getCachedSurahs(): CompleteSurah[] {
    return QuranService.cachedSurahs;
  }

  private static getScriptForLanguage(lang: string): string {
    if (lang === 'ar') {
      return 'uthmani';
    }
    if (lang === 'id') {
      return 'kemenag';
    }
    return 'indopak';
  }

  /**
   * Returns the translation file path for the current language, or null
   * if no translation exists (e.g. Arabic — the source language).
   */
  private static getTranslationPath(lang: string): string | null {
    if (lang === 'ar') {
      return null;
    } // No Arabic "translation" — Arabic IS the source
    return `quran/translations/quran_${lang}.json`;
  }
}