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
} from '../utils/PrayerTimeCalculator';
import { LocationCache } from '../utils/LocationCache';
import { LocationMode } from '../models/SettingsModels';
import { L } from './LocalizationHelper';
import { AppLogger } from './AppLogger';
import { NOTIFICATIONS_ENABLED } from '../common/FeatureFlags';

/** How many days ahead to schedule. Older reminders renew on app open. */
const DAYS_AHEAD = 3;

export const MIN_BEFORE_MINUTES = 0;

export const MAX_BEFORE_MINUTES = 60;

export const STEP_BEFORE_MINUTES = 5;

/** A single prayer entry used when scheduling reminders. */
interface PrayerNotificationItem {
  id: string;
  name: string;
  time: string;
}

/** Result of a scheduling operation, surfaced to the UI for diagnostics. */
export interface ScheduleResult {
  ok: boolean;
  scheduled: number;
  errorCode: number;
  errorMessage: string;
}

/**
 * Schedules and cancels prayer notifications using the system
 * reminder agent. Reminders fire independently of the app process,
 * so the user receives them even if the app is closed.
 *
 * ─────────────────────────────────────────────────────────────
 * CURRENT STATUS: DISABLED
 * ─────────────────────────────────────────────────────────────
 * The Agent-Powered Reminder capability is not yet approved in
 * AppGallery Connect. Without approval, publishReminder() fails
 * with error code 1700002 ("The number of reminders exceeds the
 * limit" — actually means the app's quota is 0).
 *
 * Every public method in this class begins with a check on
 * NOTIFICATIONS_ENABLED (defined in common/FeatureFlags.ets).
 * While that flag is false, all scheduling is a no-op and the
 * Settings UI hides the Notifications category entirely.
 *
 * To re-enable after AGC approval:
 *   1. Set NOTIFICATIONS_ENABLED = true in FeatureFlags.ets
 *   2. Un-comment PUBLISH_AGENT_REMINDER in module.json5
 *   3. Re-add notification sections to PrivacyPolicy.ets and index.md
 *   4. Regenerate the signing Profile and re-sign the app
 *
 * Requires the "Agent-Powered Reminder" open capability to be
 * approved in AppGallery Connect.
 */
export class NotificationHelper {
  // ============================================================
  // PERMISSION
  // ============================================================

  static async requestPermission(context: common.UIAbilityContext): Promise<boolean> {
    if (!NOTIFICATIONS_ENABLED) {
      return false;
    }
    try {
      await notificationManager.requestEnableNotification(context);
      AppLogger.info('NotificationHelper', 'Permission granted');
      return true;
    } catch (err) {
      const error = err as BusinessError;
      AppLogger.warn('NotificationHelper',
        `Permission request failed: ${error.code} ${error.message}`);
      return false;
    }
  }

  static async isPermissionGranted(): Promise<boolean> {
    if (!NOTIFICATIONS_ENABLED) {
      return false;
    }
    try {
      return await notificationManager.isNotificationEnabled();
    } catch (err) {
      const error = err as BusinessError;
      AppLogger.warn('NotificationHelper',
        `isNotificationEnabled failed: ${error.code} ${error.message}`);
      return false;
    }
  }

  // ============================================================
  // CANCEL
  // ============================================================

  static async cancelAll(): Promise<void> {
    if (!NOTIFICATIONS_ENABLED) {
      return;
    }
    try {
      await reminderAgentManager.cancelAllReminders();
      AppLogger.info('NotificationHelper', 'All reminders cancelled');
    } catch (err) {
      const error = err as BusinessError;
      AppLogger.warn('NotificationHelper',
        `cancelAll failed: ${error.code} ${error.message}`);
    }
  }

  // ============================================================
  // TEST NOTIFICATION
  // ============================================================

  /**
   * Publish a single reminder 5 seconds from now, so the user (or a
   * reviewer) can immediately verify that the notification pipeline
   * works end-to-end without waiting for the next prayer time.
   */
  static async publishTestNotification(): Promise<ScheduleResult> {
    if (!NOTIFICATIONS_ENABLED) {
      AppLogger.info('NotificationHelper',
        'publishTestNotification skipped — notifications disabled by feature flag');
      const disabled: ScheduleResult = {
        ok: false,
        scheduled: 0,
        errorCode: -100,
        errorMessage: 'notifications disabled'
      };
      return disabled;
    }

    const now = new Date();
    const fireAt = new Date(now.getTime() + 5000);

    AppLogger.info('NotificationHelper',
      `Test notification requested — will fire at ${fireAt.toISOString()}`);

    const detail = await NotificationHelper.publishReminderDetailed('Fajr', fireAt, 0);

    const result: ScheduleResult = {
      ok: detail.ok,
      scheduled: detail.ok ? 1 : 0,
      errorCode: detail.errorCode,
      errorMessage: detail.errorMessage
    };
    return result;
  }

  // ============================================================
  // RESCHEDULE
  // ============================================================

  static async rescheduleAll(): Promise<ScheduleResult> {
    if (!NOTIFICATIONS_ENABLED) {
      AppLogger.info('NotificationHelper',
        'rescheduleAll skipped — notifications disabled by feature flag');
      const skipped: ScheduleResult = {
        ok: true,
        scheduled: 0,
        errorCode: 0,
        errorMessage: 'notifications disabled'
      };
      return skipped;
    }

    AppLogger.info('NotificationHelper', 'rescheduleAll started');

    await NotificationHelper.cancelAll();

    const settings: NotificationsSettings = await SettingsHelper.getNotificationSettings();
    if (!settings.masterEnabled) {
      AppLogger.info('NotificationHelper', 'Master disabled — nothing to schedule');
      const skipped: ScheduleResult = {
        ok: true,
        scheduled: 0,
        errorCode: 0,
        errorMessage: 'master disabled'
      };
      return skipped;
    }

    const granted = await NotificationHelper.isPermissionGranted();
    if (!granted) {
      AppLogger.warn('NotificationHelper', 'Permission not granted');
      const denied: ScheduleResult = {
        ok: false,
        scheduled: 0,
        errorCode: 1600013,
        errorMessage: 'notification permission not granted'
      };
      return denied;
    }

    // ---- Resolve location ----
    const mode = await SettingsHelper.getLocationMode();
    let latitude = 0;
    let longitude = 0;

    if (mode === LocationMode.MANUAL) {
      const coords = await SettingsHelper.getManualCoords();
      if (coords.lat === 0 && coords.lng === 0) {
        AppLogger.warn('NotificationHelper', 'No manual coordinates set');
        const noLoc: ScheduleResult = {
          ok: false,
          scheduled: 0,
          errorCode: -2,
          errorMessage: 'no manual coordinates set'
        };
        return noLoc;
      }
      latitude = coords.lat;
      longitude = coords.lng;
    } else {
      const cached = await LocationCache.load();
      if (!cached) {
        AppLogger.warn('NotificationHelper', 'No cached GPS location');
        const noCache: ScheduleResult = {
          ok: false,
          scheduled: 0,
          errorCode: -3,
          errorMessage: 'no cached GPS location'
        };
        return noCache;
      }
      latitude = cached.latitude;
      longitude = cached.longitude;
    }

    // ---- Resolve calculation params ----
    const data = await SettingsHelper.loadAll();
    const method: CalculationMethod = data.method;
    const asrRule: AsrShadowRule = data.asr;
    const highLatRule: HighLatitudeRule = await SettingsHelper.getHighLatRule();
    const offsets: PrayerOffsets = await SettingsHelper.getPrayerOffsets();

    // ---- Schedule per day ----
    const nowMs = Date.now();
    const anchor = new Date();
    anchor.setHours(0, 0, 0, 0);

    let scheduledCount = 0;
    let lastErrorCode = 0;
    let lastErrorMessage = '';

    for (let dayOffset = 0; dayOffset < DAYS_AHEAD; dayOffset++) {
      const day = new Date(anchor);
      day.setDate(day.getDate() + dayOffset);

      let times: DailyPrayerTimes;
      try {
        times = PrayerTimeCalculator.calculateWithDeviceTimezone(
          day, latitude, longitude, method, asrRule, highLatRule
        );
      } catch (err) {
        const error = err as Error;
        AppLogger.warn('NotificationHelper',
          `Calculation failed for day ${dayOffset}: ${error.message}`);
        continue;
      }

      const dayResult = await NotificationHelper.scheduleDay(
        day, times, offsets, settings, nowMs
      );
      scheduledCount += dayResult.scheduled;
      if (!dayResult.ok) {
        lastErrorCode = dayResult.errorCode;
        lastErrorMessage = dayResult.errorMessage;
      }
    }

    AppLogger.info('NotificationHelper',
      `Rescheduled ${scheduledCount} reminders, lastError=${lastErrorCode}`);

    const result: ScheduleResult = {
      ok: scheduledCount > 0 || lastErrorCode === 0,
      scheduled: scheduledCount,
      errorCode: lastErrorCode,
      errorMessage: lastErrorMessage
    };
    return result;
  }

  private static async scheduleDay(
    day: Date,
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

      const prayerDate = NotificationHelper.parseToDate(p.time, day);
      if (prayerDate.getTime() <= nowMs) {
        continue;
      }

      const exactOk = await NotificationHelper.publishReminder(p.name, prayerDate, -1);
      if (exactOk) {
        count++;
      } else {
        lastErr = -1;
        lastMsg = `publish failed for ${p.name} exact`;
      }

      const before = settings.beforeMinutes;
      if (before > 0) {
        const beforeDate = new Date(prayerDate.getTime() - before * 60 * 1000);
        if (beforeDate.getTime() > nowMs) {
          const beforeOk = await NotificationHelper.publishReminder(p.name, beforeDate, before);
          if (beforeOk) {
            count++;
          } else {
            lastErr = -1;
            lastMsg = `publish failed for ${p.name} before`;
          }
        }
      }
    }

    const result: ScheduleResult = {
      ok: lastErr === 0,
      scheduled: count,
      errorCode: lastErr,
      errorMessage: lastMsg
    };
    return result;
  }

  // ============================================================
  // REMINDER PUBLISH
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
    const localizedPrayer = NotificationHelper.localizedPrayerName(prayerName);

    const isBefore = beforeMinutes > 0;
    const title = isBefore
      ? `${localizedPrayer} — ${L.get('notif_before_title')}`
      : `${localizedPrayer} — ${L.get('notif_exact_title')}`;

    let content: string;
    if (isBefore) {
      content = `${localizedPrayer} ${L.get('notif_before_content')} ` +
        `${beforeMinutes} ${L.get('notif_minutes_suffix')}`;
    } else {
      content = `${L.get('notif_exact_content')} ${localizedPrayer}`;
    }

    // Localized dismiss button label. Falls back to 'Dismiss' if the
    // key is missing from the localization table.
    const dismissLabel = NotificationHelper.safeTr('notif_dismiss', 'Dismiss');

    const reminder: reminderAgentManager.ReminderRequestCalendar = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
      dateTime: {
        year: fireAt.getFullYear(),
        month: fireAt.getMonth() + 1, // API month is 1-12
        day: fireAt.getDate(),
        hour: fireAt.getHours(),
        minute: fireAt.getMinutes(),
        second: fireAt.getSeconds()
      },
      title: title,
      content: content,
      // expiredContent is required by the runtime validator on some
      // API levels. Mirrors content so the reminder still reads
      // correctly if the user never interacts with it.
      expiredContent: content,
      // slotType is required in practice. Omitting it causes
      // publishReminder() to fail with code=401 (Parameter error),
      // as observed during on-device debugging.
      slotType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
      notificationId: 0,
      snoozeTimes: 0,
      actionButton: [
        {
          title: dismissLabel,
          type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE
        }
      ]
    };

    try {
      const id = await reminderAgentManager.publishReminder(reminder);
      AppLogger.info('NotificationHelper',
        `Published id=${id} for ${prayerName} at ${fireAt.toISOString()}`);
      const ok: ScheduleResult = {
        ok: true,
        scheduled: 1,
        errorCode: 0,
        errorMessage: ''
      };
      return ok;
    } catch (err) {
      const error = err as BusinessError;
      AppLogger.error('NotificationHelper',
        `Publish FAILED for ${prayerName} at ${fireAt.toISOString()}: ` +
          `code=${error.code}, message=${error.message}`);
      const fail: ScheduleResult = {
        ok: false,
        scheduled: 0,
        errorCode: error.code,
        errorMessage: NotificationHelper.describeError(error.code, error.message)
      };
      return fail;
    }
  }

  /** Turns a raw error code into a short human-readable hint. */
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
  // HELPERS
  // ============================================================

  private static buildPrayerList(
    times: DailyPrayerTimes,
    offsets: PrayerOffsets
  ): PrayerNotificationItem[] {
    const fajr: PrayerNotificationItem = { id: 'fajr', name: 'Fajr', time: times.fajr };
    const dhuhr: PrayerNotificationItem = { id: 'dhuhr', name: 'Dhuhr', time: times.dhuhr };
    const asr: PrayerNotificationItem = { id: 'asr', name: 'Asr', time: times.asr };
    const maghrib: PrayerNotificationItem = { id: 'maghrib', name: 'Maghrib', time: times.maghrib };
    const isha: PrayerNotificationItem = { id: 'isha', name: 'Isha', time: times.isha };

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

  private static offsetForPrayer(id: string, offsets: PrayerOffsets): number {
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

  /** Replicates PrayerManager.offsetTime without importing it (avoids a cycle). */
  private static offsetTimeString(timeStr: string, offsetMinutes: number): string {
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

  /** Parse "4:24 AM" into a Date on the given day. */
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

  private static isPrayerEnabled(settings: NotificationsSettings, prayerId: string): boolean {
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

  /**
   * Safe localization lookup: returns the translated string if the
   * key exists, otherwise the supplied fallback. Used for keys that
   * may not be present in older localization tables (e.g.
   * 'notif_dismiss').
   */
  private static safeTr(key: string, fallback: string): string {
    const value = L.get(key);
    return value === key ? fallback : value;
  }
}