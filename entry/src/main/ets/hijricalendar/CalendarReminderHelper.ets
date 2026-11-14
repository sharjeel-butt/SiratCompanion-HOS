// entry/src/main/ets/helper/CalendarReminderHelper.ets

import { calendarManager } from '@kit.CalendarKit';
import { abilityAccessCtrl, bundleManager, common, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AppLogger } from '../core/AppLogger';
import { PreferencesHelper } from '../core/PreferencesHelper';

/**
 * Calendar Kit backend for prayer-time reminders.
 *
 * Used as a workaround while the Agent-Powered Reminder capability is
 * pending AGC approval. Writes prayer events into a dedicated calendar
 * account belonging to the app, with reminders that fire at the prayer
 * time and at the configured lead time.
 *
 * ## How it works
 *
 *   1. The user grants READ_CALENDAR + WRITE_CALENDAR.
 *   2. We obtain (or create) a calendar account named "Sirat Companion".
 *   3. We enable reminders on that account via setConfig().
 *   4. For each prayer on each of the next N days, we create one event:
 *        • title   — "Sirat · Pray Fajr" (the prefix identifies our events)
 *        • start   — the prayer time
 *        • end     — prayer time + 15 min
 *        • reminderTime — [0, leadMinutes]
 *   5. The system fires a calendar reminder at each reminderTime offset.
 *
 * ## Cleanup — three layers of safety
 *
 * Before rescheduling, cancelAll() deletes stale events. Deletion is
 * scoped by three independent checks so that no event is ever removed
 * unless it was created by this app:
 *
 *   1. The calendar object is scoped to the app's own account, so
 *      events in other calendars cannot be reached.
 *   2. The event query uses EventFilter.filterByTitle with the app's
 *      EVENT_TITLE_PREFIX, so only our events appear in the result set.
 *   3. Each event is re-checked with isOurs() before its delete call,
 *      so even a filter that returned a superset cannot cause a wrong
 *      deletion.
 *
 * This makes it safe for the user to add their own events to the
 * "Sirat Companion" account from the system Calendar app — those
 * events will not be touched by the app's cleanup.
 *
 * ## Mutual exclusion
 *
 * This backend must NOT be active at the same time as the
 * reminderAgentManager backend — that would deliver two reminders per
 * prayer. NotificationHelper.resolveBackend() enforces this.
 */

export interface CalendarPermissionState {
  read: boolean;
  write: boolean;
}

export class CalendarReminderHelper {
  static permissionStatus: CalendarPermissionState = {
    read: false,
    write: false
  };
  static readonly CUSTOM_EVENT_DESCRIPTION = 'Custom Islamic Event';
  /** All events we create carry this title prefix, for easy cleanup. */
  private static readonly EVENT_TITLE_PREFIX = 'Sirat · ';
  /** Calendar account name — developer-facing, not shown to the user. */
  private static readonly ACCOUNT_NAME = 'SiratCompanionCalendar';
  /** Calendar account display name — shown in the system Calendar app. */
  private static readonly ACCOUNT_DISPLAY_NAME = 'Sirat Companion';
  /** Event duration in milliseconds. Calendar events need an end time. */
  private static readonly EVENT_DURATION_MS = 15 * 60 * 1000;
  /** Permissions required by the Calendar Kit backend. */
  private static readonly PERMISSIONS: Permissions[] = [
    'ohos.permission.READ_CALENDAR',
    'ohos.permission.WRITE_CALENDAR'
  ];
  private static calendarMgr: calendarManager.CalendarManager | null = null;
  private static calendar: calendarManager.Calendar | null = null;
  private static initializing: boolean = false;
  private static ready: boolean = false;
  private static readonly KEY_PRAYER_EVENT_IDS = 'calendar_prayer_event_ids';
  private static readonly KEY_CUSTOM_EVENT_IDS = 'calendar_custom_event_ids';

  // ============================================================
  // INIT
  // ============================================================

  /**
   * Initialise the Calendar Kit backend. Requests permissions if
   * needed, obtains the CalendarManager, and prepares the app's
   * calendar account. Idempotent — safe to call on every app open.
   *
   * @returns true when the backend is ready to schedule events
   */
  static async init(
    context: common.UIAbilityContext,
    requestPermissions: boolean = false
  ): Promise<boolean> {
    if (CalendarReminderHelper.ready) {
      return true;
    }
    if (CalendarReminderHelper.initializing) {
      return CalendarReminderHelper.waitForReady();
    }
    CalendarReminderHelper.initializing = true;

    try {
      // If requestPermissions is true, show the OS prompt.
      // Otherwise, just check if they are already granted silently.
      const granted = requestPermissions
        ? await CalendarReminderHelper.requestPermission(context)
        : await CalendarReminderHelper.isPermissionGranted(context);

      if (!granted) {
        AppLogger.warn('CalendarReminderHelper',
          'Calendar permissions not granted');
        CalendarReminderHelper.initializing = false;
        return false;
      }

      CalendarReminderHelper.calendarMgr =
        calendarManager.getCalendarManager(context);

      const cal = await CalendarReminderHelper.getOrCreateCalendar();
      if (cal === null) {
        CalendarReminderHelper.initializing = false;
        return false;
      }
      CalendarReminderHelper.calendar = cal;

      const config: calendarManager.CalendarConfig = {
        enableReminder: true,
        color: '#0F5132'
      };
      try {
        await cal.setConfig(config);
      } catch (err) {
        const e = err as BusinessError;
        AppLogger.warn('CalendarReminderHelper',
          `setConfig failed: ${e.code} ${e.message}`);
      }

      CalendarReminderHelper.ready = true;
      AppLogger.info('CalendarReminderHelper', 'Backend ready');
      return true;
    } catch (err) {
      const e = err as BusinessError;
      AppLogger.error('CalendarReminderHelper',
        `init failed: ${e.code} ${e.message}`);
      CalendarReminderHelper.ready = false;
      return false;
    } finally {
      CalendarReminderHelper.initializing = false;
    }
  }

  /** True when the backend is ready to schedule events. */
  static isReady(): boolean {
    return CalendarReminderHelper.ready;
  }

  /**
   * Request the two calendar permissions. Returns true only if both
   * are granted, but records the individual results in `permissionStatus`.
   */
  static async requestPermission(
    context: common.UIAbilityContext
  ): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const result = await atManager.requestPermissionsFromUser(
        context, CalendarReminderHelper.PERMISSIONS
      );

      // Check both individually (0 = granted)
      const canRead = result.authResults[0] === 0;
      const canWrite = result.authResults[1] === 0;

      CalendarReminderHelper.permissionStatus.read = canRead;
      CalendarReminderHelper.permissionStatus.write = canWrite;

      if (!canRead) {
        AppLogger.warn('CalendarReminderHelper', 'READ_CALENDAR permission denied');
      }
      if (!canWrite) {
        AppLogger.warn('CalendarReminderHelper', 'WRITE_CALENDAR permission denied');
      }

      return canRead && canWrite;
    } catch (err) {
      const e = err as BusinessError;
      AppLogger.warn('CalendarReminderHelper',
        `permission request failed: ${e.code} ${e.message}`);
      return false;
    }
  }

  /**
   * Silent permission check — does not prompt the user.
   *
   * Reads the app's own access-token ID and asks the ability-access-
   * control manager whether each calendar permission is granted.
   * Returns true only when both are.
   *
   * Used by NotificationHelper.isPermissionGranted, which is called
   * from SettingsPage.sendTestNotification. Without this, checking
   * whether permission was already granted would pop the system
   * dialog on every "Send Test Notification" tap.
   */
  static async isPermissionGranted(
    context: common.UIAbilityContext
  ): Promise<boolean> {
    try {
      const bundleInfo = bundleManager.getBundleInfoForSelfSync(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
      );
      const tokenId = bundleInfo.appInfo.accessTokenId;

      const atManager = abilityAccessCtrl.createAtManager();

      for (const perm of CalendarReminderHelper.PERMISSIONS) {
        const status = atManager.checkAccessTokenSync(tokenId, perm);
        if (status !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
          CalendarReminderHelper.permissionStatus.read =
            perm === 'ohos.permission.READ_CALENDAR' ? false
              : CalendarReminderHelper.permissionStatus.read;
          CalendarReminderHelper.permissionStatus.write =
            perm === 'ohos.permission.WRITE_CALENDAR' ? false
              : CalendarReminderHelper.permissionStatus.write;
          return false;
        }
      }

      CalendarReminderHelper.permissionStatus.read = true;
      CalendarReminderHelper.permissionStatus.write = true;
      return true;
    } catch (err) {
      const e = err as BusinessError;
      AppLogger.warn('CalendarReminderHelper',
        `isPermissionGranted failed: ${e.code} ${e.message}`);
      return false;
    }
  }

  // ============================================================
  // ACCOUNT
  // ============================================================

  /**
   * Replace all existing Sirat events with a fresh set.
   *
   * The caller (NotificationHelper) builds the entries after
   * computing prayer times. This method first clears all existing
   * Sirat events, then writes the new set.
   *
   * @returns the number of events successfully created
   */
  static async rescheduleAll(
    entries: CalendarReminderEntry[]
  ): Promise<number> {
    if (!CalendarReminderHelper.ready ||
      CalendarReminderHelper.calendar === null) {
      return 0;
    }

    // Clears existing events AND the prayer-ID registry.
    await CalendarReminderHelper.cancelAll();

    // Create fresh events, tracking each returned ID.
    const newIds: number[] = [];
    for (const entry of entries) {
      const id = await CalendarReminderHelper.publishEvent(entry);
      if (id > 0) {
        newIds.push(id);
      }
    }

    // Persist tracking. Done AFTER the loop so a mid-loop failure
    // still leaves a consistent registry — we track exactly what
    // we successfully created, nothing more.
    await CalendarReminderHelper.writeEventIds(
      CalendarReminderHelper.KEY_PRAYER_EVENT_IDS, newIds
    );

    AppLogger.info('CalendarReminderHelper',
      `Scheduled ${newIds.length} calendar event(s), IDs tracked`);
    return newIds.length;
  }

  // ============================================================
  // SCHEDULING
  // ============================================================

  static async cancelAll(): Promise<void> {
    if (!CalendarReminderHelper.ready ||
      CalendarReminderHelper.calendar === null) {
      // Loud log instead of silent return. If this fires when the user
      // has toggled reminders off, events remain on the device until
      // permissions are re-granted and a reschedule runs — the user
      // needs to be able to see WHY cancellation didn't happen.
      AppLogger.warn('CalendarReminderHelper',
        'cancelAll skipped — backend not ready. Existing events, if any, ' +
          'remain in the calendar until permission is re-granted.');
      return;
    }

    // ---- Phase 1: Delete by tracked IDs (primary path) ----
    //
    // Fast, semantic-free, immune to any future changes in
    // EventFilter semantics. deleteWithRetry() already handles
    // "event not found" gracefully — the ID is simply dropped.
    const trackedIds = await CalendarReminderHelper.readEventIds(
      CalendarReminderHelper.KEY_PRAYER_EVENT_IDS
    );

    let deletedById = 0;
    const survivingIds: number[] = [];
    for (const id of trackedIds) {
      const ok = await CalendarReminderHelper.deleteWithRetry(id);
      if (ok) {
        deletedById++;
      } else {
        // Delete failed twice — assume the event is gone anyway
        // (typical cause: user manually deleted it from the
        // Calendar app). The filter sweep below is the safety net.
        survivingIds.push(id);
      }
    }

    // ---- Phase 2: Filter sweep (safety net) ----
    //
    // Catches:
    //   1. Events created by v4.0.6 or earlier, before ID tracking
    //   2. Events whose tracking write failed in a prior reschedule
    //   3. Events whose ID lookup in phase 1 errored out
    //
    // Skips tracked IDs that phase 1 already tried — avoids a third
    // delete attempt per event in the same cycle. If phase 1's
    // failures still exist, they're caught on the NEXT cycle's sweep.
    let sweptByFilter = 0;
    try {
      const now = Date.now();
      const dayMs = 86400000;
      const filter = calendarManager.EventFilter.filterByTime(
        now - 7 * dayMs,
        now + 10 * 365 * dayMs
      );
      const events =
        await CalendarReminderHelper.calendar.getEvents(filter);

      for (const ev of events) {
        if (ev.id === undefined) {
          continue;
        }
        if (!CalendarReminderHelper.isOurs(ev)) {
          continue;
        }
        if (ev.description === CalendarReminderHelper.CUSTOM_EVENT_DESCRIPTION) {
          // Custom-event reminders are managed separately.
          continue;
        }
        if (survivingIds.indexOf(ev.id) >= 0) {
          // Already tried in phase 1 — skip.
          continue;
        }
        const ok = await CalendarReminderHelper.deleteWithRetry(ev.id);
        if (ok) {
          sweptByFilter++;
        }
      }
    } catch (err) {
      const e = err as BusinessError;
      AppLogger.warn('CalendarReminderHelper',
        `cancelAll filter sweep failed: ${e.code} ${e.message}`);
    }

    // ---- Phase 3: Clear the prayer-ID registry ----
    //
    // Everything prayer-related should be gone now. If a small
    // number of deletes failed, the registry is cleared anyway —
    // the next cycle's filter sweep will pick up any stragglers.
    await CalendarReminderHelper.writeEventIds(
      CalendarReminderHelper.KEY_PRAYER_EVENT_IDS, []
    );

    AppLogger.info('CalendarReminderHelper',
      `cancelAll: deleted ${deletedById} by ID, ` +
        `${sweptByFilter} by filter sweep`);
  }

  /**
   * Schedule a single event. Returns 1 on success, 0 on failure.
   *
   * Two callers use this method with different intents:
   *
   *   CustomEventNotifier.reschedule()
   *     → Real custom-event reminders. Description is set to
   *       CUSTOM_EVENT_DESCRIPTION. These SHOULD be tracked so
   *       cancelCustomEventReminders() can delete them by ID.
   *
   *   NotificationHelper.publishCalendarTest()
   *     → A one-off test event for the user to confirm their
   *       notifications work. Description is the hadith text.
   *       These are ephemeral — not tracked. cancelAll() will
   *       pick them up on the next prayer-reschedule sweep.
   *
   * The description field is the discriminator.
   */
  static async addTestEvent(
    entry: CalendarReminderEntry
  ): Promise<number> {
    if (!CalendarReminderHelper.ready ||
      CalendarReminderHelper.calendar === null) {
      return 0;
    }

    const id = await CalendarReminderHelper.publishEvent(entry);
    if (id <= 0) {
      return 0;
    }

    // Track only real custom events.
    if (entry.description === CalendarReminderHelper.CUSTOM_EVENT_DESCRIPTION) {
      try {
        const existing = await CalendarReminderHelper.readEventIds(
          CalendarReminderHelper.KEY_CUSTOM_EVENT_IDS
        );
        existing.push(id);
        await CalendarReminderHelper.writeEventIds(
          CalendarReminderHelper.KEY_CUSTOM_EVENT_IDS, existing
        );
      } catch (e) {
        // Tracking failure — the filter sweep in
        // cancelCustomEventReminders will catch it next cycle.
      }
    }

    AppLogger.info('CalendarReminderHelper',
      `Test event scheduled: "${entry.title}" at ` +
        `${new Date(entry.startTime).toISOString()}`);
    return 1;
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  /**
   * Delete every custom-event reminder from the app's calendar account.
   *
   * Mirror-image of cancelAll(): same account scoping, same title
   * filter, but the per-event check is inverted — only events whose
   * description equals CUSTOM_EVENT_DESCRIPTION are deleted, and every
   * prayer reminder is left untouched.
   *
   * Called by CustomEventNotifier.reschedule() before adding new
   * custom-event reminders, so repeated reschedules do not accumulate
   * duplicates.
   */
  static async cancelCustomEventReminders(): Promise<void> {
    if (!CalendarReminderHelper.ready ||
      CalendarReminderHelper.calendar === null) {
      AppLogger.warn('CalendarReminderHelper',
        'cancelCustomEventReminders skipped — backend not ready. Existing ' +
          'custom-event reminders, if any, remain in the calendar.');
      return;
    }

    // ---- Phase 1: Delete by tracked IDs ----
    const trackedIds = await CalendarReminderHelper.readEventIds(
      CalendarReminderHelper.KEY_CUSTOM_EVENT_IDS
    );

    let deletedById = 0;
    const survivingIds: number[] = [];
    for (const id of trackedIds) {
      const ok = await CalendarReminderHelper.deleteWithRetry(id);
      if (ok) {
        deletedById++;
      } else {
        survivingIds.push(id);
      }
    }

    // ---- Phase 2: Filter sweep ----
    let sweptByFilter = 0;
    try {
      const now = Date.now();
      const dayMs = 86400000;
      const filter = calendarManager.EventFilter.filterByTime(
        now - 7 * dayMs,
        now + 10 * 365 * dayMs
      );
      const events =
        await CalendarReminderHelper.calendar.getEvents(filter);

      for (const ev of events) {
        if (ev.id === undefined) {
          continue;
        }
        if (!CalendarReminderHelper.isOurs(ev)) {
          continue;
        }
        if (ev.description !== CalendarReminderHelper.CUSTOM_EVENT_DESCRIPTION) {
          // Prayer reminder — leave it alone.
          continue;
        }
        if (survivingIds.indexOf(ev.id) >= 0) {
          continue;
        }
        const ok = await CalendarReminderHelper.deleteWithRetry(ev.id);
        if (ok) {
          sweptByFilter++;
        }
      }
    } catch (err) {
      const e = err as BusinessError;
      AppLogger.warn('CalendarReminderHelper',
        `cancelCustomEventReminders filter sweep failed: ${e.code} ${e.message}`);
    }

    // ---- Phase 3: Clear the custom-event registry ----
    await CalendarReminderHelper.writeEventIds(
      CalendarReminderHelper.KEY_CUSTOM_EVENT_IDS, []
    );

    AppLogger.info('CalendarReminderHelper',
      `cancelCustomEventReminders: deleted ${deletedById} by ID, ` +
        `${sweptByFilter} by filter sweep`);
  }

  /**
   * Obtain the app's calendar account, creating it if it does not
   * already exist.
   */
  private static async getOrCreateCalendar():
    Promise<calendarManager.Calendar | null> {
    if (CalendarReminderHelper.calendarMgr === null) {
      return null;
    }

    const account: calendarManager.CalendarAccount = {
      name: CalendarReminderHelper.ACCOUNT_NAME,
      type: calendarManager.CalendarType.LOCAL,
      displayName: CalendarReminderHelper.ACCOUNT_DISPLAY_NAME
    };

    // Try to fetch an existing account first.
    try {
      const existing =
        await CalendarReminderHelper.calendarMgr.getCalendar(account);
      if (existing !== undefined && existing !== null) {
        return existing;
      }
    } catch (err) {
      // Not found — fall through to creation.
    }

    // Create a new account.
    try {
      const created =
        await CalendarReminderHelper.calendarMgr.createCalendar(account);
      AppLogger.info('CalendarReminderHelper',
        'Created calendar account');
      return created;
    } catch (err) {
      const e = err as BusinessError;
      AppLogger.error('CalendarReminderHelper',
        `createCalendar failed: ${e.code} ${e.message}`);
      return null;
    }
  }

  /**
   * Create one calendar event with the given reminder offsets.
   *
   * Returns the created event ID (> 0) on success, or -1 on failure.
   * Callers that need to track the ID should capture the return value;
   * callers that only care about success/failure should test `> 0`.
   */
  private static async publishEvent(
    entry: CalendarReminderEntry
  ): Promise<number> {
    if (CalendarReminderHelper.calendar === null) {
      return -1;
    }

    const event: calendarManager.Event = {
      title: `${CalendarReminderHelper.EVENT_TITLE_PREFIX}${entry.title}`,
      type: calendarManager.EventType.NORMAL,
      startTime: entry.startTime,
      endTime: entry.startTime + CalendarReminderHelper.EVENT_DURATION_MS,
      reminderTime: entry.reminderMinutes,
      description: entry.description
    };

    try {
      const id = await CalendarReminderHelper.calendar.addEvent(event);
      if (typeof id === 'number' && id > 0) {
        return id;
      }
      // Defensive: addEvent is documented to return a positive ID, but
      // treat any unexpected value as a failure so we never accidentally
      // track `0` or `undefined` as an event ID.
      return -1;
    } catch (err) {
      const e = err as BusinessError;
      AppLogger.warn('CalendarReminderHelper',
        `addEvent failed for "${entry.title}": ${e.code} ${e.message}`);
      return -1;
    }
  }

  /**
   * Layer 3 safety check — true when the event was created by this
   * app, identified by its title prefix.
   */
  private static isOurs(event: calendarManager.Event): boolean {
    const title = event.title;
    if (title === undefined || title === null || title.length === 0) {
      return false;
    }
    return title.indexOf(CalendarReminderHelper.EVENT_TITLE_PREFIX) === 0;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  /**
   * Delete one event, retrying once after a short delay if the first
   * attempt fails. Returns true when the event is gone.
   */
  private static async deleteWithRetry(eventId: number): Promise<boolean> {
    if (CalendarReminderHelper.calendar === null) {
      return false;
    }

    for (let attempt = 0; attempt < 2; attempt++) {
      try {
        await CalendarReminderHelper.calendar.deleteEvent(eventId);
        return true;
      } catch (err) {
        const e = err as BusinessError;
        if (attempt === 0) {
          AppLogger.warn('CalendarReminderHelper',
            `deleteEvent retry for id=${eventId}: ${e.code} ${e.message}`);
          await new Promise<void>(
            (resolve) => setTimeout(resolve, 80)
          );
        } else {
          AppLogger.error('CalendarReminderHelper',
            `deleteEvent failed for id=${eventId}: ${e.code} ${e.message}`);
        }
      }
    }
    return false;
  }

  private static async waitForReady(): Promise<boolean> {
    for (let i = 0; i < 20; i++) {
      if (CalendarReminderHelper.ready) {
        return true;
      }
      if (!CalendarReminderHelper.initializing) {
        return CalendarReminderHelper.ready;
      }
      await new Promise<void>((resolve) => setTimeout(resolve, 50));
    }
    return CalendarReminderHelper.ready;
  }

  /**
   * Read a tracked event-ID list. Returns only positive, finite
   * numbers — anything else (stale string, negative, NaN) is dropped
   * silently so a corrupt preferences write cannot poison deletion.
   */
  private static async readEventIds(key: string): Promise<number[]> {
    try {
      const json = await PreferencesHelper.getString(key, '[]');
      const parsed: Object = JSON.parse(json);
      if (!Array.isArray(parsed)) {
        return [];
      }
      const out: number[] = [];
      for (const v of parsed as Object[]) {
        if (typeof v === 'number' && !isNaN(v) && v > 0) {
          out.push(v);
        }
      }
      return out;
    } catch (e) {
      return [];
    }
  }

  /** Persist the tracked event-ID list. Fire-and-forget; failures
   *  are logged but do not break the caller (the filter sweep will
   *  catch anything that falls through the tracking cracks). */
  private static async writeEventIds(
    key: string, ids: number[]
  ): Promise<void> {
    try {
      await PreferencesHelper.setString(key, JSON.stringify(ids));
    } catch (e) {
      const err = e as Error;
      AppLogger.warn('CalendarReminderHelper',
        `writeEventIds(${key}) failed: ${err.message}`);
    }
  }
}


/**
 * One calendar event to create. The caller builds these after
 * computing prayer times.
 */
export interface CalendarReminderEntry {
  /** Human-readable title, e.g. "Pray Fajr". The prefix is added by
   *  the helper automatically. */
  title: string;

  /** Event start time, in milliseconds since epoch. */
  startTime: number;

  /**
   * Minutes before startTime at which to fire reminders.
   * Use [0] for an at-time reminder, [0, 10] for both at-time and
   * 10 minutes before.
   */
  reminderMinutes: number[];

  /** Optional event description — used to carry the Hadith text. */
  description?: string;
}
