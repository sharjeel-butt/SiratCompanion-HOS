// entry/src/main/ets/helper/LocalizationHelper.ets

import { STORAGE_KEY_LANGUAGE } from '../common/StorageKeys';

export enum AppLanguage {
  ENGLISH = 'en',
  CHINESE = 'zh',
  ARABIC  = 'ar'
}

export class L {

  // ============================================================
  // LANGUAGE STATE
  // ============================================================

  static current(): string {
    const v = AppStorage.get<string>(STORAGE_KEY_LANGUAGE);
    return v ? v : AppLanguage.ENGLISH;
  }

  static setLanguage(lang: string): void {
    AppStorage.setOrCreate(STORAGE_KEY_LANGUAGE, lang);
  }

  static isRtl(): boolean {
    return L.current() === AppLanguage.ARABIC;
  }

  static isRtlLang(lang: string): boolean {
    return lang === AppLanguage.ARABIC;
  }

  static getLanguageLabel(lang: string): string {
    return L.get(`lang_${lang}`);
  }

  // ============================================================
  // LOOKUPS
  // ============================================================

  static get(key: string, lang?: string): string {
    const l = (lang !== undefined && lang.length > 0) ? lang : L.current();
    const table = L.tableFor(l);
    const v = table.get(key);
    if (v !== undefined) return v;
    const en = L.EN.get(key);
    return en !== undefined ? en : key;
  }

  static getArray(key: string, lang?: string): string[] {
    const l = (lang !== undefined && lang.length > 0) ? lang : L.current();
    if (key === 'hijri_months') {
      if (l === AppLanguage.CHINESE) return L.MONTHS_ZH;
      if (l === AppLanguage.ARABIC)  return L.MONTHS_AR;
      return L.MONTHS_EN;
    }
    if (key === 'days_of_week') {
      if (l === AppLanguage.CHINESE) return L.DAYS_ZH;
      if (l === AppLanguage.ARABIC)  return L.DAYS_AR;
      return L.DAYS_EN;
    }
    return [];
  }

  private static tableFor(lang: string): Map<string, string> {
    if (lang === AppLanguage.CHINESE) return L.ZH;
    if (lang === AppLanguage.ARABIC)  return L.AR;
    return L.EN;
  }

  // ============================================================
  // STRING TABLES
  // ============================================================

  private static readonly EN: Map<string, string> = L.buildEn();
  private static readonly ZH: Map<string, string> = L.buildZh();
  private static readonly AR: Map<string, string> = L.buildAr();

  // ============================================================
  // ENGLISH
  // ============================================================

  private static buildEn(): Map<string, string> {
    const m = new Map<string, string>();

    // ---- App ----
    m.set('app_name', 'Sirat Companion');
    m.set('app_tagline', 'Your Daily Islamic Companion');
    m.set('more_languages_coming', 'More languages coming soon');

    // ---- Tabs ----
    m.set('tab_home', 'Home');
    m.set('tab_tasbih', 'Tasbih');
    m.set('tab_compass', 'Compass');
    m.set('tab_calendar', 'Calendar');

    // ---- Home ----
    m.set('current_prayer', 'Current');
    m.set('next_prayer', 'Next');
    m.set('todays_prayers', "TODAY'S PRAYERS");
    m.set('extra_timings', 'EXTRA TIMINGS');
    m.set('upcoming_islamic_events', 'UPCOMING ISLAMIC EVENTS');
    m.set('loading_location', 'Loading...');
    m.set('set_manual_location', 'Set Manual Location in Settings');
    m.set('online_prayer_times', 'Online Prayer Times');
    m.set('coming_soon', 'Coming Soon');
    m.set('online_switch_hint', 'Switch back to Local Formula in Settings to see prayer times for your location.');

    // ---- Common buttons ----
    m.set('cancel', 'Cancel');
    m.set('save', 'Save');
    m.set('reset', 'Reset');
    m.set('delete', 'Delete');
    m.set('edit', 'Edit');
    m.set('add', 'Add');
    m.set('back', 'Back');
    m.set('today', 'Today');
    m.set('exit', 'Exit');
    m.set('exit_confirm_message', 'Are you sure you want to exit Sirat Companion?');

    // ---- Titles ----
    m.set('title_settings', 'Settings');
    m.set('title_customize', 'Customize');

    // ---- Categories ----
    m.set('category_prayer_times', 'Prayer Times');
    m.set('category_hijri_calendar', 'Hijri Calendar');
    m.set('category_ui_customization', 'UI Customization');
    m.set('category_appearance', 'Appearance');
    m.set('category_about', 'About');
    m.set('category_notifications', 'Notifications');

    m.set('brand_primary', 'Sirat');
    m.set('brand_accent', 'Companion');

    // ---- Settings: Prayer Times ----
    m.set('convention', 'Convention');
    m.set('convention_desc', 'Used for calculation of Fajr and Isha');
    m.set('madhab', 'Madhab');
    m.set('madhab_desc', 'Asr Shadow Rule used in the calculation');
    m.set('source', 'Source');
    m.set('source_desc', 'Local Formula or Online');
    m.set('prayer_offsets', 'Prayer Offsets');
    m.set('prayer_offsets_desc', 'Manually shift calculated timings');
    m.set('offsets_hint', 'Shift timings in minutes (−60 to +60)');
    m.set('reset_all_offsets', 'Reset All Offsets');

    // ---- Settings: High Latitude ----
    m.set('high_latitude', 'High Latitude');
    m.set('high_latitude_desc', 'Fallback for Fajr and Isha when the Sun does not reach the angle');
    m.set('highlat_none', 'None');
    m.set('highlat_middle', 'Middle of Night');
    m.set('highlat_one_seventh', 'One Seventh of Night');
    m.set('highlat_angle', 'Angle Based');

    // ---- Settings: Location ----
    m.set('location', 'Location');
    m.set('location_desc', 'Choose how the app determines your location');
    m.set('gps', 'GPS');
    m.set('manual_location', 'Manual Location');
    m.set('current_position', 'Current Position');
    m.set('latitude', 'Latitude');
    m.set('longitude', 'Longitude');
    m.set('city', 'City');
    m.set('last_refreshed', 'Last refreshed');
    m.set('save_coordinates', 'Save Coordinates');
    m.set('latitude_hint', 'Latitude  (−90 to 90)');
    m.set('longitude_hint', 'Longitude  (−180 to 180)');
    m.set('city_name_optional', 'City name (optional)');
    m.set('city_name_placeholder', 'Leave blank to auto-detect');

    // ---- Settings: Hijri ----
    m.set('hijri_offset', 'Hijri Date & Calendar Offset');
    m.set('hijri_offset_desc', 'Shift both the Islamic date and the calendar by ±3 days');
    m.set('matching_standard', 'Matching the standard calculation');
    m.set('offset_days_ahead', 'days ahead');
    m.set('offset_days_behind', 'days behind');

    // ---- Settings: About ----
    m.set('about_version', 'Version');
    m.set('about_platform', 'Platform');
    m.set('about_copyright', '© 2026');

    // ---- Settings: Notifications ----
    m.set('notifications_master', 'Enable Notifications');
    m.set('notifications_master_desc', 'Get reminders before and at prayer time');
    m.set('notify_before', 'Notify Before');
    m.set('notify_before_desc', 'How many minutes before the prayer for the first reminder');
    m.set('notify_prayers', 'Prayer Reminders');
    m.set('notify_prayers_desc', 'Choose which prayers send reminders');
    m.set('notifications_footer', 'Reminders are scheduled for the next 3 days and renew each time you open the app');
    m.set('notification_permission_denied', 'Notification permission is required to enable reminders');
    m.set('notif_before_title', 'Prayer Reminder');
    m.set('notif_before_content', 'is in');
    m.set('notif_exact_title', 'Prayer Time');
    m.set('notif_exact_content', 'It is now time for');
    m.set('notif_minutes_suffix', 'min');
    m.set('notif_test_button', 'Send Test Notification');
    m.set('notif_test_sending', 'Sending test notification...');
    m.set('notif_test_ok', 'Test notification scheduled — you should see it in ~5 seconds');
    m.set('notif_test_failed', 'Test notification failed');

    // ---- Settings: Logs ----
    m.set('log_view_button', 'Diagnostic Logs');
    m.set('log_view_desc', 'View, copy, or clear the app log file');
    m.set('log_view_title', 'Diagnostic Logs');
    m.set('log_copy', 'Copy');
    m.set('log_clear', 'Clear');
    m.set('log_empty', 'The log is empty.');
    m.set('log_copied', 'Log copied to clipboard');
    m.set('log_cleared', 'Log cleared');

    // ---- Customize: UI Customization ----
    m.set('show_extra_timings', 'Show Extra Timings');
    m.set('show_extra_timings_desc', 'Imsak, Sunrise, Sunset and night times');
    m.set('show_islamic_events', 'Show Islamic Events');
    m.set('show_islamic_events_desc', 'Upcoming Islamic events on home screen');

    // ---- Customize: Appearance ----
    m.set('dark_mode', 'Dark Mode');
    m.set('dark_mode_desc', 'Choose how the app looks');
    m.set('theme_light', 'Light');
    m.set('theme_dark', 'Dark');
    m.set('theme_system', 'Use System Settings');
    m.set('tasbih_render_style', 'Tasbih Theme');
    m.set('tasbih_render_style_desc', 'Choose the style of your prayer beads');
    m.set('bead_style_premium', 'Premium (3D)');
    m.set('bead_style_classic', 'Classic');

    // ---- Customize: Language ----
    m.set('language', 'Language');
    m.set('language_desc', 'Choose your preferred language');
    m.set('lang_en', 'English');
    m.set('lang_zh', '中文 (Chinese)');
    m.set('lang_ar', 'العربية (Arabic)');

    // ---- Customize: Haptics ----
    m.set('haptic_feedback', 'Vibration');
    m.set('haptic_feedback_desc', 'Vibrate when counting Tasbih');

    // ---- Tasbih ----
    m.set('title_tasbih', 'Tasbih');
    m.set('my_tasbihs', 'My Tasbihs');
    m.set('select_dhikr', 'Select Dhikr');
    m.set('new_tasbih', 'New Tasbih');
    m.set('edit_tasbih', 'Edit Tasbih');
    m.set('new_dhikr', 'New Dhikr');
    m.set('edit_dhikr', 'Edit Dhikr');
    m.set('tasbih_name', 'Name');
    m.set('tasbih_name_placeholder', 'e.g. Evening Adhkar');
    m.set('dhikr_arabic', 'Arabic');
    m.set('dhikr_transliteration', 'Transliteration (optional)');
    m.set('dhikr_transliteration_placeholder', 'e.g. SubhanAllah');
    m.set('dhikr_translation', 'Translation (optional)');
    m.set('dhikr_translation_placeholder', 'e.g. Glory be to Allah');
    m.set('target_count', 'Target count');
    m.set('flick_up_to_count', 'flick up to count');
    m.set('flick_hint', 'Flick up: +1     ·     Flick down: −1');
    m.set('total_on_tasbih', 'total on this tasbih');
    m.set('dhikr_count_singular', 'dhikr');
    m.set('dhikr_count_plural', 'dhikrs');
    m.set('new_tasbih_button', '+ New Tasbih');
    m.set('add_dhikr_button', '+ Add Dhikr');
    m.set('all_dhikrs_complete', 'All dhikrs complete');
    m.set('counter_reset_toast', 'Counter reset');
    m.set('no_dhikr_title', 'No Dhikr in this Tasbih');
    m.set('no_dhikr_hint', 'Tap the dhikr pill at top to add one');
    m.set('switch_dhikr', 'Switch dhikr');
    m.set('reset_counter', 'Reset counter');
    m.set('delete_dhikr', 'Delete dhikr');
    m.set('add_new_dhikr', 'Add new dhikr');
    m.set('reset_all', 'Reset All');
    m.set('reset_all_confirm_title', 'Reset Tasbih');
    m.set('reset_all_confirm_message', 'Reset all dhikr counts in this Tasbih?');
    m.set('reset_all_done', 'Tasbih reset');

    // ---- Qibla ----
    m.set('title_qibla', 'Qibla Compass');
    m.set('qibla_direction', 'Qibla Direction');
    m.set('device_heading', 'Device Heading');
    m.set('distance_to_kaaba', 'Distance to Kaaba');
    m.set('compass_ready', 'Compass is ready. Rotate your device to align with the 🕋 marker.');
    m.set('keep_device_flat', 'Keep your device flat for accurate readings.');
    m.set('sensor_unavailable', 'Compass sensor not available. Please test on a real device.');
    m.set('location_unavailable', 'Location unavailable');

    // ---- Hijri Calendar ----
    m.set('title_hijri_calendar', 'Hijri Calendar');
    m.set('important_dates', 'IMPORTANT DATES');
    m.set('no_events_this_month', 'No major Islamic events this month');

    // ---- Status labels ----
    m.set('status_next', 'NEXT');
    m.set('status_pray', 'Pray');
    m.set('status_both', 'Pray  ·  NEXT');
    m.set('status_prayed', '✓ Prayed');
    m.set('status_express', 'Express');

    // ---- Prayer names ----
    m.set('prayer_fajr', 'Fajr');
    m.set('prayer_dhuhr', 'Dhuhr');
    m.set('prayer_asr', 'Asr');
    m.set('prayer_maghrib', 'Maghrib');
    m.set('prayer_isha', 'Isha');
    m.set('prayer_jummah', 'Jummah');

    // ---- Timing names ----
    m.set('timing_imsak', 'Imsak');
    m.set('timing_sunrise', 'Sunrise');
    m.set('timing_sunset', 'Sunset');
    m.set('timing_first_third', 'First Third');
    m.set('timing_midnight', 'Midnight');
    m.set('timing_last_third', 'Last Third');

    // ---- Event names ----
    m.set('event_new_year', 'Islamic New Year');
    m.set('event_ashura', 'Day of Ashura');
    m.set('event_mawlid', 'Mawlid al-Nabi');
    m.set('event_isra_miraj', "Isra and Mi'raj");
    m.set('event_mid_shaban', "Mid-Sha'ban");
    m.set('event_ramadan_start', 'Ramadan');
    m.set('event_eid_fitr', 'Eid al-Fitr');
    m.set('event_arafah', 'Day of Arafah');
    m.set('event_eid_adha', 'Eid al-Adha');

    // ---- Method labels ----
    m.set('method_karachi', 'University of Islamic Sciences, Karachi');
    m.set('method_jafari', 'Shia Ithna Ashari (Leva Institute, Qum)');
    m.set('method_isna', 'Islamic Society of North America');
    m.set('method_mwl', 'Muslim World League');
    m.set('asr_standard', "Standard (Shafi'i / Maliki / Hanbali)");
    m.set('asr_hanafi', 'Hanafi');
    m.set('source_local', 'Local Formula (Offline)');
    m.set('source_api', 'API (Online)');

    // ---- Wizard ----
    m.set('wizard_step', 'Step');
    m.set('wizard_welcome_title', 'Welcome to Sirat Companion');
    m.set('wizard_welcome_desc', 'Let us set up your preferences. You can change them anytime in Settings.');
    m.set('wizard_language_title', 'Choose your language');
    m.set('wizard_language_desc', 'The app will use this language across all screens');
    m.set('wizard_privacy_title', 'Privacy Policy');
    m.set('wizard_privacy_desc', 'Please read and accept before continuing');
    m.set('privacy_agree_label', 'I have read and agree to the Privacy Policy');
    m.set('privacy_view_full', 'View the full privacy policy online');
    m.set('wizard_location_title', 'Set your location');
    m.set('wizard_location_desc', 'Used for prayer times and Qibla direction');
    m.set('wizard_convention_title', 'Calculation preferences');
    m.set('wizard_convention_desc', 'Choose how prayer times should be calculated');
    m.set('wizard_grant_permission', 'Grant Location Permission');
    m.set('wizard_getting_location', 'Detecting your location...');
    m.set('wizard_location_ready', 'Location detected');
    m.set('wizard_location_failed', 'Could not get location');
    m.set('wizard_retry', 'Retry');
    m.set('wizard_next', 'Next');
    m.set('wizard_finish', 'Get Started');
    m.set('notif_dismiss', 'Dismiss'); // EN
    // ---- Tasbih theme presets ----
    m.set('theme_amber', 'Amber');
    m.set('theme_charcoal', 'Charcoal');
    m.set('theme_emerald', 'Emerald');
    m.set('theme_pearl', 'Pearl');
    m.set('theme_gold', 'Gold (Metallic)');
    m.set('tab_prayers', 'Prayers');
    // ---- Home dashboard ----
    m.set('home_today_progress', "TODAY'S PROGRESS");
    m.set('home_prayers_completed', 'prayers completed');
    m.set('home_keep_going', 'Keep it up!');
    m.set('home_streak', 'Day Streak');
    m.set('home_best_streak', 'Best');
    m.set('home_days', 'days');
    m.set('home_this_week', 'THIS WEEK');
    m.set('home_week_summary', 'prayers this week');
    m.set('home_this_month', 'THIS MONTH');
    m.set('home_month_summary', 'prayers this month');
    m.set('home_tasbih', 'TASBIH');
    m.set('home_tasbih_lifetime', 'Lifetime count');
    m.set('home_tasbih_summary', 'tasbihs');
    m.set('home_dhikrs', 'dhikrs');

    // ---- Tabs ----
    m.set('tab_prayers', 'Prayers');

    // ---- Home dashboard ----
    m.set('home_today_progress', "TODAY'S PROGRESS");
    m.set('home_prayers_completed', 'prayers completed');
    m.set('home_keep_going', 'Keep it up!');
    m.set('home_streak', 'Day Streak');
    m.set('home_best_streak', 'Best');
    m.set('home_days', 'days');
    m.set('home_this_week', 'THIS WEEK');
    m.set('home_week_summary', 'prayers this week');
    m.set('home_month_summary', 'prayers this month');
    m.set('home_tasbih', 'TASBIH');
    m.set('home_tasbih_lifetime', 'Lifetime count');
    m.set('home_tasbih_summary', 'tasbihs');
    m.set('home_dhikrs', 'dhikrs');

    // ---- Monthly view ----
    m.set('home_monthly_view', 'MONTHLY VIEW');
    m.set('home_perfect_days', 'Perfect days');
    m.set('home_days_elapsed', 'Days elapsed');
    m.set('home_lifetime_1y', 'prayers in the last year');

    // ---- Event countdown ----
    m.set('home_next_event', 'NEXT EVENT');
    m.set('home_event_today', 'Today!');
    m.set('home_event_tomorrow', 'Tomorrow');

    // ---- Ramadan card ----
    m.set('ramadan_card_title', 'RAMADAN');
    m.set('ramadan_day_of', 'Day');
    m.set('ramadan_day_of_suffix', 'of Ramadan');
    m.set('ramadan_days_until', 'Ramadan starts in');
    m.set('ramadan_fast_start', 'Fasting Start (Imsak)');
    m.set('ramadan_fast_end', 'Fasting End (Maghrib)');
    m.set('ramadan_today_fast', "Today's fasting window");
    m.set('ramadan_first_day_fast', 'First day of Ramadan');
    m.set('ramadan_calendar_start', 'Ramadan Begins');
    m.set('ramadan_calendar_end', 'Ramadan Ends');
    m.set('ramadan_ashras', 'ASHRAS');
    m.set('ramadan_first_ashra', 'First Ashra');
    m.set('ramadan_second_ashra', 'Second Ashra');
    m.set('ramadan_third_ashra', 'Third Ashra');
    m.set('ramadan_first_ashra_significance', 'Days of Mercy');
    m.set('ramadan_second_ashra_significance', 'Days of Forgiveness');
    m.set('ramadan_third_ashra_significance', 'Freedom from Hellfire');
    m.set('ramadan_laylat_al_qadr', 'LAYLAT AL-QADR');
    m.set('ramadan_laylat_al_qadr_desc',
      'The Night of Power — better than a thousand months. Seek it on the odd nights of the last ten days.');
    m.set('ramadan_jummah_tul_widah', 'JUMMAH TUL WIDAH');
    m.set('ramadan_jummah_tul_widah_desc',
      'The Farewell Friday — the last Friday of Ramadan.');
    m.set('ramadan_today', 'Tonight!');

    // ---- Live countdown (last 15 min before Imsak / Maghrib) ----
    m.set('countdown_fast_ends', 'Breaking fast in');
    m.set('countdown_fast_starts', 'Fasting begins in');
    m.set('countdown_fast_ends_desc', 'Prepare to break your fast');
    m.set('countdown_fast_starts_desc', 'Finish suhoor before Imsak');

    // ---- Duas ----
    m.set('dua_iftar_name', 'Dua for Breaking the Fast');
    m.set('dua_iftar_translation',
      'The thirst is gone, the veins are moistened, and the reward is certain, if Allah wills.');
    m.set('dua_suhoor_name', 'Intention for Fasting');
    m.set('dua_suhoor_translation',
      'I intend to keep the fast for tomorrow in the month of Ramadan.');

    // ---- Generic UI ----
    m.set('ok', 'OK');
    m.set('gps', 'GPS');

    // ---- About ----
    m.set('about_build', 'Build');
    m.set('about_bundle', 'Bundle ID');
    m.set('about_platform_value', 'HarmonyOS 5+');
    m.set('sun_path_we_are_here', 'We are here');

    // ---- Short labels (home screen pills) ----
    m.set('method_short_karachi', 'Karachi');
    m.set('method_short_jafari', 'Jafari');
    m.set('method_short_isna', 'ISNA');
    m.set('method_short_mwl', 'MWL');
    m.set('asr_short_standard', 'Standard');
    m.set('asr_short_hanafi', 'Hanafi');
    m.set('source_short_local', 'Local');
    m.set('source_short_online', 'Online');
    m.set('mark_all', 'Mark all');

    m.set('theme_preset_current_desc', 'Warm cream and deep green — the original');
    m.set('theme_preset_harmony7_desc', 'Radiant violet — serene and modern');
    m.set('theme_preset_harmony6_desc', 'Golden amber — the calm of first light');
    m.set('theme_preset_harmony5_desc', 'Cool teal — vast, fresh, and clear');

    m.set('theme_preset', 'App Theme');
    m.set('theme_preset_desc', 'Choose the visual style of the app');
    m.set('theme_preset_current', 'Sirat Classic');
    m.set('theme_preset_harmony7', 'Noor');
    m.set('theme_preset_harmony6', 'Sahar');
    m.set('theme_preset_harmony5', 'Bahar');

    // ---- Fallbacks ----
    m.set('default_location', 'Default Location');
    m.set('unknown_location', 'Unknown location');

    // ---- Dialogs ----
    m.set('dialog_gps_off_title', 'Location is disabled');
    m.set('dialog_gps_off_message',
      'Please enable location services to get accurate prayer times for your city.');
    m.set('dialog_permission_title', 'Permission required');
    m.set('dialog_permission_message',
      'Location permission is required to show prayer times for your city.\nPlease grant it in system settings.');

    // ---- Errors ----
    m.set('error_gps_fetch_failed', 'Failed to fetch GPS location');
    m.set('error_gps_off', 'Please turn on location services');
    m.set('error_location_permission_denied', 'Location permission denied');

    m.set('wizard_theme_title', 'Choose your theme');
    m.set('wizard_theme_desc', 'Pick a visual style. You can change this anytime in Settings.');

    m.set('sound_feedback', 'Sound');
    m.set('sound_feedback_desc', 'Play a click when counting Tasbih');

    // ---- Tasbih sound names ----
    m.set('sound_glass_tap_name', 'Glass Tap');
    m.set('sound_glass_tap_desc', 'Glass tap sound');
    m.set('sound_light_chime_name', 'Light Chime');
    m.set('sound_light_chime_desc', 'Light chime sound');
    m.set('sound_muted_bead_name', 'Muted Bead');
    m.set('sound_muted_bead_desc', 'Muted bead sound');
    m.set('sound_soft_click_name', 'Soft Click');
    m.set('sound_soft_click_desc', 'Soft click sound');
    m.set('sound_warm_knock_name', 'Warm Knock');
    m.set('sound_warm_knock_desc', 'Warm knock sound');

    m.set('sound_style', 'Sound Style');
    m.set('sound_style_desc', 'Choose the click sound');
    m.set('controlled_by_system', 'Controlled by system settings');

    // ---- Qibla calibration ----
    m.set('qibla_calibrate_title', 'Calibrate Compass');
    m.set('qibla_calibrate_desc',
      'Move your phone in a figure-8 pattern to improve compass accuracy.');
    m.set('qibla_calibrate_skip', 'Skip for now');
    m.set('qibla_calibrate_hint', 'Calibration improves accuracy');

    return m;
  }

  // ============================================================
  // CHINESE
  // ============================================================

  private static buildZh(): Map<string, string> {
    const m = new Map<string, string>();

    m.set('app_name', 'Sirat 伴侣');
    m.set('app_tagline', '您的每日伊斯兰伴侣');
    m.set('more_languages_coming', '更多语言即将推出');

    m.set('tab_home', '首页');
    m.set('tab_tasbih', '念珠');
    m.set('tab_compass', '指南针');
    m.set('tab_calendar', '日历');

    m.set('current_prayer', '当前');
    m.set('next_prayer', '下一个');
    m.set('todays_prayers', '今日礼拜');
    m.set('extra_timings', '额外时间');
    m.set('upcoming_islamic_events', '即将到来的伊斯兰节日');
    m.set('loading_location', '加载中...');
    m.set('set_manual_location', '在设置中设置手动位置');
    m.set('online_prayer_times', '在线礼拜时间');
    m.set('coming_soon', '即将推出');
    m.set('online_switch_hint', '请在设置中切换回本地公式以查看您所在位置的礼拜时间。');

    m.set('cancel', '取消');
    m.set('save', '保存');
    m.set('reset', '重置');
    m.set('delete', '删除');
    m.set('edit', '编辑');
    m.set('add', '添加');
    m.set('back', '返回');
    m.set('today', '今天');
    m.set('exit', '退出');
    m.set('exit_confirm_message', '您确定要退出 Sirat 伴侣吗？');

    m.set('title_settings', '设置');
    m.set('title_customize', '自定义');

    m.set('category_prayer_times', '礼拜时间');
    m.set('category_hijri_calendar', '回历');
    m.set('category_ui_customization', '界面自定义');
    m.set('category_appearance', '外观');
    m.set('category_about', '关于');
    m.set('category_notifications', '通知');

    m.set('theme_preset_current_desc', '暖米色与深绿 — 经典原版');
    m.set('theme_preset_harmony7_desc', '光辉紫罗兰 — 宁静现代');
    m.set('theme_preset_harmony6_desc', '晨曦琥珀 — 初光之静');
    m.set('theme_preset_harmony5_desc', '海韵青绿 — 辽阔清爽');

    m.set('convention', '计算方式');
    m.set('convention_desc', '用于计算晨礼和宵礼');
    m.set('madhab', '教法学派');
    m.set('madhab_desc', '用于计算晡礼的阴影规则');
    m.set('source', '来源');
    m.set('source_desc', '本地公式或在线');
    m.set('prayer_offsets', '礼拜时间偏移');
    m.set('prayer_offsets_desc', '手动调整计算时间');
    m.set('offsets_hint', '以分钟为单位调整时间（−60 至 +60）');
    m.set('reset_all_offsets', '重置全部偏移');

    m.set('high_latitude', '高纬度');
    m.set('high_latitude_desc', '当太阳未到达所需角度时，晨礼和宵礼的回退方式');
    m.set('highlat_none', '无');
    m.set('highlat_middle', '夜半');
    m.set('highlat_one_seventh', '七分之一夜');
    m.set('highlat_angle', '基于角度');

    m.set('location', '位置');
    m.set('location_desc', '选择应用如何确定您的位置');
    m.set('gps', 'GPS');
    m.set('manual_location', '手动位置');
    m.set('current_position', '当前位置');
    m.set('latitude', '纬度');
    m.set('longitude', '经度');
    m.set('city', '城市');
    m.set('last_refreshed', '最后更新');
    m.set('save_coordinates', '保存坐标');
    m.set('latitude_hint', '纬度  (−90 至 90)');
    m.set('longitude_hint', '经度  (−180 至 180)');
    m.set('city_name_optional', '城市名称（可选）');
    m.set('city_name_placeholder', '留空自动检测');

    m.set('hijri_offset', '回历日期与日历偏移');
    m.set('hijri_offset_desc', '将伊斯兰日期和日历同时偏移 ±3 天');
    m.set('matching_standard', '与标准计算一致');
    m.set('offset_days_ahead', '天提前');
    m.set('offset_days_behind', '天延后');

    m.set('about_version', '版本');
    m.set('about_platform', '平台');
    m.set('about_copyright', '© 2026');

    m.set('notifications_master', '启用通知');
    m.set('notifications_master_desc', '在礼拜前和礼拜时接收提醒');
    m.set('notify_before', '提前通知');
    m.set('notify_before_desc', '第一个提醒在礼拜前多少分钟发送');
    m.set('notify_prayers', '礼拜提醒');
    m.set('notify_prayers_desc', '选择哪些礼拜发送提醒');
    m.set('notifications_footer', '提醒已安排在未来 3 天内，每次打开应用都会重新安排');
    m.set('notification_permission_denied', '需要通知权限才能启用提醒');
    m.set('notif_before_title', '礼拜提醒');
    m.set('notif_before_content', '距离');
    m.set('notif_exact_title', '礼拜时间');
    m.set('notif_exact_content', '现在是');
    m.set('notif_minutes_suffix', '分钟');
    m.set('notif_test_button', '发送测试通知');
    m.set('notif_test_sending', '正在发送测试通知...');
    m.set('notif_test_ok', '测试通知已安排 — 约 5 秒后您将看到它');
    m.set('notif_test_failed', '测试通知失败');

    m.set('log_view_button', '诊断日志');
    m.set('log_view_desc', '查看、复制或清除应用日志文件');
    m.set('log_view_title', '诊断日志');
    m.set('log_copy', '复制');
    m.set('log_clear', '清除');
    m.set('log_empty', '日志为空。');
    m.set('sun_path_we_are_here', '我们在这里');
    m.set('log_copied', '日志已复制到剪贴板');
    m.set('log_cleared', '日志已清除');

    m.set('show_extra_timings', '显示额外时间');
    m.set('show_extra_timings_desc', '封斋、日出、日落和夜间时间');
    m.set('show_islamic_events', '显示伊斯兰节日');
    m.set('show_islamic_events_desc', '在首页显示即将到来的伊斯兰节日');

    m.set('dark_mode', '深色模式');
    m.set('dark_mode_desc', '选择应用的外观');
    m.set('theme_light', '浅色');
    m.set('theme_dark', '深色');
    m.set('theme_system', '跟随系统');
    m.set('tasbih_render_style', '念珠主题');
    m.set('tasbih_render_style_desc', '选择念珠的样式');
    m.set('bead_style_premium', '高级（3D）');
    m.set('bead_style_classic', '经典');

    m.set('language', '语言');
    m.set('language_desc', '选择您偏好的语言');
    m.set('lang_en', 'English (英语)');
    m.set('lang_zh', '中文');
    m.set('lang_ar', 'العربية (阿拉伯语)');

    m.set('haptic_feedback', '振动');
    m.set('haptic_feedback_desc', '念珠计数时振动');

    m.set('title_tasbih', '念珠');
    m.set('my_tasbihs', '我的念珠');
    m.set('select_dhikr', '选择念词');
    m.set('new_tasbih', '新念珠');
    m.set('edit_tasbih', '编辑念珠');
    m.set('new_dhikr', '新念词');
    m.set('edit_dhikr', '编辑念词');
    m.set('tasbih_name', '名称');
    m.set('tasbih_name_placeholder', '例如：晚间赞念');
    m.set('dhikr_arabic', '阿拉伯语');
    m.set('dhikr_transliteration', '音译（可选）');
    m.set('dhikr_transliteration_placeholder', '例如：SubhanAllah');
    m.set('dhikr_translation', '翻译（可选）');
    m.set('dhikr_translation_placeholder', '例如：荣耀归于安拉');
    m.set('target_count', '目标次数');
    m.set('flick_up_to_count', '上滑计数');
    m.set('flick_hint', '上滑：+1     ·     下滑：−1');
    m.set('total_on_tasbih', '此念珠总计');
    m.set('dhikr_count_singular', '个念词');
    m.set('dhikr_count_plural', '个念词');
    m.set('new_tasbih_button', '+ 新建念珠');
    m.set('add_dhikr_button', '+ 添加念词');
    m.set('all_dhikrs_complete', '所有念词已完成');
    m.set('counter_reset_toast', '计数器已重置');
    m.set('no_dhikr_title', '此念珠中没有念词');
    m.set('no_dhikr_hint', '点击顶部的念词标签添加');
    m.set('switch_dhikr', '切换念词');
    m.set('reset_counter', '重置计数器');
    m.set('delete_dhikr', '删除念词');
    m.set('add_new_dhikr', '添加新念词');
    m.set('reset_all', '重置全部');
    m.set('reset_all_confirm_title', '重置念珠');
    m.set('reset_all_confirm_message', '重置此念珠中所有念词的计数？');
    m.set('reset_all_done', '念珠已重置');

    m.set('title_qibla', '天房指南针');
    m.set('qibla_direction', '天房方向');
    m.set('device_heading', '设备朝向');
    m.set('distance_to_kaaba', '距天房距离');
    m.set('compass_ready', '指南针已就绪。旋转设备以对准 🕋 标记。');
    m.set('keep_device_flat', '请保持设备水平以获得准确读数。');
    m.set('sensor_unavailable', '指南针传感器不可用。请在真机上测试。');
    m.set('location_unavailable', '位置不可用');

    m.set('title_hijri_calendar', '回历');
    m.set('important_dates', '重要日期');
    m.set('no_events_this_month', '本月没有重大伊斯兰节日');

    m.set('status_next', '下一次');
    m.set('status_pray', '礼拜');
    m.set('status_both', '礼拜 · 下一次');
    m.set('status_prayed', '✓ 已礼');
    m.set('status_express', '抓紧');

    m.set('prayer_fajr', '晨礼');
    m.set('prayer_dhuhr', '晌礼');
    m.set('prayer_asr', '晡礼');
    m.set('prayer_maghrib', '昏礼');
    m.set('prayer_isha', '宵礼');
    m.set('prayer_jummah', '主麻');

    m.set('timing_imsak', '封斋');
    m.set('timing_sunrise', '日出');
    m.set('timing_sunset', '日落');
    m.set('timing_first_third', '第一夜段');
    m.set('timing_midnight', '午夜');
    m.set('timing_last_third', '最后夜段');

    m.set('event_new_year', '伊斯兰新年');
    m.set('event_ashura', '阿舒拉日');
    m.set('event_mawlid', '圣纪节');
    m.set('event_isra_miraj', '登霄夜');
    m.set('event_mid_shaban', '舍尔邦月中');
    m.set('event_ramadan_start', '斋月');
    m.set('event_eid_fitr', '开斋节');
    m.set('event_arafah', '阿拉法日');
    m.set('event_eid_adha', '宰牲节');

    m.set('method_karachi', '卡拉奇伊斯兰科学大学');
    m.set('method_jafari', '什叶派十二伊玛目派（库姆列瓦研究所）');
    m.set('method_isna', '北美伊斯兰协会');
    m.set('method_mwl', '穆斯林世界联盟');
    m.set('asr_standard', '标准（沙斐仪 / 马立克 / 罕百里）');
    m.set('asr_hanafi', '哈乃斐');
    m.set('source_local', '本地公式（离线）');
    m.set('source_api', '在线 API');

    m.set('wizard_step', '步骤');
    m.set('wizard_welcome_title', '欢迎使用 Sirat 伴侣');
    m.set('wizard_welcome_desc', '让我们设置您的偏好。您可以随时在设置中更改。');
    m.set('wizard_language_title', '选择语言');
    m.set('wizard_language_desc', '应用将在所有界面使用此语言');
    m.set('wizard_privacy_title', '隐私政策');
    m.set('wizard_privacy_desc', '请在继续之前阅读并接受');
    m.set('privacy_agree_label', '我已阅读并同意隐私政策');
    m.set('privacy_view_full', '在线查看完整隐私政策');
    m.set('wizard_location_title', '设置位置');
    m.set('wizard_location_desc', '用于礼拜时间和天房方向');
    m.set('wizard_convention_title', '计算偏好');
    m.set('wizard_convention_desc', '选择如何计算礼拜时间');
    m.set('wizard_grant_permission', '授予位置权限');
    m.set('wizard_getting_location', '正在定位...');
    m.set('wizard_location_ready', '位置已检测');
    m.set('wizard_location_failed', '无法获取位置');
    m.set('wizard_retry', '重试');
    m.set('wizard_next', '下一步');
    m.set('wizard_finish', '开始使用');
    m.set('notif_dismiss', '关闭');
    // ---- Tasbih theme presets ----
    m.set('theme_amber', '琥珀');
    m.set('theme_charcoal', '炭黑');
    m.set('theme_emerald', '翡翠');
    m.set('theme_pearl', '珍珠');
    m.set('theme_gold', '金色（金属）');
    m.set('tab_prayers', '礼拜');

    m.set('theme_preset', '应用主题');
    m.set('theme_preset_desc', '选择应用的视觉风格');
    m.set('theme_preset_current', 'Sirat 经典');
    m.set('theme_preset_harmony7', 'Noor · 光辉');
    m.set('theme_preset_harmony6', 'Sahar · 晨曦');
    m.set('theme_preset_harmony5', 'Bahar · 海韵');

    // ---- Home dashboard ----
    m.set('home_today_progress', '今日进度');
    m.set('home_prayers_completed', '次礼拜已完成');
    m.set('home_keep_going', '继续保持！');
    m.set('home_streak', '天连续');
    m.set('home_best_streak', '最佳');
    m.set('home_days', '天');
    m.set('home_this_week', '本周');
    m.set('home_week_summary', '次礼拜本周');
    m.set('home_this_month', '本月');
    m.set('home_month_summary', '次礼拜本月');
    m.set('home_tasbih', '念珠');
    m.set('home_tasbih_lifetime', '累计计数');
    m.set('home_tasbih_summary', '串念珠');
    m.set('home_dhikrs', '个念词');

    // ---- Tabs ----
    m.set('tab_prayers', '礼拜');

    // ---- Home dashboard ----
    m.set('home_today_progress', '今日进度');
    m.set('home_prayers_completed', '次礼拜已完成');
    m.set('home_keep_going', '继续保持！');
    m.set('home_streak', '天连续');
    m.set('home_best_streak', '最佳');
    m.set('home_days', '天');
    m.set('home_this_week', '本周');
    m.set('home_week_summary', '次礼拜本周');
    m.set('home_month_summary', '次礼拜本月');
    m.set('home_tasbih', '念珠');
    m.set('home_tasbih_lifetime', '累计计数');
    m.set('home_tasbih_summary', '串念珠');
    m.set('home_dhikrs', '个念词');

    // ---- Monthly view ----
    m.set('home_monthly_view', '月度视图');
    m.set('home_perfect_days', '完美日');
    m.set('home_days_elapsed', '已过天数');
    m.set('home_lifetime_1y', '次礼拜（近一年）');

    // ---- Event countdown ----
    m.set('home_next_event', '下一个事件');
    m.set('home_event_today', '就是今天！');
    m.set('home_event_tomorrow', '明天');

    // ---- Ramadan card ----
    m.set('ramadan_card_title', '斋月');
    m.set('ramadan_day_of', '第');
    m.set('ramadan_day_of_suffix', '天');
    m.set('ramadan_days_until', '距斋月开始还有');
    m.set('ramadan_fast_start', '封斋开始（Imsak）');
    m.set('ramadan_fast_end', '开斋时间（Maghrib）');
    m.set('ramadan_today_fast', '今日斋戒时段');
    m.set('ramadan_first_day_fast', '斋月第一天');
    m.set('ramadan_calendar_start', '斋月开始');
    m.set('ramadan_calendar_end', '斋月结束');
    m.set('ramadan_ashras', '三个十日');
    m.set('ramadan_first_ashra', '第一个十日');
    m.set('ramadan_second_ashra', '第二个十日');
    m.set('ramadan_third_ashra', '第三个十日');
    m.set('ramadan_first_ashra_significance', '慈悯之旬');
    m.set('ramadan_second_ashra_significance', '宽恕之旬');
    m.set('ramadan_third_ashra_significance', '免于火狱之旬');
    m.set('ramadan_laylat_al_qadr', '高贵之夜');
    m.set('ramadan_laylat_al_qadr_desc',
      '高贵之夜贵过千月。请在斋月最后十天的奇数夜中寻找它。');
    m.set('ramadan_jummah_tul_widah', '辞别主麻');
    m.set('ramadan_jummah_tul_widah_desc', '斋月的最后一个主麻日。');
    m.set('ramadan_today', '今晚！');

    // ---- Live countdown (last 15 min before Imsak / Maghrib) ----
    m.set('countdown_fast_ends', '距开斋还有');
    m.set('countdown_fast_starts', '距封斋还有');
    m.set('countdown_fast_ends_desc', '准备开斋');
    m.set('countdown_fast_starts_desc', '请在封斋前完成封斋饭');

    m.set('wizard_theme_title', '选择主题');
    m.set('wizard_theme_desc', '选择一种视觉风格。您可以随时在设置中更改。');

    // ---- Duas ----
    m.set('dua_iftar_name', '开斋祈祷词');
    m.set('dua_iftar_translation',
      '干渴已消，血管已润，若真主意欲，报酬已定。');
    m.set('dua_suhoor_name', '封斋举意');
    m.set('dua_suhoor_translation',
      '我举意为明天在莱麦丹月封斋。');

    // ---- Generic UI ----
    m.set('ok', '确定');
    m.set('gps', 'GPS');
    m.set('mark_all', '全部标记');

    // ---- About ----
    m.set('about_build', '构建号');
    m.set('about_bundle', '应用包名');
    m.set('about_platform_value', 'HarmonyOS 5+');

    // ---- Short labels ----
    m.set('method_short_karachi', '卡拉奇');
    m.set('method_short_jafari', '贾法里');
    m.set('method_short_isna', 'ISNA');
    m.set('method_short_mwl', 'MWL');
    m.set('asr_short_standard', '标准');
    m.set('asr_short_hanafi', '哈乃斐');
    m.set('source_short_local', '本地');
    m.set('source_short_online', '在线');

    // ---- Fallbacks ----
    m.set('default_location', '默认位置');
    m.set('unknown_location', '未知位置');

    m.set('brand_primary', 'Sirat');
    m.set('brand_accent', '伴侣');

    // ---- Dialogs ----
    m.set('dialog_gps_off_title', '定位服务已关闭');
    m.set('dialog_gps_off_message', '请开启定位服务，以便为您所在城市准确计算礼拜时间。');
    m.set('dialog_permission_title', '需要权限');
    m.set('dialog_permission_message', '需要位置权限才能显示您所在城市的礼拜时间。\n请在系统设置中授予。');

    // ---- Errors ----
    m.set('error_gps_fetch_failed', '无法获取 GPS 位置');
    m.set('error_gps_off', '请开启定位服务');
    m.set('error_location_permission_denied', '位置权限被拒绝');

    m.set('sound_feedback', '声音');
    m.set('sound_feedback_desc', '念珠计数时播放提示音');

    // ---- Tasbih sound names ----
    m.set('sound_glass_tap_name', '玻璃轻敲');
    m.set('sound_glass_tap_desc', '玻璃轻敲音效');
    m.set('sound_light_chime_name', '轻铃');
    m.set('sound_light_chime_desc', '轻铃音效');
    m.set('sound_muted_bead_name', '闷珠');
    m.set('sound_muted_bead_desc', '闷珠音效');
    m.set('sound_soft_click_name', '轻点');
    m.set('sound_soft_click_desc', '轻点音效');
    m.set('sound_warm_knock_name', '暖扣');
    m.set('sound_warm_knock_desc', '暖扣音效');

    m.set('sound_style', '音效');
    m.set('sound_style_desc', '选择点击音效');
    m.set('controlled_by_system', '受系统设置控制');

    // ---- Qibla calibration ----
    m.set('qibla_calibrate_title', '校准指南针');
    m.set('qibla_calibrate_desc', '请以 8 字形摆动手机，以提高指南针精度。');
    m.set('qibla_calibrate_skip', '暂时跳过');
    m.set('qibla_calibrate_hint', '校准可提高精度');

    return m;
  }

  // ============================================================
  // ARABIC
  // ============================================================

  private static buildAr(): Map<string, string> {
    const m = new Map<string, string>();

    m.set('app_name', 'رفيق الصراط');
    m.set('app_tagline', 'رفيقك الإسلامي اليومي');
    m.set('more_languages_coming', 'المزيد من اللغات قريباً');

    m.set('tab_home', 'الرئيسية');
    m.set('tab_tasbih', 'التسبيح');
    m.set('tab_compass', 'القبلة');
    m.set('tab_calendar', 'التقويم');

    m.set('theme_preset_current_desc', 'كريمي دافئ وأخضر غامق — الأصلي');
    m.set('theme_preset_harmony7_desc', 'بنفسجي مشرق — هدوء وحداثة');
    m.set('theme_preset_harmony6_desc', 'كهرماني ذهبي — سكون الفجر');
    m.set('theme_preset_harmony5_desc', 'أزرق مخضرّ بارد — رحب ونقي');

    m.set('wizard_theme_title', 'اختر مظهرك');
    m.set('wizard_theme_desc', 'اختر النمط البصري. يمكنك تغييره لاحقاً من الإعدادات.');

    m.set('sound_feedback', 'الصوت');
    m.set('sound_feedback_desc', 'تشغيل نقرة عند عدّ التسبيح');

    m.set('current_prayer', 'الحالي');
    m.set('next_prayer', 'التالي');
    m.set('todays_prayers', 'صلوات اليوم');
    m.set('extra_timings', 'الأوقات الإضافية');
    m.set('upcoming_islamic_events', 'المناسبات الإسلامية القادمة');
    m.set('loading_location', 'جارٍ التحميل...');
    m.set('set_manual_location', 'حدّد الموقع يدوياً من الإعدادات');
    m.set('online_prayer_times', 'أوقات الصلاة عبر الإنترنت');
    m.set('coming_soon', 'قريباً');
    m.set('online_switch_hint', 'عُد إلى الحساب المحلي من الإعدادات لعرض أوقات الصلاة لموقعك.');

    m.set('cancel', 'إلغاء');
    m.set('save', 'حفظ');
    m.set('reset', 'إعادة تعيين');
    m.set('delete', 'حذف');
    m.set('edit', 'تعديل');
    m.set('add', 'إضافة');
    m.set('back', 'رجوع');
    m.set('today', 'اليوم');
    m.set('exit', 'خروج');
    m.set('exit_confirm_message', 'هل أنت متأكد من الخروج من رفيق الصراط؟');

    m.set('title_settings', 'الإعدادات');
    m.set('title_customize', 'التخصيص');

    m.set('category_prayer_times', 'أوقات الصلاة');
    m.set('category_hijri_calendar', 'التقويم الهجري');
    m.set('category_ui_customization', 'تخصيص الواجهة');
    m.set('category_appearance', 'المظهر');
    m.set('category_about', 'حول التطبيق');
    m.set('category_notifications', 'الإشعارات');

    m.set('convention', 'طريقة الحساب');
    m.set('convention_desc', 'تُستخدم لحساب الفجر والعشاء');
    m.set('madhab', 'المذهب');
    m.set('madhab_desc', 'قاعدة ظل العصر المستخدمة في الحساب');
    m.set('source', 'المصدر');
    m.set('source_desc', 'الحساب المحلي أو عبر الإنترنت');
    m.set('prayer_offsets', 'تعديلات الصلاة');
    m.set('prayer_offsets_desc', 'تعديل الأوقات المحسوبة يدوياً');
    m.set('offsets_hint', 'عدّل الأوقات بالدقائق (−60 إلى +60)');
    m.set('reset_all_offsets', 'إعادة تعيين جميع التعديلات');

    m.set('high_latitude', 'خطوط العرض العليا');
    m.set('high_latitude_desc', 'طريقة احتياطية للفجر والعشاء عندما لا تصل الشمس إلى الزاوية المطلوبة');
    m.set('highlat_none', 'بدون');
    m.set('highlat_middle', 'منتصف الليل');
    m.set('highlat_one_seventh', 'سُبع الليل');
    m.set('highlat_angle', 'حسب الزاوية');

    m.set('location', 'الموقع');
    m.set('location_desc', 'اختر كيف يحدد التطبيق موقعك');
    m.set('gps', 'GPS');
    m.set('manual_location', 'موقع يدوي');
    m.set('current_position', 'الموقع الحالي');
    m.set('latitude', 'خط العرض');
    m.set('longitude', 'خط الطول');
    m.set('city', 'المدينة');
    m.set('last_refreshed', 'آخر تحديث');
    m.set('save_coordinates', 'حفظ الإحداثيات');
    m.set('latitude_hint', 'خط العرض  (−90 إلى 90)');
    m.set('longitude_hint', 'خط الطول  (−180 إلى 180)');
    m.set('city_name_optional', 'اسم المدينة (اختياري)');
    m.set('city_name_placeholder', 'اتركه فارغاً للكشف التلقائي');

    m.set('hijri_offset', 'إزاحة التاريخ والتقويم الهجري');
    m.set('hijri_offset_desc', 'أزح التاريخ والتقويم الإسلامي بمقدار ±3 أيام');
    m.set('matching_standard', 'مطابق للحساب القياسي');
    m.set('offset_days_ahead', 'يوم متقدم');
    m.set('offset_days_behind', 'يوم متأخر');

    m.set('about_version', 'الإصدار');
    m.set('about_platform', 'المنصة');
    m.set('about_copyright', '© 2026');

    m.set('notifications_master', 'تفعيل الإشعارات');
    m.set('notifications_master_desc', 'تذكيرات قبل وقت الصلاة وعنده');
    m.set('notify_before', 'التنبيه قبل');
    m.set('notify_before_desc', 'كم دقيقة قبل الصلاة لإرسال التنبيه الأول');
    m.set('notify_prayers', 'تذكيرات الصلاة');
    m.set('notify_prayers_desc', 'اختر الصلوات التي تُرسل تذكيرات');
    m.set('notifications_footer', 'التذكيرات مُجدولة للأيام الثلاثة القادمة وتتجدد في كل مرة تفتح فيها التطبيق');
    m.set('notification_permission_denied', 'إذن الإشعارات مطلوب لتفعيل التذكيرات');
    m.set('notif_before_title', 'تذكير بالصلاة');
    m.set('notif_before_content', 'بعد');
    m.set('notif_exact_title', 'وقت الصلاة');
    m.set('notif_exact_content', 'حان الآن وقت صلاة');
    m.set('notif_minutes_suffix', 'دقيقة');
    m.set('notif_test_button', 'إرسال إشعار تجريبي');
    m.set('notif_test_sending', 'جارٍ إرسال الإشعار التجريبي...');
    m.set('notif_test_ok', 'تم جدولة الإشعار التجريبي — سيظهر خلال 5 ثوانٍ');
    m.set('notif_test_failed', 'فشل الإشعار التجريبي');

    m.set('log_view_button', 'سجلات التشخيص');
    m.set('log_view_desc', 'عرض أو نسخ أو مسح ملف سجل التطبيق');
    m.set('log_view_title', 'سجلات التشخيص');
    m.set('log_copy', 'نسخ');
    m.set('log_clear', 'مسح');
    m.set('log_empty', 'السجل فارغ.');
    m.set('log_copied', 'تم نسخ السجل إلى الحافظة');
    m.set('log_cleared', 'تم مسح السجل');

    m.set('show_extra_timings', 'إظهار الأوقات الإضافية');
    m.set('show_extra_timings_desc', 'الإمساك والشروق والغروب وأوقات الليل');
    m.set('show_islamic_events', 'إظهار المناسبات الإسلامية');
    m.set('show_islamic_events_desc', 'المناسبات الإسلامية القادمة في الشاشة الرئيسية');

    m.set('dark_mode', 'الوضع الداكن');
    m.set('dark_mode_desc', 'اختر مظهر التطبيق');
    m.set('theme_light', 'فاتح');
    m.set('theme_dark', 'داكن');
    m.set('theme_system', 'حسب إعدادات النظام');
    m.set('tasbih_render_style', 'نمط المسبحة');
    m.set('tasbih_render_style_desc', 'اختر نمط خرزات المسبحة');
    m.set('bead_style_premium', 'متميز (ثلاثي الأبعاد)');
    m.set('bead_style_classic', 'كلاسيكي');

    m.set('language', 'اللغة');
    m.set('language_desc', 'اختر لغتك المفضلة');
    m.set('lang_en', 'English (الإنجليزية)');
    m.set('lang_zh', '中文 (الصينية)');
    m.set('lang_ar', 'العربية');

    m.set('haptic_feedback', 'الاهتزاز');
    m.set('haptic_feedback_desc', 'اهتزاز عند عدّ التسبيح');

    m.set('title_tasbih', 'التسبيح');
    m.set('my_tasbihs', 'مسبحاتي');
    m.set('select_dhikr', 'اختر الذكر');
    m.set('new_tasbih', 'مسبحة جديدة');
    m.set('edit_tasbih', 'تعديل المسبحة');
    m.set('new_dhikr', 'ذكر جديد');
    m.set('edit_dhikr', 'تعديل الذكر');
    m.set('tasbih_name', 'الاسم');
    m.set('tasbih_name_placeholder', 'مثال: أذكار المساء');
    m.set('dhikr_arabic', 'العربية');
    m.set('dhikr_transliteration', 'النقل الصوتي (اختياري)');
    m.set('dhikr_transliteration_placeholder', 'مثال: SubhanAllah');
    m.set('dhikr_translation', 'الترجمة (اختياري)');
    m.set('dhikr_translation_placeholder', 'مثال: سبحان الله');
    m.set('target_count', 'العدد المستهدف');
    m.set('flick_up_to_count', 'اسحب لأعلى للعدّ');
    m.set('flick_hint', 'اسحب لأعلى: +1     ·     اسحب لأسفل: −1');
    m.set('total_on_tasbih', 'الإجمالي على هذه المسبحة');
    m.set('dhikr_count_singular', 'ذكر');
    m.set('dhikr_count_plural', 'أذكار');
    m.set('new_tasbih_button', '+ مسبحة جديدة');
    m.set('add_dhikr_button', '+ إضافة ذكر');
    m.set('all_dhikrs_complete', 'اكتملت جميع الأذكار');
    m.set('counter_reset_toast', 'تم إعادة تعيين العداد');
    m.set('no_dhikr_title', 'لا يوجد ذكر في هذه المسبحة');
    m.set('no_dhikr_hint', 'اضغط على شريحة الذكر في الأعلى للإضافة');
    m.set('switch_dhikr', 'تبديل الذكر');
    m.set('reset_counter', 'إعادة تعيين العداد');
    m.set('delete_dhikr', 'حذف الذكر');
    m.set('add_new_dhikr', 'إضافة ذكر جديد');
    m.set('reset_all', 'إعادة تعيين الكل');
    m.set('reset_all_confirm_title', 'إعادة تعيين المسبحة');
    m.set('reset_all_confirm_message', 'هل تريد إعادة تعيين جميع الأذكار في هذه المسبحة؟');
    m.set('reset_all_done', 'تم إعادة تعيين المسبحة');

    m.set('title_qibla', 'بوصلة القبلة');
    m.set('qibla_direction', 'اتجاه القبلة');
    m.set('device_heading', 'اتجاه الجهاز');
    m.set('distance_to_kaaba', 'المسافة إلى الكعبة');
    m.set('compass_ready', 'البوصلة جاهزة. أدر جهازك لمحاذاة علامة 🕋.');
    m.set('keep_device_flat', 'حافظ على جهازك مستوياً للحصول على قراءات دقيقة.');
    m.set('sensor_unavailable', 'مستشعر البوصلة غير متوفر. يُرجى الاختبار على جهاز حقيقي.');
    m.set('location_unavailable', 'الموقع غير متوفر');

    m.set('title_hijri_calendar', 'التقويم الهجري');
    m.set('important_dates', 'التواريخ المهمة');
    m.set('no_events_this_month', 'لا توجد مناسبات إسلامية كبرى هذا الشهر');

    m.set('status_next', 'التالية');
    m.set('status_pray', 'صلِّ');
    m.set('status_both', 'صلِّ · التالية');
    m.set('status_prayed', '✓ صلّيت');
    m.set('status_express', 'سريع');

    m.set('prayer_fajr', 'الفجر');
    m.set('prayer_dhuhr', 'الظهر');
    m.set('prayer_asr', 'العصر');
    m.set('prayer_maghrib', 'المغرب');
    m.set('prayer_isha', 'العشاء');
    m.set('prayer_jummah', 'الجمعة');

    m.set('timing_imsak', 'الإمساك');
    m.set('timing_sunrise', 'الشروق');
    m.set('timing_sunset', 'الغروب');
    m.set('timing_first_third', 'الثلث الأول');
    m.set('timing_midnight', 'منتصف الليل');
    m.set('timing_last_third', 'الثلث الأخير');

    m.set('event_new_year', 'رأس السنة الهجرية');
    m.set('event_ashura', 'يوم عاشوراء');
    m.set('event_mawlid', 'المولد النبوي');
    m.set('event_isra_miraj', 'الإسراء والمعراج');
    m.set('event_mid_shaban', 'ليلة النصف من شعبان');
    m.set('event_ramadan_start', 'رمضان');
    m.set('event_eid_fitr', 'عيد الفطر');
    m.set('event_arafah', 'يوم عرفة');
    m.set('event_eid_adha', 'عيد الأضحى');

    m.set('method_karachi', 'جامعة العلوم الإسلامية بكراتشي');
    m.set('method_jafari', 'الشيعة الاثنا عشرية (معهد ليفا، قم)');
    m.set('method_isna', 'الجمعية الإسلامية لأمريكا الشمالية');
    m.set('method_mwl', 'رابطة العالم الإسلامي');
    m.set('asr_standard', 'القياسي (الشافعي / المالكي / الحنبلي)');
    m.set('asr_hanafi', 'الحنفي');
    m.set('source_local', 'الحساب المحلي (دون اتصال)');
    m.set('source_api', 'واجهة برمجية (عبر الإنترنت)');
    m.set('mark_all', 'تحديد الكل');

    m.set('wizard_step', 'خطوة');
    m.set('wizard_welcome_title', 'مرحباً بك في رفيق الصراط');
    m.set('wizard_welcome_desc', 'دعنا نُعِدّ تفضيلاتك. يمكنك تغييرها لاحقاً من الإعدادات.');
    m.set('wizard_language_title', 'اختر لغتك');
    m.set('wizard_language_desc', 'سيستخدم التطبيق هذه اللغة في جميع الشاشات');
    m.set('wizard_privacy_title', 'سياسة الخصوصية');
    m.set('wizard_privacy_desc', 'يرجى القراءة والموافقة قبل المتابعة');
    m.set('privacy_agree_label', 'لقد قرأت وأوافق على سياسة الخصوصية');
    m.set('privacy_view_full', 'عرض سياسة الخصوصية الكاملة عبر الإنترنت');
    m.set('wizard_location_title', 'حدّد موقعك');
    m.set('wizard_location_desc', 'يُستخدم لحساب أوقات الصلاة واتجاه القبلة');
    m.set('wizard_convention_title', 'تفضيلات الحساب');
    m.set('wizard_convention_desc', 'اختر طريقة حساب أوقات الصلاة');
    m.set('wizard_grant_permission', 'منح إذن الموقع');
    m.set('wizard_getting_location', 'جارٍ تحديد موقعك...');
    m.set('wizard_location_ready', 'تم تحديد الموقع');
    m.set('wizard_location_failed', 'تعذّر الحصول على الموقع');
    m.set('wizard_retry', 'إعادة المحاولة');
    m.set('wizard_next', 'التالي');
    m.set('wizard_finish', 'ابدأ الآن');
    m.set('notif_dismiss', 'إغلاق');
    // ---- Tasbih theme presets ----
    m.set('theme_amber', 'كهرماني');
    m.set('theme_charcoal', 'فحمي');
    m.set('theme_emerald', 'زمردي');
    m.set('theme_pearl', 'لؤلؤي');
    m.set('theme_gold', 'ذهبي (معدني)');
    m.set('tab_prayers', 'الصلاة');

    // ---- Home dashboard ----
    m.set('home_today_progress', 'تقدم اليوم');
    m.set('home_prayers_completed', 'صلوات مكتملة');
    m.set('home_keep_going', 'واصل!');
    m.set('home_streak', 'يوم متتالي');
    m.set('home_best_streak', 'الأفضل');
    m.set('home_days', 'أيام');
    m.set('home_this_week', 'هذا الأسبوع');
    m.set('home_week_summary', 'صلاة هذا الأسبوع');
    m.set('home_this_month', 'هذا الشهر');
    m.set('home_month_summary', 'صلاة هذا الشهر');
    m.set('home_tasbih', 'التسبيح');
    m.set('home_tasbih_lifetime', 'العدد الإجمالي');
    m.set('home_tasbih_summary', 'مسبحات');
    m.set('home_dhikrs', 'أذكار');

    // ---- Tabs ----
    m.set('tab_prayers', 'الصلاة');

    // ---- Home dashboard ----
    m.set('home_today_progress', 'تقدم اليوم');
    m.set('home_prayers_completed', 'صلوات مكتملة');
    m.set('home_keep_going', 'واصل!');
    m.set('home_streak', 'يوم متتالي');
    m.set('home_best_streak', 'الأفضل');
    m.set('home_days', 'أيام');
    m.set('home_this_week', 'هذا الأسبوع');
    m.set('home_week_summary', 'صلاة هذا الأسبوع');
    m.set('home_month_summary', 'صلاة هذا الشهر');
    m.set('home_tasbih', 'التسبيح');
    m.set('home_tasbih_lifetime', 'العدد الإجمالي');
    m.set('home_tasbih_summary', 'مسبحات');
    m.set('home_dhikrs', 'أذكار');

    // ---- Monthly view ----
    m.set('home_monthly_view', 'عرض شهري');
    m.set('home_perfect_days', 'أيام كاملة');
    m.set('home_days_elapsed', 'أيام مضت');
    m.set('home_lifetime_1y', 'صلاة خلال العام الماضي');

    // ---- Event countdown ----
    m.set('home_next_event', 'المناسبة القادمة');
    m.set('home_event_today', 'اليوم!');
    m.set('home_event_tomorrow', 'غداً');

    /// ---- Ramadan card ----
    m.set('ramadan_card_title', 'رمضان');
    m.set('ramadan_day_of', 'اليوم');
    m.set('ramadan_day_of_suffix', 'من رمضان');
    m.set('ramadan_days_until', 'يبدأ رمضان بعد');
    m.set('ramadan_fast_start', 'بداية الصيام (الإمساك)');
    m.set('ramadan_fast_end', 'نهاية الصيام (المغرب)');
    m.set('ramadan_today_fast', 'نافذة الصيام اليوم');
    m.set('ramadan_first_day_fast', 'أول يوم من رمضان');
    m.set('ramadan_calendar_start', 'بداية رمضان');
    m.set('ramadan_calendar_end', 'نهاية رمضان');
    m.set('ramadan_ashras', 'العشرات');
    m.set('ramadan_first_ashra', 'العشر الأولى');
    m.set('ramadan_second_ashra', 'العشر الثانية');
    m.set('ramadan_third_ashra', 'العشر الثالثة');
    m.set('ramadan_first_ashra_significance', 'أيام الرحمة');
    m.set('ramadan_second_ashra_significance', 'أيام المغفرة');
    m.set('ramadan_third_ashra_significance', 'العتق من النار');
    m.set('ramadan_laylat_al_qadr', 'ليلة القدر');
    m.set('ramadan_laylat_al_qadr_desc',
      'ليلة القدر خير من ألف شهر. التمسوها في الليالي الوترية من العشر الأواخر.');
    m.set('ramadan_jummah_tul_widah', 'جمعة الوداع');
    m.set('ramadan_jummah_tul_widah_desc', 'آخر جمعة من رمضان.');
    m.set('ramadan_today', 'الليلة!');

    // ---- Live countdown (last 15 min before Imsak / Maghrib) ----
    m.set('countdown_fast_ends', 'الإفطار بعد');
    m.set('countdown_fast_starts', 'يبدأ الصيام بعد');
    m.set('countdown_fast_ends_desc', 'استعد للإفطار');
    m.set('countdown_fast_starts_desc', 'أنهِ السحور قبل الإمساك');

    // ---- Duas ----
    m.set('dua_iftar_name', 'دعاء الإفطار');
    m.set('dua_iftar_translation',
      'ذهب الظمأ وابتلت العروق وثبت الأجر إن شاء الله.');
    m.set('dua_suhoor_name', 'نية الصيام');
    m.set('sun_path_we_are_here', 'نحن هنا');
    m.set('dua_suhoor_translation',
      'وبصوم غدٍ نويت من شهر رمضان.');

    m.set('theme_preset', 'مظهر التطبيق');
    m.set('theme_preset_desc', 'اختر النمط البصري للتطبيق');
    m.set('theme_preset_current', 'Sirat الكلاسيكي');
    m.set('theme_preset_harmony7', 'نور');
    m.set('theme_preset_harmony6', 'سَحَر');
    m.set('theme_preset_harmony5', 'بَحْر');

    // ---- Generic UI ----
    m.set('ok', 'موافق');
    m.set('gps', 'GPS');

    // ---- About ----
    m.set('about_build', 'رقم البناء');
    m.set('about_bundle', 'معرّف الحزمة');
    m.set('about_platform_value', 'HarmonyOS 5+');

    // ---- Short labels ----
    m.set('method_short_karachi', 'كراتشي');
    m.set('method_short_jafari', 'الجعفري');
    m.set('method_short_isna', 'ISNA');
    m.set('method_short_mwl', 'MWL');
    m.set('asr_short_standard', 'القياسي');
    m.set('asr_short_hanafi', 'الحنفي');
    m.set('source_short_local', 'محلي');
    m.set('source_short_online', 'عبر الإنترنت');

    // ---- Fallbacks ----
    m.set('default_location', 'الموقع الافتراضي');
    m.set('unknown_location', 'موقع غير معروف');

    m.set('brand_primary', 'رفيق');
    m.set('brand_accent', 'الصراط');

    // ---- Dialogs ----
    m.set('dialog_gps_off_title', 'خدمة الموقع معطّلة');
    m.set('dialog_gps_off_message',
      'يرجى تمكين خدمة الموقع للحصول على أوقات صلاة دقيقة لمدينتك.');
    m.set('dialog_permission_title', 'الإذن مطلوب');
    m.set('dialog_permission_message',
      'إذن الموقع مطلوب لعرض أوقات الصلاة لمدينتك.\nيرجى منحه من إعدادات النظام.');

    // ---- Errors ----
    m.set('error_gps_fetch_failed', 'تعذّر الحصول على موقع GPS');
    m.set('error_gps_off', 'يرجى تشغيل خدمة الموقع');
    m.set('error_location_permission_denied', 'تم رفض إذن الموقع');

    // ---- Tasbih sound names ----
    m.set('sound_glass_tap_name', 'نقرة زجاجية');
    m.set('sound_glass_tap_desc', 'صوت نقرة زجاجية');
    m.set('sound_light_chime_name', 'جرس خفيف');
    m.set('sound_light_chime_desc', 'صوت جرس خفيف');
    m.set('sound_muted_bead_name', 'خرزة مكتومة');
    m.set('sound_muted_bead_desc', 'صوت خرزة مكتومة');
    m.set('sound_soft_click_name', 'نقرة ناعمة');
    m.set('sound_soft_click_desc', 'صوت نقرة ناعمة');
    m.set('sound_warm_knock_name', 'طرقة دافئة');
    m.set('sound_warm_knock_desc', 'صوت طرقة دافئة');

    m.set('sound_style', 'نمط الصوت');
    m.set('sound_style_desc', 'اختر صوت النقرة');
    m.set('controlled_by_system', 'يُتحكَّم به من إعدادات النظام');

    // ---- Qibla calibration ----
    m.set('qibla_calibrate_title', 'معايرة البوصلة');
    m.set('qibla_calibrate_desc', 'حرّك هاتفك بحركة الرقم 8 لتحسين دقة البوصلة.');
    m.set('qibla_calibrate_skip', 'تخطَّ الآن');
    m.set('qibla_calibrate_hint', 'المعايرة تحسّن الدقة');

    return m;
  }

  // ============================================================
  // ARRAY TABLES
  // ============================================================

  private static readonly MONTHS_EN: string[] = [
    'Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi al-Thani',
    'Jumada al-Awwal', 'Jumada al-Thani', 'Rajab', "Sha'ban",
    'Ramadan', 'Shawwal', "Dhu al-Qi'dah", 'Dhu al-Hijjah'
  ];

  private static readonly MONTHS_ZH: string[] = [
    '穆哈兰姆', '萨法尔', '赖比尔·敖外鲁', '赖比尔·阿色尼',
    '主马达·敖外鲁', '主马达·阿色尼', '赖哲卜', '舍尔邦',
    '赖买丹', '闪瓦鲁', '都尔·盖尔达', '都尔·希哲'
  ];

  private static readonly MONTHS_AR: string[] = [
    'مُحَرَّم', 'صَفَر', 'رَبيع الأوّل', 'رَبيع الثاني',
    'جُمادى الأولى', 'جُمادى الآخرة', 'رَجَب', 'شَعْبان',
    'رَمَضان', 'شَوّال', 'ذو القَعْدة', 'ذو الحِجّة'
  ];

  private static readonly DAYS_EN: string[] = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  private static readonly DAYS_ZH: string[] = ['日', '一', '二', '三', '四', '五', '六'];
  private static readonly DAYS_AR: string[] = ['أحد', 'إثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت'];
}