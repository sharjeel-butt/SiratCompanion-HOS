// entry/src/main/ets/data/IslamicEvents.ets

import { IslamicEvent } from '../models/DateModels';

export const IMPORTANT_ISLAMIC_EVENTS: IslamicEvent[] = [
  { key: 'new_year',       name: 'Islamic New Year',  month: 1,  day: 1  },
  { key: 'ashura',         name: 'Day of Ashura',     month: 1,  day: 10 },
  { key: 'mawlid',         name: 'Mawlid al-Nabi',    month: 3,  day: 12 },
  { key: 'isra_miraj',     name: "Isra and Mi'raj",   month: 7,  day: 27 },
  { key: 'mid_shaban',     name: "Mid-Sha'ban",       month: 8,  day: 15 },
  { key: 'ramadan_start',  name: 'Ramadan Start',     month: 9,  day: 1  },
  { key: 'eid_fitr',       name: 'Eid al-Fitr',       month: 10, day: 1  },
  { key: 'arafah',         name: 'Day of Arafah',     month: 12, day: 9  },
  { key: 'eid_adha',       name: 'Eid al-Adha',       month: 12, day: 10 }
];