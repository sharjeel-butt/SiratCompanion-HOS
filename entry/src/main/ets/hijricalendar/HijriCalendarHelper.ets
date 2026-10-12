// entry/src/main/ets/hijricalendar/HijriCalendarHelper.ets

import { CalendarDay, HijriDate } from './HijriCalendarModels';
import {
  EventRecurrence, IslamicEvent
} from '../models/DateModels';
import { IMPORTANT_ISLAMIC_EVENTS } from '../data/IslamicEvents';
import { HijriEngineResolver } from '../hijricalendar/HijriEngineResolver';

export const HIJRI_MONTH_NAMES: string[] = [
  'Muharram',
  'Safar',
  'Rabi al-Awwal',
  'Rabi al-Thani',
  'Jumada al-Awwal',
  'Jumada al-Thani',
  'Rajab',
  "Sha'ban",
  'Ramadan',
  'Shawwal',
  "Dhu al-Qi'dah",
  'Dhu al-Hijjah'
];

export const DAYS_OF_WEEK_SHORT: string[] = [
  'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'
];

const MS_PER_DAY = 86400000;

export class HijriCalendarHelper {

  /**
   * Return the Hijri date for a given Gregorian date, after applying
   * the user's offset (in days). Positive offset moves the Hijri date
   * forward (a day later than the civil calculation).
   *
   * Conversion runs through whichever engine the user has selected
   * in Settings → Hijri Calendar (Umm al-Qura or Tabular), so the
   * calendar page matches the Home header, the Home countdown card,
   * and the Hijri offset preview.
   */
  static getHijriDate(date: Date, offsetDays: number): HijriDate {
    const adjusted = new Date(date.getTime());
    adjusted.setDate(adjusted.getDate() + offsetDays);

    const h = HijriEngineResolver.current().toHijri(adjusted);
    if (h !== null) {
      return h;
    }

    // The engines return null only when the Gregorian Julian Day
    // Number is negative — i.e. a date before 4713 BC. Unreachable
    // for any date a user can enter through the UI. Return a
    // neutral placeholder rather than throwing so a stray call
    // from a preview or a test harness cannot crash the page.
    const placeholder: HijriDate = { year: 0, month: 0, day: 0 };
    return placeholder;
  }

  static monthName(month: number): string {
    return HIJRI_MONTH_NAMES[month - 1] || '';
  }

  /** Add or subtract months, rolling the year over as needed. */
  static shiftMonth(year: number, month: number, delta: number): HijriDate {
    let m = month + delta;
    let y = year;
    while (m < 1) {
      m += 12;
      y -= 1;
    }
    while (m > 12) {
      m -= 12;
      y += 1;
    }
    const result: HijriDate = { year: y, month: m, day: 1 };
    return result;
  }

  /**
   * Find the Gregorian date matching a Hijri (year, month, day),
   * searching ±`range` days from the anchor. Default ±60 is enough
   * for month navigation.
   */
  static findGregorianForHijri(
    year: number,
    month: number,
    day: number,
    offsetDays: number,
    anchor: Date,
    range: number = 60
  ): Date | null {
    const anchorMs = anchor.getTime();
    for (let i = -range; i <= range; i++) {
      const candidate = new Date(anchorMs + i * MS_PER_DAY);
      const h = HijriCalendarHelper.getHijriDate(candidate, offsetDays);
      if (h.year === year && h.month === month && h.day === day) {
        return candidate;
      }
    }
    return null;
  }

  /**
   * Build the ordered list of days for a Hijri month. Length is 29 or 30.
   * Empty array if the anchor can't resolve the month.
   */
  static buildMonthDays(
    year: number,
    month: number,
    offsetDays: number,
    anchor: Date
  ): CalendarDay[] {
    const firstGreg = HijriCalendarHelper.findGregorianForHijri(
      year, month, 1, offsetDays, anchor
    );
    if (firstGreg === null) {
      return [];
    }

    const todayMidnight = new Date();
    todayMidnight.setHours(0, 0, 0, 0);

    const out: CalendarDay[] = [];
    for (let i = 0; i < 31; i++) {
      const g = new Date(firstGreg.getTime() + i * MS_PER_DAY);
      const h = HijriCalendarHelper.getHijriDate(g, offsetDays);
      if (h.year !== year || h.month !== month) {
        break;
      }

      const gm = new Date(g.getTime());
      gm.setHours(0, 0, 0, 0);

      const events = HijriCalendarHelper.eventsFor(h.month, h.day, g);
      const cd: CalendarDay = {
        gregorianDate: g,
        hijri: h,
        isToday: gm.getTime() === todayMidnight.getTime(),
        isFriday: g.getDay() === 5,
        events: events
      };
      out.push(cd);
    }
    return out;
  }

  /**
   * Event keys that fall on a given Hijri month/day.
   *
   * Returns the stable `IslamicEvent.key` (e.g. 'ashura', 'eid_fitr'),
   * not the English display name. Callers that need a localized label
   * should resolve it via `L.get('event_' + key, lang)`, matching how
   * every other event surface in the app works.
   *
   * @param hijriMonth  Hijri month of the cell.
   * @param hijriDay    Hijri day of the cell.
   * @param gregorianDate  Gregorian date of the cell, used to resolve
   *                    rule-based events like FIRST_THURSDAY_NIGHT
   *                    that depend on the day of the week.
   */
  static eventsFor(
    hijriMonth: number,
    hijriDay: number,
    gregorianDate?: Date
  ): string[] {
    const out: string[] = [];
    for (const e of IMPORTANT_ISLAMIC_EVENTS) {
      if (e.recurrence === EventRecurrence.FIRST_THURSDAY_NIGHT) {
        if (gregorianDate !== undefined &&
          e.month === hijriMonth &&
          gregorianDate.getDay() === 4 &&
          hijriDay >= 1 && hijriDay <= 7) {
          out.push(e.key);
        }
        continue;
      }
      if (e.month === hijriMonth && e.day === hijriDay) {
        out.push(e.key);
      }
    }
    return out;
  }

  /** All events in a Hijri month, in calendar order. */
  static eventsInMonth(hijriMonth: number): IslamicEvent[] {
    const out: IslamicEvent[] = [];
    for (const e of IMPORTANT_ISLAMIC_EVENTS) {
      if (e.month === hijriMonth) {
        out.push(e);
      }
    }
    out.sort((a: IslamicEvent, b: IslamicEvent): number => a.day - b.day);
    return out;
  }

  /** "Sep 15 – Oct 14, 2025" style string for the Gregorian span. */
  static formatGregorianSpan(days: CalendarDay[]): string {
    if (days.length === 0) {
      return '';
    }
    const first = days[0].gregorianDate;
    const last = days[days.length - 1].gregorianDate;
    const monthShort = (d: Date): string =>
    d.toLocaleDateString('en-US', { month: 'short' });
    const year = last.getFullYear();

    if (first.getMonth() === last.getMonth() &&
      first.getFullYear() === last.getFullYear()) {
      return `${monthShort(first)} ${first.getDate()} – ${last.getDate()}, ${year}`;
    }
    return `${monthShort(first)} ${first.getDate()} – ` +
      `${monthShort(last)} ${last.getDate()}, ${year}`;
  }
}