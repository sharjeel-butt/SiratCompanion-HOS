// entry/src/main/ets/utils/TabularHijriEngine.ets

import { HijriDate } from '../models/HijriCalendarModels';
import { HijriCalendarType } from '../common/HijriCalendarType';
import { HijriCalendarEngine } from './HijriCalendarEngine';

/**
 * The arithmetical (tabular / Kuwaiti) Islamic calendar.
 *
 * Intercalary scheme II with civil (Friday) epoch, as described by
 * R.H. van Gent and used by Microsoft's HijriCalendar.
 *
 * Leap years in the 30-year cycle: 2, 5, 7, 10, 13, 16, 18, 21,
 * 24, 26, 29.
 *
 * Epoch: 1 Muharram 1 AH = Friday, 16 July 622 CE (Julian).
 * The Julian Day Number of this epoch is 1948440 (at noon).
 */
export class TabularHijriEngine implements HijriCalendarEngine {
  readonly type: HijriCalendarType = HijriCalendarType.TABULAR;
  /** JDN of 1 Muharram 1 AH (civil epoch). */
  private static readonly EPOCH_JDN = 1948440;
  private static readonly LEAP_YEARS_IN_CYCLE: number[] = [
    2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29
  ];

  isLeapYear(year: number): boolean {
    const mod = ((year % 30) + 30) % 30;
    for (const y of TabularHijriEngine.LEAP_YEARS_IN_CYCLE) {
      if (y === mod) {
        return true;
      }
    }
    return false;
  }

  daysInMonth(year: number, month: number): number {
    // Odd months (1, 3, 5, ...) = 30 days.
    // Even months (2, 4, 6, ...) = 29 days.
    // Month 12 gets an extra day in leap years.
    if (month < 1 || month > 12) {
      return 0;
    }
    if (month === 12 && this.isLeapYear(year)) {
      return 30;
    }
    if (month % 2 === 1) {
      return 30;
    }
    return 29;
  }

  toHijri(gregorian: Date): HijriDate | null {
    if (gregorian === null || gregorian === undefined) {
      return null;
    }
    const jdn = TabularHijriEngine.gregorianToJDN(gregorian);
    if (jdn < 0) {
      return null;
    }
    return this.jdnToHijri(jdn);
  }

  toGregorian(hijri: HijriDate): Date | null {
    if (hijri === null || hijri === undefined) {
      return null;
    }
    const jdn = this.hijriToJDN(hijri);
    if (jdn < 0) {
      return null;
    }
    return TabularHijriEngine.jdnToGregorian(jdn);
  }

  // ============================================================
  // CORE CONVERSION
  // ============================================================

  private jdnToHijri(jdn: number): HijriDate {
    const daysSinceEpoch = jdn - TabularHijriEngine.EPOCH_JDN;

    // 30-year cycle contains 10631 days (30 × 354 + 11).
    const cycleDays = 10631;
    const cycle = Math.floor(daysSinceEpoch / cycleDays);
    let dayInCycle = daysSinceEpoch - cycle * cycleDays;
    if (dayInCycle < 0) {
      // Only possible before the epoch.
      dayInCycle += cycleDays;
    }

    // Walk through the 30 years of the cycle to find the year.
    let yearInCycle = 1;
    while (yearInCycle <= 30) {
      const yearDays = this.isLeapYearInCycle(yearInCycle) ? 355 : 354;
      if (dayInCycle < yearDays) {
        break;
      }
      dayInCycle -= yearDays;
      yearInCycle += 1;
    }

    const year = cycle * 30 + yearInCycle;

    // Walk through the months of the year to find the month.
    let month = 1;
    while (month <= 12) {
      const mDays = this.daysInMonth(year, month);
      if (dayInCycle < mDays) {
        break;
      }
      dayInCycle -= mDays;
      month += 1;
    }

    const day = dayInCycle + 1;
    const result: HijriDate = { year, month, day };
    return result;
  }

  private hijriToJDN(hijri: HijriDate): number {
    const year = hijri.year;
    const cycle = Math.floor((year - 1) / 30);
    const yearInCycle = ((year - 1) % 30) + 1;

    let days = cycle * 10631;

    // Add the days of previous years in this cycle.
    for (let y = 1; y < yearInCycle; y++) {
      days += this.isLeapYearInCycle(y) ? 355 : 354;
    }

    // Add the days of previous months in this year.
    for (let m = 1; m < hijri.month; m++) {
      days += this.daysInMonth(year, m);
    }

    days += hijri.day - 1;
    return TabularHijriEngine.EPOCH_JDN + days;
  }

  private isLeapYearInCycle(yearInCycle: number): boolean {
    for (const y of TabularHijriEngine.LEAP_YEARS_IN_CYCLE) {
      if (y === yearInCycle) {
        return true;
      }
    }
    return false;
  }

  // ============================================================
  // JULIAN DAY NUMBER
  // ============================================================

  /** Gregorian date → JDN using the Fliegel–Van Flandern formula. */
  private static gregorianToJDN(date: Date): number {
    const year = date.getFullYear();
    const month = date.getMonth() + 1;
    const day = date.getDate();

    const a = Math.floor((14 - month) / 12);
    const y = year + 4800 - a;
    const m = month + 12 * a - 3;

    return day
      + Math.floor((153 * m + 2) / 5)
      + 365 * y
      + Math.floor(y / 4)
      - Math.floor(y / 100)
      + Math.floor(y / 400)
      - 32045;
  }

  /** JDN → Gregorian date at local midnight. */
  private static jdnToGregorian(jdn: number): Date {
    const a = jdn + 32044;
    const b = Math.floor((4 * a + 3) / 146097);
    const c = a - Math.floor((146097 * b) / 4);
    const d = Math.floor((4 * c + 3) / 1461);
    const e = c - Math.floor((1461 * d) / 4);
    const m = Math.floor((5 * e + 2) / 153);

    const day = e - Math.floor((153 * m + 2) / 5) + 1;
    const month = m + 3 - 12 * Math.floor(m / 10);
    const year = 100 * b + d - 4800 + Math.floor(m / 10);

    const result = new Date(year, month - 1, day);
    result.setHours(0, 0, 0, 0);
    return result;
  }
}