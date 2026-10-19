// entry/src/main/ets/common/ClockFormat.ets

import { i18n } from '@kit.LocalizationKit';
import { settings } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
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

  /** Reformat the app's internal 12-hour string ("5:23 AM") into the
   *  user's preferred display format. */
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

  // ============================================================
  // SYSTEM HOUR-CYCLE DETECTION
  // ============================================================
  //
  // Detection layers, tried in order:
  //
  //   1. i18n.System.is24HourClock()  — authoritative. Reads the
  //      OS 24-hour toggle from the system config. Available since
  //      API 9. This is the API Huawei documents for exactly this
  //      purpose.
  //
  //   2. @ohos.settings TIME_FORMAT   — secondary. Reads the same
  //      toggle through the settings database. Returns "24" or "12".
  //      Only used if layer 1 is unavailable.
  //
  //   3. Intl.DateTimeFormat          — last resort. Known to be
  //      unreliable on HarmonyOS (ignores hour12 / hourCycle
  //      overrides), so this layer is genuinely a fallback for
  //      exotic builds, not a primary signal.
  //
  // If the app still shows 12-hour on a 24-hour device, check the
  // HiLog line "[ClockFormat] is24HourClock = true|false" printed
  // once at startup. That is what the OS reports, and it is what
  // the rest of the app will follow.

  private static hourCycleLogged: boolean = false;

  private static isSystem24Hour(): boolean {
    // ---- Layer 1: i18n.System.is24HourClock() (authoritative) ----
    try {
      const is24: boolean = i18n.System.is24HourClock();

      if (!ClockFormatHelper.hourCycleLogged) {
        ClockFormatHelper.hourCycleLogged = true;
        console.info(`[ClockFormat] is24HourClock = ${is24}`);
      }
      return is24;
    } catch (err) {
      console.warn(
        '[ClockFormat] i18n.System.is24HourClock() threw: ' +
          JSON.stringify(err)
      );
    }

    // ---- Layer 2: @ohos.settings TIME_FORMAT ("24" | "12") ----
    // settings.date.TIME_FORMAT: "24" for 24-hour, "12" for 12-hour.
    try {
      const context = getContext() as common.Context;
      const raw: string = settings.getValueSync(
        context,
        settings.date.TIME_FORMAT,
        '12'
      );
      return raw === '24';
    } catch (err) {
      // No context (e.g. called from a plain JS module), or the
      // setting isn't readable — fall through.
    }

    // ---- Layer 3: Intl.DateTimeFormat (last resort) ----
    try {
      const resolved = new Intl.DateTimeFormat(undefined, {
        hour: 'numeric'
      }).resolvedOptions();

      if (typeof resolved.hour12 === 'boolean') {
        return !resolved.hour12;
      }

      const hc = resolved.hourCycle;
      if (hc === 'h23' || hc === 'h24') {
        return true;
      }
      if (hc === 'h11' || hc === 'h12') {
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