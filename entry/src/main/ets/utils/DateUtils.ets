// entry/src/main/ets/utils/DateUtils.ets

import { UpcomingImportantDate } from '../models/DateModels';
import { IMPORTANT_ISLAMIC_EVENTS } from '../data/IslamicEvents';

export class DateHelper {

  /**
   * Find the next Gregorian date matching a Hijri month/day, starting
   * from `startDate`. Scans up to 366 days.
   *
   * The Intl.DateTimeFormat is hoisted out of the loop — creating 366
   * formatter instances per event × 9 events was a cold-start bottleneck.
   */
  static findGregorianDateForHijri(
    targetMonth: number,
    targetDay: number,
    startDate: Date
  ): Date | null {
    const fmt = new Intl.DateTimeFormat('en-u-ca-islamic', {
      month: 'numeric',
      day: 'numeric'
    });

    for (let i = 0; i < 366; i++) {
      const testDate = new Date(startDate.getTime() + i * 86_400_000);
      const parts = fmt.formatToParts(testDate);
      let month = 0;
      let day = 0;
      for (const part of parts) {
        if (part.type === 'month') month = parseInt(part.value, 10);
        else if (part.type === 'day') day = parseInt(part.value, 10);
      }
      if (month === targetMonth && day === targetDay) {
        return testDate;
      }
    }
    return null;
  }

  static getUpcomingImportantDates(): UpcomingImportantDate[] {
    const now = new Date();
    const found: UpcomingImportantDate[] = [];

    for (const event of IMPORTANT_ISLAMIC_EVENTS) {
      const gregorianDate = DateHelper.findGregorianDateForHijri(
        event.month, event.day, now
      );
      if (gregorianDate && gregorianDate.getTime() >= now.getTime()) {
        const hijriFormatter = new Intl.DateTimeFormat('en-u-ca-islamic', {
          day: 'numeric',
          month: 'long',
          year: 'numeric'
        });
        found.push({
          key: event.key,
          name: event.name,
          hijriDate: hijriFormatter.format(gregorianDate),
          gregorianDate: gregorianDate
        });
      }
    }

    found.sort((a, b) => a.gregorianDate.getTime() - b.gregorianDate.getTime());
    return found.slice(0, 2);
  }

  /**
   * Islamic (Hijri) date for any given date.
   * Example: "19 Rabi I 1448"
   */
  static getFormattedHijriDateFor(date: Date): string {
    const hijriFormatter = new Intl.DateTimeFormat('en-u-ca-islamic', {
      day: 'numeric',
      month: 'long',
      year: 'numeric'
    });
    return hijriFormatter.format(date).replace(' AH', '');
  }

  static getFormattedHijriDate(): string {
    return DateHelper.getFormattedHijriDateFor(new Date());
  }
}