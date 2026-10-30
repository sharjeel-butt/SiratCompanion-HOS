// entry/src/main/ets/hijricalendar/HijriCalendarHelper.ets

import { CalendarDay, HijriDate } from './HijriCalendarModels';
import {
  EventRecurrence, IslamicEvent
} from '../models/DateModels';
import { eventMatchesPerspective, IMPORTANT_ISLAMIC_EVENTS } from '../data/IslamicEvents';
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
    range?: number
  ): Date | null {
    let effectiveRange: number;
    if (range !== undefined) {
      effectiveRange = range;
    } else {
      effectiveRange = HijriCalendarHelper.safeSearchRange(
        year, month, day, offsetDays, anchor
      );
    }

    const anchorMs = anchor.getTime();
    for (let i = -effectiveRange; i <= effectiveRange; i++) {
      const candidate = new Date(anchorMs + i * MS_PER_DAY);
      const h = HijriCalendarHelper.getHijriDate(candidate, offsetDays);
      if (h.year === year && h.month === month && h.day === day) {
        return candidate;
      }
    }
    return null;
  }

  /**
   * Estimate the maximum number of days between the anchor and the
   * target Hijri date, with 60 days of slack for offset drift.
   */
  private static safeSearchRange(
    year: number,
    month: number,
    day: number,
    offsetDays: number,
    anchor: Date
  ): number {
    try {
      const anchorShifted = new Date(anchor.getTime());
      anchorShifted.setDate(anchorShifted.getDate() + offsetDays);
      const anchorH = HijriEngineResolver.current().toHijri(anchorShifted);
      if (anchorH === null) {
        return 60;
      }
      const yearDiff = Math.abs(year - anchorH.year);
      const monthDiff = Math.abs(month - anchorH.month);
      const estimated = yearDiff * 355 + monthDiff * 30 + 60;
      return Math.max(60, estimated);
    } catch (err) {
      return 60;
    }
  }

  /**
   * Build the ordered list of days for a Hijri month. Length is 29 or 30.
   * Empty array if the anchor can't resolve the month.
   */
  static buildMonthDays(
    year: number,
    month: number,
    offsetDays: number,
    anchor: Date,
    perspective: string = 'universal'
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

      const events = HijriCalendarHelper.eventsFor(
        h.month, h.day, g, perspective
      );
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
    gregorianDate: Date | undefined,
    perspective: string = 'universal'
  ): string[] {
    const out: string[] = [];
    for (const e of IMPORTANT_ISLAMIC_EVENTS) {
      if (!eventMatchesPerspective(e, perspective)) {
        continue;
      }
      if (e.recurrence === EventRecurrence.FIRST_THURSDAY_NIGHT) {
        // Thursday = 4. The event fires on the Thursday whose
        // next day (Friday) is within the first seven days of
        // the target Hijri month. Since the Thursday precedes
        // that Friday by one day, its Hijri day must be 0–6.
        // Day 0 is impossible, so 1–6 is the range.
        //
        // The earlier check used 1–7, which could match the
        // Thursday before the SECOND Friday of the month
        // (Hijri day 8) while missing the actual first Friday
        // when the month happened to start mid-week.
        if (gregorianDate !== undefined &&
          e.month === hijriMonth &&
          gregorianDate.getDay() === 4 &&
          hijriDay >= 1 && hijriDay <= 6) {
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
  static eventsInMonth(
    hijriMonth: number,
    perspective: string = 'universal'
  ): IslamicEvent[] {
    const out: IslamicEvent[] = [];
    for (const e of IMPORTANT_ISLAMIC_EVENTS) {
      if (!eventMatchesPerspective(e, perspective)) {
        continue;
      }
      if (e.month === hijriMonth) {
        out.push(e);
      }
    }
    out.sort((a: IslamicEvent, b: IslamicEvent): number => a.day - b.day);
    return out;
  }

  /**
   * "Sep 15 – Oct 14, 2026" style string for the Gregorian span.
   *
   * @param lang  The app's current UI language ('en' | 'ar' | 'zh').
   *              Localizes month abbreviations via Intl.DateTimeFormat.
   *              Falls back to English when Intl is unavailable.
   */
  static formatGregorianSpan(
    days: CalendarDay[], lang: string = 'en'
  ): string {
    if (days.length === 0) {
      return '';
    }
    const first = days[0].gregorianDate;
    const last = days[days.length - 1].gregorianDate;

    const locale = lang === 'zh' ? 'zh-CN'
      : lang === 'ar' ? 'ar'
        : 'en-US';

    const monthShort = (d: Date): string => {
      try {
        return d.toLocaleDateString(locale, { month: 'short' });
      } catch (err) {
        return d.toLocaleDateString('en-US', { month: 'short' });
      }
    };
    const year = last.getFullYear();

    if (first.getMonth() === last.getMonth() &&
      first.getFullYear() === last.getFullYear()) {
      return `${monthShort(first)} ${first.getDate()} – ${last.getDate()}, ${year}`;
    }
    return `${monthShort(first)} ${first.getDate()} – ` +
      `${monthShort(last)} ${last.getDate()}, ${year}`;
  }
}