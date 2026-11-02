// entry/src/main/ets/models/RamadanModels.ets

/**
 * Persisted data model for the Ramadan tracker.
 *
 * All types in this file that appear in RamadanLogStore are
 * serialized to JSON and stored under `ramadan_log` in the
 * preferences store. Every field must therefore be one of
 * string | number | boolean | enum-string | array | interface.
 */

/** Fasting status of a single Ramadan day. */
export enum FastingStatus {
  /** Not marked yet. The default for a freshly created year. */
  UNMARKED = 'unmarked',
  /** The user fasted this day. */
  FASTED = 'fasted',
  /** The user missed this day. Requires a reason. */
  MISSED = 'missed'
}

/**
 * Canonical reason codes for a missed fast.
 *
 * Codes (not freeform text) so translations and PDF export stay
 * consistent across locales, and so statistics can group by
 * reason without string matching. `OTHER` pairs with the freeform
 * `FastingDay.customReason` field when a predefined code does not
 * fit.
 */
export enum MissedReason {
  TRAVEL = 'travel',
  ILLNESS = 'illness',
  MENSTRUATION = 'menstruation',
  PREGNANCY_NURSING = 'pregnancy_nursing',
  FORGETFULNESS = 'forgetfulness',
  OTHER = 'other'
}

/** One day's tracking entry. */
export interface FastingDay {
  status: FastingStatus;
  reason?: MissedReason;
  customReason?: string;
  madeUp: boolean;
  madeUpAt?: number;
}

/**
 * One Ramadan's full tracking data.
 *
 * Keyed by `hijriYear` — the year number, not a Gregorian date.
 * A Hijri offset change or calendar-type switch does not
 * invalidate this data because the year itself is stable.
 */
export interface RamadanYearData {
  hijriYear: number;

  /** 29 or 30, from the current calendar engine for that year. */
  totalDays: number;

  /** Length always equals totalDays. Index 0 = Ramadan day 1. */
  days: FastingDay[];

  /** Length always equals totalDays. Index 0 = night 1. */
  taraweehNights: boolean[];

  /** Make-up fasts the user has logged for this year. */
  qadaMadeUp: number;
}

/** Root of the persisted store. */
export interface RamadanLogStore {
  years: RamadanYearData[];
}

/** One row in the Qada "by year" breakdown. */
export interface QadaYearRow {
  hijriYear: number;
  fasted: number;
  missed: number;

  /** Number of missed days that have been made up. Subset of missed. */
  madeUp: number;
  unmarked: number;

  /** missed - madeUp. The actionable number. */
  outstanding: number;
}

/**
 * Derived summary. Never persisted — computed on demand from a
 * RamadanLogStore by RamadanStorage.computeQadaSummary().
 */
export interface QadaSummary {
  totalFasted: number;
  totalMissed: number;
  totalMadeUp: number;
  totalUnmarked: number;

  /** totalMissed - totalMadeUp, floored at 0. */
  remaining: number;

  /** Same as remaining — alias for callers that prefer the clearer name. */
  totalOutstanding: number;
  perYear: QadaYearRow[];
}

/**
 * Derived Eid state. Never persisted — computed on demand by
 * RamadanHelper.getEidInfo() (Day 4). Included here so the model
 * file is the single source of truth for Ramadan-related shapes.
 */
export interface EidInfo {
  isEidPeriod: boolean;

  /** 1, 2, or 3 (Shawwal day). */
  eidDay: number;
  hijriYear: number;

  /** Gregorian date of 1 Shawwal. */
  eidDate: Date;
}