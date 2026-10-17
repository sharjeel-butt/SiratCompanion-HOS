// entry/src/main/ets/common/StorageKeys.ets

export const STORAGE_KEY_CALC_METHOD = 'prayer_calc_method';
export const STORAGE_KEY_ASR_RULE = 'prayer_asr_rule';
export const STORAGE_KEY_CALC_SOURCE = 'prayer_calc_source';
export const STORAGE_KEY_COUNTER = 'prayer_counter';
export const STORAGE_KEY_LOCATION_MODE = 'location_mode';
export const STORAGE_KEY_MANUAL_LAT = 'manual_lat';
export const STORAGE_KEY_MANUAL_LNG = 'manual_lng';
export const STORAGE_KEY_MANUAL_REFRESH = 'manual_refresh';
export const STORAGE_KEY_MANUAL_CITY = 'manual_city';

// ---- Show Islamic events ----
export const STORAGE_KEY_SHOW_ISLAMIC_EVENTS = 'show_islamic_events';

// ---- Prayer offsets ----
export const STORAGE_KEY_OFFSET_FAJR = 'offset_fajr';
export const STORAGE_KEY_OFFSET_DHUHR = 'offset_dhuhr';
export const STORAGE_KEY_OFFSET_ASR = 'offset_asr';
export const STORAGE_KEY_OFFSET_MAGHRIB = 'offset_maghrib';
export const STORAGE_KEY_OFFSET_ISHA = 'offset_isha';

// ---- Theme ----
export const STORAGE_KEY_THEME_MODE = 'theme_mode';
export const STORAGE_KEY_NAV_DIRECTION = 'nav_direction';
export const STORAGE_KEY_LOCATION_VERSION = 'location_version';

/**
 * Bumped on every PrayerManager.saveStateForDate() call.
 */
export const STORAGE_KEY_PRAYER_STATE_VERSION = 'prayer_state_version';

export const STORAGE_KEY_HIJRI_OFFSET = 'hijri_offset';
export const STORAGE_KEY_LANGUAGE = 'app_language';
export const STORAGE_KEY_WIZARD_COMPLETED = 'wizard_completed';
export const STORAGE_KEY_NOTIF_MASTER = 'notif_master_enabled';
export const STORAGE_KEY_NOTIF_BEFORE_MINUTES = 'notif_before_minutes';
export const STORAGE_KEY_NOTIF_FAJR = 'notif_fajr';
export const STORAGE_KEY_NOTIF_DHUHR = 'notif_dhuhr';
export const STORAGE_KEY_NOTIF_ASR = 'notif_asr';
export const STORAGE_KEY_NOTIF_MAGHRIB = 'notif_maghrib';
export const STORAGE_KEY_NOTIF_ISHA = 'notif_isha';
export const STORAGE_KEY_HIGH_LAT_RULE = 'high_lat_rule';
export const STORAGE_KEY_VIBRATION_ENABLED = 'vibration_enabled';
export const STORAGE_KEY_TASBIH_RENDER_STYLE = 'tasbih_render_style';
export const STORAGE_KEY_TASBIH_THEME_PRESET = 'tasbih_theme_preset';
export const STORAGE_KEY_APP_THEME = 'app_theme_preset';
export const STORAGE_KEY_APP_FOREGROUND_TICK = 'app_foreground_tick';
export const STORAGE_KEY_SOUND_ENABLED = 'sound_enabled';
export const STORAGE_KEY_TASBIH_SOUND = 'tasbih_sound';
export const STORAGE_KEY_SYSTEM_SOUND_ENABLED = 'system_sound_enabled';
export const STORAGE_KEY_SYSTEM_HAPTICS_ENABLED = 'system_haptics_enabled';
export const STORAGE_KEY_BREAKPOINT = 'layout_breakpoint';

// ---- Advanced Calculation Settings ----
export const STORAGE_KEY_ROUNDING_METHOD = 'calc_rounding_method';
export const STORAGE_KEY_MIDNIGHT_METHOD = 'calc_midnight_method';
export const STORAGE_KEY_POLAR_RESOLUTION = 'calc_polar_resolution';
export const STORAGE_KEY_SHAFAQ = 'calc_shafaq';
export const STORAGE_KEY_CUSTOM_FAJR_ANGLE = 'calc_custom_fajr';
export const STORAGE_KEY_CUSTOM_ISHA_ANGLE = 'calc_custom_isha';
export const STORAGE_KEY_CUSTOM_ISHA_INTERVAL = 'calc_custom_isha_interval';

export const STORAGE_KEY_TIME_FORMAT = 'time_format';

export const STORAGE_KEY_HIJRI_CALENDAR_TYPE = 'hijri_calendar_type';

/**
 * One-shot hint for SettingsPage: which category to expand when
 * the page is opened. Set by Home / Prayer before navigating, read
 * and cleared by SettingsPage.aboutToAppear(). Empty string means
 * "use the default", which is Location.
 */
export const STORAGE_KEY_SETTINGS_INITIAL_CATEGORY = 'settings_initial_category';

/**
 * Which sect perspective to use when choosing Islamic events to
 * display. Values: 'universal' | 'sunni' | 'shia' | 'all'.
 */
export const STORAGE_KEY_EVENT_PERSPECTIVE = 'event_perspective';

/**
 * Bumped whenever the Islamic Events perspective changes. Home,
 * Prayer, and HijriCalendar watch this counter rather than the
 * perspective value itself — an incrementing integer reliably
 * triggers @Watch on every SDK build, whereas a direct @StorageLink
 * on a string setting can miss notifications.
 */
export const STORAGE_KEY_EVENT_SETTINGS_VERSION = 'event_settings_version';

/**
 * Bumped whenever a prayer-calculation setting changes: method,
 * Asr rule, source, high-latitude rule, offsets, rounding,
 * midnight method, polar resolution, Shafaq, or custom angles.
 */
export const STORAGE_KEY_CALC_SETTINGS_VERSION = 'calc_settings_version';

// ============================================================
// PER-TIMING VISIBILITY — PRAYER LIST
// ============================================================

/**
 * Each of these gates the corresponding row in the prayer-list
 * timeline. Sunrise and Sunset are core astronomical markers and
 * are always shown, so they have no toggle.
 */
export const STORAGE_KEY_SHOW_IMSAK_LIST = 'show_imsak_list';

export const STORAGE_KEY_SHOW_FIRST_THIRD_LIST = 'show_first_third_list';

export const STORAGE_KEY_SHOW_MIDNIGHT_LIST = 'show_midnight_list';

export const STORAGE_KEY_SHOW_LAST_THIRD_LIST = 'show_last_third_list';

// ============================================================
// PER-TIMING VISIBILITY — SUN PATH
// ============================================================

/**
 * Each of these gates the vertical dotted guide and label for the
 * corresponding timing on the sun path.
 */
export const STORAGE_KEY_SHOW_IMSAK_SUNPATH = 'show_imsak_sunpath';

export const STORAGE_KEY_SHOW_FIRST_THIRD_SUNPATH = 'show_first_third_sunpath';

export const STORAGE_KEY_SHOW_MIDNIGHT_SUNPATH = 'show_midnight_sunpath';

export const STORAGE_KEY_SHOW_LAST_THIRD_SUNPATH = 'show_last_third_sunpath';

// ============================================================
// LEGACY KEYS — kept for migration
// ============================================================

/**
 * Legacy group toggles. Superseded by the per-timing keys above.
 */
export const STORAGE_KEY_SHOW_EXTRA_TIMINGS_LIST = 'show_extra_timings_list';

export const STORAGE_KEY_SHOW_EXTRA_TIMINGS_SUNPATH = 'show_extra_timings_sunpath';

export const STORAGE_KEY_SHOW_EXTRA_TIMINGS = 'show_extra_timings';

/**
 * Legacy per-timing keys. Each controlled both list and sun path
 * at once. Superseded by the list/sunpath split above.
 */
export const STORAGE_KEY_SHOW_IMSAK = 'show_imsak';

export const STORAGE_KEY_SHOW_FIRST_THIRD = 'show_first_third';

export const STORAGE_KEY_SHOW_MIDNIGHT = 'show_midnight';

export const STORAGE_KEY_SHOW_LAST_THIRD = 'show_last_third';

export const STORAGE_KEY_TASBIH_STATE_VERSION = 'tasbih_state_version';

export const STORAGE_KEY_HIJRI_CALENDAR_VERSION = 'hijri_calendar_version';
export const STORAGE_KEY_AUTO_SHOW_RAMADAN_VIEW = 'auto_show_ramadan_view';