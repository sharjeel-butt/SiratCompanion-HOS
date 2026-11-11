import { CustomEvent, RecurrenceType } from './CustomEventModels';
import { HijriCalendarHelper } from './HijriCalendarHelper';
import { CalendarReminderEntry, CalendarReminderHelper } from './CalendarReminderHelper';
import { AppLogger } from '../core/AppLogger';

export class CustomEventNotifier {
  static async reschedule(events: CustomEvent[], offsetDays: number): Promise<void> {
    if (!CalendarReminderHelper.isReady()) {
      return;
    }

    // Clear any existing custom-event reminders so repeated
    // reschedules do not accumulate duplicates.
    await CalendarReminderHelper.cancelCustomEventReminders();

    const entries: CalendarReminderEntry[] = [];
    const now = new Date();
    now.setHours(0, 0, 0, 0);

    for (const ev of events) {
      if (!ev.notificationEnabled) {
        continue;
      }

      // How many future occurrences to schedule per event type.
      let remaining: number;
      let maxDays: number;
      switch (ev.recurrence) {
        case RecurrenceType.WEEKLY:
          remaining = 4; // next 4 weeks
          maxDays = 35;
          break;
        case RecurrenceType.MONTHLY:
          remaining = 3; // next 3 Hijri months
          maxDays = 120;
          break;
        case RecurrenceType.YEARLY:
          remaining = 2; // this year + next
          maxDays = 731;
          break;
        case RecurrenceType.NONE:
        default:
          remaining = 1;
          maxDays = 366;
          break;
      }

      let scheduled = 0;

      for (let i = 0; i < maxDays && scheduled < remaining; i++) {
        const testDate = new Date(now);
        testDate.setDate(testDate.getDate() + i);

        let matches = false;
        if (ev.recurrence === RecurrenceType.WEEKLY) {
          matches = testDate.getDay() === ev.gregorianDayOfWeek;
        } else {
          const h = HijriCalendarHelper.getHijriDate(testDate, offsetDays);
          if (ev.recurrence === RecurrenceType.MONTHLY) {
            matches = h.day === ev.hijriDay;
          } else if (ev.recurrence === RecurrenceType.YEARLY) {
            matches = h.month === ev.hijriMonth && h.day === ev.hijriDay;
          } else {
            matches =
              h.year === ev.hijriYear &&
                h.month === ev.hijriMonth &&
                h.day === ev.hijriDay;
          }
        }

        if (matches) {
          const fireTime = new Date(testDate);
          fireTime.setHours(8, 0, 0, 0);
          if (fireTime.getTime() > Date.now()) {
            entries.push({
              title: ev.title,
              startTime: fireTime.getTime(),
              reminderMinutes: [0],
              description: CalendarReminderHelper.CUSTOM_EVENT_DESCRIPTION
            });
            scheduled++;
          }

          // One-off events have exactly one valid match — stop looking.
          // Recurring events keep scanning until `scheduled === remaining`
          // (the loop condition handles that).
          if (ev.recurrence === RecurrenceType.NONE) {
            break;
          }
        }
      }

      if (scheduled < remaining) {
        AppLogger.info('CustomEventNotifier',
          `"${ev.title}" (${ev.recurrence}): only scheduled ` +
            `${scheduled} of ${remaining} expected occurrence(s)`);
      }
    }

    if (entries.length > 0) {
      AppLogger.info('CustomEventNotifier', `Scheduling ${entries.length} custom event(s)`);
      for (const entry of entries) {
        await CalendarReminderHelper.addTestEvent(entry);
      }
    }
  }

  static getNextOccurrence(ev: CustomEvent, offsetDays: number): Date | null {
    const now = new Date();
    now.setHours(0, 0, 0, 0);
    const rec = ev.recurrence || RecurrenceType.NONE;

    // Search up to 1 year ahead
    for (let i = 0; i < 366; i++) {
      const testDate = new Date(now);
      testDate.setDate(testDate.getDate() + i);

      let matches = false;
      if (rec === RecurrenceType.WEEKLY) {
        matches = testDate.getDay() === ev.gregorianDayOfWeek;
      } else {
        const h = HijriCalendarHelper.getHijriDate(testDate, offsetDays);
        if (rec === RecurrenceType.MONTHLY) {
          matches = h.day === ev.hijriDay;
        } else if (rec === RecurrenceType.YEARLY) {
          matches = h.month === ev.hijriMonth && h.day === ev.hijriDay;
        } else {
          matches = h.year === ev.hijriYear && h.month === ev.hijriMonth && h.day === ev.hijriDay;
        }
      }

      if (matches) {
        return testDate;
      }
    }
    return null;
  }
}