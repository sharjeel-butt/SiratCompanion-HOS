import { CustomEvent, RecurrenceType } from '../models/CustomEventModels';
import { HijriCalendarHelper } from '../hijricalendar/HijriCalendarHelper';
import { CalendarReminderEntry, CalendarReminderHelper } from '../hijricalendar/CalendarReminderHelper';
import { AppLogger } from './AppLogger';

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

      for (let i = 0; i < 30; i++) {
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
            matches = h.year === ev.hijriYear && h.month === ev.hijriMonth && h.day === ev.hijriDay;
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
          }
          if (ev.recurrence !== RecurrenceType.NONE) {
            break;
          }
        }
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