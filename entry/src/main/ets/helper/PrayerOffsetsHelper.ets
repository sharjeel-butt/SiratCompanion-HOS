// entry/src/main/ets/utils/PrayerOffsetsHelper.ets

import { PrayerOffsets } from './SettingsHelper';

export type OffsetKey = 'fajr' | 'dhuhr' | 'asr' | 'maghrib' | 'isha';

export class PrayerOffsetsHelper {

  static get(offsets: PrayerOffsets, key: OffsetKey): number {
    switch (key) {
      case 'fajr':    return offsets.fajr;
      case 'dhuhr':   return offsets.dhuhr;
      case 'asr':     return offsets.asr;
      case 'maghrib': return offsets.maghrib;
      case 'isha':    return offsets.isha;
      default:        return 0;
    }
  }

  static set(offsets: PrayerOffsets, key: OffsetKey, value: number): PrayerOffsets {
    return {
      fajr:    key === 'fajr'    ? value : offsets.fajr,
      dhuhr:   key === 'dhuhr'   ? value : offsets.dhuhr,
      asr:     key === 'asr'     ? value : offsets.asr,
      maghrib: key === 'maghrib' ? value : offsets.maghrib,
      isha:    key === 'isha'    ? value : offsets.isha
    };
  }

  static clamp(value: number): number {
    if (value > 60) return 60;
    if (value < -60) return -60;
    return value;
  }

  static format(value: number): string {
    // Always show a sign, including for zero, so the pill reads like
    // a signed delta rather than a plain number. Uses the Unicode
    // minus sign (U+2212) so it looks balanced next to the plus.
    if (value === 0)  return '+0';
    if (value > 0)    return `+${value}`;
    return `\u2212${Math.abs(value)}`;
  }

  static readonly ZERO: PrayerOffsets = { fajr: 0, dhuhr: 0, asr: 0, maghrib: 0, isha: 0 };
}