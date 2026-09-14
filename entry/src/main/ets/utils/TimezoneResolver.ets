// entry/src/main/ets/utils/TimezoneResolver.ets

import { City, DstRule, OfflineCityLookup } from './OfflineCityLookup';

/**
 * Resolves the effective UTC offset (hours) for a location on a
 * given date, including DST where applicable.
 *
 * Strategy:
 *   1. If the location is near a city in OfflineCityLookup, use that
 *      city's standard offset + a DST adjustment derived from the
 *      city's DST rule.
 *   2. Otherwise, use a longitude-derived estimate with no DST.
 *   3. If the device's own offset is within 0.5 h of the location's
 *      offset, prefer the device's offset — the OS knows about local
 *      political boundaries and DST transitions more precisely than
 *      we do.
 */
export class TimezoneResolver {

  /**
   * Effective offset for a location, preferring the device's offset
   * when the two are within 30 minutes of each other.
   *
   * @returns hours east of UTC (may be fractional: 5.5 for India, 4.5 for Kabul)
   */
  static effectiveOffsetForLocation(
    latitude: number,
    longitude: number,
    date: Date
  ): number {
    if (latitude === 0 && longitude === 0) return 0;

    const deviceOffset = -date.getTimezoneOffset() / 60;
    const locationOffset = TimezoneResolver.tableOffset(latitude, longitude, date);

    const useDevice = Math.abs(deviceOffset - locationOffset) <= 0.5;
    return useDevice ? deviceOffset : locationOffset;
  }

  /**
   * Longitude-derived offset, no DST, no device input.
   * Useful when the caller only wants the location's own offset.
   */
  static tableOffset(latitude: number, longitude: number, date: Date): number {
    const city: City | null = OfflineCityLookup.nearestCity(latitude, longitude);
    if (city !== null) {
      return city.standardOffset + (TimezoneResolver.isDst(city.dstRule, date) ? 1 : 0);
    }
    return Math.round(longitude / 15);
  }

  // ============================================================
  // DST LOGIC
  // ============================================================

  private static isDst(rule: DstRule, date: Date): boolean {
    const year = date.getUTCFullYear();
    switch (rule) {
      case DstRule.US: return TimezoneResolver.isUsDst(date, year);
      case DstRule.EU: return TimezoneResolver.isEuDst(date, year);
      case DstRule.AU: return TimezoneResolver.isAuDst(date, year);
      default:         return false;
    }
  }

  /**
   * US DST: second Sunday of March → first Sunday of November,
   * both in the same calendar year.
   */
  private static isUsDst(date: Date, year: number): boolean {
    const start = TimezoneResolver.nthSunday(year, 3, 2);   // 2nd Sun Mar
    const end   = TimezoneResolver.nthSunday(year, 11, 1);  // 1st Sun Nov
    const t = date.getTime();
    return t >= start.getTime() && t < end.getTime();
  }

  /**
   * EU DST: last Sunday of March → last Sunday of October,
   * both in the same calendar year.
   */
  private static isEuDst(date: Date, year: number): boolean {
    const start = TimezoneResolver.lastSunday(year, 3);    // last Sun Mar
    const end   = TimezoneResolver.lastSunday(year, 10);   // last Sun Oct
    const t = date.getTime();
    return t >= start.getTime() && t < end.getTime();
  }

  /**
   * Southern-hemisphere DST (Australia / NZ):
   * first Sunday of October → first Sunday of April.
   * The window spans the new-year boundary.
   */
  private static isAuDst(date: Date, year: number): boolean {
    const m = date.getUTCMonth();   // 0 = Jan, 3 = Apr, 9 = Oct
    const t = date.getTime();

    if (m >= 9) {
      // Oct, Nov, Dec — DST active once past the first Sunday of Oct
      const start = TimezoneResolver.nthSunday(year, 10, 1);
      return t >= start.getTime();
    }
    if (m <= 2) {
      // Jan, Feb, Mar — still in the DST window that started last Oct
      return true;
    }
    if (m === 3) {
      // April — DST until the first Sunday
      const end = TimezoneResolver.nthSunday(year, 4, 1);
      return t < end.getTime();
    }
    // May – Sep
    return false;
  }

  // ============================================================
  // DATE HELPERS
  // ============================================================

  /** nth Sunday (1-based) of a 1-based month, at 00:00 UTC. */
  private static nthSunday(year: number, month: number, n: number): Date {
    const first = new Date(Date.UTC(year, month - 1, 1));
    const dow = first.getUTCDay();             // 0 = Sun
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