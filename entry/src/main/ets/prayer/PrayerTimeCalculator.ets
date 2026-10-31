// entry/src/main/ets/prayer/PrayerTimeCalculator.ets

import { TimezoneResolver } from '../utils/TimezoneResolver';
import { HijriEngineResolver } from '../hijricalendar/HijriEngineResolver';
import { STORAGE_KEY_HIJRI_OFFSET } from '../common/StorageKeys';
import {
  AdvancedCalcSettings,
  DEFAULT_ADVANCED_CALC,
  MidnightMethod,
  PolarResolution,
  RoundingMethod,
  Shafaq
} from '../models/AdvancedCalcModels';

// ---- Enums ----

export enum CalculationMethod {
  KARACHI = 'Karachi',
  JAFARI = 'Jafari',
  ISNA = 'ISNA',
  MWL = 'MWL',
  UMM_AL_QURA = 'UmmAlQura',
  EGYPTIAN = 'Egyptian',
  SUNNI_IRAQ = 'SunniIraq',
  QATAR = 'Qatar',
  SINGAPORE = 'Singapore',
  FRANCE = 'France',
  TURKEY = 'Turkey',
  RUSSIA = 'Russia',
  UAE = 'UAE',
  // ---- Adhan-parity additions ----
  MOONSIGHTING_COMMITTEE = 'MoonsightingCommittee',
  DUBAI = 'Dubai',
  KUWAIT = 'Kuwait',
  FRANCE_15 = 'France15',
  FRANCE_18 = 'France18',
  TURKEY_EUROPE = 'TurkeyEurope',
  TEHRAN = 'Tehran',
  INDONESIA = 'Indonesia',
  ALGERIA = 'Algeria',
  BRUNEI = 'Brunei'
}

export enum AsrShadowRule {
  STANDARD = 1,
  HANAFI = 2
}

export enum HighLatitudeRule {
  NONE = 'None',
  MIDDLE_OF_NIGHT = 'MiddleOfNight',
  ONE_SEVENTH = 'OneSeventh',
  ANGLE_BASED = 'AngleBased',
  PROPORTIONAL_DEPRESSION = 'ProportionalDepression'
}

export interface HighLatRuleOption {
  value: HighLatitudeRule;
  label: string;
}

// ---- Interfaces ----

export interface DailyPrayerTimes {
  fajr: string;
  dhuhr: string;
  asr: string;
  maghrib: string;
  isha: string;
  sunrise: string;
  sunset: string;
  imsak: string;
  firstThird: string;
  midnight: string;
  lastThird: string;
  date: Date;
  methodUsed: string;
  asrRuleUsed: string;
}

interface SolarPosition {
  declination: number;
  equationOfTime: number;
}

export interface CalculationParameters {
  fajrAngle: number;
  ishaAngle: number;
  ishaInterval: number;
  methodName: string;
}

export interface MethodOption {
  value: CalculationMethod;
  label: string;
}

// ---- Astronomical Constants ----

class Astronomy {
  static readonly J2000 = 2451545.0;
  static readonly OBLIQUITY_2000 = 23.439291;
  static readonly MEAN_ANOMALY_2000 = 357.5291;
  static readonly MEAN_LONGITUDE_2000 = 280.4665;
  static readonly MEAN_LONGITUDE_RATE = 360 / 365.2422;
  static readonly MEAN_ANOMALY_RATE = 360 / 365.2596;
}

// ---- Main Calculator ----

export class PrayerTimeCalculator {

  // ============================================================
  // PREDEFINED METHODS (Conventions)
  // ============================================================

  static readonly KARACHI: CalculationParameters = {
    fajrAngle: 18,
    ishaAngle: 18,
    ishaInterval: 0,
    methodName: 'University of Islamic Sciences, Karachi'
  };
  static readonly JAFARI: CalculationParameters = {
    fajrAngle: 16,
    ishaAngle: 14,
    ishaInterval: 0,
    methodName: 'Shia Ithna Ashari, Leva Institute, Qum'
  };
  static readonly ISNA: CalculationParameters = {
    fajrAngle: 15,
    ishaAngle: 15,
    ishaInterval: 0,
    methodName: 'Islamic Society of North America'
  };
  static readonly MWL: CalculationParameters = {
    fajrAngle: 18,
    ishaAngle: 17,
    ishaInterval: 0,
    methodName: 'Muslim World League'
  };
  static readonly UMM_AL_QURA: CalculationParameters = {
    fajrAngle: 18.5,
    ishaAngle: 0,
    ishaInterval: 90,
    methodName: 'Umm al-Qura University, Makkah'
  };
  static readonly EGYPTIAN: CalculationParameters = {
    fajrAngle: 19.5,
    ishaAngle: 17.5,
    ishaInterval: 0,
    methodName: 'Egyptian General Authority of Survey'
  };
  static readonly SUNNI_IRAQ: CalculationParameters = {
    fajrAngle: 18,
    ishaAngle: 18,
    ishaInterval: 0,
    methodName: 'Sunni Endowment, Iraq'
  };
  static readonly QATAR: CalculationParameters = {
    fajrAngle: 18,
    ishaAngle: 0,
    ishaInterval: 90,
    methodName: 'Qatar Awqaf'
  };
  static readonly SINGAPORE: CalculationParameters = {
    fajrAngle: 20,
    ishaAngle: 18,
    ishaInterval: 0,
    methodName: 'Majlis Ugama Islam Singapura'
  };
  static readonly FRANCE: CalculationParameters = {
    fajrAngle: 12,
    ishaAngle: 12,
    ishaInterval: 0,
    methodName: 'Union des Organisations Islamiques de France'
  };
  static readonly TURKEY: CalculationParameters = {
    fajrAngle: 18,
    ishaAngle: 17,
    ishaInterval: 0,
    methodName: 'Diyanet İşleri Başkanlığı, Turkey'
  };
  static readonly RUSSIA: CalculationParameters = {
    fajrAngle: 16,
    ishaAngle: 15,
    ishaInterval: 0,
    methodName: 'Spiritual Administration of Muslims of Russia'
  };
  static readonly UAE: CalculationParameters = {
    fajrAngle: 18.2,
    ishaAngle: 18.2,
    ishaInterval: 0,
    methodName: 'General Authority of Islamic Affairs & Endowments, UAE'
  };
  static readonly MOONSIGHTING_COMMITTEE: CalculationParameters = {
    fajrAngle: 18,
    ishaAngle: 18,
    ishaInterval: 0,
    methodName: 'Moonsighting Committee Worldwide'
  };
  static readonly DUBAI: CalculationParameters = {
    fajrAngle: 18.2,
    ishaAngle: 18.2,
    ishaInterval: 0,
    methodName: 'The Gulf Region (Dubai)'
  };
  static readonly KUWAIT: CalculationParameters = {
    fajrAngle: 18,
    ishaAngle: 17.5,
    ishaInterval: 0,
    methodName: 'Kuwait'
  };
  static readonly FRANCE_15: CalculationParameters = {
    fajrAngle: 15,
    ishaAngle: 15,
    ishaInterval: 0,
    methodName: 'France angle 15'
  };
  static readonly FRANCE_18: CalculationParameters = {
    fajrAngle: 18,
    ishaAngle: 18,
    ishaInterval: 0,
    methodName: 'France angle 18'
  };
  static readonly TURKEY_EUROPE: CalculationParameters = {
    fajrAngle: 18,
    ishaAngle: 17,
    ishaInterval: 0,
    methodName: 'Diyanet İşleri Başkanlığı, Europe'
  };
  static readonly TEHRAN: CalculationParameters = {
    fajrAngle: 17.7,
    ishaAngle: 14,
    ishaInterval: 0,
    methodName: 'Shia, Institute of Geophysics, University of Tehran, Iran'
  };
  static readonly INDONESIA: CalculationParameters = {
    fajrAngle: 20,
    ishaAngle: 18,
    ishaInterval: 0,
    methodName: 'Kementrian Agama Republik Indonesia (KEMENAG)'
  };
  static readonly ALGERIA: CalculationParameters = {
    fajrAngle: 18,
    ishaAngle: 17,
    ishaInterval: 0,
    methodName: 'Ministry of Religious Affairs and Wakfs, Algeria'
  };
  static readonly BRUNEI: CalculationParameters = {
    fajrAngle: 20,
    ishaAngle: 18,
    ishaInterval: 0,
    methodName: 'Kementrian Hal Ehwal Ugama (Brunei Darussalam)'
  };

  static getParameters(method: CalculationMethod): CalculationParameters {
    switch (method) {
      case CalculationMethod.KARACHI:
        return PrayerTimeCalculator.KARACHI;
      case CalculationMethod.JAFARI:
        return PrayerTimeCalculator.JAFARI;
      case CalculationMethod.ISNA:
        return PrayerTimeCalculator.ISNA;
      case CalculationMethod.MWL:
        return PrayerTimeCalculator.MWL;
      case CalculationMethod.UMM_AL_QURA:
        return PrayerTimeCalculator.UMM_AL_QURA;
      case CalculationMethod.EGYPTIAN:
        return PrayerTimeCalculator.EGYPTIAN;
      case CalculationMethod.SUNNI_IRAQ:
        return PrayerTimeCalculator.SUNNI_IRAQ;
      case CalculationMethod.QATAR:
        return PrayerTimeCalculator.QATAR;
      case CalculationMethod.SINGAPORE:
        return PrayerTimeCalculator.SINGAPORE;
      case CalculationMethod.FRANCE:
        return PrayerTimeCalculator.FRANCE;
      case CalculationMethod.TURKEY:
        return PrayerTimeCalculator.TURKEY;
      case CalculationMethod.RUSSIA:
        return PrayerTimeCalculator.RUSSIA;
      case CalculationMethod.UAE:
        return PrayerTimeCalculator.UAE;
      case CalculationMethod.MOONSIGHTING_COMMITTEE:
        return PrayerTimeCalculator.MOONSIGHTING_COMMITTEE;
      case CalculationMethod.DUBAI:
        return PrayerTimeCalculator.DUBAI;
      case CalculationMethod.KUWAIT:
        return PrayerTimeCalculator.KUWAIT;
      case CalculationMethod.FRANCE_15:
        return PrayerTimeCalculator.FRANCE_15;
      case CalculationMethod.FRANCE_18:
        return PrayerTimeCalculator.FRANCE_18;
      case CalculationMethod.TURKEY_EUROPE:
        return PrayerTimeCalculator.TURKEY_EUROPE;
      case CalculationMethod.TEHRAN:
        return PrayerTimeCalculator.TEHRAN;
      case CalculationMethod.INDONESIA:
        return PrayerTimeCalculator.INDONESIA;
      case CalculationMethod.ALGERIA:
        return PrayerTimeCalculator.ALGERIA;
      case CalculationMethod.BRUNEI:
        return PrayerTimeCalculator.BRUNEI;
      default:
        return PrayerTimeCalculator.KARACHI;
    }
  }

  static getAvailableMethods(): Array<MethodOption> {
    return [
      { value: CalculationMethod.MOONSIGHTING_COMMITTEE, label: 'Moonsighting Committee Worldwide' },
      { value: CalculationMethod.MWL, label: 'Muslim World League (18°/17°)' },
      { value: CalculationMethod.EGYPTIAN, label: 'Egyptian General Survey Authority (19.5°/17.5°)' },
      { value: CalculationMethod.KARACHI, label: 'University of Islamic Sciences, Karachi (18°/18°)' },
      { value: CalculationMethod.UMM_AL_QURA, label: 'Umm al-Qura University, Makkah (18.5° / 90 min)' },
      { value: CalculationMethod.ISNA, label: 'Islamic Society of North America (15°/15°)' },
      { value: CalculationMethod.DUBAI, label: 'The Gulf Region (Dubai) (18.2°/18.2°)' },
      { value: CalculationMethod.KUWAIT, label: 'Kuwait (18°/17.5°)' },
      { value: CalculationMethod.QATAR, label: 'Qatar (18° / 90 min)' },
      { value: CalculationMethod.SINGAPORE, label: 'Singapore (MUIS) (20°/18°)' },
      { value: CalculationMethod.FRANCE, label: 'Union Organization Islamic de France (12°/12°)' },
      { value: CalculationMethod.FRANCE_15, label: 'France angle 15 (15°/15°)' },
      { value: CalculationMethod.FRANCE_18, label: 'France angle 18 (18°/18°)' },
      { value: CalculationMethod.TURKEY, label: 'Diyanet İşleri Başkanlığı, Turkey (18°/17°)' },
      { value: CalculationMethod.TURKEY_EUROPE, label: 'Diyanet İşleri Başkanlığı, Europe (18°/17°)' },
      { value: CalculationMethod.RUSSIA, label: 'Spiritual Administration of Muslims of Russia (16°/15°)' },
      { value: CalculationMethod.JAFARI, label: 'Shia Ithna Ashari, Leva Institute, Qum, Iran (16°/14°)' },
      {
        value: CalculationMethod.TEHRAN,
        label: 'Shia, Institute of Geophysics, University of Tehran, Iran (17.7°/14°)'
      },
      { value: CalculationMethod.INDONESIA, label: 'Kementrian Agama Republik Indonesia (KEMENAG) (20°/18°)' },
      { value: CalculationMethod.ALGERIA, label: 'Ministry of Religious Affairs and Wakfs, Algeria (18°/17°)' },
      { value: CalculationMethod.BRUNEI, label: 'Kementrian Hal Ehwal Ugama (Brunei Darussalam) (20°/18°)' }
    ];
  }

  static getAvailableHighLatRules(): Array<HighLatRuleOption> {
    return [
      { value: HighLatitudeRule.NONE, label: 'None' },
      { value: HighLatitudeRule.MIDDLE_OF_NIGHT, label: 'Middle of Night' },
      { value: HighLatitudeRule.ONE_SEVENTH, label: 'One Seventh of Night' },
      { value: HighLatitudeRule.ANGLE_BASED, label: 'Angle Based' },
      { value: HighLatitudeRule.PROPORTIONAL_DEPRESSION, label: 'Proportional Depression' }
    ];
  }

  private static isAngleReachable(latitude: number, declinationDeg: number, altitudeDeg: number): boolean {
    const rad = Math.PI / 180;
    const cosHA = (Math.sin(altitudeDeg * rad) - Math.sin(latitude * rad) * Math.sin(declinationDeg * rad)) /
      (Math.cos(latitude * rad) * Math.cos(declinationDeg * rad));
    return cosHA >= -1 && cosHA <= 1;
  }

  private static applyHighLatFallback(base: Date, nightMs: number, angle: number, rule: HighLatitudeRule,
    goBackward: boolean): Date {
    let factor = 0;
    if (rule === HighLatitudeRule.MIDDLE_OF_NIGHT) {
      factor = 1 / 2;
    } else if (rule ===
      HighLatitudeRule.ONE_SEVENTH) {
      factor = 1 / 7;
    } else if (rule === HighLatitudeRule.ANGLE_BASED ||
      rule === HighLatitudeRule.PROPORTIONAL_DEPRESSION) {
      factor = angle / 60;
    }

    const portionMs = nightMs * factor;
    return new Date(base.getTime() + (goBackward ? -portionMs : portionMs));
  }

  // ============================================================
  // POLAR RESOLUTION
  // ============================================================

  private static calculateAtAqrabBaladLatitude(
    date: Date, latitude: number, longitude: number, targetAltitudeDeg: number,
    isAfternoon: boolean, declinationDeg: number, equationOfTimeMinutes: number
  ): number | null {
    if (!PrayerTimeCalculator.isAngleReachable(0, declinationDeg, targetAltitudeDeg)) {
      return null;
    }

    const equatorward = latitude >= 0 ? 1 : -1;
    const STEP = 0.5;
    for (let refLat = latitude - equatorward * STEP; Math.abs(refLat) > 0.001; refLat -= equatorward * STEP) {
      if (PrayerTimeCalculator.isAngleReachable(refLat, declinationDeg, targetAltitudeDeg)) {
        return PrayerTimeCalculator.calculateTimeForAltitude(
          date, refLat, longitude, declinationDeg, equationOfTimeMinutes, targetAltitudeDeg, isAfternoon
        );
      }
    }
    return null;
  }

  private static calculateAtAqrabYaum(
    date: Date, latitude: number, longitude: number, targetAltitudeDeg: number, isAfternoon: boolean
  ): number | null {
    const MS_PER_DAY = 86400000;
    const MAX_DAYS = 183;
    for (let offset = 1; offset <= MAX_DAYS; offset++) {
      for (const direction of [1, -1]) {
        const probe = new Date(date.getTime() + direction * offset * MS_PER_DAY);
        const solar = PrayerTimeCalculator.getSolarPosition(probe);
        if (PrayerTimeCalculator.isAngleReachable(latitude, solar.declination, targetAltitudeDeg)) {
          return PrayerTimeCalculator.calculateTimeForAltitude(
            probe, latitude, longitude, solar.declination, solar.equationOfTime, targetAltitudeDeg, isAfternoon
          );
        }
      }
    }
    return null;
  }

  private static calculatePolarFallback(
    date: Date, latitude: number, longitude: number, targetAltitudeDeg: number,
    isAfternoon: boolean, declinationDeg: number, equationOfTimeMinutes: number, polarResolution: PolarResolution
  ): number | null {
    if (polarResolution === PolarResolution.AQRAB_BALAD) {
      return PrayerTimeCalculator.calculateAtAqrabBaladLatitude(date, latitude, longitude, targetAltitudeDeg,
        isAfternoon, declinationDeg, equationOfTimeMinutes);
    }
    if (polarResolution === PolarResolution.AQRAB_YAUM) {
      return PrayerTimeCalculator.calculateAtAqrabYaum(date, latitude, longitude, targetAltitudeDeg, isAfternoon);
    }
    return null;
  }

  // ============================================================
  // MAIN CALCULATION
  // ============================================================

  static calculate(
    date: Date,
    latitude: number,
    longitude: number,
    timezoneOffset: number,
    method: CalculationMethod,
    asrRule: AsrShadowRule = AsrShadowRule.STANDARD,
    highLatRule: HighLatitudeRule = HighLatitudeRule.NONE,
    advanced: AdvancedCalcSettings = DEFAULT_ADVANCED_CALC
  ): DailyPrayerTimes {
    const params = PrayerTimeCalculator.getParameters(method);

    // --- Diyanet (Turkey) Temkin Offsets & Constraints ---
    let effectiveAsrRule = asrRule;
    let sunriseAdjust = 0;
    let dhuhrAdjust = 0;
    let asrAdjust = 0;
    let maghribAdjust = 0;

    if (method === CalculationMethod.TURKEY || method === CalculationMethod.TURKEY_EUROPE) {
      effectiveAsrRule = AsrShadowRule.STANDARD;
      sunriseAdjust = -7;
      dhuhrAdjust = 5;
      asrAdjust = 4;
      maghribAdjust = 7;
    }

    // --- Jafari / Tehran Maghrib Rule ---
    const isJafari = (method === CalculationMethod.JAFARI || method === CalculationMethod.TEHRAN);

    // --- Umm al-Qura Ramadan Rule ---
    let effectiveIshaInterval = params.ishaInterval;
    if (method === CalculationMethod.UMM_AL_QURA) {
      // The user's Hijri offset shifts their entire Hijri calendar.
      // Apply it here so that the "Ramadan" window during which Isha
      // is extended matches the month the user actually sees on the
      // Home header and the calendar page. Without this, a user who
      // has offset +2 would see Isha at 90 min for 2–3 days after
      // their own 1 Ramadan, until Umm al-Qura catches up.
      let offsetDays = 0;
      try {
        const stored = AppStorage.get<number>(STORAGE_KEY_HIJRI_OFFSET);
        if (stored !== undefined && !isNaN(stored)) {
          offsetDays = stored;
        }
      } catch (e) {
        // AppStorage unavailable (e.g. unit tests) — default to zero.
      }

      const shifted = new Date(date);
      shifted.setDate(shifted.getDate() + offsetDays);

      const hijri = HijriEngineResolver.current().toHijri(shifted);
      if (hijri !== null && hijri.month === 9) {
        effectiveIshaInterval = 120; // 90 + 30 min
      }
    }

    const solarPos = PrayerTimeCalculator.getSolarPosition(date);
    const dec = solarPos.declination;
    const eot = solarPos.equationOfTime;

    const dhuhrUTC = 12 - (longitude / 15) - (eot / 60);
    const dhuhr = PrayerTimeCalculator.dateFromUTCHours(date, dhuhrUTC + timezoneOffset);

    const SUN_HORIZON_ALTITUDE = -0.833;
    const sunriseUTC = PrayerTimeCalculator.calculateTimeForAltitude(
      date, latitude, longitude, dec, eot, SUN_HORIZON_ALTITUDE, false
    );
    const sunrise = PrayerTimeCalculator.dateFromUTCHours(date, sunriseUTC + timezoneOffset);

    const sunsetUTC = PrayerTimeCalculator.calculateTimeForAltitude(
      date, latitude, longitude, dec, eot, SUN_HORIZON_ALTITUDE, true
    );
    const sunset = PrayerTimeCalculator.dateFromUTCHours(date, sunsetUTC + timezoneOffset);

    let effectiveIshaAngle = params.ishaAngle;
    if (method === CalculationMethod.MOONSIGHTING_COMMITTEE) {
      if (advanced.shafaq === Shafaq.AHMER) {
        effectiveIshaAngle -= 1;
      } else if (advanced.shafaq ===
        Shafaq.ABYAD) {
        effectiveIshaAngle += 1;
      }
    }

    const fajrReachable = PrayerTimeCalculator.isAngleReachable(latitude, dec, -params.fajrAngle);
    const ishaReachable = effectiveIshaInterval === 0
      ? PrayerTimeCalculator.isAngleReachable(latitude, dec, -effectiveIshaAngle)
      : false;

    // Tomorrow's solar position
    const tomorrow = new Date(date);
    tomorrow.setDate(tomorrow.getDate() + 1);
    const tomorrowSolarPos = PrayerTimeCalculator.getSolarPosition(tomorrow);
    const tomorrowSunriseUTC = PrayerTimeCalculator.calculateTimeForAltitude(
      tomorrow, latitude, longitude, tomorrowSolarPos.declination, tomorrowSolarPos.equationOfTime,
      SUN_HORIZON_ALTITUDE, false
    );
    const tomorrowSunrise = PrayerTimeCalculator.dateFromUTCHours(tomorrow, tomorrowSunriseUTC + timezoneOffset);

    // Night length is from today's standard sunset to tomorrow's standard sunrise
    const nightMs = tomorrowSunrise.getTime() - sunset.getTime();

    let tomorrowFajr: Date;
    if (fajrReachable) {
      const tomorrowFajrUTC = PrayerTimeCalculator.calculateTimeForAltitude(
        tomorrow, latitude, longitude, tomorrowSolarPos.declination, tomorrowSolarPos.equationOfTime, -params.fajrAngle,
        false
      );
      tomorrowFajr = PrayerTimeCalculator.dateFromUTCHours(tomorrow, tomorrowFajrUTC + timezoneOffset);
    } else {
      tomorrowFajr =
        PrayerTimeCalculator.applyHighLatFallback(tomorrowSunrise, nightMs, params.fajrAngle, highLatRule, true);
    }

    // ---- Fajr ----
    let fajr: Date;
    const fajrPolarUTC = fajrReachable ? null : PrayerTimeCalculator.calculatePolarFallback(
      date, latitude, longitude, -params.fajrAngle, false, dec, eot, advanced.polarResolution
    );

    if (fajrPolarUTC !== null) {
      fajr = PrayerTimeCalculator.dateFromUTCHours(date, fajrPolarUTC + timezoneOffset);
    } else if (fajrReachable || highLatRule === HighLatitudeRule.NONE) {
      const fajrUTC =
        PrayerTimeCalculator.calculateTimeForAltitude(date, latitude, longitude, dec, eot, -params.fajrAngle, false);
      fajr = PrayerTimeCalculator.dateFromUTCHours(date, fajrUTC + timezoneOffset);
    } else {
      fajr = PrayerTimeCalculator.applyHighLatFallback(sunrise, nightMs, params.fajrAngle, highLatRule, true);
    }

    // ---- Asr ----
    //
    // Unlike Fajr and Isha, Asr's target altitude is derived from
    // the shadow rule and the day's declination, so its reachability
    // varies with latitude and season. When the sun never climbs to
    // the Asr altitude (extreme latitudes in winter), the raw
    // calculateTimeForAltitude() clamps cosHA to ±1 and returns a
    // meaningless time near sunrise or noon. Guard the same way Fajr
    // and Isha do.
    const asrAltitude = PrayerTimeCalculator.calculateAsrAltitude(latitude, dec, effectiveAsrRule);
    const asrReachable = PrayerTimeCalculator.isAngleReachable(latitude, dec, asrAltitude);

    let asr: Date;
    if (asrReachable) {
      const asrUTC = PrayerTimeCalculator.calculateTimeForAltitude(
        date, latitude, longitude, dec, eot, asrAltitude, true
      );
      asr = PrayerTimeCalculator.dateFromUTCHours(date, asrUTC + timezoneOffset);
    } else {
      // 1. Preferred fallback — use the user's polar resolution
      //    (Aqrab al-Balad or Aqrab al-Yaum) to find a reference
      //    latitude/day where the Asr altitude is reachable.
      const asrPolarUTC = PrayerTimeCalculator.calculatePolarFallback(
        date, latitude, longitude, asrAltitude, true,
        dec, eot, advanced.polarResolution
      );

      if (asrPolarUTC !== null) {
        asr = PrayerTimeCalculator.dateFromUTCHours(
          date, asrPolarUTC + timezoneOffset
        );
      } else {
        // 2. Last resort — place Asr at two-thirds of the
        //    Dhuhr → sunset interval. This preserves the correct
        //    ordering (Dhuhr < Asr < Maghrib) at every latitude
        //    without requiring a "night" quantity for the
        //    afternoon prayer.
        const dhuhrMs: number = dhuhr.getTime();
        const sunsetMs: number = sunset.getTime();
        asr = new Date(dhuhrMs + (sunsetMs - dhuhrMs) * (2 / 3));
      }
    }

    // ---- Maghrib ----
    let maghrib: Date;
    const maghribReachable = PrayerTimeCalculator.isAngleReachable(latitude, dec, -4.0);
    if (isJafari) {
      if (maghribReachable) {
        const maghribUTC =
          PrayerTimeCalculator.calculateTimeForAltitude(date, latitude, longitude, dec, eot, -4.0, true);
        maghrib = PrayerTimeCalculator.dateFromUTCHours(date, maghribUTC + timezoneOffset);
      } else {
        maghrib = PrayerTimeCalculator.applyHighLatFallback(sunset, nightMs, 4.0, highLatRule, false);
      }
    } else {
      maghrib = new Date(sunset);
    }

    // Apply Diyanet Temkin offsets to sunset-side timings FIRST so
    // that any interval-based Isha (Umm al-Qura, Qatar, custom)
    // measures from the *adjusted* maghrib. Ordering matters here:
    // a Turkey-style temkin adds `maghribAdjust` minutes to
    // maghrib, and Isha should track that shift if the user has
    // additionally chosen an interval-based method.
    sunrise.setMinutes(sunrise.getMinutes() + sunriseAdjust);
    dhuhr.setMinutes(dhuhr.getMinutes() + dhuhrAdjust);
    asr.setMinutes(asr.getMinutes() + asrAdjust);
    maghrib.setMinutes(maghrib.getMinutes() + maghribAdjust);

    // ---- Isha ----
    // Now maghrib already carries any temkin adjustment, so
    // maghrib + interval produces the correct Isha for
    // interval-based methods.
    let isha: Date;
    if (effectiveIshaInterval > 0) {
      isha = new Date(maghrib.getTime() + effectiveIshaInterval * 60 * 1000);
    } else {
      const ishaPolarUTC = ishaReachable ? null : PrayerTimeCalculator.calculatePolarFallback(
        date, latitude, longitude, -effectiveIshaAngle, true, dec, eot, advanced.polarResolution
      );

      if (ishaPolarUTC !== null) {
        isha = PrayerTimeCalculator.dateFromUTCHours(date, ishaPolarUTC + timezoneOffset);
      } else if (ishaReachable || highLatRule === HighLatitudeRule.NONE) {
        const ishaUTC =
          PrayerTimeCalculator.calculateTimeForAltitude(date, latitude, longitude, dec, eot, -effectiveIshaAngle, true);
        isha = PrayerTimeCalculator.dateFromUTCHours(date, ishaUTC + timezoneOffset);
      } else {
        isha = PrayerTimeCalculator.applyHighLatFallback(maghrib, nightMs, effectiveIshaAngle, highLatRule, false);
      }
    }



    // ---- Imsak (Fajr − 10 min) ----
    const imsak = new Date(fajr);
    imsak.setMinutes(imsak.getMinutes() - 10);

    // ---- Night divisions ----
    const isJafariMidnight = (advanced.midnight === MidnightMethod.JAFARI || isJafari);
    const nightEnd: Date = isJafariMidnight ? tomorrowFajr : tomorrowSunrise;

    const maghribMin = maghrib.getHours() * 60 + maghrib.getMinutes();
    let nightEndMin = nightEnd.getHours() * 60 + nightEnd.getMinutes();
    if (nightEndMin < maghribMin) {
      nightEndMin += 24 * 60;
    }

    const nightDuration = nightEndMin - maghribMin;
    const firstThirdMin = Math.round(maghribMin + nightDuration / 3);
    const midnightMin = Math.round(maghribMin + nightDuration / 2);
    const lastThirdMin = Math.round(maghribMin + (2 * nightDuration) / 3);

    const firstThird = PrayerTimeCalculator.minutesToDate(date, firstThirdMin);
    const midnight = PrayerTimeCalculator.minutesToDate(date, midnightMin);
    const lastThird = PrayerTimeCalculator.minutesToDate(date, lastThirdMin);

    // ---- Rounding ----
    const roundFn = PrayerTimeCalculator.rounderFor(advanced.rounding);

    return {
      fajr: roundFn(fajr),
      dhuhr: roundFn(dhuhr),
      asr: roundFn(asr),
      maghrib: roundFn(maghrib),
      isha: roundFn(isha),
      sunrise: roundFn(sunrise),
      sunset: roundFn(sunset),
      imsak: roundFn(imsak),
      firstThird: roundFn(firstThird),
      midnight: roundFn(midnight),
      lastThird: roundFn(lastThird),
      date: new Date(date),
      methodUsed: params.methodName,
      asrRuleUsed: effectiveAsrRule === AsrShadowRule.STANDARD ? 'Standard' : 'Hanafi'
    };
  }

  static calculateWithDeviceTimezone(
    date: Date, latitude: number, longitude: number, method: CalculationMethod,
    asrRule: AsrShadowRule = AsrShadowRule.STANDARD, highLatRule: HighLatitudeRule = HighLatitudeRule.NONE,
    advanced: AdvancedCalcSettings = DEFAULT_ADVANCED_CALC
  ): DailyPrayerTimes {
    const effectiveOffset = TimezoneResolver.effectiveOffsetForLocation(latitude, longitude, date);
    return PrayerTimeCalculator.calculate(date, latitude, longitude, effectiveOffset, method, asrRule, highLatRule,
      advanced);
  }

  // ============================================================
  // HELPERS
  // ============================================================

  private static rounderFor(method: RoundingMethod): (d: Date) => string {
    if (method === RoundingMethod.UP) {
      return PrayerTimeCalculator.formatTimeUp;
    }
    if (method === RoundingMethod.NONE) {
      return PrayerTimeCalculator.formatTimeExact;
    }
    return PrayerTimeCalculator.formatTime;
  }

  private static formatTime(date: Date): string {
    const rounded = new Date(date.getTime() + 30000);
    let hours = rounded.getHours();
    const minutes = rounded.getMinutes();
    const ampm = hours >= 12 ? 'PM' : 'AM';
    hours = hours % 12;
    if (hours === 0) {
      hours = 12;
    }
    return `${hours}:${minutes.toString().padStart(2, '0')} ${ampm}`;
  }

  /**
   * Round up to the next full minute.
   *
   * A prayer time that landed at 5:23:00 stays 5:23; one that landed
   * at 5:23:01 becomes 5:24. The prior implementation bumped the
   * minute then handed the bumped Date back to formatTime(), which
   * adds a further 30 s — over-rounding to 5:25 for the 5:23:30 case.
   * Using formatTimeExact() prevents the double bump.
   */
  private static formatTimeUp(date: Date): string {
    const d = new Date(date.getTime());
    if (d.getSeconds() > 0) {
      d.setMinutes(d.getMinutes() + 1);
      d.setSeconds(0, 0);
    }
    return PrayerTimeCalculator.formatTimeExact(d);
  }

  private static formatTimeExact(date: Date): string {
    let hours = date.getHours();
    const minutes = date.getMinutes();
    const ampm = hours >= 12 ? 'PM' : 'AM';
    hours = hours % 12;
    if (hours === 0) {
      hours = 12;
    }
    return `${hours}:${minutes.toString().padStart(2, '0')} ${ampm}`;
  }

  private static getSolarPosition(date: Date): SolarPosition {
    const jd = PrayerTimeCalculator.calculateJulianDay(date);
    const daysSinceJ2000 = jd - Astronomy.J2000;
    const meanAnomaly =
      PrayerTimeCalculator.normalizeAngle(Astronomy.MEAN_ANOMALY_2000 + Astronomy.MEAN_ANOMALY_RATE * daysSinceJ2000);
    const meanLongitude = PrayerTimeCalculator.normalizeAngle(
      Astronomy.MEAN_LONGITUDE_2000 + Astronomy.MEAN_LONGITUDE_RATE * daysSinceJ2000);
    const T = daysSinceJ2000 / 36525;
    const mRad = meanAnomaly * Math.PI / 180;
    const eqCenter =
      (1.914602 - 0.004817 * T - 0.000014 * T * T) * Math.sin(mRad) + (0.019993 - 0.000101 * T) * Math.sin(2 * mRad) +
        0.000289 * Math.sin(3 * mRad);
    const eclipticLongitude = meanLongitude + eqCenter;
    const obliquity = Astronomy.OBLIQUITY_2000 - 0.0130042 * T;
    const eclRad = eclipticLongitude * Math.PI / 180;
    const oblRad = obliquity * Math.PI / 180;
    const dec = Math.asin(Math.sin(eclRad) * Math.sin(oblRad)) * 180 / Math.PI;
    let ra = Math.atan2(Math.sin(eclRad) * Math.cos(oblRad), Math.cos(eclRad)) * 180 / Math.PI;
    let diffDeg = meanLongitude - ra;
    diffDeg = diffDeg - 360 * Math.round(diffDeg / 360);
    return { declination: dec, equationOfTime: 4 * diffDeg };
  }

  private static calculateJulianDay(date: Date): number {
    let year = date.getUTCFullYear();
    let month = date.getUTCMonth() + 1;
    const day =
      date.getUTCDate() + date.getUTCHours() / 24 + date.getUTCMinutes() / 1440 + date.getUTCSeconds() / 86400;
    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    const a = Math.floor(year / 100);
    const b = 2 - a + Math.floor(a / 4);
    return Math.floor(365.25 * (year + 4716)) + Math.floor(30.6001 * (month + 1)) + day + b - 1524.5;
  }

  private static normalizeAngle(degrees: number): number {
    let angle = degrees % 360;
    if (angle < 0) {
      angle += 360;
    }
    return angle;
  }

  private static calculateTimeForAltitude(
    date: Date, latitude: number, longitude: number, declinationDeg: number,
    equationOfTimeMinutes: number, targetAltitudeDeg: number, isAfternoon: boolean
  ): number {
    const rad = Math.PI / 180;
    const cosHA = (Math.sin(targetAltitudeDeg * rad) - Math.sin(latitude * rad) * Math.sin(declinationDeg * rad)) /
      (Math.cos(latitude * rad) * Math.cos(declinationDeg * rad));
    const clampedCosHA = Math.max(-1, Math.min(1, cosHA));
    let haDeg = Math.acos(clampedCosHA) * 180 / Math.PI;
    if (!isAfternoon) {
      haDeg = -haDeg;
    }
    const solarNoonUTC = 12 - (longitude / 15) - (equationOfTimeMinutes / 60);
    return solarNoonUTC + (haDeg / 15);
  }

  private static calculateAsrAltitude(latitude: number, declinationDeg: number, rule: AsrShadowRule): number {
    const rad = Math.PI / 180;
    const delta = Math.abs(latitude * rad - declinationDeg * rad);
    return Math.atan(1 / (Number(rule) + Math.tan(delta))) * 180 / Math.PI;
  }

  private static dateFromUTCHours(date: Date, utcHours: number): Date {
    // Compute total minutes first so a rounding that lands on a
    // 60-minute boundary is handled by integer division rather
    // than by relying on Date.setHours' implicit hour overflow.
    // utcHours is bounded by the caller to roughly [0, 24], so
    // totalMinutes is [0, 1440]; setHours(0, N, 0, 0) rolls over
    // into the next day when N >= 1440, which matches the old
    // behaviour for the "solar noon spills past midnight" case.
    const totalMinutes = Math.round(utcHours * 60);
    const result = new Date(date);
    result.setHours(0, totalMinutes, 0, 0);
    return result;
  }

  private static minutesToDate(baseDate: Date, totalMinutes: number): Date {
    const result = new Date(baseDate);
    result.setHours(0, 0, 0, 0);
    result.setMinutes(totalMinutes);
    return result;
  }
}