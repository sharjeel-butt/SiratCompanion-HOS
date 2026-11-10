// entry/src/main/ets/utils/ProgressHelper.ets

import { Tasbih } from '../tasbih/TasbihModels';
import { PrayerCheckState, PrayerManager } from '../prayer/PrayerManager';
import { L } from '../i18n/LocalizationHelper';

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
  isFuture: boolean; // NEW
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
  currentWeekNumber: number;
  weekStartDate: Date;
  weekEndDate: Date;
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
  currentWeekNumber: number;
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

  static getPrayerDetails(): PrayerDetailsSnapshot {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const currentYear = today.getFullYear();

    // ==========================================
    // 1. WEEK LOGIC (Sliced from Year Start)
    // ==========================================
    const yearStart = new Date(currentYear, 0, 1);
    const dayOfYear = Math.floor((today.getTime() - yearStart.getTime()) / 86400000) + 1;
    const currentWeekNumber = Math.ceil(dayOfYear / 7);

    const weekStartDate = new Date(currentYear, 0, 1 + (currentWeekNumber - 1) * 7);
    const weekEndDate = new Date(currentYear, 0, 1 + (currentWeekNumber - 1) * 7 + 6);

    const weekPerPrayer = ProgressHelper.emptyPerPrayer();

    for (let i = 0; i < 7; i++) {
      const d = new Date(weekStartDate.getTime() + i * 86400000);
      d.setHours(0, 0, 0, 0);
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

    // ==========================================
    // 2. MONTH LOGIC (Whole Month)
    // ==========================================
    const monthPerPrayer = ProgressHelper.emptyPerPrayer();
    const daysInMonth = new Date(currentYear, today.getMonth() + 1, 0).getDate();

    for (let d = 1; d <= daysInMonth; d++) {
      const date = new Date(currentYear, today.getMonth(), d);
      date.setHours(0, 0, 0, 0);

      const st = ProgressHelper.readState(ProgressHelper.getDateKey(date));
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
    }

    // ==========================================
    // 3. YEAR LOGIC (Whole Year)
    // ==========================================
    const yearPerPrayer = ProgressHelper.emptyPerPrayer();
    for (let m = 0; m < 12; m++) {
      const daysInM = new Date(currentYear, m + 1, 0).getDate();
      for (let d = 1; d <= daysInM; d++) {
        const date = new Date(currentYear, m, d);
        date.setHours(0, 0, 0, 0); // Safe from DST shifts

        // NOTE: We do NOT use 'break' here. We count all recorded data.
        const st = ProgressHelper.readState(ProgressHelper.getDateKey(date));
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
      }
    }

    // ==========================================
    // TOTALS & RETURN
    // ==========================================
    const weekTotal =
      weekPerPrayer.fajr + weekPerPrayer.dhuhr + weekPerPrayer.asr + weekPerPrayer.maghrib + weekPerPrayer.isha;
    const monthTotal =
      monthPerPrayer.fajr + monthPerPrayer.dhuhr + monthPerPrayer.asr + monthPerPrayer.maghrib + monthPerPrayer.isha;
    const yearTotal =
      yearPerPrayer.fajr + yearPerPrayer.dhuhr + yearPerPrayer.asr + yearPerPrayer.maghrib + yearPerPrayer.isha;

    const base = ProgressHelper.getPrayerProgress();

    // CRITICAL FIX: Ensure we map the correct objects to the correct keys.
    // If you accidentally map weekPerPrayer to yearPerPrayer, both will show '6'.
    return {
      weekPerPrayer: weekPerPrayer,
      monthPerPrayer: monthPerPrayer,
      yearPerPrayer: yearPerPrayer,
      weekTotal: weekTotal,
      weekPossible: 7 * 5,
      monthTotal: monthTotal,
      monthPossible: daysInMonth * 5,
      yearTotal: yearTotal,
      yearPossible: 365 * 5,
      currentStreak: base.currentStreak,
      bestStreak: base.bestStreak,
      monthProgress: ProgressHelper.getMonthProgress(),
      currentWeekNumber: currentWeekNumber,
      weekStartDate: weekStartDate,
      weekEndDate: weekEndDate
    };
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
        const dayTotal = d.dailyTotal ?? d.count;
        if (d.target > 0 && dayTotal >= d.target) {
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
    period: TasbihPeriod,
    lang: string = 'en'
  ): TasbihDetailsSnapshot {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const currentYear = today.getFullYear();
    const dateKeys: string[] = [];
    let fullPeriodDays = 0;
    let currentWeekNumber = 1;

    if (period === 'week') {
      const yearStart = new Date(currentYear, 0, 1);
      const dayOfYear = Math.floor((today.getTime() - yearStart.getTime()) / 86400000) + 1;
      currentWeekNumber = Math.ceil(dayOfYear / 7);
      fullPeriodDays = 7;

      const weekStart = new Date(yearStart.getTime() + (currentWeekNumber - 1) * 7 * 86400000);
      for (let i = 0; i < 7; i++) {
        const d = new Date(weekStart.getTime() + i * 86400000);
        d.setHours(0, 0, 0, 0);
        dateKeys.push(ProgressHelper.getDateKey(d));
      }
    } else if (period === 'month') {
      const daysInMonth = new Date(currentYear, today.getMonth() + 1, 0).getDate();
      fullPeriodDays = daysInMonth;

      for (let d = 1; d <= daysInMonth; d++) {
        const date = new Date(currentYear, today.getMonth(), d);
        date.setHours(0, 0, 0, 0);
        dateKeys.push(ProgressHelper.getDateKey(date));
      }
    } else {
      fullPeriodDays = 365;
      for (let m = 0; m < 12; m++) {
        const daysInM = new Date(currentYear, m + 1, 0).getDate();
        for (let d = 1; d <= daysInM; d++) {
          const date = new Date(currentYear, m, d);
          date.setHours(0, 0, 0, 0);
          dateKeys.push(ProgressHelper.getDateKey(date)); // No break!
        }
      }
    }

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

        const label = (d.transliterationKey && d.transliterationKey.length > 0)
          ? L.get(d.transliterationKey, lang)
          : (d.transliteration.length > 0 ? d.transliteration : d.arabic);

        perDhikr.push({
          dhikrId: d.id,
          dhikrLabel: label,
          target: d.target,
          daysCompleted: daysCompleted,
          daysInPeriod: fullPeriodDays,
          totalCount: countSum
        });
        tasbihDaysCompleted += daysCompleted;
        totalCount += countSum;
      }

      const possible = t.dhikrs.length * fullPeriodDays;
      const tasbihName = (t.nameKey && t.nameKey.length > 0) ? L.get(t.nameKey, lang) : t.name;

      rows.push({
        tasbihId: t.id,
        tasbihName: tasbihName,
        themePresetId: t.themePresetId !== undefined ? t.themePresetId : '',
        isActive: t.id === activeId,
        perDhikr: perDhikr,
        totalDaysCompleted: tasbihDaysCompleted,
        totalDaysPossible: possible
      });
      totalDaysCompleted += tasbihDaysCompleted;
      totalDaysPossible += possible;
    }

    return {
      rows: rows,
      totalDaysCompleted: totalDaysCompleted,
      totalDaysPossible: totalDaysPossible,
      totalCountInPeriod: totalCount,
      daysInPeriod: fullPeriodDays,
      currentWeekNumber: currentWeekNumber
    };
  }

  // ============================================================
  // TASBIH DETAILS — WEEK / MONTH / YEAR
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

  // ============================================================
  // MONTHLY VIEW
  // ============================================================

  /** Seven days ending today. */
  static getWeekDetail(): WeekDetailCell[] {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const msPerDay = 86400000;
    const yearStart = new Date(today.getFullYear(), 0, 1);

    const dayOfYear = Math.floor((today.getTime() - yearStart.getTime()) / msPerDay) + 1;
    const currentWeekNumber = Math.ceil(dayOfYear / 7);
    const weekStart = new Date(yearStart.getTime() + (currentWeekNumber - 1) * 7 * msPerDay);

    const out: WeekDetailCell[] = [];
    for (let i = 0; i < 7; i++) {
      const d = new Date(weekStart.getTime() + i * msPerDay);
      const st = ProgressHelper.readState(ProgressHelper.getDateKey(d));

      out.push({
        dateKey: ProgressHelper.getDateKey(d),
        dayOfWeek: d.getDay(),
        dayOfMonth: d.getDate(),
        isToday: d.getTime() === today.getTime(),
        isFuture: d.getTime() > today.getTime(),
        completed: ProgressHelper.countCompleted(st)
      });
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
}