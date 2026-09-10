// entry/src/main/ets/utils/DateUtils.ets

import { UpcomingImportantDate } from '../models/DateModels';
import { IMPORTANT_ISLAMIC_EVENTS } from '../data/IslamicEvents';

export class DateHelper {

  static getCurrentHijriYear(): number {
    const now = new Date();
    const formatter = new Intl.DateTimeFormat('en-u-ca-islamic', { year: 'numeric' });
    const parts = formatter.formatToParts(now);
    const yearPart = parts.find((part) => part.type === 'year'); // arrow function
    return yearPart ? parseInt(yearPart.value, 10) : 1448;
  }

  static findGregorianDateForHijri(targetMonth: number, targetDay: number, startDate: Date): Date | null {
    for (let i = 0; i < 366; i++) {
      const testDate = new Date(startDate.getTime() + i * 24 * 60 * 60 * 1000);
      const formatter = new Intl.DateTimeFormat('en-u-ca-islamic', {
        month: 'numeric',
        day: 'numeric'
      });
      const parts = formatter.formatToParts(testDate);
      let month = 0;
      let day = 0;
      for (const part of parts) {
        if (part.type === 'month') {
          month = parseInt(part.value, 10);
        } else if (part.type === 'day') {
          day = parseInt(part.value, 10);
        }
      }
      if (month === targetMonth && day === targetDay) {
        return testDate;
      }
    }
    return null;
  }

  static getUpcomingImportantDates(): UpcomingImportantDate[] {
    const now = new Date();
    const events = IMPORTANT_ISLAMIC_EVENTS;
    const found: UpcomingImportantDate[] = [];

    for (const event of events) {
      // 🔥 Use the CLASS NAME, not 'this'
      const gregorianDate = DateHelper.findGregorianDateForHijri(event.month, event.day, now);
      if (gregorianDate && gregorianDate.getTime() >= now.getTime()) {
        const hijriFormatter = new Intl.DateTimeFormat('en-u-ca-islamic', {
          day: 'numeric',
          month: 'long',
          year: 'numeric'
        });
        const hijriDate = hijriFormatter.format(gregorianDate);
        found.push({
          name: event.name,
          hijriDate: hijriDate,
          gregorianDate: gregorianDate
        });
      }
    }

    found.sort((a, b) => a.gregorianDate.getTime() - b.gregorianDate.getTime()); // arrow function
    return found.slice(0, 2);
  }

  static getFormattedFullDate(): string {
    const now = new Date();
    const hijriFormatter = new Intl.DateTimeFormat('en-u-ca-islamic', {
      day: 'numeric',
      month: 'long',
      year: 'numeric'
    });
    const hijriDate = hijriFormatter.format(now).replace(' AH', '');

    const georgianDate = now.toLocaleDateString(undefined, {
      weekday: 'long',
      month: 'long',
      day: 'numeric',
      year: 'numeric'
    });

    return `${hijriDate} (${georgianDate})`;
  }

  static getFormattedHijriDate(): string {
    const now = new Date();
    const hijriFormatter = new Intl.DateTimeFormat('en-u-ca-islamic', {
      day: 'numeric',
      month: 'long',
      year: 'numeric'
    });
    const hijriDate = hijriFormatter.format(now).replace(' AH', '');

    return `${hijriDate}`;
  }
}