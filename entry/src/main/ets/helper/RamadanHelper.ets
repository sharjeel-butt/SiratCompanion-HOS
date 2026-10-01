// entry/src/main/ets/utils/RamadanHelper.ets

import { HijriCalendarHelper } from './HijriCalendarHelper';
import { DateHelper } from '../utils/DateUtils';
import { HijriDate } from '../models/HijriCalendarModels';

/** One of the three ten-day periods of Ramadan. */
export interface RamadanAshra {
  number: number; // 1, 2, 3
  startHijriDay: number; // 1, 11, 21
  endHijriDay: number; // 10, 20, lastDay
  startDate: Date;
  endDate: Date;
  nameKey: string; // 'ramadan_first_ashra', etc.
  significanceKey: string; // 'ramadan_first_ashra_significance', etc.
}

/** One candidate night for Laylat al-Qadr (odd nights of last ashra). */
export interface LaylatAlQadrNight {
  hijriDay: number; // 21, 23, 25, 27, 29
  gregorianDate: Date;
  isToday: boolean;
  isPast: boolean;
}

export interface RamadanInfo {
  hijriYear: number;
  fastingStart: Date; // 1 Ramadan
  fastingEnd: Date; // last day of Ramadan
  ashras: RamadanAshra[];
  laylatAlQadrNights: LaylatAlQadrNight[];
  jummahTulWidah: Date | null; // last Friday within Ramadan
  currentDayNumber: number; // 1..30 if today is in Ramadan, else 0
  totalDays: number; // 29 or 30
  isRamadanNow: boolean;
  daysUntilStart: number; // 0 if in Ramadan
}

const MS_PER_DAY = 86400000;

export class RamadanHelper {
  /**
   * Compute the full Ramadan information for the current or upcoming
   * Ramadan, honouring the user's Hijri offset.
   *
   * Returns null only if the Hijri calendar cannot resolve the date.
   */
  static getRamadanInfo(offsetDays: number): RamadanInfo | null {
    const now = new Date();
    const todayMidnight = new Date(now);
    todayMidnight.setHours(0, 0, 0, 0);

    const todayHijri: HijriDate = HijriCalendarHelper.getHijriDate(now, offsetDays);
    const isInRamadan = todayHijri.month === 9;

    // ---- Locate Ramadan 1st ----
    let ramadanStart: Date | null = null;
    let hijriYear = todayHijri.year;

    if (isInRamadan) {
      // Walk backwards until the Hijri month changes or day === 1.
      for (let i = 0; i <= 30; i++) {
        const test = new Date(todayMidnight);
        test.setDate(test.getDate() - i);
        const h = HijriCalendarHelper.getHijriDate(test, offsetDays);
        if (h.month !== 9) {
          break;
        }
        ramadanStart = test;
        if (h.day === 1) {
          break;
        }
      }
    } else {
      ramadanStart = DateHelper.findGregorianDateForHijri(9, 1, now, offsetDays);
      if (ramadanStart) {
        const sh = HijriCalendarHelper.getHijriDate(ramadanStart, offsetDays);
        hijriYear = sh.year;
      }
    }

    if (!ramadanStart) {
      return null;
    }
    ramadanStart.setHours(0, 0, 0, 0);

    // ---- Locate the last day of Ramadan ----
    let fastingEnd = new Date(ramadanStart);
    for (let i = 1; i <= 30; i++) {
      const test = new Date(ramadanStart);
      test.setDate(test.getDate() + i);
      const h = HijriCalendarHelper.getHijriDate(test, offsetDays);
      if (h.month !== 9) {
        break;
      }
      fastingEnd = test;
    }
    fastingEnd.setHours(0, 0, 0, 0);

    const totalDays = Math.round(
      (fastingEnd.getTime() - ramadanStart.getTime()) / MS_PER_DAY
    ) + 1;

    // ---- Ashras ----
    const ashras: RamadanAshra[] = [];

    const a1Start = new Date(ramadanStart);
    const a1End = new Date(ramadanStart);
    a1End.setDate(a1End.getDate() + 9);
    ashras.push({
      number: 1,
      startHijriDay: 1,
      endHijriDay: 10,
      startDate: a1Start,
      endDate: a1End,
      nameKey: 'ramadan_first_ashra',
      significanceKey: 'ramadan_first_ashra_significance'
    });

    const a2Start = new Date(ramadanStart);
    a2Start.setDate(a2Start.getDate() + 10);
    const a2End = new Date(ramadanStart);
    a2End.setDate(a2End.getDate() + 19);
    ashras.push({
      number: 2,
      startHijriDay: 11,
      endHijriDay: 20,
      startDate: a2Start,
      endDate: a2End,
      nameKey: 'ramadan_second_ashra',
      significanceKey: 'ramadan_second_ashra_significance'
    });

    const a3Start = new Date(ramadanStart);
    a3Start.setDate(a3Start.getDate() + 20);
    const a3End = new Date(fastingEnd);
    ashras.push({
      number: 3,
      startHijriDay: 21,
      endHijriDay: totalDays,
      startDate: a3Start,
      endDate: a3End,
      nameKey: 'ramadan_third_ashra',
      significanceKey: 'ramadan_third_ashra_significance'
    });

    // ---- Laylat al-Qadr candidate nights (odd days from 21) ----
    const laylatAlQadrNights: LaylatAlQadrNight[] = [];
    const oddDays: number[] = [21, 23, 25, 27, 29];
    for (const d of oddDays) {
      if (d > totalDays) {
        continue;
      }
      const g = new Date(ramadanStart);
      g.setDate(g.getDate() + (d - 1));
      g.setHours(0, 0, 0, 0);
      laylatAlQadrNights.push({
        hijriDay: d,
        gregorianDate: g,
        isToday: g.getTime() === todayMidnight.getTime(),
        isPast: g.getTime() < todayMidnight.getTime()
      });
    }

    // ---- Jummah tul Widah: the last Friday within Ramadan ----
    let jummahTulWidah: Date | null = null;
    for (let i = totalDays - 1; i >= 0; i--) {
      const g = new Date(ramadanStart);
      g.setDate(g.getDate() + i);
      g.setHours(0, 0, 0, 0);
      if (g.getDay() === 5) {
        jummahTulWidah = g;
        break;
      }
    }

    // ---- Current day number & days until start ----
    const currentDayNumber = isInRamadan ? todayHijri.day : 0;
    const daysUntilStart = isInRamadan
      ? 0
      : Math.round((ramadanStart.getTime() - todayMidnight.getTime()) / MS_PER_DAY);

    const info: RamadanInfo = {
      hijriYear,
      fastingStart: ramadanStart,
      fastingEnd,
      ashras,
      laylatAlQadrNights,
      jummahTulWidah,
      currentDayNumber,
      totalDays,
      isRamadanNow: isInRamadan,
      daysUntilStart
    };
    return info;
  }

  /** Short date like "Mar 15". Uses the caller's language. */
  static formatShort(date: Date, lang: string): string {
    const locale = lang === 'zh' ? 'zh-CN'
      : lang === 'ar' ? 'ar'
        : 'en-US';
    try {
      const fmt = new Intl.DateTimeFormat(locale, { month: 'short', day: 'numeric' });
      return fmt.format(date);
    } catch (err) {
      const months: string[] = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return `${months[date.getMonth()]} ${date.getDate()}`;
    }
  }

  /** Long date like "March 15, 2026". */
  static formatLong(date: Date, lang: string): string {
    const locale = lang === 'zh' ? 'zh-CN'
      : lang === 'ar' ? 'ar'
        : 'en-US';
    try {
      const fmt = new Intl.DateTimeFormat(locale, {
        month: 'long', day: 'numeric', year: 'numeric'
      });
      return fmt.format(date);
    } catch (err) {
      return date.toDateString();
    }
  }
}