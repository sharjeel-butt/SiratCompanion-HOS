// entry/src/main/ets/models/TasbihModels.ets

import { TasbihTheme } from './TasbihThemes';

export interface Dhikr {
  id: string;
  arabic: string;
  transliteration: string;
  translation: string;
  transliterationKey?: string;
  translationKey?: string;
  target: number;
  count: number;
  lastCountDate?: string;
  dailyTotal?: number;
  liveCounts?: Record<string, number>;
}

export interface Tasbih {
  id: string;
  name: string;
  nameKey?: string;
  dhikrs: Dhikr[];
  createdAt: number;
  lifetimeCount: number;
  theme?: TasbihTheme;
  themePresetId?: string;
  history?: TasbihDayLog[];
  boundPrayerIds?: string[];
  prayerCompletions?: Record<string, string>;
}

export interface DhikrDayCount {
  dhikrId: string;
  count: number;
}

export interface TasbihDayLog {
  dateKey: string;
  dhikrCounts: DhikrDayCount[];
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