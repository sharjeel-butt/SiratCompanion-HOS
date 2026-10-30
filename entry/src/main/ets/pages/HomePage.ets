// entry/src/main/ets/pages/HomePage.ets

import { mediaquery, router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { Theme, ThemeColors, ThemeMode, ThemePreset } from '../common/Theme';
import { PageTheme } from '../common/PageTheme';
import { AppLogger } from '../helper/AppLogger';
import { PdfExportHelper } from '../utils/PdfExportHelper';
import { HijriEngineResolver } from '../hijricalendar/HijriEngineResolver';
import { DuaService } from '../helper/DuaService';
import { CompleteDua } from '../models/DuaModels';
import { CustomEvent } from '../models/CustomEventModels';
import { CustomEventStorage } from '../helper/CustomEventStorage';
import { CustomEventNotifier } from '../helper/CustomEventNotifier';
import {
  STORAGE_KEY_APP_FOREGROUND_TICK,
  STORAGE_KEY_APP_THEME,
  STORAGE_KEY_AUTO_SHOW_RAMADAN_VIEW,
  STORAGE_KEY_BREAKPOINT,
  STORAGE_KEY_CALC_SETTINGS_VERSION,
  STORAGE_KEY_CUSTOM_EVENTS_VERSION,
  STORAGE_KEY_EVENT_SETTINGS_VERSION,
  STORAGE_KEY_HIJRI_CALENDAR_TYPE,
  STORAGE_KEY_HIJRI_CALENDAR_VERSION,
  STORAGE_KEY_HIJRI_OFFSET,
  STORAGE_KEY_LANGUAGE,
  STORAGE_KEY_LOCATION_VERSION,
  STORAGE_KEY_PRAYER_STATE_VERSION,
  STORAGE_KEY_RAMADAN_STATE_VERSION,
  STORAGE_KEY_SETTINGS_INITIAL_CATEGORY,
  STORAGE_KEY_SHOW_ISLAMIC_EVENTS,
  STORAGE_KEY_TASBIH_STATE_VERSION,
  STORAGE_KEY_THEME_MODE,
  STORAGE_KEY_TIME_FORMAT
} from '../common/StorageKeys';
import { RamadanStorage } from '../helper/RamadanStorage';
import { EidInfo, FastingStatus, QadaSummary } from '../models/RamadanModels';
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
import { Dhikr, Tasbih } from '../tasbih/TasbihModels';
import { PageHeader } from '../components/PageHeader';
import { DuaCard } from '../components/DuaCard';
import { RamadanAshra, RamadanHelper, RamadanInfo } from '../helper/RamadanHelper';
import { Breakpoints } from '../common/Breakpoints';
import { AdvancedCalcSettings, DEFAULT_ADVANCED_CALC } from '../models/AdvancedCalcModels';
import { HijriCalendarType } from '../hijricalendar/HijriCalendarType';
import { EventPerspectiveNotifier } from '../utils/EventPerspectiveNotifier';
import { TypographyHelper } from '../helper/TypographyHelper';
import { HijriCalendarHelper } from '../hijricalendar/HijriCalendarHelper';

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

export interface DayPrayerPreview {
  dateLabel: string;
  hijriLabel: string;
  fajr: string;
  dhuhr: string;
  asr: string;
  maghrib: string;
  isha: string;
}

export interface UpcomingCustomEvent {
  ev: CustomEvent;
  date: Date;
}

export interface BoundTasbihRowData {
  tasbih: Tasbih;
  prayerId: string;
  completed: boolean;
  firstPendingDhikrIndex: number;
  currentCount: number;
  targetCount: number;
}

export interface PrayerGroupData {
  prayerId: string;
  doneCount: number;
  totalCount: number;
  rows: BoundTasbihRowData[];
}

@Component
export struct HomePage {

  @StorageLink(STORAGE_KEY_THEME_MODE)
  @Watch('onThemeModeChanged')
  themeMode: string = ThemeMode.SYSTEM;
  @StorageLink(STORAGE_KEY_PRAYER_STATE_VERSION)
  @Watch('onPrayerStateChanged')
  prayerStateVersion: number = 0;
  @StorageLink(STORAGE_KEY_HIJRI_CALENDAR_VERSION)
  @Watch('onHijriCalendarVersionChanged')
  calendarVersion: number = 0;
  @StorageLink(STORAGE_KEY_CUSTOM_EVENTS_VERSION)
  @Watch('onCustomEventsVersionChanged')
  customEventsVersion: number = 0;

  @StorageLink(STORAGE_KEY_LOCATION_VERSION)
  @Watch('onLocationVersionChanged')
  locationVersion: number = 0;
  @StorageLink(STORAGE_KEY_EVENT_SETTINGS_VERSION)
  @Watch('onEventSettingsVersionChanged')
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
  @StorageLink(STORAGE_KEY_RAMADAN_STATE_VERSION)
  @Watch('onRamadanStateVersionChanged')
  ramadanStateVersion: number = 0;

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
  @State private todayFastingStatus: FastingStatus = FastingStatus.UNMARKED;
  @State private showLaylatNote: boolean = false;
  @State private dailyDuas: CompleteDua[] = [];
  @State private iftarDua: CompleteDua | null = null;
  @State private suhoorDua: CompleteDua | null = null;

  @State locationMode: LocationMode = LocationMode.GPS;
  @State private upcomingCustomEvents: UpcomingCustomEvent[] = [];
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
  @State private next3Days: DayPrayerPreview[] = [];
  // ---- Qada (Home banner) ----
  @State private qadaSummary: QadaSummary | null = null;

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
  @State upcomingEvents: UpcomingImportantDate[] = [];
  @State private ramadanInfo: RamadanInfo | null = null;
  @State private eidInfo: EidInfo | null = null;

  @State private todayImsakTime: string = '--:--';
  @State private todayMaghribTime: string = '--:--';
  @State private fastingWindowIsPreview: boolean = false;
  @State private countdownTarget: string = '';
  @State private countdownDisplay: string = '';
  @State private countdownHeld: boolean = false;
  @State private isFriday: boolean = false;
  @State private currentLanguage: string = 'en';
  @State private isRefreshing: boolean = false;
  @State private boundTasbihs: Tasbih[] = [];

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
  private countdownTimerId: number = -1;



  private onShowIslamicEventsChanged(): void {
    // Re-render is handled by the @StorageLink.
  }

  private onTasbihStateChanged(): void {
    this.refreshTasbihData();
  }

  private refreshNext3Days(): void {
    if (this.latitude === 0 && this.longitude === 0) {
      this.next3Days = [];
      return;
    }

    const days: DayPrayerPreview[] = [];
    const months = L.getArray('hijri_months', this.appLanguage);
    // Use the localized short weekday array (kept in sync with
    // the tab bar labels) rather than toLocaleDateString, so the
    // date label goes through the same resource path as the
    // Hijri month. This avoids mixed localization sources.
    const weekdaysShort = L.getArray('days_of_week_short', this.appLanguage);

    for (let i = 0; i < 3; i++) {
      const date = new Date();
      date.setDate(date.getDate() + i);

      try {
        const times = PrayerTimeCalculator.calculateWithDeviceTimezone(
          date, this.latitude, this.longitude, this.calcMethod,
          this.asrRule, this.highLatRule, this.advanced
        );

        const shifted = new Date(date);
        shifted.setDate(shifted.getDate() + this.hijriOffset);
        const h = HijriEngineResolver.current().toHijri(shifted);

        let hijriStr = '';
        if (h !== null) {
          hijriStr = `${h.day} ${months[h.month - 1]}`;
        }

        let dateLabel = '';
        if (i === 0) {
          dateLabel = this.tr('today');
        } else if (i === 1) {
          dateLabel = this.tr('home_event_tomorrow');
        } else {
          dateLabel = weekdaysShort[date.getDay()] || '';
        }

        days.push({
          dateLabel: dateLabel,
          hijriLabel: hijriStr,
          fajr: this.dt(PrayerManager.offsetTime(times.fajr, this.offsets.fajr)),
          dhuhr: this.dt(PrayerManager.offsetTime(times.dhuhr, this.offsets.dhuhr)),
          asr: this.dt(PrayerManager.offsetTime(times.asr, this.offsets.asr)),
          maghrib: this.dt(PrayerManager.offsetTime(times.maghrib, this.offsets.maghrib)),
          isha: this.dt(PrayerManager.offsetTime(times.isha, this.offsets.isha))
        });
      } catch (err) {
        console.error('Failed to calc next 3 days', err);
      }
    }
    this.next3Days = days;
  }

  private async loadTrackerState(): Promise<void> {
    if (this.ramadanInfo === null || !this.ramadanInfo.isRamadanNow) {
      this.todayFastingStatus = FastingStatus.UNMARKED;
      this.showLaylatNote = false;
      return;
    }

    // 1. Laylat al-Qadr Check (Odd nights in the last 10 days: 21, 23, 25, 27, 29)
    const day = this.ramadanInfo.currentDayNumber;
    this.showLaylatNote = (day >= 21 && day % 2 !== 0);

    // 2. Load Storage
    const store = await RamadanStorage.load();
    const yearData = store.years.find((y) => y.hijriYear === this.ramadanInfo!.hijriYear);

    if (yearData) {
      this.todayFastingStatus = yearData.days[day - 1]?.status ?? FastingStatus.UNMARKED;
    } else {
      this.todayFastingStatus = FastingStatus.UNMARKED;
    }

  }

  private onEventSettingsVersionChanged(): void {
    this.upcomingEvents = DateHelper.getUpcomingImportantDates(
      this.hijriOffset,
      SettingsHelper.getEventPerspective()
    );
  }

  private onHijriCalendarVersionChanged(): void {
    this.refreshHijriDate();
    this.refreshRamadan();
    this.upcomingEvents = DateHelper.getUpcomingImportantDates(
      this.hijriOffset,
      SettingsHelper.getEventPerspective()
    );
    this.reloadCustomEvents();
  }

  private onAutoShowRamadanViewChanged(): void {
    this.refreshRamadan(); // Instantly re-evaluate visibility
  }

  private async refreshDashboard(): Promise<void> {
    this.prayerProgress = ProgressHelper.getPrayerProgress(this.currentLanguage);
    this.monthProgress = ProgressHelper.getMonthProgress();

    await this.refreshTasbihData();

    // FETCH CONTEXTUAL DUAS
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      const allDuas = await DuaService.loadDuas(ctx, this.currentLanguage);
      this.dailyDuas = DuaService.getDailyDuas(allDuas, this.ramadanInfo, this.isFriday);
      this.iftarDua = allDuas.find((d: CompleteDua) => d.id === 'dua_breaking_the_fast') ?? null;
      this.suhoorDua = allDuas.find((d: CompleteDua) => d.id === 'dua_suhoor') ?? null;
    } catch (e) {
      console.error('Failed to load daily duas', e);
    }

    await this.reloadCustomEvents();

    this.refreshHeader();
    this.refreshFastingWindow();
  }

  private formatEventHijriDate(date: Date): string {
    const shifted = new Date(date);
    shifted.setDate(shifted.getDate() + this.hijriOffset);
    const h = HijriEngineResolver.current().toHijri(shifted);
    if (h === null) {
      return '';
    }
    const months = L.getArray('hijri_months', this.currentLanguage);
    const monthName = months[h.month - 1] || '';
    return `${h.day} ${monthName} ${h.year}`;
  }

  private formatEventDaysUntil(date: Date): string {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const target = new Date(date);
    target.setHours(0, 0, 0, 0);
    const days = Math.round((target.getTime() - today.getTime()) / 86400000);

    if (days < 0) {
      return '';
    }
    if (days === 0) {
      return this.tr('home_event_today');
    }
    if (days === 1) {
      return this.tr('home_event_tomorrow');
    }
    // Arabic dual form implies "two" and takes no numeral.
    if (this.currentLanguage === 'ar' && days === 2) {
      return this.tr('home_days_dual');
    }
    return `${days} ${this.tr('home_days')}`;
  }

  private async reloadCustomEvents(): Promise<void> {
    try {
      const customEvents = await CustomEventStorage.load();
      const upcoming: UpcomingCustomEvent[] = [];

      for (const ev of customEvents) {
        const nextDate = CustomEventNotifier.getNextOccurrence(ev, this.hijriOffset);
        if (nextDate) {
          const entry: UpcomingCustomEvent = {
            ev: ev,
            date: nextDate
          };
          upcoming.push(entry);
        }
      }

      upcoming.sort((a: UpcomingCustomEvent, b: UpcomingCustomEvent): number => {
        return a.date.getTime() - b.date.getTime();
      });

      this.upcomingCustomEvents = upcoming.slice(0, 3);
    } catch (e) {
      const err = e as Error;
      console.error('Failed to load custom events: ' + err.message);
    }
  }

  private async onCustomEventsVersionChanged(): Promise<void> {
    await this.reloadCustomEvents();
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

  private async onRamadanStateVersionChanged(): Promise<void> {
    await this.refreshQadaStatus();
    await this.loadTrackerState();
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
    this.refreshNext3Days();
  }

  private onPrayerStateChanged(): void {
    this.refreshDashboard();
  }

  private async refreshQadaStatus(): Promise<void> {
    try {
      const store = await RamadanStorage.load();
      this.qadaSummary = RamadanStorage.computeQadaSummary(store);
    } catch (err) {
      console.error('[HomePage] refreshQadaStatus failed: ' +
        JSON.stringify(err));
    }
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
    this.refreshNext3Days();
    this.prayerProgress =
      ProgressHelper.getPrayerProgress(this.currentLanguage);
    this.refreshDashboard();
  }

  private async onLocationVersionChanged(): Promise<void> {
    await this.loadSettingsAndLocation();
    await this.refreshDashboard();
  }

  private onEventPerspectiveListener = (): void => {
    this.upcomingEvents = DateHelper.getUpcomingImportantDates(
      this.hijriOffset,
      SettingsHelper.getEventPerspective() // Read directly from SettingsHelper
    );
  };

  private onHijriOffsetChanged(): void {
    this.refreshHijriDate();
    this.refreshRamadan();
    this.onEventPerspectiveListener();
    this.reloadCustomEvents();
  }

  private async onAppForegrounded(): Promise<void> {
    this.isFriday = new Date().getDay() === 5;
    this.refreshHijriDate();
    this.refreshRamadan();
    this.onEventPerspectiveListener();
    await this.loadSettingsAndLocation();
    await this.refreshDashboard();
    this.updateCountdown();
    this.startCountdownTimer();
    this.refreshLocationSilently();
    await this.refreshQadaStatus();
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

    EventPerspectiveNotifier.subscribe(this.onEventPerspectiveListener);
    this.onEventPerspectiveListener();

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
    await this.refreshQadaStatus();
  }

  aboutToDisappear(): void {
    EventPerspectiveNotifier.unsubscribe(this.onEventPerspectiveListener);
    PageTheme.uninstallSystemListener(this.systemDarkListener);
    this.systemDarkListener = null;
    this.stopCountdownTimer();
    EventPerspectiveNotifier.unsubscribe(this.eventPerspectiveListener);
  }

  async onPageShow(): Promise<void> {
    this.isFriday = new Date().getDay() === 5;
    this.currentLanguage = this.appLanguage;
    this.colors = PageTheme.compute(this.themeMode);
    this.refreshHijriDate();
    this.refreshRamadan();
    this.onEventPerspectiveListener();
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
      this.refreshNext3Days();
    } finally {
      this.settingsLoading = false;
      if (this.settingsPending) {
        this.settingsPending = false;
        // Fire-and-forget; the second pass will complete on its own.
        this.loadSettingsAndLocation();
      }
    }
  }

  private async refreshTasbihData(): Promise<void> {
    const loaded = await TasbihStorage.load(TasbihManager.createDefaults());
    this.tasbihToday = ProgressHelper.getTasbihTodayProgress(loaded.tasbihs);
    // Reload bound tasbihs too — the version bump fires when the
    // user increments on the Tasbih tab, and this is what makes the
    // Home card reflect the new counts in real time.
    this.boundTasbihs = loaded.tasbihs.filter(
      (t: Tasbih) => t.boundPrayerIds && t.boundPrayerIds.length > 0
    );
  }

  /**
   * Compute the per-prayer groups shown in the Bound Tasbihs card.
   *
   * Iterates the five canonical prayers in order. Any prayer with
   * at least one bound tasbih produces a group. Within each group,
   * tasbihs are shown in the order they appear in `boundTasbihs`.
   *
   * Completion is read from `liveCounts[prayerId]` — the per-prayer
   * source of truth — rather than `dailyTotal`/`count`, because a
   * tasbih bound to both Fajr and Dhuhr has two independent counts.
   */
  private getPrayerGroups(): PrayerGroupData[] {
    const order: string[] = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
    const groups: PrayerGroupData[] = [];

    for (const prayerId of order) {
      // Collect tasbihs bound to this prayer.
      const boundForPrayer: Tasbih[] = [];
      for (const t of this.boundTasbihs) {
        const bound = t.boundPrayerIds || [];
        if (bound.indexOf(prayerId) >= 0) {
          boundForPrayer.push(t);
        }
      }
      if (boundForPrayer.length === 0) {
        continue;
      }

      const rows: BoundTasbihRowData[] = [];
      let doneCount = 0;

      for (const t of boundForPrayer) {
        const completed = this.isTasbihCompleteForPrayerInView(t, prayerId);
        if (completed) {
          doneCount++;
        }

        const pendingIdx = this.getFirstPendingDhikrIndexForPrayer(t, prayerId);
        const pendingDhikr: Dhikr | null =
          t.dhikrs.length > 0 ? t.dhikrs[pendingIdx] : null;
        const curCount = pendingDhikr
          ? this.getDhikrCountForPrayer(pendingDhikr, prayerId)
          : 0;
        const tgtCount = pendingDhikr ? pendingDhikr.target : 0;

        rows.push({
          tasbih: t,
          prayerId: prayerId,
          completed: completed,
          firstPendingDhikrIndex: pendingIdx,
          currentCount: curCount,
          targetCount: tgtCount
        });
      }

      groups.push({
        prayerId: prayerId,
        doneCount: doneCount,
        totalCount: rows.length,
        rows: rows
      });
    }

    return groups;
  }

  private isTasbihCompleteForPrayerInView(
    t: Tasbih, prayerId: string
  ): boolean {
    if (t.dhikrs.length === 0) {
      return false;
    }
    for (const d of t.dhikrs) {
      const count = this.getDhikrCountForPrayer(d, prayerId);
      if (count < d.target) {
        return false;
      }
    }
    return true;
  }

  private getFirstPendingDhikrIndexForPrayer(
    t: Tasbih, prayerId: string
  ): number {
    for (let i = 0; i < t.dhikrs.length; i++) {
      const d = t.dhikrs[i];
      if (this.getDhikrCountForPrayer(d, prayerId) < d.target) {
        return i;
      }
    }
    return 0;
  }

  private getDhikrCountForPrayer(d: Dhikr, prayerId: string): number {
    if (!d.liveCounts) {
      return 0;
    }
    return d.liveCounts[prayerId] ?? 0;
  }

  private getTasbihDisplayName(t: Tasbih): string {
    return t.nameKey
      ? L.get(t.nameKey, this.currentLanguage)
      : t.name;
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
      this.loadTrackerState(); // Clears tracker states
      return;
    }

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
    this.loadTrackerState(); // Loads tracker states
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

  private isCurrentlyInRamadan(): boolean {
    return this.ramadanInfo !== null && this.ramadanInfo.isRamadanNow;
  }

  private hasOutstandingQada(): boolean {
    return this.qadaSummary !== null && this.qadaSummary.remaining > 0;
  }

  private shouldShowQadaCard(): boolean {
    // Do not show during Eid — the Eid card owns that slot.
    if (this.eidInfo !== null) {
      return false;
    }
    // Do not show during active Ramadan — logging is gated.
    if (this.isCurrentlyInRamadan()) {
      return false;
    }
    // Do not show during the 60-day pre-Ramadan preview window.
    // During this phase the Ramadan countdown card is the primary
    // message ("prepare for Ramadan"); the Qada banner would
    // compete with it. The user can still log make-ups via
    // RamadanDetailsPage (reached from the Ramadan card's
    // "Track Ramadan ›" link). The banner returns after Eid, on
    // day 4 of Shawwal, when logging is valid again.
    if (this.ramadanInfo !== null && !this.ramadanInfo.isRamadanNow) {
      const daysUntil = this.ramadanInfo.daysUntilStart;
      if (daysUntil >= 0 && daysUntil <= 60) {
        return false;
      }
    }
    return this.hasOutstandingQada();
  }

  private currentDuaEntry(): CompleteDua | null {
    if (this.countdownTarget === 'maghrib') {
      return this.iftarDua;
    }
    if (this.countdownTarget === 'imsak') {
      return this.suhoorDua;
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
      this.onEventPerspectiveListener();
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
        const error = err as Error;
        if (error.message === 'GPS_OFF') {
          await LocationHelper.showLocationDisabledDialog(this.colors.accentGold);
        } else if (error.message === 'PERMISSION_DENIED') {
          await LocationHelper.showPermissionDeniedDialog(this.colors.accentGold);
        }
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
          isRamadan: this.ramadanInfo !== null && this.ramadanInfo.isRamadanNow,
          fastingEndTime: this.todayMaghribTime,
          onOpenLocationSettings: () => {
            this.navigateToLocationSettings();
          },
          onOpenSettings: () => {
            this.navigateToSettings();
          },
          onNavigateToTasbih: (tasbihId: string, dhikrIndex: number, prayerId: string) => {
            AppStorage.setOrCreate('nav_target_tasbih', tasbihId);
            AppStorage.setOrCreate('nav_target_dhikr', dhikrIndex);
            AppStorage.setOrCreate('nav_target_prayer', prayerId);
            AppStorage.setOrCreate('nav_target_tab', 'tasbih');
          }
        })

        Refresh({ refreshing: $$this.isRefreshing }) {
          Scroll() {
            Column() {
              if (this.isTablet()) {
                Row({ space: 16 }) {
                  Column() {
                    if (this.isFriday) {
                      Text(this.tr('jummah_mubarak'))
                        .fontSize(15)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(this.colors.accentGold)
                        .width('100%')
                        .textAlign(TextAlign.Center)
                        .margin({ top: 8, bottom: 12 })
                    }
                    if (this.showIslamicEvents) {
                      this.CountdownCard()
                    }
                    this.LiveCountdownBanner()
                    if (this.eidInfo !== null) {
                      this.EidCard()
                    } else if (this.ramadanInfo !== null) {
                      this.RamadanCard()
                    }
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)

                  Column() {
                    this.DuasCard()
                    // --- NEW: Bound Tasbihs Card ---
                    this.BoundTasbihsCard()
                    this.CustomEventsCard()
                    this.Next3DaysPreview()
                    this.TodayProgressCard()
                    // ---- Qada (persistent obligation — bottom of column) ----
                    if (this.shouldShowQadaCard()) {
                      this.QadaHomeBanner()
                    }
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
                  if (new Date().getDay() === 5) {
                    Text(this.tr('jummah_mubarak'))
                      .fontSize(15)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(this.colors.accentGold)
                      .width('100%')
                      .textAlign(TextAlign.Center)
                      .margin({ top: 8, bottom: 12 })
                  }
                  // ---- Next Event ----
                  if (this.showIslamicEvents) {
                    this.CountdownCard()
                  }
                  this.LiveCountdownBanner()
                  if (this.eidInfo !== null) {
                    this.EidCard()
                  } else if (this.ramadanInfo !== null) {
                    this.RamadanCard()
                  }
                  this.DuasCard()
                  // --- NEW: Bound Tasbihs Card ---
                  this.BoundTasbihsCard()
                  this.CustomEventsCard()
                  this.Next3DaysPreview()
                  // ---- Prayers ----
                  this.TodayProgressCard()

                  // ---- Qada (persistent obligation — bottom of page) ----
                  if (this.shouldShowQadaCard()) {
                    this.QadaHomeBanner()
                  }
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

  // ============================================================
  // QADA HOME BANNER
  // ============================================================
  //
  // A compact single-row reminder shown at the bottom of Home
  // whenever the user has outstanding make-up fasts and is not
  // in a phase where logging is gated (Ramadan / Eid / the
  // 60-day pre-Ramadan preview).
  //
  // Layout:  🔄  15 fasts to make up    [Log]  ›
  //
  //   Tap anywhere except [Log] → navigate to RamadanDetailsPage
  //   Tap [Log]               → open the Qada log sheet

  @Builder
  QadaHomeBanner() {
    if (this.qadaSummary !== null && this.qadaSummary.remaining > 0) {
      Row() {
        Image($r('app.media.ic_refresh'))
          .width(16)
          .height(16)
          .fillColor(this.colors.accentGold)
          .flexShrink(0)
          .margin({ right: this.isRtl() ? 0 : 10, left: this.isRtl() ? 10 : 0 })

        Column() {
          Text(this.tr('section_qada'))
            .fontSize(10)
            .fontColor(this.colors.textMuted)
            .fontWeight(FontWeight.Bold)
            .letterSpacing(1.2)

          Row() {
            Text(this.qadaBannerText())
              .fontSize(13)
              .fontColor(this.colors.textWhite)
              .fontWeight(FontWeight.Medium)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Image($r('app.media.ic_chevron_right'))
              .width(12)
              .height(12)
              .fillColor(this.colors.accentGold)
              .opacity(0.85)
              .margin({ left: this.isRtl() ? 0 : 4, right: this.isRtl() ? 4 : 0 })
              .rotate({ angle: this.isRtl() ? 180 : 0 })
          }
          .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // Compact "Manage ›" hint in place of the old [Log] button
        Image($r('app.media.ic_chevron_right'))
          .width(16)
          .height(16)
          .fillColor(this.colors.accentGold)
          .opacity(0.7)
          .margin({ left: this.isRtl() ? 4 : 8, right: this.isRtl() ? 8 : 4 })
          .rotate({ angle: this.isRtl() ? 180 : 0 })
      }
      .width('100%')
      .padding({
        top: 10,
        bottom: 10,
        left: 16,
        right: 12
      })
      .backgroundColor(this.colors.cardDark)
      .borderRadius(Theme.radiusMedium)
      .border({ width: 1, color: this.colors.borderSoft })
      .shadow({
        radius: 8,
        color: this.colors.shadowCard,
        offsetX: 0,
        offsetY: 2
      })
      .margin({ bottom: 14 })
      // Soft fade-in so the banner does not pop abruptly the
      // moment the Eid card disappears on Shawwal 4.
      .transition(
        TransitionEffect.OPACITY.animation({
          duration: 400,
          curve: Curve.EaseInOut
        })
      )
      .onClick(() => {
        router.pushUrl({ url: 'pages/RamadanDetailsPage' })
          .catch((e: Error) =>
          console.error('Navigation failed:', JSON.stringify(e)));
      })
    }
  }

  /**
   * Compose the banner's main label:
   *   n === 1           → "1 fast to make up"
   *   n === 2, ar       → "صومان للقضاء"  (Arabic dual)
   *   n >= 2, otherwise → "N fasts to make up"
   */
  private qadaBannerText(): string {
    if (this.qadaSummary === null) {
      return '';
    }
    const n = this.qadaSummary.remaining;
    if (n <= 0) {
      return '';
    }
    if (n === 2 && this.currentLanguage === 'ar') {
      return this.tr('qada_banner_dual');
    }
    const word = n === 1
      ? this.tr('qada_banner_singular')
      : this.tr('qada_banner_plural');
    return `${n} ${word}`;
  }

  @Builder
  RamadanExportLayout() {
    Column() {
      // Header
      Row({ space: 12 }) { // <-- Replaced margin({ right: 12 })
        Image($r('app.media.foreground'))
          .syncLoad(true)
          .width(36)
          .height(36)
          .borderRadius(8)
          .flexShrink(0)

        Column() {
          Text(`${L.getArray('hijri_months', this.appLanguage)[8]} ${this.pdfRamadanYear} ${L.get('hijri_year_suffix', this.appLanguage)}`)
            .fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.pdfColors.textWhite)
            .width('100%')

          Text(`${this.pdfRamadanGregSpan} · ${this.currentLocation}`)
            .fontSize(10).fontColor(this.pdfColors.accentGold).margin({ top: 4 })
            .width('100%')
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        Text(L.get('generated_by', this.appLanguage))
          .fontSize(8).fontColor(this.pdfColors.textMuted).alignSelf(ItemAlign.Start)
      }
      .width('100%')
      .padding({ top: 15, bottom: 10, left: 20, right: 20 })
      .backgroundColor(this.pdfColors.cardDark)
      .alignItems(VerticalAlign.Center)

      Row().width('100%').height(3).backgroundColor(this.pdfColors.accentGold)

      // Table Headers
      Row() {
        Text(L.get('export_date', this.appLanguage))
          .layoutWeight(1.8)
          .fontWeight(FontWeight.Bold)
          .fontSize(9)
          .fontColor(this.pdfColors.accentGold)
          .textAlign(this.isRtl() ? TextAlign.End : TextAlign.Start)
        Text(L.get('export_sahur', this.appLanguage))
          .layoutWeight(1)
          .fontWeight(FontWeight.Bold)
          .fontSize(9)
          .fontColor(this.pdfColors.accentGold)
          .textAlign(TextAlign.Center)
        Text(L.get('prayer_fajr', this.appLanguage))
          .layoutWeight(1)
          .fontWeight(FontWeight.Bold)
          .fontSize(9)
          .fontColor(this.pdfColors.accentGold)
          .textAlign(TextAlign.Center)
        Text(L.get('prayer_dhuhr', this.appLanguage))
          .layoutWeight(1)
          .fontWeight(FontWeight.Bold)
          .fontSize(9)
          .fontColor(this.pdfColors.accentGold)
          .textAlign(TextAlign.Center)
        Text(L.get('prayer_asr', this.appLanguage))
          .layoutWeight(1)
          .fontWeight(FontWeight.Bold)
          .fontSize(9)
          .fontColor(this.pdfColors.accentGold)
          .textAlign(TextAlign.Center)
        Text(L.get('export_iftar', this.appLanguage))
          .layoutWeight(1)
          .fontWeight(FontWeight.Bold)
          .fontSize(9)
          .fontColor(this.pdfColors.accentGold)
          .textAlign(TextAlign.Center)
        Text(L.get('prayer_isha', this.appLanguage))
          .layoutWeight(1)
          .fontWeight(FontWeight.Bold)
          .fontSize(9)
          .fontColor(this.pdfColors.accentGold)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .padding({ top: 6, bottom: 6, left: 20, right: 20 })
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
                .width('100%')
                .textAlign(TextAlign.Start) // <-- Forces text to the right in RTL
              Text(row.gregorianDate)
                .fontSize(7)
                .lineHeight(9)
                .fontColor(this.pdfColors.textMuted)
                .margin({ top: 0 })
                .width('100%')
                .textAlign(TextAlign.Start) // <-- Forces text to the right in RTL
            }
            .layoutWeight(1.8)
            .alignItems(HorizontalAlign.Start)
            Text(row.sahur).layoutWeight(1).fontSize(8).fontColor(this.pdfColors.textWhite).textAlign(TextAlign.Center)
            Text(row.fajr).layoutWeight(1).fontSize(8).fontColor(this.pdfColors.textWhite).textAlign(TextAlign.Center)
            Text(row.dhuhr).layoutWeight(1).fontSize(8).fontColor(this.pdfColors.textWhite).textAlign(TextAlign.Center)
            Text(row.asr).layoutWeight(1).fontSize(8).fontColor(this.pdfColors.textWhite).textAlign(TextAlign.Center)
            Text(row.iftar).layoutWeight(1).fontSize(8).fontColor(this.pdfColors.accentGoldLight).textAlign(TextAlign.Center)
            Text(row.isha).layoutWeight(1).fontSize(8).fontColor(this.pdfColors.textWhite).textAlign(TextAlign.Center)
          }
          .width('100%')
          .padding({ top: 2, bottom: 2, left: 20, right: 20 })
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
    .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr) // <-- ADDED
  }

  @Builder
  CountdownCard() {
    if (this.upcomingEvents.length > 0) {
      Column() {
        Row({ space: 8 }) {
          Image($r('app.media.ic_nav_home'))
            .width(16).height(16)
            .fillColor(this.colors.accentGold)
            .flexShrink(0)
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
      .border({
        width: 1,
        color: PageTheme.isDarkFor(this.themeMode)
          ? 'rgba(255, 255, 255, 0.08)'
          : this.colors.borderSoft
      })
      .shadow({
        radius: 16,
        color: PageTheme.isDarkFor(this.themeMode)
          ? 'rgba(0, 0, 0, 0.35)'
          : 'rgba(0, 0, 0, 0.08)',
        offsetX: 0,
        offsetY: 6
      })
      .margin({ bottom: 14 })
    }
  }

  @Builder
  CustomEventsCard() {
    if (this.upcomingCustomEvents.length > 0) {
      Column() {
        // Header (unchanged)
        Row({ space: 8 }) {
          Image($r('app.media.ic_nav_calendar'))
            .width(16).height(16)
            .fillColor(this.colors.accentGold)
            .flexShrink(0)
          Text(this.tr('upcoming_custom_events'))
            .fontSize(12)
            .fontColor(this.colors.textMuted)
            .fontWeight(FontWeight.Bold)
            .letterSpacing(1.2)
            .layoutWeight(1)
        }
        .width('100%').padding({ bottom: 14 })

        // List — UPDATED ForEach type
        Column({ space: 10 }) {
          ForEach(this.upcomingCustomEvents.slice(0, 3), (item: UpcomingCustomEvent) => {
            Row({ space: 12 }) {
              // Date badge (Gregorian — unchanged)
              Column() {
                Text(item.date.toLocaleDateString(this.currentLanguage, { month: 'short' }).toUpperCase())
                  .fontSize(9).fontColor(this.colors.textOnAccent).fontWeight(FontWeight.Bold)
                Text(`${item.date.getDate()}`)
                  .fontSize(16).fontColor(this.colors.textOnAccent).fontWeight(FontWeight.Bold)
              }
              .width(44)
              .height(44)
              .backgroundColor(this.colors.accentGold)
              .borderRadius(8)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .flexShrink(0)

              // Text content — now three rows
              Column() {
                // Title
                Text(item.ev.title)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.colors.textWhite)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%')
                  .textAlign(TextAlign.Start)

                // Hijri date
                Row({ space: 4 }) {
                  Image($r('app.media.ic_ramadan_moon'))
                    .width(10).height(10)
                    .fillColor(this.colors.accentGold)
                    .flexShrink(0)
                  Text(this.formatEventHijriDate(item.date))
                    .fontSize(11)
                    .fontColor(this.colors.accentGold)
                    .fontWeight(FontWeight.Medium)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1)
                    .textAlign(TextAlign.Start)
                }
                .width('100%')
                .margin({ top: 3 })
                .alignItems(VerticalAlign.Center)

                // Days remaining · recurrence (if any)
                Row({ space: 4 }) {
                  Text(this.formatEventDaysUntil(item.date))
                    .fontSize(10)
                    .fontColor(this.colors.textMuted)
                    .maxLines(1)
                  if (item.ev.recurrence && item.ev.recurrence !== 'none') {
                    Text('·').fontSize(10).fontColor(this.colors.textMuted)
                    Text(this.tr('recur_' + item.ev.recurrence))
                      .fontSize(10)
                      .fontColor(this.colors.textMuted)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .layoutWeight(1)
                  }
                }
                .width('100%')
                .margin({ top: 2 })
                .alignItems(VerticalAlign.Center)
              }
              .alignItems(HorizontalAlign.Start).layoutWeight(1)

              Image($r('app.media.ic_chevron_right'))
                .width(12)
                .height(12)
                .fillColor(this.colors.accentGold)
                .opacity(0.6)
                .rotate({ angle: this.isRtl() ? 180 : 0 })
                .flexShrink(0)
            }
            .width('100%')
            .padding(10)
            .backgroundColor(this.colors.tintSubtle)
            .borderRadius(10)
            .onClick(() => {
              const h = HijriCalendarHelper.getHijriDate(item.date, this.hijriOffset);

              // Clear any stale target FIRST so setOrCreate always
              // fires @Watch even when re-tapping the same event
              // while a previous target is still pending (e.g. after
              // a first navigation whose page build was interrupted).
              AppStorage.setOrCreate('nav_target_hijri_year', 0);
              AppStorage.setOrCreate('nav_target_hijri_month', 0);
              AppStorage.setOrCreate('nav_target_hijri_day', 0);

              // Then set the actual target.
              AppStorage.setOrCreate('nav_target_hijri_year', h.year);
              AppStorage.setOrCreate('nav_target_hijri_month', h.month);
              AppStorage.setOrCreate('nav_target_hijri_day', h.day);

              // Tab switch LAST so MainTabs sees a fully-prepared target.
              AppStorage.setOrCreate('nav_target_tab', 'calendar');
            })
          }, (item: UpcomingCustomEvent) => `ce-${item.ev.id}-${item.date.getTime()}`)
        }
        .width('100%')
      }
      .width('100%')
      .padding(18)
      .backgroundColor(this.colors.cardDark)
      .borderRadius(Theme.radiusLarge)
      .border({
        width: 1,
        color: PageTheme.isDarkFor(this.themeMode)
          ? 'rgba(255, 255, 255, 0.08)'
          : this.colors.borderSoft
      })
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
  DuasCard() {
    if (this.dailyDuas.length > 0) {
      Column() {
        // Header
        Row({ space: 8 }) {
          Image($r('app.media.ic_dua'))
            .width(16).height(16)
            .fillColor(this.colors.accentGold)
            .flexShrink(0)
          Text(this.tr('home_duas_title'))
            .fontSize(12)
            .fontColor(this.colors.textMuted)
            .fontWeight(FontWeight.Bold)
            .letterSpacing(1.2)
            .layoutWeight(1)
            .textAlign(TextAlign.Start) // Ensures RTL alignment

          Row({ space: 2 }) {
            Text(this.tr('view_all'))
              .fontSize(11).fontColor(this.colors.accentGold)
              .fontWeight(FontWeight.Medium)
            Image($r('app.media.ic_chevron_right'))
              .width(12).height(12)
              .fillColor(this.colors.accentGold)
              .rotate({ angle: this.isRtl() ? 180 : 0 })
          }
          .flexShrink(0)
          .onClick(() => {
            router.pushUrl({ url: 'pages/DuasPage' })
              .catch((e: Error) => console.error(JSON.stringify(e)));
          })
        }
        .width('100%').padding({ bottom: 14 })

        // List of 3 Duas
        Column({ space: 10 }) {
          ForEach(this.dailyDuas, (dua: CompleteDua) => {
            Row({ space: 12 }) {
              Column() {
                Text(dua.translatedName)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.colors.textWhite)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%')
                  .textAlign(TextAlign.Start)

                Text(dua.translatedText)
                  .fontSize(11)
                  .fontColor(this.colors.textMuted)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: 2 })
                  .width('100%')
                  .textAlign(TextAlign.Start)
              }
              .alignItems(HorizontalAlign.Start).layoutWeight(1)

              Image($r('app.media.ic_chevron_right'))
                .width(12)
                .height(12)
                .fillColor(this.colors.accentGold)
                .opacity(0.6)
                .rotate({ angle: this.isRtl() ? 180 : 0 })
                .flexShrink(0)
            }
            .width('100%')
            .padding(12)
            .backgroundColor(this.colors.tintSubtle)
            .borderRadius(10)
            .onClick(() => {
              // Pass the category to filter the page
              router.pushUrl({
                url: 'pages/DuasPage',
                params: { filterCategory: dua.category }
              }).catch((e: Error) => console.error(JSON.stringify(e)));
            })
          })
        }
        .width('100%')
      }
      .width('100%')
      .padding(18)
      .backgroundColor(this.colors.cardDark)
      .borderRadius(Theme.radiusLarge)
      .border({
        width: 1,
        color: PageTheme.isDarkFor(this.themeMode)
          ? 'rgba(255, 255, 255, 0.08)'
          : this.colors.borderSoft
      })
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
  BoundTasbihsCard() {
    if (this.boundTasbihs.length > 0) {
      Column() {
        // Header — unchanged
        Row({ space: 8 }) {
          Image($r('app.media.ic_nav_tasbih'))
            .width(16).height(16)
            .fillColor(this.colors.accentGold)
            .flexShrink(0)
          Text(this.tr('home_tasbih_tracker'))
            .fontSize(12)
            .fontColor(this.colors.textMuted)
            .fontWeight(FontWeight.Bold)
            .letterSpacing(1.2)
            .layoutWeight(1)

          Row({ space: 2 }) {
            Text(this.tr('view_all'))
              .fontSize(11).fontColor(this.colors.accentGold)
              .fontWeight(FontWeight.Medium)
            Image($r('app.media.ic_chevron_right'))
              .width(12).height(12)
              .fillColor(this.colors.accentGold)
              .rotate({ angle: this.isRtl() ? 180 : 0 })
          }
          .onClick(() => {
            AppStorage.setOrCreate('nav_target_tab', 'tasbih');
          })
        }
        .width('100%').padding({ bottom: 14 })

        // Per-prayer groups. The key includes tasbihStateVersion
        // so ArkUI recreates each group (and its inner rows) when
        // any tasbih changes — this avoids the @Builder-snapshot
        // gotcha where the parameterized builder keeps stale data.
        Column({ space: 10 }) {
          ForEach(this.getPrayerGroups(), (group: PrayerGroupData) => {
            this.PrayerGroupHeader(group)
          }, (group: PrayerGroupData) =>
          `${group.prayerId}-${group.doneCount}-${group.totalCount}-${this.tasbihStateVersion}`)
        }
        .width('100%')
      }
      .width('100%')
      .padding(18)
      .backgroundColor(this.colors.cardDark)
      .borderRadius(Theme.radiusLarge)
      .border({
        width: 1,
        color: PageTheme.isDarkFor(this.themeMode)
          ? 'rgba(255, 255, 255, 0.08)'
          : this.colors.borderSoft
      })
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
  PrayerGroupHeader(group: PrayerGroupData) {
    Column({ space: 6 }) {
      Row({ space: 6 }) {
        Text(this.tr('prayer_' + group.prayerId))
          .fontSize(11)
          .fontColor(this.colors.accentGold)
          .fontWeight(FontWeight.Bold)
          .letterSpacing(0.8)
          .layoutWeight(1)

        if (group.doneCount === group.totalCount) {
          Row({ space: 3 }) {
            Image($r('app.media.ic_check'))
              .width(10).height(10)
              .fillColor(this.colors.accentGold)
              .flexShrink(0)
            Text(`${group.doneCount}/${group.totalCount}`)
              .fontSize(10)
              .fontColor(this.colors.accentGold)
              .fontWeight(FontWeight.Medium)
          }
          .padding({
            left: 6,
            right: 8,
            top: 2,
            bottom: 2
          })
          .backgroundColor(this.colors.tintSoft)
          .borderRadius(8)
        } else {
          Text(`${group.doneCount}/${group.totalCount}`)
            .fontSize(10)
            .fontColor(this.colors.textMuted)
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Column({ space: 2 }) {
        ForEach(group.rows, (row: BoundTasbihRowData) => {
          this.BoundTasbihRowView(row)
        }, (row: BoundTasbihRowData) =>
        `${row.prayerId}-${row.tasbih.id}-${row.completed}-${row.currentCount}`)
      }
      .width('100%')
    }
    .width('100%')
    .padding({
      top: 8,
      bottom: 8,
      left: 8,
      right: 8
    })
    .backgroundColor(this.colors.tintSubtle)
    .borderRadius(10)
  }

  @Builder
  BoundTasbihRowView(row: BoundTasbihRowData) {
    Row({ space: 10 }) {
      Image(row.completed
        ? $r('app.media.ic_check')
        : $r('app.media.ic_nav_tasbih'))
        .width(14)
        .height(14)
        .fillColor(row.completed
          ? this.colors.accentGold
          : this.colors.textMuted)
        .opacity(row.completed ? 1.0 : 0.7)
        .flexShrink(0)

      Column() {
        Text(this.getTasbihDisplayName(row.tasbih))
          .fontSize(13)
          .fontColor(row.completed
            ? this.colors.textMuted
            : this.colors.textWhite)
          .fontWeight(row.completed
            ? FontWeight.Normal
            : FontWeight.Medium)
          .opacity(row.completed ? 0.7 : 1.0)
          .decoration(row.completed
            ? { type: TextDecorationType.LineThrough }
            : { type: TextDecorationType.None })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .textAlign(TextAlign.Start)

        if (!row.completed && row.targetCount > 0) {
          Text(`${row.currentCount}/${row.targetCount}`)
            .fontSize(10)
            .fontColor(this.colors.textMuted)
            .margin({ top: 1 })
            .width('100%')
            .textAlign(TextAlign.Start)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Image($r('app.media.ic_chevron_right'))
        .width(12)
        .height(12)
        .fillColor(this.colors.accentGold)
        .opacity(0.6)
        .rotate({ angle: this.isRtl() ? 180 : 0 })
        .flexShrink(0)
    }
    .width('100%')
    .padding({
      top: 6,
      bottom: 6,
      left: 6,
      right: 4
    })
    .borderRadius(6)
    .onClick(() => {
      // Navigate to this specific tasbih, this specific prayer,
      // and the first dhikr that is still pending for that prayer.
      AppStorage.setOrCreate('nav_target_tasbih', row.tasbih.id);
      AppStorage.setOrCreate('nav_target_dhikr', row.firstPendingDhikrIndex);
      AppStorage.setOrCreate('nav_target_prayer', row.prayerId);
      AppStorage.setOrCreate('nav_target_tab', 'tasbih');
    })
  }

  private getTasbihSubtitle(t: Tasbih): string {
    const prayerId = t.boundPrayerIds![0];
    const prayerName = L.get('prayer_' + prayerId, this.currentLanguage);

    const pending = t.dhikrs.find(d => (d.dailyTotal ?? d.count) < d.target);
    if (pending) {
      const dhikrName = pending.transliterationKey
        ? L.get(pending.transliterationKey, this.currentLanguage)
        : pending.transliteration;
      const total = pending.dailyTotal ?? pending.count;
      const left = pending.target - total;
      return `${prayerName} · ${dhikrName} (${left} left)`;
    }
    return `${prayerName} · ${this.tr('tasbih_status_completed')}`;
  }

  @Builder
  CountdownMainEvent() {
    Row({ space: 16 }) {
      Column() {
        if (this.upcomingEvents[0].daysUntil === 0) {
          Image($r('app.media.ic_celebration'))
            .width(30).height(30)
            .fillColor(this.colors.accentGold)
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
      .flexShrink(0)
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
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  CountdownSecondaryRow(index: number) {
    Row({ space: 8 }) {
      Image($r('app.media.ic_star'))
        .width(14)
        .height(14)
        .fillColor(this.colors.accentGold)
        .opacity(0.75)
        .flexShrink(0)
      Text(this.translateUpcomingEventName(this.upcomingEvents[index]))
        .fontSize(13)
        .fontColor(this.colors.textWhite)
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
      Text(this.countdownShortLabel(this.upcomingEvents[index].daysUntil))
        .fontSize(11).fontColor(this.colors.accentGold)
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
    // Arabic dual form ("يومان") implies "two" and takes no numeral.
    if (this.currentLanguage === 'ar' && days === 2) {
      return this.tr('home_days_dual');
    }
    return `${days} ${this.tr('home_days')}`;
  }

  @Builder
  LiveCountdownBanner() {
    if (this.countdownTarget !== '') {
      Column() {
        Row({ space: 14 }) {
          Image(this.countdownTarget === 'maghrib' ? $r('app.media.ic_sunset') : $r('app.media.ic_sunrise'))
            .width(32).height(32)
            .fillColor(this.colors.accentGold)

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
        // Header Row
        Row({ space: 8 }) {
          Image($r('app.media.ic_ramadan_moon'))
            .width(16).height(16)
            .fillColor(this.colors.accentGold)
            .flexShrink(0)
          Text(this.tr('ramadan_card_title'))
            .fontSize(12)
            .fontColor(this.colors.textMuted)
            .fontWeight(FontWeight.Bold)
            .letterSpacing(1.5)
          Text(`  ${this.ramadanInfo!.hijriYear} ${this.tr('hijri_year_suffix')}`)
            .fontSize(12)
            .fontColor(this.colors.accentGold)
            .fontWeight(FontWeight.Medium)
          Blank()

          // Duas Quick Link
          Row({ space: 4 }) {
            Text(this.tr('duas_link'))
              .fontSize(11).fontColor(this.colors.accentGold)
              .fontWeight(FontWeight.Medium)
            Image($r('app.media.ic_chevron_right'))
              .width(12).height(12)
              .fillColor(this.colors.accentGold)
              .rotate({ angle: this.isRtl() ? 180 : 0 })
          }
          .onClick(() => {
            router.pushUrl({
              url: 'pages/RamadanDetailsPage',
              params: { scrollToDuas: true }
            }).catch((e: Error) => console.error(JSON.stringify(e)));
          })
          .margin({ right: this.isRtl() ? 0 : 8, left: this.isRtl() ? 8 : 0 })

          // Track Link
          Row({ space: 4 }) {
            Text(this.tr('track_ramadan'))
              .fontSize(11).fontColor(this.colors.accentGold)
              .fontWeight(FontWeight.Medium)
            Image($r('app.media.ic_chevron_right'))
              .width(12).height(12)
              .fillColor(this.colors.accentGold)
              .rotate({ angle: this.isRtl() ? 180 : 0 })
          }
          .onClick(() => {
            router.pushUrl({ url: 'pages/RamadanDetailsPage' })
              .catch((e: Error) => console.error(JSON.stringify(e)));
          })
        }
        .width('100%').padding({ bottom: 14 })

        // 1. Laylat al-Qadr Inline Note
        if (this.showLaylatNote) {
          Row({ space: 8 }) {
            Image($r('app.media.ic_star'))
              .width(14).height(14)
              .fillColor(this.colors.accentGold)
              .flexShrink(0)
            Text(this.tr('ramadan_laylat_today'))
              .fontSize(12).fontColor(this.colors.accentGold).fontWeight(FontWeight.Bold)
          }
          .width('100%')
          .padding({
            top: 8,
            bottom: 8,
            left: 12,
            right: 12
          })
          .backgroundColor(this.colors.tintSoft)
          .borderRadius(8)
          .margin({ bottom: 12 })
        }

        if (this.ramadanInfo!.isRamadanNow) {
          this.RamadanInProgress()
        } else {
          this.RamadanCountdown()
        }

        Divider().color(this.colors.borderSoft).margin({ top: 14, bottom: 12 })

        // ---- Export Ramadan timetable button (existing) ----
        Row() {
          if (this.isExportingRamadan) {
            LoadingProgress().width(18).height(18).color(this.colors.accentGold).margin({ right: 8 })
            Text(L.get('export_saving')).fontSize(12).fontColor(this.colors.textMuted)
          } else {
            Image($r('app.media.ic_printer'))
              .width(16)
              .height(16)
              .fillColor(this.colors.accentGold)
              .flexShrink(0)
              .margin({ right: this.isRtl() ? 0 : 8, left: this.isRtl() ? 8 : 0 })
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
      .border({
        width: 1,
        color: PageTheme.isDarkFor(this.themeMode)
          ? 'rgba(255, 255, 255, 0.08)'
          : this.colors.borderSoft
      })
      .shadow({
        radius: 16,
        color: PageTheme.isDarkFor(this.themeMode)
          ? 'rgba(0, 0, 0, 0.35)'
          : 'rgba(0, 0, 0, 0.08)',
        offsetX: 0,
        offsetY: 6
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
          .margin({
            left: this.isRtl() ? 4 : 0,
            right: this.isRtl() ? 0 : 4
          })
        Text(` ${this.tr('ramadan_day_of_suffix')}`)
          .fontSize(12).fontColor(this.colors.textMuted)
          .margin({
            left: this.isRtl() ? 0 : 6,
            right: this.isRtl() ? 6 : 0,
            bottom: 4
          })
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
    Row({ space: 16 }) {
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
      .flexShrink(0) // ADD THIS
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
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%').alignItems(VerticalAlign.Center)
  }

  @Builder
  Next3DaysPreview() {
    if (this.next3Days.length > 0) {
      Column() {
        Row({ space: 8 }) {
          Image($r('app.media.ic_nav_calendar'))
            .width(16).height(16)
            .fillColor(this.colors.accentGold)
            .flexShrink(0)
          Text(this.tr('next_3_days'))
            .fontSize(12)
            .fontColor(this.colors.textMuted)
            .fontWeight(FontWeight.Bold)
            .letterSpacing(1.5)
            .layoutWeight(1)
        }
        .width('100%').padding({ bottom: 14 })

        Row({ space: 8 }) {
          ForEach(this.next3Days, (day: DayPrayerPreview) => {
            Column() {
              // Day Header
              Text(day.dateLabel)
                .fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
              Text(day.hijriLabel)
                .fontSize(9)
                .fontColor(this.colors.accentGold)
                .margin({ top: 2, bottom: 4 })
                .width('100%')
                .textAlign(TextAlign.Center)
                .maxLines(2)

              Divider().color(this.colors.borderSoft).margin({ top: 8, bottom: 8 })

              // Compact 5-Prayer List
              Row() {
                Text(this.tr('prayer_fajr')).fontSize(9).fontColor(this.colors.textMuted)
                Blank()
                Text(day.fajr).fontSize(9).fontColor(this.colors.textWhite).fontFeature('"tnum" 1')
              }.width('100%').margin({ bottom: 4 })

              Row() {
                Text(this.tr('prayer_dhuhr')).fontSize(9).fontColor(this.colors.textMuted)
                Blank()
                Text(day.dhuhr).fontSize(9).fontColor(this.colors.textWhite)
              }.width('100%').margin({ bottom: 4 })

              Row() {
                Text(this.tr('prayer_asr')).fontSize(9).fontColor(this.colors.textMuted)
                Blank()
                Text(day.asr).fontSize(9).fontColor(this.colors.textWhite)
              }.width('100%').margin({ bottom: 4 })

              Row() {
                Text(this.tr('prayer_maghrib')).fontSize(9).fontColor(this.colors.textMuted)
                Blank()
                Text(day.maghrib).fontSize(9).fontColor(this.colors.textWhite)
              }.width('100%').margin({ bottom: 4 })

              Row() {
                Text(this.tr('prayer_isha')).fontSize(9).fontColor(this.colors.textMuted)
                Blank()
                Text(day.isha).fontSize(9).fontColor(this.colors.textWhite)
              }.width('100%')

            }
            .layoutWeight(1)
            .padding(10)
            .backgroundColor(this.colors.tintSubtle)
            .borderRadius(10)
            .border({
              width: 1,
              color: PageTheme.isDarkFor(this.themeMode)
                ? 'rgba(255, 255, 255, 0.06)' // Simulates light catching the top edge
                : 'rgba(0, 0, 0, 0.04)'
            })
          })
        }
        .width('100%')
      }
      .width('100%')
      .padding(18)
      .backgroundColor(this.colors.cardDark)
      .borderRadius(Theme.radiusLarge)
      .border({
        width: 1,
        color: PageTheme.isDarkFor(this.themeMode)
          ? 'rgba(255, 255, 255, 0.08)'
          : this.colors.borderSoft
      })
      .shadow({
        radius: 16,
        color: PageTheme.isDarkFor(this.themeMode)
          ? 'rgba(0, 0, 0, 0.35)'
          : 'rgba(0, 0, 0, 0.08)',
        offsetX: 0,
        offsetY: 6
      })
      .margin({ bottom: 14 })
    }
  }

  @Builder
  TodayProgressCard() {
    Column() {
      Row({ space: 8 }) {
        Image($r('app.media.ic_nav_mosque'))
          .width(16).height(16)
          .fillColor(this.colors.accentGold)
          .flexShrink(0)
        Text(this.tr('home_today_progress'))
          .fontFamily(TypographyHelper.getFont(this.currentLanguage, true))
          .fontSize(12)
          .fontColor(this.colors.textMuted)
          .fontWeight(FontWeight.Bold)
          .letterSpacing(1.5)
          .layoutWeight(1)
        Row({ space: 2 }) {
          Text(this.tr('details_view'))
            .fontSize(11).fontColor(this.colors.accentGold)
            .fontWeight(FontWeight.Medium)
          Image($r('app.media.ic_chevron_right'))
            .width(12).height(12)
            .fillColor(this.colors.accentGold)
            .rotate({ angle: this.isRtl() ? 180 : 0 })
        }
        .onClick(() => {
          router.pushUrl({ url: 'pages/PrayerDetailsPage' })
            .catch((e: Error) => console.error('Nav fail', e));
        })
      }
      .width('100%').padding({ bottom: 14 })

      Row() {
        Column() {
          Row() {
            Text(`${this.prayerProgress.todayCompleted}`)
              .fontSize(52)
              .fontFamily(TypographyHelper.getFont(this.currentLanguage, true))
              .fontFeature('"tnum" 1')
              .fontWeight(FontWeight.Bold)
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
      Row({ space: 8 }) {
        Image($r('app.media.ic_nav_tasbih'))
          .width(16).height(16)
          .fillColor(this.colors.accentGold)
          .flexShrink(0)
        Text(this.tr('home_tasbih'))
          .fontSize(12)
          .fontColor(this.colors.textMuted)
          .fontWeight(FontWeight.Bold)
          .letterSpacing(1.5)
          .layoutWeight(1)
        Row({ space: 2 }) {
          Text(this.tr('details_view'))
            .fontSize(11).fontColor(this.colors.accentGold)
            .fontWeight(FontWeight.Medium)
          Image($r('app.media.ic_chevron_right'))
            .width(12).height(12)
            .fillColor(this.colors.accentGold)
            .rotate({ angle: this.isRtl() ? 180 : 0 })
        }
        .onClick(() => {
          router.pushUrl({ url: 'pages/TasbihDetailsPage' })
            .catch((e: Error) => console.error('Nav fail', e));
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

  // ============================================================
  // EID AL-FITR CARD
  // ============================================================

  @Builder
  EidCard() {
    if (this.eidInfo !== null) {
      Column() {
        // ---- Header: 🌙 EID AL-FITR · 1447 AH · View Details › ----
        Row() {
          Image($r('app.media.ic_ramadan_moon'))
            .width(16).height(16)
            .fillColor(this.colors.accentGold)
            .margin({ right: 8 })
          Text(this.tr('eid_card_title'))
            .fontSize(12)
            .fontColor(this.colors.textMuted)
            .fontWeight(FontWeight.Bold)
            .letterSpacing(1.5)
          Text(`  ${this.eidInfo!.hijriYear} ${this.tr('hijri_year_suffix')}`)
            .fontSize(12)
            .fontColor(this.colors.accentGold)
            .fontWeight(FontWeight.Medium)
          Blank()
          Row() {
            Text(this.tr('eid_card_link'))
              .fontSize(11).fontColor(this.colors.accentGold)
              .fontWeight(FontWeight.Medium)
            Image($r('app.media.ic_chevron_right'))
              .width(12)
              .height(12)
              .fillColor(this.colors.accentGold)
              .margin({ left: this.isRtl() ? 0 : 2, right: this.isRtl() ? 2 : 0 })
              .rotate({ angle: this.isRtl() ? 180 : 0 })
          }
          .onClick(() => {
            router.pushUrl({ url: 'pages/RamadanDetailsPage' })
              .catch((e: Error) =>
              console.error('Navigation failed:', JSON.stringify(e)));
          })
        }
        .width('100%').padding({ bottom: 16 })

        // ---- Greeting ----
        Text(this.tr('eid_greeting'))
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textWhite)
          .width('100%')
          .margin({ bottom: 4 })
        Text(this.tr('eid_greeting_subtitle'))
          .fontSize(13)
          .fontColor(this.colors.accentGold)
          .width('100%')
          .lineHeight(18)
          .margin({ bottom: 18 })

        Divider().color(this.colors.borderSoft).margin({ bottom: 14 })

        // ---- Zakat al-Fitr ----
        Text(this.tr('eid_zakat_fitr'))
          .fontSize(11)
          .fontColor(this.colors.textMuted)
          .fontWeight(FontWeight.Bold)
          .letterSpacing(1.2)
          .width('100%')
          .padding({ bottom: 8 })
        Text(this.tr('eid_zakat_fitr_desc'))
          .fontSize(12)
          .fontColor(this.colors.textWhite)
          .lineHeight(18)
          .width('100%')
          .padding({ bottom: 16 })

        Divider().color(this.colors.borderSoft).margin({ bottom: 16 })

        // ---- Takbeer ----
        Text(this.tr('eid_takbeer_arabic'))
          .fontSize(20)
          .fontFamily(TypographyHelper.getFont('ar', false))
          .fontColor(this.colors.accentGold)
          .textAlign(TextAlign.Center)
          .lineHeight(34)
          .width('100%')
          .padding({ bottom: 10 })

        if (this.currentLanguage !== 'ar') {
          Text(this.tr('eid_takbeer_translation'))
            .fontSize(11)
            .fontColor(this.colors.textMuted)
            .fontStyle(FontStyle.Italic)
            .textAlign(TextAlign.Center)
            .lineHeight(16)
            .width('100%')
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
}