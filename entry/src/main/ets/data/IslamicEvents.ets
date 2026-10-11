// entry/src/main/ets/data/IslamicEvents.ets

import { EventRecurrence, IslamicEvent } from '../models/DateModels';

/**
 * Registry of Islamic events surfaced on the Home countdown card
 * and in the Hijri calendar.
 *
 * ## Scope — sect-independent events only
 *
 * This list deliberately contains only events that are recognized
 * and observed by all major Islamic traditions — Sunni, Shia, and
 * the schools within each. Sect-specific observances are excluded
 * so that the "next event" countdown matches what a user or
 * reviewer would find on any general Islamic calendar:
 *
 *   Excluded (sect-specific):
 *     • Laylat al-Raghaib — observed mainly in Sunni Sufi traditions
 *     • Eid al-Ghadir — observed mainly in Shia tradition
 *     • Arbaeen — observed mainly in Shia tradition
 *     • Laylat al-Qadr — a period, not a single date; treated
 *       separately in the Ramadan card on the Home page
 *
 * Order within a month does not matter — the resolver sorts by
 * Gregorian date at display time. Events are grouped by Hijri month
 * here so the list reads in calendar order for anyone editing it.
 */
export const IMPORTANT_ISLAMIC_EVENTS: IslamicEvent[] = [
  // ---- Muharram ----
  {
    key: 'new_year',
    name: 'Islamic New Year',
    month: 1,
    day: 1,
    recurrence: EventRecurrence.FIXED
  },
  {
    key: 'ashura',
    name: 'Day of Ashura',
    month: 1,
    day: 10,
    recurrence: EventRecurrence.FIXED
  },

  // ---- Rabi al-Awwal ----
  {
    key: 'mawlid',
    name: 'Mawlid al-Nabi',
    month: 3,
    day: 12,
    recurrence: EventRecurrence.FIXED
  },

  // ---- Rajab ----
  {
    key: 'isra_miraj',
    name: "Isra and Mi'raj",
    month: 7,
    day: 27,
    recurrence: EventRecurrence.FIXED
  },

  // ---- Sha'ban ----
  {
    key: 'mid_shaban',
    name: "Mid-Sha'ban",
    month: 8,
    day: 15,
    recurrence: EventRecurrence.FIXED
  },

  // ---- Ramadan ----
  {
    key: 'ramadan_start',
    name: 'Ramadan Start',
    month: 9,
    day: 1,
    recurrence: EventRecurrence.FIXED
  },

  // ---- Shawwal ----
  {
    key: 'eid_fitr',
    name: 'Eid al-Fitr',
    month: 10,
    day: 1,
    recurrence: EventRecurrence.FIXED
  },

  // ---- Dhul-Hijjah ----
  {
    key: 'arafah',
    name: 'Day of Arafah',
    month: 12,
    day: 9,
    recurrence: EventRecurrence.FIXED
  },
  {
    key: 'eid_adha',
    name: 'Eid al-Adha',
    month: 12,
    day: 10,
    recurrence: EventRecurrence.FIXED
  }
];