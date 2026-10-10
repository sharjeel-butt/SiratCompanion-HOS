// entry/src/main/ets/utils/HijriCalendarEngine.ets

import { HijriDate } from '../models/HijriCalendarModels';
import { HijriCalendarType } from '../common/HijriCalendarType';

/**
 * A Hijri calendar engine converts between Gregorian dates and
 * Hijri (year, month, day) triples. Implementations must be pure
 * — no state, no side effects, safe to call from any thread.
 */
export interface HijriCalendarEngine {
  /** Engine identifier. */
  readonly type: HijriCalendarType;

  /**
   * Convert a Gregorian date to a Hijri date.
   * Returns null if the date is outside the engine's valid range.
   */
  toHijri(gregorian: Date): HijriDate | null;

  /**
   * Convert a Hijri date to a Gregorian date.
   * Returns null if the date is outside the engine's valid range.
   */
  toGregorian(hijri: HijriDate): Date | null;

  /** Number of days in a Hijri month. */
  daysInMonth(year: number, month: number): number;

  /** True when the Hijri year is a leap year (has 355 days). */
  isLeapYear(year: number): boolean;
}