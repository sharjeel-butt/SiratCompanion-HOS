// entry/src/main/ets/utils/SettingsHelper.ets

import { CalculationMethod, AsrShadowRule } from './PrayerTimeCalculator';
import {
  STORAGE_KEY_CALC_METHOD,
  STORAGE_KEY_ASR_RULE,
  STORAGE_KEY_CALC_SOURCE,
  STORAGE_KEY_COUNTER
} from '../common/StorageKeys';
import { PickerItem, CalculationSource } from '../models/SettingsModels';

export class SettingsHelper {

  private static initialized: boolean = false;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  static initializeDefaults(): void {
    if (SettingsHelper.initialized) return;
    SettingsHelper.initialized = true;

    PersistentStorage.persistProp(STORAGE_KEY_CALC_METHOD, CalculationMethod.KARACHI);
    PersistentStorage.persistProp(STORAGE_KEY_ASR_RULE, AsrShadowRule.STANDARD as number);
    PersistentStorage.persistProp(STORAGE_KEY_CALC_SOURCE, CalculationSource.LOCAL);
    PersistentStorage.persistProp(STORAGE_KEY_COUNTER, 0);
  }

  // ============================================================
  // CALCULATION METHOD
  // ============================================================

  static getCalcMethod(): CalculationMethod {
    const stored = AppStorage.get<string>(STORAGE_KEY_CALC_METHOD);
    if (stored) {
      const found = [
        CalculationMethod.KARACHI,
        CalculationMethod.JAFARI,
        CalculationMethod.ISNA,
        CalculationMethod.MWL
      ].find(v => v === stored);
      if (found !== undefined) return found;
    }
    return CalculationMethod.KARACHI;
  }

  static setCalcMethod(method: CalculationMethod): void {
    AppStorage.setOrCreate(STORAGE_KEY_CALC_METHOD, method);
  }

  static getCalcMethodLabel(method: CalculationMethod): string {
    switch (method) {
      case CalculationMethod.KARACHI: return 'University of Islamic Sciences, Karachi';
      case CalculationMethod.JAFARI:  return 'Shia Ithna Ashari (Leva Institute, Qum)';
      case CalculationMethod.ISNA:    return 'Islamic Society of North America';
      case CalculationMethod.MWL:     return 'Muslim World League';
      default: return 'Karachi';
    }
  }

  // ============================================================
  // ASR RULE
  // ============================================================

  static getAsrRule(): AsrShadowRule {
    const stored = AppStorage.get<number>(STORAGE_KEY_ASR_RULE);
    if (stored !== undefined) {
      if (stored === AsrShadowRule.STANDARD) return AsrShadowRule.STANDARD;
      if (stored === AsrShadowRule.HANAFI) return AsrShadowRule.HANAFI;
    }
    return AsrShadowRule.STANDARD;
  }

  static setAsrRule(rule: AsrShadowRule): void {
    AppStorage.setOrCreate(STORAGE_KEY_ASR_RULE, rule as number);
  }

  static getAsrRuleLabel(rule: AsrShadowRule): string {
    switch (rule) {
      case AsrShadowRule.STANDARD: return 'Standard (Shafi\'i / Maliki / Hanbali)';
      case AsrShadowRule.HANAFI:   return 'Hanafi';
      default: return 'Standard';
    }
  }

  // ============================================================
  // CALCULATION SOURCE
  // ============================================================

  static getCalcSource(): CalculationSource {
    const stored = AppStorage.get<string>(STORAGE_KEY_CALC_SOURCE);
    if (stored) {
      if (stored === CalculationSource.LOCAL) return CalculationSource.LOCAL;
      if (stored === CalculationSource.API) return CalculationSource.API;
    }
    return CalculationSource.LOCAL;
  }

  static setCalcSource(source: CalculationSource): void {
    AppStorage.setOrCreate(STORAGE_KEY_CALC_SOURCE, source);
  }

  static getCalcSourceLabel(source: CalculationSource): string {
    switch (source) {
      case CalculationSource.LOCAL: return 'Local Formula (Offline)';
      case CalculationSource.API:   return 'API (Online)';
      default: return 'Local Formula (Offline)';
    }
  }

  // ============================================================
  // COUNTER
  // ============================================================

  static getCounter(): number {
    const stored = AppStorage.get<number>(STORAGE_KEY_COUNTER);
    return stored !== undefined ? stored : 0;
  }

  static setCounter(value: number): void {
    AppStorage.setOrCreate(STORAGE_KEY_COUNTER, value);
  }

  // ============================================================
  // PICKER ITEM BUILDERS
  // ============================================================

  static buildMethodPickerItems(current: CalculationMethod): PickerItem[] {
    return [
      CalculationMethod.KARACHI,
      CalculationMethod.JAFARI,
      CalculationMethod.ISNA,
      CalculationMethod.MWL
    ].map((m): PickerItem => ({
      id: m,
      label: SettingsHelper.getCalcMethodLabel(m),
      selected: m === current
    }));
  }

  static buildAsrPickerItems(current: AsrShadowRule): PickerItem[] {
    return [
      AsrShadowRule.STANDARD,
      AsrShadowRule.HANAFI
    ].map((r): PickerItem => ({
      id: r.toString(),
      label: SettingsHelper.getAsrRuleLabel(r),
      selected: r === current
    }));
  }

  static buildSourcePickerItems(current: CalculationSource): PickerItem[] {
    return [
      CalculationSource.LOCAL,
      CalculationSource.API
    ].map((s): PickerItem => ({
      id: s,
      label: SettingsHelper.getCalcSourceLabel(s),
      selected: s === current
    }));
  }
}