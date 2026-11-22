// entry/src/main/ets/common/FeatureFlags.ets

/**
 * Compile-time feature flags.
 *
 * ## Two reminder backends
 *
 * The app can deliver prayer-time reminders through one of two
 * mechanisms. Exactly one should be enabled at a time.
 *
 * CALENDAR_REMINDERS_ENABLED — Calendar Kit backend.
 *   • Writes prayer events into the system calendar with reminders.
 *   • Requires READ_CALENDAR + WRITE_CALENDAR (user-granted).
 *   • No AGC capability approval needed.
 *   • The reminder appears as a calendar event, not an app notification.
 *
 * NOTIFICATIONS_ENABLED — Agent-Powered Reminder backend.
 *   • Uses reminderAgentManager.publishReminder().
 *   • Requires PUBLISH_AGENT_REMINDER (AGC capability approval).
 *   • The reminder appears as a standard app notification.
 *
 * ## Current state
 *
 * Agent-Powered Reminder is pending AGC approval, so the Calendar Kit
 * backend is the active one. When AGC approves the capability:
 *   1. Set NOTIFICATIONS_ENABLED = true
 *   2. Set CALENDAR_REMINDERS_ENABLED = false
 *   3. Un-comment PUBLISH_AGENT_REMINDER in module.json5
 *   4. Comment out READ_CALENDAR / WRITE_CALENDAR in module.json5
 *   5. Update PrivacyPolicy.ets and index.md
 *   6. Regenerate the signing Profile and re-sign the app
 *
 * ## Why not both at once?
 *
 * Running both backends would deliver two reminders per prayer — one
 * from the calendar and one from the agent. The mutual exclusion is
 * enforced in NotificationHelper.resolveBackend().
 */

/** Agent-Powered Reminder backend. Pending AGC approval. */
export const NOTIFICATIONS_ENABLED = false;

/** Calendar Kit backend. Active workaround while AGC is pending. */
export const CALENDAR_REMINDERS_ENABLED = true;