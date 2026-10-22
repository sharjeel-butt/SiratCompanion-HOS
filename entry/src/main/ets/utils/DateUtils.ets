// entry/src/main/ets/utils/DateUtils.ets

import { eventMatchesPerspective, IMPORTANT_ISLAMIC_EVENTS } from '../data/IslamicEvents';
import {
  EventRecurrence, IslamicEvent, UpcomingImportantDate
} from '../models/DateModels';
import { HijriEngineResolver } from '../hijricalendar/HijriEngineResolver';
import { L } from '../i8n/LocalizationHelper';

const MS_PER_DAY = 86400000;

/**
 * Hijri month names in English, matching the names shown elsewhere
 * in the app. Kept local rather than imported so this module has no
 * dependency on the calendar-page helper.
 */
const HIJRI_MONTHS_EN: string[] = [
  'Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi al-Thani',
  'Jumada al-Awwal', 'Jumada al-Thani', 'Rajab', "Sha'ban",
  'Ramadan', 'Shawwal', "Dhu al-Qi'dah", 'Dhu al-Hijjah'
];

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
   * Scans up to 366 days from `startDate`. Conversion runs through
   * the engine selected by the user's calendar-type setting, so the
   * result reflects Umm al-Qura or Tabular as configured.
   */
  static findGregorianDateForHijri(
    targetMonth: number,
    targetDay: number,
    startDate: Date,
    offsetDays: number
  ): Date | null {
    const engine = HijriEngineResolver.current();

    for (let i = 0; i < 366; i++) {
      const testDate = new Date(startDate.getTime() + i * MS_PER_DAY);

      // Apply the user's Hijri offset before reading the Hijri day.
      const shifted = new Date(testDate);
      shifted.setDate(shifted.getDate() + offsetDays);

      const h = engine.toHijri(shifted);
      if (h !== null && h.month === targetMonth && h.day === targetDay) {
        return testDate;
      }
    }
    return null;
  }

  /**
   * Find the next Gregorian date on which an event occurs, honouring
   * the user's Hijri offset and calendar-type setting.
   *
   * FIXED events scan for a specific Hijri (month, day).
   *
   * FIRST_THURSDAY_NIGHT events scan for the first Gregorian
   * Thursday whose visible Hijri date falls within the first seven
   * days of the target Hijri month.
   */
  private static findNextGregorianForEvent(
    event: IslamicEvent,
    startDate: Date,
    offsetDays: number
  ): Date | null {
    if (event.recurrence === EventRecurrence.FIXED) {
      return DateHelper.findGregorianDateForHijri(
        event.month, event.day, startDate, offsetDays
      );
    }

    const engine = HijriEngineResolver.current();

    for (let i = 0; i < 366; i++) {
      const testDate = new Date(startDate.getTime() + i * MS_PER_DAY);

      // Thursday = 4 (Sunday = 0).
      if (testDate.getDay() !== 4) {
        continue;
      }

      const shifted = new Date(testDate);
      shifted.setDate(shifted.getDate() + offsetDays);

      const h = engine.toHijri(shifted);
      if (h !== null && h.month === event.month &&
        h.day >= 1 && h.day <= 7) {
        return testDate;
      }
    }
    return null;
  }

  /**
   * Next 3 upcoming events with a `daysUntil` countdown, honouring
   * the user's Hijri calendar offset and calendar-type setting.
   *
   * @param offsetDays  The Hijri offset from Settings (+3 … −3).
   */
  static getUpcomingImportantDates(
    offsetDays: number,
    perspective: string = 'universal'
  ): UpcomingImportantDate[] {
    const now = new Date();
    const todayMidnight = new Date(now);
    todayMidnight.setHours(0, 0, 0, 0);

    const engine = HijriEngineResolver.current();
    const found: UpcomingImportantDate[] = [];

    for (const event of IMPORTANT_ISLAMIC_EVENTS) {
      if (!eventMatchesPerspective(event, perspective)) {
        continue;
      }
      const gregorianDate = DateHelper.findNextGregorianForEvent(
        event, now, offsetDays
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

      // Displayed Hijri string must also reflect the offset and the
      // selected engine so it matches the Home header / calendar.
      const shiftedForDisplay = new Date(gregorianDate);
      shiftedForDisplay.setDate(
        shiftedForDisplay.getDate() + offsetDays
      );

      const h = engine.toHijri(shiftedForDisplay);
      let hijriString = '';
      if (h !== null) {
        const lang = L.current();
        const localizedMonths = L.getArray('hijri_months', lang);
        const monthName = localizedMonths[h.month - 1] || HIJRI_MONTHS_EN[h.month - 1];
        hijriString = `${h.day} ${monthName} ${h.year}`;
      }

      const entry: UpcomingImportantDate = {
        key: event.key,
        name: event.name,
        hijriDate: hijriString,
        gregorianDate: gregorianDate,
        daysUntil: daysUntil
      };
      found.push(entry);
    }

    found.sort(
      (a, b) => a.gregorianDate.getTime() - b.gregorianDate.getTime()
    );
    return found.slice(0, 3);
  }

  /**
   * Islamic (Hijri) date for any given date.
   * Example: "19 Rabi al-Awwal 1448"
   *
   * Callers that need the offset applied should shift the date
   * themselves before calling (see HomePage.refreshHijriDate).
   */
  static getFormattedHijriDateFor(date: Date): string {
    const engine = HijriEngineResolver.current();
    const h = engine.toHijri(date);
    if (h === null) {
      return '';
    }

    // Fetch localized month names
    const lang = L.current();
    const months = L.getArray('hijri_months', lang);
    const monthName = months[h.month - 1] || '';

    return `${h.day} ${monthName} ${h.year}`;
  }

  static getFormattedHijriDate(): string {
    return DateHelper.getFormattedHijriDateFor(new Date());
  }
}