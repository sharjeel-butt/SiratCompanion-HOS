// entry/src/main/ets/location/TimezoneResolver.ets

import { CountryTimezoneLookup } from './CountryTimezoneTable';
import { City, DstRule, OfflineCityLookup } from './OfflineCityLookup';
import { HijriEngineResolver } from '../hijricalendar/HijriEngineResolver';
import { STORAGE_KEY_HIJRI_OFFSET } from '../core/StorageKeys';

const MS_PER_DAY = 86400000;

export class TimezoneResolver {
  static effectiveOffsetForLocation(latitude: number, longitude: number, date: Date): number {
    if (latitude === 0 && longitude === 0) {
      return 0;
    }

    const deviceOffset = -date.getTimezoneOffset() / 60;
    const locationOffset = TimezoneResolver.tableOffset(latitude, longitude, date);

    const useDevice = Math.abs(deviceOffset - locationOffset) <= 0.25;
    return useDevice ? deviceOffset : locationOffset;
  }

  static tableOffset(latitude: number, longitude: number, date: Date): number {
    const city: City | null = OfflineCityLookup.nearestCityForTimezone(latitude, longitude);

    if (city !== null) {
      const baseHours = city.standardOffsetMinutes / 60;
      const dstHours = TimezoneResolver.getDstOffsetMinutes(city.dstRule, date) / 60;
      return baseHours + dstHours;
    }

    // Fallback to country table (still using old float hours for now, as the new JSON
    // replaces this table entirely for 99% of cases).
    const country = CountryTimezoneLookup.zoneFor(latitude, longitude);
    if (country !== null) {
      const dstHours = TimezoneResolver.getDstOffsetMinutes(country.dstRule, date) / 60;
      return country.standardOffset + dstHours;
    }

    return Math.round(longitude / 15);
  }

  private static getDstOffsetMinutes(rule: DstRule, date: Date): number {
    const year = date.getUTCFullYear();
    switch (rule) {
      case DstRule.US:
      case DstRule.EU:
        return TimezoneResolver.isNorthernDst(date, year) ? 60 : 0;
      case DstRule.CHILE:
        return TimezoneResolver.isSouthernDst(DstRule.CHILE, date, year) ? 60 : 0;
      // Note: CHILE is southern hemisphere, see isSouthernDst below.
      case DstRule.AU:
      case DstRule.NZ:
        return TimezoneResolver.isSouthernDst(rule, date, year) ? 60 : 0;
      case DstRule.EGYPT:
        return TimezoneResolver.isEgyptDst(date, year) ? 60 : 0;
      case DstRule.PALESTINE:
        return TimezoneResolver.isPalestineDst(date, year) ? 60 : 0;
      case DstRule.MOROCCO:
        return TimezoneResolver.isMoroccoRamadan(date) ? -60 : 0; // Negative DST shift
      case DstRule.LORD_HOWE:
        return TimezoneResolver.isSouthernDst(DstRule.AU, date, year) ? 30 : 0; // 30 min shift
      default:
        return 0;
    }
  }

  // --- DST Logic Implementations ---

  private static isNorthernDst(date: Date, year: number): boolean {
    const start = TimezoneResolver.nthSunday(year, 3, 2); // 2nd Sun March
    const end = TimezoneResolver.nthSunday(year, 11, 1); // 1st Sun Nov
    const t = date.getTime();
    return t >= start.getTime() && t < end.getTime();
  }

  private static isSouthernDst(rule: DstRule, date: Date, year: number): boolean {
    const m = date.getUTCMonth();
    const t = date.getTime();
    const startMonth = rule === DstRule.NZ ? 9 : 10; // Oct (NZ is Sep)

    if (m >= startMonth) {
      const start = TimezoneResolver.nthSunday(year, startMonth, 1);
      return t >= start.getTime();
    }
    if (m <= 2) {
      return true;
    } // Jan, Feb, Mar
    if (m === 3) {
      const end = TimezoneResolver.nthSunday(year, 4, 1); // 1st Sun Apr
      return t < end.getTime();
    }
    return false;
  }

  private static isEgyptDst(date: Date, year: number): boolean {
    // Last Friday of April -> Last Thursday of October
    const start = TimezoneResolver.lastWeekdayOfMonth(year, 4, 5);
    const lastThu = TimezoneResolver.lastWeekdayOfMonth(year, 10, 4);
    const end = new Date(lastThu.getTime() + MS_PER_DAY);
    const t = date.getTime();
    return t >= start.getTime() && t < end.getTime();
  }

  private static isPalestineDst(date: Date, year: number): boolean {
    // Approximation: Last Friday of March -> Last Friday of October
    // (Official dates vary annually; this matches 95% of years).
    const start = TimezoneResolver.lastWeekdayOfMonth(year, 3, 5);
    const end = TimezoneResolver.lastWeekdayOfMonth(year, 10, 5);
    const t = date.getTime();
    return t >= start.getTime() && t < end.getTime();
  }

  private static isMoroccoRamadan(date: Date): boolean {
    // In Morocco, standard is UTC+1, but drops to UTC+0 during Ramadan.
    try {
      let offsetDays = 0;
      const stored = AppStorage.get<number>(STORAGE_KEY_HIJRI_OFFSET);
      if (stored !== undefined && !isNaN(stored)) {
        offsetDays = stored;
      }
      const shifted = new Date(date.getTime());
      shifted.setDate(shifted.getDate() + offsetDays);
      const hijri = HijriEngineResolver.current().toHijri(shifted);
      return hijri !== null && hijri.month === 9;
    } catch (err) {
      return false;
    }
  }

  private static lastWeekdayOfMonth(year: number, month: number, weekday: number): Date {
    const last = new Date(Date.UTC(year, month, 0));
    const lastDow = last.getUTCDay();
    let delta = lastDow - weekday;
    if (delta < 0) {
      delta += 7;
    }
    return new Date(Date.UTC(year, month - 1, last.getUTCDate() - delta));
  }

  private static nthSunday(year: number, month: number, n: number): Date {
    const first = new Date(Date.UTC(year, month - 1, 1));
    const dow = first.getUTCDay();
    const day = 1 + ((7 - dow) % 7) + (n - 1) * 7;
    return new Date(Date.UTC(year, month - 1, day));
  }
}