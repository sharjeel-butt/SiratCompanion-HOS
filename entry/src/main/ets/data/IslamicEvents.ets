import {
  EventRecurrence, EventSect, IslamicEvent
} from '../models/DateModels';

export const IMPORTANT_ISLAMIC_EVENTS: IslamicEvent[] = [
  // ---- Muharram ----
  {
    key: 'new_year',
    name: 'Islamic New Year',
    month: 1,
    day: 1,
    recurrence: EventRecurrence.FIXED,
    sect: EventSect.UNIVERSAL
  },
  {
    key: 'ashura',
    name: 'Day of Ashura',
    month: 1,
    day: 10,
    recurrence: EventRecurrence.FIXED,
    sect: EventSect.UNIVERSAL
  },

  // ---- Safar (Shia) ----
  {
    key: 'arbaeen',
    name: 'Arbaeen',
    month: 2,
    day: 20,
    recurrence: EventRecurrence.FIXED,
    sect: EventSect.SHIA
  },

  // ---- Rabi al-Awwal ----
  {
    key: 'mawlid',
    name: 'Mawlid al-Nabi',
    month: 3,
    day: 12,
    recurrence: EventRecurrence.FIXED,
    sect: EventSect.UNIVERSAL
  },

  // ---- Rajab ----
  {
    key: 'raghaib',
    name: 'Laylat al-Raghaib',
    month: 7,
    day: 1,
    recurrence: EventRecurrence.FIRST_THURSDAY_NIGHT,
    sect: EventSect.SUNNI
  },
  {
    key: 'imam_ali_birthday',
    name: 'Birthday of Imam Ali',
    month: 7,
    day: 13,
    recurrence: EventRecurrence.FIXED,
    sect: EventSect.SHIA
  },
  {
    key: 'isra_miraj',
    name: "Isra and Mi'raj",
    month: 7,
    day: 27,
    recurrence: EventRecurrence.FIXED,
    sect: EventSect.UNIVERSAL
  },

  // ---- Sha'ban ----
  {
    key: 'mid_shaban',
    name: "Mid-Sha'ban",
    month: 8,
    day: 15,
    recurrence: EventRecurrence.FIXED,
    sect: EventSect.UNIVERSAL
  },

  // ---- Ramadan ----
  {
    key: 'ramadan_start',
    name: 'Ramadan Start',
    month: 9,
    day: 1,
    recurrence: EventRecurrence.FIXED,
    sect: EventSect.UNIVERSAL
  },

  // ---- Shawwal ----
  {
    key: 'eid_fitr',
    name: 'Eid al-Fitr',
    month: 10,
    day: 1,
    recurrence: EventRecurrence.FIXED,
    sect: EventSect.UNIVERSAL
  },

  // ---- Dhul-Hijjah ----
  {
    key: 'arafah',
    name: 'Day of Arafah',
    month: 12,
    day: 9,
    recurrence: EventRecurrence.FIXED,
    sect: EventSect.UNIVERSAL
  },
  {
    key: 'eid_adha',
    name: 'Eid al-Adha',
    month: 12,
    day: 10,
    recurrence: EventRecurrence.FIXED,
    sect: EventSect.UNIVERSAL
  },
  {
    key: 'ghadir',
    name: 'Eid al-Ghadir',
    month: 12,
    day: 18,
    recurrence: EventRecurrence.FIXED,
    sect: EventSect.SHIA
  }
];

/**
 * True when the given event should be shown for the given
 * perspective string.
 */
export function eventMatchesPerspective(
  event: IslamicEvent, perspective: string
): boolean {
  if (perspective === 'universal') {
    return event.sect === EventSect.UNIVERSAL;
  }
  if (perspective === 'sunni') {
    return event.sect === EventSect.UNIVERSAL
      || event.sect === EventSect.SUNNI;
  }
  if (perspective === 'shia') {
    return event.sect === EventSect.UNIVERSAL
      || event.sect === EventSect.SHIA;
  }
  return true; // 'all'
}