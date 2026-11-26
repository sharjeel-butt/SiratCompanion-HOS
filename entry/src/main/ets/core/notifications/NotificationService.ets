// entry/src/main/ets/core/notifications/NotificationService.ets

import { PrayerManager } from '../../prayer/PrayerManager'
import { ProgressHelper } from '../../progress/ProgressHelper'
import { STORAGE_KEY_DISMISSED_ACHIEVEMENTS } from '../common/StorageKeys'
import { preferences } from '@kit.ArkData'

import { AppNotification, NotificationCategory, NotificationPriority, NotificationSummary } from './NotificationModels'
import { common } from '@kit.AbilityKit'
import { RamadanHelper } from '../../ramadan/RamadanHelper'

export enum NotificationType {
  PRAYER_DUE = 'prayer_due', ACHIEVEMENT = 'achievement'
}

export class NotificationService {
  private static prefs: preferences.Preferences | null = null

  static async init(context: common.UIAbilityContext): Promise<void> {
    if (NotificationService.prefs !== null) {
      return
    }

    NotificationService.prefs = await preferences.getPreferences(context, 'notification_preferences')
  }

  private static getDismissedIds(): string[] {
    if (NotificationService.prefs === null) {
      return []
    }

    const raw = NotificationService.prefs.getSync(STORAGE_KEY_DISMISSED_ACHIEVEMENTS, '[]') as string

    try {
      return JSON.parse(raw) as string[]
    } catch {
      return []
    }
  }

  private static saveDismissedIds(ids: string[]): void {
    if (NotificationService.prefs === null) {
      return
    }

    NotificationService.prefs.putSync(STORAGE_KEY_DISMISSED_ACHIEVEMENTS, JSON.stringify(ids))

    NotificationService.prefs.flush()
  }

  static getSummary(): NotificationSummary {
    const items = NotificationService.buildPrayerNotifications()

    return {
      items: items, unreadCount: items.length
    } as NotificationSummary
  }

  static getNotifications(): AppNotification[] {
    return NotificationService.buildPrayerNotifications()
  }

  static getUnreadCount(): number {
    return NotificationService.buildPrayerNotifications().length
  }

  private static buildPrayerNotifications(): AppNotification[] {
    const items: AppNotification[] = []
    NotificationService.buildRamadanNotifications(items)
    const dateKey = PrayerManager.getDateKey()
    const state = PrayerManager.getCheckState(dateKey)
    const allComplete = state.fajr && state.dhuhr && state.asr && state.maghrib && state.isha
    const progress = ProgressHelper.getPrayerProgress()
    const milestones: number[] = [3, 7, 14, 30, 100, 1000, 10000]

    for (const streak of milestones) {
      if (progress.currentStreak === streak) {
        items.push(NotificationService.createStreakNotification(streak))
      }
    }

    if (allComplete) {
      NotificationService.createCompleteDayNotification(dateKey)
      items.push(NotificationService.createCompleteDayNotification(dateKey))
    } else {
      if (!state.fajr) {
        items.push(NotificationService.createPrayerNotification('fajr', dateKey))
      }
      if (!state.dhuhr) {
        items.push(NotificationService.createPrayerNotification('dhuhr', dateKey))
      }
      if (!state.asr) {
        items.push(NotificationService.createPrayerNotification('asr', dateKey))
      }
      if (!state.maghrib) {
        items.push(NotificationService.createPrayerNotification('maghrib', dateKey))
      }
      if (!state.isha) {
        items.push(NotificationService.createPrayerNotification('isha', dateKey))
      }
    }
    const dismissed = NotificationService.getDismissedIds()
    return items.filter((item: AppNotification) => dismissed.indexOf(item.id) < 0)
  }

  private static createPrayerNotification(prayerId: string, dateKey: string): AppNotification {
    return {
      id: 'prayer_pending_' + prayerId + '_' + dateKey,
      titleKey: 'notif_prayer_due_title',
      messageKey: 'notif_' + prayerId + '_due',
      category: NotificationCategory.PRAYER,
      priority: NotificationPriority.HIGH,
      payload: prayerId,
      createdAt: Date.now(),
      isRead: false
    } as AppNotification
  }

  static canDismiss(notification: AppNotification): boolean {
    return notification.category !== NotificationCategory.PRAYER &&
      notification.category !== NotificationCategory.RAMADAN
  }

  private static createCompleteDayNotification(dateKey: string): AppNotification {
    return {
      id: 'complete_day_' + dateKey,
      titleKey: 'all_prayers_completed',
      messageKey: 'all_prayers_completed_subtitle',
      category: NotificationCategory.ACHIEVEMENT,
      priority: NotificationPriority.HIGH,
      payload: dateKey,
      createdAt: Date.now(),
      isRead: false
    } as AppNotification
  }

  private static createStreakNotification(streak: number): AppNotification {
    return {
      id: 'streak_' + streak,
      titleKey: 'notif_streak_title',
      messageKey: 'notif_streak_' + streak,
      category: NotificationCategory.ACHIEVEMENT,
      priority: NotificationPriority.HIGH,
      payload: streak.toString(),
      createdAt: Date.now(),
      isRead: false
    } as AppNotification
  }

  static dismissAchievement(id: string): void {
    const dismissed = NotificationService.getDismissedIds()
    console.info('[Generated ID] ' + id)
    if (dismissed.indexOf(id) >= 0) {
      return
    }
    dismissed.push(id)
    NotificationService.prefs?.putSync(STORAGE_KEY_DISMISSED_ACHIEVEMENTS, JSON.stringify(dismissed))
    NotificationService.prefs?.flush()
  }

  private static createRamadanNotification(id: string, titleKey: string, messageKey: string): AppNotification {
    return {
      id: id,
      titleKey: titleKey,
      messageKey: messageKey,
      category: NotificationCategory.RAMADAN,
      priority: NotificationPriority.HIGH,
      payload: id,
      createdAt: Date.now(),
      isRead: false
    } as AppNotification
  }

  private static buildRamadanNotifications(items: AppNotification[]): void {
    const info = RamadanHelper.getRamadanInfo(0)
    if (info === null) {
      return
    }
    if (info.daysUntilStart === 7) {
      items.push(
        NotificationService.createRamadanNotification('ramadan_start_7_' + info.hijriYear, 'notif_ramadan_start_title',
          'notif_ramadan_start_7'))
    }
    if (info.isRamadanNow && info.currentDayNumber === 1) {
      items.push(
        NotificationService.createRamadanNotification('ramadan_day1_' + info.hijriYear, 'notif_ramadan_mubarak_title',
          'notif_ramadan_mubarak_message'))
    }
    if (info.isRamadanNow &&
      (info.currentDayNumber === 21 || info.currentDayNumber === 23 || info.currentDayNumber === 25 ||
        info.currentDayNumber === 27 || info.currentDayNumber === 29)) {
      items.push(
        NotificationService.createRamadanNotification('laylatul_qadr_' + info.currentDayNumber + '_' + info.hijriYear,
          'notif_laylatul_qadr_title', 'notif_laylatul_qadr_' + info.currentDayNumber))
    }

    if (info.isRamadanNow && info.currentDayNumber === 21) {
      items.push(NotificationService.createRamadanNotification('last_ashra_' + info.hijriYear, 'notif_last_ashra_title',
        'notif_last_ashra_message'))
    }

    const eid = RamadanHelper.getEidInfo(0)
    if (eid !== null) {
      items.push(
        NotificationService.createRamadanNotification('eid_' + eid.hijriYear, 'notif_eid_title', 'notif_eid_message'))
    }

    if (info.isRamadanNow && info.currentDayNumber === 10) {
      items.push(NotificationService.createRamadanNotification('ramadan_day10_' + info.hijriYear, 'notif_day10_title',
        'notif_day10_message'))
    }

    // Day 20 completed
    if (info.isRamadanNow && info.currentDayNumber === 20) {
      items.push(NotificationService.createRamadanNotification('ramadan_day20_' + info.hijriYear, 'notif_day20_title',
        'notif_day20_message'))
    }

    if (info.jummahTulWidah !== null) {
      const today = new Date()
      today.setHours(0, 0, 0, 0)
      if (today.getTime() === info.jummahTulWidah.getTime()) {
        items.push(NotificationService.createRamadanNotification('jummah_tul_wida_' + info.hijriYear,
          'notif_jummah_tul_wida_title', 'notif_jummah_tul_wida_message'))
      }
    }

    const daysRemaining = info.totalDays - info.currentDayNumber
    if (info.isRamadanNow && daysRemaining === 3) {
      items.push(NotificationService.createRamadanNotification('ramadan_3_days_left_' + info.hijriYear,
        'notif_ramadan_end_title', 'notif_ramadan_3_days_left'))
    }

    if (info.isRamadanNow && daysRemaining === 1) {
      items.push(
        NotificationService.createRamadanNotification('eid_tomorrow_' + info.hijriYear, 'notif_eid_tomorrow_title',
          'notif_eid_tomorrow_message'))
    }
  }
}
