// entry/src/main/ets/utils/PrayerTimeCalculator.ets

import { TimezoneResolver } from '../utils/TimezoneResolver';
import {
  AdvancedCalcSettings,
  CustomAngles,
  DEFAULT_ADVANCED_CALC,
  DEFAULT_CUSTOM_ANGLES,
  MidnightMethod,
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
  BRUNEI = 'Brunei',
  CUSTOM = 'Custom'
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
  /** Diyanet Takdir — scales portions by the sun's depression. */
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

  /**
   * When > 0, Isha is computed as a fixed number of minutes after
   * Maghrib instead of using ishaAngle. Used by Umm al-Qura and Qatar
   * Awqaf, which define Isha as 90 minutes after sunset.
   */
  ishaInterval: number;
  methodName: string;
}

export interface MethodOption {
  value: CalculationMethod;
  label: string;
}

export interface AsrRuleOption {
  value: AsrShadowRule;
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
  static readonly DHUHR_SAFETY_MIN = 2;
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
  // ---- Adhan-parity additions ----

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

  // ============================================================
  // PUBLIC API
  // ============================================================

  static getParameters(
    method: CalculationMethod,
    custom?: CustomAngles
  ): CalculationParameters {
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
      case CalculationMethod.CUSTOM: {
        const c = custom ?? DEFAULT_CUSTOM_ANGLES;
        return {
          fajrAngle: c.fajr,
          ishaAngle: c.isha,
          ishaInterval: c.ishaInterval,
          methodName: 'Custom'
        };
      }
      default:
        return PrayerTimeCalculator.KARACHI;
    }
  }

  static getAvailableMethods(): Array<MethodOption> {
    return [
      { value: CalculationMethod.CUSTOM, label: 'Custom' },
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
      { value: HighLatitudeRule.PROPORTIONAL_DEPRESSION, label: 'Proportional Depression (Diyanet Takdir)' }
    ];
  }

  private static isAngleReachable(
    latitude: number, declinationDeg: number, altitudeDeg: number
  ): boolean {
    const rad = Math.PI / 180;
    const latRad = latitude * rad;
    const decRad = declinationDeg * rad;
    const altRad = altitudeDeg * rad;
    const numerator = Math.sin(altRad) - Math.sin(latRad) * Math.sin(decRad);
    const denominator = Math.cos(latRad) * Math.cos(decRad);
    const cosHA = numerator / denominator;
    return cosHA >= -1 && cosHA <= 1;
  }

  private static applyHighLatFallback(
    base: Date, nightMs: number, angle: number,
    rule: HighLatitudeRule, goBackward: boolean
  ): Date {
    let factor: number;
    switch (rule) {
      case HighLatitudeRule.MIDDLE_OF_NIGHT:
        factor = 1 / 2;
        break;
      case HighLatitudeRule.ONE_SEVENTH:
        factor = 1 / 7;
        break;
      case HighLatitudeRule.ANGLE_BASED:
        factor = angle / 60;
        break;
      case HighLatitudeRule.PROPORTIONAL_DEPRESSION:
        factor = angle / 60;
        break;
      default:
        factor = 0;
    }
    const portionMs = nightMs * factor;
    return new Date(base.getTime() + (goBackward ? -portionMs : portionMs));
  }

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
    const params = PrayerTimeCalculator.getParameters(
      method, advanced.customAngles
    );

    const solarPos = PrayerTimeCalculator.getSolarPosition(date);
    const dec = solarPos.declination;
    const eot = solarPos.equationOfTime;

    const dhuhrUTC = 12 - (longitude / 15) - (eot / 60);
    const dhuhr = PrayerTimeCalculator.dateFromUTCHours(date, dhuhrUTC + timezoneOffset);

    const SUN_HORIZON_ALTITUDE = -0.833;
    const sunriseUTC = PrayerTimeCalculator.calculateTimeForAltitude(
      date, latitude, longitude, dec, eot, SUN_HORIZON_ALTITUDE, false
    );
    const sunsetUTC = PrayerTimeCalculator.calculateTimeForAltitude(
      date, latitude, longitude, dec, eot, SUN_HORIZON_ALTITUDE, true
    );
    const sunrise = PrayerTimeCalculator.dateFromUTCHours(date, sunriseUTC + timezoneOffset);
    const sunset = PrayerTimeCalculator.dateFromUTCHours(date, sunsetUTC + timezoneOffset);

    // Shafaq affects the effective Isha angle only for the
    // Moonsighting Committee method.
    let effectiveIshaAngle = params.ishaAngle;
    if (method === CalculationMethod.MOONSIGHTING_COMMITTEE) {
      if (advanced.shafaq === Shafaq.AHMER) {
        effectiveIshaAngle = params.ishaAngle - 1;
      } else if (advanced.shafaq === Shafaq.ABYAD) {
        effectiveIshaAngle = params.ishaAngle + 1;
      }
    }

    const fajrReachable = PrayerTimeCalculator.isAngleReachable(
      latitude, dec, -params.fajrAngle
    );
    const ishaReachable = params.ishaInterval === 0
      ? PrayerTimeCalculator.isAngleReachable(latitude, dec, -effectiveIshaAngle)
      : false;

    const tomorrow = new Date(date);
    tomorrow.setDate(tomorrow.getDate() + 1);
    const tomorrowSolarPos = PrayerTimeCalculator.getSolarPosition(tomorrow);
    const tomorrowSunriseUTC = PrayerTimeCalculator.calculateTimeForAltitude(
      tomorrow, latitude, longitude,
      tomorrowSolarPos.declination, tomorrowSolarPos.equationOfTime,
      SUN_HORIZON_ALTITUDE, false
    );
    const tomorrowSunrise = PrayerTimeCalculator.dateFromUTCHours(
      tomorrow, tomorrowSunriseUTC + timezoneOffset
    );

    const tomorrowFajrUTC = PrayerTimeCalculator.calculateTimeForAltitude(
      tomorrow, latitude, longitude,
      tomorrowSolarPos.declination, tomorrowSolarPos.equationOfTime,
      -params.fajrAngle, false
    );
    const tomorrowFajr = PrayerTimeCalculator.dateFromUTCHours(
      tomorrow, tomorrowFajrUTC + timezoneOffset
    );

    // Night length for high-latitude fallback uses sunset → next sunrise.
    const nightMs = tomorrowSunrise.getTime() - sunset.getTime();

    // ---- Fajr ----
    let fajr: Date;
    if (fajrReachable || highLatRule === HighLatitudeRule.NONE) {
      const fajrUTC = PrayerTimeCalculator.calculateTimeForAltitude(
        date, latitude, longitude, dec, eot, -params.fajrAngle, false
      );
      fajr = PrayerTimeCalculator.dateFromUTCHours(date, fajrUTC + timezoneOffset);
    } else {
      fajr = PrayerTimeCalculator.applyHighLatFallback(
        sunrise, nightMs, params.fajrAngle, highLatRule, true
      );
    }

    // ---- Asr ----
    const asrAltitude = PrayerTimeCalculator.calculateAsrAltitude(
      latitude, dec, asrRule
    );
    const asrUTC = PrayerTimeCalculator.calculateTimeForAltitude(
      date, latitude, longitude, dec, eot, asrAltitude, true
    );
    const asr = PrayerTimeCalculator.dateFromUTCHours(date, asrUTC + timezoneOffset);

    // ---- Maghrib ----
    const maghrib = new Date(sunset);

    // ---- Isha ----
    let isha: Date;
    if (params.ishaInterval > 0) {
      isha = new Date(maghrib.getTime() + params.ishaInterval * 60 * 1000);
    } else if (ishaReachable || highLatRule === HighLatitudeRule.NONE) {
      const ishaUTC = PrayerTimeCalculator.calculateTimeForAltitude(
        date, latitude, longitude, dec, eot, -effectiveIshaAngle, true
      );
      isha = PrayerTimeCalculator.dateFromUTCHours(date, ishaUTC + timezoneOffset);
    } else {
      isha = PrayerTimeCalculator.applyHighLatFallback(
        sunset, nightMs, effectiveIshaAngle, highLatRule, false
      );
    }

    // ---- Imsak (Fajr − 10 min) ----
    const imsak = new Date(fajr);
    imsak.setMinutes(imsak.getMinutes() - 10);

    // ---- Night divisions ----
    // Midnight method picks which boundary terminates the night.
    const nightEnd: Date = advanced.midnight === MidnightMethod.JAFARI
      ? tomorrowFajr : tomorrowSunrise;

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
      asrRuleUsed: asrRule === AsrShadowRule.STANDARD ? 'Standard (Shafi\'i)' : 'Hanafi'
    };
  }

  static calculateWithDeviceTimezone(
    date: Date,
    latitude: number,
    longitude: number,
    method: CalculationMethod,
    asrRule: AsrShadowRule = AsrShadowRule.STANDARD,
    highLatRule: HighLatitudeRule = HighLatitudeRule.NONE,
    advanced: AdvancedCalcSettings = DEFAULT_ADVANCED_CALC
  ): DailyPrayerTimes {
    const effectiveOffset = TimezoneResolver.effectiveOffsetForLocation(
      latitude, longitude, date
    );
    return PrayerTimeCalculator.calculate(
      date, latitude, longitude, effectiveOffset,
      method, asrRule, highLatRule, advanced
    );
  }

  // ============================================================
  // ROUNDING
  // ============================================================

  private static rounderFor(method: RoundingMethod): (d: Date) => string {
    switch (method) {
      case RoundingMethod.UP:
        return PrayerTimeCalculator.formatTimeUp;
      case RoundingMethod.NONE:
        return PrayerTimeCalculator.formatTimeExact;
      case RoundingMethod.NEAREST:
      default:
        return PrayerTimeCalculator.formatTime;
    }
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
    const minutesStr = minutes.toString().padStart(2, '0');
    return `${hours}:${minutesStr} ${ampm}`;
  }

  private static formatTimeUp(date: Date): string {
    const d = new Date(date.getTime());
    if (d.getSeconds() > 0) {
      d.setMinutes(d.getMinutes() + 1);
    }
    return PrayerTimeCalculator.formatTime(d);
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

  // ============================================================
  // CORE ASTRONOMICAL METHODS (Meeus)
  // ============================================================

  private static getSolarPosition(date: Date): SolarPosition {
    const jd = PrayerTimeCalculator.calculateJulianDay(date);
    const daysSinceJ2000 = jd - Astronomy.J2000;

    let meanAnomaly = Astronomy.MEAN_ANOMALY_2000
      + Astronomy.MEAN_ANOMALY_RATE * daysSinceJ2000;
    meanAnomaly = PrayerTimeCalculator.normalizeAngle(meanAnomaly);

    let meanLongitude = Astronomy.MEAN_LONGITUDE_2000
      + Astronomy.MEAN_LONGITUDE_RATE * daysSinceJ2000;
    meanLongitude = PrayerTimeCalculator.normalizeAngle(meanLongitude);

    const T = daysSinceJ2000 / 36525;
    const mRad = meanAnomaly * Math.PI / 180;
    const eqCenter =
      (1.914602 - 0.004817 * T - 0.000014 * T * T) * Math.sin(mRad)
        + (0.019993 - 0.000101 * T) * Math.sin(2 * mRad)
        + 0.000289 * Math.sin(3 * mRad);

    const eclipticLongitude = meanLongitude + eqCenter;

    const centuries = daysSinceJ2000 / 36525;
    const obliquity = Astronomy.OBLIQUITY_2000 - 0.0130042 * centuries;

    const eclRad = eclipticLongitude * Math.PI / 180;
    const oblRad = obliquity * Math.PI / 180;

    const sinDec = Math.sin(eclRad) * Math.sin(oblRad);
    const dec = Math.asin(sinDec) * 180 / Math.PI;

    let ra = Math.atan2(Math.sin(eclRad) * Math.cos(oblRad), Math.cos(eclRad));
    ra = ra * 180 / Math.PI;

    let diffDeg = meanLongitude - ra;
    diffDeg = diffDeg - 360 * Math.round(diffDeg / 360);
    const eot = 4 * diffDeg;

    return { declination: dec, equationOfTime: eot };
  }

  private static calculateJulianDay(date: Date): number {
    let year = date.getUTCFullYear();
    let month = date.getUTCMonth() + 1;
    const day = date.getUTCDate() +
      date.getUTCHours() / 24 +
      date.getUTCMinutes() / 1440 +
      date.getUTCSeconds() / 86400;

    if (month <= 2) {
      year -= 1;
      month += 12;
    }

    const a = Math.floor(year / 100);
    const b = 2 - a + Math.floor(a / 4);
    return Math.floor(365.25 * (year + 4716)) +
      Math.floor(30.6001 * (month + 1)) +
      day + b - 1524.5;
  }

  private static normalizeAngle(degrees: number): number {
    let angle = degrees % 360;
    if (angle < 0) {
      angle += 360;
    }
    return angle;
  }

  private static calculateTimeForAltitude(
    date: Date,
    latitude: number,
    longitude: number,
    declinationDeg: number,
    equationOfTimeMinutes: number,
    targetAltitudeDeg: number,
    isAfternoon: boolean
  ): number {
    const rad = Math.PI / 180;
    const latRad = latitude * rad;
    const decRad = declinationDeg * rad;
    const altRad = targetAltitudeDeg * rad;

    const numerator = Math.sin(altRad) - Math.sin(latRad) * Math.sin(decRad);
    const denominator = Math.cos(latRad) * Math.cos(decRad);
    let cosHA = numerator / denominator;

    if (cosHA > 1) {
      cosHA = 1;
    }
    if (cosHA < -1) {
      cosHA = -1;
    }

    const haRad = Math.acos(cosHA);
    let haDeg = haRad * 180 / Math.PI;

    if (!isAfternoon) {
      haDeg = -haDeg;
    }

    const solarNoonUTC = 12 - (longitude / 15) - (equationOfTimeMinutes / 60);
    return solarNoonUTC + (haDeg / 15);
  }

  private static calculateAsrAltitude(
    latitude: number,
    declinationDeg: number,
    rule: AsrShadowRule
  ): number {
    const rad = Math.PI / 180;
    const latRad = latitude * rad;
    const decRad = declinationDeg * rad;
    const delta = Math.abs(latRad - decRad);
    const multiplier = rule as number;

    const altitudeRad = Math.atan(1 / (multiplier + Math.tan(delta)));
    return altitudeRad * 180 / Math.PI;
  }

  private static dateFromUTCHours(date: Date, utcHours: number): Date {
    const midnight = new Date(date);
    midnight.setHours(0, 0, 0, 0);
    const msOffset = Math.round(utcHours * 3600 * 1000);
    return new Date(midnight.getTime() + msOffset);
  }

  private static minutesToDate(baseDate: Date, totalMinutes: number): Date {
    const result = new Date(baseDate);
    result.setHours(0, 0, 0, 0);
    result.setMinutes(totalMinutes);
    return result;
  }
}