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
  private static isMoroccoRamadan(date: Date): boolean {
    const year = date.getUTCFullYear();
    switch (year) {
      case 2025:
        return date >= new Date(2025, 1, 28) &&
          date < new Date(2025, 2, 30);
      case 2026:
        return date >= new Date(2026, 1, 17) &&
          date < new Date(2026, 2, 19);
      case 2027:
        return date >= new Date(2027, 1, 7) &&
          date < new Date(2027, 2, 9);
      default:
        return false;
    }
  }

  // ============================================================
  // DST LOGIC
  // ============================================================

  private static isDst(rule: DstRule, date: Date): boolean {
    const year = date.getUTCFullYear();
    switch (rule) {
      case DstRule.US:
        return TimezoneResolver.isUsDst(date, year);
      case DstRule.EU:
        return TimezoneResolver.isEuDst(date, year);
      case DstRule.AU:
        return TimezoneResolver.isAuDst(date, year);
      default:
        return false;
    }
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