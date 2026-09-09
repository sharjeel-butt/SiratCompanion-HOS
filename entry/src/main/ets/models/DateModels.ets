// entry/src/main/ets/models/DateModels.ets

export interface IslamicEvent {
  name: string;
  month: number; // Hijri month (1 = Muharram, 12 = Dhul-Hijjah)
  day: number;   // Hijri day (1–30)
}

export interface UpcomingImportantDate {
  name: string;
  hijriDate: string; // Formatted like "1 Muharram 1448 AH"
  gregorianDate: Date;
}