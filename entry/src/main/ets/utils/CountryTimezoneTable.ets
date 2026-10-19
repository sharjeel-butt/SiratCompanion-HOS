// entry/src/main/ets/utils/CountryTimezoneTable.ets

import { DstRule } from './OfflineCityLookup';

export interface CountryZone {
  code: string;
  minLat: number;
  maxLat: number;
  minLng: number;
  maxLng: number;
  standardOffset: number;
  dstRule: DstRule;
}

/**
 * Coarse bounding-box table, one entry per country or distinct
 * timezone region. Only used as a fallback when the nearest-city
 * lookup misses — so precision is not critical, coverage is.
 *
 * Tested in array order; the first containing box wins. Put the
 * smaller / more-specific boxes before the wider ones for the
 * same country.
 *
 * Multi-zone splits included:
 *   US (4), CA (6), RU (11), AU (5), BR (2), MX (3), ID (3)
 */

export const COUNTRY_ZONES: CountryZone[] = [
  // ---- Middle East / Anatolia ----
  {
    code: 'TR',
    minLat: 35.8,
    maxLat: 42.1,
    minLng: 25.6,
    maxLng: 44.8,
    standardOffset: 3,
    dstRule: DstRule.NONE
  },

  // ---- South Asia ----
  {
    code: 'PK',
    minLat: 23.6,
    maxLat: 37.1,
    minLng: 60.8,
    maxLng: 77.9,
    standardOffset: 5,
    dstRule: DstRule.NONE
  },
  {
    code: 'IN',
    minLat: 6.7,
    maxLat: 35.5,
    minLng: 68.1,
    maxLng: 97.4,
    standardOffset: 5.5,
    dstRule: DstRule.NONE
  },
  {
    code: 'AF',
    minLat: 29.3,
    maxLat: 38.5,
    minLng: 60.5,
    maxLng: 74.9,
    standardOffset: 4.5,
    dstRule: DstRule.NONE
  },
  {
    code: 'BD',
    minLat: 20.6,
    maxLat: 26.6,
    minLng: 88.0,
    maxLng: 92.7,
    standardOffset: 6,
    dstRule: DstRule.NONE
  },
  {
    code: 'LK',
    minLat: 5.9,
    maxLat: 9.9,
    minLng: 79.6,
    maxLng: 81.9,
    standardOffset: 5.5,
    dstRule: DstRule.NONE
  },
  {
    code: 'NP',
    minLat: 26.3,
    maxLat: 30.5,
    minLng: 80.0,
    maxLng: 88.2,
    standardOffset: 5.75,
    dstRule: DstRule.NONE
  },

  // ---- Gulf / Arabia ----
  {
    code: 'SA',
    minLat: 16.3,
    maxLat: 32.2,
    minLng: 34.5,
    maxLng: 55.7,
    standardOffset: 3,
    dstRule: DstRule.NONE
  },
  {
    code: 'AE',
    minLat: 22.6,
    maxLat: 26.1,
    minLng: 51.5,
    maxLng: 56.4,
    standardOffset: 4,
    dstRule: DstRule.NONE
  },
  {
    code: 'QA',
    minLat: 24.4,
    maxLat: 26.2,
    minLng: 50.7,
    maxLng: 51.7,
    standardOffset: 3,
    dstRule: DstRule.NONE
  },
  {
    code: 'KW',
    minLat: 28.5,
    maxLat: 30.1,
    minLng: 46.5,
    maxLng: 48.4,
    standardOffset: 3,
    dstRule: DstRule.NONE
  },
  {
    code: 'OM',
    minLat: 16.6,
    maxLat: 26.4,
    minLng: 52.0,
    maxLng: 59.9,
    standardOffset: 4,
    dstRule: DstRule.NONE
  },
  {
    code: 'IR',
    minLat: 25.0,
    maxLat: 39.8,
    minLng: 44.0,
    maxLng: 63.3,
    standardOffset: 3.5,
    dstRule: DstRule.NONE
  },

  // ---- Europe ----
  {
    code: 'GB',
    minLat: 49.9,
    maxLat: 60.9,
    minLng: -8.6,
    maxLng: 1.8,
    standardOffset: 0,
    dstRule: DstRule.EU
  },
  {
    code: 'FR',
    minLat: 41.3,
    maxLat: 51.1,
    minLng: -5.2,
    maxLng: 9.6,
    standardOffset: 1,
    dstRule: DstRule.EU
  },
  {
    code: 'DE',
    minLat: 47.2,
    maxLat: 55.1,
    minLng: 5.8,
    maxLng: 15.1,
    standardOffset: 1,
    dstRule: DstRule.EU
  },
  {
    code: 'ES',
    minLat: 36.0,
    maxLat: 43.8,
    minLng: -9.3,
    maxLng: 4.4,
    standardOffset: 1,
    dstRule: DstRule.EU
  },
  {
    code: 'IT',
    minLat: 36.6,
    maxLat: 47.1,
    minLng: 6.6,
    maxLng: 18.6,
    standardOffset: 1,
    dstRule: DstRule.EU
  },

  // ---- Africa ----
  {
    code: 'EG',
    minLat: 22.0,
    maxLat: 31.7,
    minLng: 24.7,
    maxLng: 36.9,
    standardOffset: 2,
    dstRule: DstRule.EGYPT
  },
  {
    code: 'MA',
    minLat: 27.6,
    maxLat: 36.0,
    minLng: -13.2,
    maxLng: -1.0,
    standardOffset: 1,
    dstRule: DstRule.NONE
  },
  {
    code: 'NG',
    minLat: 4.2,
    maxLat: 13.9,
    minLng: 2.6,
    maxLng: 14.7,
    standardOffset: 1,
    dstRule: DstRule.NONE
  },
  {
    code: 'KE',
    minLat: -4.7,
    maxLat: 5.1,
    minLng: 33.8,
    maxLng: 41.9,
    standardOffset: 3,
    dstRule: DstRule.NONE
  },
  {
    code: 'ZA',
    minLat: -34.9,
    maxLat: -22.1,
    minLng: 16.4,
    maxLng: 32.9,
    standardOffset: 2,
    dstRule: DstRule.NONE
  },

  // ---- Russia — eleven zones, west → east ----
  // Kaliningrad is the only +2 zone; small box, put it first.
  {
    code: 'RU-KGD',
    minLat: 54.3,
    maxLat: 55.3,
    minLng: 19.5,
    maxLng: 23.0,
    standardOffset: 2,
    dstRule: DstRule.NONE
  },
  // Moscow Time (European Russia)
  {
    code: 'RU-MSK',
    minLat: 41.0,
    maxLat: 82.0,
    minLng: 26.0,
    maxLng: 46.0,
    standardOffset: 3,
    dstRule: DstRule.NONE
  },
  // Samara Time (Samara, Udmurtia, Ulyanovsk)
  {
    code: 'RU-SAM',
    minLat: 50.0,
    maxLat: 60.0,
    minLng: 46.0,
    maxLng: 56.0,
    standardOffset: 4,
    dstRule: DstRule.NONE
  },
  // Yekaterinburg Time (Sverdlovsk, Chelyabinsk, Bashkortostan)
  {
    code: 'RU-YEK',
    minLat: 50.0,
    maxLat: 70.0,
    minLng: 56.0,
    maxLng: 68.0,
    standardOffset: 5,
    dstRule: DstRule.NONE
  },
  // Omsk Time
  {
    code: 'RU-OMS',
    minLat: 53.0,
    maxLat: 60.0,
    minLng: 68.0,
    maxLng: 79.0,
    standardOffset: 6,
    dstRule: DstRule.NONE
  },
  // Krasnoyarsk Time (Novosibirsk, Krasnoyarsk, Tomsk)
  {
    code: 'RU-NOV',
    minLat: 50.0,
    maxLat: 80.0,
    minLng: 79.0,
    maxLng: 96.0,
    standardOffset: 7,
    dstRule: DstRule.NONE
  },
  // Irkutsk Time
  {
    code: 'RU-IRK',
    minLat: 50.0,
    maxLat: 60.0,
    minLng: 96.0,
    maxLng: 116.0,
    standardOffset: 8,
    dstRule: DstRule.NONE
  },
  // Yakutsk Time (Yakutia west, Amur, Zabaykalsky)
  {
    code: 'RU-YAK',
    minLat: 50.0,
    maxLat: 73.0,
    minLng: 116.0,
    maxLng: 140.0,
    standardOffset: 9,
    dstRule: DstRule.NONE
  },
  // Vladivostok Time (Primorsky, Khabarovsk south)
  {
    code: 'RU-VLA',
    minLat: 42.0,
    maxLat: 50.0,
    minLng: 130.0,
    maxLng: 142.0,
    standardOffset: 10,
    dstRule: DstRule.NONE
  },
  // Magadan Time (Magadan, Sakhalin, Kuril)
  {
    code: 'RU-MAG',
    minLat: 43.0,
    maxLat: 73.0,
    minLng: 140.0,
    maxLng: 160.0,
    standardOffset: 11,
    dstRule: DstRule.NONE
  },
  // Kamchatka Time (Kamchatka, Chukotka)
  {
    code: 'RU-KAM',
    minLat: 50.0,
    maxLat: 72.0,
    minLng: 158.0,
    maxLng: 180.0,
    standardOffset: 12,
    dstRule: DstRule.NONE
  },

  // ---- East / Southeast Asia ----
  {
    code: 'CN',
    minLat: 18.1,
    maxLat: 53.6,
    minLng: 73.5,
    maxLng: 134.8,
    standardOffset: 8,
    dstRule: DstRule.NONE
  },
  {
    code: 'JP',
    minLat: 24.0,
    maxLat: 45.6,
    minLng: 122.9,
    maxLng: 153.9,
    standardOffset: 9,
    dstRule: DstRule.NONE
  },
  {
    code: 'KR',
    minLat: 33.1,
    maxLat: 38.7,
    minLng: 124.6,
    maxLng: 131.9,
    standardOffset: 9,
    dstRule: DstRule.NONE
  },

  // ---- Indonesia — three zones ----
  // WIB (Java, Sumatra) — +7
  {
    code: 'ID-WIB',
    minLat: -11.0,
    maxLat: 6.1,
    minLng: 95.0,
    maxLng: 115.0,
    standardOffset: 7,
    dstRule: DstRule.NONE
  },
  // WITA (Bali, Lombok, Sulawesi, Kalimantan south/east) — +8
  {
    code: 'ID-WITA',
    minLat: -11.0,
    maxLat: 6.1,
    minLng: 115.0,
    maxLng: 127.5,
    standardOffset: 8,
    dstRule: DstRule.NONE
  },
  // WIT (Papua, Maluku) — +9
  {
    code: 'ID-WIT',
    minLat: -11.0,
    maxLat: 6.1,
    minLng: 127.5,
    maxLng: 141.1,
    standardOffset: 9,
    dstRule: DstRule.NONE
  },

  {
    code: 'MY',
    minLat: 0.8,
    maxLat: 7.4,
    minLng: 99.6,
    maxLng: 119.3,
    standardOffset: 8,
    dstRule: DstRule.NONE
  },
  {
    code: 'SG',
    minLat: 1.1,
    maxLat: 1.5,
    minLng: 103.6,
    maxLng: 104.1,
    standardOffset: 8,
    dstRule: DstRule.NONE
  },
  {
    code: 'TH',
    minLat: 5.6,
    maxLat: 20.5,
    minLng: 97.3,
    maxLng: 105.6,
    standardOffset: 7,
    dstRule: DstRule.NONE
  },
  {
    code: 'VN',
    minLat: 8.1,
    maxLat: 23.4,
    minLng: 102.1,
    maxLng: 109.5,
    standardOffset: 7,
    dstRule: DstRule.NONE
  },
  {
    code: 'PH',
    minLat: 4.5,
    maxLat: 21.2,
    minLng: 116.9,
    maxLng: 126.6,
    standardOffset: 8,
    dstRule: DstRule.NONE
  },

  // ---- Americas — multiple zones ----
  {
    code: 'US-E',
    minLat: 24.4,
    maxLat: 49.4,
    minLng: -82.0,
    maxLng: -66.9,
    standardOffset: -5,
    dstRule: DstRule.US
  },
  {
    code: 'US-C',
    minLat: 24.4,
    maxLat: 49.4,
    minLng: -104.0,
    maxLng: -82.0,
    standardOffset: -6,
    dstRule: DstRule.US
  },
  {
    code: 'US-M',
    minLat: 24.4,
    maxLat: 49.4,
    minLng: -115.0,
    maxLng: -104.0,
    standardOffset: -7,
    dstRule: DstRule.US
  },
  {
    code: 'US-P',
    minLat: 24.4,
    maxLat: 49.4,
    minLng: -125.0,
    maxLng: -115.0,
    standardOffset: -8,
    dstRule: DstRule.US
  },

  // ---- Canada — six zones, smallest / most-specific first ----
  // Newfoundland — the only half-hour offset in North America.
  {
    code: 'CA-NL',
    minLat: 46.5,
    maxLat: 60.5,
    minLng: -60.0,
    maxLng: -52.6,
    standardOffset: -3.5,
    dstRule: DstRule.US
  },
  // Atlantic (Nova Scotia, New Brunswick, PEI)
  {
    code: 'CA-ATL',
    minLat: 43.0,
    maxLat: 48.5,
    minLng: -69.1,
    maxLng: -59.9,
    standardOffset: -4,
    dstRule: DstRule.US
  },
  // Eastern (Ontario, Quebec)
  {
    code: 'CA-E',
    minLat: 41.7,
    maxLat: 53.0,
    minLng: -90.0,
    maxLng: -59.9,
    standardOffset: -5,
    dstRule: DstRule.US
  },
  // Central (Manitoba, Saskatchewan, Nunavut east)
  {
    code: 'CA-C',
    minLat: 48.0,
    maxLat: 70.0,
    minLng: -102.0,
    maxLng: -90.0,
    standardOffset: -6,
    dstRule: DstRule.US
  },
  // Mountain (Alberta, Northwest Territories)
  {
    code: 'CA-M',
    minLat: 48.0,
    maxLat: 70.0,
    minLng: -120.0,
    maxLng: -102.0,
    standardOffset: -7,
    dstRule: DstRule.US
  },
  // Pacific (British Columbia, Yukon)
  {
    code: 'CA-P',
    minLat: 48.0,
    maxLat: 70.0,
    minLng: -141.0,
    maxLng: -120.0,
    standardOffset: -8,
    dstRule: DstRule.US
  },

  // ---- Mexico — three zones ----
  // Quintana Roo (Cancún) — the only -5 area
  {
    code: 'MX-CUN',
    minLat: 18.0,
    maxLat: 21.7,
    minLng: -88.5,
    maxLng: -86.7,
    standardOffset: -5,
    dstRule: DstRule.NONE
  },
  // Sonora — the only -7 area
  {
    code: 'MX-SON',
    minLat: 26.0,
    maxLat: 32.5,
    minLng: -115.0,
    maxLng: -108.4,
    standardOffset: -7,
    dstRule: DstRule.NONE
  },
  // Rest of Mexico — -6
  {
    code: 'MX',
    minLat: 14.5,
    maxLat: 32.7,
    minLng: -118.4,
    maxLng: -86.7,
    standardOffset: -6,
    dstRule: DstRule.NONE
  },

  // ---- Brazil — two zones ----
  // Amazonas (Manaus) — the only -4 area
  {
    code: 'BR-AM',
    minLat: -9.0,
    maxLat: 2.0,
    minLng: -73.9,
    maxLng: -56.0,
    standardOffset: -4,
    dstRule: DstRule.NONE
  },
  // Rest of Brazil — -3
  {
    code: 'BR',
    minLat: -33.7,
    maxLat: 5.3,
    minLng: -73.9,
    maxLng: -34.8,
    standardOffset: -3,
    dstRule: DstRule.NONE
  },

  // ---- Oceania — split by state ----
  // Western Australia (Perth) — +8, no DST
  {
    code: 'AU-WA',
    minLat: -35.0,
    maxLat: -13.0,
    minLng: 112.9,
    maxLng: 129.0,
    standardOffset: 8,
    dstRule: DstRule.NONE
  },
  // Northern Territory (Darwin) — +9:30, no DST
  {
    code: 'AU-NT',
    minLat: -26.0,
    maxLat: -11.0,
    minLng: 129.0,
    maxLng: 138.0,
    standardOffset: 9.5,
    dstRule: DstRule.NONE
  },
  // South Australia (Adelaide) — +9:30, DST
  {
    code: 'AU-SA',
    minLat: -38.0,
    maxLat: -26.0,
    minLng: 129.0,
    maxLng: 141.0,
    standardOffset: 9.5,
    dstRule: DstRule.AU
  },
  // Eastern states (NSW, VIC, TAS, ACT) — +10, DST
  // Listed before QLD so the Gold Coast / Tweed Heads
  // border region falls to DST (NSW) rather than no-DST.
  {
    code: 'AU-E',
    minLat: -44.0,
    maxLat: -28.0,
    minLng: 140.0,
    maxLng: 154.0,
    standardOffset: 10,
    dstRule: DstRule.AU
  },
  // Queensland (Brisbane) — +10, no DST
  {
    code: 'AU-QLD',
    minLat: -29.0,
    maxLat: -10.0,
    minLng: 138.0,
    maxLng: 154.0,
    standardOffset: 10,
    dstRule: DstRule.NONE
  },

  // New Zealand — +12, DST
  {
    code: 'NZ',
    minLat: -47.3,
    maxLat: -34.4,
    minLng: 166.4,
    maxLng: 178.6,
    standardOffset: 12,
    dstRule: DstRule.AU
  },
];

export class CountryTimezoneLookup {
  /**
   * Return the zone whose bounding box contains the point, or null.
   * Zones are tested in array order; the first match wins.
   */
  static zoneFor(latitude: number, longitude: number): CountryZone | null {
    for (const z of COUNTRY_ZONES) {
      if (latitude >= z.minLat && latitude <= z.maxLat &&
        longitude >= z.minLng && longitude <= z.maxLng) {
        return z;
      }
    }
    return null;
  }
}