// entry/src/main/ets/models/TasbihModels.ets

import { TasbihTheme } from './TasbihThemes';

export interface Dhikr {
  id: string;
  arabic: string;
  transliteration: string;
  translation: string;
  target: number;
  count: number;
  lastCountDate?: string;
  dailyTotal?: number;
}

export interface DhikrDayCount {
  dhikrId: string;
  count: number;
}

export interface TasbihDayLog {
  dateKey: string;
  dhikrCounts: DhikrDayCount[];
}

export interface Tasbih {
  id: string;
  name: string;
  dhikrs: Dhikr[];
  createdAt: number;
  lifetimeCount: number;

  theme?: TasbihTheme;
  themePresetId?: string;

  /**
   * Rolling daily log. One entry per day on which the tasbih was
   * touched, capped at HISTORY_MAX_DAYS. Absent on data created
   * before 3.2.5.
   */
  history?: TasbihDayLog[];
}

export interface DhikrFields {
  arabic: string;
  transliteration: string;
  translation: string;
  target: number;
}

export interface BeadView {
  topIds: number[];
  bottomIds: number[];
  isComplete: boolean;
  topAtCap: boolean;
  bottomAtCap: boolean;
}

export interface AddTasbihResult {
  tasbihs: Tasbih[];
  newId: string;
}