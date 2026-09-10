// entry/src/main/ets/utils/PrayerTimeCalculator.ets

// ---- Enums ----

export enum CalculationMethod {
  KARACHI = 'Karachi',
  JAFARI = 'Jafari',
  ISNA = 'ISNA',
  MWL = 'MWL'
}

export enum AsrShadowRule {
  STANDARD = 1,
  HANAFI = 2
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
  static readonly ECCENTRICITY_CORRECTION = 0.98560028;
}

// ---- Main Calculator ----

export class PrayerTimeCalculator {

  static readonly KARACHI: CalculationParameters = {
    fajrAngle: 18,
    ishaAngle: 18,
    methodName: 'University of Islamic Sciences, Karachi'
  };

  static readonly JAFARI: CalculationParameters = {
    fajrAngle: 16,
    ishaAngle: 14,
    methodName: 'Shia Ithna Ashari, Leva Institute, Qum'
  };

  static readonly ISNA: CalculationParameters = {
    fajrAngle: 15,
    ishaAngle: 15,
    methodName: 'Islamic Society of North America'
  };

  static readonly MWL: CalculationParameters = {
    fajrAngle: 18,
    ishaAngle: 17,
    methodName: 'Muslim World League'
  };

  static getParameters(method: CalculationMethod): CalculationParameters {
    switch (method) {
      case CalculationMethod.KARACHI: return PrayerTimeCalculator.KARACHI;
      case CalculationMethod.JAFARI:  return PrayerTimeCalculator.JAFARI;
      case CalculationMethod.ISNA:    return PrayerTimeCalculator.ISNA;
      case CalculationMethod.MWL:     return PrayerTimeCalculator.MWL;
      default:                        return PrayerTimeCalculator.KARACHI;
    }
  }

  static getAvailableMethods(): Array<MethodOption> {
    return [
      { value: CalculationMethod.KARACHI, label: 'Karachi (18°/18°)' },
      { value: CalculationMethod.JAFARI,  label: 'Jafari - Leva Institute (16°/14°)' },
      { value: CalculationMethod.ISNA,    label: 'ISNA (15°/15°)' },
      { value: CalculationMethod.MWL,     label: 'Muslim World League (18°/17°)' }
    ];
  }

  static getAvailableAsrRules(): Array<AsrRuleOption> {
    return [
      { value: AsrShadowRule.STANDARD, label: 'Standard (Shafi\'i / Maliki / Hanbali)' },
      { value: AsrShadowRule.HANAFI,   label: 'Hanafi' }
    ];
  }

  static calculate(
    date: Date,
    latitude: number,
    longitude: number,
    timezoneOffset: number,
    method: CalculationMethod,
    asrRule: AsrShadowRule = AsrShadowRule.STANDARD
  ): DailyPrayerTimes {
    const params = PrayerTimeCalculator.getParameters(method);

    const solarPos = PrayerTimeCalculator.getSolarPosition(date);
    const dec = solarPos.declination;
    const eot = solarPos.equationOfTime;

    // Dhuhr
    const dhuhrUTC = 12 - (longitude / 15) - (eot / 60);
    const dhuhr = PrayerTimeCalculator.dateFromUTCHours(date, dhuhrUTC + timezoneOffset);

    // Sunrise & Sunset
    const sunriseUTC = PrayerTimeCalculator.calculateTimeForAltitude(date, latitude, longitude, dec, eot, 0, false);
    const sunsetUTC  = PrayerTimeCalculator.calculateTimeForAltitude(date, latitude, longitude, dec, eot, 0, true);
    const sunrise = PrayerTimeCalculator.dateFromUTCHours(date, sunriseUTC + timezoneOffset);
    const sunset  = PrayerTimeCalculator.dateFromUTCHours(date, sunsetUTC + timezoneOffset);

    // Fajr & Isha
    const fajrUTC = PrayerTimeCalculator.calculateTimeForAltitude(date, latitude, longitude, dec, eot, -params.fajrAngle, false);
    const ishaUTC = PrayerTimeCalculator.calculateTimeForAltitude(date, latitude, longitude, dec, eot, -params.ishaAngle, true);
    const fajr = PrayerTimeCalculator.dateFromUTCHours(date, fajrUTC + timezoneOffset);
    const isha = PrayerTimeCalculator.dateFromUTCHours(date, ishaUTC + timezoneOffset);

    // Asr
    const asrAltitude = PrayerTimeCalculator.calculateAsrAltitude(latitude, dec, asrRule);
    const asrUTC = PrayerTimeCalculator.calculateTimeForAltitude(date, latitude, longitude, dec, eot, asrAltitude, true);
    const asr = PrayerTimeCalculator.dateFromUTCHours(date, asrUTC + timezoneOffset);

    // Maghrib = sunset
    const maghrib = new Date(sunset);

    // Imsak = Fajr - 10 minutes
    const imsak = new Date(fajr);
    imsak.setMinutes(imsak.getMinutes() - 10);

    // Night calculations
    const tomorrow = new Date(date);
    tomorrow.setDate(tomorrow.getDate() + 1);
    const tomorrowSolarPos = PrayerTimeCalculator.getSolarPosition(tomorrow);
    const tomorrowFajrUTC = PrayerTimeCalculator.calculateTimeForAltitude(
      tomorrow, latitude, longitude,
      tomorrowSolarPos.declination, tomorrowSolarPos.equationOfTime,
      -params.fajrAngle, false
    );
    const tomorrowFajr = PrayerTimeCalculator.dateFromUTCHours(tomorrow, tomorrowFajrUTC + timezoneOffset);

    const maghribMin = maghrib.getHours() * 60 + maghrib.getMinutes();
    let tomorrowFajrMin = tomorrowFajr.getHours() * 60 + tomorrowFajr.getMinutes();
    if (tomorrowFajrMin < maghribMin) tomorrowFajrMin += 24 * 60;
    const nightDuration = tomorrowFajrMin - maghribMin;

    const firstThirdMin = Math.round(maghribMin + nightDuration / 3);
    const midnightMin   = Math.round(maghribMin + nightDuration / 2);
    const lastThirdMin  = Math.round(maghribMin + (2 * nightDuration) / 3);

    const firstThird = PrayerTimeCalculator.minutesToDate(date, firstThirdMin);
    const midnight   = PrayerTimeCalculator.minutesToDate(date, midnightMin);
    const lastThird  = PrayerTimeCalculator.minutesToDate(date, lastThirdMin);

    return {
      fajr: PrayerTimeCalculator.formatTime(fajr),
      dhuhr: PrayerTimeCalculator.formatTime(dhuhr),
      asr: PrayerTimeCalculator.formatTime(asr),
      maghrib: PrayerTimeCalculator.formatTime(maghrib),
      isha: PrayerTimeCalculator.formatTime(isha),
      sunrise: PrayerTimeCalculator.formatTime(sunrise),
      sunset: PrayerTimeCalculator.formatTime(sunset),
      imsak: PrayerTimeCalculator.formatTime(imsak),
      firstThird: PrayerTimeCalculator.formatTime(firstThird),
      midnight: PrayerTimeCalculator.formatTime(midnight),
      lastThird: PrayerTimeCalculator.formatTime(lastThird),
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
    asrRule: AsrShadowRule = AsrShadowRule.STANDARD
  ): DailyPrayerTimes {
    const timezoneOffset = PrayerTimeCalculator.getCurrentTimezoneOffset(date);
    return PrayerTimeCalculator.calculate(date, latitude, longitude, timezoneOffset, method, asrRule);
  }

  // ---- Core Astronomical Methods ----

  private static getSolarPosition(date: Date): SolarPosition {
    const jd = PrayerTimeCalculator.calculateJulianDay(date);
    const daysSinceJ2000 = jd - Astronomy.J2000;

    let meanAnomaly = Astronomy.MEAN_ANOMALY_2000 + Astronomy.ECCENTRICITY_CORRECTION * daysSinceJ2000;
    meanAnomaly = PrayerTimeCalculator.normalizeAngle(meanAnomaly);

    let meanLongitude = Astronomy.MEAN_LONGITUDE_2000 + Astronomy.ECCENTRICITY_CORRECTION * daysSinceJ2000;
    meanLongitude = PrayerTimeCalculator.normalizeAngle(meanLongitude);

    const mRad = meanAnomaly * Math.PI / 180;
    const eqCenter = 1.91482 * Math.sin(mRad) - 0.00099 * Math.sin(2 * mRad) + 0.00002 * Math.sin(3 * mRad);

    const eclipticLongitude = meanLongitude + eqCenter;
    const centuries = daysSinceJ2000 / 36525;
    const obliquity = Astronomy.OBLIQUITY_2000 - 0.0130042 * centuries;

    const eclRad = eclipticLongitude * Math.PI / 180;
    const oblRad = obliquity * Math.PI / 180;

    const sinDec = Math.sin(eclRad) * Math.sin(oblRad);
    const dec = Math.asin(sinDec) * 180 / Math.PI;

    let ra = Math.atan2(Math.sin(eclRad) * Math.cos(oblRad), Math.cos(eclRad));
    ra = ra * 180 / Math.PI;

    let eot = 4 * (meanLongitude - ra);
    if (eot > 20) eot = eot - 1440;
    if (eot < -20) eot = eot + 1440;

    return { declination: dec, equationOfTime: eot };
  }

  private static calculateJulianDay(date: Date): number {
    let year = date.getFullYear();
    let month = date.getMonth() + 1;
    const day = date.getDate() + date.getHours() / 24 + date.getMinutes() / 1440 + date.getSeconds() / 86400;

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
    if (angle < 0) angle += 360;
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

    if (cosHA > 1) cosHA = 1;
    if (cosHA < -1) cosHA = -1;

    const haRad = Math.acos(cosHA);
    let haDeg = haRad * 180 / Math.PI;

    if (!isAfternoon) haDeg = -haDeg;

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

  // ---- Utility Methods ----

  private static dateFromUTCHours(date: Date, utcHours: number): Date {
    const result = new Date(date);
    result.setHours(0, 0, 0, 0);
    result.setMinutes(utcHours * 60);
    return result;
  }

  private static minutesToDate(baseDate: Date, totalMinutes: number): Date {
    const result = new Date(baseDate);
    result.setHours(0, 0, 0, 0);
    result.setMinutes(totalMinutes);
    return result;
  }

  // ---- AM/PM FORMATTER ----
  private static formatTime(date: Date): string {
    let hours = date.getHours();
    const minutes = date.getMinutes();
    const ampm = hours >= 12 ? 'PM' : 'AM';
    hours = hours % 12;
    if (hours === 0) hours = 12;
    const minutesStr = minutes.toString().padStart(2, '0');
    return `${hours}:${minutesStr} ${ampm}`;
  }

  private static getCurrentTimezoneOffset(date: Date): number {
    return -date.getTimezoneOffset() / 60;
  }
}