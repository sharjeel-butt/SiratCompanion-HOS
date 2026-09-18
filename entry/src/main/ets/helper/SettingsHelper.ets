// entry/src/main/ets/helper/SettingsHelper.ets

import { ThemeMode } from '../common/Theme';
import {
  STORAGE_KEY_NOTIF_MASTER,
  STORAGE_KEY_NOTIF_BEFORE_MINUTES,
  STORAGE_KEY_NOTIF_FAJR,
  STORAGE_KEY_NOTIF_DHUHR,
  STORAGE_KEY_NOTIF_ASR,
  STORAGE_KEY_NOTIF_MAGHRIB,
  STORAGE_KEY_NOTIF_ISHA
} from '../common/StorageKeys';
import {
  STORAGE_KEY_THEME_MODE,
  STORAGE_KEY_HIJRI_OFFSET,
  STORAGE_KEY_LANGUAGE
} from '../common/StorageKeys';
import { CalculationMethod, AsrShadowRule } from '../utils/PrayerTimeCalculator';
import { PreferencesHelper } from './PreferencesHelper';
import {
  PickerItem,
  CalculationSource,
  LocationMode,
  ManualCoords
} from '../models/SettingsModels';
import { L } from './LocalizationHelper';
import { STORAGE_KEY_WIZARD_COMPLETED } from '../common/StorageKeys';
import { HighLatitudeRule } from '../utils/PrayerTimeCalculator';
import { STORAGE_KEY_HIGH_LAT_RULE } from '../common/StorageKeys';
import { STORAGE_KEY_VIBRATION_ENABLED } from '../common/StorageKeys';

const KEY_METHOD  = 'calc_method';
const KEY_ASR     = 'asr_rule';
const KEY_SOURCE  = 'calc_source';

const KEY_LOCATION_MODE  = 'location_mode';
const KEY_MANUAL_LAT     = 'manual_lat';
const KEY_MANUAL_LNG     = 'manual_lng';
const KEY_MANUAL_REFRESH = 'manual_refresh';
const KEY_MANUAL_CITY    = 'manual_city';

const KEY_SHOW_EXTRA_TIMINGS  = 'show_extra_timings';
const KEY_SHOW_ISLAMIC_EVENTS = 'show_islamic_events';

const KEY_OFFSET_FAJR    = 'offset_fajr';
const KEY_OFFSET_DHUHR   = 'offset_dhuhr';
const KEY_OFFSET_ASR     = 'offset_asr';
const KEY_OFFSET_MAGHRIB = 'offset_maghrib';
const KEY_OFFSET_ISHA    = 'offset_isha';

export interface PrayerOffsets {
  fajr: number;
  dhuhr: number;
  asr: number;
  maghrib: number;
  isha: number;
}

export interface NotificationsSettings {
  masterEnabled: boolean;
  beforeMinutes: number;
  fajrEnabled: boolean;
  dhuhrEnabled: boolean;
  asrEnabled: boolean;
  maghribEnabled: boolean;
  ishaEnabled: boolean;
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
  showExtraTimings: boolean;
  showIslamicEvents: boolean;
}

export class SettingsHelper {

  static async loadAll(): Promise<LoadedSettings> {
    const methodStr = await PreferencesHelper.getString(KEY_METHOD, CalculationMethod.KARACHI);
    const asrNum    = await PreferencesHelper.getNumber(KEY_ASR, AsrShadowRule.STANDARD as number);
    const sourceStr = await PreferencesHelper.getString(KEY_SOURCE, CalculationSource.LOCAL);
    const showExtraTimings  = await PreferencesHelper.getBoolean(KEY_SHOW_EXTRA_TIMINGS, true);
    const showIslamicEvents = await PreferencesHelper.getBoolean(KEY_SHOW_ISLAMIC_EVENTS, true);

    return {
      method: methodStr as CalculationMethod,
      asr: asrNum as AsrShadowRule,
      source: sourceStr as CalculationSource,
      showExtraTimings,
      showIslamicEvents
    };
  }

  // ============================================================
  // HIGH-LATITUDE RULE
  // ============================================================

  static async getHighLatRule(): Promise<HighLatitudeRule> {
    const stored = await PreferencesHelper.getString(
      STORAGE_KEY_HIGH_LAT_RULE, HighLatitudeRule.NONE
    );
    switch (stored) {
      case HighLatitudeRule.MIDDLE_OF_NIGHT: return HighLatitudeRule.MIDDLE_OF_NIGHT;
      case HighLatitudeRule.ONE_SEVENTH:     return HighLatitudeRule.ONE_SEVENTH;
      case HighLatitudeRule.ANGLE_BASED:     return HighLatitudeRule.ANGLE_BASED;
      default:                                return HighLatitudeRule.NONE;
    }
  }

  static saveHighLatRule(rule: HighLatitudeRule): void {
    PreferencesHelper.setString(STORAGE_KEY_HIGH_LAT_RULE, rule);
  }

  static getHighLatRuleLabel(rule: HighLatitudeRule): string {
    switch (rule) {
      case HighLatitudeRule.NONE:            return L.get('highlat_none');
      case HighLatitudeRule.MIDDLE_OF_NIGHT: return L.get('highlat_middle');
      case HighLatitudeRule.ONE_SEVENTH:     return L.get('highlat_one_seventh');
      case HighLatitudeRule.ANGLE_BASED:     return L.get('highlat_angle');
      default:                                return L.get('highlat_none');
    }
  }

  static buildHighLatPickerItems(current: HighLatitudeRule): PickerItem[] {
    const rules = [
      HighLatitudeRule.NONE,
      HighLatitudeRule.MIDDLE_OF_NIGHT,
      HighLatitudeRule.ONE_SEVENTH,
      HighLatitudeRule.ANGLE_BASED
    ];
    return rules.map((r): PickerItem => {
      const item: PickerItem = {
        id: r,
        label: SettingsHelper.getHighLatRuleLabel(r),
        selected: r === current
      };
      return item;
    });
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  static async getNotificationSettings(): Promise<NotificationsSettings> {
    const master = await PreferencesHelper.getBoolean(STORAGE_KEY_NOTIF_MASTER, false);
    const before = await PreferencesHelper.getNumber(STORAGE_KEY_NOTIF_BEFORE_MINUTES, 10);
    const fajr = await PreferencesHelper.getBoolean(STORAGE_KEY_NOTIF_FAJR, true);
    const dhuhr = await PreferencesHelper.getBoolean(STORAGE_KEY_NOTIF_DHUHR, true);
    const asr = await PreferencesHelper.getBoolean(STORAGE_KEY_NOTIF_ASR, true);
    const maghrib = await PreferencesHelper.getBoolean(STORAGE_KEY_NOTIF_MAGHRIB, true);
    const isha = await PreferencesHelper.getBoolean(STORAGE_KEY_NOTIF_ISHA, true);

    const out: NotificationsSettings = {
      masterEnabled: master,
      beforeMinutes: before,
      fajrEnabled: fajr,
      dhuhrEnabled: dhuhr,
      asrEnabled: asr,
      maghribEnabled: maghrib,
      ishaEnabled: isha
    };
    return out;
  }

  static saveNotifMaster(value: boolean): void {
    PreferencesHelper.setBoolean(STORAGE_KEY_NOTIF_MASTER, value);
  }

  static saveNotifBeforeMinutes(minutes: number): void {
    PreferencesHelper.setNumber(STORAGE_KEY_NOTIF_BEFORE_MINUTES, minutes);
  }

  static saveNotifPrayer(prayerId: string, value: boolean): void {
    switch (prayerId) {
      case 'fajr':    PreferencesHelper.setBoolean(STORAGE_KEY_NOTIF_FAJR, value); break;
      case 'dhuhr':   PreferencesHelper.setBoolean(STORAGE_KEY_NOTIF_DHUHR, value); break;
      case 'asr':     PreferencesHelper.setBoolean(STORAGE_KEY_NOTIF_ASR, value); break;
      case 'maghrib': PreferencesHelper.setBoolean(STORAGE_KEY_NOTIF_MAGHRIB, value); break;
      case 'isha':    PreferencesHelper.setBoolean(STORAGE_KEY_NOTIF_ISHA, value); break;
    }
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
  }

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
    SettingsHelper.bumpLocationVersion();
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

    SettingsHelper.bumpLocationVersion();
    return { lat, lng, refresh, cityName };
  }

  private static bumpLocationVersion(): void {
    const prev = AppStorage.get<number>('location_version');
    const next = (prev === undefined ? 0 : prev) + 1;
    AppStorage.setOrCreate('location_version', next);
  }

  // ============================================================
  // LABELS
  // ============================================================

  static getCalcMethodLabel(method: CalculationMethod): string {
    switch (method) {
      case CalculationMethod.KARACHI: return L.get('method_karachi');
      case CalculationMethod.JAFARI:  return L.get('method_jafari');
      case CalculationMethod.ISNA:    return L.get('method_isna');
      case CalculationMethod.MWL:     return L.get('method_mwl');
      default:                        return L.get('method_karachi');
    }
  }

  static getAsrRuleLabel(rule: AsrShadowRule): string {
    switch (rule) {
      case AsrShadowRule.STANDARD: return L.get('asr_standard');
      case AsrShadowRule.HANAFI:   return L.get('asr_hanafi');
      default:                     return L.get('asr_standard');
    }
  }

  static getCalcSourceLabel(source: CalculationSource): string {
    switch (source) {
      case CalculationSource.LOCAL: return L.get('source_local');
      case CalculationSource.API:   return L.get('source_api');
      default:                      return L.get('source_local');
    }
  }

  static getThemeModeLabel(mode: string): string {
    switch (mode) {
      case ThemeMode.LIGHT:  return L.get('theme_light');
      case ThemeMode.DARK:   return L.get('theme_dark');
      case ThemeMode.SYSTEM: return L.get('theme_system');
      default:               return L.get('theme_system');
    }
  }
  static getLocationModeLabel(mode: LocationMode): string {
    switch (mode) {
      case LocationMode.GPS:    return 'GPS';
      case LocationMode.MANUAL: return 'Manual Location';
      default: return 'GPS';
    }
  }

  static getCalcMethodShortLabel(method: CalculationMethod): string {
    switch (method) {
      case CalculationMethod.KARACHI: return 'Karachi';
      case CalculationMethod.JAFARI:  return 'Jafari';
      case CalculationMethod.ISNA:    return 'ISNA';
      case CalculationMethod.MWL:     return 'MWL';
      default: return 'Karachi';
    }
  }

  static getAsrRuleShortLabel(rule: AsrShadowRule): string {
    return rule === AsrShadowRule.HANAFI ? 'Hanafi' : 'Standard';
  }

  static getCalcSourceShortLabel(source: CalculationSource): string {
    return source === CalculationSource.API ? 'Online' : 'Local';
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
    AppStorage.setOrCreate(STORAGE_KEY_THEME_MODE, mode);
    PreferencesHelper.setString(STORAGE_KEY_THEME_MODE, mode);
  }

  static buildThemePickerItems(current: string): PickerItem[] {
    return [ThemeMode.LIGHT, ThemeMode.DARK, ThemeMode.SYSTEM]
      .map((m): PickerItem => ({
        id: m,
        label: SettingsHelper.getThemeModeLabel(m),
        selected: m === current
      }));
  }

  // ============================================================
  // HIJRI OFFSET
  // ============================================================

  static async getHijriOffset(): Promise<number> {
    const cached = AppStorage.get<number>(STORAGE_KEY_HIJRI_OFFSET);
    if (cached !== undefined) return cached;

    const loaded = await PreferencesHelper.getNumber(STORAGE_KEY_HIJRI_OFFSET, 0);
    AppStorage.setOrCreate(STORAGE_KEY_HIJRI_OFFSET, loaded);
    return loaded;
  }

  static saveHijriOffset(days: number): void {
    AppStorage.setOrCreate(STORAGE_KEY_HIJRI_OFFSET, days);
    PreferencesHelper.setNumber(STORAGE_KEY_HIJRI_OFFSET, days);
  }

  // ============================================================
  // LANGUAGE
  // ============================================================

  static async getLanguage(): Promise<string> {
    const cached = AppStorage.get<string>(STORAGE_KEY_LANGUAGE);
    if (cached !== undefined) return cached;

    const loaded = await PreferencesHelper.getString(STORAGE_KEY_LANGUAGE, 'en');
    AppStorage.setOrCreate(STORAGE_KEY_LANGUAGE, loaded);
    return loaded;
  }

  static saveLanguage(lang: string): void {
    AppStorage.setOrCreate(STORAGE_KEY_LANGUAGE, lang);
    PreferencesHelper.setString(STORAGE_KEY_LANGUAGE, lang);
  }

  // ============================================================
  // WIZARD
  // ============================================================

  static async isWizardCompleted(): Promise<boolean> {
    return PreferencesHelper.getBoolean(STORAGE_KEY_WIZARD_COMPLETED, false);
  }

  static markWizardCompleted(): void {
    PreferencesHelper.setBoolean(STORAGE_KEY_WIZARD_COMPLETED, true);
  }

  /** Reset for testing — clears the flag so the wizard runs again. */
  static resetWizard(): void {
    PreferencesHelper.setBoolean(STORAGE_KEY_WIZARD_COMPLETED, false);
  }

  // ============================================================
  // VIBRATION
  // ============================================================

  static getVibrationEnabled(): boolean {
    const cached = AppStorage.get<boolean>(STORAGE_KEY_VIBRATION_ENABLED);
    return cached === undefined ? true : cached;
  }

  static saveVibrationEnabled(value: boolean): void {
    AppStorage.setOrCreate(STORAGE_KEY_VIBRATION_ENABLED, value);
    PreferencesHelper.setBoolean(STORAGE_KEY_VIBRATION_ENABLED, value);
  }
}