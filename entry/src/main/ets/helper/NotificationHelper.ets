// entry/src/main/ets/helper/NotificationHelper.ets

import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { notificationManager } from '@kit.NotificationKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { SettingsHelper, NotificationsSettings, PrayerOffsets } from './SettingsHelper';
import {
  PrayerTimeCalculator,
  CalculationMethod,
  AsrShadowRule,
  DailyPrayerTimes
} from '../utils/PrayerTimeCalculator';
import { LocationCache } from '../utils/LocationCache';
import { LocationMode } from '../models/SettingsModels';
import { L } from './LocalizationHelper';

/** How many days ahead to schedule. Older reminders renew on app open. */
const DAYS_AHEAD = 3;

/** Bounds for the "notify before" stepper. */
export const MIN_BEFORE_MINUTES = 0;
export const MAX_BEFORE_MINUTES = 60;
export const STEP_BEFORE_MINUTES = 5;

/** A single prayer entry used when scheduling reminders. */
interface PrayerNotificationItem {
  id: string;
  name: string;
  time: string;
}

/**
 * Schedules and cancels prayer notifications using the system
 * reminder agent. Reminders fire independently of the app process,
 * so the user receives them even if the app is closed.
 */
export class NotificationHelper {

  // ============================================================
  // PERMISSION
  // ============================================================

  static async requestPermission(context: common.UIAbilityContext): Promise<boolean> {
    try {
      await notificationManager.requestEnableNotification(context);
      return true;
    } catch (err) {
      const error = err as BusinessError;
      console.warn(`[NotificationHelper] permission request failed: ${error.code} ${error.message}`);
      return false;
    }
  }

  static async isPermissionGranted(): Promise<boolean> {
    try {
      return await notificationManager.isNotificationEnabled();
    } catch (err) {
      return false;
    }
  }

  // ============================================================
  // CANCEL
  // ============================================================

  static async cancelAll(): Promise<void> {
    try {
      await reminderAgentManager.cancelAllReminders();
      console.info('[NotificationHelper] all reminders cancelled');
    } catch (err) {
      const error = err as BusinessError;
      console.warn(`[NotificationHelper] cancelAll failed: ${error.code} ${error.message}`);
    }
  }

  // ============================================================
  // RESCHEDULE
  // ============================================================
  //
  // Full rebuild of the notification queue. Called on app open and
  // whenever a relevant setting changes (location, method, language,
  // notification toggles).

  static async rescheduleAll(): Promise<void> {
    // Always start from a clean slate to avoid duplicates.
    await NotificationHelper.cancelAll();

    const settings: NotificationsSettings = await SettingsHelper.getNotificationSettings();
    if (!settings.masterEnabled) {
      console.info('[NotificationHelper] master disabled, nothing to schedule');
      return;
    }

    const granted = await NotificationHelper.isPermissionGranted();
    if (!granted) {
      console.info('[NotificationHelper] permission not granted, nothing to schedule');
      return;
    }

    // ---- Resolve location ----
    const mode = await SettingsHelper.getLocationMode();
    let latitude = 0;
    let longitude = 0;

    if (mode === LocationMode.MANUAL) {
      const coords = await SettingsHelper.getManualCoords();
      if (coords.lat === 0 && coords.lng === 0) return;
      latitude = coords.lat;
      longitude = coords.lng;
    } else {
      const cached = await LocationCache.load();
      if (!cached) {
        console.info('[NotificationHelper] no cached location, skipping');
        return;
      }
      latitude = cached.latitude;
      longitude = cached.longitude;
    }

    // ---- Resolve calculation params ----
    const data = await SettingsHelper.loadAll();
    const method: CalculationMethod = data.method;
    const asrRule: AsrShadowRule = data.asr;
    const offsets: PrayerOffsets = await SettingsHelper.getPrayerOffsets();

    // ---- Schedule per day ----
    const now = Date.now();
    const anchor = new Date();
    anchor.setHours(0, 0, 0, 0);

    let scheduledCount = 0;

    const highLatRule = await SettingsHelper.getHighLatRule();
    for (let dayOffset = 0; dayOffset < DAYS_AHEAD; dayOffset++) {
      const day = new Date(anchor);
      day.setDate(day.getDate() + dayOffset);

      let times: DailyPrayerTimes;
      try {
        times = PrayerTimeCalculator.calculateWithDeviceTimezone(
          day, latitude, longitude, method, asrRule, highLatRule
        );
      } catch (err) {
        continue;
      }

      scheduledCount += await NotificationHelper.scheduleDay(
        day, times, offsets, settings, now
      );
    }

    console.info(`[NotificationHelper] scheduled ${scheduledCount} reminders`);
  }

  /**
   * Schedule notifications for a single day. Returns the count of
   * reminders successfully published.
   */
  private static async scheduleDay(
    day: Date,
    times: DailyPrayerTimes,
    offsets: PrayerOffsets,
    settings: NotificationsSettings,
    nowMs: number
  ): Promise<number> {
    const prayers = NotificationHelper.buildPrayerList(times, offsets);
    let count = 0;

    for (const p of prayers) {
      if (!NotificationHelper.isPrayerEnabled(settings, p.id)) continue;

      const prayerDate = NotificationHelper.parseToDate(p.time, day);
      if (prayerDate.getTime() <= nowMs) continue;

      // ---- Exact-time reminder ----
      const exactOk = await NotificationHelper.publishReminder(p.name, prayerDate, -1);
      if (exactOk) count++;

      // ---- Before reminder ----
      const before = settings.beforeMinutes;
      if (before > 0) {
        const beforeDate = new Date(prayerDate.getTime() - before * 60 * 1000);
        if (beforeDate.getTime() > nowMs) {
          const beforeOk = await NotificationHelper.publishReminder(p.name, beforeDate, before);
          if (beforeOk) count++;
        }
      }
    }

    return count;
  }

  // ============================================================
  // REMINDER PUBLISH
  // ============================================================

  private static async publishReminder(
    prayerName: string,
    fireAt: Date,
    beforeMinutes: number
  ): Promise<boolean> {
    const localizedPrayer = NotificationHelper.localizedPrayerName(prayerName);

    // Build title and content
    const isBefore = beforeMinutes > 0;
    const title = isBefore
      ? `${localizedPrayer} — ${L.get('notif_before_title')}`
      : `${localizedPrayer} — ${L.get('notif_exact_title')}`;

    let content: string;
    if (isBefore) {
      content = `${localizedPrayer} ${L.get('notif_before_content')} ${beforeMinutes} ${L.get('notif_minutes_suffix')}`;
    } else {
      content = `${L.get('notif_exact_content')} ${localizedPrayer}`;
    }

    const reminder: reminderAgentManager.ReminderRequestCalendar = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
      dateTime: {
        year: fireAt.getFullYear(),
        month: fireAt.getMonth() + 1,
        day: fireAt.getDate(),
        hour: fireAt.getHours(),
        minute: fireAt.getMinutes(),
        second: 0
      },
      title: title,
      content: content,
      notificationId: 0,
      snoozeTimes: 0,
      actionButton: [
        {
          title: 'Dismiss',
          type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE
        }
      ]
    };

    try {
      await reminderAgentManager.publishReminder(reminder);
      return true;
    } catch (err) {
      const error = err as BusinessError;
      console.warn(`[NotificationHelper] publish failed for ${prayerName}: ${error.code} ${error.message}`);
      return false;
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  /** The 5 prayers in order with their localized display names. */
  /** The 5 prayers in order with their localized display names. */
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

    // Apply user offsets
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
      case 'fajr':    return offsets.fajr;
      case 'dhuhr':   return offsets.dhuhr;
      case 'asr':     return offsets.asr;
      case 'maghrib': return offsets.maghrib;
      case 'isha':    return offsets.isha;
      default:        return 0;
    }
  }

  /** Replicates PrayerManager.offsetTime without importing it (avoids a cycle). */
  private static offsetTimeString(timeStr: string, offsetMinutes: number): string {
    if (offsetMinutes === 0) return timeStr;
    const parts = timeStr.trim().split(' ');
    if (parts.length !== 2) return timeStr;
    const tp = parts[0].split(':');
    if (tp.length !== 2) return timeStr;

    let hours = parseInt(tp[0], 10);
    const minutes = parseInt(tp[1], 10);
    const period = parts[1].toUpperCase();
    if (isNaN(hours) || isNaN(minutes)) return timeStr;

    if (period === 'PM' && hours !== 12) hours += 12;
    if (period === 'AM' && hours === 12) hours = 0;

    let total = hours * 60 + minutes + offsetMinutes;
    total = ((total % 1440) + 1440) % 1440;

    const nh = Math.floor(total / 60);
    const nm = total % 60;
    const np = nh >= 12 ? 'PM' : 'AM';
    let dh = nh % 12;
    if (dh === 0) dh = 12;
    return `${dh}:${nm.toString().padStart(2, '0')} ${np}`;
  }

  /** Parse "4:24 AM" into a Date on the given day. */
  private static parseToDate(timeStr: string, day: Date): Date {
    const result = new Date(day);
    result.setHours(0, 0, 0, 0);

    const trimmed = timeStr.trim();
    if (trimmed === '' || trimmed === '--:--') return result;

    const parts = trimmed.split(' ');
    if (parts.length !== 2) return result;

    const tp = parts[0].split(':');
    if (tp.length !== 2) return result;

    let hours = parseInt(tp[0], 10);
    const minutes = parseInt(tp[1], 10);
    const period = parts[1].toUpperCase();
    if (isNaN(hours) || isNaN(minutes)) return result;

    if (period === 'PM' && hours !== 12) hours += 12;
    if (period === 'AM' && hours === 12) hours = 0;

    result.setHours(hours, minutes, 0, 0);
    return result;
  }

  private static isPrayerEnabled(settings: NotificationsSettings, prayerId: string): boolean {
    switch (prayerId) {
      case 'fajr':    return settings.fajrEnabled;
      case 'dhuhr':   return settings.dhuhrEnabled;
      case 'asr':     return settings.asrEnabled;
      case 'maghrib': return settings.maghribEnabled;
      case 'isha':    return settings.ishaEnabled;
      default:        return false;
    }
  }

  private static localizedPrayerName(raw: string): string {
    switch (raw) {
      case 'Fajr':    return L.get('prayer_fajr');
      case 'Dhuhr':   return L.get('prayer_dhuhr');
      case 'Asr':     return L.get('prayer_asr');
      case 'Maghrib': return L.get('prayer_maghrib');
      case 'Isha':    return L.get('prayer_isha');
      default:        return raw;
    }
  }
}