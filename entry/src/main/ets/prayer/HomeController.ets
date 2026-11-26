// entry/src/main/ets/utils/HomeController.ets

import { ExtraTiming, PrayerModel } from './PrayerModel'
import {
  AsrShadowRule,
  CalculationMethod,
  DailyPrayerTimes,
  HighLatitudeRule,
  PrayerTimeCalculator
} from './PrayerTimeCalculator'
import { PrayerManager } from './PrayerManager'
import { PrayerOffsets, SettingsHelper } from '../settings/SettingsHelper'
import { LocationMode } from '../settings/SettingsModels'
import { CachedLocation, FALLBACK_LOCATION, LocationCache } from '../location/LocationCache'
import { L } from '../i18n/LocalizationHelper'
import { TimezoneResolver } from '../location/TimezoneResolver'
import { AdvancedCalcSettings, DEFAULT_ADVANCED_CALC } from './AdvancedCalcModels'
import { AppLogger } from '../core/app/AppLogger'
import { OfflineCityLookup } from '../location/OfflineCityLookup'

export interface HomePrayerSnapshot {
  prayers: PrayerModel[]
  extras: ExtraTiming[]
}

export interface HomeHeaderSnapshot {
  currentName: string
  currentTime: string
  nextName: string
  nextTime: string
}

export interface HomeLocationSnapshot {
  latitude: number
  longitude: number
  displayName: string
  isManual: boolean
}

export interface NextEventInfo {
  name: string
  time: string
}

interface TimelineEvent {
  name: string
  time: Date
}

const MS_PER_DAY = 86400000

export class HomeController {
  // ============================================================
  // PRAYER TIME COMPUTATION
  // ============================================================

  static buildPrayersForDate(date: Date, latitude: number, longitude: number, method: CalculationMethod,
    asrRule: AsrShadowRule, highLatRule: HighLatitudeRule, offsets: PrayerOffsets, template: PrayerModel[],
    advanced: AdvancedCalcSettings = DEFAULT_ADVANCED_CALC): HomePrayerSnapshot | null {
    if (latitude === 0 && longitude === 0) {
      return null
    }

    try {
      const anchor = HomeController.getLocationAnchor(latitude, longitude, date)

      const times: DailyPrayerTimes =
        PrayerTimeCalculator.calculateWithDeviceTimezone(anchor, latitude, longitude, method, asrRule, highLatRule,
          advanced)

      // M-N1: pick the day-of-week source for applyDayNames.
      //
      //   • "Today" (device day) → use `anchor` so the Jummah label
      //     reflects the location's current Gregorian day, not the
      //     device's. Fixes the cross-timezone label bug (Karachi
      //     device Friday morning + NYC location still Thursday
      //     showed "Jummah" one day early).
      //
      //   • Explicit past/future date → use `date` unchanged so the
      //     user's date selection wins. Shifting it through the tz
      //     delta can silently roll into the previous Gregorian day,
      //     which the user did not pick.
      const todayMidnight = new Date()
      todayMidnight.setHours(0, 0, 0, 0)
      const dateMidnight = new Date(date)
      dateMidnight.setHours(0, 0, 0, 0)
      const isViewingToday = dateMidnight.getTime() === todayMidnight.getTime()
      const dayNameSource = isViewingToday ? anchor : date

      const withOffsets: PrayerModel[] = PrayerManager.applyTimesToPrayers(template, times, offsets, dayNameSource)
      const offsetHours: number = TimezoneResolver.effectiveOffsetForLocation(latitude, longitude, date)
      const withStatus: PrayerModel[] = PrayerManager.updateStatuses(withOffsets, date, offsetHours)
      const emptyExtras: ExtraTiming[] = []
      const snapshot: HomePrayerSnapshot = {
        prayers: withStatus, extras: emptyExtras
      }
      return snapshot
    } catch (err) {
      const error = err as Error
      console.error(`[HomeController] build failed: ${error.message}`)
      return null
    }
  }

  static buildExtraTimings(date: Date, latitude: number, longitude: number, method: CalculationMethod,
    asrRule: AsrShadowRule, highLatRule: HighLatitudeRule, offsets: PrayerOffsets, template: ExtraTiming[],
    advanced: AdvancedCalcSettings = DEFAULT_ADVANCED_CALC): ExtraTiming[] {
    if (latitude === 0 && longitude === 0) {
      return template
    }
    try {
      const anchor = HomeController.getLocationAnchor(latitude, longitude, date)
      const times: DailyPrayerTimes =
        PrayerTimeCalculator.calculateWithDeviceTimezone(anchor, latitude, longitude, method, asrRule, highLatRule,
          advanced)
      return PrayerManager.applyTimesToExtraTimings(template, times, offsets)
    } catch (err) {
      return template
    }
  }

  // ============================================================
  // TODAY HEADER
  // ============================================================

  static buildTodayHeader(latitude: number, longitude: number, method: CalculationMethod, asrRule: AsrShadowRule,
    highLatRule: HighLatitudeRule, offsets: PrayerOffsets, template: PrayerModel[],
    advanced: AdvancedCalcSettings = DEFAULT_ADVANCED_CALC): HomeHeaderSnapshot | null {
    if (latitude === 0 && longitude === 0) {
      return null
    }
    const today = new Date()
    const anchor = HomeController.getLocationAnchor(latitude, longitude, today)
    try {
      const times: DailyPrayerTimes =
        PrayerTimeCalculator.calculateWithDeviceTimezone(anchor, latitude, longitude, method, asrRule, highLatRule,
          advanced) // Pass the location anchor, not the device `today`. applyDayNames
      // reads getDay() to decide Jummah vs Dhuhr. In a cross-timezone
      // setup the device and location can be on different Gregorian
      // days — e.g. Karachi device Tuesday 01:00, NYC location still
      // Monday 20:00. Using `today` labels Dhuhr as Jummah one day
      // early for the NYC user. Using `anchor` reflects what day it
      // actually is at the location.
      const withOffsets: PrayerModel[] = PrayerManager.applyTimesToPrayers(template, times, offsets, anchor)
      const offsetHours: number = TimezoneResolver.effectiveOffsetForLocation(latitude, longitude, today)

      // Log the offsets actually used so that a "wrong times" report
      // can be traced to a specific device/location pair without
      // guessing.
      try {
        const deviceOffset = -today.getTimezoneOffset() / 60
        AppLogger.info('HomeController', `Header offsets: device=${deviceOffset}h, ` + `location=${offsetHours}h, ` +
          `lat=${latitude.toFixed(4)}, lng=${longitude.toFixed(4)}`)
      } catch (err) { // Never let diagnostics affect the calculation path.
      }

      const withStatus: PrayerModel[] = PrayerManager.updateStatuses(withOffsets, today, offsetHours)

      let current: PrayerModel | null = PrayerManager.getCurrentPrayer(withStatus, offsetHours)

      // Before Fajr, no prayer has occurred yet today. The logical
      // "current" prayer is the previous day's Isha, whose window
      // runs from Maghrib through to the next Fajr.
      if (current === null) {
        current =
          HomeController.buildPreviousIsha(today, latitude, longitude, method, asrRule, highLatRule, offsets, advanced)
      }

      const nextEvent: NextEventInfo | null =
        HomeController.computeNextEvent(today, latitude, longitude, method, asrRule, highLatRule, offsets, advanced)

      const snapshot: HomeHeaderSnapshot = {
        currentName: current ? current.name : '—',
        currentTime: current ? current.time : '--:--',
        nextName: nextEvent ? nextEvent.name : '—',
        nextTime: nextEvent ? nextEvent.time : '--:--'
      }
      return snapshot
    } catch (err) {
      return null
    }
  }

  /**
   * Return the next upcoming prayer or timing relative to `now`.
   *
   * ## Timezone handling (critical)
   *
   * Event times produced by `appendDayEvents` / `parseToDate` are in
   * the **location's wall-clock space** — they carry the raw hours and
   * minutes that a clock on the wall in the location would show, but
   * their `Date` object holds those values against the **device's**
   * epoch. This is by design: the rest of the codebase (PrayerManager
   * statuses, PrayerTimeCalculator offsets) also works in this shifted
   * space, so everything compares consistently.
   *
   * For the "is this event in the future?" test to work, `now` must be
   * shifted into the same space before comparison. Comparing raw
   * `now.getTime()` against the shifted event times silently returns
   * the wrong answer whenever the device and the location are in
   * different timezones.
   *
   * Concretely: a Karachi device (UTC+5) with a New York manual
   * location (UTC−5) at Monday 07:00 UTC is 02:00 AM in NY. Correct
   * next prayer is Fajr 5:30 AM. Before this fix, the comparison
   * treated Fajr and Dhuhr (Monday 00:30 and 05:00 UTC) as already
   * past — returning Asr instead. Confirmed in the bug report.
   *
   * ## Reference points
   *
   * `nowShifted` = `now` in the location's wall-clock space. Used
   *   for the future-comparison.
   *
   * `anchor` = midnight of "today" in the location's wall clock.
   *   Used to build the -1 / 0 / +1 day grid. Derived from `nowShifted`
   *   so both values agree on which day counts as "today" in the
   *   location's clock.
   */
  static computeNextEvent(now: Date, latitude: number, longitude: number, method: CalculationMethod,
    asrRule: AsrShadowRule, highLatRule: HighLatitudeRule, offsets: PrayerOffsets,
    advanced: AdvancedCalcSettings = DEFAULT_ADVANCED_CALC): NextEventInfo | null {
    const events: TimelineEvent[] = []

    // Shift "now" into the location's wall clock, then take midnight
    // of that day for the -1/0/+1 grid. Same-timezone users get a
    // byte-identical `nowShifted` and `anchor` as before — no
    // behavioural change for the common case.
    const nowShifted = HomeController.getLocationAnchor(latitude, longitude, now)
    const anchor = new Date(nowShifted.getTime())
    anchor.setHours(0, 0, 0, 0)

    for (let delta = -1; delta <= 1; delta++) {
      const day = new Date(anchor)
      day.setDate(day.getDate() + delta)

      try {
        const times: DailyPrayerTimes =
          PrayerTimeCalculator.calculateWithDeviceTimezone(day, latitude, longitude, method, asrRule, highLatRule,
            advanced)
        HomeController.appendDayEvents(events, day, times, offsets)
      } catch (err) { // Skip this day silently; the other two days cover "next".
      }
    }

    events.sort((a: TimelineEvent, b: TimelineEvent): number => a.time.getTime() - b.time.getTime())

    // Compare against the shifted "now", not the raw device time.
    // Both sides of the comparison are now in the location's
    // wall-clock space.
    const nowMs: number = nowShifted.getTime()
    for (let i = 0; i < events.length; i++) {
      const e: TimelineEvent = events[i]
      if (e.time.getTime() > nowMs) {
        const info: NextEventInfo = {
          name: e.name, time: HomeController.formatEventTime(e.time)
        }
        return info
      }
    }
    return null
  }

  // ============================================================
  // TIMELINE — next event including extras after Isha
  // ============================================================

  static async loadLocationForMode(mode: LocationMode): Promise<HomeLocationSnapshot> {
    const manualLabel = L.get('manual_location')
    const lang = L.current()

    if (mode === LocationMode.MANUAL) {
      const coords = await SettingsHelper.getManualCoords()
      if (coords.lat !== 0 || coords.lng !== 0) {
        let rawCity = coords.cityName
        if (rawCity === 'DEFAULT LOCATION' || rawCity.length === 0) {
          rawCity = L.get('default_location')
        } else {
          rawCity = OfflineCityLookup.translateCityName(rawCity, lang)
        }

        const snapshot: HomeLocationSnapshot = {
          latitude: coords.lat,
          longitude: coords.lng,
          displayName: `${rawCity} (${manualLabel})`,
          isManual: true
        }
        return snapshot
      }
      const snapshot: HomeLocationSnapshot = {
        latitude: 0,
        longitude: 0,
        displayName: L.get('set_manual_location'),
        isManual: true
      }
      return snapshot
    }

    const cached: CachedLocation | null = await LocationCache.load()
    if (cached) {
      let rawCity = cached.cityName
      if (rawCity === 'DEFAULT LOCATION' || rawCity.length === 0) {
        rawCity = L.get('default_location')
      } else {
        rawCity = OfflineCityLookup.translateCityName(rawCity, lang)
      }

      const snapshot: HomeLocationSnapshot = {
        latitude: cached.latitude,
        longitude: cached.longitude,
        displayName: rawCity,
        isManual: false
      }
      return snapshot
    }
    const fallback: HomeLocationSnapshot = {
      latitude: FALLBACK_LOCATION.latitude,
      longitude: FALLBACK_LOCATION.longitude,
      displayName: L.get('default_location'),
      isManual: false
    }
    return fallback
  }

  /**
   * Before Fajr, the app has no current prayer for today. The
   * correct display is the previous day's Isha — its window runs
   * from Maghrib through the next Fajr.
   *
   * Returns a minimal PrayerModel carrying only the fields the
   * header needs. The result is not added to any persistent state.
   *
   * Note: we do NOT call getLocationAnchor() before passing
   * `yesterday` to calculateWithDeviceTimezone. Doing so shifted
   * yesterday by the offset delta, then let calculateWithDeviceTimezone
   * re-resolve the offset from the shifted date — a double-shift
   * that could flap across a DST boundary on manual-location users.
   * The calculator already resolves its own offset from the
   * (date + coords) pair, so we hand it yesterday unmodified.
   */
  private static buildPreviousIsha(today: Date, latitude: number, longitude: number, method: CalculationMethod,
    asrRule: AsrShadowRule, highLatRule: HighLatitudeRule, offsets: PrayerOffsets,
    advanced: AdvancedCalcSettings): PrayerModel | null {
    const yesterday = new Date(today.getTime() - MS_PER_DAY)

    try {
      const yTimes: DailyPrayerTimes =
        PrayerTimeCalculator.calculateWithDeviceTimezone(yesterday, latitude, longitude, method, asrRule, highLatRule,
          advanced)
      const yIsha = PrayerManager.offsetTime(yTimes.isha, offsets.isha)

      const result: PrayerModel = {
        id: 'isha',
        name: 'Isha',
        arabicName: 'العشاء',
        time: yIsha,
        status: 'pray',
        checked: false
      }
      return result
    } catch (err) {
      return null
    }
  }

  private static appendDayEvents(events: TimelineEvent[], prayerDay: Date, times: DailyPrayerTimes,
    offsets: PrayerOffsets): void {
    const isFriday = prayerDay.getDay() === 5
    const dhuhrName = isFriday ? 'Jummah' : 'Dhuhr'

    // Compute the Maghrib threshold for evening events
    const maghribStr = PrayerManager.offsetTime(times.maghrib, offsets.maghrib)
    const maghribMinutes = PrayerManager.timeToMinutes(maghribStr)

    const fajrEv: TimelineEvent = {
      name: 'Fajr',
      time: HomeController.parseToDate(PrayerManager.offsetTime(times.fajr, offsets.fajr), prayerDay, null)
    }
    events.push(fajrEv)

    const dhuhrEv: TimelineEvent = {
      name: dhuhrName,
      time: HomeController.parseToDate(PrayerManager.offsetTime(times.dhuhr, offsets.dhuhr), prayerDay, null)
    }
    events.push(dhuhrEv)

    const asrEv: TimelineEvent = {
      name: 'Asr', time: HomeController.parseToDate(PrayerManager.offsetTime(times.asr, offsets.asr), prayerDay, null)
    }
    events.push(asrEv)

    const maghribEv: TimelineEvent = {
      name: 'Maghrib',
      time: HomeController.parseToDate(PrayerManager.offsetTime(times.maghrib, offsets.maghrib), prayerDay, null)
    }
    events.push(maghribEv)

    const ishaEv: TimelineEvent = {
      name: 'Isha',
      time: HomeController.parseToDate(PrayerManager.offsetTime(times.isha, offsets.isha), prayerDay, null)
    }
    events.push(ishaEv)

    const firstThirdEv: TimelineEvent = {
      name: 'First Third', time: HomeController.parseToDate(times.firstThird, prayerDay, maghribMinutes)
    }
    events.push(firstThirdEv)

    const midnightEv: TimelineEvent = {
      name: 'Midnight', time: HomeController.parseToDate(times.midnight, prayerDay, maghribMinutes)
    }
    events.push(midnightEv)

    const lastThirdEv: TimelineEvent = {
      name: 'Last Third', time: HomeController.parseToDate(times.lastThird, prayerDay, maghribMinutes)
    }
    events.push(lastThirdEv)

    const imsakEv: TimelineEvent = {
      name: 'Imsak',
      time: HomeController.parseToDate(PrayerManager.offsetTime(times.imsak, offsets.fajr), prayerDay, null)
    }
    events.push(imsakEv)
  }

  /**
   * Parse a formatted time string ("6:32 PM" / "17:23") into a Date
   * anchored to `prayerDay`.
   *
   * `minMinutes` provides the day-boundary threshold: an event whose
   * parsed time is numerically earlier than `minMinutes` (minutes
   * since midnight) belongs to the *next* calendar day. Pass `null`
   * for events that are always same-day (prayers, Imsak).
   */
  private static parseToDate(timeStr: string, prayerDay: Date, minMinutes: number | null): Date {
    const result = new Date(prayerDay)
    result.setHours(0, 0, 0, 0)

    const trimmed: string = timeStr.trim()
    if (trimmed === '' || trimmed === '--:--') {
      return result
    }

    const parts: string[] = trimmed.split(' ')
    if (parts.length !== 2) {
      return result
    }

    const timeParts: string[] = parts[0].split(':')
    if (timeParts.length !== 2) {
      return result
    }

    let hours: number = parseInt(timeParts[0], 10)
    const minutes: number = parseInt(timeParts[1], 10)
    const period: string = parts[1].toUpperCase()

    if (isNaN(hours) || isNaN(minutes)) {
      return result
    }

    if (period === 'PM' && hours !== 12) {
      hours += 12
    }
    if (period === 'AM' && hours === 12) {
      hours = 0
    }

    result.setHours(hours, minutes, 0, 0)

    if (minMinutes !== null && hours * 60 + minutes < minMinutes) {
      result.setDate(result.getDate() + 1)
    }
    return result
  }

  private static getLocationAnchor(latitude: number, longitude: number, now: Date): Date {
    if (latitude === 0 && longitude === 0) {
      return new Date(now)
    }

    const locationOffset = TimezoneResolver.effectiveOffsetForLocation(latitude, longitude, now)
    const deviceOffset = -now.getTimezoneOffset() / 60
    const deltaMs = (locationOffset - deviceOffset) * 3600 * 1000
    return new Date(now.getTime() + deltaMs)
  }

  private static formatEventTime(date: Date): string {
    let hours: number = date.getHours()
    const minutes: number = date.getMinutes()
    const ampm: string = hours >= 12 ? 'PM' : 'AM'
    hours = hours % 12
    if (hours === 0) {
      hours = 12
    }
    const minutesStr: string = minutes.toString().padStart(2, '0')
    return `${hours}:${minutesStr} ${ampm}`
  }
}
