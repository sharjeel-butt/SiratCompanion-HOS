// entry/src/main/ets/models/HijriCalendarModels.ets

export interface HijriDate {
  year: number;
  month: number; // 1–12
  day: number; // 1–30
}

/** One cell of the calendar grid. */
export interface CalendarDay {
  gregorianDate: Date;
  hijri: HijriDate;
  isToday: boolean;
  isFriday: boolean;

  /**
   * Stable event keys (`IslamicEvent.key`) for events on this Hijri
   * day. Resolve to a localized label via `L.get('event_' + key)`,
   * as done elsewhere in the app. Empty when no events match.
   */
  events: string[];
}