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
}

const MAX_MATCH_KM = 100;

const CITIES: City[] = [
  // Pakistan (PKT, UTC+5, no DST)
  { name: 'Karachi',      lat: 24.8607,  lng: 67.0011,  standardOffset: 5,    dstRule: DstRule.NONE },
  { name: 'Lahore',       lat: 31.5204,  lng: 74.3587,  standardOffset: 5,    dstRule: DstRule.NONE },
  { name: 'Islamabad',    lat: 33.6844,  lng: 73.0479,  standardOffset: 5,    dstRule: DstRule.NONE },
  { name: 'Rawalpindi',   lat: 33.5651,  lng: 73.0169,  standardOffset: 5,    dstRule: DstRule.NONE },
  { name: 'Faisalabad',   lat: 31.4180,  lng: 73.0790,  standardOffset: 5,    dstRule: DstRule.NONE },
  { name: 'Multan',       lat: 30.1575,  lng: 71.5249,  standardOffset: 5,    dstRule: DstRule.NONE },
  { name: 'Peshawar',     lat: 34.0151,  lng: 71.5249,  standardOffset: 5,    dstRule: DstRule.NONE },
  { name: 'Quetta',       lat: 30.1798,  lng: 66.9750,  standardOffset: 5,    dstRule: DstRule.NONE },

  // India (IST, UTC+5:30, no DST)
  { name: 'Delhi',        lat: 28.6139,  lng: 77.2090,  standardOffset: 5.5,  dstRule: DstRule.NONE },
  { name: 'Mumbai',       lat: 19.0760,  lng: 72.8777,  standardOffset: 5.5,  dstRule: DstRule.NONE },
  { name: 'Bangalore',    lat: 12.9716,  lng: 77.5946,  standardOffset: 5.5,  dstRule: DstRule.NONE },
  { name: 'Hyderabad',    lat: 17.3850,  lng: 78.4867,  standardOffset: 5.5,  dstRule: DstRule.NONE },
  { name: 'Chennai',      lat: 13.0827,  lng: 80.2707,  standardOffset: 5.5,  dstRule: DstRule.NONE },
  { name: 'Kolkata',      lat: 22.5726,  lng: 88.3639,  standardOffset: 5.5,  dstRule: DstRule.NONE },

  // Middle East
  { name: 'Makkah',       lat: 21.4225,  lng: 39.8262,  standardOffset: 3,    dstRule: DstRule.NONE },
  { name: 'Madinah',      lat: 24.5247,  lng: 39.5692,  standardOffset: 3,    dstRule: DstRule.NONE },
  { name: 'Riyadh',       lat: 24.7136,  lng: 46.6753,  standardOffset: 3,    dstRule: DstRule.NONE },
  { name: 'Jeddah',       lat: 21.4858,  lng: 39.1925,  standardOffset: 3,    dstRule: DstRule.NONE },
  { name: 'Dubai',        lat: 25.2048,  lng: 55.2708,  standardOffset: 4,    dstRule: DstRule.NONE },
  { name: 'Abu Dhabi',    lat: 24.4539,  lng: 54.3773,  standardOffset: 4,    dstRule: DstRule.NONE },
  { name: 'Doha',         lat: 25.2854,  lng: 51.5310,  standardOffset: 3,    dstRule: DstRule.NONE },
  { name: 'Kuwait City',  lat: 29.3759,  lng: 47.9774,  standardOffset: 3,    dstRule: DstRule.NONE },
  { name: 'Muscat',       lat: 23.5880,  lng: 58.3829,  standardOffset: 4,    dstRule: DstRule.NONE },
  { name: 'Tehran',       lat: 35.6892,  lng: 51.3890,  standardOffset: 3.5,  dstRule: DstRule.NONE },
  { name: 'Istanbul',     lat: 41.0082,  lng: 28.9784,  standardOffset: 3,    dstRule: DstRule.NONE },
  { name: 'Baghdad',      lat: 33.3152,  lng: 44.3661,  standardOffset: 3,    dstRule: DstRule.NONE },
  { name: 'Amman',        lat: 31.9454,  lng: 35.9284,  standardOffset: 3,    dstRule: DstRule.NONE },
  { name: 'Beirut',       lat: 33.8938,  lng: 35.5018,  standardOffset: 2,    dstRule: DstRule.EU },
  { name: 'Cairo',        lat: 30.0444,  lng: 31.2357,  standardOffset: 2,    dstRule: DstRule.EU },

  // Asia
  { name: 'Shanghai',     lat: 31.2304,  lng: 121.4737, standardOffset: 8,    dstRule: DstRule.NONE },
  { name: 'Beijing',      lat: 39.9042,  lng: 116.4074, standardOffset: 8,    dstRule: DstRule.NONE },
  { name: 'Guangzhou',    lat: 23.1291,  lng: 113.2644, standardOffset: 8,    dstRule: DstRule.NONE },
  { name: 'Shenzhen',     lat: 22.5431,  lng: 114.0579, standardOffset: 8,    dstRule: DstRule.NONE },
  { name: 'Hong Kong',    lat: 22.3193,  lng: 114.1694, standardOffset: 8,    dstRule: DstRule.NONE },
  { name: 'Tokyo',        lat: 35.6762,  lng: 139.6503, standardOffset: 9,    dstRule: DstRule.NONE },
  { name: 'Seoul',        lat: 37.5665,  lng: 126.9780, standardOffset: 9,    dstRule: DstRule.NONE },
  { name: 'Singapore',    lat: 1.3521,   lng: 103.8198, standardOffset: 8,    dstRule: DstRule.NONE },
  { name: 'Kuala Lumpur', lat: 3.1390,   lng: 101.6869, standardOffset: 8,    dstRule: DstRule.NONE },
  { name: 'Jakarta',      lat: -6.2088,  lng: 106.8456, standardOffset: 7,    dstRule: DstRule.NONE },
  { name: 'Dhaka',        lat: 23.8103,  lng: 90.4125,  standardOffset: 6,    dstRule: DstRule.NONE },
  { name: 'Kabul',        lat: 34.5553,  lng: 69.2075,  standardOffset: 4.5,  dstRule: DstRule.NONE },

  // Europe
  { name: 'London',       lat: 51.5074,  lng: -0.1278,  standardOffset: 0,    dstRule: DstRule.EU },
  { name: 'Paris',        lat: 48.8566,  lng: 2.3522,   standardOffset: 1,    dstRule: DstRule.EU },
  { name: 'Berlin',       lat: 52.5200,  lng: 13.4050,  standardOffset: 1,    dstRule: DstRule.EU },
  { name: 'Madrid',       lat: 40.4168,  lng: -3.7038,  standardOffset: 1,    dstRule: DstRule.EU },
  { name: 'Rome',         lat: 41.9028,  lng: 12.4964,  standardOffset: 1,    dstRule: DstRule.EU },
  { name: 'Amsterdam',    lat: 52.3676,  lng: 4.9041,   standardOffset: 1,    dstRule: DstRule.EU },
  { name: 'Moscow',       lat: 55.7558,  lng: 37.6173,  standardOffset: 3,    dstRule: DstRule.NONE },

  // Africa
  { name: 'Lagos',        lat: 6.5244,   lng: 3.3792,   standardOffset: 1,    dstRule: DstRule.NONE },
  { name: 'Nairobi',      lat: -1.2921,  lng: 36.8219,  standardOffset: 3,    dstRule: DstRule.NONE },
  { name: 'Cape Town',    lat: -33.9249, lng: 18.4241,  standardOffset: 2,    dstRule: DstRule.NONE },
  { name: 'Casablanca',   lat: 33.5731,  lng: -7.5898,  standardOffset: 1,    dstRule: DstRule.NONE },

  // Americas
  { name: 'New York',     lat: 40.7128,  lng: -74.0060, standardOffset: -5,   dstRule: DstRule.US },
  { name: 'Chicago',      lat: 41.8781,  lng: -87.6298, standardOffset: -6,   dstRule: DstRule.US },
  { name: 'Los Angeles',  lat: 34.0522,  lng: -118.2437, standardOffset: -8,  dstRule: DstRule.US },
  { name: 'Toronto',      lat: 43.6532,  lng: -79.3832, standardOffset: -5,   dstRule: DstRule.US },
  { name: 'Vancouver',    lat: 49.2827,  lng: -123.1207, standardOffset: -8,  dstRule: DstRule.US },
  { name: 'Mexico City',  lat: 19.4326,  lng: -99.1332, standardOffset: -6,   dstRule: DstRule.NONE },
  { name: 'São Paulo',    lat: -23.5505, lng: -46.6333, standardOffset: -3,   dstRule: DstRule.NONE },

  // Oceania
  { name: 'Sydney',       lat: -33.8688, lng: 151.2093, standardOffset: 10,   dstRule: DstRule.AU },
  { name: 'Melbourne',    lat: -37.8136, lng: 144.9631, standardOffset: 10,   dstRule: DstRule.AU },
  { name: 'Auckland',     lat: -36.8485, lng: 174.7633, standardOffset: 12,   dstRule: DstRule.AU }
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