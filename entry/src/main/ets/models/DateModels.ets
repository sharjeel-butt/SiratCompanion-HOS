// entry/src/main/ets/models/DateModels.ets

/**
 * How an Islamic event recurs within the Hijri calendar.
 *
 * FIXED — the event falls on the same Hijri month and day every year.
 * FIRST_THURSDAY_NIGHT — the event falls on the Thursday night that
 *   precedes the first Friday of a Hijri month. The night technically
 *   belongs to the following Gregorian day, but the app displays the
 *   event against the Thursday's Gregorian date so it appears before
 *   the Friday in the calendar.
 */
export enum EventRecurrence {
  FIXED = 'fixed',
  FIRST_THURSDAY_NIGHT = 'firstThursdayNight'
}

export interface IslamicEvent {
  /** Stable identifier used for localisation — e.g. 'ashura' → event_ashura */
  key: string;
  name: string;

  /** Hijri month (1 = Muharram, 12 = Dhul-Hijjah). */
  month: number;

  /** Hijri day (1–30) for FIXED events. Ignored otherwise. */
  day: number;

  /** How the event recurs within the month. */
  recurrence: EventRecurrence;
}

export interface UpcomingImportantDate {
  /** Stable identifier used for localisation — e.g. 'ashura' → event_ashura */
  key: string;
  name: string;
  hijriDate: string;
  gregorianDate: Date;
  /** Calendar days from today. 0 = today, 1 = tomorrow, etc. */
  daysUntil: number;
}