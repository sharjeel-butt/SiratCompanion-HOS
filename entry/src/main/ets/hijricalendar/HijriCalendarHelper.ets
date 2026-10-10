// entry/src/main/ets/utils/HijriCalendarHelper.ets

import { CalendarDay, HijriDate } from './HijriCalendarModels';
import { IslamicEvent } from '../models/DateModels';
import { IMPORTANT_ISLAMIC_EVENTS } from '../data/IslamicEvents';
import { HijriCalendarType } from './HijriCalendarType';
import { HijriCalendarEngine } from './HijriCalendarEngine';
import { TabularHijriEngine } from './TabularHijriEngine';
import { UmmAlQuraEngine } from './UmmAlQuraEngine';
import { STORAGE_KEY_HIJRI_CALENDAR_TYPE } from '../common/StorageKeys';

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
  private static formatter: Intl.DateTimeFormat | null = null;
  private static readonly ummAlQura: UmmAlQuraEngine = new UmmAlQuraEngine();
  private static readonly tabular: TabularHijriEngine = new TabularHijriEngine();

  /** Currently selected engine, read from AppStorage. */
  private static activeEngine(): HijriCalendarEngine {
    const v = AppStorage.get<string>(STORAGE_KEY_HIJRI_CALENDAR_TYPE);
    if (v === HijriCalendarType.TABULAR) {
      return HijriCalendarHelper.tabular;
    }
    return HijriCalendarHelper.ummAlQura;
  }

  /**
   * Return the Hijri date for a given Gregorian date, after applying
   * the user's offset (in days). Positive offset moves the Hijri date
   * forward (a day later than the calculation).
   */
  static getHijriDate(date: Date, offsetDays: number): HijriDate {
    const adjusted = new Date(date.getTime());
    adjusted.setDate(adjusted.getDate() + offsetDays);

    const engine = HijriCalendarHelper.activeEngine();
    const result = engine.toHijri(adjusted);
    if (result !== null) {
      return result;
    }

    // Fallback: parse the Intl-formatted date.
    const parts = HijriCalendarHelper.getFormatter().formatToParts(adjusted);
    let y = 0;
    let m = 0;
    let d = 0;
    for (const p of parts) {
      if (p.type === 'year') {
        y = parseInt(p.value, 10);
      } else if (p.type === 'month') {
        m = parseInt(p.value, 10);
      } else if (p.type === 'day') {
        d = parseInt(p.value, 10);
      }
    }
    const fallback: HijriDate = { year: y, month: m, day: d };
    return fallback;
  }

  static monthName(month: number): string {
    return HIJRI_MONTH_NAMES[month - 1] || '';
  }

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

  static findGregorianForHijri(
    year: number,
    month: number,
    day: number,
    offsetDays: number,
    anchor: Date,
    range: number = 60
  ): Date | null {
    // Offset shifts the entire Hijri calendar, so to find the
    // Gregorian date whose *visible* Hijri date is (year, month, day),
    // we look for a Gregorian date G such that hijri(G + offset) ==
    // target. That is equivalent to converting the target Hijri date
    // to Gregorian via the engine, then subtracting the offset.
    const engine = HijriCalendarHelper.activeEngine();
    const target: HijriDate = { year, month, day };
    const direct = engine.toGregorian(target);
    if (direct !== null) {
      direct.setDate(direct.getDate() - offsetDays);
      return direct;
    }
    // Fallback: scan around the anchor.
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

    const engine = HijriCalendarHelper.activeEngine();
    const out: CalendarDay[] = [];
    for (let i = 0; i < 31; i++) {
      const g = new Date(firstGreg.getTime() + i * MS_PER_DAY);
      const h = HijriCalendarHelper.getHijriDate(g, offsetDays);
      if (h.year !== year || h.month !== month) {
        break;
      }

      const gm = new Date(g.getTime());
      gm.setHours(0, 0, 0, 0);

      const events = HijriCalendarHelper.eventsFor(h.month, h.day);
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

  static eventsFor(hijriMonth: number, hijriDay: number): string[] {
    const out: string[] = [];
    for (const e of IMPORTANT_ISLAMIC_EVENTS) {
      if (e.month === hijriMonth && e.day === hijriDay) {
        out.push(e.name);
      }
    }
    return out;
  }

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

  private static getFormatter(): Intl.DateTimeFormat {
    if (HijriCalendarHelper.formatter === null) {
      HijriCalendarHelper.formatter = new Intl.DateTimeFormat(
        'en-u-ca-islamic',
        { day: 'numeric', month: 'numeric', year: 'numeric' }
      );
    }
    return HijriCalendarHelper.formatter;
  }
}