// entry/src/main/ets/pages/HomePage.ets

import { mediaquery, router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { Theme, ThemeColors, ThemeMode, ThemePreset } from '../common/Theme';
import { PageTheme } from '../common/PageTheme';
import { AppLogger } from '../helper/AppLogger';
import { PdfExportHelper } from '../utils/PdfExportHelper';
import {
  STORAGE_KEY_APP_FOREGROUND_TICK,
  STORAGE_KEY_APP_THEME,
  STORAGE_KEY_AUTO_SHOW_RAMADAN_VIEW,
  STORAGE_KEY_BREAKPOINT,
  STORAGE_KEY_CALC_SETTINGS_VERSION,
  STORAGE_KEY_EVENT_SETTINGS_VERSION,
  STORAGE_KEY_HIJRI_CALENDAR_TYPE,
  STORAGE_KEY_HIJRI_OFFSET,
  STORAGE_KEY_LANGUAGE,
  STORAGE_KEY_LOCATION_VERSION,
  STORAGE_KEY_PRAYER_STATE_VERSION,
  STORAGE_KEY_SETTINGS_INITIAL_CATEGORY,
  STORAGE_KEY_SHOW_ISLAMIC_EVENTS,
  STORAGE_KEY_TASBIH_STATE_VERSION,
  STORAGE_KEY_THEME_MODE,
  STORAGE_KEY_TIME_FORMAT
} from '../common/StorageKeys';
import { ClockFormat, ClockFormatHelper } from '../common/ClockFormat';
import { DateHelper } from '../utils/DateUtils';
import { PrayerModel } from '../prayer/PrayerModel';
import { UpcomingImportantDate } from '../models/DateModels';
import { LocationData, LocationHelper } from '../utils/LocationUtils';
import { LocationCache } from '../utils/LocationCache';
import { HomeController } from '../utils/HomeController';
import { PrayerOffsets, SettingsHelper } from '../helper/SettingsHelper';
import { CalculationSource, LocationMode } from '../models/SettingsModels';
import {
  AsrShadowRule,
  CalculationMethod,
  HighLatitudeRule,
  PrayerTimeCalculator
} from '../prayer/PrayerTimeCalculator';
import { PrayerManager } from '../prayer/PrayerManager';
import { NavHelper } from '../helper/NavHelper';
import { L } from '../i8n/LocalizationHelper';
import {
  MonthDayCell,
  MonthProgress,
  PrayerProgress,
  ProgressHelper,
  TasbihTodayProgress
} from '../utils/ProgressHelper';
import { TasbihStorage } from '../tasbih/TasbihStorage';
import { TasbihManager } from '../tasbih/TasbihManager';
import { Tasbih } from '../tasbih/TasbihModels';
import { PageHeader } from '../components/PageHeader';
import { DuaCard } from '../components/DuaCard';
import { DUA_IFTAR, DUA_SUHOOR, DuaEntry } from '../data/Duas';
import {
  LaylatAlQadrNight, RamadanAshra, RamadanHelper, RamadanInfo
} from '../helper/RamadanHelper';
import { Breakpoints } from '../common/Breakpoints';
import {
  AdvancedCalcSettings, DEFAULT_ADVANCED_CALC
} from '../models/AdvancedCalcModels';
import { HijriCalendarType } from '../hijricalendar/HijriCalendarType';
import { EventPerspectiveNotifier } from '../utils/EventPerspectiveNotifier';

export interface RamadanTableRow {
  hijriDate: string;
  gregorianDate: string;
  sahur: string;
  fajr: string;
  dhuhr: string;
  asr: string;
  iftar: string;
  isha: string;
}

@Component
export struct HomePage {

  @StorageLink(STORAGE_KEY_THEME_MODE)
  @Watch('onThemeModeChanged')
  themeMode: string = ThemeMode.SYSTEM;
  @StorageLink(STORAGE_KEY_PRAYER_STATE_VERSION)
  @Watch('onPrayerStateChanged')
  prayerStateVersion: number = 0;

  @StorageLink(STORAGE_KEY_LOCATION_VERSION)
  @Watch('onLocationVersionChanged')
  locationVersion: number = 0;
  @StorageLink(STORAGE_KEY_EVENT_SETTINGS_VERSION)
  @Watch('onEventSettingsChanged')
  eventSettingsVersion: number = 0;
  @StorageLink(STORAGE_KEY_TASBIH_STATE_VERSION)
  @Watch('onTasbihStateChanged')
  tasbihStateVersion: number = 0;
  @StorageLink(STORAGE_KEY_AUTO_SHOW_RAMADAN_VIEW)
  @Watch('onAutoShowRamadanViewChanged')
  autoShowRamadanView: boolean = true;

  @StorageLink(STORAGE_KEY_LANGUAGE)
  @Watch('onLanguageChanged')
  appLanguage: string = 'en';
  @StorageLink(STORAGE_KEY_APP_THEME)
  @Watch('onAppThemePresetChanged')
  appThemePreset: string = ThemePreset.SIRAT;
  @StorageLink(STORAGE_KEY_SHOW_ISLAMIC_EVENTS)
  @Watch('onShowIslamicEventsChanged')
  showIslamicEvents: boolean = true;
  @StorageLink(STORAGE_KEY_CALC_SETTINGS_VERSION)
  @Watch('onCalcSettingsChanged')
  calcSettingsVersion: number = 0;

  @StorageLink(STORAGE_KEY_HIJRI_OFFSET)
  @Watch('onHijriOffsetChanged')
  hijriOffset: number = 0;

  @StorageLink(STORAGE_KEY_APP_FOREGROUND_TICK)
  @Watch('onAppForegrounded')
  appForegroundTick: number = 0;

  @StorageLink(STORAGE_KEY_BREAKPOINT)
  breakpoint: string = 'sm';

  @StorageLink(STORAGE_KEY_TIME_FORMAT)
  @Watch('onClockFormatChanged')
  clockFormat: string = ClockFormat.SYSTEM;
  @StorageLink(STORAGE_KEY_HIJRI_CALENDAR_TYPE)
  @Watch('onHijriCalendarTypeChanged')
  hijriCalendarType: string = HijriCalendarType.UMM_AL_QURA;

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
  @State isExportingRamadan: boolean = false;
  @State pdfRamadanDays: RamadanTableRow[] = [];
  @State pdfColors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);
  @State pdfRamadanHijriSpan: string = '';
  @State pdfRamadanGregSpan: string = '';
  @State pdfRamadanYear: number = 1447;

  @State locationMode: LocationMode = LocationMode.GPS;
  @State prayerProgress: PrayerProgress = {
    todayCompleted: 0,
    todayTotal: 5,
    todayFajr: false,
    todayDhuhr: false,
    todayAsr: false,
    todayMaghrib: false,
    todayIsha: false,
    currentStreak: 0,
    bestStreak: 0,
    weeklyGrid: [false, false, false, false, false, false, false],
    weeklyLabels: ['S', 'M', 'T', 'W', 'T', 'F', 'S'],
    weekCompleted: 0,
    monthCompleted: 0,
    yearCompleted: 0
  };
  @State private tasbihToday: TasbihTodayProgress = {
    dhikrsCompleted: 0,
    dhikrsTotal: 0,
    percent: 0,
    totalTasbihs: 0,
    lifetimeCount: 0
  };

  @State private monthProgress: MonthProgress = {
    year: 2026,
    monthIndex: 0,
    cells: [],
    weeks: [],
    totalCompleted: 0,
    perfectDays: 0,
    daysElapsed: 0,
    daysInMonth: 0
  };

  @State private upcomingEvents: UpcomingImportantDate[] = [];
  @State private ramadanInfo: RamadanInfo | null = null;

  @State private todayImsakTime: string = '--:--';
  @State private todayMaghribTime: string = '--:--';
  @State private fastingWindowIsPreview: boolean = false;
  @State private countdownTarget: string = '';
  @State private countdownDisplay: string = '';
  @State private countdownHeld: boolean = false;
  private countdownTimerId: number = -1;

  @State private isRefreshing: boolean = false;

  @State calcMethod: CalculationMethod = CalculationMethod.KARACHI;
  @State asrRule: AsrShadowRule = AsrShadowRule.STANDARD;
  @State calcSource: CalculationSource = CalculationSource.LOCAL;
  private highLatRule: HighLatitudeRule = HighLatitudeRule.NONE;
  private offsets: PrayerOffsets = {
    fajr: 0,
    dhuhr: 0,
    asr: 0,
    maghrib: 0,
    isha: 0
  };
  private advanced: AdvancedCalcSettings = DEFAULT_ADVANCED_CALC;

  private settingsLoading: boolean = false;
  private settingsPending: boolean = false;

  @State private currentLanguage: string = 'en';

  private onShowIslamicEventsChanged(): void {
    // Re-render is handled by the @StorageLink.
  }

  private onTasbihStateChanged(): void {
    this.refreshTasbihData();
  }

  private onEventSettingsChanged(): void {
    this.upcomingEvents = DateHelper.getUpcomingImportantDates(
      this.hijriOffset,
      SettingsHelper.getEventPerspective()
    );
  }

  private onAutoShowRamadanViewChanged(): void {
    this.refreshRamadan(); // Instantly re-evaluate visibility
  }

  private async onCalcSettingsChanged(): Promise<void> {
    await this.loadSettingsAndLocation();
  }

  private tr(key: string): string {
    return L.get(key, this.currentLanguage);
  }

  private dt(t: string): string {
    if (this.clockFormat.length === 0) {
      return t;
    }
    return ClockFormatHelper.reformat(t);
  }

  private onHijriCalendarTypeChanged(): void {
    this.refreshHijriDate();
    this.refreshRamadan();
    this.upcomingEvents = DateHelper.getUpcomingImportantDates(this.hijriOffset, SettingsHelper.getEventPerspective());
  }

  private isRtl(): boolean {
    return L.isRtlLang(this.currentLanguage);
  }

  private isTablet(): boolean {
    return Breakpoints.isTablet(this.breakpoint);
  }

  private isDarkMode(): boolean {
    return PageTheme.isDarkFor(this.themeMode);
  }

  private onAppThemePresetChanged(): void {
    this.colors = PageTheme.compute(this.themeMode);
  }

  private onClockFormatChanged(): void {
    // Re-render is handled by the @StorageLink.
  }

  private onPrayerStateChanged(): void {
    this.refreshDashboard();
  }

  private translatePrayerName(raw: string): string {
    switch (raw) {
      case 'Fajr':
        return this.tr('prayer_fajr');
      case 'Dhuhr':
        return this.tr('prayer_dhuhr');
      case 'Asr':
        return this.tr('prayer_asr');
      case 'Maghrib':
        return this.tr('prayer_maghrib');
      case 'Isha':
        return this.tr('prayer_isha');
      case 'Jummah':
        return this.tr('prayer_jummah');
      default:
        return raw;
    }
  }

  private translateEventName(raw: string): string {
    const asPrayer = this.translatePrayerName(raw);
    if (asPrayer !== raw) {
      return asPrayer;
    }
    switch (raw) {
      case 'Imsak':
        return this.tr('timing_imsak');
      case 'Sunrise':
        return this.tr('timing_sunrise');
      case 'Sunset':
        return this.tr('timing_sunset');
      case 'First Third':
        return this.tr('timing_first_third');
      case 'Midnight':
        return this.tr('timing_midnight');
      case 'Last Third':
        return this.tr('timing_last_third');
      default:
        return raw;
    }
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

  private translateEventSignificance(key: string): string {
    const descKey = 'event_' + key + '_desc';
    const translated = this.tr(descKey);
    // L.get falls back to the key itself when missing. Return an
    // empty string in that case so the layout collapses cleanly.
    return translated === descKey ? '' : translated;
  }

  private onThemeModeChanged(): void {
    this.colors = PageTheme.compute(this.themeMode);
  }

  private onLanguageChanged(): void {
    this.currentLanguage = this.appLanguage;
    this.prayerProgress =
      ProgressHelper.getPrayerProgress(this.currentLanguage);
  }

  private async onLocationVersionChanged(): Promise<void> {
    await this.loadSettingsAndLocation();
    await this.refreshDashboard();
  }

  private onHijriOffsetChanged(): void {
    this.refreshHijriDate();
    this.refreshRamadan();
    this.upcomingEvents = DateHelper.getUpcomingImportantDates(this.hijriOffset, SettingsHelper.getEventPerspective());
  }

  private async onAppForegrounded(): Promise<void> {
    this.refreshHijriDate();
    this.refreshRamadan();
    this.upcomingEvents = DateHelper.getUpcomingImportantDates(this.hijriOffset, SettingsHelper.getEventPerspective());
    await this.loadSettingsAndLocation();
    await this.refreshDashboard();
    this.updateCountdown();
    this.startCountdownTimer();
    this.refreshLocationSilently();
  }

  private eventPerspectiveListener: () => void = (): void => {
    console.info('[HomePage] perspective listener fired');
    this.upcomingEvents = DateHelper.getUpcomingImportantDates(
      this.hijriOffset,
      SettingsHelper.getEventPerspective()
    );
  };

  async aboutToAppear(): Promise<void> {
    this.currentLanguage = this.appLanguage;
    this.colors = PageTheme.compute(this.themeMode);

    this.systemDarkListener = PageTheme.installSystemListener(this.themeMode, (c) => {
      this.colors = c;
    });

    const ctx = getContext(this) as common.UIAbilityContext;
    await TasbihStorage.init(ctx);

    this.refreshHijriDate();
    this.refreshRamadan();
    this.upcomingEvents = DateHelper.getUpcomingImportantDates(this.hijriOffset, SettingsHelper.getEventPerspective());
    await this.loadSettingsAndLocation();
    await this.refreshDashboard();
    this.startCountdownTimer();
    this.refreshLocationSilently();
    EventPerspectiveNotifier.subscribe(this.eventPerspectiveListener);
  }

  aboutToDisappear(): void {
    PageTheme.uninstallSystemListener(this.systemDarkListener);
    this.systemDarkListener = null;
    this.stopCountdownTimer();
    EventPerspectiveNotifier.unsubscribe(this.eventPerspectiveListener);
  }

  async onPageShow(): Promise<void> {
    this.currentLanguage = this.appLanguage;
    this.colors = PageTheme.compute(this.themeMode);
    this.refreshHijriDate();
    this.refreshRamadan();
    this.upcomingEvents = DateHelper.getUpcomingImportantDates(this.hijriOffset, SettingsHelper.getEventPerspective());
    await this.refreshDashboard();
    this.startCountdownTimer();
  }

  onPageHide(): void {
    this.stopCountdownTimer();
  }

  private async loadSettingsAndLocation(): Promise<void> {
    if (this.settingsLoading) {
      // A load is already in flight. Queue exactly one follow-up so
      // a second settings change during the same burst is not lost.
      this.settingsPending = true;
      return;
    }
    this.settingsLoading = true;

    try {
      const data = await SettingsHelper.loadAll();
      this.calcMethod = data.method;
      this.asrRule = data.asr;
      this.calcSource = data.source;
      this.highLatRule = await SettingsHelper.getHighLatRule();
      this.offsets = await SettingsHelper.getPrayerOffsets();
      this.advanced = await SettingsHelper.getAdvancedCalcSettings();
      this.locationMode = await SettingsHelper.getLocationMode();

      const loc = await HomeController.loadLocationForMode(this.locationMode);
      this.latitude = loc.latitude;
      this.longitude = loc.longitude;
      this.currentLocation = loc.displayName;
      this.isLoadingLocation = false;

      this.refreshHeader();
      this.refreshFastingWindow();
    } finally {
      this.settingsLoading = false;
      if (this.settingsPending) {
        this.settingsPending = false;
        // Fire-and-forget; the second pass will complete on its own.
        this.loadSettingsAndLocation();
      }
    }
  }

  private async refreshDashboard(): Promise<void> {
    this.prayerProgress = ProgressHelper.getPrayerProgress(this.currentLanguage);
    this.monthProgress = ProgressHelper.getMonthProgress();

    const loaded = await TasbihStorage.load(TasbihManager.createDefaults());
    const tasbihs: Tasbih[] = loaded.tasbihs;
    this.tasbihToday = ProgressHelper.getTasbihTodayProgress(tasbihs);

    this.refreshHeader();
    this.refreshFastingWindow();
  }

  private async refreshTasbihData(): Promise<void> {
    const loaded = await TasbihStorage.load(TasbihManager.createDefaults());
    this.tasbihToday = ProgressHelper.getTasbihTodayProgress(loaded.tasbihs);
  }

  private refreshHeader(): void {
    if (this.calcSource !== CalculationSource.LOCAL) {
      return;
    }

    const template: PrayerModel[] = [
      {
        id: 'fajr',
        name: 'Fajr',
        arabicName: 'الفجر',
        time: '--:--',
        status: 'abbreviation',
        checked: false
      },
      {
        id: 'dhuhr',
        name: 'Dhuhr',
        arabicName: 'الظهر',
        time: '--:--',
        status: 'abbreviation',
        checked: false
      },
      {
        id: 'asr',
        name: 'Asr',
        arabicName: 'العصر',
        time: '--:--',
        status: 'abbreviation',
        checked: false
      },
      {
        id: 'maghrib',
        name: 'Maghrib',
        arabicName: 'المغرب',
        time: '--:--',
        status: 'abbreviation',
        checked: false
      },
      {
        id: 'isha',
        name: 'Isha',
        arabicName: 'العشاء',
        time: '--:--',
        status: 'abbreviation',
        checked: false
      }
    ];

    const prayers = PrayerManager.loadStateForDate(
      PrayerManager.getDateKeyForDate(new Date()),
      template,
      new Date()
    );

    const hdr = HomeController.buildTodayHeader(
      this.latitude, this.longitude, this.calcMethod, this.asrRule,
      this.highLatRule, this.offsets, prayers, this.advanced
    );
    if (!hdr) {
      return;
    }
    this.todayCurrentPrayerName = hdr.currentName;
    this.todayCurrentPrayerTime = hdr.currentTime;
    this.todayNextPrayerName = hdr.nextName;
    this.todayNextPrayerTime = hdr.nextTime;
  }

  private refreshFastingWindow(): void {
    this.todayImsakTime = '--:--';
    this.todayMaghribTime = '--:--';

    let targetDate: Date = new Date();
    let isPreview = false;

    if (this.ramadanInfo !== null && !this.ramadanInfo.isRamadanNow) {
      targetDate = this.ramadanInfo.fastingStart;
      isPreview = true;
    }
    this.fastingWindowIsPreview = isPreview;

    if (this.calcSource !== CalculationSource.LOCAL) {
      return;
    }
    if (this.latitude === 0 && this.longitude === 0) {
      return;
    }

    try {
      const times = PrayerTimeCalculator.calculateWithDeviceTimezone(
        targetDate, this.latitude, this.longitude,
        this.calcMethod, this.asrRule, this.highLatRule, this.advanced
      );

      const imsak = PrayerManager.offsetTime(times.imsak, this.offsets.fajr);
      const maghrib = PrayerManager.offsetTime(times.maghrib, this.offsets.maghrib);

      this.todayImsakTime = imsak;
      this.todayMaghribTime = maghrib;
      this.updateCountdown();
    } catch (err) {
      const e = err as Error;
      console.error('[HomePage] refreshFastingWindow failed: ' + e.message);
    }
  }

  private refreshHijriDate(): void {
    const shifted = new Date();
    shifted.setDate(shifted.getDate() + this.hijriOffset);
    this.hijriDateString = DateHelper.getFormattedHijriDateFor(shifted);
  }

  private refreshRamadan(): void {
    const info = RamadanHelper.getRamadanInfo(this.hijriOffset);
    if (!info) {
      this.ramadanInfo = null;
      this.refreshFastingWindow();
      return;
    }

    // If auto is ON: enforce the 60-day rule. If auto is OFF: always show.
    if (this.autoShowRamadanView) {
      if (info.isRamadanNow || (info.daysUntilStart >= 0 && info.daysUntilStart <= 60)) {
        this.ramadanInfo = info;
      } else {
        this.ramadanInfo = null;
      }
    } else {
      this.ramadanInfo = info;
    }

    this.refreshFastingWindow();
  }

  private currentAshra(): RamadanAshra | null {
    if (!this.ramadanInfo || !this.ramadanInfo.isRamadanNow) {
      return null;
    }
    const day = this.ramadanInfo.currentDayNumber;
    for (const a of this.ramadanInfo.ashras) {
      if (day >= a.startHijriDay && day <= a.endHijriDay) {
        return a;
      }
    }
    return null;
  }

  private isCurrentAshra(a: RamadanAshra): boolean {
    const cur = this.currentAshra();
    return cur !== null && cur.number === a.number;
  }

  private currentDuaEntry(): DuaEntry | null {
    if (this.countdownTarget === 'maghrib') {
      return DUA_IFTAR;
    }
    if (this.countdownTarget === 'imsak') {
      return DUA_SUHOOR;
    }
    return null;
  }

  private async handleExportRamadan(): Promise<void> {
    if (this.isExportingRamadan || !this.ramadanInfo) {
      return;
    }
    this.isExportingRamadan = true;
    this.pdfRamadanDays = [];
    this.pdfColors = PageTheme.compute(ThemeMode.LIGHT); // Force light mode

    try {
      this.pdfRamadanYear = this.ramadanInfo.hijriYear;

      // Get Ramadan month names
      const hijriMonths = L.getArray('hijri_months', this.appLanguage);
      const ramadanName = hijriMonths[8] || 'Ramadan';

      // Calculate start and end dates
      const startDate = new Date(this.ramadanInfo.fastingStart);
      const totalDays = this.ramadanInfo.totalDays;
      const endDate = new Date(startDate);
      endDate.setDate(endDate.getDate() + totalDays - 1);

      // Format spans
      const locale = this.appLanguage === 'zh' ? 'zh-CN' : (this.appLanguage === 'ar' ? 'ar' : 'en-US');

      const startHStr = DateHelper.getFormattedHijriDateFor(startDate);
      const endHStr = DateHelper.getFormattedHijriDateFor(endDate);
      this.pdfRamadanHijriSpan = `${startHStr} – ${endHStr}`;

      const startGStr = startDate.toLocaleString(locale, { month: 'short', day: 'numeric' });
      const endGStr = endDate.toLocaleString(locale, { month: 'short', day: 'numeric', year: 'numeric' });
      this.pdfRamadanGregSpan = `${startGStr} – ${endGStr}`;

      const rows: RamadanTableRow[] = [];

      for (let i = 0; i < totalDays; i++) {
        const date = new Date(startDate);
        date.setDate(date.getDate() + i);

        const times = PrayerTimeCalculator.calculateWithDeviceTimezone(
          date, this.latitude, this.longitude, this.calcMethod,
          this.asrRule, this.highLatRule, this.advanced
        );

        const shortHijri = `${i + 1} ${ramadanName}`;
        const shortGregorian = `${date.getDate()}/${date.getMonth() + 1}`;

        rows.push({
          hijriDate: shortHijri,
          gregorianDate: shortGregorian,
          sahur: PrayerManager.offsetTime(times.imsak, this.offsets.fajr),
          fajr: PrayerManager.offsetTime(times.fajr, this.offsets.fajr),
          dhuhr: PrayerManager.offsetTime(times.dhuhr, this.offsets.dhuhr),
          asr: PrayerManager.offsetTime(times.asr, this.offsets.asr),
          iftar: PrayerManager.offsetTime(times.maghrib, this.offsets.maghrib),
          isha: PrayerManager.offsetTime(times.isha, this.offsets.isha)
        });
      }

      this.pdfRamadanDays = rows;
      const ctx = getContext(this) as common.UIAbilityContext;

      await new Promise<void>((resolve) => setTimeout(() => resolve(), 100));

      await PdfExportHelper.exportBuilderToPdf(
        ctx, this.getUIContext(), this.RamadanExportLayout.bind(this), 'Ramadan_Timetable'
      );
    } catch (err) {
      console.error('Ramadan PDF failed:', JSON.stringify(err));
    } finally {
      this.isExportingRamadan = false;
    }
  }

  private parseTimeToDateToday(timeStr: string): Date | null {
    const trimmed = timeStr.trim();
    if (trimmed === '' || trimmed === '--:--') {
      return null;
    }

    const parts = trimmed.split(' ');
    if (parts.length !== 2) {
      return null;
    }

    const tp = parts[0].split(':');
    if (tp.length !== 2) {
      return null;
    }

    let hours = parseInt(tp[0], 10);
    const minutes = parseInt(tp[1], 10);
    if (isNaN(hours) || isNaN(minutes)) {
      return null;
    }

    const period = parts[1].toUpperCase();
    if (period === 'PM' && hours !== 12) {
      hours += 12;
    }
    if (period === 'AM' && hours === 12) {
      hours = 0;
    }

    const d = new Date();
    d.setHours(hours, minutes, 0, 0);
    return d;
  }

  private updateCountdown(): void {
    if (this.ramadanInfo === null || !this.ramadanInfo.isRamadanNow) {
      this.clearCountdown();
      return;
    }

    const WINDOW_MS = 15 * 60 * 1000;
    const HOLD_MS = 5 * 60 * 1000;
    const nowMs = Date.now();

    const imsak = this.parseTimeToDateToday(this.todayImsakTime);
    const maghrib = this.parseTimeToDateToday(this.todayMaghribTime);

    let holdTarget = '';
    let holdRemainingMs = Number.MAX_VALUE;

    if (maghrib !== null) {
      const delta = nowMs - maghrib.getTime();
      if (delta >= 0 && delta < HOLD_MS) {
        const remaining = HOLD_MS - delta;
        if (remaining < holdRemainingMs) {
          holdRemainingMs = remaining;
          holdTarget = 'maghrib';
        }
      }
    }
    if (imsak !== null) {
      const delta = nowMs - imsak.getTime();
      if (delta >= 0 && delta < HOLD_MS) {
        const remaining = HOLD_MS - delta;
        if (remaining < holdRemainingMs) {
          holdRemainingMs = remaining;
          holdTarget = 'imsak';
        }
      }
    }

    if (holdTarget !== '') {
      if (this.countdownTarget !== holdTarget) {
        this.countdownTarget = holdTarget;
      }
      if (this.countdownDisplay !== '00:00') {
        this.countdownDisplay = '00:00';
      }
      if (!this.countdownHeld) {
        this.countdownHeld = true;
      }
      return;
    }

    let target = '';
    let diffMs = Number.MAX_VALUE;

    if (imsak !== null) {
      const d = imsak.getTime() - nowMs;
      if (d > 0 && d <= WINDOW_MS && d < diffMs) {
        target = 'imsak';
        diffMs = d;
      }
    }
    if (maghrib !== null) {
      const d = maghrib.getTime() - nowMs;
      if (d > 0 && d <= WINDOW_MS && d < diffMs) {
        target = 'maghrib';
        diffMs = d;
      }
    }

    if (target === '') {
      this.clearCountdown();
      return;
    }

    const totalSec = Math.max(0, Math.floor(diffMs / 1000));
    const mm = Math.floor(totalSec / 60);
    const ss = totalSec % 60;
    const display = `${mm.toString().padStart(2, '0')}:${ss.toString().padStart(2, '0')}`;

    if (this.countdownTarget !== target) {
      this.countdownTarget = target;
    }
    if (this.countdownDisplay !== display) {
      this.countdownDisplay = display;
    }
    if (this.countdownHeld) {
      this.countdownHeld = false;
    }
  }

  private clearCountdown(): void {
    if (this.countdownTarget !== '') {
      this.countdownTarget = '';
    }
    if (this.countdownDisplay !== '') {
      this.countdownDisplay = '';
    }
    if (this.countdownHeld) {
      this.countdownHeld = false;
    }
  }

  private startCountdownTimer(): void {
    if (this.countdownTimerId !== -1) {
      return;
    }
    this.updateCountdown();
    this.countdownTimerId = setInterval(() => {
      this.updateCountdown();
    }, 1000);
  }

  private stopCountdownTimer(): void {
    if (this.countdownTimerId !== -1) {
      clearInterval(this.countdownTimerId);
      this.countdownTimerId = -1;
    }
  }

  private async handleRefresh(): Promise<void> {
    try {
      this.refreshHijriDate();
      this.refreshRamadan();
      this.upcomingEvents =
        DateHelper.getUpcomingImportantDates(this.hijriOffset, SettingsHelper.getEventPerspective());
      await this.loadSettingsAndLocation();
      await this.refreshDashboard();
    } finally {
      this.isRefreshing = false;
    }
  }

  private navigateToSettings(): void {
    AppStorage.setOrCreate(
      STORAGE_KEY_SETTINGS_INITIAL_CATEGORY, 'Prayer Times'
    );
    NavHelper.prepareForward();
    router.pushUrl({ url: 'pages/SettingsPage' })
      .catch((e: Error) =>
      console.error('Navigation failed:', JSON.stringify(e)));
  }

  private async refreshLocation(): Promise<void> {
    if (this.isLoadingLocation) {
      return;
    }
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
        this.refreshHeader();
        this.refreshFastingWindow();
      } catch (err) {
        console.error('Manual refresh failed:', JSON.stringify(err));
      } finally {
        this.isLoadingLocation = false;
      }
      return;
    }

    try {
      const data: LocationData = await LocationHelper.fetchLocationData(getContext(this));
      this.latitude = data.latitude;
      this.longitude = data.longitude;
      this.currentLocation = data.cityName;
      await LocationCache.save(data.latitude, data.longitude, data.cityName);
      this.refreshHeader();
      this.refreshFastingWindow();
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

      AppLogger.info('HomePage',
        `Silent location refresh: ${data.latitude.toFixed(4)}, ` +
          `${data.longitude.toFixed(4)} (${data.cityName})`);

      this.latitude = data.latitude;
      this.longitude = data.longitude;
      this.currentLocation = data.cityName;

      await LocationCache.save(data.latitude, data.longitude, data.cityName);

      this.refreshHeader();
      this.refreshFastingWindow();
    } catch (err) {
      const e = err as Error;
      console.info(
        `[HomePage] silent location refresh skipped: ${e.message}`
      );
    }
  }

  private cellBg(cell: MonthDayCell): string {
    if (cell.isPadding || cell.isFuture) {
      return 'transparent';
    }
    if (cell.completed === 5) {
      return this.colors.accentGold;
    }
    if (cell.completed >= 3) {
      return this.colors.tintMedium;
    }
    if (cell.completed >= 1) {
      return this.colors.tintSubtle;
    }
    return 'transparent';
  }

  private navigateToLocationSettings(): void {
    AppStorage.setOrCreate(
      STORAGE_KEY_SETTINGS_INITIAL_CATEGORY, 'Location'
    );
    NavHelper.prepareForward();
    router.pushUrl({ url: 'pages/SettingsPage' })
      .catch((e: Error) =>
      console.error('Navigation failed:', JSON.stringify(e)));
  }

  private cellTextColor(cell: MonthDayCell): string {
    if (cell.isFuture) {
      return this.colors.textMuted;
    }
    if (cell.completed === 5) {
      return this.colors.textOnAccent;
    }
    if (cell.isToday) {
      return this.colors.accentGold;
    }
    if (cell.completed > 0) {
      return this.colors.accentGold;
    }
    return this.colors.textMuted;
  }

  private cellBorderColor(cell: MonthDayCell): string {
    if (cell.isToday) {
      return this.colors.accentGold;
    }
    return 'transparent';
  }

  private cellBorderWidth(cell: MonthDayCell): number {
    return cell.isToday ? 2 : 0;
  }

  private monthDayLabels(): string[] {
    return L.getArray('days_of_week_short', this.currentLanguage);
  }

  build() {
    Stack() {
      Column() {
        // inside the Column, before PageHeader:
        //   if (deviceInfo.sdkApiVersion < 23) {
        //     Column().height(72)
        //   }
        // Fixed page header — Hijri pill, location, current prayer,
        // and calc pills. HdsNavigation provides the top offset, so
        // no spacer is needed.
        PageHeader({
          colors: this.colors,
          currentLanguage: this.currentLanguage,
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

        Refresh({ refreshing: $$this.isRefreshing }) {
          Scroll() {
            Column() {
              if (this.isTablet()) {
                Row({ space: 16 }) {
                  Column() {
                    if (this.showIslamicEvents) {
                      this.CountdownCard()
                    }
                    this.LiveCountdownBanner()
                    if (this.ramadanInfo !== null) {
                      this.RamadanCard()
                    }
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)

                  Column() {
                    this.TodayProgressCard()
                    this.TasbihCard()
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                }
                .width('100%')
                .alignItems(VerticalAlign.Top)
                .padding({ left: 24, right: 24 })
              } else {
                Column() {
                  // ---- Next Event ----
                  if (this.showIslamicEvents) {
                    this.CountdownCard()
                  }
                  this.LiveCountdownBanner()
                  this.RamadanCard()

                  // ---- Prayers ----
                  this.TodayProgressCard()

                  // ---- Tasbih ----
                  this.TasbihCard()
                }
                .width('100%')
                .padding({ left: 16, right: 16 })
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
        .onRefreshing(() => {
          this.handleRefresh();
        })
      }
      .width('100%').height('100%').backgroundColor(this.colors.primaryGreen)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.primaryGreen)
    .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
  }

  @Builder
  RamadanExportLayout() {
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
          Text(`${L.getArray('hijri_months', this.appLanguage)[8]} ${this.pdfRamadanYear} ${L.get('hijri_year_suffix',
            this.appLanguage)}`)
            .fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.pdfColors.textWhite)

          Text(`${this.pdfRamadanGregSpan} · ${this.currentLocation}`)
            .fontSize(10).fontColor(this.pdfColors.accentGold).margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        // Localized Footer
        Text(L.get('generated_by', this.appLanguage))
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
        Text(L.get('export_date', this.appLanguage))
          .layoutWeight(1.8)
          .fontWeight(FontWeight.Bold)
          .fontSize(9)
          .fontColor(this.pdfColors.accentGold)
        Text(L.get('export_sahur', this.appLanguage))
          .layoutWeight(1)
          .fontWeight(FontWeight.Bold)
          .fontSize(9)
          .fontColor(this.pdfColors.accentGold)
        Text(L.get('prayer_fajr', this.appLanguage))
          .layoutWeight(1)
          .fontWeight(FontWeight.Bold)
          .fontSize(9)
          .fontColor(this.pdfColors.accentGold)
        Text(L.get('prayer_dhuhr', this.appLanguage))
          .layoutWeight(1)
          .fontWeight(FontWeight.Bold)
          .fontSize(9)
          .fontColor(this.pdfColors.accentGold)
        Text(L.get('prayer_asr', this.appLanguage))
          .layoutWeight(1)
          .fontWeight(FontWeight.Bold)
          .fontSize(9)
          .fontColor(this.pdfColors.accentGold)
        Text(L.get('export_iftar', this.appLanguage))
          .layoutWeight(1)
          .fontWeight(FontWeight.Bold)
          .fontSize(9)
          .fontColor(this.pdfColors.accentGold)
        Text(L.get('prayer_isha', this.appLanguage))
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
        ForEach(this.pdfRamadanDays, (row: RamadanTableRow, index: number) => {
          Row() {
            Column() {
              Text(row.hijriDate)
                .fontSize(9)
                .lineHeight(11)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.pdfColors.textWhite)
              Text(row.gregorianDate).fontSize(7).lineHeight(9).fontColor(this.pdfColors.textMuted).margin({ top: 0 })
            }.layoutWeight(1.8).alignItems(HorizontalAlign.Start)

            Text(row.sahur).layoutWeight(1).fontSize(8).fontColor(this.pdfColors.textWhite)
            Text(row.fajr).layoutWeight(1).fontSize(8).fontColor(this.pdfColors.textWhite)
            Text(row.dhuhr).layoutWeight(1).fontSize(8).fontColor(this.pdfColors.textWhite)
            Text(row.asr).layoutWeight(1).fontSize(8).fontColor(this.pdfColors.textWhite)
            Text(row.iftar).layoutWeight(1).fontSize(8).fontColor(this.pdfColors.accentGoldLight) // Highlight Iftar
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
        Text(L.get('generated_by', this.appLanguage)).fontSize(8).lineHeight(12).fontColor(this.pdfColors.textMuted)
      }
      .width('100%').padding({ top: 4, bottom: 4 }).justifyContent(FlexAlign.Center)
    }
    .width(595).height(842).backgroundColor(this.pdfColors.primaryGreen)
  }

  @Builder
  CountdownCard() {
    if (this.upcomingEvents.length > 0) {
      Column() {
        Row() {
          Text('✨').fontSize(14).margin({ right: 8 })
          Text(this.tr('home_next_event'))
            .fontSize(11)
            .fontColor(this.colors.textMuted)
            .fontWeight(FontWeight.Bold)
            .letterSpacing(1.2)
            .layoutWeight(1)
        }
        .width('100%').padding({ bottom: 14 })

        this.CountdownMainEvent()

        if (this.upcomingEvents.length > 1) {
          Divider().color(this.colors.borderSoft)
            .margin({ top: 14, bottom: 12 })
          Column() {
            this.CountdownSecondaryRow(1)
            if (this.upcomingEvents.length > 2) {
              this.CountdownSecondaryRow(2)
            }
          }
          .width('100%')
        }
      }
      .width('100%')
      .padding(18)
      .backgroundColor(this.colors.cardDark)
      .borderRadius(Theme.radiusLarge)
      .border({ width: 1, color: this.colors.borderSoft })
      .shadow({
        radius: 12,
        color: this.colors.shadowCard,
        offsetX: 0,
        offsetY: 4
      })
      .margin({ bottom: 14 })
    }
  }

  @Builder
  CountdownMainEvent() {
    Row() {
      Column() {
        if (this.upcomingEvents[0].daysUntil === 0) {
          Text('🎉').fontSize(30)
          Text(this.tr('home_event_today'))
            .fontSize(12).fontWeight(FontWeight.Bold)
            .fontColor(this.colors.textOnAccent)
            .margin({ top: 2 })
        } else if (this.upcomingEvents[0].daysUntil === 1) {
          Text('1')
            .fontSize(38).fontWeight(FontWeight.Bold)
            .fontColor(this.colors.textOnAccent)
          Text(this.tr('home_event_tomorrow'))
            .fontSize(10).fontWeight(FontWeight.Medium)
            .fontColor(this.colors.textOnAccent).opacity(0.9)
        } else {
          Text(`${this.upcomingEvents[0].daysUntil}`)
            .fontSize(38).fontWeight(FontWeight.Bold)
            .fontColor(this.colors.textOnAccent)
          Text(this.tr('home_days'))
            .fontSize(11).fontWeight(FontWeight.Medium)
            .fontColor(this.colors.textOnAccent).opacity(0.9)
        }
      }
      .width(84)
      .height(84)
      .backgroundColor(this.colors.accentGold)
      .borderRadius(18)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Column() {
        Text(this.translateUpcomingEventName(this.upcomingEvents[0]))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textWhite)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(this.upcomingEvents[0].hijriDate)
          .fontSize(12)
          .fontColor(this.colors.accentGold)
          .margin({ top: 6 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        if (this.translateEventSignificance(this.upcomingEvents[0].key).length > 0) {
          Text(this.translateEventSignificance(this.upcomingEvents[0].key))
            .fontSize(11)
            .fontColor(this.colors.textMuted)
            .lineHeight(16)
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 8 })
            .width('100%')
        }
      }
      .layoutWeight(1).margin({ left: 16 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  CountdownSecondaryRow(index: number) {
    Row() {
      Text('✨').fontSize(13).margin({ right: 8 }).opacity(0.75)
      Text(this.translateUpcomingEventName(this.upcomingEvents[index]))
        .fontSize(13)
        .fontColor(this.colors.textWhite)
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
      Text(this.countdownShortLabel(this.upcomingEvents[index].daysUntil))
        .fontSize(11).fontColor(this.colors.accentGold)
        .margin({ left: 8 })
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
    .alignItems(VerticalAlign.Center)
  }

  private countdownShortLabel(days: number): string {
    if (days === 0) {
      return this.tr('home_event_today');
    }
    if (days === 1) {
      return this.tr('home_event_tomorrow');
    }
    return `${days} ${this.tr('home_days')}`;
  }

  @Builder
  LiveCountdownBanner() {
    if (this.countdownTarget !== '') {
      Column() {
        Row() {
          Text(this.countdownTarget === 'maghrib' ? '🌇' : '🌅')
            .fontSize(32)
            .margin({ right: 14 })

          Column() {
            Text(this.countdownHeld
              ? (this.countdownTarget === 'maghrib'
                ? this.tr('countdown_fast_ends_now')
                : this.tr('countdown_fast_starts_now'))
              : (this.countdownTarget === 'maghrib'
                ? this.tr('countdown_fast_ends')
                : this.tr('countdown_fast_starts')))
              .fontSize(12)
              .fontColor(this.countdownHeld
                ? this.colors.accentGold : this.colors.textMuted)
              .fontWeight(FontWeight.Medium)
              .letterSpacing(0.5)

            if (!this.countdownHeld) {
              Text(this.countdownTarget === 'maghrib'
                ? this.tr('countdown_fast_ends_desc')
                : this.tr('countdown_fast_starts_desc'))
                .fontSize(11)
                .fontColor(this.colors.textMuted)
                .fontStyle(FontStyle.Italic)
                .margin({ top: 2 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Text(this.countdownDisplay)
            .fontSize(38)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.colors.accentGold)
            .direction(Direction.Ltr)
            .margin({ left: 12 })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        if (this.countdownHeld && this.currentDuaEntry() !== null) {
          Divider().color(this.colors.borderSoft).margin({ top: 14, bottom: 14 })

          DuaCard({
            dua: this.currentDuaEntry()!,
            colors: this.colors,
            currentLanguage: this.currentLanguage,
            showName: true
          })
        }
      }
      .width('100%')
      .padding(18)
      .backgroundColor(this.colors.cardDark)
      .borderRadius(Theme.radiusLarge)
      .border({ width: 2, color: this.colors.accentGold })
      .shadow({
        radius: 16,
        color: this.colors.shadowFloating,
        offsetX: 0,
        offsetY: 6
      })
      .margin({ bottom: 14 })
    }
  }

  @Builder
  RamadanCard() {
    if (this.ramadanInfo !== null) {
      Column() {
        Row() {
          Text('🌙').fontSize(16).margin({ right: 8 })
          Text(this.tr('ramadan_card_title'))
            .fontSize(12)
            .fontColor(this.colors.textMuted)
            .fontWeight(FontWeight.Bold)
            .letterSpacing(1.2)
            .layoutWeight(1)
          Text(`${this.ramadanInfo!.hijriYear} AH`)
            .fontSize(11).fontColor(this.colors.accentGold)
            .fontWeight(FontWeight.Medium)
        }
        .width('100%').padding({ bottom: 14 })

        if (this.ramadanInfo!.isRamadanNow) {
          this.RamadanInProgress()
        } else {
          this.RamadanCountdown()
        }

        Divider().color(this.colors.borderSoft).margin({ top: 14, bottom: 12 })
        Row() {
          Text('⏳').fontSize(12).margin({ right: 6 }).opacity(0.75)
          Text(this.fastingWindowIsPreview
            ? this.tr('ramadan_first_day_fast')
            : this.tr('ramadan_today_fast'))
            .fontSize(10).fontColor(this.colors.textMuted)
            .fontStyle(FontStyle.Italic)
            .layoutWeight(1)
        }
        .width('100%').padding({ bottom: 6 })

        Row() {
          Text('🌅').fontSize(14).margin({ right: 8 }).width(20).textAlign(TextAlign.Center)
          Text(this.tr('ramadan_fast_start'))
            .fontSize(12).fontColor(this.colors.textMuted).layoutWeight(1)
          Text(this.dt(this.todayImsakTime))
            .fontSize(16).fontColor(this.colors.accentGold).fontWeight(FontWeight.Bold)
            .direction(Direction.Ltr)
        }
        .width('100%').padding({ top: 6, bottom: 6 }).alignItems(VerticalAlign.Center)

        Row() {
          Text('🌇').fontSize(14).margin({ right: 8 }).width(20).textAlign(TextAlign.Center)
          Text(this.tr('ramadan_fast_end'))
            .fontSize(12).fontColor(this.colors.textMuted).layoutWeight(1)
          Text(this.dt(this.todayMaghribTime))
            .fontSize(16).fontColor(this.colors.accentGoldLight).fontWeight(FontWeight.Bold)
            .direction(Direction.Ltr)
        }
        .width('100%').padding({ top: 6, bottom: 6 }).alignItems(VerticalAlign.Center)

        Divider().color(this.colors.borderSoft).margin({ top: 14, bottom: 12 })

        Row() {
          Text('📅').fontSize(14).margin({ right: 8 }).width(20).textAlign(TextAlign.Center)
          Text(this.tr('ramadan_calendar_start'))
            .fontSize(12).fontColor(this.colors.textMuted).layoutWeight(1)
          Text(RamadanHelper.formatLong(
            this.ramadanInfo!.fastingStart, this.currentLanguage))
            .fontSize(12).fontColor(this.colors.accentGold).fontWeight(FontWeight.Medium)
        }
        .width('100%').padding({ top: 4, bottom: 4 }).alignItems(VerticalAlign.Center)

        Row() {
          Text('🌙').fontSize(14).margin({ right: 8 }).width(20).textAlign(TextAlign.Center)
          Text(this.tr('ramadan_calendar_end'))
            .fontSize(12).fontColor(this.colors.textMuted).layoutWeight(1)
          Text(RamadanHelper.formatLong(
            this.ramadanInfo!.fastingEnd, this.currentLanguage))
            .fontSize(12).fontColor(this.colors.accentGoldLight).fontWeight(FontWeight.Medium)
        }
        .width('100%').padding({ top: 4, bottom: 4 }).alignItems(VerticalAlign.Center)

        Divider().color(this.colors.borderSoft).margin({ top: 14, bottom: 12 })
        Text(this.tr('ramadan_ashras'))
          .fontSize(11)
          .fontColor(this.colors.textMuted)
          .fontWeight(FontWeight.Bold)
          .letterSpacing(1.2)
          .width('100%')
          .padding({ bottom: 10 })

        ForEach(this.ramadanInfo!.ashras, (a: RamadanAshra) => {
          Row() {
            Text(`${a.number}`)
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isCurrentAshra(a)
                ? this.colors.textOnAccent : this.colors.accentGold)
              .width(24)
              .height(24)
              .textAlign(TextAlign.Center)
              .backgroundColor(this.isCurrentAshra(a)
                ? this.colors.accentGold : this.colors.tintSoft)
              .borderRadius(12)
              .border({
                width: 1,
                color: this.isCurrentAshra(a)
                  ? this.colors.accentGold : this.colors.borderSoft
              })

            Column() {
              Row() {
                Text(this.tr(a.nameKey))
                  .fontSize(13).fontColor(this.colors.textWhite)
                  .fontWeight(this.isCurrentAshra(a)
                    ? FontWeight.Bold : FontWeight.Medium)
                Text('  ·  ').fontSize(11).fontColor(this.colors.textMuted)
                Text(this.tr(a.significanceKey))
                  .fontSize(11)
                  .fontColor(this.colors.accentGold)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)
              }
              .width('100%')

              Text(`${RamadanHelper.formatShort(a.startDate, this.currentLanguage)} – ${RamadanHelper.formatShort(
                a.endDate, this.currentLanguage)}`)
                .fontSize(10).fontColor(this.colors.textMuted)
                .margin({ top: 2 }).width('100%')
            }
            .layoutWeight(1).margin({ left: 10 })
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding({
            top: 8,
            bottom: 8,
            left: 8,
            right: 8
          })
          .backgroundColor(this.isCurrentAshra(a)
            ? this.colors.tintSubtle : 'transparent')
          .borderRadius(10)
          .margin({ bottom: 4 })
          .alignItems(VerticalAlign.Center)
        }, (a: RamadanAshra) =>
        `ashra-${a.number}-${a.startHijriDay}-${a.endHijriDay}`)

        Divider().color(this.colors.borderSoft).margin({ top: 14, bottom: 12 })
        Row() {
          Text('✨').fontSize(13).margin({ right: 6 })
          Text(this.tr('ramadan_laylat_al_qadr'))
            .fontSize(11).fontColor(this.colors.accentGold)
            .fontWeight(FontWeight.Bold).letterSpacing(1.2)
        }
        .width('100%').padding({ bottom: 8 })

        Text(this.tr('ramadan_laylat_al_qadr_desc'))
          .fontSize(11)
          .fontColor(this.colors.textMuted)
          .lineHeight(16)
          .width('100%')
          .padding({ bottom: 12 })

        Row({ space: 6 }) {
          ForEach(this.ramadanInfo!.laylatAlQadrNights,
            (n: LaylatAlQadrNight) => {
              Column() {
                Text(`${n.hijriDay}`)
                  .fontSize(14)
                  .fontWeight(n.isToday ? FontWeight.Bold : FontWeight.Medium)
                  .fontColor(n.isToday ? this.colors.textOnAccent
                    : n.isPast ? this.colors.textMuted : this.colors.accentGold)
                if (n.isToday) {
                  Text(this.tr('ramadan_today'))
                    .fontSize(8).fontColor(this.colors.textOnAccent)
                    .margin({ top: 1 })
                } else {
                  Text(RamadanHelper.formatShort(
                    n.gregorianDate, this.currentLanguage))
                    .fontSize(8).fontColor(this.colors.textMuted)
                    .margin({ top: 1 })
                }
              }
              .layoutWeight(1)
              .padding({ top: 8, bottom: 8 })
              .backgroundColor(n.isToday ? this.colors.accentGold
                : n.isPast ? 'transparent' : this.colors.tintSubtle)
              .borderRadius(10)
              .border({
                width: n.isToday ? 0 : 1,
                color: n.isPast ? this.colors.borderSoft : this.colors.borderMedium
              })
              .opacity(n.isPast && !n.isToday ? 0.55 : 1.0)
              .alignItems(HorizontalAlign.Center)
            }, (n: LaylatAlQadrNight) =>
            `laq-${n.hijriDay}-${n.isPast ? 'p' : n.isToday ? 't' : 'f'}`)
        }
        .width('100%').justifyContent(FlexAlign.SpaceBetween)

        if (this.ramadanInfo!.jummahTulWidah !== null) {
          Divider().color(this.colors.borderSoft).margin({ top: 14, bottom: 12 })
          Row() {
            Text('🕌').fontSize(13).margin({ right: 6 })
            Text(this.tr('ramadan_jummah_tul_widah'))
              .fontSize(11)
              .fontColor(this.colors.accentGold)
              .fontWeight(FontWeight.Bold)
              .letterSpacing(1.2)
              .layoutWeight(1)
            Text(RamadanHelper.formatShort(
              this.ramadanInfo!.jummahTulWidah!, this.currentLanguage))
              .fontSize(11).fontColor(this.colors.accentGoldLight)
              .fontWeight(FontWeight.Medium)
          }
          .width('100%').padding({ bottom: 4 })
          Text(this.tr('ramadan_jummah_tul_widah_desc'))
            .fontSize(11).fontColor(this.colors.textMuted)
            .lineHeight(16).width('100%')
        }

        Divider().color(this.colors.borderSoft).margin({ top: 14, bottom: 12 })
        Row() {
          if (this.isExportingRamadan) {
            LoadingProgress().width(18).height(18).color(this.colors.accentGold).margin({ right: 8 })
            Text(L.get('export_saving')).fontSize(12).fontColor(this.colors.textMuted)
          } else {
            Text('🖨️').fontSize(16).margin({ right: 8 })
            Text(L.get('export_ramadan_timetable'))
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.colors.accentGold)
          }
        }
        .width('100%')
        .padding({ top: 8, bottom: 8 })
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.colors.tintSoft)
        .borderRadius(10)
        .border({ width: 1, color: this.colors.borderSoft })
        .onClick(() => {
          this.handleExportRamadan();
        })

      } // end Column
      .width('100%')
      .padding(18)
      .backgroundColor(this.colors.cardDark)
      .borderRadius(Theme.radiusLarge)
      .border({ width: 1, color: this.colors.borderSoft })
      .shadow({
        radius: 12,
        color: this.colors.shadowCard,
        offsetX: 0,
        offsetY: 4
      })
      .margin({ bottom: 14 })
    }
  }

  @Builder
  RamadanInProgress() {
    Column() {
      Row() {
        Text(this.tr('ramadan_day_of'))
          .fontSize(12).fontColor(this.colors.textMuted).margin({ right: 4 })
        Text(`${this.ramadanInfo!.currentDayNumber}`)
          .fontSize(32).fontWeight(FontWeight.Bold)
          .fontColor(this.colors.accentGold)
        Text(` ${this.tr('ramadan_day_of_suffix')}`)
          .fontSize(12).fontColor(this.colors.textMuted)
          .margin({ left: 6, bottom: 4 })
        Blank()
      }
      .width('100%').alignItems(VerticalAlign.Bottom)

      Row() {
        Row()
          .width(`${(this.ramadanInfo!.currentDayNumber / this.ramadanInfo!.totalDays) * 100}%`)
          .height(6).backgroundColor(this.colors.accentGold).borderRadius(3)
      }
      .width('100%')
      .height(6)
      .backgroundColor(this.colors.tintMedium)
      .borderRadius(3)
      .margin({ top: 10 })

      Row() {
        Text(`${this.ramadanInfo!.currentDayNumber} / ${this.ramadanInfo!.totalDays}`)
          .fontSize(10).fontColor(this.colors.textMuted).layoutWeight(1)
        if (this.currentAshra() !== null) {
          Text(this.tr(this.currentAshra()!.nameKey))
            .fontSize(10).fontColor(this.colors.accentGold)
            .fontWeight(FontWeight.Medium)
        }
      }
      .width('100%').margin({ top: 6 })
    }
    .width('100%')
  }

  @Builder
  RamadanCountdown() {
    Row() {
      Column() {
        Text(`${this.ramadanInfo!.daysUntilStart}`)
          .fontSize(38).fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textOnAccent)
        Text(this.tr('home_days'))
          .fontSize(11).fontWeight(FontWeight.Medium)
          .fontColor(this.colors.textOnAccent).opacity(0.9)
      }
      .width(84)
      .height(84)
      .backgroundColor(this.colors.accentGold)
      .borderRadius(18)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Column() {
        Text(this.tr('ramadan_days_until'))
          .fontSize(14).fontColor(this.colors.textWhite)
          .fontWeight(FontWeight.Medium).width('100%')
        Text(RamadanHelper.formatLong(
          this.ramadanInfo!.fastingStart, this.currentLanguage))
          .fontSize(12).fontColor(this.colors.accentGold)
          .margin({ top: 6 }).width('100%')
      }
      .layoutWeight(1).margin({ left: 16 }).alignItems(HorizontalAlign.Start)
    }
    .width('100%').alignItems(VerticalAlign.Center)
  }

  @Builder
  TodayProgressCard() {
    Column() {
      Row() {
        Text('🕌').fontSize(14).margin({ right: 8 })
        Text(this.tr('home_today_progress'))
          .fontSize(12)
          .fontColor(this.colors.textMuted)
          .fontWeight(FontWeight.Bold)
          .letterSpacing(1.2)
          .layoutWeight(1)
        Row() {
          Text(this.tr('details_view'))
            .fontSize(11).fontColor(this.colors.accentGold)
            .fontWeight(FontWeight.Medium)
          Text('›').fontSize(14).fontColor(this.colors.accentGold)
            .margin({ left: 2 })
        }
        .onClick(() => {
          router.pushUrl({ url: 'pages/PrayerDetailsPage' })
            .catch((e: Error) =>
            console.error('Navigation failed:', JSON.stringify(e)));
        })
      }
      .width('100%').padding({ bottom: 14 })

      Row() {
        Column() {
          Row() {
            Text(`${this.prayerProgress.todayCompleted}`)
              .fontSize(52).fontWeight(FontWeight.Bold)
              .fontColor(this.prayerProgress.todayCompleted === 5
                ? this.colors.accentGoldLight : this.colors.textWhite)
            Text(` / ${this.prayerProgress.todayTotal}`)
              .fontSize(22).fontColor(this.colors.textMuted)
              .margin({ left: 4, bottom: 8 })
          }
          .alignItems(VerticalAlign.Bottom)

          Text(this.tr('home_prayers_completed'))
            .fontSize(12).fontColor(this.colors.textMuted).margin({ top: -2 })
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        Stack() {
          Circle()
            .width(64)
            .height(64)
            .fill(Color.Transparent)
            .stroke(this.colors.tintMedium)
            .strokeWidth(6)
          Circle()
            .width(64)
            .height(64)
            .fill(Color.Transparent)
            .stroke(this.colors.accentGold)
            .strokeWidth(6)
            .strokeDashArray([this.prayerProgress.todayCompleted * 40.2, 500])
            .strokeLineCap(LineCapStyle.Round)
            .rotate({ angle: -90 })
          Text(`${Math.round(this.prayerProgress.todayCompleted / 5 * 100)}%`)
            .fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
        }
        .width(64).height(64)
      }
      .width('100%')

      Row({ space: 8 }) {
        this.FajrDot()
        this.DhuhrDot()
        this.AsrDot()
        this.MaghribDot()
        this.IshaDot()
      }
      .width('100%').margin({ top: 18 })
    }
    .width('100%')
    .padding(18)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(Theme.radiusLarge)
    .border({ width: 1, color: this.colors.borderSoft })
    .shadow({
      radius: 12,
      color: this.colors.shadowCard,
      offsetX: 0,
      offsetY: 4
    })
    .margin({ bottom: 14 })
  }

  @Builder
  FajrDot() {
    Column() {
      Stack() {
        Circle()
          .width(20)
          .height(20)
          .fill(this.prayerProgress.todayFajr
            ? this.colors.accentGold : Color.Transparent)
          .stroke(this.prayerProgress.todayFajr
            ? this.colors.accentGold : this.colors.borderStrong)
          .strokeWidth(2)
      }
      .width(20).height(20)

      Text(this.tr('prayer_fajr'))
        .fontSize(9)
        .fontColor(this.prayerProgress.todayFajr
          ? this.colors.accentGold : this.colors.textMuted)
        .margin({ top: 6 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1).alignItems(HorizontalAlign.Center)
  }

  @Builder
  DhuhrDot() {
    Column() {
      Stack() {
        Circle()
          .width(20)
          .height(20)
          .fill(this.prayerProgress.todayDhuhr
            ? this.colors.accentGold : Color.Transparent)
          .stroke(this.prayerProgress.todayDhuhr
            ? this.colors.accentGold : this.colors.borderStrong)
          .strokeWidth(2)
      }
      .width(20).height(20)

      Text(this.tr('prayer_dhuhr'))
        .fontSize(9)
        .fontColor(this.prayerProgress.todayDhuhr
          ? this.colors.accentGold : this.colors.textMuted)
        .margin({ top: 6 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1).alignItems(HorizontalAlign.Center)
  }

  @Builder
  AsrDot() {
    Column() {
      Stack() {
        Circle()
          .width(20)
          .height(20)
          .fill(this.prayerProgress.todayAsr
            ? this.colors.accentGold : Color.Transparent)
          .stroke(this.prayerProgress.todayAsr
            ? this.colors.accentGold : this.colors.borderStrong)
          .strokeWidth(2)
      }
      .width(20).height(20)

      Text(this.tr('prayer_asr'))
        .fontSize(9)
        .fontColor(this.prayerProgress.todayAsr
          ? this.colors.accentGold : this.colors.textMuted)
        .margin({ top: 6 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1).alignItems(HorizontalAlign.Center)
  }

  @Builder
  MaghribDot() {
    Column() {
      Stack() {
        Circle()
          .width(20)
          .height(20)
          .fill(this.prayerProgress.todayMaghrib
            ? this.colors.accentGold : Color.Transparent)
          .stroke(this.prayerProgress.todayMaghrib
            ? this.colors.accentGold : this.colors.borderStrong)
          .strokeWidth(2)
      }
      .width(20).height(20)

      Text(this.tr('prayer_maghrib'))
        .fontSize(9)
        .fontColor(this.prayerProgress.todayMaghrib
          ? this.colors.accentGold : this.colors.textMuted)
        .margin({ top: 6 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1).alignItems(HorizontalAlign.Center)
  }

  @Builder
  IshaDot() {
    Column() {
      Stack() {
        Circle()
          .width(20)
          .height(20)
          .fill(this.prayerProgress.todayIsha
            ? this.colors.accentGold : Color.Transparent)
          .stroke(this.prayerProgress.todayIsha
            ? this.colors.accentGold : this.colors.borderStrong)
          .strokeWidth(2)
      }
      .width(20).height(20)

      Text(this.tr('prayer_isha'))
        .fontSize(9)
        .fontColor(this.prayerProgress.todayIsha
          ? this.colors.accentGold : this.colors.textMuted)
        .margin({ top: 6 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1).alignItems(HorizontalAlign.Center)
  }

  @Builder
  MonthDayCellView(cell: MonthDayCell) {
    Column() {
      Text(`${cell.dayOfMonth}`)
        .fontSize(12)
        .fontWeight(cell.isToday ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.cellTextColor(cell))
        .opacity(cell.isFuture ? 0.45 : 1.0)
    }
    .layoutWeight(1)
    .height(32)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.cellBg(cell))
    .borderRadius(8)
    .border({
      width: this.cellBorderWidth(cell),
      color: this.cellBorderColor(cell)
    })
    .margin({ left: 2, right: 2 })
  }

  @Builder
  TasbihCard() {
    Column() {
      Row() {
        Text('📿').fontSize(14).margin({ right: 8 })
        Text(this.tr('home_tasbih'))
          .fontSize(12)
          .fontColor(this.colors.textMuted)
          .fontWeight(FontWeight.Bold)
          .letterSpacing(1.2)
          .layoutWeight(1)
        Row() {
          Text(this.tr('details_view'))
            .fontSize(11).fontColor(this.colors.accentGold)
            .fontWeight(FontWeight.Medium)
          Text('›').fontSize(14).fontColor(this.colors.accentGold)
            .margin({ left: 2 })
        }
        .onClick(() => {
          router.pushUrl({ url: 'pages/TasbihDetailsPage' })
            .catch((e: Error) =>
            console.error('Navigation failed:', JSON.stringify(e)));
        })
      }
      .width('100%').padding({ bottom: 14 })

      // ---- Today's progress ----
      Row() {
        Column() {
          Row() {
            Text(`${this.tasbihToday.dhikrsCompleted}`)
              .fontSize(42).fontWeight(FontWeight.Bold)
              .fontColor(this.tasbihToday.percent === 100
                ? this.colors.accentGoldLight : this.colors.textWhite)
            Text(` / ${this.tasbihToday.dhikrsTotal}`)
              .fontSize(18).fontColor(this.colors.textMuted)
              .margin({ left: 4, bottom: 8 })
          }
          .alignItems(VerticalAlign.Bottom)

          Text(this.tr('details_tasbih_summary_dhikrs'))
            .fontSize(12).fontColor(this.colors.textMuted)
            .margin({ top: -4 })
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        Stack() {
          Circle()
            .width(64)
            .height(64)
            .fill(Color.Transparent)
            .stroke(this.colors.tintMedium)
            .strokeWidth(6)
          Circle()
            .width(64)
            .height(64)
            .fill(Color.Transparent)
            .stroke(this.colors.accentGold)
            .strokeWidth(6)
            .strokeDashArray([this.tasbihToday.percent / 100 * 201, 500])
            .strokeLineCap(LineCapStyle.Round)
            .rotate({ angle: -90 })
          Text(`${this.tasbihToday.percent}%`)
            .fontSize(13).fontWeight(FontWeight.Bold)
            .fontColor(this.colors.textWhite)
        }
        .width(64).height(64)
      }
      .width('100%')

      // ---- Progress bar ----
      Row() {
        Row()
          .width(`${this.tasbihToday.percent}%`)
          .height(6)
          .backgroundColor(this.colors.accentGold)
          .borderRadius(3)
      }
      .width('100%')
      .height(6)
      .backgroundColor(this.colors.tintMedium)
      .borderRadius(3)
      .margin({ top: 16 })

      // ---- Summary row ----
      Row() {
        Column() {
          Text(`${this.tasbihToday.totalTasbihs}`)
            .fontSize(18).fontWeight(FontWeight.Bold)
            .fontColor(this.colors.textWhite)
          Text(this.tr('details_tasbih_summary_tasbihs'))
            .fontSize(10).fontColor(this.colors.textMuted).margin({ top: 2 })
        }
        .layoutWeight(1).alignItems(HorizontalAlign.Start)

        Divider().vertical(true).height(32).color(this.colors.borderSoft)

        Column() {
          Text(`${this.tasbihToday.lifetimeCount}`)
            .fontSize(18).fontWeight(FontWeight.Bold)
            .fontColor(this.colors.accentGold)
          Text(this.tr('details_tasbih_summary_lifetime'))
            .fontSize(10).fontColor(this.colors.textMuted).margin({ top: 2 })
        }
        .padding({ left: 16 })
        .layoutWeight(1).alignItems(HorizontalAlign.Start)
      }
      .width('100%').margin({ top: 14 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(18)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(Theme.radiusLarge)
    .border({ width: 1, color: this.colors.borderSoft })
    .shadow({
      radius: 12,
      color: this.colors.shadowCard,
      offsetX: 0,
      offsetY: 4
    })
    .margin({ bottom: 14 })
  }
}