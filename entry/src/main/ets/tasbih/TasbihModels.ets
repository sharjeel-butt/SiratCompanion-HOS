// entry/src/main/ets/models/TasbihModels.ets

import { TasbihTheme } from './TasbihThemes';

export interface Dhikr {
  id: string;
  arabic: string;
  transliteration: string;
  translation: string;
  target: number;
  count: number;
}

export interface Tasbih {
  id: string;
  name: string;
  dhikrs: Dhikr[];
  createdAt: number;
  lifetimeCount: number;

  /** Optional per-tasbih theme. When absent, the global default is used. */
  theme?: TasbihTheme;

  /** Preset id ('amber' | 'charcoal' | ...) — kept alongside the theme so the
   *  preset can be restored verbatim (including its swatch). */
  themePresetId?: string;
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