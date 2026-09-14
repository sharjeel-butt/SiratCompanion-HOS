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

  /**
   * Language-aware RTL check that callers can pass a reactive value to.
   * Pages read their own `currentLanguage` state and pass it here so
   * the direction flips the moment the language changes.
   */
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
  // STRING TABLES — built once at class init
  // ============================================================

  private static readonly EN: Map<string, string> = L.buildEn();
  private static readonly ZH: Map<string, string> = L.buildZh();
  private static readonly AR: Map<string, string> = L.buildAr();

  // ============================================================
  // ENGLISH
  // ============================================================

  private static buildEn(): Map<string, string> {
    const m = new Map<string, string>();
    m.set('app_name', 'Sirat Companion');
    m.set('app_tagline', 'Your Daily Islamic Companion');
    m.set('more_languages_coming', 'More languages coming soon');

    m.set('tab_home', 'Home');
    m.set('tab_tasbih', 'Tasbih');
    m.set('tab_compass', 'Compass');
    m.set('tab_calendar', 'Calendar');

    m.set('current_prayer', 'CURRENT PRAYER');
    m.set('next_prayer', 'NEXT PRAYER');
    m.set('todays_prayers', "TODAY'S PRAYERS");
    m.set('extra_timings', 'EXTRA TIMINGS');
    m.set('upcoming_islamic_events', 'UPCOMING ISLAMIC EVENTS');
    m.set('loading_location', 'Loading...');
    m.set('set_manual_location', 'Set Manual Location in Settings');
    m.set('online_prayer_times', 'Online Prayer Times');
    m.set('coming_soon', 'Coming Soon');
    m.set('online_switch_hint', 'Switch back to Local Formula in Settings to see prayer times for your location.');

    m.set('cancel', 'Cancel');
    m.set('save', 'Save');
    m.set('reset', 'Reset');
    m.set('delete', 'Delete');
    m.set('edit', 'Edit');
    m.set('add', 'Add');
    m.set('back', 'Back');
    m.set('today', 'Today');
    m.set('exit', 'Exit');

    m.set('title_settings', 'Settings');
    m.set('title_customize', 'Customize');
    m.set('category_prayer_times', 'Prayer Times');
    m.set('category_hijri_calendar', 'Hijri Calendar');
    m.set('category_ui_customization', 'UI Customization');
    m.set('category_appearance', 'Appearance');
    m.set('category_about', 'About');

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

    m.set('hijri_offset', 'Hijri Offset');
    m.set('hijri_offset_desc', 'Shift the Islamic date by ±3 days');
    m.set('matching_standard', 'Matching the standard calculation');

    m.set('about_version', 'Version');
    m.set('about_platform', 'Platform');
    m.set('about_copyright', '© 2026');
    m.set('theme_light', 'Light');
    m.set('theme_dark', 'Dark');
    m.set('theme_system', 'Use System Settings');
    m.set('exit_confirm_message', 'Are you sure you want to exit Sirat Companion?');
    m.set('method_karachi', 'University of Islamic Sciences, Karachi');
    m.set('method_jafari', 'Shia Ithna Ashari (Leva Institute, Qum)');
    m.set('method_isna', 'Islamic Society of North America');
    m.set('method_mwl', 'Muslim World League');
    m.set('asr_standard', "Standard (Shafi'i / Maliki / Hanbali)");
    m.set('asr_hanafi', 'Hanafi');
    m.set('source_local', 'Local Formula (Offline)');
    m.set('source_api', 'API (Online)');

    m.set('show_extra_timings', 'Show Extra Timings');
    m.set('show_extra_timings_desc', 'Imsak, Sunrise, Sunset and night times');
    m.set('show_islamic_events', 'Show Islamic Events');
    m.set('show_islamic_events_desc', 'Upcoming Islamic events on home screen');
    m.set('dark_mode', 'Dark Mode');
    m.set('dark_mode_desc', 'Choose how the app looks');
    m.set('language', 'Language');
    m.set('language_desc', 'Choose your preferred language');
    m.set('lang_en', 'English');
    m.set('lang_zh', '中文 (Chinese)');
    m.set('lang_ar', 'العربية (Arabic)');

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

    m.set('title_qibla', 'Qibla Compass');
    m.set('qibla_direction', 'Qibla Direction');
    m.set('device_heading', 'Device Heading');
    m.set('distance_to_kaaba', 'Distance to Kaaba');
    m.set('compass_ready', 'Compass is ready. Rotate your device to align with the 🕋 marker.');
    m.set('keep_device_flat', 'Keep your device flat for accurate readings.');
    m.set('sensor_unavailable', 'Compass sensor not available. Please test on a real device.');
    m.set('location_unavailable', 'Location unavailable');

    m.set('title_hijri_calendar', 'Hijri Calendar');
    m.set('important_dates', 'IMPORTANT DATES');
    m.set('no_events_this_month', 'No major Islamic events this month');

    m.set('status_next', 'NEXT');
    m.set('status_pray', 'Pray');
    m.set('status_both', 'Pray  ·  NEXT');
    m.set('status_prayed', '✓ Prayed');
    m.set('status_express', 'Express');

    m.set('prayer_fajr', 'Fajr');
    m.set('prayer_dhuhr', 'Dhuhr');
    m.set('prayer_asr', 'Asr');
    m.set('prayer_maghrib', 'Maghrib');
    m.set('prayer_isha', 'Isha');
    m.set('prayer_jummah', 'Jummah');

    m.set('timing_imsak', 'Imsak');
    m.set('timing_sunrise', 'Sunrise');
    m.set('timing_sunset', 'Sunset');
    m.set('timing_first_third', 'First Third');
    m.set('timing_midnight', 'Midnight');
    m.set('timing_last_third', 'Last Third');

    m.set('event_new_year', 'Islamic New Year');
    m.set('event_ashura', 'Day of Ashura');
    m.set('event_mawlid', 'Mawlid al-Nabi');
    m.set('event_isra_miraj', "Isra and Mi'raj");
    m.set('event_mid_shaban', "Mid-Sha'ban");
    m.set('event_ramadan_start', 'Ramadan Start');
    m.set('event_eid_fitr', 'Eid al-Fitr');
    m.set('event_arafah', 'Day of Arafah');
    m.set('event_eid_adha', 'Eid al-Adha');
    m.set('wizard_step', 'Step');
    m.set('wizard_welcome_title', 'Welcome to Sirat Companion');
    m.set('wizard_welcome_desc', 'Let us set up your preferences. You can change them anytime in Settings.');
    m.set('wizard_language_title', 'Choose your language');
    m.set('wizard_language_desc', 'The app will use this language across all screens');
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

    m.set('current_prayer', '当前礼拜');
    m.set('next_prayer', '下一次礼拜');
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

    m.set('title_settings', '设置');
    m.set('title_customize', '自定义');
    m.set('category_prayer_times', '礼拜时间');
    m.set('category_hijri_calendar', '回历');
    m.set('category_ui_customization', '界面自定义');
    m.set('category_appearance', '外观');
    m.set('category_about', '关于');

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

    m.set('hijri_offset', '回历偏移');
    m.set('hijri_offset_desc', '将伊斯兰日期偏移 ±3 天');
    m.set('matching_standard', '与标准计算一致');

    m.set('about_version', '版本');
    m.set('about_platform', '平台');
    m.set('about_copyright', '© 2026');
    m.set('theme_light', '浅色');
    m.set('theme_dark', '深色');
    m.set('theme_system', '跟随系统');
    m.set('exit_confirm_message', '您确定要退出 Sirat 伴侣吗？');
    m.set('method_karachi', '卡拉奇伊斯兰科学大学');
    m.set('method_jafari', '什叶派十二伊玛目派（库姆列瓦研究所）');
    m.set('method_isna', '北美伊斯兰协会');
    m.set('method_mwl', '穆斯林世界联盟');
    m.set('asr_standard', '标准（沙斐仪 / 马立克 / 罕百里）');
    m.set('asr_hanafi', '哈乃斐');
    m.set('source_local', '本地公式（离线）');
    m.set('source_api', '在线 API');

    m.set('show_extra_timings', '显示额外时间');
    m.set('show_extra_timings_desc', '封斋、日出、日落和夜间时间');
    m.set('show_islamic_events', '显示伊斯兰节日');
    m.set('show_islamic_events_desc', '在首页显示即将到来的伊斯兰节日');
    m.set('dark_mode', '深色模式');
    m.set('dark_mode_desc', '选择应用的外观');
    m.set('language', '语言');
    m.set('language_desc', '选择您偏好的语言');
    m.set('lang_en', 'English (英语)');
    m.set('lang_zh', '中文');
    m.set('lang_ar', 'العربية (阿拉伯语)');

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
    m.set('event_ramadan_start', '斋月开始');
    m.set('event_eid_fitr', '开斋节');
    m.set('event_arafah', '阿拉法日');
    m.set('event_eid_adha', '宰牲节');
    m.set('wizard_step', '步骤');
    m.set('wizard_welcome_title', '欢迎使用 Sirat 伴侣');
    m.set('wizard_welcome_desc', '让我们设置您的偏好。您可以随时在设置中更改。');
    m.set('wizard_language_title', '选择语言');
    m.set('wizard_language_desc', '应用将在所有界面使用此语言');
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

    m.set('current_prayer', 'الصلاة الحالية');
    m.set('next_prayer', 'الصلاة القادمة');
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

    m.set('title_settings', 'الإعدادات');
    m.set('title_customize', 'التخصيص');
    m.set('category_prayer_times', 'أوقات الصلاة');
    m.set('category_hijri_calendar', 'التقويم الهجري');
    m.set('category_ui_customization', 'تخصيص الواجهة');
    m.set('category_appearance', 'المظهر');
    m.set('category_about', 'حول التطبيق');

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

    m.set('hijri_offset', 'إزاحة التقويم الهجري');
    m.set('hijri_offset_desc', 'أزح التاريخ الإسلامي بمقدار ±3 أيام');
    m.set('matching_standard', 'مطابق للحساب القياسي');

    m.set('about_version', 'الإصدار');
    m.set('about_platform', 'المنصة');
    m.set('about_copyright', '© 2026');
    m.set('theme_light', 'فاتح');
    m.set('theme_dark', 'داكن');
    m.set('theme_system', 'حسب إعدادات النظام');
    m.set('exit_confirm_message', 'هل أنت متأكد من الخروج من رفيق الصراط؟');
    m.set('method_karachi', 'جامعة العلوم الإسلامية بكراتشي');
    m.set('method_jafari', 'الشيعة الاثنا عشرية (معهد ليفا، قم)');
    m.set('method_isna', 'الجمعية الإسلامية لأمريكا الشمالية');
    m.set('method_mwl', 'رابطة العالم الإسلامي');
    m.set('asr_standard', 'القياسي (الشافعي / المالكي / الحنبلي)');
    m.set('asr_hanafi', 'الحنفي');
    m.set('source_local', 'الحساب المحلي (دون اتصال)');
    m.set('source_api', 'واجهة برمجية (عبر الإنترنت)');

    m.set('show_extra_timings', 'إظهار الأوقات الإضافية');
    m.set('show_extra_timings_desc', 'الإمساك والشروق والغروب وأوقات الليل');
    m.set('show_islamic_events', 'إظهار المناسبات الإسلامية');
    m.set('show_islamic_events_desc', 'المناسبات الإسلامية القادمة في الشاشة الرئيسية');
    m.set('dark_mode', 'الوضع الداكن');
    m.set('dark_mode_desc', 'اختر مظهر التطبيق');
    m.set('language', 'اللغة');
    m.set('language_desc', 'اختر لغتك المفضلة');
    m.set('lang_en', 'English (الإنجليزية)');
    m.set('lang_zh', '中文 (الصينية)');
    m.set('lang_ar', 'العربية');

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
    m.set('event_ramadan_start', 'بداية رمضان');
    m.set('event_eid_fitr', 'عيد الفطر');
    m.set('event_arafah', 'يوم عرفة');
    m.set('event_eid_adha', 'عيد الأضحى');
    m.set('wizard_step', 'خطوة');
    m.set('wizard_welcome_title', 'مرحباً بك في رفيق الصراط');
    m.set('wizard_welcome_desc', 'دعنا نُعِدّ تفضيلاتك. يمكنك تغييرها لاحقاً من الإعدادات.');
    m.set('wizard_language_title', 'اختر لغتك');
    m.set('wizard_language_desc', 'سيستخدم التطبيق هذه اللغة في جميع الشاشات');
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