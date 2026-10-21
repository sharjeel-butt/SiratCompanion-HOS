// entry/src/main/ets/pages/Prayer.ets

import { mediaquery, router } from '@kit.ArkUI';
import { Theme, ThemeColors, ThemeMode, ThemePreset } from '../common/Theme';
import { PageTheme } from '../common/PageTheme';
import { ExtraTiming, PrayerModel } from '../prayer/PrayerModel';
import { DateHelper } from '../utils/DateUtils';
import { LocationData, LocationHelper } from '../utils/LocationUtils';
import { LocationCache } from '../utils/LocationCache';
import { UpcomingImportantDate } from '../models/DateModels';
import { PrayerManager } from '../prayer/PrayerManager';
import { PrayerOffsets, SettingsHelper } from '../helper/SettingsHelper';
import { CalculationSource, LocationMode } from '../models/SettingsModels';
import { NotificationHelper } from '../helper/NotificationHelper';
import { common } from '@kit.AbilityKit';
import { PdfExportHelper } from '../utils/PdfExportHelper';
import {
  STORAGE_KEY_APP_FOREGROUND_TICK,
  STORAGE_KEY_APP_THEME,
  STORAGE_KEY_BREAKPOINT,
  STORAGE_KEY_CALC_SETTINGS_VERSION,
  STORAGE_KEY_HIJRI_CALENDAR_TYPE,
  STORAGE_KEY_HIJRI_CALENDAR_VERSION,
  STORAGE_KEY_HIJRI_OFFSET,
  STORAGE_KEY_LANGUAGE,
  STORAGE_KEY_LOCATION_VERSION,
  STORAGE_KEY_PRAYER_STATE_VERSION,
  STORAGE_KEY_SETTINGS_INITIAL_CATEGORY,
  STORAGE_KEY_SHOW_FIRST_THIRD_LIST,
  STORAGE_KEY_SHOW_FIRST_THIRD_SUNPATH,
  STORAGE_KEY_SHOW_IMSAK_LIST,
  STORAGE_KEY_SHOW_IMSAK_SUNPATH,
  STORAGE_KEY_SHOW_LAST_THIRD_LIST,
  STORAGE_KEY_SHOW_LAST_THIRD_SUNPATH,
  STORAGE_KEY_SHOW_MIDNIGHT_LIST,
  STORAGE_KEY_SHOW_MIDNIGHT_SUNPATH,
  STORAGE_KEY_THEME_MODE,
  STORAGE_KEY_TIME_FORMAT
} from '../common/StorageKeys';
import { ClockFormat, ClockFormatHelper } from '../common/ClockFormat';
import { AppLogger } from '../helper/AppLogger';
import { HomeController } from '../utils/HomeController';
import {
  AsrShadowRule,
  CalculationMethod,
  HighLatitudeRule,
  PrayerTimeCalculator
} from '../prayer/PrayerTimeCalculator';
import { NavHelper } from '../helper/NavHelper';
import { TimezoneResolver } from '../utils/TimezoneResolver';
import { L } from '../i8n/LocalizationHelper';
import { PageHeader } from '../components/PageHeader';
import { PrayerSunPath } from '../prayer/PrayerSunPath';
import { Breakpoints } from '../common/Breakpoints';
import { AdvancedCalcSettings, DEFAULT_ADVANCED_CALC } from '../models/AdvancedCalcModels';
import { EventPerspectiveNotifier } from '../utils/EventPerspectiveNotifier';
import { HijriCalendarType } from '../hijricalendar/HijriCalendarType';
import { HijriCalendarHelper } from '../hijricalendar/HijriCalendarHelper';

interface TimelineRow {
  kind: 'prayer' | 'extra';
  id: string;
  time: string;
  sortMinutes: number;
  prayerRef: PrayerModel | null;
  extraRef: ExtraTiming | null;
}

export interface PrayerTableRow {
  hijriDate: string;
  gregorianDate: string;
  fajr: string;
  dhuhr: string;
  asr: string;
  maghrib: string;
  isha: string;
}

const NIGHT_EXTRA_IDS: string[] = ['firstThird', 'midnight', 'lastThird'];

@Component
export struct Prayer {

  @StorageLink(STORAGE_KEY_THEME_MODE)
  @Watch('onThemeModeChanged')
  themeMode: string = ThemeMode.SYSTEM;

  @StorageLink(STORAGE_KEY_LOCATION_VERSION)
  @Watch('onLocationVersionChanged')
  locationVersion: number = 0;

  @StorageLink(STORAGE_KEY_APP_THEME)
  @Watch('onAppThemePresetChanged')
  appThemePreset: string = ThemePreset.SIRAT;

  @StorageLink(STORAGE_KEY_LANGUAGE)
  @Watch('onLanguageChangedInHome')
  appLanguage: string = 'en';

  @StorageLink(STORAGE_KEY_PRAYER_STATE_VERSION)
  prayerStateVersion: number = 0;

  @StorageLink(STORAGE_KEY_HIJRI_OFFSET)
  @Watch('onHijriOffsetChangedInHome')
  hijriOffset: number = 0;
  @StorageLink(STORAGE_KEY_HIJRI_CALENDAR_TYPE)
  @Watch('onHijriCalendarTypeChanged')
  hijriCalendarType: string = HijriCalendarType.UMM_AL_QURA;

  @StorageLink(STORAGE_KEY_APP_FOREGROUND_TICK)
  @Watch('onAppForegrounded')
  appForegroundTick: number = 0;

  @StorageLink(STORAGE_KEY_BREAKPOINT)
  breakpoint: string = 'sm';

  @StorageLink(STORAGE_KEY_TIME_FORMAT)
  @Watch('onClockFormatChanged')
  clockFormat: string = ClockFormat.SYSTEM;
  @StorageLink(STORAGE_KEY_CALC_SETTINGS_VERSION)
  @Watch('onCalcSettingsChanged')
  calcSettingsVersion: number = 0;
  // ---- Per-timing visibility — prayer list ----
  @StorageLink(STORAGE_KEY_SHOW_IMSAK_LIST)
  @Watch('onShowImsakListChanged')
  showImsakList: boolean = true;
  @StorageLink(STORAGE_KEY_SHOW_FIRST_THIRD_LIST)
  @Watch('onShowFirstThirdListChanged')
  showFirstThirdList: boolean = true;
  @StorageLink(STORAGE_KEY_SHOW_MIDNIGHT_LIST)
  @Watch('onShowMidnightListChanged')
  showMidnightList: boolean = true;
  @StorageLink(STORAGE_KEY_SHOW_LAST_THIRD_LIST)
  @Watch('onShowLastThirdListChanged')
  showLastThirdList: boolean = true;
  // ---- Per-timing visibility — sun path ----
  @StorageLink(STORAGE_KEY_SHOW_IMSAK_SUNPATH)
  @Watch('onShowImsakSunpathChanged')
  showImsakSunpath: boolean = true;
  @StorageLink(STORAGE_KEY_SHOW_FIRST_THIRD_SUNPATH)
  @Watch('onShowFirstThirdSunpathChanged')
  showFirstThirdSunpath: boolean = true;
  @StorageLink(STORAGE_KEY_SHOW_MIDNIGHT_SUNPATH)
  @Watch('onShowMidnightSunpathChanged')
  showMidnightSunpath: boolean = true;
  @StorageLink(STORAGE_KEY_SHOW_LAST_THIRD_SUNPATH)
  @Watch('onShowLastThirdSunpathChanged')
  showLastThirdSunpath: boolean = true;
  @StorageLink(STORAGE_KEY_HIJRI_CALENDAR_VERSION)
  @Watch('onHijriCalendarVersionChanged')
  calendarVersion: number = 0;

  @State colors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);
  private systemDarkListener: mediaquery.MediaQueryListener | null = null;

  @State currentLocation: string = 'Loading...';
  @State isLoadingLocation: boolean = true;
  @State latitude: number = 0;
  @State longitude: number = 0;

  @State hijriDateString: string = '';
  @State todayCurrentPrayerName: string = '—';
  @State todayCurrentPrayerTime: string = '--:--';
  @State todayNextPrayerName: string = '—';
  @State todayNextPrayerTime: string = '--:--';

  @State dateOffset: number = 0;
  @State viewingDate: Date = new Date();
  @State viewingDateKey: string = '';
  @State viewingHijriDate: string = '';
  @State isExporting: boolean = false;
  @State pdfPrayerDays: PrayerTableRow[] = [];
  @State pdfColors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);
  @State pdfMonthName: string = '';
  @State pdfYear: number = 2026;
  @State pdfHijriMonthName: string = '';
  @State pdfHijriYear: number = 1447;
  @State pdfHijriSpan: string = '';

  @State upcomingImportantDates: UpcomingImportantDate[] = [];

  @State prayers: PrayerModel[] = [
    { id: 'fajr',    name: 'Fajr',    arabicName: 'الفجر',   time: '--:--', status: 'abbreviation', checked: false },
    { id: 'dhuhr',   name: 'Dhuhr',   arabicName: 'الظهر',   time: '--:--', status: 'abbreviation', checked: false },
    { id: 'asr',     name: 'Asr',     arabicName: 'العصر',   time: '--:--', status: 'abbreviation', checked: false },
    { id: 'maghrib', name: 'Maghrib', arabicName: 'المغرب',  time: '--:--', status: 'abbreviation', checked: false },
    { id: 'isha',    name: 'Isha',    arabicName: 'العشاء',  time: '--:--', status: 'abbreviation', checked: false }
  ];

  @State extraTimings: ExtraTiming[] = [
    {
      id: 'imsak',
      name: 'Imsak',
      arabicName: 'الإمساك',
      time: '--:--',
      status: 'abbreviation',
      icon: 'app.media.ic_moon'
    },
    {
      id: 'sunrise',
      name: 'Sunrise',
      arabicName: 'الشروق',
      time: '--:--',
      status: 'abbreviation',
      icon: 'app.media.ic_sunrise'
    },
    {
      id: 'sunset',
      name: 'Sunset',
      arabicName: 'المغرب',
      time: '--:--',
      status: 'abbreviation',
      icon: 'app.media.ic_sunset'
    },
    {
      id: 'firstThird',
      name: 'First Third',
      arabicName: 'الثلث الأول',
      time: '--:--',
      status: 'abbreviation',
      icon: 'app.media.ic_star'
    },
    {
      id: 'midnight',
      name: 'Midnight',
      arabicName: 'منتصف الليل',
      time: '--:--',
      status: 'abbreviation',
      icon: 'app.media.ic_star'
    },
    {
      id: 'lastThird',
      name: 'Last Third',
      arabicName: 'الثلث الأخير',
      time: '--:--',
      status: 'abbreviation',
      icon: 'app.media.ic_star'
    }
  ];

  @State calcMethod: CalculationMethod = CalculationMethod.KARACHI;
  @State asrRule: AsrShadowRule = AsrShadowRule.STANDARD;
  @State calcSource: CalculationSource = CalculationSource.LOCAL;
  @State locationMode: LocationMode = LocationMode.GPS;
  @State offsets: PrayerOffsets = { fajr: 0, dhuhr: 0, asr: 0, maghrib: 0, isha: 0 };
  private advanced: AdvancedCalcSettings = DEFAULT_ADVANCED_CALC;

  @State private isRefreshingHome: boolean = false;
  @State highLatRule: HighLatitudeRule = HighLatitudeRule.NONE;

  private statusTimerId: number = -1;
  private settingsLoaded: boolean = false;
  private settingsLoading: boolean = false;
  private settingsPending: boolean = false;
  private eventPerspectiveListener: () => void = (): void => {
    this.upcomingImportantDates = DateHelper.getUpcomingImportantDates(
      this.hijriOffset,
      SettingsHelper.getEventPerspective()
    );
  };

  private tr(key: string): string {
    return L.get(key, this.appLanguage);
  }

  private onShowImsakListChanged(): void {
  }

  private onShowFirstThirdListChanged(): void {
  }

  private onShowMidnightListChanged(): void {
  }

  private onShowLastThirdListChanged(): void {
  }

  private onHijriCalendarVersionChanged(): void {
    this.refreshHijriDates();
    this.upcomingImportantDates = DateHelper.getUpcomingImportantDates(this.hijriOffset);
  }

  private onShowImsakSunpathChanged(): void {
  }

  private onShowFirstThirdSunpathChanged(): void {
  }

  private onShowMidnightSunpathChanged(): void {
  }

  private onShowLastThirdSunpathChanged(): void {
  }

  private dt(t: string): string {
    if (this.clockFormat.length === 0) {
      return t;
    }
    return ClockFormatHelper.reformat(t);
  }

  private isRtl(): boolean {
    return L.isRtlLang(this.appLanguage);
  }

  private isTablet(): boolean {
    return Breakpoints.isTablet(this.breakpoint);
  }

  private isDarkMode(): boolean {
    return PageTheme.isDarkFor(this.themeMode);
  }

  private translatePrayerName(raw: string): string {
    switch (raw) {
      case 'Fajr':    return this.tr('prayer_fajr');
      case 'Dhuhr':   return this.tr('prayer_dhuhr');
      case 'Asr':     return this.tr('prayer_asr');
      case 'Maghrib': return this.tr('prayer_maghrib');
      case 'Isha':    return this.tr('prayer_isha');
      case 'Jummah':  return this.tr('prayer_jummah');
      default:        return raw;
    }
  }

  private translateTimingName(raw: string): string {
    switch (raw) {
      case 'Imsak':       return this.tr('timing_imsak');
      case 'Sunrise':     return this.tr('timing_sunrise');
      case 'Sunset':      return this.tr('timing_sunset');
      case 'First Third': return this.tr('timing_first_third');
      case 'Midnight':    return this.tr('timing_midnight');
      case 'Last Third':  return this.tr('timing_last_third');
      default:            return raw;
    }
  }

  private translateEventName(raw: string): string {
    const asPrayer = this.translatePrayerName(raw);
    if (asPrayer !== raw) return asPrayer;
    return this.translateTimingName(raw);
  }

  private translateUpcomingEventName(e: UpcomingImportantDate): string {
    if (e.key && e.key.length > 0) {
      const translated = this.tr('event_' + e.key);
      if (translated !== 'event_' + e.key) {
        return translated;
      }
    }
    return e.name;
  }

  private onThemeModeChanged(): void {
    this.colors = PageTheme.compute(this.themeMode);
  }

  private onAppThemePresetChanged(): void {
    this.colors = PageTheme.compute(this.themeMode);
  }

  private onClockFormatChanged(): void {
    // Re-render is handled by the @StorageLink.
  }

  private async onCalcSettingsChanged(): Promise<void> {
    await this.loadSettingsAndLocation();
  }

  private async onLocationVersionChanged(): Promise<void> {
    const mode = await SettingsHelper.getLocationMode();
    const loc = await HomeController.loadLocationForMode(mode);

    this.locationMode = mode;
    this.latitude = loc.latitude;
    this.longitude = loc.longitude;
    this.currentLocation = loc.displayName;
    this.isLoadingLocation = false;

    this.refreshPrayerTimes();
    this.updateTodayHeaderData();
    this.refreshHijriDates();
  }

  private async onLanguageChangedInHome(): Promise<void> {
    // Re-render is handled by the @StorageLink.
  }

  private onHijriOffsetChangedInHome(): void {
    this.refreshHijriDates();
    this.upcomingImportantDates = DateHelper.getUpcomingImportantDates(
      this.hijriOffset,
      SettingsHelper.getEventPerspective()
    );
  }

  private onHijriCalendarTypeChanged(): void {
    this.refreshHijriDates();
    this.upcomingImportantDates = DateHelper.getUpcomingImportantDates(
      this.hijriOffset,
      SettingsHelper.getEventPerspective()
    );
  }

  private async onAppForegrounded(): Promise<void> {
    this.syncViewingDateIfStale();

    this.refreshHijriDates();
    this.upcomingImportantDates = DateHelper.getUpcomingImportantDates(
      this.hijriOffset,
      SettingsHelper.getEventPerspective()
    );

    await this.loadSettingsAndLocation();
    this.prayers = PrayerManager.updateStatuses(
      this.prayers, this.viewingDate, this.getLocationOffsetHours()
    );
    this.updateTodayHeaderData();
    this.refreshPrayerTimes();

    this.refreshLocationSilently();
  }

  aboutToAppear(): void {
    this.colors = PageTheme.compute(this.themeMode);
    this.systemDarkListener = PageTheme.installSystemListener(this.themeMode, (c) => {
      this.colors = c;
    });

    EventPerspectiveNotifier.subscribe(this.eventPerspectiveListener);

    this.refreshHijriDates();
    this.upcomingImportantDates = DateHelper.getUpcomingImportantDates(
      this.hijriOffset,
      SettingsHelper.getEventPerspective()
    );

    this.refreshViewingDate(true);
    this.initialize();
    this.startStatusTimer();

    this.refreshLocationSilently();
  }

  aboutToDisappear(): void {
    PageTheme.uninstallSystemListener(this.systemDarkListener);
    this.systemDarkListener = null;
    EventPerspectiveNotifier.unsubscribe(this.eventPerspectiveListener);
    if (this.statusTimerId !== -1) {
      clearInterval(this.statusTimerId);
      this.statusTimerId = -1;
    }
  }

  onPageShow(): void {
    this.colors = PageTheme.compute(this.themeMode);
    this.syncViewingDateIfStale();

    this.prayers = PrayerManager.loadStateForDate(
      this.viewingDateKey, this.prayers, this.viewingDate
    );
    this.prayers = PrayerManager.updateStatuses(
      this.prayers, this.viewingDate, this.getLocationOffsetHours()
    );

    this.loadSettingsAndLocation();
    this.updateTodayHeaderData();
    this.refreshHijriDates();
  }

  private syncViewingDateIfStale(): void {
    if (this.dateOffset !== 0) {
      return;
    }
    const viewDay = new Date(this.viewingDate);
    viewDay.setHours(0, 0, 0, 0);
    const todayMidnight = new Date();
    todayMidnight.setHours(0, 0, 0, 0);
    if (viewDay.getTime() !== todayMidnight.getTime()) {
      this.refreshViewingDate(true);
    }
  }

  private async initialize(): Promise<void> {
    await this.loadSettingsAndLocation();
  }

  private startStatusTimer(): void {
    if (this.statusTimerId !== -1) {
      clearInterval(this.statusTimerId);
      this.statusTimerId = -1;
    }
    this.statusTimerId = setInterval(() => {
      if (this.dateOffset === 0) {
        this.prayers = PrayerManager.updateStatuses(
          this.prayers, this.viewingDate, this.getLocationOffsetHours()
        );
      }
      this.updateTodayHeaderData();
    }, 60000);
  }

  private refreshHijriDates(): void {
    const today = new Date();
    const shiftedToday = new Date(today);
    shiftedToday.setDate(shiftedToday.getDate() + this.hijriOffset);
    this.hijriDateString = DateHelper.getFormattedHijriDateFor(shiftedToday);

    const viewed = new Date(this.viewingDate);
    const shiftedViewed = new Date(viewed);
    shiftedViewed.setDate(shiftedViewed.getDate() + this.hijriOffset);
    this.viewingHijriDate = DateHelper.getFormattedHijriDateFor(shiftedViewed);
  }

  private getLocationOffsetHours(): number {
    if (this.latitude === 0 && this.longitude === 0) return 0;
    return TimezoneResolver.effectiveOffsetForLocation(
      this.latitude, this.longitude, new Date()
    );
  }

  private refreshViewingDate(skipReload: boolean = false): void {
    const d = new Date();
    d.setDate(d.getDate() + this.dateOffset);
    this.viewingDate = d;
    this.viewingDateKey = PrayerManager.getDateKeyForDate(d);

    const shifted = new Date(d);
    shifted.setDate(shifted.getDate() + this.hijriOffset);
    this.viewingHijriDate = DateHelper.getFormattedHijriDateFor(shifted);

    if (!skipReload) {
      this.prayers = PrayerManager.loadStateForDate(
        this.viewingDateKey, this.prayers, this.viewingDate
      );
      this.prayers = PrayerManager.updateStatuses(
        this.prayers, this.viewingDate, this.getLocationOffsetHours()
      );
      this.refreshPrayerTimes();
    }
  }

  private goToNextDay(): void {
    this.dateOffset += 1;
    this.refreshViewingDate();
  }

  private goToPreviousDay(): void {
    this.dateOffset -= 1;
    this.refreshViewingDate();
  }

  private goToToday(): void {
    if (this.dateOffset === 0) {
      return;
    }
    this.dateOffset = 0;
    this.refreshViewingDate();
  }

  private async loadSettingsAndLocation(): Promise<void> {
    if (this.settingsLoading) {
      this.settingsPending = true;
      return;
    }
    this.settingsLoading = true;

    try {
      const data = await SettingsHelper.loadAll();
      const mode = await SettingsHelper.getLocationMode();

      this.calcMethod = data.method;
      this.asrRule    = data.asr;
      this.calcSource = data.source;
      this.locationMode = mode;
      this.offsets = await SettingsHelper.getPrayerOffsets();
      this.highLatRule = await SettingsHelper.getHighLatRule();
      this.advanced = await SettingsHelper.getAdvancedCalcSettings();

      const loc = await HomeController.loadLocationForMode(mode);
      this.latitude = loc.latitude;
      this.longitude = loc.longitude;
      this.currentLocation = loc.displayName;
      this.isLoadingLocation = false;

      this.prayers = PrayerManager.loadStateForDate(
        this.viewingDateKey, this.prayers, this.viewingDate
      );

      this.refreshPrayerTimes();
      this.updateTodayHeaderData();
      this.settingsLoaded = true;
    } finally {
      this.settingsLoading = false;
      if (this.settingsPending) {
        this.settingsPending = false;
        this.loadSettingsAndLocation();
      }
    }
  }

  private refreshPrayerTimes(): void {
    if (this.calcSource !== CalculationSource.LOCAL) return;

    const snap = HomeController.buildPrayersForDate(
      this.viewingDate, this.latitude, this.longitude,
      this.calcMethod, this.asrRule, this.highLatRule,
      this.offsets, this.prayers, this.advanced
    );
    if (snap) this.prayers = snap.prayers;

    this.extraTimings = HomeController.buildExtraTimings(
      this.viewingDate, this.latitude, this.longitude,
      this.calcMethod, this.asrRule, this.highLatRule,
      this.offsets, this.extraTimings, this.advanced
    );
  }

  private updateTodayHeaderData(): void {
    if (this.calcSource !== CalculationSource.LOCAL) return;
    const hdr = HomeController.buildTodayHeader(
      this.latitude, this.longitude, this.calcMethod, this.asrRule,
      this.highLatRule, this.offsets, this.prayers, this.advanced
    );
    if (!hdr) return;
    this.todayCurrentPrayerName = hdr.currentName;
    this.todayCurrentPrayerTime = hdr.currentTime;
    this.todayNextPrayerName = hdr.nextName;
    this.todayNextPrayerTime = hdr.nextTime;
  }

  private buildCombinedTimeline(): TimelineRow[] {
    const rows: TimelineRow[] = [];

    for (const p of this.prayers) {
      const row: TimelineRow = {
        kind: 'prayer',
        id: p.id,
        time: p.time,
        sortMinutes: 0,
        prayerRef: p,
        extraRef: null
      };
      rows.push(row);
    }

    // Sunrise and Sunset are core astronomical markers — always
    // shown. The other four extras are gated individually by their
    // list toggle.
    const GATED_EXTRAS: string[] = ['imsak', 'firstThird', 'midnight', 'lastThird'];

    for (const t of this.extraTimings) {
      if (GATED_EXTRAS.indexOf(t.id) !== -1) {
        if (t.id === 'imsak' && !this.showImsakList) {
          continue;
        }
        if (t.id === 'firstThird' && !this.showFirstThirdList) {
          continue;
        }
        if (t.id === 'midnight' && !this.showMidnightList) {
          continue;
        }
        if (t.id === 'lastThird' && !this.showLastThirdList) {
          continue;
        }
      }
      const row: TimelineRow = {
        kind: 'extra',
        id: t.id,
        time: t.time,
        sortMinutes: 0,
        prayerRef: null,
        extraRef: t
      };
      rows.push(row);
    }

    for (const r of rows) {
      const raw = r.time.trim();
      if (raw === '' || raw === '--:--') {
        r.sortMinutes = 99999;
        continue;
      }
      const m = PrayerManager.timeToMinutes(raw);
      if (r.kind === 'extra'
        && NIGHT_EXTRA_IDS.indexOf(r.id) !== -1
        && m < 720) {
        r.sortMinutes = m + 1440;
      } else {
        r.sortMinutes = m;
      }
    }

    rows.sort((a: TimelineRow, b: TimelineRow): number => {
      if (a.sortMinutes !== b.sortMinutes) {
        return a.sortMinutes - b.sortMinutes;
      }
      const aT: number = a.kind === 'extra' ? 0 : 1;
      const bT: number = b.kind === 'extra' ? 0 : 1;
      return aT - bT;
    });
    return rows;
  }

  private async refreshLocationSilently(): Promise<void> {
    if (this.locationMode !== LocationMode.GPS) {
      return;
    }

    try {
      const data: LocationData = await LocationHelper.fetchLocationData(
        getContext(this), 'silent'
      );

      const sameLat = Math.abs(data.latitude - this.latitude) < 0.0001;
      const sameLng = Math.abs(data.longitude - this.longitude) < 0.0001;
      if (sameLat && sameLng) {
        return;
      }

      AppLogger.info('Prayer',
        `Silent location refresh: ${data.latitude.toFixed(4)}, ` +
          `${data.longitude.toFixed(4)} (${data.cityName})`);

      this.latitude = data.latitude;
      this.longitude = data.longitude;
      this.currentLocation = data.cityName;

      await LocationCache.save(data.latitude, data.longitude, data.cityName);

      this.prayers = PrayerManager.loadStateForDate(
        this.viewingDateKey, this.prayers, this.viewingDate
      );
      this.refreshPrayerTimes();
      this.prayers = PrayerManager.updateStatuses(
        this.prayers, this.viewingDate, this.getLocationOffsetHours()
      );
      this.updateTodayHeaderData();
    } catch (err) {
      const e = err as Error;
      console.info(
        `[Prayer] silent location refresh skipped: ${e.message}`
      );
    }
  }

  private async refreshLocation(): Promise<void> {
    if (this.isLoadingLocation) return;
    this.isLoadingLocation = true;

    if (this.locationMode === LocationMode.MANUAL) {
      try {
        const manual = await SettingsHelper.getManualCoords();
        if (manual.lat === 0 && manual.lng === 0) {
          this.isLoadingLocation = false;
          return;
        }
        let cityName = this.tr('manual_location');
        try {
          cityName = await LocationHelper.reverseGeocode(manual.lat, manual.lng);
        } catch (e) { /* fall through */
        }
        await SettingsHelper.saveManualCoords(manual.lat, manual.lng, cityName);
        this.latitude = manual.lat;
        this.longitude = manual.lng;
        this.currentLocation = `${cityName} (${this.tr('manual_location')})`;
        this.refreshPrayerTimes();
        this.updateTodayHeaderData();
      } catch (err) {
        console.error('Manual refresh failed:', JSON.stringify(err));
      } finally {
        this.isLoadingLocation = false;
      }
      return;
    }

    try {
      const data: LocationData =
        await LocationHelper.fetchLocationData(getContext(this));
      this.latitude = data.latitude;
      this.longitude = data.longitude;
      this.currentLocation = data.cityName;
      await LocationCache.save(data.latitude, data.longitude, data.cityName);
      this.refreshPrayerTimes();
      this.updateTodayHeaderData();
    } catch (err) {
      const error = err as Error;
      if (error.message === 'GPS_OFF') {
        await LocationHelper.showLocationDisabledDialog();
      } else if (error.message === 'PERMISSION_DENIED') {
        await LocationHelper.showPermissionDeniedDialog();
      }
    } finally {
      this.isLoadingLocation = false;
    }
  }

  private async handleHomeRefresh(): Promise<void> {
    try {
      await this.loadSettingsAndLocation();
      if (this.locationMode === LocationMode.GPS) {
        await this.refreshLocation();
      }
      this.prayers = PrayerManager.updateStatuses(
        this.prayers, this.viewingDate, this.getLocationOffsetHours()
      );
      this.refreshPrayerTimes();
      this.updateTodayHeaderData();
      this.refreshHijriDates();
    } finally {
      this.isRefreshingHome = false;
    }
  }

  private setPrayerChecked(id: string, checked: boolean): void {
    const target = this.prayers.find(p => p.id === id);
    if (!target) {
      return;
    }
    if (target.checked === checked) {
      return;
    }
    if (checked && !PrayerManager.isPrayerCheckable(target, this.viewingDate)) {
      return;
    }

    this.prayers = this.prayers.map((p): PrayerModel => {
      if (p.id === id) {
        const updated: PrayerModel = {
          id: p.id,
          name: p.name,
          arabicName: p.arabicName,
          time: p.time,
          status: p.status,
          checked: checked
        };
        return updated;
      }
      return p;
    });

    PrayerManager.saveStateForDate(this.viewingDateKey, this.prayers);

    if (checked
      && this.dateOffset === 0
      && this.allPrayersForViewingDateAreChecked()) {
      AppLogger.info('Prayer',
        'Last prayer of the day marked — immediate reschedule');
      NotificationHelper.scheduleRescheduleNow();
    } else {
      NotificationHelper.scheduleReschedule();
    }

    this.prayers = PrayerManager.updateStatuses(
      this.prayers, this.viewingDate, this.getLocationOffsetHours()
    );
    if (this.dateOffset === 0) {
      this.updateTodayHeaderData();
    }
  }

  private async handleExportPdf(): Promise<void> {
    if (this.isExporting) {
      return;
    }
    this.isExporting = true;
    this.pdfPrayerDays = [];
    this.pdfColors = PageTheme.compute(ThemeMode.LIGHT);

    try {
      // 1. Determine the target Hijri Month based on the currently viewing date
      const anchor = this.viewingDate;
      const hDate = HijriCalendarHelper.getHijriDate(anchor, this.hijriOffset);
      const targetHYear = hDate.year;
      const targetHMonth = hDate.month;

      const hijriMonths = L.getArray('hijri_months', this.appLanguage);
      this.pdfHijriMonthName = hijriMonths[targetHMonth - 1] || '';
      this.pdfHijriYear = targetHYear;

      // 2. Build the exact days for this Hijri month (returns 29 or 30 days)
      const days = HijriCalendarHelper.buildMonthDays(
        targetHYear, targetHMonth, this.hijriOffset, anchor
      );

      if (days.length === 0) {
        console.error('Could not build days for Hijri month');
        return;
      }

      // 3. Calculate Gregorian Span for the subtitle (e.g., "Nov 15 – Dec 14, 2026")
      const startG = days[0].gregorianDate;
      const endG = days[days.length - 1].gregorianDate;
      const locale = this.appLanguage === 'zh' ? 'zh-CN' : (this.appLanguage === 'ar' ? 'ar' : 'en-US');

      const startGStr = startG.toLocaleString(locale, { month: 'short', day: 'numeric' });
      const endGStr = endG.toLocaleString(locale, { month: 'short', day: 'numeric', year: 'numeric' });
      this.pdfMonthName = `${startGStr} – ${endGStr}`;

      // 4. Calculate Hijri Span for the header
      const startHStr = DateHelper.getFormattedHijriDateFor(startG);
      const endHStr = DateHelper.getFormattedHijriDateFor(endG);
      this.pdfHijriSpan = `${startHStr} – ${endHStr}`;

      // 5. Generate the table rows
      const rows: PrayerTableRow[] = [];

      for (let i = 0; i < days.length; i++) {
        const dayObj = days[i];
        const date = dayObj.gregorianDate;

        const times = PrayerTimeCalculator.calculateWithDeviceTimezone(
          date, this.latitude, this.longitude, this.calcMethod,
          this.asrRule, this.highLatRule, this.advanced
        );

        // Hijri Date is Primary (e.g., "1 Jumada II")
        const shortHijri = `${dayObj.hijri.day} ${this.pdfHijriMonthName}`;

        // Gregorian Date is Secondary (e.g., "15/11")
        const shortGregorian = `${date.getDate()}/${date.getMonth() + 1}`;

        rows.push({
          hijriDate: shortHijri,
          gregorianDate: shortGregorian,
          fajr: PrayerManager.offsetTime(times.fajr, this.offsets.fajr),
          dhuhr: PrayerManager.offsetTime(times.dhuhr, this.offsets.dhuhr),
          asr: PrayerManager.offsetTime(times.asr, this.offsets.asr),
          maghrib: PrayerManager.offsetTime(times.maghrib, this.offsets.maghrib),
          isha: PrayerManager.offsetTime(times.isha, this.offsets.isha)
        });
      }

      this.pdfPrayerDays = rows;
      const ctx = getContext(this) as common.UIAbilityContext;

      await new Promise<void>((resolve) => setTimeout(() => resolve(), 100));

      await PdfExportHelper.exportBuilderToPdf(
        ctx, this.getUIContext(), this.PrayerExportLayout.bind(this), 'Prayer_Timetable'
      );
    } catch (err) {
      console.error('PDF generation failed:', JSON.stringify(err));
    } finally {
      this.isExporting = false;
    }
  }

  private hasUncheckedCheckablePrayers(): boolean {
    for (const p of this.prayers) {
      if (!p.checked
        && PrayerManager.isPrayerCheckable(p, this.viewingDate)) {
        return true;
      }
    }
    return false;
  }

  private allPrayersForViewingDateAreChecked(): boolean {
    if (this.prayers.length === 0) {
      return false;
    }
    for (const p of this.prayers) {
      if (!p.checked) {
        return false;
      }
    }
    return true;
  }

  private markAllPrayed(): void {
    let changed = false;
    this.prayers = this.prayers.map((p): PrayerModel => {
      if (p.checked) {
        return p;
      }
      if (!PrayerManager.isPrayerCheckable(p, this.viewingDate)) {
        return p;
      }
      changed = true;
      const updated: PrayerModel = {
        id: p.id,
        name: p.name,
        arabicName: p.arabicName,
        time: p.time,
        status: p.status,
        checked: true
      };
      return updated;
    });

    if (!changed) {
      return;
    }
    PrayerManager.saveStateForDate(this.viewingDateKey, this.prayers);

    if (this.dateOffset === 0 && this.allPrayersForViewingDateAreChecked()) {
      AppLogger.info('Prayer',
        'Mark all — day complete, immediate reschedule');
      NotificationHelper.scheduleRescheduleNow();
    } else {
      NotificationHelper.scheduleReschedule();
    }

    this.prayers = PrayerManager.updateStatuses(
      this.prayers, this.viewingDate, this.getLocationOffsetHours()
    );
    if (this.dateOffset === 0) {
      this.updateTodayHeaderData();
    }
  }

  private navigateToSettings(): void {
    AppStorage.setOrCreate(
      STORAGE_KEY_SETTINGS_INITIAL_CATEGORY, 'Prayer Times'
    );
    NavHelper.prepareForward();
    router.pushUrl({ url: 'pages/SettingsPage' })
      .catch((err: Error) =>
      console.error('Navigation failed:', JSON.stringify(err)));
  }

  private navigateToLocationSettings(): void {
    AppStorage.setOrCreate(
      STORAGE_KEY_SETTINGS_INITIAL_CATEGORY, 'Location'
    );
    NavHelper.prepareForward();
    router.pushUrl({ url: 'pages/SettingsPage' })
      .catch((err: Error) =>
      console.error('Navigation failed:', JSON.stringify(err)));
  }

  private getStatusColor(status: string): string {
    switch (status) {
      case 'next':    return this.colors.accentGold;
      case 'pray':    return this.colors.statusPray;
      case 'both':    return this.colors.statusPray;
      case 'prayed':  return this.colors.accentGoldLight;
      case 'express': return this.colors.statusExpress;
      default:        return this.colors.textMuted;
    }
  }

  private getStatusLabel(status: string): string {
    switch (status) {
      case 'next':    return this.tr('status_next');
      case 'pray':    return this.tr('status_pray');
      case 'both':    return this.tr('status_both');
      case 'prayed':  return this.tr('status_prayed');
      case 'express': return this.tr('status_express');
      default:        return '';
    }
  }

  private getExtraTimeById(id: string): string {
    for (const t of this.extraTimings) {
      if (t.id === id) {
        return t.time;
      }
    }
    return '--:--';
  }

  private getSunriseTime(): string {
    return this.getExtraTimeById('sunrise');
  }

  private getSunsetTime(): string {
    return this.getExtraTimeById('sunset');
  }

  private getImsakTime(): string {
    return this.getExtraTimeById('imsak');
  }

  private getFirstThirdTime(): string {
    return this.getExtraTimeById('firstThird');
  }

  private getMidnightTime(): string {
    return this.getExtraTimeById('midnight');
  }

  private getLastThirdTime(): string {
    return this.getExtraTimeById('lastThird');
  }

  build() {
    Stack() {
      Column() {
        PageHeader({
          colors: this.colors,
          currentLanguage: this.appLanguage,
          hijriDateString: this.hijriDateString,
          currentLocation: this.currentLocation,
          isLoadingLocation: this.isLoadingLocation,
          todayCurrentPrayerName: this.todayCurrentPrayerName,
          todayCurrentPrayerTime: this.todayCurrentPrayerTime,
          calcMethod: this.calcMethod,
          asrRule: this.asrRule,
          calcSource: this.calcSource,
          showCalcPills: true,
          onOpenLocationSettings: () => {
            this.navigateToLocationSettings();
          },
          onOpenSettings: () => {
            this.navigateToSettings();
          }
        })

        Refresh({ refreshing: $$this.isRefreshingHome }) {
          Scroll() {
            Column() {
              if (this.isTablet()) {
                Row({ space: 16 }) {
                  Column() {
                    this.NextPrayerSection()
                    if (this.calcSource === CalculationSource.LOCAL) {
                      this.TimelineSection()
                    } else {
                      this.ComingSoonCard()
                    }
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)

                  Column() {
                    PrayerSunPath({
                      colors: this.colors,
                      prayers: this.prayers,
                      sunriseTime: this.getSunriseTime(),
                      sunsetTime: this.getSunsetTime(),
                      imsakTime: this.getImsakTime(),
                      firstThirdTime: this.getFirstThirdTime(),
                      midnightTime: this.getMidnightTime(),
                      lastThirdTime: this.getLastThirdTime(),
                      currentLanguage: this.appLanguage,
                      isDarkMode: this.isDarkMode(),
                      showImsakGuide: this.showImsakSunpath,
                      showFirstThirdGuide: this.showFirstThirdSunpath,
                      showMidnightGuide: this.showMidnightSunpath,
                      showLastThirdGuide: this.showLastThirdSunpath
                    })
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                }
                .width('100%')
                .alignItems(VerticalAlign.Top)
                .padding({ left: 24, right: 24 })
              } else {
                Column() {
                  this.NextPrayerSection()

                  Column() {
                    PrayerSunPath({
                      colors: this.colors,
                      prayers: this.prayers,
                      sunriseTime: this.getSunriseTime(),
                      sunsetTime: this.getSunsetTime(),
                      imsakTime: this.getImsakTime(),
                      firstThirdTime: this.getFirstThirdTime(),
                      midnightTime: this.getMidnightTime(),
                      lastThirdTime: this.getLastThirdTime(),
                      currentLanguage: this.appLanguage,
                      isDarkMode: this.isDarkMode(),
                      showImsakGuide: this.showImsakSunpath,
                      showFirstThirdGuide: this.showFirstThirdSunpath,
                      showMidnightGuide: this.showMidnightSunpath,
                      showLastThirdGuide: this.showLastThirdSunpath
                    })
                  }
                  .width('100%')
                  .padding({ left: 16, right: 16 })

                  if (this.calcSource === CalculationSource.LOCAL) {
                    this.TimelineSection()
                  } else {
                    this.ComingSoonCard()
                  }
                }
                .width('100%')
              }

              Column().height(140)
            }
            .width('100%')
          }
          .width('100%')
          .backgroundColor(this.colors.primaryGreen)
          .scrollable(ScrollDirection.Vertical)
          .scrollBar(BarState.Auto)
          .edgeEffect(EdgeEffect.Spring)
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor(this.colors.primaryGreen)
        .onRefreshing(() => { this.handleHomeRefresh(); })
      }
      .width('100%').height('100%').backgroundColor(this.colors.primaryGreen)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.primaryGreen)
    .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
  }

  @Builder
  PrayerExportLayout() {
    Column() {
      // Header
      Row() {
        Image($r('app.media.foreground'))
          .syncLoad(true)
          .width(36)
          .height(36)
          .borderRadius(8)
          .margin({ right: 12 })

        Column() {
          // Localized Hijri Year Suffix
          Text(`${this.pdfHijriMonthName} ${this.pdfHijriYear} ${this.tr('hijri_year_suffix')}`)
            .fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.pdfColors.textWhite)

          Text(`${this.pdfMonthName} · ${this.currentLocation}`)
            .fontSize(10).fontColor(this.pdfColors.accentGold).margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        // Localized Footer
        Text(this.tr('generated_by'))
          .fontSize(8).fontColor(this.pdfColors.textMuted).alignSelf(ItemAlign.Start)
      }
      .width('100%')
      .padding({
        top: 15,
        bottom: 10,
        left: 20,
        right: 20
      })
      .backgroundColor(this.pdfColors.cardDark)

      Row().width('100%').height(3).backgroundColor(this.pdfColors.accentGold)

      // Table Headers
      Row() {
        // Localized "Date"
        Text(this.tr('export_date'))
          .layoutWeight(1.8)
          .fontWeight(FontWeight.Bold)
          .fontSize(9)
          .fontColor(this.pdfColors.accentGold)
        Text(this.tr('prayer_fajr'))
          .layoutWeight(1)
          .fontWeight(FontWeight.Bold)
          .fontSize(9)
          .fontColor(this.pdfColors.accentGold)
        Text(this.tr('prayer_dhuhr'))
          .layoutWeight(1)
          .fontWeight(FontWeight.Bold)
          .fontSize(9)
          .fontColor(this.pdfColors.accentGold)
        Text(this.tr('prayer_asr'))
          .layoutWeight(1)
          .fontWeight(FontWeight.Bold)
          .fontSize(9)
          .fontColor(this.pdfColors.accentGold)
        Text(this.tr('prayer_maghrib'))
          .layoutWeight(1)
          .fontWeight(FontWeight.Bold)
          .fontSize(9)
          .fontColor(this.pdfColors.accentGold)
        Text(this.tr('prayer_isha'))
          .layoutWeight(1)
          .fontWeight(FontWeight.Bold)
          .fontSize(9)
          .fontColor(this.pdfColors.accentGold)
      }
      .width('100%')
      .padding({
        top: 6,
        bottom: 6,
        left: 20,
        right: 20
      })
      .backgroundColor(this.pdfColors.tintSoft)

      // Table Rows
      Column() {
        ForEach(this.pdfPrayerDays, (row: PrayerTableRow, index: number) => {
          Row() {
            Column() {
              Text(row.hijriDate)
                .fontSize(9)
                .lineHeight(11)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.pdfColors.textWhite)
              Text(row.gregorianDate).fontSize(7).lineHeight(9).fontColor(this.pdfColors.textMuted).margin({ top: 0 })
            }.layoutWeight(1.8).alignItems(HorizontalAlign.Start)

            Text(row.fajr).layoutWeight(1).fontSize(8).fontColor(this.pdfColors.textWhite)
            Text(row.dhuhr).layoutWeight(1).fontSize(8).fontColor(this.pdfColors.textWhite)
            Text(row.asr).layoutWeight(1).fontSize(8).fontColor(this.pdfColors.textWhite)
            Text(row.maghrib).layoutWeight(1).fontSize(8).fontColor(this.pdfColors.textWhite)
            Text(row.isha).layoutWeight(1).fontSize(8).fontColor(this.pdfColors.textWhite)
          }
          .width('100%')
          .padding({
            top: 2,
            bottom: 2,
            left: 20,
            right: 20
          })
          .backgroundColor(index % 2 === 0 ? 'transparent' : this.pdfColors.tintSubtle)
          .alignItems(VerticalAlign.Center)
        })
      }
      .width('100%')

      // Footer
      Row() {
        Text(this.tr('generated_by')).fontSize(8).lineHeight(12).fontColor(this.pdfColors.textMuted)
      }
      .width('100%').padding({ top: 4, bottom: 4 }).justifyContent(FlexAlign.Center)
    }
    .width(595).height(842).backgroundColor(this.pdfColors.primaryGreen)
  }

  @Builder
  NextPrayerSection() {
    Column() {
      Row() {
        Text(this.tr('next_prayer'))
          .fontSize(12).fontColor(this.colors.textMuted)
          .letterSpacing(1).fontWeight(FontWeight.Medium)
        Blank()
        Row() {
          Text(this.translateEventName(this.todayNextPrayerName))
            .fontSize(16).fontColor(this.colors.accentGold)
            .fontWeight(FontWeight.Bold)
          Text('   ')
          Text(this.dt(this.todayNextPrayerTime))
            .fontSize(16).fontColor(this.colors.textWhite)
            .fontWeight(FontWeight.Medium)
        }
      }
      .width('100%')
      .padding({
        top: 12,
        bottom: 12,
        left: 16,
        right: 16
      })
      .backgroundColor(this.colors.cardDark).borderRadius(Theme.radiusMedium)
      .border({ width: 1, color: this.colors.borderSoft })
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .margin({ top: 4, bottom: 12 })
  }

  @Builder
  TimelineSection() {
    Column() {
      Row() {
        Text(this.tr('todays_prayers'))
          .fontSize(14)
          .fontColor(this.colors.textWhite)
          .fontWeight(FontWeight.Bold)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`${this.prayers.filter(p => p.checked).length} / ${this.prayers.length}`)
          .fontSize(14)
          .fontColor(this.colors.textWhite)
          .fontWeight(FontWeight.Bold)
          .direction(Direction.Ltr)
          .margin({ left: 8 })

        Blank()

        // --- Export PDF Button ---
        if (this.isExporting) {
          LoadingProgress()
            .width(24).height(24)
            .color(this.colors.accentGold)
            .margin({ right: 8 })
        } else {
          Image($r('app.media.ic_print'))
            .width(16)
            .height(16)
            .fillColor(this.colors.accentGold)
            .width(32)
            .height(32)
            .padding(8)
            .borderRadius(16)
            .backgroundColor(this.colors.cardDark)
            .border({ width: 1, color: this.colors.borderSoft })
            .margin({ right: 8 })
            .onClick(() => {
              this.handleExportPdf();
            })
        }

        Row() {
          Image($r('app.media.ic_check'))
            .width(12).height(12)
            .fillColor(this.colors.accentGold)
            .margin({ right: 4 })
          Text(this.tr('mark_all'))
            .fontSize(11).fontColor(this.colors.accentGold)
            .fontWeight(FontWeight.Medium).maxLines(1)
        }
        .padding({
          left: 10,
          right: 10,
          top: 5,
          bottom: 5
        })
        .backgroundColor(this.colors.cardDark)
        .borderRadius(12)
        .border({ width: 1, color: this.colors.borderSoft })
        .opacity(this.hasUncheckedCheckablePrayers() ? 1.0 : 0.4)
        .onClick(() => {
          this.markAllPrayed();
        })
      }
      .width('100%').padding({ bottom: 8 })
      .alignItems(VerticalAlign.Center)

      Row() {
        Image($r('app.media.ic_chevron_right'))
          .width(14)
          .height(14)
          .fillColor(this.colors.accentGold)
          .rotate({ angle: 180 }) // Points left
          .width(36)
          .height(36)
          .padding(11)
          .borderRadius(18)
          .backgroundColor(this.colors.cardDark)
          .border({ width: 1, color: this.colors.borderSoft })
          .onClick(() => { this.goToPreviousDay(); })

        Text(this.viewingHijriDate)
          .fontSize(13)
          .fontColor(this.colors.accentGold)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1).textAlign(TextAlign.Center).maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Image($r('app.media.ic_chevron_right'))
          .width(14)
          .height(14)
          .fillColor(this.colors.accentGold)
          .width(36)
          .height(36)
          .padding(11)
          .borderRadius(18)
          .backgroundColor(this.colors.cardDark)
          .border({ width: 1, color: this.colors.borderSoft })
          .onClick(() => { this.goToNextDay(); })

        if (this.dateOffset !== 0) {
          Text(this.tr('today'))
            .fontSize(11)
            .fontColor(this.colors.accentGold)
            .fontWeight(FontWeight.Medium)
            .padding({
              left: 12,
              right: 12,
              top: 9,
              bottom: 9
            })
            .backgroundColor(this.colors.cardDark)
            .borderRadius(18)
            .border({ width: 1, color: this.colors.borderSoft })
            .margin({ left: 8 })
            .onClick(() => {
              this.goToToday();
            })
        }
      }
      .width('100%').padding({ bottom: 12 })
      .alignItems(VerticalAlign.Center)
      .direction(Direction.Ltr)

      Column() {
        ForEach(this.buildCombinedTimeline(), (row: TimelineRow) => {
          if (row.prayerRef !== null) {
            this.PrayerItem(row.prayerRef)
          } else if (row.extraRef !== null) {
            this.ExtraTimingRow(row.extraRef)
          }
        }, (row: TimelineRow) => {
          const checkedPart = row.prayerRef !== null
            ? (row.prayerRef.checked ? 'c' : 'u') : 'x';
          return `${this.viewingDateKey}-${row.kind}-${row.id}-${row.time}-${row.sortMinutes}-${checkedPart}-${this.clockFormat}`;
        })
      }
      .width('100%')
      .backgroundColor(this.colors.cardDark)
      .borderRadius(Theme.radiusMedium)
      .border({ width: 1, color: this.colors.borderSoft })
      .padding({ left: 4, right: 4, top: 4, bottom: 4 })
    }
    .width('100%').padding({ left: 16, right: 16 })
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 12 })
  }

  @Builder
  PrayerItem(prayer: PrayerModel) {
    Row() {
      Stack() {
        if (prayer.checked) {
          Image($r('app.media.ic_check'))
            .width(14)
            .height(14)
            .fillColor(this.colors.textOnAccent)
            .width('100%')
            .height('100%')
            .padding(4)
        }
      }
      .width(22)
      .height(22)
      .borderRadius(5)
      .backgroundColor(prayer.checked
        ? this.colors.accentGold : 'transparent')
      .border({
        width: 1.5,
        color: prayer.checked
          ? this.colors.accentGold : this.colors.borderStrong
      })
      .opacity(PrayerManager.isPrayerCheckable(prayer, this.viewingDate)
        ? 1.0 : 0.4)
      .margin({ right: 12 })
      .onClick(() => {
        if (PrayerManager.isPrayerCheckable(prayer, this.viewingDate)) {
          this.setPrayerChecked(prayer.id, !prayer.checked);
        }
      })

      Column() {
        Row() {
          Text(this.translatePrayerName(prayer.name))
            .fontSize(16).fontColor(this.colors.textWhite)
            .fontWeight(prayer.checked
              ? FontWeight.Normal : FontWeight.Medium)
            .opacity(prayer.checked ? 0.5 : 1.0)
          Text('  ')
          Text(prayer.arabicName)
            .fontSize(14).fontColor(this.colors.textMuted)
        }
        Text(this.getStatusLabel(prayer.status))
          .fontSize(11).fontColor(this.getStatusColor(prayer.status))
          .letterSpacing(1).margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)

      Text(this.dt(prayer.time)).fontSize(16)
        .fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .padding({
      top: 10,
      bottom: 10,
      left: 12,
      right: 12
    })
    .alignItems(VerticalAlign.Center)
    .borderRadius(Theme.radiusSmall)
    .backgroundColor(prayer.checked
      ? this.colors.tintSoft : 'transparent')
    .margin({ bottom: 4 })
  }

  @Builder
  ExtraTimingRow(timing: ExtraTiming) {
    Row() {
      if (timing.icon && timing.icon.length > 0) {
        Image($r(timing.icon))
          .width(16).height(16)
          .fillColor(this.colors.textMuted)
          .margin({ right: 8 })
      } else {
        Text('•')
          .fontSize(15)
          .fontColor(this.colors.textMuted)
          .width(20)
          .height(20)
          .textAlign(TextAlign.Center)
      }

      Column() {
        Row() {
          Text(this.translateTimingName(timing.name))
            .fontSize(14).fontColor(this.colors.textMuted)
            .fontStyle(FontStyle.Italic)
          Text('  ')
          Text(timing.arabicName)
            .fontSize(12).fontColor(this.colors.textMuted).opacity(0.65)
        }
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)

      Text(this.dt(timing.time)).fontSize(14)
        .fontColor(this.colors.textMuted).fontStyle(FontStyle.Italic)
    }
    .width('100%')
    .padding({
      top: 8,
      bottom: 8,
      left: 12,
      right: 12
    })
    .alignItems(VerticalAlign.Center)
    .borderRadius(Theme.radiusSmall)
    .backgroundColor(this.colors.tintSubtle)
    .margin({ bottom: 4 })
  }

  @Builder
  ComingSoonCard() {
    Column() {
      Image($r('app.media.ic_globe'))
        .width(56).height(56)
        .fillColor(this.colors.accentGold)
        .margin({ bottom: 12 })
      Text(this.tr('online_prayer_times'))
        .fontSize(18).fontWeight(FontWeight.Bold)
        .fontColor(this.colors.textWhite)
      Text(this.tr('coming_soon'))
        .fontSize(13).fontColor(this.colors.accentGold)
        .letterSpacing(1).margin({ top: 4 })
      Divider().width('60%').color(this.colors.borderSoft)
        .margin({ top: 16, bottom: 16 })
      Text(this.tr('online_switch_hint'))
        .fontSize(12)
        .fontColor(this.colors.textMuted)
        .textAlign(TextAlign.Center)
        .lineHeight(18)
        .maxLines(4)
    }
    .width('92%').padding(28).backgroundColor(this.colors.cardDark)
    .borderRadius(Theme.radiusLarge)
    .border({ width: 1, color: this.colors.borderSoft })
    .shadow({
      radius: 16,
      color: PageTheme.isDarkFor(this.themeMode)
        ? 'rgba(0, 0, 0, 0.35)'
        : 'rgba(0, 0, 0, 0.08)',
      offsetX: 0,
      offsetY: 6
    })
    .margin({ top: 4, bottom: 24 })
    .alignItems(HorizontalAlign.Center)
  }
}