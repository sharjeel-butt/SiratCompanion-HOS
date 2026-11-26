// entry/src/main/ets/hijricalendar/UmmAlQuraEngine.ets

import { HijriDate } from './HijriCalendarModels'
import { HijriCalendarType } from './HijriCalendarType'
import { HijriCalendarEngine } from './HijriCalendarEngine'
import { TabularHijriEngine } from './TabularHijriEngine'

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
  private static readonly MIN_YEAR = 1318
  private static readonly MAX_YEAR = 1500
  /** JDN of 1 Muharram 1318 AH (30 April 1900 CE). */
  private static readonly EPOCH_JDN = 2415140
  private static readonly fallback: TabularHijriEngine = new TabularHijriEngine()
  /**
   * Month-length bitmasks for Hijri years 1318–1500.
   *
   * Index 0 → year 1318 AH.
   * Index 182 → year 1500 AH.
   *
   * Values are the flags column from the .NET `UmAlQuraCalendar`
   * `rawData` table (every fourth short value, starting at index 0).
   */
  private static readonly MONTH_LENGTH_FLAGS: number[] =
    [0x02ea, 0x06e9, 0x0ed2, 0x0ea4, 0x0d4a, 0x0a96, 0x0536, 0x0ab5, 0x0daa, 0x0ba4, 0x0b49, 0x0a93, 0x052b, 0x0a57,
      0x04b6, 0x0ab5, 0x05aa, 0x0d55, 0x0d2a, 0x0a56, 0x04ae, 0x095d, 0x02ec, 0x06d5, 0x06aa, 0x0555, 0x04ab, 0x095b,
      0x02ba, 0x0575, 0x0bb2, 0x0764, 0x0749, 0x0655, 0x02ab, 0x055b, 0x0ada, 0x06d4, 0x0ec9, 0x0d92, 0x0d25, 0x0a4d,
      0x02ad, 0x056d, 0x0b6a, 0x0b52, 0x0aa5, 0x0a4b, 0x0497, 0x0937, 0x02b6, 0x0575, 0x0d6a, 0x0d52, 0x0a96, 0x092d,
      0x025d, 0x04dd, 0x0ada, 0x05d4, 0x0da9, 0x0d52, 0x0aaa, 0x04d6, 0x09b6, 0x0374, 0x0769, 0x0752, 0x06a5, 0x054b,
      0x0aab, 0x055a, 0x0ad5, 0x0dd2, 0x0da4, 0x0d49, 0x0a95, 0x052d, 0x0a5d, 0x055a, 0x0ad5, 0x06aa, 0x0695, 0x052b,
      0x0a57, 0x04ae, 0x0976, 0x056c, 0x0b55, 0x0aaa, 0x0a55, 0x04ad, 0x095d, 0x02da, 0x05d9, 0x0db2, 0x0ba4, 0x0b4a,
      0x0a55, 0x02b5, 0x0575, 0x0b6a, 0x0bd2, 0x0bc4, 0x0b89, 0x0a95, 0x052d, 0x05ad, 0x0b6a, 0x06d4, 0x0dc9, 0x0d92,
      0x0aa6, 0x0956, 0x02ae, 0x056d, 0x036a, 0x0b55, 0x0aaa, 0x094d, 0x049d, 0x095d, 0x02ba, 0x05b5, 0x05aa, 0x0d55,
      0x0a9a, 0x092e, 0x026e, 0x055d, 0x0ada, 0x06d4, 0x06a5, 0x054b, 0x0a97, 0x054e, 0x0aae, 0x05ac, 0x0ba9, 0x0d92,
      0x0b25, 0x064b, 0x0cab, 0x055a, 0x0b55, 0x06d2, 0x0ea5, 0x0e4a, 0x0a95, 0x052d, 0x0aad, 0x036c, 0x0759, 0x06d2,
      0x0695, 0x052d, 0x0a5b, 0x04ba, 0x09ba, 0x03b4, 0x0b69, 0x0b52, 0x0aa6, 0x04b6, 0x096d, 0x02ec, 0x06d9, 0x0eb2,
      0x0d54, 0x0d2a, 0x0a56, 0x04ae, 0x096d, 0x0d6a, 0x0b54, 0x0b29, 0x0a93, 0x052b, 0x0a57, 0x0536, 0x0ab5, 0x06aa,
      0x0e93]
  /**
   * Pre-computed JDN for the first day of each Hijri year in range,
   * plus one extra entry for the day after the last year ends.
   * `YEAR_START_JDN[y - MIN_YEAR]` = JDN of 1 Muharram of year y.
   */
  private static readonly YEAR_START_JDN: number[] = UmmAlQuraEngine.initYearStarts()
  readonly type: HijriCalendarType = HijriCalendarType.UMM_AL_QURA

  // ============================================================
  // PUBLIC API
  // ============================================================

  /**
   * Binary-search `YEAR_START_JDN` for the year index whose start
   * is <= jdn and whose *next* year's start is > jdn. Returns the
   * 0-based index; caller adds `MIN_YEAR`.
   */
  private static findYearIndexForJdn(jdn: number): number {
    const arr = UmmAlQuraEngine.YEAR_START_JDN
    let lo = 0
    let hi = arr.length - 2 // last valid year index
    while (lo <= hi) {
      const mid = Math.floor((lo + hi) / 2)
      if (arr[mid] <= jdn) {
        lo = mid + 1
      } else {
        hi = mid - 1
      }
    }
    return hi
  }

  private static staticDaysInMonth(year: number, month: number): number {
    const flags = UmmAlQuraEngine.MONTH_LENGTH_FLAGS[year - UmmAlQuraEngine.MIN_YEAR]
    const bitIndex = month - 1
    const isThirty = ((flags >> bitIndex) & 1) === 1
    return isThirty ? 30 : 29
  }

  private static initYearStarts(): number[] {
    const out: number[] = []
    let jdn = UmmAlQuraEngine.EPOCH_JDN
    out.push(jdn)
    for (let y = UmmAlQuraEngine.MIN_YEAR; y <= UmmAlQuraEngine.MAX_YEAR; y++) {
      let yearDays = 0
      for (let m = 1; m <= 12; m++) {
        yearDays += UmmAlQuraEngine.staticDaysInMonth(y, m)
      }
      jdn += yearDays
      out.push(jdn)
    }
    return out
  }

  /** Gregorian date → JDN using the Fliegel–Van Flandern formula. */
  private static gregorianToJDN(date: Date): number {
    const year = date.getFullYear()
    const month = date.getMonth() + 1
    const day = date.getDate()

    const a = Math.floor((14 - month) / 12)
    const y = year + 4800 - a
    const m = month + 12 * a - 3

    return (day + Math.floor((153 * m + 2) / 5) + 365 * y + Math.floor(y / 4) - Math.floor(y / 100) +
      Math.floor(y / 400) - 32045)
  }

  /** JDN → Gregorian date at local midnight. */
  private static jdnToGregorian(jdn: number): Date {
    const a = jdn + 32044
    const b = Math.floor((4 * a + 3) / 146097)
    const c = a - Math.floor((146097 * b) / 4)
    const d = Math.floor((4 * c + 3) / 1461)
    const e = c - Math.floor((1461 * d) / 4)
    const m = Math.floor((5 * e + 2) / 153)

    const day = e - Math.floor((153 * m + 2) / 5) + 1
    const month = m + 3 - 12 * Math.floor(m / 10)
    const year = 100 * b + d - 4800 + Math.floor(m / 10)

    const result = new Date(year, month - 1, day)
    result.setHours(0, 0, 0, 0)
    return result
  }

  // ============================================================
  // INTERNAL
  // ============================================================

  isLeapYear(year: number): boolean {
    if (year < UmmAlQuraEngine.MIN_YEAR || year > UmmAlQuraEngine.MAX_YEAR) {
      return UmmAlQuraEngine.fallback.isLeapYear(year)
    }
    let total = 0
    for (let m = 1; m <= 12; m++) {
      total += UmmAlQuraEngine.staticDaysInMonth(year, m)
    }
    return total === 355
  }

  daysInMonth(year: number, month: number): number {
    if (month < 1 || month > 12) {
      return 0
    }
    if (year < UmmAlQuraEngine.MIN_YEAR || year > UmmAlQuraEngine.MAX_YEAR) {
      return UmmAlQuraEngine.fallback.daysInMonth(year, month)
    }
    return UmmAlQuraEngine.staticDaysInMonth(year, month)
  }

  // ============================================================
  // JULIAN DAY NUMBER (integer, noon-based)
  // ============================================================

  toHijri(gregorian: Date): HijriDate | null {
    if (gregorian === null || gregorian === undefined) {
      return null
    }

    const jdn = UmmAlQuraEngine.gregorianToJDN(gregorian)
    if (jdn < 0) {
      return null
    }

    const minJdn = UmmAlQuraEngine.EPOCH_JDN
    const maxJdn = UmmAlQuraEngine.YEAR_START_JDN[UmmAlQuraEngine.YEAR_START_JDN.length - 1]

    if (jdn < minJdn || jdn >= maxJdn) {
      return UmmAlQuraEngine.fallback.toHijri(gregorian)
    }

    // Find the year by scanning the pre-computed year-start JDNs.
    // Binary-search the pre-computed year-start JDNs
    const yearIdx = UmmAlQuraEngine.findYearIndexForJdn(jdn)
    const year = UmmAlQuraEngine.MIN_YEAR + yearIdx

    let remaining = jdn - UmmAlQuraEngine.YEAR_START_JDN[year - UmmAlQuraEngine.MIN_YEAR]

    let month = 12
    for (let m = 1; m <= 12; m++) {
      const mDays = UmmAlQuraEngine.staticDaysInMonth(year, m)
      if (remaining < mDays) {
        month = m
        break
      }
      remaining -= mDays
    }

    const day = remaining + 1
    const result: HijriDate = { year, month, day }
    return result
  }

  toGregorian(hijri: HijriDate): Date | null {
    if (hijri === null || hijri === undefined) {
      return null
    }

    if (hijri.year < UmmAlQuraEngine.MIN_YEAR || hijri.year > UmmAlQuraEngine.MAX_YEAR) {
      return UmmAlQuraEngine.fallback.toGregorian(hijri)
    }
    if (hijri.month < 1 || hijri.month > 12) {
      return null
    }

    // Validate day against this month's actual length.
    const monthDays = UmmAlQuraEngine.staticDaysInMonth(hijri.year, hijri.month)
    if (hijri.day < 1 || hijri.day > monthDays) {
      return null
    }

    let jdn = UmmAlQuraEngine.YEAR_START_JDN[hijri.year - UmmAlQuraEngine.MIN_YEAR]
    for (let m = 1; m < hijri.month; m++) {
      jdn += UmmAlQuraEngine.staticDaysInMonth(hijri.year, m)
    }
    jdn += hijri.day - 1

    return UmmAlQuraEngine.jdnToGregorian(jdn)
  }
}
