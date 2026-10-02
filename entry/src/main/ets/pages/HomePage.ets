// entry/src/main/ets/pages/HomePage.ets

import { mediaquery, promptAction, router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { Theme, ThemeColors, ThemeMode } from '../common/Theme';
import { PageTheme } from '../common/PageTheme';
import {
  STORAGE_KEY_APP_FOREGROUND_TICK,
  STORAGE_KEY_BREAKPOINT,
  STORAGE_KEY_HIJRI_OFFSET,
  STORAGE_KEY_LANGUAGE,
  STORAGE_KEY_LOCATION_VERSION,
  STORAGE_KEY_PRAYER_STATE_VERSION,
  STORAGE_KEY_THEME_MODE
} from '../common/StorageKeys';
import { DateHelper } from '../utils/DateUtils';
import { PrayerModel } from '../models/PrayerModel';
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
} from '../utils/PrayerTimeCalculator';
import { PrayerManager } from '../utils/PrayerManager';
import { NavHelper } from '../helper/NavHelper';
import { L } from '../helper/LocalizationHelper';
import { MonthDayCell, MonthProgress, PrayerProgress, ProgressHelper, TasbihProgress } from '../utils/ProgressHelper';
import { TasbihStorage } from '../utils/TasbihStorage';
import { TasbihManager } from '../utils/TasbihManager';
import { Tasbih } from '../models/TasbihModels';
import { PageHeader } from '../components/PageHeader';
import { DuaCard } from '../components/DuaCard';
import { DUA_IFTAR, DUA_SUHOOR, DuaEntry } from '../data/Duas';
import { LaylatAlQadrNight, RamadanAshra, RamadanHelper, RamadanInfo } from '../helper/RamadanHelper';
import { Breakpoints } from '../common/Breakpoints';

@Component
export struct HomePage {

  // ============================================================
  // STORAGE LINKS
  // ============================================================

  @StorageLink(STORAGE_KEY_THEME_MODE)
  @Watch('onThemeModeChanged')
  themeMode: string = ThemeMode.SYSTEM;
  @StorageLink(STORAGE_KEY_PRAYER_STATE_VERSION)
  @Watch('onPrayerStateChanged')
  prayerStateVersion: number = 0;

  @StorageLink(STORAGE_KEY_LOCATION_VERSION)
  @Watch('onLocationVersionChanged')
  locationVersion: number = 0;

  @StorageLink(STORAGE_KEY_LANGUAGE)
  @Watch('onLanguageChanged')
  appLanguage: string = 'en';

  @StorageLink(STORAGE_KEY_HIJRI_OFFSET)
  @Watch('onHijriOffsetChanged')
  hijriOffset: number = 0;

  @StorageLink(STORAGE_KEY_APP_FOREGROUND_TICK)
  @Watch('onAppForegrounded')
  appForegroundTick: number = 0;

  @StorageLink(STORAGE_KEY_BREAKPOINT)
  breakpoint: string = 'sm';

  @State colors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);
  private systemDarkListener: mediaquery.MediaQueryListener | null = null;

  // ============================================================
  // HEADER STATE
  // ============================================================

  @State currentLocation: string = 'Loading...';
  @State isLoadingLocation: boolean = true;
  @State latitude: number = 0;
  @State longitude: number = 0;
  @State hijriDateString: string = '';
  @State todayCurrentPrayerName: string = '—';
  @State todayCurrentPrayerTime: string = '--:--';
  @State todayNextPrayerName: string = '—';
  @State todayNextPrayerTime: string = '--:--';

  @State locationMode: LocationMode = LocationMode.GPS;

  // ============================================================
  // DASHBOARD STATE
  // ============================================================

  @State private prayerProgress: PrayerProgress = {
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

  @State private tasbihProgress: TasbihProgress = {
    totalTasbihs: 0,
    totalDhikrs: 0,
    lifetimeCount: 0,
    completedDhikrs: 0
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

  // ============================================================
  // FASTING WINDOW
  // ============================================================

  @State private todayImsakTime: string = '--:--';
  @State private todayMaghribTime: string = '--:--';
  @State private fastingWindowIsPreview: boolean = false;
  // ---- Live countdown ----
  @State private countdownTarget: string = '';
  @State private countdownDisplay: string = '';
  @State private countdownHeld: boolean = false;
  private countdownTimerId: number = -1;

  // ============================================================
  // PULL-TO-REFRESH
  // ============================================================

  @State private isRefreshing: boolean = false;

  // ============================================================
  // HAMBURGER SHEET
  // ============================================================

  @State showBottomSheet: boolean = false;

  // ============================================================
  // LOCATION + CALC PARAMS
  // ============================================================

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

  private settingsLoading: boolean = false;

  // ============================================================
  // LOCALIZATION + DIRECTION + BREAKPOINT
  // ============================================================

  @State private currentLanguage: string = 'en';

  private tr(key: string): string {
    return L.get(key, this.currentLanguage);
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

  /**
   * Fires the moment any page writes prayer check state. Because
   * HomePage is hosted inside MainTabs as a TabContent, it does not
   * receive onPageShow on tab switches — this watcher is how it learns
   * that the Prayers tab checked a prayer.
   */
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

  // ============================================================
  // WATCHERS
  // ============================================================

  private onThemeModeChanged(): void {
    this.colors = PageTheme.compute(this.themeMode);
  }

  private onLanguageChanged(): void {
    this.currentLanguage = this.appLanguage;
  }

  private async onLocationVersionChanged(): Promise<void> {
    await this.loadSettingsAndLocation();
    await this.refreshDashboard();
  }

  private onHijriOffsetChanged(): void {
    this.refreshHijriDate();
    this.refreshRamadan();
    this.upcomingEvents = DateHelper.getUpcomingImportantDates(this.hijriOffset);
  }

  private async onAppForegrounded(): Promise<void> {
    this.refreshHijriDate();
    this.refreshRamadan();
    this.upcomingEvents = DateHelper.getUpcomingImportantDates(this.hijriOffset);
    await this.loadSettingsAndLocation();
    await this.refreshDashboard();
    this.updateCountdown();
    this.startCountdownTimer();
  }

  // ============================================================
  // LIFECYCLE
  // ============================================================

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
    this.upcomingEvents = DateHelper.getUpcomingImportantDates(this.hijriOffset);
    await this.loadSettingsAndLocation();
    await this.refreshDashboard();
    this.startCountdownTimer();
  }

  aboutToDisappear(): void {
    PageTheme.uninstallSystemListener(this.systemDarkListener);
    this.systemDarkListener = null;
    this.stopCountdownTimer();
  }

  async onPageShow(): Promise<void> {
    this.currentLanguage = this.appLanguage;
    this.colors = PageTheme.compute(this.themeMode);
    this.refreshHijriDate();
    this.refreshRamadan();
    this.upcomingEvents = DateHelper.getUpcomingImportantDates(this.hijriOffset);
    await this.refreshDashboard();
    this.startCountdownTimer();
  }

  onPageHide(): void {
    this.stopCountdownTimer();
  }

  // ============================================================
  // DATA LOADING
  // ============================================================

  private async loadSettingsAndLocation(): Promise<void> {
    if (this.settingsLoading) {
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
    }
  }

  private async refreshDashboard(): Promise<void> {
    this.prayerProgress = ProgressHelper.getPrayerProgress();
    this.monthProgress = ProgressHelper.getMonthProgress();

    const loaded = await TasbihStorage.load(TasbihManager.createDefaults());
    const tasbihs: Tasbih[] = loaded.tasbihs;
    this.tasbihProgress = ProgressHelper.getTasbihProgress(tasbihs);

    this.refreshHeader();
    this.refreshFastingWindow();
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
      this.highLatRule, this.offsets, prayers
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
        this.calcMethod, this.asrRule, this.highLatRule
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
    if (info.isRamadanNow || (info.daysUntilStart >= 0 && info.daysUntilStart <= 60)) {
      this.ramadanInfo = info;
    } else {
      this.ramadanInfo = null;
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

  // ============================================================
  // LIVE COUNTDOWN
  // ============================================================

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

  // ============================================================
  // PULL-TO-REFRESH
  // ============================================================

  private async handleRefresh(): Promise<void> {
    try {
      this.refreshHijriDate();
      this.refreshRamadan();
      this.upcomingEvents = DateHelper.getUpcomingImportantDates(this.hijriOffset);
      await this.loadSettingsAndLocation();
      await this.refreshDashboard();
    } finally {
      this.isRefreshing = false;
    }
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  private navigateToSettings(): void {
    this.closeBottomSheet();
    setTimeout(() => {
      NavHelper.prepareForward();
      router.pushUrl({ url: 'pages/SettingsPage' })
        .catch((e: Error) =>
        console.error('Navigation failed:', JSON.stringify(e)));
    }, 350);
  }

  private closeBottomSheetAndNavigate(url: string): void {
    this.showBottomSheet = false;
    setTimeout(() => {
      NavHelper.prepareForward();
      router.pushUrl({ url })
        .catch((e: Error) =>
        console.error('Navigation failed:', JSON.stringify(e)));
    }, 350);
  }

  private closeBottomSheet(): void {
    this.showBottomSheet = false;
  }

  private exitApp(): void {
    promptAction.showDialog({
      title: this.tr('exit'),
      message: this.tr('exit_confirm_message'),
      buttons: [
        { text: this.tr('cancel'), color: this.colors.dialogCancel },
        { text: this.tr('exit'), color: this.colors.accentGold }
      ]
    }).then((result: promptAction.ShowDialogSuccessResponse) => {
      if (result.index === 1) {
        const ctx = getContext(this) as common.UIAbilityContext;
        ctx.terminateSelf().catch((err: Error) =>
        console.error('Terminate failed:', JSON.stringify(err)));
      }
    }).catch((err: Error) =>
    console.error('Dialog error:', JSON.stringify(err)));
  }

  // ============================================================
  // LOCATION
  // ============================================================

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

  // ============================================================
  // MONTH CELL HELPERS
  // ============================================================

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

  // ============================================================
  // BUILD
  // ============================================================

  build() {
    Stack() {
      Column() {
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
          onHamburger: () => {
            this.showBottomSheet = !this.showBottomSheet;
          },
          onRefreshLocation: () => {
            this.refreshLocation();
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
                    this.CountdownCard()
                    this.LiveCountdownBanner()
                    this.RamadanCard()
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)

                  Column() {
                    this.TodayProgressCard()
                    this.StreakCard()
                    this.WeekGridCard()
                    this.MonthCard()
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
                  this.CountdownCard()
                  this.LiveCountdownBanner()
                  this.RamadanCard()
                  this.TodayProgressCard()
                  this.StreakCard()
                  this.WeekGridCard()
                  this.MonthCard()
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
    // bindSheet renders in the system modal layer, above the native
    // Tabs chrome. This is the only reliable way to cover the floating
    // tab bar from inside a TabContent page.
    .bindSheet($$this.showBottomSheet, this.HamburgerMenu(), {
      height: 300,
      dragBar: true,
      showClose: false,
      backgroundColor: this.colors.cardDark,
      blurStyle: BlurStyle.Thick,
      maskColor: this.colors.overlayDim
    })
  }

  // ============================================================
  // HAMBURGER MENU (rendered by bindSheet)
  // ============================================================

  @Builder
  HamburgerMenu() {
    Column() {
      // ---- Brand header — forced LTR, explicitly centred ----
      Row() {
        Text('Sirat')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textWhite)
        Text('Companion')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.accentGold)
          .margin({ left: 8 })
      }
      .width('100%')
      .height(48)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .direction(Direction.Ltr)
      .margin({ top: 12, bottom: 12 })

      // ---- Divider — full width, clearly visible ----
      Divider()
        .strokeWidth(1)
        .color(this.colors.borderMedium)
        .width('100%')

      // ---- Menu items ----
      Column() {
        this.BottomSheetItem('✏️', this.tr('title_customize'), () => {
          this.closeBottomSheetAndNavigate('pages/CustomizePage');
        })
        this.BottomSheetItem('⚙️', this.tr('title_settings'), () => {
          this.closeBottomSheetAndNavigate('pages/SettingsPage');
        })
        this.BottomSheetItem('🚪', this.tr('exit'), () => {
          this.showBottomSheet = false;
          setTimeout(() => {
            this.exitApp();
          }, 350);
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8 })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }

  // ============================================================
  // COUNTDOWN CARD
  // ============================================================

  @Builder
  CountdownCard() {
    if (this.upcomingEvents.length > 0) {
      Column() {
        Row() {
          Text('🌙').fontSize(14).margin({ right: 8 })
          Text(this.tr('home_next_event'))
            .fontSize(11)
            .fontColor(this.colors.textMuted)
            .fontWeight(FontWeight.Bold)
            .letterSpacing(1.2)
            .layoutWeight(1)
        }
        .width('100%').padding({ bottom: 14 })

        this.CountdownMainEvent(this.upcomingEvents[0])

        if (this.upcomingEvents.length > 1) {
          Divider().color(this.colors.borderSoft).margin({ top: 14, bottom: 12 })
          Column() {
            this.CountdownSecondaryRow(this.upcomingEvents[1])
            if (this.upcomingEvents.length > 2) {
              this.CountdownSecondaryRow(this.upcomingEvents[2])
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
  CountdownMainEvent(e: UpcomingImportantDate) {
    Row() {
      Column() {
        if (e.daysUntil === 0) {
          Text('🎉').fontSize(30)
          Text(this.tr('home_event_today'))
            .fontSize(12).fontWeight(FontWeight.Bold)
            .fontColor(this.colors.textOnAccent)
            .margin({ top: 2 })
        } else if (e.daysUntil === 1) {
          Text('1')
            .fontSize(38).fontWeight(FontWeight.Bold)
            .fontColor(this.colors.textOnAccent)
          Text(this.tr('home_event_tomorrow'))
            .fontSize(10).fontWeight(FontWeight.Medium)
            .fontColor(this.colors.textOnAccent).opacity(0.9)
        } else {
          Text(`${e.daysUntil}`)
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
        Text(this.translateUpcomingEventName(e))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textWhite)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Text(e.hijriDate)
          .fontSize(12)
          .fontColor(this.colors.accentGold)
          .margin({ top: 6 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .layoutWeight(1).margin({ left: 16 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  CountdownSecondaryRow(e: UpcomingImportantDate) {
    Row() {
      Text('✨').fontSize(13).margin({ right: 8 }).opacity(0.75)
      Text(this.translateUpcomingEventName(e))
        .fontSize(13)
        .fontColor(this.colors.textWhite)
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
      Text(this.countdownShortLabel(e.daysUntil))
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

  // ============================================================
  // LIVE COUNTDOWN BANNER
  // ============================================================

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

  // ============================================================
  // RAMADAN CARD
  // ============================================================

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
          Text(this.todayImsakTime)
            .fontSize(16).fontColor(this.colors.accentGold).fontWeight(FontWeight.Bold)
            .direction(Direction.Ltr)
        }
        .width('100%').padding({ top: 6, bottom: 6 }).alignItems(VerticalAlign.Center)

        Row() {
          Text('🌇').fontSize(14).margin({ right: 8 }).width(20).textAlign(TextAlign.Center)
          Text(this.tr('ramadan_fast_end'))
            .fontSize(12).fontColor(this.colors.textMuted).layoutWeight(1)
          Text(this.todayMaghribTime)
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

  // ============================================================
  // TODAY'S PROGRESS CARD
  // ============================================================

  @Builder
  TodayProgressCard() {
    Column() {
      Row() {
        Text(this.tr('home_today_progress'))
          .fontSize(12)
          .fontColor(this.colors.textMuted)
          .fontWeight(FontWeight.Bold)
          .letterSpacing(1.2)
          .layoutWeight(1)
        Text(this.tr('home_keep_going'))
          .fontSize(11).fontColor(this.colors.accentGold)
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
        this.PrayerDot(this.tr('prayer_fajr'), this.prayerProgress.todayFajr)
        this.PrayerDot(this.tr('prayer_dhuhr'), this.prayerProgress.todayDhuhr)
        this.PrayerDot(this.tr('prayer_asr'), this.prayerProgress.todayAsr)
        this.PrayerDot(this.tr('prayer_maghrib'), this.prayerProgress.todayMaghrib)
        this.PrayerDot(this.tr('prayer_isha'), this.prayerProgress.todayIsha)
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
  PrayerDot(label: string, done: boolean) {
    Column() {
      Stack() {
        Circle()
          .width(20)
          .height(20)
          .fill(done ? this.colors.accentGold : Color.Transparent)
          .stroke(done ? this.colors.accentGold : this.colors.borderStrong)
          .strokeWidth(2)
      }
      .width(20).height(20)

      Text(label)
        .fontSize(9)
        .fontColor(done
          ? this.colors.accentGold : this.colors.textMuted)
        .margin({ top: 6 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1).alignItems(HorizontalAlign.Center)
  }

  // ============================================================
  // STREAK CARD
  // ============================================================

  @Builder
  StreakCard() {
    Row() {
      Row() {
        Column() {
          Text('🔥').fontSize(28)
        }
        .width(48)
        .height(48)
        .borderRadius(24)
        .backgroundColor(this.colors.tintSoft)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Column() {
          Row() {
            Text(`${this.prayerProgress.currentStreak}`)
              .fontSize(28).fontWeight(FontWeight.Bold)
              .fontColor(this.colors.textWhite)
            Text(` ${this.tr('home_days')}`)
              .fontSize(12).fontColor(this.colors.textMuted)
              .margin({ left: 2, bottom: 4 })
          }.alignItems(VerticalAlign.Bottom)
          Text(this.tr('home_streak'))
            .fontSize(11).fontColor(this.colors.textMuted)
        }
        .alignItems(HorizontalAlign.Start).margin({ left: 12 }).layoutWeight(1)
      }.layoutWeight(1)

      Divider().vertical(true).height(48).color(this.colors.borderSoft)

      Column() {
        Text('🏆').fontSize(20).margin({ bottom: 4 })
        Row() {
          Text(`${this.prayerProgress.bestStreak}`)
            .fontSize(18).fontWeight(FontWeight.Bold)
            .fontColor(this.colors.accentGold)
          Text(` ${this.tr('home_best_streak')}`)
            .fontSize(10).fontColor(this.colors.textMuted).margin({ left: 4 })
        }
      }
      .layoutWeight(1).padding({ left: 12 }).alignItems(HorizontalAlign.Center)
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
    .alignItems(VerticalAlign.Center)
  }

  // ============================================================
  // WEEK GRID CARD
  // ============================================================

  @Builder
  WeekGridCard() {
    Column() {
      Row() {
        Text(this.tr('home_this_week'))
          .fontSize(12)
          .fontColor(this.colors.textMuted)
          .fontWeight(FontWeight.Bold)
          .letterSpacing(1.2)
          .layoutWeight(1)
        Text(`${this.prayerProgress.weekCompleted} / 35`)
          .fontSize(12).fontColor(this.colors.accentGold)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%').padding({ bottom: 14 })

      Row({ space: 6 }) {
        ForEach(this.prayerProgress.weeklyGrid, (done: boolean, i: number) => {
          Column() {
            Text(this.prayerProgress.weeklyLabels[i])
              .fontSize(11).fontColor(this.colors.textMuted).margin({ bottom: 8 })
            Row()
              .width('100%')
              .height(36)
              .borderRadius(8)
              .backgroundColor(done ? this.colors.accentGold : this.colors.tintSoft)
              .border({
                width: 1,
                color: done ? this.colors.accentGold : this.colors.borderSoft
              })
            if (done) {
              Text('✓').fontSize(14).fontColor(this.colors.textOnAccent)
                .position({ x: '50%', y: 32 }).translate({ x: -8 })
            }
          }
          .layoutWeight(1).alignItems(HorizontalAlign.Center)
        }, (done: boolean, i: number) => `w-${i}-${done ? 'd' : 'u'}`)
      }
      .width('100%')

      Text(`${this.prayerProgress.weekCompleted} ${this.tr('home_week_summary')}`)
        .fontSize(11).fontColor(this.colors.textMuted).margin({ top: 12 })
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
  // MONTHLY VIEW CARD
  // ============================================================

  @Builder
  MonthCard() {
    Column() {
      Row() {
        Text('📊').fontSize(14).margin({ right: 8 })
        Text(this.tr('home_monthly_view'))
          .fontSize(12)
          .fontColor(this.colors.textMuted)
          .fontWeight(FontWeight.Bold)
          .letterSpacing(1.2)
          .layoutWeight(1)
        Text(ProgressHelper.formatGregorianMonth(
          this.monthProgress.year,
          this.monthProgress.monthIndex,
          this.currentLanguage
        ))
          .fontSize(12).fontColor(this.colors.accentGold)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%').padding({ bottom: 14 })

      Row() {
        ForEach(['S', 'M', 'T', 'W', 'T', 'F', 'S'], (d: string, i: number) => {
          Text(d)
            .fontSize(10)
            .fontColor(this.colors.textMuted)
            .fontWeight(FontWeight.Medium)
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
        }, (d: string, i: number) => `mh-${i}-${d}`)
      }
      .width('100%').padding({ bottom: 6 }).direction(Direction.Ltr)

      Column() {
        ForEach(this.monthProgress.weeks, (week: MonthDayCell[], wi: number) => {
          Row() {
            ForEach(week, (cell: MonthDayCell, di: number) => {
              if (cell.isPadding) {
                Column().layoutWeight(1).height(32).margin({ left: 2, right: 2 })
              } else {
                this.MonthDayCellView(cell)
              }
            }, (cell: MonthDayCell, di: number) =>
            `mc-${wi}-${di}-${cell.dayOfMonth}-${cell.completed}-${cell.isToday ? 'T' : ''}`)
          }
          .width('100%').margin({ bottom: 4 })
        }, (week: MonthDayCell[], wi: number) =>
        `mw-${wi}-${this.monthProgress.year}-${this.monthProgress.monthIndex}`)
      }
      .width('100%').direction(Direction.Ltr)

      Row() {
        Column() {
          Text(`${this.monthProgress.totalCompleted}`)
            .fontSize(18).fontWeight(FontWeight.Bold)
            .fontColor(this.colors.accentGold)
          Text(this.tr('home_month_summary'))
            .fontSize(10).fontColor(this.colors.textMuted).margin({ top: 2 })
        }
        .layoutWeight(1).alignItems(HorizontalAlign.Center)

        Divider().vertical(true).height(30).color(this.colors.borderSoft)

        Column() {
          Text(`${this.monthProgress.perfectDays}`)
            .fontSize(18).fontWeight(FontWeight.Bold)
            .fontColor(this.colors.accentGoldLight)
          Text(this.tr('home_perfect_days'))
            .fontSize(10).fontColor(this.colors.textMuted).margin({ top: 2 })
        }
        .layoutWeight(1).alignItems(HorizontalAlign.Center)

        Divider().vertical(true).height(30).color(this.colors.borderSoft)

        Column() {
          Text(`${this.monthProgress.daysElapsed}`)
            .fontSize(18).fontWeight(FontWeight.Bold)
            .fontColor(this.colors.textWhite)
          Text(this.tr('home_days_elapsed'))
            .fontSize(10).fontColor(this.colors.textMuted).margin({ top: 2 })
        }
        .layoutWeight(1).alignItems(HorizontalAlign.Center)
      }
      .width('100%').margin({ top: 14 }).alignItems(VerticalAlign.Center)
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

  // ============================================================
  // TASBIH CARD
  // ============================================================

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
      }
      .width('100%').padding({ bottom: 14 })

      Row() {
        Column() {
          Text(`${this.tasbihProgress.lifetimeCount}`)
            .fontSize(32).fontWeight(FontWeight.Bold)
            .fontColor(this.colors.accentGold)
          Text(this.tr('home_tasbih_lifetime'))
            .fontSize(11).fontColor(this.colors.textMuted).margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        Divider().vertical(true).height(50).color(this.colors.borderSoft)

        Column() {
          Text(`${this.tasbihProgress.totalTasbihs}`)
            .fontSize(22).fontWeight(FontWeight.Bold)
            .fontColor(this.colors.textWhite)
          Text(this.tr('home_tasbih_summary'))
            .fontSize(10).fontColor(this.colors.textMuted).margin({ top: 2 })
        }
        .padding({ left: 16 }).layoutWeight(1).alignItems(HorizontalAlign.Start)

        Divider().vertical(true).height(50).color(this.colors.borderSoft)

        Column() {
          Text(`${this.tasbihProgress.totalDhikrs}`)
            .fontSize(22).fontWeight(FontWeight.Bold)
            .fontColor(this.colors.textWhite)
          Text(this.tr('home_dhikrs'))
            .fontSize(10).fontColor(this.colors.textMuted).margin({ top: 2 })
        }
        .padding({ left: 16 }).layoutWeight(1).alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      Divider().color(this.colors.borderSoft).margin({ top: 14, bottom: 12 })

      Row() {
        Text('✨').fontSize(11).margin({ right: 6 }).opacity(0.75)
        Text(`${this.prayerProgress.yearCompleted} ${this.tr('home_lifetime_1y')}`)
          .fontSize(10).fontColor(this.colors.textMuted)
          .fontStyle(FontStyle.Italic).layoutWeight(1)
      }
      .width('100%').justifyContent(FlexAlign.Center)
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
  // BOTTOM SHEET ITEM
  // ============================================================

  @Builder
  BottomSheetItem(icon: string, label: string, onClick: () => void) {
    Row() {
      Text(icon).fontSize(22).margin({ right: 16 })
      Text(label).fontSize(16).fontColor(this.colors.textWhite)
    }
    .width('100%')
    .padding({ top: 12, bottom: 12, left: 16 })
    .borderRadius(Theme.radiusSmall)
    .onClick(() => {
      onClick();
    })
  }
}