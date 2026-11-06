// entry/src/main/ets/quran/QuranService.ets

import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { AppLogger } from '../core/AppLogger';
import {
  CompleteSurah,
  LocalizedRecitationInfo,
  RawRecitationTask,
  RecitationTask,
  SurahTranslationInfo
} from './QuranSurahModels';
import { UpcomingCustomEvent } from '../pages/HomePage';

export class QuranService {
  private static cachedSurahs: CompleteSurah[] = [];
  private static cachedLang: string = '';

  static async loadSurahs(context: common.UIAbilityContext, lang: string): Promise<CompleteSurah[]> {
    if (QuranService.cachedSurahs.length > 0 && QuranService.cachedLang === lang) {
      return QuranService.cachedSurahs;
    }

    const mgr = context.resourceManager;
    const script = QuranService.getScriptForLanguage(lang);
    const baseFileName = `quran/scripts/quran_base_${script}.json`;

    // 1. Load Arabic script with fallback to uthmani
    let baseSurahs: CompleteSurah[] = [];
    try {
      const baseData = await mgr.getRawFileContent(baseFileName);
      baseSurahs = JSON.parse(util.TextDecoder.create('utf-8').decodeToString(baseData)) as CompleteSurah[];
      AppLogger.info('QuranService', `Loaded script: ${script} (${baseSurahs.length} surahs)`);
    } catch (e) {
      AppLogger.warn('QuranService', `Failed ${baseFileName}, falling back to uthmani`);
      try {
        const fallback = await mgr.getRawFileContent('quran/scripts/quran_base_uthmani.json');
        baseSurahs = JSON.parse(util.TextDecoder.create('utf-8').decodeToString(fallback)) as CompleteSurah[];
      } catch (e2) {
        AppLogger.error('QuranService', 'Critical: uthmani script missing.');
        return [];
      }
    }

    // 2. Load translation (null path = no translation for this lang)
    let transSurahs: Record<string, SurahTranslationInfo> = {};
    const transFileName = QuranService.getTranslationPath(lang);

    if (transFileName !== null) {
      try {
        const transData = await mgr.getRawFileContent(transFileName);
        transSurahs = JSON.parse(util.TextDecoder.create('utf-8').decodeToString(transData)) as
          Record<string, SurahTranslationInfo>;

        // Sanity check
        const s1 = transSurahs['1'];
        if (s1 && s1.translatedText && s1.translatedText.trim().length > 0) {
          AppLogger.info('QuranService',
            `Translation OK: ${transFileName} (Surah 1 = ${s1.translatedText.length} chars)`);
        } else {
          AppLogger.error('QuranService', `Translation file ${transFileName} has empty Surah 1`);
        }
      } catch (e) {
        AppLogger.warn('QuranService', `Translation ${transFileName} not found.`);
      }
    } else {
      AppLogger.info('QuranService', `Language "${lang}" has no translation (source language).`);
    }

    // 3. Merge
    const merged: CompleteSurah[] = baseSurahs.map((base: CompleteSurah): CompleteSurah => {
      const trans = transSurahs[base.id.toString()];
      const mergedSurah: CompleteSurah = {
        id: base.id,
        nameArabic: base.nameArabic,
        nameTransliteration: base.nameTransliteration,
        revelationPlace: base.revelationPlace,
        ayahCount: base.ayahCount,
        arabicText: base.arabicText,
        nameMeaning: trans ? trans.nameMeaning : base.nameTransliteration,
        translatedText: trans ? trans.translatedText : '',
        isFavorite: false
      };
      return mergedSurah;
    });

    QuranService.cachedSurahs = merged;
    QuranService.cachedLang = lang;
    return merged;
  }

  static async getRecommendedRecitations(
    context: common.UIAbilityContext,
    lang: string,
    isFriday: boolean,
    customEvents: UpcomingCustomEvent[]
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
        if (title.includes('sick') || title.includes('illness') || title.includes('fever')) {
          activeOccasions.push('illness_ruqyah');
        }
        if (title.includes('protect') || title.includes('safe')) {
          activeOccasions.push('home_protection', 'protection_dajjal');
        }
        if (title.includes('eid')) {
          activeOccasions.push('eid_prayer');
        }
      }

      const results: RecitationTask[] = [];
      const seenGroups = new Set<string>();
      const allSurahs = await QuranService.loadSurahs(context, lang);

      for (const task of rawTasks) {
        if (activeOccasions.includes(task.occasion)) {
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

            name: trans ? trans.name : `Surah ${task.surahNumber}`,
            notes: trans ? trans.notes : '',
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