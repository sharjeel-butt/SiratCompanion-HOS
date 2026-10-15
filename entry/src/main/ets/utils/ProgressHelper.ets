// entry/src/main/ets/utils/ProgressHelper.ets

import { Tasbih } from '../tasbih/TasbihModels';
import { PrayerCheckState, PrayerManager } from '../prayer/PrayerManager';
import { L } from '../helper/LocalizationHelper';

export interface PrayerProgress {
  todayCompleted: number; // 0–5
  todayTotal: number; // always 5
  /** Which specific prayers are checked today. */
  todayFajr: boolean;
  todayDhuhr: boolean;
  todayAsr: boolean;
  todayMaghrib: boolean;
  todayIsha: boolean;
  currentStreak: number;
  bestStreak: number;
  weeklyGrid: boolean[];
  weeklyLabels: string[];
  weekCompleted: number;
  monthCompleted: number;
  yearCompleted: number;
}

export interface WeekDetailCell {
  dateKey: string;
  dayOfWeek: number; // 0 = Sunday
  dayOfMonth: number;
  isToday: boolean;
  completed: number; // 0–5
}

export interface YearMonthRow {
  monthIndex: number; // 0 = January
  daysInMonth: number;

  /**
   * Per-day completion count. Length = daysInMonth, index 0 = day 1.
   * A value of -1 marks a day still in the future.
   */
  completed: number[];
  isFuture: boolean; // the entire month is ahead of today
  totalCompleted: number;
}

export interface YearDetailSnapshot {
  year: number;
  months: YearMonthRow[];
  totalCompleted: number;
}

export interface TasbihProgress {
  totalTasbihs: number;
  totalDhikrs: number;
  lifetimeCount: number;
  completedDhikrs: number;
}

interface PrayerDayState {
  fajr: boolean;
  dhuhr: boolean;
  asr: boolean;
  maghrib: boolean;
  isha: boolean;
}

/** One cell in the monthly heatmap grid. */
export interface MonthDayCell {
  /** 1–31 for real days; 0 for the leading/trailing padding cells. */
  dayOfMonth: number;
  isToday: boolean;
  isFuture: boolean;
  isPadding: boolean;
  completed: number; // 0–5
}

/** Full month view: flat cells + the same data chunked into weeks. */
export interface MonthProgress {
  year: number;
  monthIndex: number; // 0 = January
  cells: MonthDayCell[]; // length is a multiple of 7
  weeks: MonthDayCell[][]; // chunked into 7-cell rows
  totalCompleted: number;
  perfectDays: number; // days with 5/5
  daysElapsed: number; // days up to and including today
  daysInMonth: number;
}

// ============================================================
// PRAYER DETAILS SNAPSHOT
// ============================================================

export interface PerPrayerCount {
  fajr: number;
  dhuhr: number;
  asr: number;
  maghrib: number;
  isha: number;
}

export interface PrayerDetailsSnapshot {
  weekPerPrayer: PerPrayerCount;
  monthPerPrayer: PerPrayerCount;
  yearPerPrayer: PerPrayerCount;
  weekTotal: number;
  weekPossible: number;
  monthTotal: number;
  monthPossible: number;
  yearTotal: number;
  yearPossible: number;
  currentStreak: number;
  bestStreak: number;
  monthProgress: MonthProgress;
}

// ============================================================
// TASBIH PROGRESS SNAPSHOTS
// ============================================================

/** Today's dhikr completion across all tasbihs. */
export interface TasbihTodayProgress {
  dhikrsCompleted: number;
  dhikrsTotal: number;
  percent: number;
  totalTasbihs: number;
  lifetimeCount: number;
}

export type TasbihPeriod = 'week' | 'month' | 'year';

/** One dhikr's progress within a tasbih, for the selected period. */
export interface TasbihDhikrProgress {
  dhikrId: string;
  dhikrLabel: string;
  target: number;
  daysCompleted: number;
  daysInPeriod: number;
  totalCount: number;
}

/** One tasbih's progress, with a row per dhikr. */
export interface TasbihProgressRow {
  tasbihId: string;
  tasbihName: string;
  themePresetId: string;
  isActive: boolean;
  perDhikr: TasbihDhikrProgress[];
  totalDaysCompleted: number;
  totalDaysPossible: number;
}

export interface TasbihDetailsSnapshot {
  rows: TasbihProgressRow[];
  totalDaysCompleted: number;
  totalDaysPossible: number;
  totalCountInPeriod: number;
  daysInPeriod: number;
}

export class ProgressHelper {
  static getDateKey(d: Date): string {
    const y = d.getFullYear();
    const m = (d.getMonth() + 1).toString().padStart(2, '0');
    const day = d.getDate().toString().padStart(2, '0');
    return `${y}-${m}-${day}`;
  }

  static countCompleted(state: PrayerDayState): number {
    let n = 0;
    if (state.fajr) {
      n++;
    }
    if (state.dhuhr) {
      n++;
    }
    if (state.asr) {
      n++;
    }
    if (state.maghrib) {
      n++;
    }
    if (state.isha) {
      n++;
    }
    return n;
  }

  /**
   * Read a day's prayer check state.
   *
   * Delegates to PrayerManager's in-memory map — the single source
   * of truth. This is fully synchronous and always reflects the
   * latest writes from the Prayers page.
   */
  static readState(dateKey: string): PrayerDayState {
    const state: PrayerCheckState = PrayerManager.getCheckState(dateKey);
    const result: PrayerDayState = {
      fajr: state.fajr === true,
      dhuhr: state.dhuhr === true,
      asr: state.asr === true,
      maghrib: state.maghrib === true,
      isha: state.isha === true
    };
    return result;
  }

  // ============================================================
  // PRAYER PROGRESS — HOME CARD
  // ============================================================

  static getPrayerProgress(lang: string = 'en'): PrayerProgress {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const dayLabels: string[] = L.getArray('days_of_week_short', lang);

    const todayState = ProgressHelper.readState(
      ProgressHelper.getDateKey(today)
    );
    const todayCompleted = ProgressHelper.countCompleted(todayState);
    const todayFajr = todayState.fajr === true;
    const todayDhuhr = todayState.dhuhr === true;
    const todayAsr = todayState.asr === true;
    const todayMaghrib = todayState.maghrib === true;
    const todayIsha = todayState.isha === true;

    // ---- Weekly grid (last 7 days, oldest → today) ----
    const weeklyGrid: boolean[] = [];
    const weeklyLabels: string[] = [];
    let weekCompleted = 0;

    for (let i = 6; i >= 0; i--) {
      const d = new Date(today);
      d.setDate(d.getDate() - i);
      const st = ProgressHelper.readState(ProgressHelper.getDateKey(d));
      const c = ProgressHelper.countCompleted(st);
      weeklyGrid.push(c === 5);
      weeklyLabels.push(dayLabels[d.getDay()]);
      weekCompleted += c;
    }

    // ---- Current calendar month ----
    let monthCompleted = 0;
    const cursor = new Date(today.getFullYear(), today.getMonth(), 1);
    while (cursor.getTime() <= today.getTime()) {
      const st = ProgressHelper.readState(
        ProgressHelper.getDateKey(cursor)
      );
      monthCompleted += ProgressHelper.countCompleted(st);
      cursor.setDate(cursor.getDate() + 1);
    }

    // ---- Current streak ----
    let streak = 0;
    const streakCursor = new Date(today);
    if (todayCompleted < 5) {
      streakCursor.setDate(streakCursor.getDate() - 1);
    }
    while (true) {
      const st = ProgressHelper.readState(
        ProgressHelper.getDateKey(streakCursor)
      );
      if (ProgressHelper.countCompleted(st) === 5) {
        streak++;
        streakCursor.setDate(streakCursor.getDate() - 1);
      } else {
        break;
      }
    }

    // ---- Best streak in the last 60 days ----
    let best = 0;
    let running = 0;
    for (let i = 59; i >= 0; i--) {
      const d = new Date(today);
      d.setDate(d.getDate() - i);
      const st = ProgressHelper.readState(ProgressHelper.getDateKey(d));
      if (ProgressHelper.countCompleted(st) === 5) {
        running++;
        if (running > best) {
          best = running;
        }
      } else {
        running = 0;
      }
    }
    if (streak > best) {
      best = streak;
    }

    // ---- Rolling 365-day total ----
    let yearTotal = 0;
    for (let i = 0; i < 365; i++) {
      const d = new Date(today);
      d.setDate(d.getDate() - i);
      const st = ProgressHelper.readState(ProgressHelper.getDateKey(d));
      yearTotal += ProgressHelper.countCompleted(st);
    }

    const progress: PrayerProgress = {
      todayCompleted,
      todayTotal: 5,
      todayFajr,
      todayDhuhr,
      todayAsr,
      todayMaghrib,
      todayIsha,
      currentStreak: streak,
      bestStreak: best,
      weeklyGrid,
      weeklyLabels,
      weekCompleted,
      monthCompleted,
      yearCompleted: yearTotal
    };
    return progress;
  }

  // ============================================================
  // PRAYER DETAILS — WEEK / MONTH / YEAR
  // ============================================================

  private static emptyPerPrayer(): PerPrayerCount {
    const out: PerPrayerCount = {
      fajr: 0,
      dhuhr: 0,
      asr: 0,
      maghrib: 0,
      isha: 0
    };
    return out;
  }

  static getPrayerDetails(): PrayerDetailsSnapshot {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const weekPerPrayer = ProgressHelper.emptyPerPrayer();
    const monthPerPrayer = ProgressHelper.emptyPerPrayer();
    const yearPerPrayer = ProgressHelper.emptyPerPrayer();

    // ---- Week: last 7 days, inclusive of today ----
    for (let i = 0; i < 7; i++) {
      const d = new Date(today);
      d.setDate(d.getDate() - i);
      const st = ProgressHelper.readState(ProgressHelper.getDateKey(d));
      if (st.fajr) {
        weekPerPrayer.fajr++;
      }
      if (st.dhuhr) {
        weekPerPrayer.dhuhr++;
      }
      if (st.asr) {
        weekPerPrayer.asr++;
      }
      if (st.maghrib) {
        weekPerPrayer.maghrib++;
      }
      if (st.isha) {
        weekPerPrayer.isha++;
      }
    }

    // ---- Month: current calendar month, elapsed days only ----
    const monthStart = new Date(today.getFullYear(), today.getMonth(), 1);
    const cursorM = new Date(monthStart);
    while (cursorM.getTime() <= today.getTime()) {
      const st = ProgressHelper.readState(
        ProgressHelper.getDateKey(cursorM)
      );
      if (st.fajr) {
        monthPerPrayer.fajr++;
      }
      if (st.dhuhr) {
        monthPerPrayer.dhuhr++;
      }
      if (st.asr) {
        monthPerPrayer.asr++;
      }
      if (st.maghrib) {
        monthPerPrayer.maghrib++;
      }
      if (st.isha) {
        monthPerPrayer.isha++;
      }
      cursorM.setDate(cursorM.getDate() + 1);
    }

    // ---- Year: current calendar year, elapsed days only ----
    const yearStart = new Date(today.getFullYear(), 0, 1);
    const cursorY = new Date(yearStart);
    while (cursorY.getTime() <= today.getTime()) {
      const st = ProgressHelper.readState(
        ProgressHelper.getDateKey(cursorY)
      );
      if (st.fajr) {
        yearPerPrayer.fajr++;
      }
      if (st.dhuhr) {
        yearPerPrayer.dhuhr++;
      }
      if (st.asr) {
        yearPerPrayer.asr++;
      }
      if (st.maghrib) {
        yearPerPrayer.maghrib++;
      }
      if (st.isha) {
        yearPerPrayer.isha++;
      }
      cursorY.setDate(cursorY.getDate() + 1);
    }

    const weekTotal = weekPerPrayer.fajr + weekPerPrayer.dhuhr
      + weekPerPrayer.asr + weekPerPrayer.maghrib + weekPerPrayer.isha;
    const monthTotal = monthPerPrayer.fajr + monthPerPrayer.dhuhr
      + monthPerPrayer.asr + monthPerPrayer.maghrib + monthPerPrayer.isha;
    const yearTotal = yearPerPrayer.fajr + yearPerPrayer.dhuhr
      + yearPerPrayer.asr + yearPerPrayer.maghrib + yearPerPrayer.isha;

    const daysElapsedMonth = today.getDate();
    const daysElapsedYear = Math.floor(
      (today.getTime() - yearStart.getTime()) / 86400000
    ) + 1;

    const base = ProgressHelper.getPrayerProgress();
    const snapshot: PrayerDetailsSnapshot = {
      weekPerPrayer,
      monthPerPrayer,
      yearPerPrayer,
      weekTotal,
      weekPossible: 7 * 5,
      monthTotal,
      monthPossible: daysElapsedMonth * 5,
      yearTotal,
      yearPossible: daysElapsedYear * 5,
      currentStreak: base.currentStreak,
      bestStreak: base.bestStreak,
      monthProgress: ProgressHelper.getMonthProgress()
    };
    return snapshot;
  }

  // ============================================================
  // TASBIH — HOME CARD
  // ============================================================

  static getTasbihProgress(tasbihs: Tasbih[]): TasbihProgress {
    let totalDhikrs = 0;
    let lifetimeCount = 0;
    let completedDhikrs = 0;

    for (const t of tasbihs) {
      lifetimeCount += (t.lifetimeCount || 0);
      totalDhikrs += t.dhikrs.length;
      for (const d of t.dhikrs) {
        if (d.target > 0 && d.count >= d.target) {
          completedDhikrs++;
        }
      }
    }

    const progress: TasbihProgress = {
      totalTasbihs: tasbihs.length,
      totalDhikrs,
      lifetimeCount,
      completedDhikrs
    };
    return progress;
  }

  /**
   * Today's dhikr completion across all tasbihs.
   *
   * "Complete" means the live count has reached that dhikr's target.
   * Because TasbihStorage rolls the count at midnight, the live
   * count is always today's count.
   */
  static getTasbihTodayProgress(
    tasbihs: Tasbih[]
  ): TasbihTodayProgress {
    let completed = 0;
    let total = 0;
    let lifetime = 0;

    for (const t of tasbihs) {
      lifetime += t.lifetimeCount || 0;
      for (const d of t.dhikrs) {
        total++;
        if (d.target > 0 && d.count >= d.target) {
          completed++;
        }
      }
    }

    const percent = total > 0 ? Math.round(completed / total * 100) : 0;
    const out: TasbihTodayProgress = {
      dhikrsCompleted: completed,
      dhikrsTotal: total,
      percent: percent,
      totalTasbihs: tasbihs.length,
      lifetimeCount: lifetime
    };
    return out;
  }

  // ============================================================
  // TASBIH DETAILS — WEEK / MONTH / YEAR
  // ============================================================

  /**
   * Per-tasbih, per-dhikr progress for the given period.
   *
   * Reads the rolling history log on each tasbih. A day counts as
   * complete for a dhikr when that day's logged count reached the
   * dhikr's current target.
   */
  static getTasbihDetails(
    tasbihs: Tasbih[],
    activeId: string,
    period: TasbihPeriod
  ): TasbihDetailsSnapshot {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const dateKeys: string[] = [];

    if (period === 'week') {
      for (let i = 6; i >= 0; i--) {
        const d = new Date(today);
        d.setDate(d.getDate() - i);
        dateKeys.push(ProgressHelper.getDateKey(d));
      }
    } else if (period === 'month') {
      const cur = new Date(today.getFullYear(), today.getMonth(), 1);
      while (cur.getTime() <= today.getTime()) {
        dateKeys.push(ProgressHelper.getDateKey(cur));
        cur.setDate(cur.getDate() + 1);
      }
    } else {
      const cur = new Date(today.getFullYear(), 0, 1);
      while (cur.getTime() <= today.getTime()) {
        dateKeys.push(ProgressHelper.getDateKey(cur));
        cur.setDate(cur.getDate() + 1);
      }
    }

    const daysInPeriod = dateKeys.length;

    const rows: TasbihProgressRow[] = [];
    let totalDaysCompleted = 0;
    let totalDaysPossible = 0;
    let totalCount = 0;

    for (const t of tasbihs) {
      const perDhikr: TasbihDhikrProgress[] = [];
      let tasbihDaysCompleted = 0;

      for (const d of t.dhikrs) {
        let daysCompleted = 0;
        let countSum = 0;

        for (const key of dateKeys) {
          const c = ProgressHelper.historyCountFor(t, key, d.id);
          countSum += c;
          if (d.target > 0 && c >= d.target) {
            daysCompleted++;
          }
        }

        const label = d.transliteration.length > 0
          ? d.transliteration
          : d.arabic;

        const row: TasbihDhikrProgress = {
          dhikrId: d.id,
          dhikrLabel: label,
          target: d.target,
          daysCompleted: daysCompleted,
          daysInPeriod: daysInPeriod,
          totalCount: countSum
        };
        perDhikr.push(row);
        tasbihDaysCompleted += daysCompleted;
        totalCount += countSum;
      }

      const possible = t.dhikrs.length * daysInPeriod;
      const tasbihRow: TasbihProgressRow = {
        tasbihId: t.id,
        tasbihName: t.name,
        themePresetId: t.themePresetId !== undefined
          ? t.themePresetId : '',
        isActive: t.id === activeId,
        perDhikr: perDhikr,
        totalDaysCompleted: tasbihDaysCompleted,
        totalDaysPossible: possible
      };
      rows.push(tasbihRow);
      totalDaysCompleted += tasbihDaysCompleted;
      totalDaysPossible += possible;
    }

    const out: TasbihDetailsSnapshot = {
      rows: rows,
      totalDaysCompleted: totalDaysCompleted,
      totalDaysPossible: totalDaysPossible,
      totalCountInPeriod: totalCount,
      daysInPeriod: daysInPeriod
    };
    return out;
  }

  private static historyCountFor(
    t: Tasbih, dateKey: string, dhikrId: string
  ): number {
    if (t.history === undefined) {
      return 0;
    }
    for (const log of t.history) {
      if (log.dateKey !== dateKey) {
        continue;
      }
      for (const dc of log.dhikrCounts) {
        if (dc.dhikrId === dhikrId) {
          return dc.count;
        }
      }
    }
    return 0;
  }

  // ============================================================
  // MONTHLY VIEW
  // ============================================================

  /**
   * Build the current calendar month as a padded 7-column grid.
   * Each cell carries the day's completion count and whether the
   * day is in the future / is today.
   */
  static getMonthProgress(): MonthProgress {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const year = today.getFullYear();
    const monthIndex = today.getMonth();

    const firstOfMonth = new Date(year, monthIndex, 1);
    const lastOfMonth = new Date(year, monthIndex + 1, 0);
    const daysInMonth = lastOfMonth.getDate();
    const firstDow = firstOfMonth.getDay(); // 0 = Sunday

    const cells: MonthDayCell[] = [];

    // Leading padding to align the first day under its weekday column.
    for (let i = 0; i < firstDow; i++) {
      const pad: MonthDayCell = {
        dayOfMonth: 0,
        isToday: false,
        isFuture: false,
        isPadding: true,
        completed: 0
      };
      cells.push(pad);
    }

    let totalCompleted = 0;
    let perfectDays = 0;
    let daysElapsed = 0;

    for (let d = 1; d <= daysInMonth; d++) {
      const date = new Date(year, monthIndex, d);
      date.setHours(0, 0, 0, 0);
      const isToday = date.getTime() === today.getTime();
      const isFuture = date.getTime() > today.getTime();

      let completed = 0;
      if (!isFuture) {
        const st = ProgressHelper.readState(
          ProgressHelper.getDateKey(date)
        );
        completed = ProgressHelper.countCompleted(st);
        totalCompleted += completed;
        if (completed === 5) {
          perfectDays++;
        }
        daysElapsed++;
      }

      const cell: MonthDayCell = {
        dayOfMonth: d,
        isToday,
        isFuture,
        isPadding: false,
        completed
      };
      cells.push(cell);
    }

    // Trailing padding so the grid ends on a full week.
    while (cells.length % 7 !== 0) {
      const pad: MonthDayCell = {
        dayOfMonth: 0,
        isToday: false,
        isFuture: false,
        isPadding: true,
        completed: 0
      };
      cells.push(pad);
    }

    // Chunk into weeks for rendering.
    const weeks: MonthDayCell[][] = [];
    let current: MonthDayCell[] = [];
    for (const c of cells) {
      current.push(c);
      if (current.length === 7) {
        weeks.push(current);
        current = [];
      }
    }

    const result: MonthProgress = {
      year,
      monthIndex,
      cells,
      weeks,
      totalCompleted,
      perfectDays,
      daysElapsed,
      daysInMonth
    };
    return result;
  }

  /**
   * Format "October 2026" (or the localized equivalent) using Intl.
   * Falls back to English month names when Intl is unavailable.
   */
  static formatGregorianMonth(
    year: number, monthIndex: number, lang: string
  ): string {
    const locale = lang === 'zh' ? 'zh-CN'
      : lang === 'ar' ? 'ar'
        : 'en-US';
    try {
      const fmt = new Intl.DateTimeFormat(locale, {
        month: 'long',
        year: 'numeric'
      });
      return fmt.format(new Date(year, monthIndex, 1));
    } catch (err) {
      const fallback: string[] = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return `${fallback[monthIndex]} ${year}`;
    }
  }

  /** Seven days ending today. */
  static getWeekDetail(): WeekDetailCell[] {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const out: WeekDetailCell[] = [];

    for (let i = 6; i >= 0; i--) {
      const d = new Date(today);
      d.setDate(d.getDate() - i);
      const st = ProgressHelper.readState(ProgressHelper.getDateKey(d));
      const cell: WeekDetailCell = {
        dateKey: ProgressHelper.getDateKey(d),
        dayOfWeek: d.getDay(),
        dayOfMonth: d.getDate(),
        isToday: i === 0,
        completed: ProgressHelper.countCompleted(st)
      };
      out.push(cell);
    }
    return out;
  }

  /** Twelve months of the current year, elapsed days only. */
  static getYearDetail(): YearDetailSnapshot {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const year = today.getFullYear();
    const months: YearMonthRow[] = [];
    let totalCompleted = 0;

    for (let m = 0; m < 12; m++) {
      const firstOfMonth = new Date(year, m, 1);
      const lastOfMonth = new Date(year, m + 1, 0);
      const daysInMonth = lastOfMonth.getDate();
      const isFuture = firstOfMonth.getTime() > today.getTime();

      const completed: number[] = [];
      let monthTotal = 0;

      for (let d = 1; d <= daysInMonth; d++) {
        const date = new Date(year, m, d);
        date.setHours(0, 0, 0, 0);
        if (date.getTime() > today.getTime()) {
          completed.push(-1);
        } else {
          const st = ProgressHelper.readState(
            ProgressHelper.getDateKey(date)
          );
          const c = ProgressHelper.countCompleted(st);
          completed.push(c);
          monthTotal += c;
        }
      }

      const row: YearMonthRow = {
        monthIndex: m,
        daysInMonth: daysInMonth,
        completed: completed,
        isFuture: isFuture,
        totalCompleted: monthTotal
      };
      months.push(row);
      totalCompleted += monthTotal;
    }

    const out: YearDetailSnapshot = {
      year: year,
      months: months,
      totalCompleted: totalCompleted
    };
    return out;
  }
}