// entry/src/main/ets/utils/SettingsHelper.ets

import { ThemeMode } from '../common/Theme';
import { STORAGE_KEY_THEME_MODE } from '../common/StorageKeys';
import { CalculationMethod, AsrShadowRule } from './PrayerTimeCalculator';
import { PreferencesHelper } from './PreferencesHelper';
import {
  PickerItem,
  CalculationSource,
  LocationMode,
  ManualCoords
} from '../models/SettingsModels';

const KEY_METHOD  = 'calc_method';
const KEY_ASR     = 'asr_rule';
const KEY_SOURCE  = 'calc_source';
const KEY_COUNTER = 'counter';

const KEY_LOCATION_MODE  = 'location_mode';
const KEY_MANUAL_LAT     = 'manual_lat';
const KEY_MANUAL_LNG     = 'manual_lng';
const KEY_MANUAL_REFRESH = 'manual_refresh';
const KEY_MANUAL_CITY    = 'manual_city';

const KEY_SHOW_EXTRA_TIMINGS  = 'show_extra_timings';
const KEY_SHOW_ISLAMIC_EVENTS = 'show_islamic_events';

// Prayer offset keys (values are minutes, negative = subtract)
const KEY_OFFSET_FAJR    = 'offset_fajr';
const KEY_OFFSET_DHUHR   = 'offset_dhuhr';
const KEY_OFFSET_ASR     = 'offset_asr';
const KEY_OFFSET_MAGHRIB = 'offset_maghrib';
const KEY_OFFSET_ISHA    = 'offset_isha';

// ============================================================
// INTERFACES
// ============================================================

export interface PrayerOffsets {
  fajr: number;
  dhuhr: number;
  asr: number;
  maghrib: number;
  isha: number;
}

export interface OffsetKeys {
  fajr: string;
  dhuhr: string;
  asr: string;
  maghrib: string;
  isha: string;
}

export interface LoadedSettings {
  method: CalculationMethod;
  asr: AsrShadowRule;
  source: CalculationSource;
  counter: number;
  showExtraTimings: boolean;
  showIslamicEvents: boolean;
}

export class SettingsHelper {

  // ============================================================
  // GENERAL SETTINGS
  // ============================================================

  static async loadAll(): Promise<LoadedSettings> {
    const methodStr = await PreferencesHelper.getString(KEY_METHOD, CalculationMethod.KARACHI);
    const asrNum    = await PreferencesHelper.getNumber(KEY_ASR, AsrShadowRule.STANDARD as number);
    const sourceStr = await PreferencesHelper.getString(KEY_SOURCE, CalculationSource.LOCAL);
    const counter   = await PreferencesHelper.getNumber(KEY_COUNTER, 0);
    const showExtraTimings  = await PreferencesHelper.getBoolean(KEY_SHOW_EXTRA_TIMINGS, true);
    const showIslamicEvents = await PreferencesHelper.getBoolean(KEY_SHOW_ISLAMIC_EVENTS, true);

    return {
      method: methodStr as CalculationMethod,
      asr: asrNum as AsrShadowRule,
      source: sourceStr as CalculationSource,
      counter,
      showExtraTimings,
      showIslamicEvents
    };
  }

  static saveMethod(method: CalculationMethod): void {
    PreferencesHelper.setString(KEY_METHOD, method);
  }

  static saveAsrRule(rule: AsrShadowRule): void {
    PreferencesHelper.setNumber(KEY_ASR, rule as number);
  }

  static saveSource(source: CalculationSource): void {
    PreferencesHelper.setString(KEY_SOURCE, source);
  }

  static saveCounter(value: number): void {
    PreferencesHelper.setNumber(KEY_COUNTER, value);
  }

  static saveShowExtraTimings(value: boolean): void {
    PreferencesHelper.setBoolean(KEY_SHOW_EXTRA_TIMINGS, value);
  }

  static saveShowIslamicEvents(value: boolean): void {
    PreferencesHelper.setBoolean(KEY_SHOW_ISLAMIC_EVENTS, value);
  }

  // ============================================================
  // PRAYER OFFSETS
  // ============================================================

  static async getPrayerOffsets(): Promise<PrayerOffsets> {
    const fajr    = await PreferencesHelper.getNumber(KEY_OFFSET_FAJR, 0);
    const dhuhr   = await PreferencesHelper.getNumber(KEY_OFFSET_DHUHR, 0);
    const asr     = await PreferencesHelper.getNumber(KEY_OFFSET_ASR, 0);
    const maghrib = await PreferencesHelper.getNumber(KEY_OFFSET_MAGHRIB, 0);
    const isha    = await PreferencesHelper.getNumber(KEY_OFFSET_ISHA, 0);

    return { fajr, dhuhr, asr, maghrib, isha };
  }

  static saveOffset(key: string, minutes: number): void {
    PreferencesHelper.setNumber(key, minutes);
  }

  static async saveAllOffsets(offsets: PrayerOffsets): Promise<void> {
    await PreferencesHelper.setNumber(KEY_OFFSET_FAJR, offsets.fajr);
    await PreferencesHelper.setNumber(KEY_OFFSET_DHUHR, offsets.dhuhr);
    await PreferencesHelper.setNumber(KEY_OFFSET_ASR, offsets.asr);
    await PreferencesHelper.setNumber(KEY_OFFSET_MAGHRIB, offsets.maghrib);
    await PreferencesHelper.setNumber(KEY_OFFSET_ISHA, offsets.isha);

    console.info(`[SettingsHelper] Saved offsets: fajr=${offsets.fajr}, dhuhr=${offsets.dhuhr}, asr=${offsets.asr}, maghrib=${offsets.maghrib}, isha=${offsets.isha}`);
  }

  // Expose keys so the Settings page can save individual offsets
  static readonly OFFSET_KEYS: OffsetKeys = {
    fajr: KEY_OFFSET_FAJR,
    dhuhr: KEY_OFFSET_DHUHR,
    asr: KEY_OFFSET_ASR,
    maghrib: KEY_OFFSET_MAGHRIB,
    isha: KEY_OFFSET_ISHA
  };

  // ============================================================
  // LOCATION SETTINGS
  // ============================================================

  static async getLocationMode(): Promise<LocationMode> {
    const stored = await PreferencesHelper.getString(KEY_LOCATION_MODE, LocationMode.GPS);
    if (stored === LocationMode.MANUAL) return LocationMode.MANUAL;
    return LocationMode.GPS;
  }

  static saveLocationMode(mode: LocationMode): void {
    PreferencesHelper.setString(KEY_LOCATION_MODE, mode);
  }

  static async getManualCoords(): Promise<ManualCoords> {
    const lat      = await PreferencesHelper.getNumber(KEY_MANUAL_LAT, 0);
    const lng      = await PreferencesHelper.getNumber(KEY_MANUAL_LNG, 0);
    const refresh  = await PreferencesHelper.getNumber(KEY_MANUAL_REFRESH, 0);
    const cityName = await PreferencesHelper.getString(KEY_MANUAL_CITY, '');
    return { lat, lng, refresh, cityName };
  }

  static async saveManualCoords(lat: number, lng: number, cityName: string): Promise<ManualCoords> {
    const refresh = Date.now();

    await PreferencesHelper.setNumber(KEY_MANUAL_LAT, lat);
    await PreferencesHelper.setNumber(KEY_MANUAL_LNG, lng);
    await PreferencesHelper.setNumber(KEY_MANUAL_REFRESH, refresh);
    await PreferencesHelper.setString(KEY_MANUAL_CITY, cityName);

    console.info(`[SettingsHelper] Saved manual coords: ${lat}, ${lng} (${cityName})`);

    return { lat, lng, refresh, cityName };
  }

  // ============================================================
  // LABELS
  // ============================================================

  static getCalcMethodLabel(method: CalculationMethod): string {
    switch (method) {
      case CalculationMethod.KARACHI: return 'University of Islamic Sciences, Karachi';
      case CalculationMethod.JAFARI:  return 'Shia Ithna Ashari (Leva Institute, Qum)';
      case CalculationMethod.ISNA:    return 'Islamic Society of North America';
      case CalculationMethod.MWL:     return 'Muslim World League';
      default: return 'Karachi';
    }
  }

  static getAsrRuleLabel(rule: AsrShadowRule): string {
    switch (rule) {
      case AsrShadowRule.STANDARD: return 'Standard (Shafi\'i / Maliki / Hanbali)';
      case AsrShadowRule.HANAFI:   return 'Hanafi';
      default: return 'Standard';
    }
  }

  static getCalcSourceLabel(source: CalculationSource): string {
    switch (source) {
      case CalculationSource.LOCAL: return 'Local Formula (Offline)';
      case CalculationSource.API:   return 'API (Online)';
      default: return 'Local Formula (Offline)';
    }
  }

  static getLocationModeLabel(mode: LocationMode): string {
    switch (mode) {
      case LocationMode.GPS:    return 'GPS';
      case LocationMode.MANUAL: return 'Manual Location';
      default: return 'GPS';
    }
  }

  // ============================================================
  // PICKER ITEM BUILDERS
  // ============================================================

  static buildMethodPickerItems(current: CalculationMethod): PickerItem[] {
    return [CalculationMethod.KARACHI, CalculationMethod.JAFARI, CalculationMethod.ISNA, CalculationMethod.MWL]
      .map((m): PickerItem => ({
        id: m,
        label: SettingsHelper.getCalcMethodLabel(m),
        selected: m === current
      }));
  }

  static buildAsrPickerItems(current: AsrShadowRule): PickerItem[] {
    return [AsrShadowRule.STANDARD, AsrShadowRule.HANAFI]
      .map((r): PickerItem => ({
        id: r.toString(),
        label: SettingsHelper.getAsrRuleLabel(r),
        selected: r === current
      }));
  }

  static buildSourcePickerItems(current: CalculationSource): PickerItem[] {
    return [CalculationSource.LOCAL, CalculationSource.API]
      .map((s): PickerItem => ({
        id: s,
        label: SettingsHelper.getCalcSourceLabel(s),
        selected: s === current
      }));
  }

  // ============================================================
  // THEME MODE
  // ============================================================

  static saveThemeMode(mode: string): void {
    // Write to AppStorage immediately (for reactivity across pages)
    AppStorage.setOrCreate(STORAGE_KEY_THEME_MODE, mode);
    // Write to disk via PreferencesHelper for durability
    PreferencesHelper.setString(STORAGE_KEY_THEME_MODE, mode);
  }

  static getThemeModeLabel(mode: string): string {
    switch (mode) {
      case ThemeMode.LIGHT: return 'Light';
      case ThemeMode.DARK: return 'Dark';
      case ThemeMode.SYSTEM: return 'Use System Settings';
      default: return 'Use System Settings';
    }
  }

  static buildThemePickerItems(current: string): PickerItem[] {
    return [ThemeMode.LIGHT, ThemeMode.DARK, ThemeMode.SYSTEM]
      .map((m): PickerItem => ({
        id: m,
        label: SettingsHelper.getThemeModeLabel(m),
        selected: m === current
      }));
  }
}