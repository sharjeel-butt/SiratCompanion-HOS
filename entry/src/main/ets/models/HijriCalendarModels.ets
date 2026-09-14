// entry/src/main/ets/models/HijriCalendarModels.ets

export interface HijriDate {
  year: number;
  month: number;   // 1–12
  day: number;     // 1–30
}

/** One cell of the calendar grid. */
export interface CalendarDay {
  gregorianDate: Date;
  hijri: HijriDate;
  isToday: boolean;
  isFriday: boolean;
  events: string[];        // names of events on this Hijri day
}