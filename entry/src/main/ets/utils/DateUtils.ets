// entry/src/main/ets/utils/DateUtils.ets

import { UpcomingImportantDate } from '../models/DateModels';
import { IMPORTANT_ISLAMIC_EVENTS } from '../data/IslamicEvents';

const MS_PER_DAY = 86400000;

export class DateHelper {

  /**
   * Find the next Gregorian date whose app-visible Hijri date matches
   * `targetMonth / targetDay`.
   *
   * The app's "visible Hijri date" for a given Gregorian day D is
   * hijri(D + offsetDays), because the user's Hijri offset shifts
   * their entire Hijri calendar. So we look for the first Gregorian
   * day G such that hijri(G + offsetDays) == target.
   *
   * Scans up to 366 days from `startDate`.
   */
  static findGregorianDateForHijri(
    targetMonth: number,
    targetDay: number,
    startDate: Date,
    offsetDays: number
  ): Date | null {
    const fmt = new Intl.DateTimeFormat('en-u-ca-islamic', {
      month: 'numeric',
      day: 'numeric'
    });

    for (let i = 0; i < 366; i++) {
      const testDate = new Date(startDate.getTime() + i * MS_PER_DAY);

      // Apply the user's Hijri offset before reading the Hijri day.
      const shifted = new Date(testDate);
      shifted.setDate(shifted.getDate() + offsetDays);

      const parts = fmt.formatToParts(shifted);
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

  /**
   * Next 3 upcoming events with a `daysUntil` countdown, honouring
   * the user's Hijri calendar offset.
   *
   * @param offsetDays  The Hijri offset from Settings (+3 … −3).
   */
  static getUpcomingImportantDates(offsetDays: number): UpcomingImportantDate[] {
    const now = new Date();
    const todayMidnight = new Date(now);
    todayMidnight.setHours(0, 0, 0, 0);

    // Hoisted out of the loop so we don't rebuild it for each event.
    const hijriFormatter = new Intl.DateTimeFormat('en-u-ca-islamic', {
      day: 'numeric',
      month: 'long',
      year: 'numeric'
    });

    const found: UpcomingImportantDate[] = [];

    for (const event of IMPORTANT_ISLAMIC_EVENTS) {
      const gregorianDate = DateHelper.findGregorianDateForHijri(
        event.month, event.day, now, offsetDays
      );
      if (!gregorianDate) {
        continue;
      }

      const eventMidnight = new Date(gregorianDate);
      eventMidnight.setHours(0, 0, 0, 0);

      // Skip events that already passed (today counts as "not passed").
      if (eventMidnight.getTime() < todayMidnight.getTime()) {
        continue;
      }

      const daysUntil = Math.round(
        (eventMidnight.getTime() - todayMidnight.getTime()) / MS_PER_DAY
      );

      // Displayed Hijri string must also reflect the offset so it
      // matches what the app shows on the Home header / calendar.
      const shiftedForDisplay = new Date(gregorianDate);
      shiftedForDisplay.setDate(shiftedForDisplay.getDate() + offsetDays);

      const entry: UpcomingImportantDate = {
        key: event.key,
        name: event.name,
        hijriDate: hijriFormatter.format(shiftedForDisplay),
        gregorianDate: gregorianDate,
        daysUntil: daysUntil
      };
      found.push(entry);
    }

    found.sort((a, b) => a.gregorianDate.getTime() - b.gregorianDate.getTime());
    return found.slice(0, 3);
  }

  /**
   * Islamic (Hijri) date for any given date.
   * Example: "19 Rabi I 1448"
   *
   * Callers that need the offset applied should shift the date
   * themselves before calling (see HomePage.refreshHijriDate).
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