// entry/src/main/ets/helper/SettingsHelper.ets

import { AsrShadowRule, CalculationMethod, HighLatitudeRule } from '../utils/PrayerTimeCalculator';
import { CalculationSource, LocationMode, ManualCoords, PickerItem } from '../models/SettingsModels';
import { PreferencesHelper } from './PreferencesHelper';
import {
  STORAGE_KEY_APP_THEME,
  STORAGE_KEY_CUSTOM_FAJR_ANGLE,
  STORAGE_KEY_CUSTOM_ISHA_ANGLE,
  STORAGE_KEY_CUSTOM_ISHA_INTERVAL,
  STORAGE_KEY_HIGH_LAT_RULE,
  STORAGE_KEY_HIJRI_CALENDAR_TYPE,
  STORAGE_KEY_HIJRI_OFFSET,
  STORAGE_KEY_LANGUAGE,
  STORAGE_KEY_MIDNIGHT_METHOD,
  STORAGE_KEY_NOTIF_ASR,
  STORAGE_KEY_NOTIF_BEFORE_MINUTES,
  STORAGE_KEY_NOTIF_DHUHR,
  STORAGE_KEY_NOTIF_FAJR,
  STORAGE_KEY_NOTIF_ISHA,
  STORAGE_KEY_NOTIF_MAGHRIB,
  STORAGE_KEY_NOTIF_MASTER,
  STORAGE_KEY_POLAR_RESOLUTION,
  STORAGE_KEY_ROUNDING_METHOD,
  STORAGE_KEY_SHAFAQ,
  STORAGE_KEY_SOUND_ENABLED,
  STORAGE_KEY_TASBIH_RENDER_STYLE,
  STORAGE_KEY_TASBIH_SOUND,
  STORAGE_KEY_TASBIH_THEME_PRESET,
  STORAGE_KEY_THEME_MODE,
  STORAGE_KEY_TIME_FORMAT,
  STORAGE_KEY_VIBRATION_ENABLED,
  STORAGE_KEY_WIZARD_COMPLETED
} from '../common/StorageKeys';
import { ThemeMode, ThemePreset } from '../common/Theme';
import { L } from './LocalizationHelper';
import { SoundOptions } from '../common/SoundOptions';
import { TasbihThemes } from '../common/TasbihThemes';
import {
  AdvancedCalcSettings,
  CustomAngles,
  DEFAULT_CUSTOM_ANGLES,
  MidnightMethod,
  PolarResolution,
  RoundingMethod,
  Shafaq
} from '../models/AdvancedCalcModels';
import { ClockFormat } from '../common/ClockFormat';
import { HijriCalendarType } from '../common/HijriCalendarType';

const KEY_METHOD = 'calc_method';
const KEY_ASR = 'asr_rule';
const KEY_SOURCE = 'calc_source';

const KEY_LOCATION_MODE = 'location_mode';
const KEY_MANUAL_LAT = 'manual_lat';
const KEY_MANUAL_LNG = 'manual_lng';
const KEY_MANUAL_REFRESH = 'manual_refresh';
const KEY_MANUAL_CITY = 'manual_city';

const KEY_SHOW_EXTRA_TIMINGS = 'show_extra_timings';
const KEY_SHOW_ISLAMIC_EVENTS = 'show_islamic_events';

const KEY_OFFSET_FAJR = 'offset_fajr';
const KEY_OFFSET_DHUHR = 'offset_dhuhr';
const KEY_OFFSET_ASR = 'offset_asr';
const KEY_OFFSET_MAGHRIB = 'offset_maghrib';
const KEY_OFFSET_ISHA = 'offset_isha';

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
  static readonly OFFSET_KEYS: OffsetKeys = {
    fajr: KEY_OFFSET_FAJR,
    dhuhr: KEY_OFFSET_DHUHR,
    asr: KEY_OFFSET_ASR,
    maghrib: KEY_OFFSET_MAGHRIB,
    isha: KEY_OFFSET_ISHA
  };

  // ============================================================
  // HIGH-LATITUDE RULE
  // ============================================================

  static async loadAll(): Promise<LoadedSettings> {
    const methodStr = await PreferencesHelper.getString(KEY_METHOD, CalculationMethod.KARACHI);
    const asrNum = await PreferencesHelper.getNumber(KEY_ASR, AsrShadowRule.STANDARD as number);
    const sourceStr = await PreferencesHelper.getString(KEY_SOURCE, CalculationSource.LOCAL);
    const showExtraTimings = await PreferencesHelper.getBoolean(KEY_SHOW_EXTRA_TIMINGS, true);
    const showIslamicEvents = await PreferencesHelper.getBoolean(KEY_SHOW_ISLAMIC_EVENTS, true);

    return {
      method: methodStr as CalculationMethod,
      asr: asrNum as AsrShadowRule,
      source: sourceStr as CalculationSource,
      showExtraTimings,
      showIslamicEvents
    };
  }

  static async getHighLatRule(): Promise<HighLatitudeRule> {
    const stored = await PreferencesHelper.getString(
      STORAGE_KEY_HIGH_LAT_RULE, HighLatitudeRule.NONE
    );
    switch (stored) {
      case HighLatitudeRule.MIDDLE_OF_NIGHT:
        return HighLatitudeRule.MIDDLE_OF_NIGHT;
      case HighLatitudeRule.ONE_SEVENTH:
        return HighLatitudeRule.ONE_SEVENTH;
      case HighLatitudeRule.ANGLE_BASED:
        return HighLatitudeRule.ANGLE_BASED;
      default:
        return HighLatitudeRule.NONE;
    }
  }

  static saveHighLatRule(rule: HighLatitudeRule): void {
    PreferencesHelper.setString(STORAGE_KEY_HIGH_LAT_RULE, rule);
  }

  // ============================================================
  // TIME FORMAT
  // ============================================================

  static getClockFormat(): string {
    const cached = AppStorage.get<string>(STORAGE_KEY_TIME_FORMAT);
    if (cached !== undefined && cached.length > 0) {
      return cached;
    }
    return ClockFormat.SYSTEM;
  }

  static saveClockFormat(format: string): void {
    AppStorage.setOrCreate(STORAGE_KEY_TIME_FORMAT, format);
    PreferencesHelper.setString(STORAGE_KEY_TIME_FORMAT, format);
  }

  static buildClockFormatPickerItems(current: string): PickerItem[] {
    const out: PickerItem[] = [];

    const system: PickerItem = {
      id: ClockFormat.SYSTEM,
      label: L.get('time_format_system'),
      selected: current === ClockFormat.SYSTEM
    };
    out.push(system);

    const twelve: PickerItem = {
      id: ClockFormat.TWELVE_HOUR,
      label: L.get('time_format_12h'),
      selected: current === ClockFormat.TWELVE_HOUR
    };
    out.push(twelve);

    const twentyFour: PickerItem = {
      id: ClockFormat.TWENTY_FOUR_HOUR,
      label: L.get('time_format_24h'),
      selected: current === ClockFormat.TWENTY_FOUR_HOUR
    };
    out.push(twentyFour);

    return out;
  }

  // ============================================================
  // APP THEME PRESET
  // ============================================================

  static getHighLatRuleLabel(rule: HighLatitudeRule): string {
    switch (rule) {
      case HighLatitudeRule.NONE:
        return L.get('highlat_none');
      case HighLatitudeRule.MIDDLE_OF_NIGHT:
        return L.get('highlat_middle');
      case HighLatitudeRule.ONE_SEVENTH:
        return L.get('highlat_one_seventh');
      case HighLatitudeRule.ANGLE_BASED:
        return L.get('highlat_angle');
      default:
        return L.get('highlat_none');
    }
  }

  static async getAppTheme(): Promise<string> {
    const cached = AppStorage.get<string>(STORAGE_KEY_APP_THEME);
    if (cached !== undefined && cached.length > 0) {
      return cached;
    }

    const stored = await PreferencesHelper.getString(
      STORAGE_KEY_APP_THEME, ThemePreset.SIRAT
    );
    AppStorage.setOrCreate(STORAGE_KEY_APP_THEME, stored);
    return stored;
  }

  static saveAppTheme(preset: string): void {
    AppStorage.setOrCreate(STORAGE_KEY_APP_THEME, preset);
    PreferencesHelper.setString(STORAGE_KEY_APP_THEME, preset);
  }

  static getAppThemeLabel(preset: string): string {
    switch (preset) {
      case ThemePreset.HARMONY_7:
        return L.get('theme_preset_harmony7');
      case ThemePreset.HARMONY_6:
        return L.get('theme_preset_harmony6');
      case ThemePreset.HARMONY_5:
        return L.get('theme_preset_harmony5');
      case ThemePreset.CURRENT:
        return L.get('theme_preset_current');
      case ThemePreset.SIRAT:
      default:
        return L.get('theme_preset_sirat');
    }
  }

  static buildAppThemePickerItems(current: string): PickerItem[] {
    return [
      ThemePreset.SIRAT,
      ThemePreset.CURRENT,
      ThemePreset.HARMONY_7,
      ThemePreset.HARMONY_6,
      ThemePreset.HARMONY_5
    ].map((p): PickerItem => {
      const item: PickerItem = {
        id: p,
        label: SettingsHelper.getAppThemeLabel(p),
        selected: p === current
      };
      return item;
    });
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

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

  /**
   * Persist the master notification toggle.
   *
   * Async so callers can await the write before triggering a
   * reschedule — rescheduleAll() reads the settings back to decide
   * what to schedule, so the write must be flushed first.
   */
  static async saveNotifMaster(value: boolean): Promise<void> {
    await PreferencesHelper.setBoolean(STORAGE_KEY_NOTIF_MASTER, value);
  }

  /**
   * Persist the lead-time stepper value.
   *
   * Async for the same reason as saveNotifMaster — a race here causes
   * the reschedule to use the previous value.
   */
  static async saveNotifBeforeMinutes(minutes: number): Promise<void> {
    await PreferencesHelper.setNumber(
      STORAGE_KEY_NOTIF_BEFORE_MINUTES, minutes
    );
  }

  /**
   * Persist a per-prayer enable toggle. Async for the same reason.
   */
  static async saveNotifPrayer(
    prayerId: string, value: boolean
  ): Promise<void> {
    switch (prayerId) {
      case 'fajr':
        await PreferencesHelper.setBoolean(STORAGE_KEY_NOTIF_FAJR, value);
        break;
      case 'dhuhr':
        await PreferencesHelper.setBoolean(STORAGE_KEY_NOTIF_DHUHR, value);
        break;
      case 'asr':
        await PreferencesHelper.setBoolean(STORAGE_KEY_NOTIF_ASR, value);
        break;
      case 'maghrib':
        await PreferencesHelper.setBoolean(
          STORAGE_KEY_NOTIF_MAGHRIB, value
        );
        break;
      case 'isha':
        await PreferencesHelper.setBoolean(STORAGE_KEY_NOTIF_ISHA, value);
        break;
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

  // ============================================================
  // PRAYER OFFSETS
  // ============================================================

  static saveShowIslamicEvents(value: boolean): void {
    PreferencesHelper.setBoolean(KEY_SHOW_ISLAMIC_EVENTS, value);
  }

  static async getPrayerOffsets(): Promise<PrayerOffsets> {
    const fajr = await PreferencesHelper.getNumber(KEY_OFFSET_FAJR, 0);
    const dhuhr = await PreferencesHelper.getNumber(KEY_OFFSET_DHUHR, 0);
    const asr = await PreferencesHelper.getNumber(KEY_OFFSET_ASR, 0);
    const maghrib = await PreferencesHelper.getNumber(KEY_OFFSET_MAGHRIB, 0);
    const isha = await PreferencesHelper.getNumber(KEY_OFFSET_ISHA, 0);

    return {
      fajr,
      dhuhr,
      asr,
      maghrib,
      isha
    };
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

  // ============================================================
  // LOCATION SETTINGS
  // ============================================================

  static async getLocationMode(): Promise<LocationMode> {
    const stored = await PreferencesHelper.getString(KEY_LOCATION_MODE, LocationMode.GPS);
    if (stored === LocationMode.MANUAL) {
      return LocationMode.MANUAL;
    }
    return LocationMode.GPS;
  }

  static saveLocationMode(mode: LocationMode): void {
    PreferencesHelper.setString(KEY_LOCATION_MODE, mode);
    SettingsHelper.bumpLocationVersion();
  }

  static async getManualCoords(): Promise<ManualCoords> {
    const lat = await PreferencesHelper.getNumber(KEY_MANUAL_LAT, 0);
    const lng = await PreferencesHelper.getNumber(KEY_MANUAL_LNG, 0);
    const refresh = await PreferencesHelper.getNumber(KEY_MANUAL_REFRESH, 0);
    const cityName = await PreferencesHelper.getString(KEY_MANUAL_CITY, '');
    return {
      lat,
      lng,
      refresh,
      cityName
    };
  }

  static async saveManualCoords(lat: number, lng: number, cityName: string): Promise<ManualCoords> {
    const refresh = Date.now();

    await PreferencesHelper.setNumber(KEY_MANUAL_LAT, lat);
    await PreferencesHelper.setNumber(KEY_MANUAL_LNG, lng);
    await PreferencesHelper.setNumber(KEY_MANUAL_REFRESH, refresh);
    await PreferencesHelper.setString(KEY_MANUAL_CITY, cityName);

    SettingsHelper.bumpLocationVersion();
    return {
      lat,
      lng,
      refresh,
      cityName
    };
  }

  static getCalcMethodLabel(method: CalculationMethod): string {
    switch (method) {
      case CalculationMethod.KARACHI:
        return L.get('method_karachi');
      case CalculationMethod.JAFARI:
        return L.get('method_jafari');
      case CalculationMethod.ISNA:
        return L.get('method_isna');
      case CalculationMethod.MWL:
        return L.get('method_mwl');
      case CalculationMethod.UMM_AL_QURA:
        return L.get('method_umm_al_qura');
      case CalculationMethod.EGYPTIAN:
        return L.get('method_egyptian');
      case CalculationMethod.SUNNI_IRAQ:
        return L.get('method_sunni_iraq');
      case CalculationMethod.QATAR:
        return L.get('method_qatar');
      case CalculationMethod.SINGAPORE:
        return L.get('method_singapore');
      case CalculationMethod.FRANCE:
        return L.get('method_france');
      case CalculationMethod.TURKEY:
        return L.get('method_turkey');
      case CalculationMethod.RUSSIA:
        return L.get('method_russia');
      case CalculationMethod.UAE:
        return L.get('method_uae');
      default:
        return L.get('method_karachi');
    }
  }

  // ============================================================
  // LABELS
  // ============================================================

  static getAsrRuleLabel(rule: AsrShadowRule): string {
    switch (rule) {
      case AsrShadowRule.STANDARD:
        return L.get('asr_standard');
      case AsrShadowRule.HANAFI:
        return L.get('asr_hanafi');
      default:
        return L.get('asr_standard');
    }
  }

  static getCalcSourceLabel(source: CalculationSource): string {
    switch (source) {
      case CalculationSource.LOCAL:
        return L.get('source_local');
      case CalculationSource.API:
        return L.get('source_api');
      default:
        return L.get('source_local');
    }
  }

  static getThemeModeLabel(mode: string): string {
    switch (mode) {
      case ThemeMode.LIGHT:
        return L.get('theme_light');
      case ThemeMode.DARK:
        return L.get('theme_dark');
      case ThemeMode.SYSTEM:
        return L.get('theme_system');
      default:
        return L.get('theme_system');
    }
  }

  static getLocationModeLabel(mode: LocationMode): string {
    switch (mode) {
      case LocationMode.GPS:
        return L.get('gps');
      case LocationMode.MANUAL:
        return L.get('manual_location');
      default:
        return L.get('gps');
    }
  }

  static getCalcMethodShortLabel(method: CalculationMethod): string {
    switch (method) {
      case CalculationMethod.KARACHI:
        return L.get('method_short_karachi');
      case CalculationMethod.JAFARI:
        return L.get('method_short_jafari');
      case CalculationMethod.ISNA:
        return L.get('method_short_isna');
      case CalculationMethod.MWL:
        return L.get('method_short_mwl');
      case CalculationMethod.UMM_AL_QURA:
        return L.get('method_short_umm_al_qura');
      case CalculationMethod.EGYPTIAN:
        return L.get('method_short_egyptian');
      case CalculationMethod.SUNNI_IRAQ:
        return L.get('method_short_sunni_iraq');
      case CalculationMethod.QATAR:
        return L.get('method_short_qatar');
      case CalculationMethod.SINGAPORE:
        return L.get('method_short_singapore');
      case CalculationMethod.FRANCE:
        return L.get('method_short_france');
      case CalculationMethod.TURKEY:
        return L.get('method_short_turkey');
      case CalculationMethod.RUSSIA:
        return L.get('method_short_russia');
      case CalculationMethod.UAE:
        return L.get('method_short_uae');
      default:
        return L.get('method_short_karachi');
    }
  }

  static getAsrRuleShortLabel(rule: AsrShadowRule): string {
    return rule === AsrShadowRule.HANAFI
      ? L.get('asr_short_hanafi')
      : L.get('asr_short_standard');
  }

  static getCalcSourceShortLabel(source: CalculationSource): string {
    return source === CalculationSource.API
      ? L.get('source_short_online')
      : L.get('source_short_local');
  }

  static buildMethodPickerItems(current: CalculationMethod): PickerItem[] {
    return [
      CalculationMethod.KARACHI,
      CalculationMethod.JAFARI,
      CalculationMethod.ISNA,
      CalculationMethod.MWL,
      CalculationMethod.UMM_AL_QURA,
      CalculationMethod.EGYPTIAN,
      CalculationMethod.SUNNI_IRAQ,
      CalculationMethod.QATAR,
      CalculationMethod.SINGAPORE,
      CalculationMethod.FRANCE,
      CalculationMethod.TURKEY,
      CalculationMethod.RUSSIA,
      CalculationMethod.UAE
    ].map((m): PickerItem => ({
      id: m,
      label: SettingsHelper.getCalcMethodLabel(m),
      selected: m === current
    }));
  }

  // ============================================================
  // PICKER ITEM BUILDERS
  // ============================================================

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

  static saveThemeMode(mode: string): void {
    AppStorage.setOrCreate(STORAGE_KEY_THEME_MODE, mode);
    PreferencesHelper.setString(STORAGE_KEY_THEME_MODE, mode);
  }

  // ============================================================
  // THEME MODE
  // ============================================================

  static buildThemePickerItems(current: string): PickerItem[] {
    return [ThemeMode.LIGHT, ThemeMode.DARK, ThemeMode.SYSTEM]
      .map((m): PickerItem => ({
        id: m,
        label: SettingsHelper.getThemeModeLabel(m),
        selected: m === current
      }));
  }

  static async getHijriOffset(): Promise<number> {
    const cached = AppStorage.get<number>(STORAGE_KEY_HIJRI_OFFSET);
    if (cached !== undefined) {
      return cached;
    }

    const loaded = await PreferencesHelper.getNumber(STORAGE_KEY_HIJRI_OFFSET, 0);
    AppStorage.setOrCreate(STORAGE_KEY_HIJRI_OFFSET, loaded);
    return loaded;
  }

  // ============================================================
  // HIJRI OFFSET
  // ============================================================

  static saveHijriOffset(days: number): void {
    AppStorage.setOrCreate(STORAGE_KEY_HIJRI_OFFSET, days);
    PreferencesHelper.setNumber(STORAGE_KEY_HIJRI_OFFSET, days);
  }

  static async getLanguage(): Promise<string> {
    const cached = AppStorage.get<string>(STORAGE_KEY_LANGUAGE);
    if (cached !== undefined) {
      return cached;
    }

    const loaded = await PreferencesHelper.getString(STORAGE_KEY_LANGUAGE, 'en');
    AppStorage.setOrCreate(STORAGE_KEY_LANGUAGE, loaded);
    return loaded;
  }

  // ============================================================
  // LANGUAGE
  // ============================================================

  static saveLanguage(lang: string): void {
    AppStorage.setOrCreate(STORAGE_KEY_LANGUAGE, lang);
    PreferencesHelper.setString(STORAGE_KEY_LANGUAGE, lang);
  }

  static async isWizardCompleted(): Promise<boolean> {
    return PreferencesHelper.getBoolean(STORAGE_KEY_WIZARD_COMPLETED, false);
  }

  // ============================================================
  // WIZARD
  // ============================================================

  static markWizardCompleted(): void {
    PreferencesHelper.setBoolean(STORAGE_KEY_WIZARD_COMPLETED, true);
  }

  /** Reset for testing — clears the flag so the wizard runs again. */
  static resetWizard(): void {
    PreferencesHelper.setBoolean(STORAGE_KEY_WIZARD_COMPLETED, false);
  }

  static getSoundEnabled(): boolean {
    const cached = AppStorage.get<boolean>(STORAGE_KEY_SOUND_ENABLED);
    return cached === undefined ? true : cached;
  }

  // ============================================================
  // SOUND
  // ============================================================

  static saveSoundEnabled(value: boolean): void {
    AppStorage.setOrCreate(STORAGE_KEY_SOUND_ENABLED, value);
    PreferencesHelper.setBoolean(STORAGE_KEY_SOUND_ENABLED, value);
  }

  static getTasbihSound(): string {
    const cached = AppStorage.get<string>(STORAGE_KEY_TASBIH_SOUND);
    if (cached !== undefined && cached.length > 0) {
      return cached;
    }
    return SoundOptions.DEFAULT_ID;
  }

  // ============================================================
  // TASBIH SOUND SELECTION
  // ============================================================

  static saveTasbihSound(id: string): void {
    AppStorage.setOrCreate(STORAGE_KEY_TASBIH_SOUND, id);
    PreferencesHelper.setString(STORAGE_KEY_TASBIH_SOUND, id);
  }

  static getVibrationEnabled(): boolean {
    const cached = AppStorage.get<boolean>(STORAGE_KEY_VIBRATION_ENABLED);
    return cached === undefined ? true : cached;
  }

  // ============================================================
  // VIBRATION
  // ============================================================

  static saveVibrationEnabled(value: boolean): void {
    AppStorage.setOrCreate(STORAGE_KEY_VIBRATION_ENABLED, value);
    PreferencesHelper.setBoolean(STORAGE_KEY_VIBRATION_ENABLED, value);
  }

  static async getTasbihRenderStyle(): Promise<string> {
    return PreferencesHelper.getString(STORAGE_KEY_TASBIH_RENDER_STYLE, 'premium');
  }

  // ============================================================
  // TASBIH RENDER STYLE (premium / classic)
  // ============================================================

  static saveTasbihRenderStyle(style: string): void {
    PreferencesHelper.setString(STORAGE_KEY_TASBIH_RENDER_STYLE, style);
  }

  static async getTasbihThemePreset(): Promise<string> {
    return PreferencesHelper.getString(
      STORAGE_KEY_TASBIH_THEME_PRESET,
      TasbihThemes.DEFAULT_PRESET_ID
    );
  }

  // ============================================================
  // TASBIH THEME PRESET (global default)
  // ============================================================

  static saveTasbihThemePreset(presetId: string): void {
    PreferencesHelper.setString(STORAGE_KEY_TASBIH_THEME_PRESET, presetId);
  }

  private static bumpLocationVersion(): void {
    const prev = AppStorage.get<number>('location_version');
    const next = (prev === undefined ? 0 : prev) + 1;
    AppStorage.setOrCreate('location_version', next);
  }

  // ============================================================
  // ADVANCED CALCULATION SETTINGS
  // ============================================================

  static async getAdvancedCalcSettings(): Promise<AdvancedCalcSettings> {
    const rounding = await PreferencesHelper.getString(
      STORAGE_KEY_ROUNDING_METHOD, RoundingMethod.NEAREST
    ) as RoundingMethod;
    const midnight = await PreferencesHelper.getString(
      STORAGE_KEY_MIDNIGHT_METHOD, MidnightMethod.STANDARD
    ) as MidnightMethod;
    const polar = await PreferencesHelper.getString(
      STORAGE_KEY_POLAR_RESOLUTION, PolarResolution.UNRESOLVED
    ) as PolarResolution;
    const shafaq = await PreferencesHelper.getString(
      STORAGE_KEY_SHAFAQ, Shafaq.GENERAL
    ) as Shafaq;

    const fajr = await PreferencesHelper.getNumber(
      STORAGE_KEY_CUSTOM_FAJR_ANGLE, DEFAULT_CUSTOM_ANGLES.fajr
    );
    const isha = await PreferencesHelper.getNumber(
      STORAGE_KEY_CUSTOM_ISHA_ANGLE, DEFAULT_CUSTOM_ANGLES.isha
    );
    const interval = await PreferencesHelper.getNumber(
      STORAGE_KEY_CUSTOM_ISHA_INTERVAL, DEFAULT_CUSTOM_ANGLES.ishaInterval
    );

    const angles: CustomAngles = {
      fajr: fajr,
      isha: isha,
      ishaInterval: interval
    };

    const result: AdvancedCalcSettings = {
      rounding: rounding,
      midnight: midnight,
      polarResolution: polar,
      shafaq: shafaq,
      customAngles: angles
    };
    return result;
  }

  static saveRounding(r: RoundingMethod): void {
    PreferencesHelper.setString(STORAGE_KEY_ROUNDING_METHOD, r);
  }

  static saveMidnight(m: MidnightMethod): void {
    PreferencesHelper.setString(STORAGE_KEY_MIDNIGHT_METHOD, m);
  }

  static savePolarResolution(p: PolarResolution): void {
    PreferencesHelper.setString(STORAGE_KEY_POLAR_RESOLUTION, p);
  }

  static saveShafaq(s: Shafaq): void {
    PreferencesHelper.setString(STORAGE_KEY_SHAFAQ, s);
  }

  static async saveCustomAngles(a: CustomAngles): Promise<void> {
    await PreferencesHelper.setNumber(STORAGE_KEY_CUSTOM_FAJR_ANGLE, a.fajr);
    await PreferencesHelper.setNumber(STORAGE_KEY_CUSTOM_ISHA_ANGLE, a.isha);
    await PreferencesHelper.setNumber(
      STORAGE_KEY_CUSTOM_ISHA_INTERVAL, a.ishaInterval
    );
  }

  // ============================================================
  // HIJRI CALENDAR TYPE
  // ============================================================

  static getHijriCalendarType(): string {
    const cached = AppStorage.get<string>(STORAGE_KEY_HIJRI_CALENDAR_TYPE);
    if (cached !== undefined && cached.length > 0) {
      return cached;
    }
    return HijriCalendarType.UMM_AL_QURA;
  }

  static saveHijriCalendarType(type: string): void {
    AppStorage.setOrCreate(STORAGE_KEY_HIJRI_CALENDAR_TYPE, type);
    PreferencesHelper.setString(STORAGE_KEY_HIJRI_CALENDAR_TYPE, type);
  }

  static getHijriCalendarTypeLabel(type: string): string {
    if (type === HijriCalendarType.TABULAR) {
      return L.get('hijri_calendar_tabular');
    }
    return L.get('hijri_calendar_umm_al_qura');
  }

  static buildHijriCalendarTypePickerItems(current: string): PickerItem[] {
    const out: PickerItem[] = [];

    const uaq: PickerItem = {
      id: HijriCalendarType.UMM_AL_QURA,
      label: L.get('hijri_calendar_umm_al_qura'),
      selected: current === HijriCalendarType.UMM_AL_QURA
    };
    out.push(uaq);

    const tab: PickerItem = {
      id: HijriCalendarType.TABULAR,
      label: L.get('hijri_calendar_tabular'),
      selected: current === HijriCalendarType.TABULAR
    };
    out.push(tab);

    return out;
  }
}