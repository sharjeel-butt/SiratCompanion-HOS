// entry/src/main/ets/common/FeatureFlags.ets

/**
 * Compile-time feature flags.
 *
 * NOTIFICATIONS_ENABLED is currently false because the
 * Agent-Powered Reminder capability is not yet approved in
 * AppGallery Connect. Without approval, publishReminder()
 * fails with error 1700002 (quota is 0).
 *
 * To re-enable notifications after AGC approval:
 *   1. Set NOTIFICATIONS_ENABLED = true
 *   2. Un-comment the PUBLISH_AGENT_REMINDER entry in module.json5
 *   3. Re-declare the permission in the privacy policy
 *   4. Regenerate the signing Profile and re-sign the app
 */
export const NOTIFICATIONS_ENABLED = false;