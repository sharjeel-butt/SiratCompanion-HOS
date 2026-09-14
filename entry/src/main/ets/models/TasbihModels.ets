// entry/src/main/ets/models/TasbihModels.ets

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
  /** Total increment actions ever performed on any dhikr in this
   *  tasbih. Never decremented by the user. Persisted with the tasbih. */
  lifetimeCount: number;
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