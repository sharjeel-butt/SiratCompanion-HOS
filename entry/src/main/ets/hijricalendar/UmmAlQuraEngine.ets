// entry/src/main/ets/utils/UmmAlQuraEngine.ets

import { HijriDate } from './HijriCalendarModels';
import { HijriCalendarType } from './HijriCalendarType';
import { HijriCalendarEngine } from './HijriCalendarEngine';
import { TabularHijriEngine } from './TabularHijriEngine';

/**
 * The Umm al-Qura calendar of Saudi Arabia.
 *
 * Uses a pre-computed table of month lengths covering Hijri years
 * 1318–1500 AH (Gregorian 1900-04-30 through 2076-11-16 CE).
 *
 * ## Data source
 *
 * The table below is the month-length bitmask series from the .NET
 * `UmAlQuraCalendar` reference implementation, which is licensed
 * under the MIT License and is in turn derived from the official
 * KACST tables published by the Government of Saudi Arabia.
 *
 *   https://github.com/dotnet/runtime/blob/main/src/libraries/
 *     System.Private.CoreLib/src/System/Globalization/
 *     UmAlQuraCalendar.cs
 *
 * ## Bit layout
 *
 * Each 12-bit value encodes one Hijri year's month lengths:
 *
 *   bit 0  → Muharram (month 1)
 *   bit 1  → Safar    (month 2)
 *   ...
 *   bit 11 → Dhu al-Hijjah (month 12)
 *
 * A set bit means 30 days; a clear bit means 29 days.
 *
 * ## Epoch
 *
 * 1 Muharram 1318 AH = 30 April 1900 CE (Gregorian).
 * Julian Day Number: 2415140.
 *
 * ## Fallback
 *
 * Dates outside 1318–1500 AH delegate to the tabular (arithmetical)
 * engine so that conversion remains computable everywhere.
 */
export class UmmAlQuraEngine implements HijriCalendarEngine {
  readonly type: HijriCalendarType = HijriCalendarType.UMM_AL_QURA;
  private static readonly MIN_YEAR = 1318;
  private static readonly MAX_YEAR = 1500;
  /** JDN of 1 Muharram 1318 AH (30 April 1900 CE). */
  private static readonly EPOCH_JDN = 2415140;
  private static readonly fallback: TabularHijriEngine =
    new TabularHijriEngine();
  /**
   * Month-length bitmasks for Hijri years 1318–1500.
   *
   * Index 0 → year 1318 AH.
   * Index 182 → year 1500 AH.
   *
   * Values are the flags column from the .NET `UmAlQuraCalendar`
   * `rawData` table (every fourth short value, starting at index 0).
   */
  private static readonly MONTH_LENGTH_FLAGS: number[] = [
    0x02EA, 0x06E9, 0x0ED2, 0x0EA4, 0x0D4A, 0x0A96, 0x0536, 0x0AB5,
    0x0DAA, 0x0BA4, 0x0B49, 0x0A93, 0x052B, 0x0A57, 0x04B6, 0x0AB5,
    0x05AA, 0x0D55, 0x0D2A, 0x0A56, 0x04AE, 0x095D, 0x02EC, 0x06D5,
    0x06AA, 0x0555, 0x04AB, 0x095B, 0x02BA, 0x0575, 0x0BB2, 0x0764,
    0x0749, 0x0655, 0x02AB, 0x055B, 0x0ADA, 0x06D4, 0x0EC9, 0x0D92,
    0x0D25, 0x0A4D, 0x02AD, 0x056D, 0x0B6A, 0x0B52, 0x0AA5, 0x0A4B,
    0x0497, 0x0937, 0x02B6, 0x0575, 0x0D6A, 0x0D52, 0x0A96, 0x092D,
    0x025D, 0x04DD, 0x0ADA, 0x05D4, 0x0DA9, 0x0D52, 0x0AAA, 0x04D6,
    0x09B6, 0x0374, 0x0769, 0x0752, 0x06A5, 0x054B, 0x0AAB, 0x055A,
    0x0AD5, 0x0DD2, 0x0DA4, 0x0D49, 0x0A95, 0x052D, 0x0A5D, 0x055A,
    0x0AD5, 0x06AA, 0x0695, 0x052B, 0x0A57, 0x04AE, 0x0976, 0x056C,
    0x0B55, 0x0AAA, 0x0A55, 0x04AD, 0x095D, 0x02DA, 0x05D9, 0x0DB2,
    0x0BA4, 0x0B4A, 0x0A55, 0x02B5, 0x0575, 0x0B6A, 0x0BD2, 0x0BC4,
    0x0B89, 0x0A95, 0x052D, 0x05AD, 0x0B6A, 0x06D4, 0x0DC9, 0x0D92,
    0x0AA6, 0x0956, 0x02AE, 0x056D, 0x036A, 0x0B55, 0x0AAA, 0x094D,
    0x049D, 0x095D, 0x02BA, 0x05B5, 0x05AA, 0x0D55, 0x0A9A, 0x092E,
    0x026E, 0x055D, 0x0ADA, 0x06D4, 0x06A5, 0x054B, 0x0A97, 0x054E,
    0x0AAE, 0x05AC, 0x0BA9, 0x0D92, 0x0B25, 0x064B, 0x0CAB, 0x055A,
    0x0B55, 0x06D2, 0x0EA5, 0x0E4A, 0x0A95, 0x052D, 0x0AAD, 0x036C,
    0x0759, 0x06D2, 0x0695, 0x052D, 0x0A5B, 0x04BA, 0x09BA, 0x03B4,
    0x0B69, 0x0B52, 0x0AA6, 0x04B6, 0x096D, 0x02EC, 0x06D9, 0x0EB2,
    0x0D54, 0x0D2A, 0x0A56, 0x04AE, 0x096D, 0x0D6A, 0x0B54, 0x0B29,
    0x0A93, 0x052B, 0x0A57, 0x0536, 0x0AB5, 0x06AA, 0x0E93
  ];
  /**
   * Pre-computed JDN for the first day of each Hijri year in range,
   * plus one extra entry for the day after the last year ends.
   * `YEAR_START_JDN[y - MIN_YEAR]` = JDN of 1 Muharram of year y.
   */
  private static readonly YEAR_START_JDN: number[] =
    UmmAlQuraEngine.initYearStarts();

  // ============================================================
  // PUBLIC API
  // ============================================================

  isLeapYear(year: number): boolean {
    if (year < UmmAlQuraEngine.MIN_YEAR
      || year > UmmAlQuraEngine.MAX_YEAR) {
      return UmmAlQuraEngine.fallback.isLeapYear(year);
    }
    let total = 0;
    for (let m = 1; m <= 12; m++) {
      total += UmmAlQuraEngine.staticDaysInMonth(year, m);
    }
    return total === 355;
  }

  daysInMonth(year: number, month: number): number {
    if (month < 1 || month > 12) {
      return 0;
    }
    if (year < UmmAlQuraEngine.MIN_YEAR
      || year > UmmAlQuraEngine.MAX_YEAR) {
      return UmmAlQuraEngine.fallback.daysInMonth(year, month);
    }
    return UmmAlQuraEngine.staticDaysInMonth(year, month);
  }

  toHijri(gregorian: Date): HijriDate | null {
    if (gregorian === null || gregorian === undefined) {
      return null;
    }

    const jdn = UmmAlQuraEngine.gregorianToJDN(gregorian);
    if (jdn < 0) {
      return null;
    }

    const minJdn = UmmAlQuraEngine.EPOCH_JDN;
    const maxJdn =
      UmmAlQuraEngine.YEAR_START_JDN[UmmAlQuraEngine.YEAR_START_JDN.length - 1];

    if (jdn < minJdn || jdn >= maxJdn) {
      return UmmAlQuraEngine.fallback.toHijri(gregorian);
    }

    // Find the year by scanning the pre-computed year-start JDNs.
    let year = UmmAlQuraEngine.MAX_YEAR;
    for (let y = UmmAlQuraEngine.MIN_YEAR;
      y <= UmmAlQuraEngine.MAX_YEAR; y++) {
      const start = UmmAlQuraEngine.YEAR_START_JDN[y - UmmAlQuraEngine.MIN_YEAR];
      const next = UmmAlQuraEngine.YEAR_START_JDN[y - UmmAlQuraEngine.MIN_YEAR + 1];
      if (jdn >= start && jdn < next) {
        year = y;
        break;
      }
    }

    let remaining = jdn - UmmAlQuraEngine.YEAR_START_JDN[
    year - UmmAlQuraEngine.MIN_YEAR
    ];

    let month = 12;
    for (let m = 1; m <= 12; m++) {
      const mDays = UmmAlQuraEngine.staticDaysInMonth(year, m);
      if (remaining < mDays) {
        month = m;
        break;
      }
      remaining -= mDays;
    }

    const day = remaining + 1;
    const result: HijriDate = { year, month, day };
    return result;
  }

  toGregorian(hijri: HijriDate): Date | null {
    if (hijri === null || hijri === undefined) {
      return null;
    }

    if (hijri.year < UmmAlQuraEngine.MIN_YEAR
      || hijri.year > UmmAlQuraEngine.MAX_YEAR) {
      return UmmAlQuraEngine.fallback.toGregorian(hijri);
    }
    if (hijri.month < 1 || hijri.month > 12) {
      return null;
    }

    let jdn = UmmAlQuraEngine.YEAR_START_JDN[
    hijri.year - UmmAlQuraEngine.MIN_YEAR
    ];
    for (let m = 1; m < hijri.month; m++) {
      jdn += UmmAlQuraEngine.staticDaysInMonth(hijri.year, m);
    }
    jdn += hijri.day - 1;

    return UmmAlQuraEngine.jdnToGregorian(jdn);
  }

  // ============================================================
  // INTERNAL
  // ============================================================

  private static staticDaysInMonth(year: number, month: number): number {
    const flags = UmmAlQuraEngine.MONTH_LENGTH_FLAGS[
    year - UmmAlQuraEngine.MIN_YEAR
    ];
    const bitIndex = month - 1;
    const isThirty = ((flags >> bitIndex) & 1) === 1;
    return isThirty ? 30 : 29;
  }

  private static initYearStarts(): number[] {
    const out: number[] = [];
    let jdn = UmmAlQuraEngine.EPOCH_JDN;
    out.push(jdn);
    for (let y = UmmAlQuraEngine.MIN_YEAR;
      y <= UmmAlQuraEngine.MAX_YEAR; y++) {
      let yearDays = 0;
      for (let m = 1; m <= 12; m++) {
        yearDays += UmmAlQuraEngine.staticDaysInMonth(y, m);
      }
      jdn += yearDays;
      out.push(jdn);
    }
    return out;
  }

  // ============================================================
  // JULIAN DAY NUMBER (integer, noon-based)
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