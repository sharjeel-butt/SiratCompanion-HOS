// entry/src/main/ets/utils/ProgressHelper.ets

import { Tasbih } from '../models/TasbihModels';
import { PrayerManager, PrayerCheckState } from './PrayerManager';

export interface PrayerProgress {
  todayCompleted: number; // 0–5
  todayTotal: number; // always 5
  currentStreak: number; // consecutive days with all 5 completed
  bestStreak: number; // best streak in the last 60 days
  weeklyGrid: boolean[]; // 7 booleans, oldest → today
  weeklyLabels: string[]; // matching single-letter day labels
  weekCompleted: number; // total prayers completed this week
  monthCompleted: number; // total prayers completed this calendar month
  lifetimeCompleted: number; // total in the last 365 days
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

const DAY_LABELS: string[] = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

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

  static getPrayerProgress(): PrayerProgress {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const todayState = ProgressHelper.readState(ProgressHelper.getDateKey(today));
    const todayCompleted = ProgressHelper.countCompleted(todayState);

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
      weeklyLabels.push(DAY_LABELS[d.getDay()]);
      weekCompleted += c;
    }

    // ---- Current calendar month ----
    let monthCompleted = 0;
    const cursor = new Date(today.getFullYear(), today.getMonth(), 1);
    while (cursor.getTime() <= today.getTime()) {
      const st = ProgressHelper.readState(ProgressHelper.getDateKey(cursor));
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
      const st = ProgressHelper.readState(ProgressHelper.getDateKey(streakCursor));
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

    // ---- Lifetime (last 365 days) ----
    let lifetime = 0;
    for (let i = 0; i < 365; i++) {
      const d = new Date(today);
      d.setDate(d.getDate() - i);
      const st = ProgressHelper.readState(ProgressHelper.getDateKey(d));
      lifetime += ProgressHelper.countCompleted(st);
    }

    const progress: PrayerProgress = {
      todayCompleted,
      todayTotal: 5,
      currentStreak: streak,
      bestStreak: best,
      weeklyGrid,
      weeklyLabels,
      weekCompleted,
      monthCompleted,
      lifetimeCompleted: lifetime
    };
    return progress;
  }

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
        const st = ProgressHelper.readState(ProgressHelper.getDateKey(date));
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
  static formatGregorianMonth(year: number, monthIndex: number, lang: string): string {
    const locale = lang === 'zh' ? 'zh-CN'
      : lang === 'ar' ? 'ar'
        : 'en-US';
    try {
      const fmt = new Intl.DateTimeFormat(locale, { month: 'long', year: 'numeric' });
      return fmt.format(new Date(year, monthIndex, 1));
    } catch (err) {
      const fallback: string[] = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return `${fallback[monthIndex]} ${year}`;
    }
  }
}