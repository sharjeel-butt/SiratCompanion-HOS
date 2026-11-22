import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import { util } from '@kit.ArkTS';
import { AppLogger } from '../core/app/AppLogger';
import { RawPaths } from '../core/common/RawPaths';
import {
  CompleteSurah, LocalizedRecitationInfo, RawRecitationTask, RecitationTask, Verse
} from './QuranSurahModels';
import { UpcomingCustomEvent } from '../pages/HomePage';

export class QuranService {
  private static db: relationalStore.RdbStore | null = null;
  private static cachedSurahs: CompleteSurah[] = [];
  private static cachedLang: string = '';
  private static surahCache: Map<number, CompleteSurah> = new Map();

  // ---- DB open ----
  static async openDatabase(context: common.UIAbilityContext): Promise<boolean> {
    if (QuranService.db !== null) {
      return true;
    }
    try {
      const config: relationalStore.StoreConfig = {
        name: 'quran.db',
        securityLevel: relationalStore.SecurityLevel.S1,
        customDir: 'quran',
        isReadOnly: true
      };
      QuranService.db = await relationalStore.getRdbStore(context, config);
      return true;
    } catch (e) {
      AppLogger.error('QuranService', `Failed to open quran.db: ${(e as Error).message}`);
      return false;
    }
  }

  // ---- Metadata-only surah list (fast) ----
  static async loadSurahs(context: common.UIAbilityContext, lang: string): Promise<CompleteSurah[]> {
    if (QuranService.cachedSurahs.length > 0 && QuranService.cachedLang === lang) {
      return QuranService.cachedSurahs;
    }
    const ok = await QuranService.openDatabase(context);
    if (!ok || QuranService.db === null) {
      return [];
    }

    try {
      const rs = await QuranService.db.querySql(
        'SELECT number, name_arabic, name_transliteration, revelation_place, ayah_count ' +
          'FROM surahs ORDER BY number'
      );
      const surahs: CompleteSurah[] = [];
      while (rs.goToNextRow()) {
        const s: CompleteSurah = {
          id: rs.getLong(0),
          nameArabic: rs.getString(1) ?? '',
          nameTransliteration: rs.getString(2) ?? '',
          revelationPlace: rs.getString(3) ?? '',
          ayahCount: rs.getLong(4),
          verses: [],
          isFavorite: false
        };
        surahs.push(s);
      }
      rs.close();
      QuranService.cachedSurahs = surahs;
      QuranService.cachedLang = lang;
      return surahs;
    } catch (e) {
      AppLogger.error('QuranService', `loadSurahs failed: ${(e as Error).message}`);
      return [];
    }
  }

  // ---- Single surah with full verses ----
  static async loadSurah(
    context: common.UIAbilityContext, surahId: number, lang: string
  ): Promise<CompleteSurah | null> {
    const cached = QuranService.surahCache.get(surahId);
    if (cached && cached.verses.length > 0) {
      return cached;
    }

    const ok = await QuranService.openDatabase(context);
    if (!ok || QuranService.db === null) {
      return null;
    }

    try {
      // Metadata
      const metaRs = await QuranService.db.querySql(
        'SELECT number, name_arabic, name_transliteration, revelation_place, ayah_count ' +
          'FROM surahs WHERE number = ?',
        [surahId]
      );
      if (!metaRs.goToFirstRow()) {
        metaRs.close();
        return null;
      }
      const meta: CompleteSurah = {
        id: metaRs.getLong(0),
        nameArabic: metaRs.getString(1) ?? '',
        nameTransliteration: metaRs.getString(2) ?? '',
        revelationPlace: metaRs.getString(3) ?? '',
        ayahCount: metaRs.getLong(4),
        verses: [],
        isFavorite: false
      };
      metaRs.close();

      // Verses
      const versesRs = await QuranService.db.querySql(
        'SELECT ayah_number, arabic FROM verses WHERE surah_number = ? ORDER BY ayah_number',
        [surahId]
      );
      const verseMap: Map<number, Verse> = new Map();
      while (versesRs.goToNextRow()) {
        const ayah = versesRs.getLong(0);
        const v: Verse = {
          ayah,
          arabic: versesRs.getString(1) ?? '',
          translations: {}
        };
        verseMap.set(ayah, v);
      }
      versesRs.close();

      // Translations — skip 'ar' (Arabic lives in verses.arabic)
      const langs: string[] = ['en', 'ur', 'tr', 'bn', 'id', 'zh'];
      for (const l of langs) {
        const tRs = await QuranService.db.querySql(
          'SELECT ayah_number, text FROM translations WHERE surah_number = ? AND lang = ?',
          [surahId, l]
        );
        while (tRs.goToNextRow()) {
          const ayah = tRs.getLong(0);
          const text = tRs.getString(1) ?? '';
          const v = verseMap.get(ayah);
          if (v !== undefined) {
            v.translations[l] = text;
          }
        }
        tRs.close();
      }

      const verses: Verse[] = [];
      const ayahs: number[] = [];
      verseMap.forEach((_v, k) => ayahs.push(k));
      ayahs.sort((a, b) => a - b);
      for (const a of ayahs) {
        const v = verseMap.get(a);
        if (v !== undefined) {
          verses.push(v);
        }
      }
      meta.verses = verses;

      QuranService.surahCache.set(surahId, meta);
      return meta;
    } catch (e) {
      AppLogger.error('QuranService', `loadSurah(${surahId}) failed: ${(e as Error).message}`);
      return null;
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
      const rawData = await mgr.getRawFileContent(RawPaths.QURAN_RECITATIONS_RAW);
      const rawTasks = JSON.parse(util.TextDecoder.create('utf-8').decodeToString(rawData)) as RawRecitationTask[];

      const enData = await mgr.getRawFileContent(RawPaths.quranRecitations('en'));
      const englishLoc =
        JSON.parse(util.TextDecoder.create('utf-8').decodeToString(enData)) as Record<string, LocalizedRecitationInfo>;

      let targetLoc: Record<string, LocalizedRecitationInfo> = {};
      if (lang === 'en') {
        targetLoc = englishLoc;
      } else {
        try {
          const langData = await mgr.getRawFileContent(RawPaths.quranRecitations(lang));
          targetLoc = JSON.parse(util.TextDecoder.create('utf-8').decodeToString(langData)) as
            Record<string, LocalizedRecitationInfo>;
        } catch (e) {
          targetLoc = {};
        }
      }

      const activeOccasions: string[] = ['general_virtue'];
      const hour = new Date().getHours();

      if (hour >= 4 && hour < 12) {
        activeOccasions.push('morning_evening', 'fajr_prayer', 'fajr_sunnah');
      }
      if (hour >= 12 && hour < 16) {
        activeOccasions.push('dhuhr_prayer');
      }
      if (hour >= 16 && hour < 19) {
        activeOccasions.push('maghrib_prayer');
      }
      if (hour >= 19 || hour < 4) {
        activeOccasions.push('bedtime', 'night', 'witr_prayer');
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
}