// entry/src/main/ets/core/notifications/NotificationModels.ets

/**
 * Notification priorities.
 *
 * LOW      = informational
 * MEDIUM   = action recommended
 * HIGH     = action required
 */
export enum NotificationPriority {
  LOW = 1, MEDIUM = 2, HIGH = 3
}

/**
 * Notification categories.
 *
 * Start small:
 *  - prayer
 *  - ramadan
 *  - event
 *
 * More can be added later.
 */
export enum NotificationCategory {
  PRAYER = 'prayer', RAMADAN = 'ramadan', EVENT = 'event', ACHIEVEMENT = 'achievement'
}

/**
 * Stable notification record used by the
 * NotificationCenterService and UI.
 */
export interface AppNotification {
  /**
   * Unique identifier.
   *
   * Examples:
   * prayer_due_asr_20261122
   * prayer_missed_fajr_20261122
   */
  id: string;

  /**
   * Localized title key.
   *
   * Example:
   * notif_prayer_due_title
   */
  titleKey: string;

  /**
   * Localized message key.
   *
   * Example:
   * notif_asr_due_message
   */
  messageKey: string;

  /**
   * Category.
   */
  category: NotificationCategory;

  /**
   * Display order importance.
   */
  priority: NotificationPriority;

  /**
   * Creation timestamp.
   */
  createdAt: number;

  /**
   * Has the user opened/read it?
   */
  isRead: boolean;

  /**
   * Optional context.
   *
   * Examples:
   * Fajr
   * Asr
   * event_42
   */
  payload?: string;
}

/**
 * Collection returned to UI.
 */
export interface NotificationSummary {
  items: AppNotification[];
  unreadCount: number;
}

