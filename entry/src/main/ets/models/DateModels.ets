// entry/src/main/ets/models/DateModels.ets

export interface IslamicEvent {
  /** Stable identifier used for localisation — e.g. 'ashura' → event_ashura */
  key: string;
  name: string;
  month: number; // Hijri month (1 = Muharram, 12 = Dhul-Hijjah)
  day: number;   // Hijri day (1–30)
}

export interface UpcomingImportantDate {
  /** Stable identifier used for localisation — e.g. 'ashura' → event_ashura */
  key: string;
  name: string;
  hijriDate: string;
  gregorianDate: Date;
}