// entry/src/main/ets/utils/TimezoneResolver.ets

import { CountryTimezoneLookup } from './CountryTimezoneTable';
import { City, DstRule, OfflineCityLookup } from './OfflineCityLookup';


const MS_PER_DAY = 86400000;
/**
 * Resolves the effective UTC offset (hours) for a location on a
 * given date, including DST where applicable.
 *
 * Strategy:
 *   1. If the location is near a city in OfflineCityLookup, use that
 *      city's standard offset + a DST adjustment derived from the
 *      city's DST rule.
 *   2. Otherwise, use a longitude-derived estimate with no DST.
 *   3. If the device's own offset is within 15 minutes of the
 *      location's offset, prefer the device's offset — the OS knows
 *      about local political boundaries and DST transitions more
 *      precisely than we do.
 *
 * ## Why the 15-minute window
 *
 * The original threshold was 30 minutes. That let a Karachi device
 * (UTC+5) override Kabul's UTC+4:30, since the difference is exactly
 * 0.5 hours and passed the <= 0.5 check — the app would compute
 * Kabul's prayers on Karachi's clock. The tighter window keeps the
 * "prefer device" safety for cases where the two clocks agree, while
 * refusing to override legitimate half-hour and quarter-hour offsets.
 *
 */


export class TimezoneResolver {
  /**
   * Effective offset for a location, preferring the device's offset
   * when the two are within 15 minutes of each other.
   *
   * @returns hours east of UTC (may be fractional: 5.5 for India,
   *          4.5 for Kabul)
   */
  static effectiveOffsetForLocation(
    latitude: number,
    longitude: number,
    date: Date
  ): number {
    if (latitude === 0 && longitude === 0) {
      return 0;
    }

    const deviceOffset = -date.getTimezoneOffset() / 60;
    const locationOffset = TimezoneResolver.tableOffset(
      latitude, longitude, date
    );

    const useDevice = Math.abs(deviceOffset - locationOffset) <= 0.25;
    return useDevice ? deviceOffset : locationOffset;
  }

  /**
   * Longitude-derived or table-listed offset, no device input.
   */
  static tableOffset(
    latitude: number,
    longitude: number,
    date: Date
  ): number {
    // Morocco — permanent UTC+1 except during Ramadan, when the
    // country shifts to UTC+0. The transition dates follow the
    // Ramadan crescent sighting, which varies by year; the windows
    // below cover the next three years and can be extended.
    if (latitude >= 27 && latitude <= 36 &&
      longitude >= -14 && longitude <= -1) {
      const inRamadan = TimezoneResolver.isMoroccoRamadan(date);
      return inRamadan ? 0 : 1;
    }

    const city: City | null = OfflineCityLookup.nearestCity(
      latitude, longitude
    );
    if (city !== null) {
      return city.standardOffset +
        (TimezoneResolver.isDst(city.dstRule, date) ? 1 : 0);
    }

    // ---- Country fallback ----
    // The nearest-city table misses anything more than 300 km from
    // a listed city. The country table is coarser but covers the
    // whole landmass, so a lookup that misses a city still lands on
    // the correct offset rather than a longitude estimate that
    // ignores political boundaries.
    const country = CountryTimezoneLookup.zoneFor(latitude, longitude);
    if (country !== null) {
      return country.standardOffset +
        (TimezoneResolver.isDst(country.dstRule, date) ? 1 : 0);
    }

    // ---- Last resort: mid-ocean or Antarctic ----
    return Math.round(longitude / 15);
  }

  /**
   * True when the given date falls within Morocco's Ramadan window
   * for the years covered by the hard-coded table.
   *
   * Dates are approximate — the actual transition follows the local
   * crescent sighting and can shift by a day. For a companion app
   * showing today's times, a day of slack on the boundary is
   * acceptable; a full month of the wrong offset is not.
   */
  /**
   * True when the given date falls within Morocco's Ramadan window
   * for the years covered by the table below.
   *
   * The window dates are approximate — the real transition follows
   * the local crescent sighting and can shift by a day. For a
   * companion app showing today's times, a day of slack on the
   * boundary is acceptable; a full month of the wrong offset is
   * what this method prevents.
   *
   * Years beyond the table fall back to standard +1. That is one
   * hour off during the missed Ramadan — noticeable but not
   * catastrophic, and easily fixed by extending the table before
   * the app reaches that year.
   */
  private static isMoroccoRamadan(date: Date): boolean {
    // Windows are built with local-time Date constructors, so the
    // comparison year must also be local. Using getUTCFullYear()
    // here would test 31 Dec UTC / 1 Jan local against the wrong
    // row around New Year's Eve.
    const year = date.getFullYear();
    const t = date.getTime();

    switch (year) {
      case 2025:
        return t >= new Date(2025, 1, 28).getTime()
          && t < new Date(2025, 2, 30).getTime();
      case 2026:
        return t >= new Date(2026, 1, 17).getTime()
          && t < new Date(2026, 2, 19).getTime();
      case 2027:
        return t >= new Date(2027, 1, 7).getTime()
          && t < new Date(2027, 2, 9).getTime();
      // Extended table — approximate, ±1 day, same policy as above.
      case 2028:
        return t >= new Date(2028, 0, 27).getTime()
          && t < new Date(2028, 1, 27).getTime();
      case 2029:
        return t >= new Date(2029, 0, 15).getTime()
          && t < new Date(2029, 1, 15).getTime();
      default:
      // Table exhausted — fall back to standard time. See the
      // method comment: 1 hour off during the actual Ramadan.
        return false;
    }
  }

  // ============================================================
  // DST LOGIC
  // ============================================================

  // In TimezoneResolver.ets, inside the isDst method
  private static isDst(rule: DstRule, date: Date): boolean {
    const year = date.getUTCFullYear();
    switch (rule) {
      case DstRule.US:
        return TimezoneResolver.isUsDst(date, year);
      case DstRule.EU:
        return TimezoneResolver.isEuDst(date, year);
      case DstRule.AU:
        return TimezoneResolver.isAuDst(date, year);
      case DstRule.NZ: // NEW
        return TimezoneResolver.isNzDst(date, year);
      case DstRule.EGYPT:
        return TimezoneResolver.isEgyptDst(date, year);
      default:
        return false;
    }
  }

  /**
   * Egypt DST: last Friday of April → last Thursday of October,
   * per Law No. 34 of 2023.
   *
   * The clock goes forward at midnight entering the last Friday of
   * April, and back at midnight at the end of the last Thursday of
   * October. The `end` Date is therefore the Friday *after* the last
   * Thursday, so a date on that Friday (the transition day) is
   * already outside DST.
   */
  private static isEgyptDst(date: Date, year: number): boolean {
    const start = TimezoneResolver.lastWeekdayOfMonth(
      year, 4, 5
    ); // Friday = 5
    const lastThursday = TimezoneResolver.lastWeekdayOfMonth(
      year, 10, 4
    ); // Thursday = 4
    const end = new Date(lastThursday.getTime() + MS_PER_DAY);

    const t = date.getTime();
    return t >= start.getTime() && t < end.getTime();
  }

  /**
   * Last occurrence of a given weekday in a 1-based month, at 00:00 UTC.
   *
   * @param year      Calendar year
   * @param month     1-based month (4 = April, 10 = October)
   * @param weekday   0 = Sunday … 6 = Saturday
   */
  private static lastWeekdayOfMonth(
    year: number, month: number, weekday: number
  ): Date {
    // Day 0 of month+1 is the last day of `month`.
    const last = new Date(Date.UTC(year, month, 0));
    const lastDow = last.getUTCDay();
    let delta = lastDow - weekday;
    if (delta < 0) {
      delta += 7;
    }
    return new Date(Date.UTC(
      year, month - 1, last.getUTCDate() - delta
    ));
  }

  /**
   * US DST: second Sunday of March → first Sunday of November,
   * both in the same calendar year.
   */
  private static isUsDst(date: Date, year: number): boolean {
    const start = TimezoneResolver.nthSunday(year, 3, 2);
    const end = TimezoneResolver.nthSunday(year, 11, 1);
    const t = date.getTime();
    return t >= start.getTime() && t < end.getTime();
  }

  /**
   * EU DST: last Sunday of March → last Sunday of October,
   * both in the same calendar year.
   */
  private static isEuDst(date: Date, year: number): boolean {
    const start = TimezoneResolver.lastSunday(year, 3);
    const end = TimezoneResolver.lastSunday(year, 10);
    const t = date.getTime();
    return t >= start.getTime() && t < end.getTime();
  }

  /**
   * Southern-hemisphere DST (Australia / NZ):
   * first Sunday of October → first Sunday of April.
   * The window spans the new-year boundary.
   */
  private static isAuDst(date: Date, year: number): boolean {
    const m = date.getUTCMonth(); // 0 = Jan, 3 = Apr, 9 = Oct
    const t = date.getTime();

    if (m >= 9) {
      const start = TimezoneResolver.nthSunday(year, 10, 1);
      return t >= start.getTime();
    }
    if (m <= 2) {
      return true;
    }
    if (m === 3) {
      const end = TimezoneResolver.nthSunday(year, 4, 1);
      return t < end.getTime();
    }
    return false;
  }

  /**
   * New Zealand DST: last Sunday of September → first Sunday of April.
   *
   * Differs from Australia's window only in the start date. NZ starts
   * DST roughly one week earlier, on the last Sunday of September,
   * whereas Australia starts on the first Sunday of October. Without
   * this distinct rule, Auckland would be treated as on standard time
   * for that one week in late September / early October and every
   * displayed prayer time would be one hour late.
   *
   * The window spans the new-year boundary, so the year argument is
   * the calendar year of the date being tested.
   */
  private static isNzDst(date: Date, year: number): boolean {
    const m = date.getUTCMonth(); // 0 = Jan, 3 = Apr, 8 = Sep, 9 = Oct
    const t = date.getTime();

    if (m >= 9) {
      // October, November, December — inside DST since September.
      return true;
    }
    if (m === 8) {
      // September — check whether the last Sunday has passed.
      const start = TimezoneResolver.lastSunday(year, 9);
      return t >= start.getTime();
    }
    if (m <= 2) {
      // January, February, March — inside DST since October.
      return true;
    }
    if (m === 3) {
      // April — DST ends at the first Sunday.
      const end = TimezoneResolver.nthSunday(year, 4, 1);
      return t < end.getTime();
    }
    // May, June, July, August — outside DST.
    return false;
  }

  // ============================================================
  // DATE HELPERS
  // ============================================================

  /** nth Sunday (1-based) of a 1-based month, at 00:00 UTC. */
  private static nthSunday(year: number, month: number, n: number): Date {
    const first = new Date(Date.UTC(year, month - 1, 1));
    const dow = first.getUTCDay();
    const day = 1 + ((7 - dow) % 7) + (n - 1) * 7;
    return new Date(Date.UTC(year, month - 1, day));
  }

  /** Last Sunday of a 1-based month, at 00:00 UTC. */
  private static lastSunday(year: number, month: number): Date {
    const last = new Date(Date.UTC(year, month, 0));
    const dow = last.getUTCDay();
    return new Date(Date.UTC(year, month - 1, last.getUTCDate() - dow));
  }
}