// entry/src/main/ets/helper/NotificationHelper.ets

import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { notificationManager } from '@kit.NotificationKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { NotificationsSettings, PrayerOffsets, SettingsHelper } from './SettingsHelper';
import {
  AsrShadowRule,
  CalculationMethod,
  DailyPrayerTimes,
  HighLatitudeRule,
  PrayerTimeCalculator
} from '../prayer/PrayerTimeCalculator';
import { PrayerCheckState, PrayerManager } from '../prayer/PrayerManager';
import { LocationCache } from '../utils/LocationCache';
import { LocationMode } from '../models/SettingsModels';
import { L } from './LocalizationHelper';
import { AppLogger } from './AppLogger';
import { CALENDAR_REMINDERS_ENABLED, NOTIFICATIONS_ENABLED } from '../common/FeatureFlags';
import { CalendarReminderEntry, CalendarReminderHelper } from '../hijricalendar/CalendarReminderHelper';

/** How many days ahead to schedule. Older reminders renew on app open. */
const DAYS_AHEAD = 3;

export const MIN_BEFORE_MINUTES = 0;
export const MAX_BEFORE_MINUTES = 60;
export const STEP_BEFORE_MINUTES = 5;

/** Default debounce for scheduled reschedules, in milliseconds. */
const RESCHEDULE_DEBOUNCE_MS = 600;

/** Which backend is currently active. */
export type ReminderBackend = 'agent' | 'calendar' | 'none';

interface PrayerNotificationItem {
  id: string;
  name: string;
  time: string;
}

export interface ScheduleResult {
  ok: boolean;
  scheduled: number;
  errorCode: number;
  errorMessage: string;
}

/**
 * Schedules and cancels prayer reminders.
 *
 * Two backends are supported:
 *
 *   Agent-Powered Reminder (reminderAgentManager)
 *     Produces standard app notifications.
 *     Gated by NOTIFICATIONS_ENABLED in FeatureFlags.ets.
 *
 *   Calendar Kit (calendarManager)
 *     Writes prayer events into the system calendar with reminders.
 *     Gated by CALENDAR_REMINDERS_ENABLED in FeatureFlags.ets.
 *
 * Both backends deliver the same content per prayer:
 *   Title  — "Pray Fajr" (localized)
 *   Body   — a Hadith associated with that prayer, with its source
 *
 * ## Prayed prayers are skipped
 *
 * If a prayer is marked as prayed on a given date, its reminder for
 * that date is not scheduled. Because rescheduleAll() cancels the
 * entire existing set and then re-creates only the pending prayers,
 * marking a prayer as prayed removes its existing reminder too.
 *
 * ## Debounced reschedule
 *
 * scheduleReschedule() coalesces rapid state changes into a single
 * reschedule. Toggling five prayers in a row, or tapping "Mark all
 * as prayed", produces one reschedule pass rather than five.
 *
 * Exactly one backend is active at a time. resolveBackend() enforces
 * this — if both flags are true, Calendar wins.
 */
export class NotificationHelper {

  // ============================================================
  // BACKEND RESOLUTION
  // ============================================================

  static resolveBackend(): ReminderBackend {
    if (CALENDAR_REMINDERS_ENABLED) {
      return 'calendar';
    }
    if (NOTIFICATIONS_ENABLED) {
      return 'agent';
    }
    return 'none';
  }

  static isAnyBackendEnabled(): boolean {
    return NotificationHelper.resolveBackend() !== 'none';
  }

  // ============================================================
  // PERMISSION
  // ============================================================

  static async requestPermission(
    context: common.UIAbilityContext
  ): Promise<boolean> {
    const backend = NotificationHelper.resolveBackend();

    if (backend === 'calendar') {
      return CalendarReminderHelper.requestPermission(context);
    }
    if (backend === 'agent') {
      try {
        await notificationManager.requestEnableNotification(context);
        AppLogger.info('NotificationHelper', 'Agent permission granted');
        return true;
      } catch (err) {
        const error = err as BusinessError;
        AppLogger.warn('NotificationHelper',
          `Agent permission request failed: ${error.code} ${error.message}`);
        return false;
      }
    }
    return false;
  }

  static async isPermissionGranted(
    context: common.UIAbilityContext
  ): Promise<boolean> {
    const backend = NotificationHelper.resolveBackend();

    if (backend === 'calendar') {
      return CalendarReminderHelper.isPermissionGranted(context);
    }
    if (backend === 'agent') {
      try {
        return await notificationManager.isNotificationEnabled();
      } catch (err) {
        const error = err as BusinessError;
        AppLogger.warn('NotificationHelper',
          `isNotificationEnabled failed: ${error.code} ${error.message}`);
        return false;
      }
    }
    return false;
  }

  // ============================================================
  // CANCEL
  // ============================================================

  static async cancelAll(): Promise<void> {
    const backend = NotificationHelper.resolveBackend();

    if (backend === 'calendar') {
      await CalendarReminderHelper.cancelAll();
      return;
    }
    if (backend === 'agent') {
      try {
        await reminderAgentManager.cancelAllReminders();
        AppLogger.info('NotificationHelper', 'All agent reminders cancelled');
      } catch (err) {
        const error = err as BusinessError;
        AppLogger.warn('NotificationHelper',
          `cancelAll failed: ${error.code} ${error.message}`);
      }
    }
  }

  // ============================================================
  // TEST
  // ============================================================

  static async publishTestNotification(): Promise<ScheduleResult> {
    const backend = NotificationHelper.resolveBackend();

    if (backend === 'none') {
      const disabled: ScheduleResult = {
        ok: false,
        scheduled: 0,
        errorCode: -100,
        errorMessage: 'no reminder backend enabled'
      };
      return disabled;
    }

    const fireAt = new Date(Date.now() + 5000);
    AppLogger.info('NotificationHelper',
      `Test reminder requested — fire at ${fireAt.toISOString()}`);

    if (backend === 'calendar') {
      return NotificationHelper.publishCalendarTest(fireAt);
    }
    return NotificationHelper.publishAgentTest(fireAt);
  }

  private static async publishCalendarTest(
    fireAt: Date
  ): Promise<ScheduleResult> {
    const entry: CalendarReminderEntry = {
      title: NotificationHelper.prayTitle('Fajr'),
      startTime: fireAt.getTime(),
      reminderMinutes: [0],
      description: NotificationHelper.hadithFor('Fajr')
    };
    const count = await CalendarReminderHelper.rescheduleAll([entry]);
    const result: ScheduleResult = {
      ok: count > 0,
      scheduled: count,
      errorCode: count > 0 ? 0 : -1,
      errorMessage: count > 0 ? '' : 'calendar addEvent failed'
    };
    return result;
  }

  private static async publishAgentTest(
    fireAt: Date
  ): Promise<ScheduleResult> {
    const detail = await NotificationHelper.publishReminderDetailed(
      'Fajr', fireAt, -1
    );
    const result: ScheduleResult = {
      ok: detail.ok,
      scheduled: detail.ok ? 1 : 0,
      errorCode: detail.errorCode,
      errorMessage: detail.errorMessage
    };
    return result;
  }

  // ============================================================
  // DEBOUNCED RESCHEDULE
  // ============================================================

  private static rescheduleDebounceId: number = -1;

  /**
   * Request a reschedule after a short delay. Multiple calls within
   * the debounce window coalesce into one reschedule pass.
   *
   * Use this from UI event handlers where a user action may trigger
   * several state changes in quick succession — for example, tapping
   * a prayer checkbox or "Mark all as prayed". The reschedule runs
   * once, after the last change settles.
   *
   * Fire-and-forget. Errors are logged, never thrown.
   */
  static scheduleReschedule(delayMs: number = RESCHEDULE_DEBOUNCE_MS): void {
    if (NotificationHelper.rescheduleDebounceId !== -1) {
      clearTimeout(NotificationHelper.rescheduleDebounceId);
    }
    NotificationHelper.rescheduleDebounceId = setTimeout(() => {
      NotificationHelper.rescheduleDebounceId = -1;
      AppLogger.info('NotificationHelper',
        'Debounced reschedule firing');
      NotificationHelper.rescheduleAll().catch((e: Error) => {
        AppLogger.warn('NotificationHelper',
          `Debounced reschedule failed: ${e.message}`);
      });
    }, delayMs);
  }

  /**
   * Run a reschedule immediately, bypassing the debounce.
   *
   * Used when a state change carries a semantic meaning that should
   * be reflected right away — for example, when the last prayer of
   * the day is marked as prayed, and the rolling window should
   * advance to include the next day's reminders before the user
   * closes the app.
   *
   * Any pending debounced reschedule is cancelled first, so this
   * call's reschedule runs alone.
   */
  static scheduleRescheduleNow(): void {
    if (NotificationHelper.rescheduleDebounceId !== -1) {
      clearTimeout(NotificationHelper.rescheduleDebounceId);
      NotificationHelper.rescheduleDebounceId = -1;
    }
    NotificationHelper.rescheduleAll().catch((e: Error) => {
      AppLogger.warn('NotificationHelper',
        `Immediate reschedule failed: ${e.message}`);
    });
  }

  // ============================================================
  // RESCHEDULE (main entry point)
  // ============================================================

  /**
   * Guards against overlapping reschedule calls. If the user taps
   * the lead-time stepper three times in a row, three calls arrive
   * in quick succession; without serialization the cancel / schedule
   * pairs interleave and can leave orphaned events.
   */
  private static rescheduleInFlight: boolean = false;
  /** Set to true if a reschedule was requested while one was running. */
  private static reschedulePending: boolean = false;

  static async rescheduleAll(): Promise<ScheduleResult> {
    if (NotificationHelper.rescheduleInFlight) {
      NotificationHelper.reschedulePending = true;
      AppLogger.info('NotificationHelper',
        'rescheduleAll queued — one is already in flight');
      return {
        ok: true,
        scheduled: 0,
        errorCode: 0,
        errorMessage: 'queued'
      };
    }

    NotificationHelper.rescheduleInFlight = true;
    try {
      const result = await NotificationHelper.doRescheduleAll();
      return result;
    } finally {
      NotificationHelper.rescheduleInFlight = false;

      if (NotificationHelper.reschedulePending) {
        NotificationHelper.reschedulePending = false;
        AppLogger.info('NotificationHelper',
          'rescheduleAll running queued pass');
        NotificationHelper.rescheduleAll().catch((e: Error) => {
          AppLogger.warn('NotificationHelper',
            `Queued reschedule failed: ${e.message}`);
        });
      }
    }
  }

  private static async doRescheduleAll(): Promise<ScheduleResult> {
    const backend = NotificationHelper.resolveBackend();

    if (backend === 'none') {
      AppLogger.info('NotificationHelper',
        'rescheduleAll skipped — no backend enabled');
      return {
        ok: true,
        scheduled: 0,
        errorCode: 0,
        errorMessage: 'no backend enabled'
      };
    }

    AppLogger.info('NotificationHelper',
      `rescheduleAll started (backend=${backend})`);

    if (backend === 'calendar') {
      if (!CalendarReminderHelper.isReady()) {
        AppLogger.warn('NotificationHelper',
          'Calendar backend not ready — init failed or not attempted');
        return {
          ok: false,
          scheduled: 0,
          errorCode: -10,
          errorMessage: 'calendar backend not ready'
        };
      }
    }

    // ---- Step 1: cancel everything ----
    await NotificationHelper.cancelAll();

    // ---- Step 2: check master toggle ----
    const settings: NotificationsSettings =
      await SettingsHelper.getNotificationSettings();
    if (!settings.masterEnabled) {
      AppLogger.info('NotificationHelper',
        'Master disabled — nothing to schedule');
      return {
        ok: true,
        scheduled: 0,
        errorCode: 0,
        errorMessage: 'master disabled'
      };
    }

    // ---- Step 3: resolve location ----
    const mode = await SettingsHelper.getLocationMode();
    let latitude = 0;
    let longitude = 0;

    if (mode === LocationMode.MANUAL) {
      const coords = await SettingsHelper.getManualCoords();
      if (coords.lat === 0 && coords.lng === 0) {
        return {
          ok: false,
          scheduled: 0,
          errorCode: -2,
          errorMessage: 'no manual coordinates set'
        };
      }
      latitude = coords.lat;
      longitude = coords.lng;
    } else {
      const cached = await LocationCache.load();
      if (!cached) {
        return {
          ok: false,
          scheduled: 0,
          errorCode: -3,
          errorMessage: 'no cached GPS location'
        };
      }
      latitude = cached.latitude;
      longitude = cached.longitude;
    }

    // ---- Step 4: resolve calculation params ----
    const data = await SettingsHelper.loadAll();
    const method: CalculationMethod = data.method;
    const asrRule: AsrShadowRule = data.asr;
    const highLatRule: HighLatitudeRule =
      await SettingsHelper.getHighLatRule();
    const offsets: PrayerOffsets = await SettingsHelper.getPrayerOffsets();

    // ---- Step 5: schedule fresh ----
    // If today's prayers are all marked as prayed, shift the anchor
    // to tomorrow so the rolling window still yields DAYS_AHEAD days
    // of pending reminders. Without this, a completed day would
    // shrink the effective coverage to (DAYS_AHEAD - 1) future days.
    const anchor = new Date();
    anchor.setHours(0, 0, 0, 0);

    const todayKey = PrayerManager.getDateKeyForDate(anchor);
    if (PrayerManager.isDayFullyPrayed(todayKey)) {
      anchor.setDate(anchor.getDate() + 1);
      AppLogger.info('NotificationHelper',
        'Today fully prayed — anchor shifted to tomorrow');
    }

    const nowMs = Date.now();

    if (backend === 'calendar') {
      return NotificationHelper.scheduleViaCalendar(
        anchor, nowMs, latitude, longitude,
        method, asrRule, highLatRule, offsets, settings
      );
    }
    return NotificationHelper.scheduleViaAgent(
      anchor, nowMs, latitude, longitude,
      method, asrRule, highLatRule, offsets, settings
    );
  }

  // ============================================================
  // CALENDAR BACKEND SCHEDULING
  // ============================================================

  private static async scheduleViaCalendar(
    anchor: Date,
    nowMs: number,
    latitude: number,
    longitude: number,
    method: CalculationMethod,
    asrRule: AsrShadowRule,
    highLatRule: HighLatitudeRule,
    offsets: PrayerOffsets,
    settings: NotificationsSettings
  ): Promise<ScheduleResult> {
    AppLogger.info('NotificationHelper',
      `Scheduling calendar reminders from ` +
        `${PrayerManager.getDateKeyForDate(anchor)} for ${DAYS_AHEAD} day(s)`);
    const entries: CalendarReminderEntry[] = [];
    const leadMinutes = settings.beforeMinutes;
    const reminderMinutes: number[] = leadMinutes > 0
      ? [0, leadMinutes]
      : [0];

    for (let dayOffset = 0; dayOffset < DAYS_AHEAD; dayOffset++) {
      const day = new Date(anchor);
      day.setDate(day.getDate() + dayOffset);

      // Skip prayers already marked as prayed for this date.
      const dateKey = PrayerManager.getDateKeyForDate(day);
      const dayState: PrayerCheckState =
        PrayerManager.getCheckState(dateKey);

      let times: DailyPrayerTimes;
      try {
        times = PrayerTimeCalculator.calculateWithDeviceTimezone(
          day, latitude, longitude, method, asrRule, highLatRule
        );
      } catch (err) {
        const e = err as Error;
        AppLogger.warn('NotificationHelper',
          `Calculation failed for day ${dayOffset}: ${e.message}`);
        continue;
      }

      const prayers = NotificationHelper.buildPrayerList(times, offsets);
      for (const p of prayers) {
        if (!NotificationHelper.isPrayerEnabled(settings, p.id)) {
          continue;
        }

        // Already prayed → no reminder needed for this date.
        if (NotificationHelper.isPrayerChecked(dayState, p.id)) {
          AppLogger.info('NotificationHelper',
            `Skipping ${p.name} on ${dateKey} — already prayed`);
          continue;
        }

        const prayerDate = NotificationHelper.parseToDate(p.time, day);
        if (prayerDate.getTime() + leadMinutes * 60 * 1000 <= nowMs) {
          continue;
        }

        const entry: CalendarReminderEntry = {
          title: NotificationHelper.prayTitle(p.name),
          startTime: prayerDate.getTime(),
          reminderMinutes: reminderMinutes,
          description: NotificationHelper.hadithFor(p.name)
        };
        entries.push(entry);
      }
    }

    if (entries.length === 0) {
      return {
        ok: true,
        scheduled: 0,
        errorCode: 0,
        errorMessage: 'nothing to schedule'
      };
    }

    const created = await CalendarReminderHelper.rescheduleAll(entries);
    AppLogger.info('NotificationHelper',
      `Calendar backend scheduled ${created} event(s)`);

    return {
      ok: created > 0,
      scheduled: created,
      errorCode: created > 0 ? 0 : -1,
      errorMessage: created > 0 ? '' : 'calendar addEvent failed'
    };
  }

  // ============================================================
  // AGENT BACKEND SCHEDULING
  // ============================================================

  private static async scheduleViaAgent(
    anchor: Date,
    nowMs: number,
    latitude: number,
    longitude: number,
    method: CalculationMethod,
    asrRule: AsrShadowRule,
    highLatRule: HighLatitudeRule,
    offsets: PrayerOffsets,
    settings: NotificationsSettings
  ): Promise<ScheduleResult> {
    AppLogger.info('NotificationHelper',
      `Scheduling agent reminders from ` +
        `${PrayerManager.getDateKeyForDate(anchor)} for ${DAYS_AHEAD} day(s)`);
    let scheduledCount = 0;
    let lastErrorCode = 0;
    let lastErrorMessage = '';

    for (let dayOffset = 0; dayOffset < DAYS_AHEAD; dayOffset++) {
      const day = new Date(anchor);
      day.setDate(day.getDate() + dayOffset);

      // Skip prayers already marked as prayed for this date.
      const dateKey = PrayerManager.getDateKeyForDate(day);
      const dayState: PrayerCheckState =
        PrayerManager.getCheckState(dateKey);

      let times: DailyPrayerTimes;
      try {
        times = PrayerTimeCalculator.calculateWithDeviceTimezone(
          day, latitude, longitude, method, asrRule, highLatRule
        );
      } catch (err) {
        const e = err as Error;
        AppLogger.warn('NotificationHelper',
          `Calculation failed for day ${dayOffset}: ${e.message}`);
        continue;
      }

      const dayResult = await NotificationHelper.scheduleAgentDay(
        day, dateKey, dayState, times, offsets, settings, nowMs
      );
      scheduledCount += dayResult.scheduled;
      if (!dayResult.ok) {
        lastErrorCode = dayResult.errorCode;
        lastErrorMessage = dayResult.errorMessage;
      }
    }

    AppLogger.info('NotificationHelper',
      `Agent backend scheduled ${scheduledCount}, lastError=${lastErrorCode}`);

    return {
      ok: scheduledCount > 0 || lastErrorCode === 0,
      scheduled: scheduledCount,
      errorCode: lastErrorCode,
      errorMessage: lastErrorMessage
    };
  }

  private static async scheduleAgentDay(
    day: Date,
    dateKey: string,
    dayState: PrayerCheckState,
    times: DailyPrayerTimes,
    offsets: PrayerOffsets,
    settings: NotificationsSettings,
    nowMs: number
  ): Promise<ScheduleResult> {
    const prayers = NotificationHelper.buildPrayerList(times, offsets);
    let count = 0;
    let lastErr = 0;
    let lastMsg = '';

    for (const p of prayers) {
      if (!NotificationHelper.isPrayerEnabled(settings, p.id)) {
        continue;
      }

      // Already prayed → no reminder needed for this date.
      if (NotificationHelper.isPrayerChecked(dayState, p.id)) {
        AppLogger.info('NotificationHelper',
          `Skipping ${p.name} on ${dateKey} — already prayed`);
        continue;
      }

      const prayerDate = NotificationHelper.parseToDate(p.time, day);
      if (prayerDate.getTime() <= nowMs) {
        continue;
      }

      const exactOk = await NotificationHelper.publishReminder(
        p.name, prayerDate, -1
      );
      if (exactOk) {
        count++;
      } else {
        lastErr = -1;
        lastMsg = `publish failed for ${p.name} exact`;
      }

      const before = settings.beforeMinutes;
      if (before > 0) {
        const beforeDate =
          new Date(prayerDate.getTime() - before * 60 * 1000);
        if (beforeDate.getTime() > nowMs) {
          const beforeOk = await NotificationHelper.publishReminder(
            p.name, beforeDate, before
          );
          if (beforeOk) {
            count++;
          } else {
            lastErr = -1;
            lastMsg = `publish failed for ${p.name} before`;
          }
        }
      }
    }

    return {
      ok: lastErr === 0,
      scheduled: count,
      errorCode: lastErr,
      errorMessage: lastMsg
    };
  }

  // ============================================================
  // AGENT REMINDER PUBLISH
  // ============================================================

  private static async publishReminder(
    prayerName: string,
    fireAt: Date,
    beforeMinutes: number
  ): Promise<boolean> {
    const detail = await NotificationHelper.publishReminderDetailed(
      prayerName, fireAt, beforeMinutes
    );
    return detail.ok;
  }

  private static async publishReminderDetailed(
    prayerName: string,
    fireAt: Date,
    beforeMinutes: number
  ): Promise<ScheduleResult> {
    const titleBase = NotificationHelper.prayTitle(prayerName);
    const isBefore = beforeMinutes > 0;

    const title = isBefore
      ? `${titleBase} \u2014 ${beforeMinutes} ${L.get('notif_minutes_suffix')}`
      : titleBase;
    const content = NotificationHelper.hadithFor(prayerName);

    const dismissLabel =
      NotificationHelper.safeTr('notif_dismiss', 'Dismiss');

    const reminder: reminderAgentManager.ReminderRequestCalendar = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
      dateTime: {
        year: fireAt.getFullYear(),
        month: fireAt.getMonth() + 1,
        day: fireAt.getDate(),
        hour: fireAt.getHours(),
        minute: fireAt.getMinutes(),
        second: fireAt.getSeconds()
      },
      title: title,
      content: content,
      expiredContent: content,
      slotType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
      notificationId: 0,
      snoozeTimes: 0,
      actionButton: [
        {
          title: dismissLabel,
          type: reminderAgentManager.ActionButtonType
            .ACTION_BUTTON_TYPE_CLOSE
        }
      ]
    };

    try {
      const id = await reminderAgentManager.publishReminder(reminder);
      AppLogger.info('NotificationHelper',
        `Published id=${id} for ${prayerName} at ${fireAt.toISOString()}`);
      return {
        ok: true,
        scheduled: 1,
        errorCode: 0,
        errorMessage: ''
      };
    } catch (err) {
      const error = err as BusinessError;
      AppLogger.error('NotificationHelper',
        `Publish FAILED for ${prayerName} at ${fireAt.toISOString()}: ` +
          `code=${error.code}, message=${error.message}`);
      return {
        ok: false,
        scheduled: 0,
        errorCode: error.code,
        errorMessage: NotificationHelper.describeError(
          error.code, error.message
        )
      };
    }
  }

  private static describeError(code: number, message: string): string {
    switch (code) {
      case 1700001:
        return '1700001 — Notifications are disabled. Enable them in Settings.';
      case 1700002:
        return '1700002 — No Agent-Powered Reminder quota. This capability ' +
          'must be approved in AppGallery Connect, then the app must ' +
          'be re-signed with the updated Profile.';
      case 1700003:
        return '1700003 — Reminder not found.';
      case 1700004:
        return '1700004 — Package name not found. Check that the bundle ' +
          'name matches AGC.';
      case 1700007:
        return '1700007 — Invalid parameters. Check the reminder date/time fields.';
      case 401:
        return '401 — Parameter error. Verify the reminder request shape ' +
          '(slotType, expiredContent, dateTime fields).';
      case 1600013:
        return '1600013 — Notification permission dialog issue. Grant permission ' +
          'in Settings first.';
      default:
        return `Error ${code}: ${message}`;
    }
  }

  // ============================================================
  // PER-PRAYER CONTENT
  // ============================================================

  private static prayTitle(prayerName: string): string {
    switch (prayerName) {
      case 'Fajr':
        return L.get('notif_pray_fajr');
      case 'Dhuhr':
        return L.get('notif_pray_dhuhr');
      case 'Asr':
        return L.get('notif_pray_asr');
      case 'Maghrib':
        return L.get('notif_pray_maghrib');
      case 'Isha':
        return L.get('notif_pray_isha');
      default:
        return prayerName;
    }
  }

  private static hadithFor(prayerName: string): string {
    switch (prayerName) {
      case 'Fajr':
        return L.get('hadith_fajr');
      case 'Dhuhr':
        return L.get('hadith_dhuhr');
      case 'Asr':
        return L.get('hadith_asr');
      case 'Maghrib':
        return L.get('hadith_maghrib');
      case 'Isha':
        return L.get('hadith_isha');
      default:
        return '';
    }
  }

  // ============================================================
  // SHARED HELPERS
  // ============================================================

  /**
   * True when the given prayer is marked as prayed in the given
   * check state. Used to skip reminders for prayers the user has
   * already performed on that date.
   */
  private static isPrayerChecked(
    state: PrayerCheckState,
    prayerId: string
  ): boolean {
    switch (prayerId) {
      case 'fajr':
        return state.fajr === true;
      case 'dhuhr':
        return state.dhuhr === true;
      case 'asr':
        return state.asr === true;
      case 'maghrib':
        return state.maghrib === true;
      case 'isha':
        return state.isha === true;
      default:
        return false;
    }
  }

  private static buildPrayerList(
    times: DailyPrayerTimes,
    offsets: PrayerOffsets
  ): PrayerNotificationItem[] {
    const fajr: PrayerNotificationItem = {
      id: 'fajr', name: 'Fajr', time: times.fajr
    };
    const dhuhr: PrayerNotificationItem = {
      id: 'dhuhr', name: 'Dhuhr', time: times.dhuhr
    };
    const asr: PrayerNotificationItem = {
      id: 'asr', name: 'Asr', time: times.asr
    };
    const maghrib: PrayerNotificationItem = {
      id: 'maghrib', name: 'Maghrib', time: times.maghrib
    };
    const isha: PrayerNotificationItem = {
      id: 'isha', name: 'Isha', time: times.isha
    };

    const list: PrayerNotificationItem[] = [fajr, dhuhr, asr, maghrib, isha];

    for (let i = 0; i < list.length; i++) {
      const p: PrayerNotificationItem = list[i];
      const off: number = NotificationHelper.offsetForPrayer(p.id, offsets);
      if (off !== 0) {
        p.time = NotificationHelper.offsetTimeString(p.time, off);
      }
    }
    return list;
  }

  private static offsetForPrayer(
    id: string, offsets: PrayerOffsets
  ): number {
    switch (id) {
      case 'fajr':
        return offsets.fajr;
      case 'dhuhr':
        return offsets.dhuhr;
      case 'asr':
        return offsets.asr;
      case 'maghrib':
        return offsets.maghrib;
      case 'isha':
        return offsets.isha;
      default:
        return 0;
    }
  }

  private static offsetTimeString(
    timeStr: string, offsetMinutes: number
  ): string {
    if (offsetMinutes === 0) {
      return timeStr;
    }
    const parts = timeStr.trim().split(' ');
    if (parts.length !== 2) {
      return timeStr;
    }
    const tp = parts[0].split(':');
    if (tp.length !== 2) {
      return timeStr;
    }

    let hours = parseInt(tp[0], 10);
    const minutes = parseInt(tp[1], 10);
    const period = parts[1].toUpperCase();
    if (isNaN(hours) || isNaN(minutes)) {
      return timeStr;
    }

    if (period === 'PM' && hours !== 12) {
      hours += 12;
    }
    if (period === 'AM' && hours === 12) {
      hours = 0;
    }

    let total = hours * 60 + minutes + offsetMinutes;
    total = ((total % 1440) + 1440) % 1440;

    const nh = Math.floor(total / 60);
    const nm = total % 60;
    const np = nh >= 12 ? 'PM' : 'AM';
    let dh = nh % 12;
    if (dh === 0) {
      dh = 12;
    }
    return `${dh}:${nm.toString().padStart(2, '0')} ${np}`;
  }

  private static parseToDate(timeStr: string, day: Date): Date {
    const result = new Date(day);
    result.setHours(0, 0, 0, 0);

    const trimmed = timeStr.trim();
    if (trimmed === '' || trimmed === '--:--') {
      return result;
    }

    const parts = trimmed.split(' ');
    if (parts.length !== 2) {
      return result;
    }

    const tp = parts[0].split(':');
    if (tp.length !== 2) {
      return result;
    }

    let hours = parseInt(tp[0], 10);
    const minutes = parseInt(tp[1], 10);
    const period = parts[1].toUpperCase();
    if (isNaN(hours) || isNaN(minutes)) {
      return result;
    }

    if (period === 'PM' && hours !== 12) {
      hours += 12;
    }
    if (period === 'AM' && hours === 12) {
      hours = 0;
    }

    result.setHours(hours, minutes, 0, 0);
    return result;
  }

  private static isPrayerEnabled(
    settings: NotificationsSettings, prayerId: string
  ): boolean {
    switch (prayerId) {
      case 'fajr':
        return settings.fajrEnabled;
      case 'dhuhr':
        return settings.dhuhrEnabled;
      case 'asr':
        return settings.asrEnabled;
      case 'maghrib':
        return settings.maghribEnabled;
      case 'isha':
        return settings.ishaEnabled;
      default:
        return false;
    }
  }

  private static localizedPrayerName(raw: string): string {
    switch (raw) {
      case 'Fajr':
        return L.get('prayer_fajr');
      case 'Dhuhr':
        return L.get('prayer_dhuhr');
      case 'Asr':
        return L.get('prayer_asr');
      case 'Maghrib':
        return L.get('prayer_maghrib');
      case 'Isha':
        return L.get('prayer_isha');
      default:
        return raw;
    }
  }

  private static safeTr(key: string, fallback: string): string {
    const value = L.get(key);
    return value === key ? fallback : value;
  }
}