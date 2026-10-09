// entry/src/main/ets/models/AdvancedCalcModels.ets

/** How displayed times are rounded. */
export enum RoundingMethod {
  NEAREST = 'Nearest',
  UP = 'Up',
  NONE = 'None'
}

/** Which night boundary defines Islamic midnight. */
export enum MidnightMethod {
  /** Sunset → next sunrise. Common default. */
  STANDARD = 'Standard',
  /** Sunset → next Fajr. Jafari / Shia convention. */
  JAFARI = 'Jafari'
}

/** Twilight colour used by the Moonsighting Committee method. */
export enum Shafaq {
  GENERAL = 'General',
  AHMER = 'Ahmer',
  ABYAD = 'Abyad'
}

/** What to do at extreme latitudes when an angle can't be reached. */
export enum PolarResolution {
  UNRESOLVED = 'Unresolved',
  AQRAB_BALAD = 'AqrabBalad',
  AQRAB_YAUM = 'AqrabYaum'
}

/** User-supplied angles for the Custom method. */
export interface CustomAngles {
  fajr: number;
  isha: number;

  /** > 0 → Isha is interval-minutes after Maghrib, angle ignored. */
  ishaInterval: number;
}

export const DEFAULT_CUSTOM_ANGLES: CustomAngles = {
  fajr: 18,
  isha: 18,
  ishaInterval: 0
};

/** Everything the Advanced Calculation Settings screen persists. */
export interface AdvancedCalcSettings {
  rounding: RoundingMethod;
  midnight: MidnightMethod;
  polarResolution: PolarResolution;
  shafaq: Shafaq;
  customAngles: CustomAngles;
}

export const DEFAULT_ADVANCED_CALC: AdvancedCalcSettings = {
  rounding: RoundingMethod.NEAREST,
  midnight: MidnightMethod.STANDARD,
  polarResolution: PolarResolution.UNRESOLVED,
  shafaq: Shafaq.GENERAL,
  customAngles: DEFAULT_CUSTOM_ANGLES
};