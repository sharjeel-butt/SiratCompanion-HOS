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
export const STORAGE_KEY_SHOW_EXTRA_TIMINGS = 'show_extra_timings';
export const STORAGE_KEY_SHOW_ISLAMIC_EVENTS = 'show_islamic_events';
export const STORAGE_KEY_OFFSET_FAJR = 'offset_fajr';
export const STORAGE_KEY_OFFSET_DHUHR = 'offset_dhuhr';
export const STORAGE_KEY_OFFSET_ASR = 'offset_asr';
export const STORAGE_KEY_OFFSET_MAGHRIB = 'offset_maghrib';
export const STORAGE_KEY_OFFSET_ISHA = 'offset_isha';
export const STORAGE_KEY_THEME_MODE = 'theme_mode';
export const STORAGE_KEY_NAV_DIRECTION = 'nav_direction';
export const STORAGE_KEY_LOCATION_VERSION = 'location_version';

/**
 * Bumped on every PrayerManager.saveStateForDate() call.
 *
 * Pages hosted as TabContent (which receive no onPageShow on tab
 * switches) subscribe to this key so they refresh the moment a
 * prayer is checked on another tab.
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