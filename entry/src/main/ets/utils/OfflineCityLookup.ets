// entry/src/main/ets/utils/OfflineCityLookup.ets

/**
 * Offline city lookup with timezone metadata.
 *
 * Matching rule: the closest city within MAX_MATCH_KM wins.
 * Beyond that, callers fall back to a longitude estimate.
 */

export enum DstRule {
  NONE = 'NONE',   // No DST
  US   = 'US',     // 2nd Sun March → 1st Sun November
  EU   = 'EU',     // Last Sun March → Last Sun October
  AU   = 'AU'      // Southern hemisphere: 1st Sun Oct → 1st Sun April
}

export interface City {
  name: string;
  lat: number;
  lng: number;
  standardOffset: number;   // hours east of UTC (may be fractional)
  dstRule: DstRule;
  /**
   * Magnetic declination in degrees for 2024, East positive.
   * Applied on top of the magnetic heading reported by the sensor
   * to obtain true north.
   */
  declinationDeg: number;
}

const MAX_MATCH_KM = 100;

const CITIES: City[] = [
  { name: 'Karachi',      lat: 24.8607,  lng: 67.0011,  standardOffset: 5,    dstRule: DstRule.NONE, declinationDeg:  1.6 },
  { name: 'Lahore',       lat: 31.5204,  lng: 74.3587,  standardOffset: 5,    dstRule: DstRule.NONE, declinationDeg:  1.8 },
  { name: 'Islamabad',    lat: 33.6844,  lng: 73.0479,  standardOffset: 5,    dstRule: DstRule.NONE, declinationDeg:  1.9 },
  { name: 'Rawalpindi',   lat: 33.5651,  lng: 73.0169,  standardOffset: 5,    dstRule: DstRule.NONE, declinationDeg:  1.9 },
  { name: 'Faisalabad',   lat: 31.4180,  lng: 73.0790,  standardOffset: 5,    dstRule: DstRule.NONE, declinationDeg:  1.8 },
  { name: 'Multan',       lat: 30.1575,  lng: 71.5249,  standardOffset: 5,    dstRule: DstRule.NONE, declinationDeg:  1.7 },
  { name: 'Peshawar',     lat: 34.0151,  lng: 71.5249,  standardOffset: 5,    dstRule: DstRule.NONE, declinationDeg:  1.9 },
  { name: 'Quetta',       lat: 30.1798,  lng: 66.9750,  standardOffset: 5,    dstRule: DstRule.NONE, declinationDeg:  1.6 },

  { name: 'Delhi',        lat: 28.6139,  lng: 77.2090,  standardOffset: 5.5,  dstRule: DstRule.NONE, declinationDeg:  0.5 },
  { name: 'Mumbai',       lat: 19.0760,  lng: 72.8777,  standardOffset: 5.5,  dstRule: DstRule.NONE, declinationDeg: -0.2 },
  { name: 'Bangalore',    lat: 12.9716,  lng: 77.5946,  standardOffset: 5.5,  dstRule: DstRule.NONE, declinationDeg: -0.5 },
  { name: 'Hyderabad',    lat: 17.3850,  lng: 78.4867,  standardOffset: 5.5,  dstRule: DstRule.NONE, declinationDeg: -0.1 },
  { name: 'Chennai',      lat: 13.0827,  lng: 80.2707,  standardOffset: 5.5,  dstRule: DstRule.NONE, declinationDeg: -0.7 },
  { name: 'Kolkata',      lat: 22.5726,  lng: 88.3639,  standardOffset: 5.5,  dstRule: DstRule.NONE, declinationDeg:  0.3 },

  { name: 'Makkah',       lat: 21.4225,  lng: 39.8262,  standardOffset: 3,    dstRule: DstRule.NONE, declinationDeg:  3.1 },
  { name: 'Madinah',      lat: 24.5247,  lng: 39.5692,  standardOffset: 3,    dstRule: DstRule.NONE, declinationDeg:  3.5 },
  { name: 'Riyadh',       lat: 24.7136,  lng: 46.6753,  standardOffset: 3,    dstRule: DstRule.NONE, declinationDeg:  3.3 },
  { name: 'Jeddah',       lat: 21.4858,  lng: 39.1925,  standardOffset: 3,    dstRule: DstRule.NONE, declinationDeg:  3.2 },
  { name: 'Dubai',        lat: 25.2048,  lng: 55.2708,  standardOffset: 4,    dstRule: DstRule.NONE, declinationDeg:  2.2 },
  { name: 'Abu Dhabi',    lat: 24.4539,  lng: 54.3773,  standardOffset: 4,    dstRule: DstRule.NONE, declinationDeg:  2.1 },
  { name: 'Doha',         lat: 25.2854,  lng: 51.5310,  standardOffset: 3,    dstRule: DstRule.NONE, declinationDeg:  2.6 },
  { name: 'Kuwait City',  lat: 29.3759,  lng: 47.9774,  standardOffset: 3,    dstRule: DstRule.NONE, declinationDeg:  3.3 },
  { name: 'Muscat',       lat: 23.5880,  lng: 58.3829,  standardOffset: 4,    dstRule: DstRule.NONE, declinationDeg:  2.1 },
  { name: 'Tehran',       lat: 35.6892,  lng: 51.3890,  standardOffset: 3.5,  dstRule: DstRule.NONE, declinationDeg:  5.1 },
  { name: 'Istanbul',     lat: 41.0082,  lng: 28.9784,  standardOffset: 3,    dstRule: DstRule.NONE, declinationDeg:  5.5 },
  { name: 'Baghdad',      lat: 33.3152,  lng: 44.3661,  standardOffset: 3,    dstRule: DstRule.NONE, declinationDeg:  4.5 },
  { name: 'Amman',        lat: 31.9454,  lng: 35.9284,  standardOffset: 3,    dstRule: DstRule.NONE, declinationDeg:  4.5 },
  { name: 'Beirut',       lat: 33.8938,  lng: 35.5018,  standardOffset: 2,    dstRule: DstRule.EU,   declinationDeg:  4.5 },
  { name: 'Cairo',        lat: 30.0444,  lng: 31.2357,  standardOffset: 2,    dstRule: DstRule.EU,   declinationDeg:  4.5 },

  { name: 'Shanghai',     lat: 31.2304,  lng: 121.4737, standardOffset: 8,    dstRule: DstRule.NONE, declinationDeg: -5.5 },
  { name: 'Beijing',      lat: 39.9042,  lng: 116.4074, standardOffset: 8,    dstRule: DstRule.NONE, declinationDeg: -6.8 },
  { name: 'Guangzhou',    lat: 23.1291,  lng: 113.2644, standardOffset: 8,    dstRule: DstRule.NONE, declinationDeg: -3.3 },
  { name: 'Shenzhen',     lat: 22.5431,  lng: 114.0579, standardOffset: 8,    dstRule: DstRule.NONE, declinationDeg: -3.2 },
  { name: 'Hong Kong',    lat: 22.3193,  lng: 114.1694, standardOffset: 8,    dstRule: DstRule.NONE, declinationDeg: -3.2 },
  { name: 'Tokyo',        lat: 35.6762,  lng: 139.6503, standardOffset: 9,    dstRule: DstRule.NONE, declinationDeg: -7.5 },
  { name: 'Seoul',        lat: 37.5665,  lng: 126.9780, standardOffset: 9,    dstRule: DstRule.NONE, declinationDeg: -8.3 },
  { name: 'Singapore',    lat: 1.3521,   lng: 103.8198, standardOffset: 8,    dstRule: DstRule.NONE, declinationDeg:  0.2 },
  { name: 'Kuala Lumpur', lat: 3.1390,   lng: 101.6869, standardOffset: 8,    dstRule: DstRule.NONE, declinationDeg: -0.1 },
  { name: 'Jakarta',      lat: -6.2088,  lng: 106.8456, standardOffset: 7,    dstRule: DstRule.NONE, declinationDeg:  0.8 },
  { name: 'Dhaka',        lat: 23.8103,  lng: 90.4125,  standardOffset: 6,    dstRule: DstRule.NONE, declinationDeg: -0.5 },
  { name: 'Kabul',        lat: 34.5553,  lng: 69.2075,  standardOffset: 4.5,  dstRule: DstRule.NONE, declinationDeg:  2.4 },

  { name: 'London',       lat: 51.5074,  lng: -0.1278,  standardOffset: 0,    dstRule: DstRule.EU,   declinationDeg:  0.5 },
  { name: 'Paris',        lat: 48.8566,  lng: 2.3522,   standardOffset: 1,    dstRule: DstRule.EU,   declinationDeg:  1.5 },
  { name: 'Berlin',       lat: 52.5200,  lng: 13.4050,  standardOffset: 1,    dstRule: DstRule.EU,   declinationDeg:  4.0 },
  { name: 'Madrid',       lat: 40.4168,  lng: -3.7038,  standardOffset: 1,    dstRule: DstRule.EU,   declinationDeg: -1.5 },
  { name: 'Rome',         lat: 41.9028,  lng: 12.4964,  standardOffset: 1,    dstRule: DstRule.EU,   declinationDeg:  2.5 },
  { name: 'Amsterdam',    lat: 52.3676,  lng: 4.9041,   standardOffset: 1,    dstRule: DstRule.EU,   declinationDeg:  2.0 },
  { name: 'Moscow',       lat: 55.7558,  lng: 37.6173,  standardOffset: 3,    dstRule: DstRule.NONE, declinationDeg: 10.5 },

  { name: 'Lagos',        lat: 6.5244,   lng: 3.3792,   standardOffset: 1,    dstRule: DstRule.NONE, declinationDeg: -1.5 },
  { name: 'Nairobi',      lat: -1.2921,  lng: 36.8219,  standardOffset: 3,    dstRule: DstRule.NONE, declinationDeg:  0.5 },
  { name: 'Cape Town',    lat: -33.9249, lng: 18.4241,  standardOffset: 2,    dstRule: DstRule.NONE, declinationDeg: -24.0 },
  { name: 'Casablanca',   lat: 33.5731,  lng: -7.5898,  standardOffset: 1,    dstRule: DstRule.NONE, declinationDeg: -4.0 },

  { name: 'New York',     lat: 40.7128,  lng: -74.0060, standardOffset: -5,   dstRule: DstRule.US,   declinationDeg: -13.0 },
  { name: 'Chicago',      lat: 41.8781,  lng: -87.6298, standardOffset: -6,   dstRule: DstRule.US,   declinationDeg:  -4.0 },
  { name: 'Los Angeles',  lat: 34.0522,  lng: -118.2437, standardOffset: -8,  dstRule: DstRule.US,   declinationDeg:  12.0 },
  { name: 'Toronto',      lat: 43.6532,  lng: -79.3832, standardOffset: -5,   dstRule: DstRule.US,   declinationDeg: -11.0 },
  { name: 'Vancouver',    lat: 49.2827,  lng: -123.1207, standardOffset: -8,  dstRule: DstRule.US,   declinationDeg:  15.0 },
  { name: 'Mexico City',  lat: 19.4326,  lng: -99.1332, standardOffset: -6,   dstRule: DstRule.NONE, declinationDeg:   5.0 },
  { name: 'São Paulo',    lat: -23.5505, lng: -46.6333, standardOffset: -3,   dstRule: DstRule.NONE, declinationDeg: -21.0 },

  { name: 'Sydney',       lat: -33.8688, lng: 151.2093, standardOffset: 10,   dstRule: DstRule.AU,   declinationDeg:  12.0 },
  { name: 'Melbourne',    lat: -37.8136, lng: 144.9631, standardOffset: 10,   dstRule: DstRule.AU,   declinationDeg:  11.0 },
  { name: 'Auckland',     lat: -36.8485, lng: 174.7633, standardOffset: 12,   dstRule: DstRule.AU,   declinationDeg:  19.0 }
];

export class OfflineCityLookup {

  /**
   * Return the nearest known city's display name, if within range.
   */
  static nearest(latitude: number, longitude: number): string | null {
    const city = OfflineCityLookup.nearestCity(latitude, longitude);
    return city !== null ? city.name.toUpperCase() : null;
  }

  /**
   * Return the nearest known city record (including timezone data),
   * or null if nothing is within MAX_MATCH_KM.
   */
  static nearestCity(latitude: number, longitude: number): City | null {
    let best: City | null = null;
    let bestDist = Number.MAX_VALUE;

    for (const city of CITIES) {
      const d = OfflineCityLookup.haversineKm(latitude, longitude, city.lat, city.lng);
      if (d < bestDist) {
        bestDist = d;
        best = city;
      }
    }

    if (best !== null && bestDist <= MAX_MATCH_KM) {
      return best;
    }
    return null;
  }

  /**
   * Magnetic declination (degrees East) for the nearest known city.
   * Falls back to 0 when the coordinates are outside the table —
   * meaning the sensor heading is used as-is.
   */
  static declinationFor(latitude: number, longitude: number): number {
    const city = OfflineCityLookup.nearestCity(latitude, longitude);
    return city !== null ? city.declinationDeg : 0;
  }

  private static haversineKm(
    lat1: number, lng1: number,
    lat2: number, lng2: number
  ): number {
    const R = 6371;
    const toRad = Math.PI / 180;
    const dLat = (lat2 - lat1) * toRad;
    const dLng = (lng2 - lng1) * toRad;
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(lat1 * toRad) * Math.cos(lat2 * toRad) *
          Math.sin(dLng / 2) * Math.sin(dLng / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }
}