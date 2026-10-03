// entry/src/main/ets/helper/CalendarReminderHelper.ets

import { calendarManager } from '@kit.CalendarKit';
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AppLogger } from './AppLogger';

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
export class CalendarReminderHelper {
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
  static async init(context: common.UIAbilityContext): Promise<boolean> {
    if (CalendarReminderHelper.ready) {
      return true;
    }
    if (CalendarReminderHelper.initializing) {
      return CalendarReminderHelper.waitForReady();
    }
    CalendarReminderHelper.initializing = true;

    try {
      const granted =
        await CalendarReminderHelper.requestPermission(context);
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

      // Enable reminders on this account. Without this, the system
      // will not fire calendar notifications even if reminderTime
      // is set on the events.
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
   * are granted.
   */
  static async requestPermission(
    context: common.UIAbilityContext
  ): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const result = await atManager.requestPermissionsFromUser(
        context, CalendarReminderHelper.PERMISSIONS
      );
      for (const status of result.authResults) {
        if (status !== 0) {
          return false;
        }
      }
      return true;
    } catch (err) {
      const e = err as BusinessError;
      AppLogger.warn('CalendarReminderHelper',
        `permission request failed: ${e.code} ${e.message}`);
      return false;
    }
  }

  /** True when both calendar permissions are already granted. */
  static async isPermissionGranted(
    context: common.UIAbilityContext
  ): Promise<boolean> {
    // The most reliable check is to re-request; the system returns
    // immediately without a dialog if the permission is already granted.
    return CalendarReminderHelper.requestPermission(context);
  }

  // ============================================================
  // ACCOUNT
  // ============================================================

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

  // ============================================================
  // SCHEDULING
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

    // Clear old events first so we don't accumulate duplicates.
    await CalendarReminderHelper.cancelAll();

    let created = 0;
    for (const entry of entries) {
      const ok = await CalendarReminderHelper.publishEvent(entry);
      if (ok) {
        created++;
      }
    }

    AppLogger.info('CalendarReminderHelper',
      `Scheduled ${created} calendar event(s)`);
    return created;
  }

  /**
   * Create one calendar event with the given reminder offsets.
   */
  private static async publishEvent(
    entry: CalendarReminderEntry
  ): Promise<boolean> {
    if (CalendarReminderHelper.calendar === null) {
      return false;
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
      await CalendarReminderHelper.calendar.addEvent(event);
      return true;
    } catch (err) {
      const e = err as BusinessError;
      AppLogger.warn('CalendarReminderHelper',
        `addEvent failed for "${entry.title}": ${e.code} ${e.message}`);
      return false;
    }
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  /**
   * Delete every Sirat event from the app's calendar account.
   *
   * Three layers of safety, all applied:
   *
   *   1. The calendar object is scoped to the app's own account
   *      (obtained via getCalendar with the SiratCompanionCalendar
   *      account name). Events in other accounts cannot be reached.
   *
   *   2. An EventFilter.filterByTitle restricts the result set to
   *      events whose title contains the app's EVENT_TITLE_PREFIX.
   *      This guarantees that even if the underlying account ever
   *      contained a non-Sirat event, it would not appear in the
   *      query results.
   *
   *   3. Each event is re-checked with isOurs() before its delete
   *      call, so a filter that returned a superset cannot cause a
   *      wrong deletion.
   *
   * Called by NotificationHelper.doRescheduleAll() before scheduling,
   * so that a change to the lead time, prayer toggles, location, or
   * calculation method always produces a clean slate for the events
   * that belong to us.
   *
   * Individual deletions retry once. A failure is logged but not
   * fatal — the next reschedule will attempt the delete again.
   */
  static async cancelAll(): Promise<void> {
    if (!CalendarReminderHelper.ready ||
      CalendarReminderHelper.calendar === null) {
      return;
    }

    try {
      // Layer 2 — title filter. Combined with the account-scoped
      // calendar object, this guarantees we only see our own events.
      const filter = calendarManager.EventFilter.filterByTitle(
        CalendarReminderHelper.EVENT_TITLE_PREFIX
      );
      const events =
        await CalendarReminderHelper.calendar.getEvents(filter);

      AppLogger.info('CalendarReminderHelper',
        `cancelAll: found ${events.length} event(s) to delete`);

      let deleted = 0;
      let failed = 0;

      for (const ev of events) {
        if (ev.id === undefined) {
          continue;
        }

        // Layer 3 — per-event title re-check. Guards against a filter
        // that returns a superset (e.g. partial or case-insensitive
        // matches).
        if (!CalendarReminderHelper.isOurs(ev)) {
          AppLogger.warn('CalendarReminderHelper',
            `cancelAll: skipping non-Sirat event id=${ev.id} ` +
              `title="${ev.title ?? ''}"`);
          continue;
        }

        const ok = await CalendarReminderHelper.deleteWithRetry(ev.id);
        if (ok) {
          deleted++;
        } else {
          failed++;
        }
      }

      AppLogger.info('CalendarReminderHelper',
        `cancelAll: deleted ${deleted}, failed ${failed}`);
    } catch (err) {
      const e = err as BusinessError;
      AppLogger.warn('CalendarReminderHelper',
        `cancelAll failed: ${e.code} ${e.message}`);
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

  // ============================================================
  // HELPERS
  // ============================================================

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