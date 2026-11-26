// entry/src/main/ets/models/DateModels.ets
import { SourceItem } from '../i18n/SourceParser'

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
  FIXED = 'fixed', FIRST_THURSDAY_NIGHT = 'firstThursdayNight'
}

export enum EventSect {
  UNIVERSAL = 'universal', SUNNI = 'sunni', SHIA = 'shia'
}

export interface IslamicEventSource extends SourceItem {
  type: 'hadith' | 'quran' | 'external'
  id?: string
  surah?: number
  ayah?: number
  display?: string
  role: 'primary' | 'supporting'
}

export interface IslamicEvent {
  key: string
  name: string
  month: number
  day: number
  recurrence: EventRecurrence
  sect: EventSect

  // v4.1.0 additions (optional for backward compat)
  sources?: IslamicEventSource[]
  duas?: string[]
  recitations?: string[]
  migrationStatus?: string
}

export interface UpcomingImportantDate {
  /** Stable identifier used for localisation — e.g. 'ashura' → event_ashura */
  key: string
  name: string
  hijriDate: string
  gregorianDate: Date

  /** Calendar days from today. 0 = today, 1 = tomorrow, etc. */
  daysUntil: number
}
