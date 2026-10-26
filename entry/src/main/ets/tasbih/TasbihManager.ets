// entry/src/main/ets/tasbih/TasbihManager.ets

import {
  AddTasbihResult, BeadView, Dhikr, DhikrDayCount, DhikrFields, Tasbih, TasbihDayLog
} from './TasbihModels';
import { TasbihThemes } from './TasbihThemes';

export const MAX_TOP_BEADS = 5;
export const MAX_BOTTOM_BEADS = 5;

/** Rolling history window. Covers a full quarter. */
export const HISTORY_MAX_DAYS = 90;

export class TasbihManager {

  /** Today's date key, matching ProgressHelper.getDateKey format. */
  static todayKey(): string {
    const d = new Date();
    const y = d.getFullYear();
    const m = (d.getMonth() + 1).toString().padStart(2, '0');
    const day = d.getDate().toString().padStart(2, '0');
    return `${y}-${m}-${day}`;
  }

  static generateId(): string {
    return `id_${Date.now()}_${Math.floor(Math.random() * 100000)}`;
  }

  static createDefaults(): Tasbih[] {
    const today = TasbihManager.todayKey();

    const classic: Dhikr[] = [
      {
        id: TasbihManager.generateId(),
        arabic: 'سُبْحَانَ ٱللَّٰهِ',
        transliteration: 'SubhanAllah',
        translation: 'Glory be to Allah',
        transliterationKey: 'dhikr_subhanallah_translit',
        translationKey: 'dhikr_subhanallah_trans',
        target: 33,
        count: 0,
        lastCountDate: today,
        dailyTotal: 0
      },
      {
        id: TasbihManager.generateId(),
        arabic: 'ٱلْحَمْدُ لِلَّٰهِ',
        transliteration: 'Alhamdulillah',
        translation: 'All praise is for Allah',
        transliterationKey: 'dhikr_alhamdulillah_translit',
        translationKey: 'dhikr_alhamdulillah_trans',
        target: 33,
        count: 0,
        lastCountDate: today,
        dailyTotal: 0
      },
      {
        id: TasbihManager.generateId(),
        arabic: 'ٱللَّٰهُ أَكْبَرُ',
        transliteration: 'Allahu Akbar',
        translation: 'Allah is the Greatest',
        transliterationKey: 'dhikr_allahuakbar_translit',
        translationKey: 'dhikr_allahuakbar_trans',
        target: 34,
        count: 0,
        lastCountDate: today,
        dailyTotal: 0
      }
    ];
    const tahlil: Dhikr[] = [
      {
        id: TasbihManager.generateId(),
        arabic: 'لَا إِلَٰهَ إِلَّا ٱللَّٰهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ ٱلْمُلْكُ وَلَهُ ٱلْحَمْدُ',
        transliteration: 'La ilaha illallahu wahdahu la sharika lah',
        translation: 'There is no god but Allah, alone, without partner',
        transliterationKey: 'dhikr_tahlil_translit',
        translationKey: 'dhikr_tahlil_trans',
        target: 100,
        count: 0,
        lastCountDate: today,
        dailyTotal: 0
      }
    ];
    const istighfar: Dhikr[] = [
      {
        id: TasbihManager.generateId(),
        arabic: 'أَسْتَغْفِرُ ٱللَّٰهَ',
        transliteration: 'Astaghfirullah',
        translation: 'I seek forgiveness from Allah',
        transliterationKey: 'dhikr_istighfar_translit',
        translationKey: 'dhikr_istighfar_trans',
        target: 100,
        count: 0,
        lastCountDate: today,
        dailyTotal: 0
      }
    ];

    const out: Tasbih[] = [
      {
        id: TasbihManager.generateId(),
        name: 'Classic 33',
        nameKey: 'tasbih_default_classic_name',
        createdAt: Date.now(),
        dhikrs: classic,
        lifetimeCount: 0,
        themePresetId: 'amber',
        history: []
      },
      {
        id: TasbihManager.generateId(),
        name: 'Tahlil 100',
        nameKey: 'tasbih_default_tahlil_name',
        createdAt: Date.now() + 1,
        dhikrs: tahlil,
        lifetimeCount: 0,
        themePresetId: 'emerald',
        history: []
      },
      {
        id: TasbihManager.generateId(),
        name: 'Istighfar',
        nameKey: 'tasbih_default_istighfar_name',
        createdAt: Date.now() + 2,
        dhikrs: istighfar,
        lifetimeCount: 0,
        themePresetId: 'pearl',
        history: []
      }
    ];
    return out;
  }

  static findTasbih(tasbihs: Tasbih[], id: string): Tasbih | null {
    const found = tasbihs.find((t): boolean => t.id === id);
    return found ? found : null;
  }

  static getActiveDhikr(
    tasbihs: Tasbih[], activeTasbihId: string, index: number
  ): Dhikr | null {
    const t = TasbihManager.findTasbih(tasbihs, activeTasbihId);
    if (!t || t.dhikrs.length === 0) {
      return null;
    }
    const safeIdx = Math.min(index, t.dhikrs.length - 1);
    return t.dhikrs[safeIdx];
  }

  static computeBeadView(dhikr: Dhikr | null): BeadView {
    if (!dhikr) {
      const empty: BeadView = {
        topIds: [],
        bottomIds: [],
        isComplete: false,
        topAtCap: false,
        bottomAtCap: false
      };
      return empty;
    }

    const isComplete = dhikr.count >= dhikr.target;
    const topCount = Math.min(Math.max(0, dhikr.count), MAX_TOP_BEADS);
    const bottomCount = Math.min(
      Math.max(0, dhikr.target - dhikr.count), MAX_BOTTOM_BEADS
    );

    const topIds: number[] = [];
    for (let i = 0; i < topCount; i++) {
      topIds.push(i);
    }

    const bottomIds: number[] = [];
    for (let i = 0; i < bottomCount; i++) {
      bottomIds.push(i);
    }

    const view: BeadView = {
      topIds: topIds,
      bottomIds: bottomIds,
      isComplete: isComplete,
      topAtCap: topCount === MAX_TOP_BEADS,
      bottomAtCap: bottomCount === MAX_BOTTOM_BEADS
    };
    return view;
  }

  // ============================================================
  // COUNTING
  // ============================================================

  static increment(
    tasbihs: Tasbih[], activeId: string, dhikrId: string
  ): Tasbih[] {
    return TasbihManager.mutateDhikr(
      tasbihs, activeId, dhikrId, 1, (d: Dhikr): Dhikr => {
      const next: Dhikr = {
        id: d.id,
        arabic: d.arabic,
        transliteration: d.transliteration,
        translation: d.translation,
        target: d.target,
        count: d.count + 1,
        lastCountDate: d.lastCountDate,
        dailyTotal: (d.dailyTotal ?? d.count) + 1
      };
      return next;
    });
  }

  static decrement(
    tasbihs: Tasbih[], activeId: string, dhikrId: string
  ): Tasbih[] {
    return TasbihManager.mutateDhikr(
      tasbihs, activeId, dhikrId, 0, (d: Dhikr): Dhikr => {
      const currentTotal = d.dailyTotal ?? d.count;
      const next: Dhikr = {
        id: d.id,
        arabic: d.arabic,
        transliteration: d.transliteration,
        translation: d.translation,
        target: d.target,
        count: d.count > 0 ? d.count - 1 : 0,
        lastCountDate: d.lastCountDate,
        dailyTotal: Math.max(0, currentTotal - 1)
      };
      return next;
    });
  }

  /**
   * Clear the live counter for one dhikr.
   * Only `count` is reset. `dailyTotal`, `lifetimeCount`, and the
   * rolling history are preserved, so a completion logged earlier
   * today is not undone by starting a new round.
   */
  static reset(
    tasbihs: Tasbih[], activeId: string, dhikrId: string
  ): Tasbih[] {
    const today = TasbihManager.todayKey();

    return tasbihs.map((t: Tasbih): Tasbih => {
      if (t.id !== activeId) {
        return t;
      }

      const dhikrs: Dhikr[] = t.dhikrs.map((d: Dhikr): Dhikr => {
        if (d.id !== dhikrId) {
          return d;
        }
        // Preserve the total accumulated today
        const preservedTotal = d.dailyTotal ?? d.count;
        const cleared: Dhikr = {
          id: d.id,
          arabic: d.arabic,
          transliteration: d.transliteration,
          translation: d.translation,
          target: d.target,
          count: 0,
          lastCountDate: today,
          dailyTotal: preservedTotal
        };
        return cleared;
      });

      const result: Tasbih = {
        id: t.id,
        name: t.name,
        nameKey: t.nameKey,
        dhikrs: dhikrs,
        createdAt: t.createdAt,
        lifetimeCount: t.lifetimeCount, // Preserved
        theme: t.theme,
        themePresetId: t.themePresetId,
        history: t.history // Preserved
      };
      return result;
    });
  }

  /**
   * Clear every dhikr's live counter within the active tasbih.
   * Same semantics as reset() — `dailyTotal`, `lifetimeCount`, and
   * history are preserved.
   */
  static resetAll(tasbihs: Tasbih[], activeId: string): Tasbih[] {
    const today = TasbihManager.todayKey();

    return tasbihs.map((t: Tasbih): Tasbih => {
      if (t.id !== activeId) {
        return t;
      }

      const dhikrs: Dhikr[] = t.dhikrs.map((d: Dhikr): Dhikr => {
        const preservedTotal = d.dailyTotal ?? d.count;
        const cleared: Dhikr = {
          id: d.id,
          arabic: d.arabic,
          transliteration: d.transliteration,
          translation: d.translation,
          target: d.target,
          count: 0,
          lastCountDate: today,
          dailyTotal: preservedTotal
        };
        return cleared;
      });

      const result: Tasbih = {
        id: t.id,
        name: t.name,
        nameKey: t.nameKey,
        dhikrs: dhikrs,
        createdAt: t.createdAt,
        lifetimeCount: t.lifetimeCount, // Preserved
        theme: t.theme,
        themePresetId: t.themePresetId,
        history: t.history // Preserved
      };
      return result;
    });
  }

  // ============================================================
  // TASBIH CRUD
  // ============================================================

  static addTasbih(
    tasbihs: Tasbih[], name: string, themePresetId: string
  ): AddTasbihResult {
    const presetId = themePresetId.length > 0
      ? themePresetId
      : TasbihThemes.DEFAULT_PRESET_ID;
    const newTasbih: Tasbih = {
      id: TasbihManager.generateId(),
      name: name,
      dhikrs: [],
      createdAt: Date.now(),
      lifetimeCount: 0,
      theme: TasbihThemes.themeForPreset(presetId),
      themePresetId: presetId,
      history: []
    };
    const result: AddTasbihResult = {
      tasbihs: [...tasbihs, newTasbih],
      newId: newTasbih.id
    };
    return result;
  }

  static renameTasbih(
    tasbihs: Tasbih[],
    id: string,
    name: string,
    themePresetId: string
  ): Tasbih[] {
    return tasbihs.map((t: Tasbih): Tasbih => {
      if (t.id !== id) {
        return t;
      }
      const presetId = themePresetId.length > 0
        ? themePresetId
        : (t.themePresetId ?? TasbihThemes.DEFAULT_PRESET_ID);

      const updated: Tasbih = {
        id: t.id,
        name: name,
        nameKey: undefined, // Cleared because the user renamed it manually
        dhikrs: t.dhikrs,
        createdAt: t.createdAt,
        lifetimeCount: t.lifetimeCount,
        theme: TasbihThemes.themeForPreset(presetId),
        themePresetId: presetId,
        history: t.history
      };
      return updated;
    });
  }

  static updateDhikr(
    tasbihs: Tasbih[], activeId: string,
    dhikrId: string, fields: DhikrFields
  ): Tasbih[] {
    return tasbihs.map((t: Tasbih): Tasbih => {
      if (t.id !== activeId) {
        return t;
      }
      const updated: Dhikr[] = t.dhikrs.map((d: Dhikr): Dhikr => {
        if (d.id !== dhikrId) {
          return d;
        }
        const next: Dhikr = {
          id: d.id,
          arabic: fields.arabic,
          transliteration: fields.transliteration,
          translation: fields.translation,
          transliterationKey: undefined, // Cleared because user edited
          translationKey: undefined, // Cleared because user edited
          target: fields.target,
          count: d.count,
          lastCountDate: d.lastCountDate,
          dailyTotal: d.dailyTotal
        };
        return next;
      });
      const result: Tasbih = {
        id: t.id,
        name: t.name,
        nameKey: t.nameKey,
        dhikrs: updated,
        createdAt: t.createdAt,
        lifetimeCount: t.lifetimeCount,
        theme: t.theme,
        themePresetId: t.themePresetId,
        history: t.history
      };
      return result;
    });
  }

  static setTheme(
    tasbihs: Tasbih[], id: string, themePresetId: string
  ): Tasbih[] {
    return tasbihs.map((t: Tasbih): Tasbih => {
      if (t.id !== id) {
        return t;
      }
      const updated: Tasbih = {
        id: t.id,
        name: t.name,
        dhikrs: t.dhikrs,
        createdAt: t.createdAt,
        lifetimeCount: t.lifetimeCount,
        theme: TasbihThemes.themeForPreset(themePresetId),
        themePresetId: themePresetId,
        history: t.history
      };
      return updated;
    });
  }

  static removeTasbih(tasbihs: Tasbih[], id: string): Tasbih[] {
    if (tasbihs.length <= 1) {
      return tasbihs;
    }
    return tasbihs.filter((t: Tasbih): boolean => t.id !== id);
  }

  // ============================================================
  // DHIKR CRUD
  // ============================================================

  static addDhikr(
    tasbihs: Tasbih[], activeId: string, fields: DhikrFields
  ): Tasbih[] {
    const today = TasbihManager.todayKey();
    const newDhikr: Dhikr = {
      id: TasbihManager.generateId(),
      arabic: fields.arabic,
      transliteration: fields.transliteration,
      translation: fields.translation,
      target: fields.target,
      count: 0,
      lastCountDate: today,
      dailyTotal: 0
    };
    return tasbihs.map((t: Tasbih): Tasbih => {
      if (t.id !== activeId) {
        return t;
      }
      const updated: Tasbih = {
        id: t.id,
        name: t.name,
        dhikrs: [...t.dhikrs, newDhikr],
        createdAt: t.createdAt,
        lifetimeCount: t.lifetimeCount,
        theme: t.theme,
        themePresetId: t.themePresetId,
        history: t.history
      };
      return updated;
    });
  }

  static removeDhikr(
    tasbihs: Tasbih[], activeId: string, dhikrId: string
  ): Tasbih[] {
    return tasbihs.map((t: Tasbih): Tasbih => {
      if (t.id !== activeId) {
        return t;
      }
      const filtered: Dhikr[] = t.dhikrs.filter(
        (d: Dhikr): boolean => d.id !== dhikrId
      );
      const result: Tasbih = {
        id: t.id,
        name: t.name,
        dhikrs: filtered,
        createdAt: t.createdAt,
        lifetimeCount: t.lifetimeCount,
        theme: t.theme,
        themePresetId: t.themePresetId,
        history: t.history
      };
      return result;
    });
  }

  // ============================================================
  // NORMALIZATION — call once at load time
  // ============================================================

  /**
   * Roll any dhikr whose lastCountDate is stale into history and
   * reset the live counters. Also seeds dailyTotal and
   * lastCountDate for data written by versions before they
   * existed.
   */
  static rollOverStaleCounts(tasbihs: Tasbih[]): Tasbih[] {
    const today = TasbihManager.todayKey();
    let anyChanged = false;

    const out = tasbihs.map((t: Tasbih): Tasbih => {
      let history: TasbihDayLog[] = t.history !== undefined
        ? t.history : [];
      let changed = false;

      const dhikrs: Dhikr[] = t.dhikrs.map((d: Dhikr): Dhikr => {
        // ---- Migration: seed missing fields ----
        if (d.lastCountDate === undefined) {
          changed = true;
          const seeded: Dhikr = {
            id: d.id,
            arabic: d.arabic,
            transliteration: d.transliteration,
            translation: d.translation,
            target: d.target,
            count: d.count,
            lastCountDate: today,
            dailyTotal: d.dailyTotal ?? d.count
          };
          return seeded;
        }

        if (d.dailyTotal === undefined) {
          changed = true;
          const seeded: Dhikr = {
            id: d.id,
            arabic: d.arabic,
            transliteration: d.transliteration,
            translation: d.translation,
            target: d.target,
            count: d.count,
            lastCountDate: d.lastCountDate,
            dailyTotal: d.count
          };
          return seeded;
        }

        if (d.lastCountDate === today) {
          return d;
        }

        // ---- Stale: roll the day's total into history, reset ----
        changed = true;
        if (d.dailyTotal > 0) {
          history = TasbihManager.upsertHistory(
            history, d.lastCountDate, d.id, d.dailyTotal
          );
        }
        const reset: Dhikr = {
          id: d.id,
          arabic: d.arabic,
          transliteration: d.transliteration,
          translation: d.translation,
          target: d.target,
          count: 0,
          lastCountDate: today,
          dailyTotal: 0
        };
        return reset;
      });

      if (!changed && t.history !== undefined) {
        return t;
      }
      anyChanged = true;

      const result: Tasbih = {
        id: t.id,
        name: t.name,
        dhikrs: dhikrs,
        createdAt: t.createdAt,
        lifetimeCount: t.lifetimeCount,
        theme: t.theme,
        themePresetId: t.themePresetId,
        history: TasbihManager.trimHistory(history)
      };
      return result;
    });

    return anyChanged ? out : tasbihs;
  }

  // ============================================================
  // INTERNAL
  // ============================================================

  private static mutateDhikr(
    tasbihs: Tasbih[],
    activeId: string,
    dhikrId: string,
    lifetimeDelta: number,
    fn: (d: Dhikr) => Dhikr
  ): Tasbih[] {
    const today = TasbihManager.todayKey();

    return tasbihs.map((t: Tasbih): Tasbih => {
      if (t.id !== activeId) {
        return t;
      }

      let history: TasbihDayLog[] = t.history !== undefined
        ? t.history : [];
      let dhikrChanged = false;

      const updated: Dhikr[] = t.dhikrs.map((d: Dhikr): Dhikr => {
        if (d.id !== dhikrId) {
          return d;
        }
        dhikrChanged = true;

        // ---- Day rollover before applying the change ----
        let baseDhikr = d;
        if (d.lastCountDate !== undefined && d.lastCountDate !== today) {
          const dayTotal = d.dailyTotal ?? d.count;
          if (dayTotal > 0) {
            history = TasbihManager.upsertHistory(
              history, d.lastCountDate, d.id, dayTotal
            );
          }
          baseDhikr = {
            id: d.id,
            arabic: d.arabic,
            transliteration: d.transliteration,
            translation: d.translation,
            target: d.target,
            count: 0,
            lastCountDate: today,
            dailyTotal: 0
          };
        } else if (d.lastCountDate === undefined) {
          // First touch after upgrade — seed today.
          baseDhikr = {
            id: d.id,
            arabic: d.arabic,
            transliteration: d.transliteration,
            translation: d.translation,
            target: d.target,
            count: d.count,
            lastCountDate: today,
            dailyTotal: d.dailyTotal ?? d.count
          };
        }

        const afterFn: Dhikr = fn(baseDhikr);

        // ---- Record the day's running total ----
        const dayTotal = afterFn.dailyTotal ?? afterFn.count;
        history = TasbihManager.upsertHistory(
          history, today, d.id, dayTotal
        );

        return afterFn;
      });

      if (!dhikrChanged) {
        return t;
      }

      const result: Tasbih = {
        id: t.id,
        name: t.name,
        dhikrs: updated,
        createdAt: t.createdAt,
        lifetimeCount: (t.lifetimeCount || 0) + lifetimeDelta,
        theme: t.theme,
        themePresetId: t.themePresetId,
        history: TasbihManager.trimHistory(history)
      };
      return result;
    });
  }

  private static upsertHistory(
    history: TasbihDayLog[],
    dateKey: string,
    dhikrId: string,
    count: number
  ): TasbihDayLog[] {
    const out: TasbihDayLog[] = [];
    let found = false;

    for (const log of history) {
      if (log.dateKey === dateKey) {
        let dhikrFound = false;
        const updated: DhikrDayCount[] = log.dhikrCounts.map(
          (dc: DhikrDayCount): DhikrDayCount => {
            if (dc.dhikrId === dhikrId) {
              dhikrFound = true;
              return { dhikrId: dhikrId, count: count };
            }
            return dc;
          }
        );
        if (!dhikrFound) {
          updated.push({ dhikrId: dhikrId, count: count });
        }
        out.push({ dateKey: dateKey, dhikrCounts: updated });
        found = true;
      } else {
        out.push(log);
      }
    }

    if (!found) {
      const dhikrCounts: DhikrDayCount[] = [
        { dhikrId: dhikrId, count: count }
      ];
      out.push({ dateKey: dateKey, dhikrCounts: dhikrCounts });
    }
    return out;
  }

  private static trimHistory(history: TasbihDayLog[]): TasbihDayLog[] {
    if (history.length <= HISTORY_MAX_DAYS) {
      return history;
    }
    const sorted = history.slice().sort(
      (a: TasbihDayLog, b: TasbihDayLog): number => {
        return a.dateKey < b.dateKey ? 1 : (a.dateKey > b.dateKey ? -1 : 0);
      }
    );
    return sorted.slice(0, HISTORY_MAX_DAYS);
  }
}