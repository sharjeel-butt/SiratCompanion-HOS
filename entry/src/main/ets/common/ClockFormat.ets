// entry/src/main/ets/common/ClockFormat.ets

import { STORAGE_KEY_TIME_FORMAT } from './StorageKeys';

export enum ClockFormat {
  SYSTEM = 'System',
  TWELVE_HOUR = '12h',
  TWENTY_FOUR_HOUR = '24h'
}

export class ClockFormatHelper {
  /** Current preference as stored by the user. */
  static current(): ClockFormat {
    const v = AppStorage.get<string>(STORAGE_KEY_TIME_FORMAT);
    if (v === ClockFormat.TWELVE_HOUR) {
      return ClockFormat.TWELVE_HOUR;
    }
    if (v === ClockFormat.TWENTY_FOUR_HOUR) {
      return ClockFormat.TWENTY_FOUR_HOUR;
    }
    return ClockFormat.SYSTEM;
  }

  /** Resolved boolean — true when times should be shown as 24-hour. */
  static use24Hour(): boolean {
    const f = ClockFormatHelper.current();
    if (f === ClockFormat.TWENTY_FOUR_HOUR) {
      return true;
    }
    if (f === ClockFormat.TWELVE_HOUR) {
      return false;
    }
    return ClockFormatHelper.isSystem24Hour();
  }

  /**
   * Reformat the app's internal 12-hour string ("5:23 AM") into the
   * user's preferred display format.
   */
  static reformat(timeStr: string): string {
    if (timeStr === undefined || timeStr === null) {
      return '--:--';
    }
    const trimmed: string = timeStr.trim();
    if (trimmed.length === 0 || trimmed === '--:--') {
      return timeStr;
    }

    const minutes: number = ClockFormatHelper.parseToMinutes(trimmed);
    if (minutes < 0) {
      return timeStr;
    }
    return ClockFormatHelper.formatMinutes(minutes);
  }

  /** Format a minutes-since-midnight value in the user's preferred format. */
  static formatMinutes(totalMinutes: number): string {
    const clamped: number = ((totalMinutes % 1440) + 1440) % 1440;
    const h: number = Math.floor(clamped / 60);
    const m: number = clamped % 60;
    const mm: string = m.toString().padStart(2, '0');

    if (ClockFormatHelper.use24Hour()) {
      return `${h.toString().padStart(2, '0')}:${mm}`;
    }
    const period: string = h >= 12 ? 'PM' : 'AM';
    let dh: number = h % 12;
    if (dh === 0) {
      dh = 12;
    }
    return `${dh}:${mm} ${period}`;
  }

  /**
   * Detect the device's hour-cycle preference by formatting a known
   * afternoon time (15:00) and inspecting the leading hour digit.
   *
   * A 24-hour locale formats 15:00 as "15" (or "15时"); a 12-hour
   * locale formats it as "3 PM" or a localized form. Arabic-Indic
   * digits are normalized to Latin before parsing.
   */
  private static isSystem24Hour(): boolean {
    try {
      const test: Date = new Date(2020, 0, 1, 15, 0, 0);
      const options: Intl.DateTimeFormatOptions = { hour: 'numeric' };
      const formatter: Intl.DateTimeFormat =
        new Intl.DateTimeFormat('en-GB', options);
      const formatted: string = formatter.format(test);

      let normalized: string = '';
      for (let i = 0; i < formatted.length; i++) {
        const code: number = formatted.charCodeAt(i);
        // Arabic-Indic digits U+0660–U+0669 → ASCII 0–9.
        if (code >= 0x0660 && code <= 0x0669) {
          normalized += String.fromCharCode(code - 0x0660 + 0x30);
        } else {
          normalized += formatted.charAt(i);
        }
      }

      const match: RegExpMatchArray | null = normalized.match(/\d+/);
      if (match !== null) {
        const hour: number = parseInt(match[0], 10);
        if (!isNaN(hour)) {
          return hour > 12;
        }
      }

      const lower: string = normalized.toLowerCase();
      if (lower.indexOf('am') >= 0 || lower.indexOf('pm') >= 0) {
        return false;
      }
    } catch (err) {
      // Fall through.
    }

    // Last resort — assume 12-hour.
    return false;
  }

  /**
   * Parse "5:23 AM" or "17:23" into minutes since midnight.
   * Returns -1 on failure.
   */
  private static parseToMinutes(timeStr: string): number {
    const parts: string[] = timeStr.split(' ');
    if (parts.length === 1) {
      const tp: string[] = parts[0].split(':');
      if (tp.length !== 2) {
        return -1;
      }
      const h: number = parseInt(tp[0], 10);
      const m: number = parseInt(tp[1], 10);
      if (isNaN(h) || isNaN(m)) {
        return -1;
      }
      return h * 60 + m;
    }
    if (parts.length !== 2) {
      return -1;
    }
    const tp: string[] = parts[0].split(':');
    if (tp.length !== 2) {
      return -1;
    }
    let h: number = parseInt(tp[0], 10);
    const m: number = parseInt(tp[1], 10);
    const period: string = parts[1].toUpperCase();
    if (isNaN(h) || isNaN(m)) {
      return -1;
    }
    if (period === 'PM' && h !== 12) {
      h += 12;
    }
    if (period === 'AM' && h === 12) {
      h = 0;
    }
    return h * 60 + m;
  }
}