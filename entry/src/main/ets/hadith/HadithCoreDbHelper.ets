// entry/src/main/ets/hadith/HadithCoreDbHelper.ets

import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { AppLogger } from '../core/app/AppLogger';
import { HadithGrading, Sanad, SanadStep } from './HadithModels';

export class HadithCoreDbHelper {
  private static store: relationalStore.RdbStore | null = null;

  static async open(context: common.Context): Promise<boolean> {
    if (HadithCoreDbHelper.store !== null) {
      return true;
    }
    try {
      const config: relationalStore.StoreConfig = {
        name: 'core.db',
        securityLevel: relationalStore.SecurityLevel.S1,
        customDir: 'core',
        isReadOnly: true
      };
      HadithCoreDbHelper.store = await relationalStore.getRdbStore(context, config);
      return true;
    } catch (e) {
      AppLogger.error('HadithCoreDbHelper', `open failed: ${(e as Error).message}`);
      return false;
    }
  }

  static async getSanad(context: common.Context, hadithId: string): Promise<Sanad | null> {
    const ok = await HadithCoreDbHelper.open(context);
    if (!ok || HadithCoreDbHelper.store === null) {
      return null;
    }

    // 👇 FIX: Normalize the ID before querying
    const canonicalId = HadithCoreDbHelper.normalizeId(hadithId);

    try {
      const metaRs = await HadithCoreDbHelper.store.querySql(
        'SELECT sanad_ar, sanad_normalized, sanad_confidence FROM hadiths WHERE hadith_id = ?',
        [canonicalId] // 👈 Use canonicalId
      );
      let arabic: string | null = null;
      let normalized: string | null = null;
      let confidence: string = 'none';
      if (metaRs.goToFirstRow()) {
        arabic = metaRs.getString(0);
        normalized = metaRs.getString(1);
        confidence = metaRs.getString(2) ?? 'none';
      }
      metaRs.close();

      // Hide sanad entirely when confidence = 'none'
      if (confidence === 'none') {
        return {
          arabic: null,
          normalized: null,
          confidence: 'none',
          steps: []
        };
      }

      const stepsRs = await HadithCoreDbHelper.store.querySql(
        'SELECT hn.position, n.narrator_id, n.name_ar, n.name_en, ' +
          'n.generation, n.reliability, n.death_hijri, n.auto_derived ' +
          'FROM hadith_narrators hn JOIN narrators n ON n.narrator_id = hn.narrator_id ' +
          'WHERE hn.hadith_id = ? ORDER BY hn.position',
        [canonicalId] // 👈 Use canonicalId
      );
      const steps: SanadStep[] = [];
      while (stepsRs.goToNextRow()) {
        const step: SanadStep = {
          position: stepsRs.getLong(0),
          narrator_id: stepsRs.getString(1) ?? '',
          name_ar: stepsRs.getString(2) ?? '',
          name_en: stepsRs.getString(3),
          generation: stepsRs.getString(4),
          reliability: stepsRs.getString(5),
          death_hijri: stepsRs.getLong(6) > 0 ? stepsRs.getLong(6) : null,
          auto_derived: stepsRs.getLong(7)
        };
        steps.push(step);
      }
      stepsRs.close();

      return {
        arabic,
        normalized,
        confidence,
        steps
      };
    } catch (e) {
      AppLogger.warn('HadithCoreDbHelper', `getSanad(${hadithId}): ${(e as Error).message}`);
      return null;
    }
  }

  static async getGrades(context: common.Context, hadithId: string): Promise<HadithGrading[]> {
    const ok = await HadithCoreDbHelper.open(context);
    if (!ok || HadithCoreDbHelper.store === null) {
      return [];
    }

    // 👇 FIX: Normalize the ID before querying
    const canonicalId = HadithCoreDbHelper.normalizeId(hadithId);

    try {
      const rs = await HadithCoreDbHelper.store.querySql(
        "SELECT grade, grader, source, grade_type, note " +
          "FROM hadith_gradings WHERE hadith_id = ? " +
          "ORDER BY CASE grade " +
          "  WHEN 'sahih' THEN 1 WHEN 'hasan' THEN 2 " +
          "  WHEN 'daif' THEN 3 WHEN 'mawdu' THEN 4 ELSE 5 END",
        [canonicalId] // 👈 Use canonicalId
      );
      const out: HadithGrading[] = [];
      while (rs.goToNextRow()) {
        out.push({
          grade: rs.getString(0) ?? '',
          grader: rs.getString(1) ?? '',
          source: rs.getString(2) ?? '',
          gradeType: rs.getString(3) ?? 'overall',
          note: rs.getString(4)
        });
      }
      rs.close();
      return out;
    } catch (e) {
      AppLogger.warn('HadithCoreDbHelper', `getGrades(${hadithId}): ${(e as Error).message}`);
      return [];
    }
  }

  /**
   * Normalizes an ID from the language DB (e.g., 'eng-bukhari:1' or 'urd-bukh:1')
   * into the canonical format used by core.db (e.g., 'bukhari:1').
   */
  private static normalizeId(rawId: string): string {
    let baseId = rawId;
    // Strip language prefix (e.g., "eng-", "urd-", "ara-")
    if (baseId.includes('-')) {
      baseId = baseId.substring(baseId.indexOf('-') + 1);
    }
    // Expand collection alias
    const parts = baseId.split(':');
    if (parts.length === 2) {
      const col = parts[0].toLowerCase();
      const num = parts[1];
      if (col === 'bukh') {
        return `bukhari:${num}`;
      }
      if (col === 'musl') {
        return `muslim:${num}`;
      }
      if (col === 'abud') {
        return `abudawud:${num}`;
      }
      if (col === 'tirm') {
        return `tirmidhi:${num}`;
      }
      if (col === 'nasa') {
        return `nasai:${num}`;
      }
      if (col === 'ibnm') {
        return `ibnmajah:${num}`;
      }
      if (col === 'mali') {
        return `malik:${num}`;
      }
    }
    return baseId;
  }
}