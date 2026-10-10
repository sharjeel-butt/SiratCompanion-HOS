// entry/src/main/ets/pages/Prayer.ets
import { mediaquery, promptAction, router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
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
import {
  STORAGE_KEY_APP_FOREGROUND_TICK,
  STORAGE_KEY_APP_THEME,
  STORAGE_KEY_BREAKPOINT,
  STORAGE_KEY_HIJRI_OFFSET,
  STORAGE_KEY_LANGUAGE,
  STORAGE_KEY_LOCATION_VERSION,
  STORAGE_KEY_PRAYER_STATE_VERSION,
  STORAGE_KEY_THEME_MODE,
  STORAGE_KEY_TIME_FORMAT
} from '../common/StorageKeys';
import { AppLogger } from '../helper/AppLogger';
import { HomeController } from '../utils/HomeController';
import { AsrShadowRule, CalculationMethod, HighLatitudeRule } from '../prayer/PrayerTimeCalculator';
import { NavHelper } from '../helper/NavHelper';
import { TimezoneResolver } from '../utils/TimezoneResolver';
import { L } from '../helper/LocalizationHelper';
import { PageHeader } from '../components/PageHeader';
import { PrayerSunPath } from '../prayer/PrayerSunPath';
import { Breakpoints } from '../common/Breakpoints';
import { ClockFormat, ClockFormatHelper } from '../common/ClockFormat';

interface DialogResult {
  index: number;
}

interface TimelineRow {
  kind: 'prayer' | 'extra';
  id: string;
  time: string;
  sortMinutes: number;
  prayerRef: PrayerModel | null;
  extraRef: ExtraTiming | null;
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

  @StorageLink(STORAGE_KEY_APP_FOREGROUND_TICK)
  @Watch('onAppForegrounded')
  appForegroundTick: number = 0;

  @StorageLink(STORAGE_KEY_BREAKPOINT)
  breakpoint: string = 'sm';
  @StorageLink(STORAGE_KEY_TIME_FORMAT)
  @Watch('onClockFormatChanged')
  clockFormat: string = ClockFormat.SYSTEM;

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

  @State upcomingImportantDates: UpcomingImportantDate[] = [];

  @State prayers: PrayerModel[] = [
    { id: 'fajr',    name: 'Fajr',    arabicName: 'الفجر',   time: '--:--', status: 'abbreviation', checked: false },
    { id: 'dhuhr',   name: 'Dhuhr',   arabicName: 'الظهر',   time: '--:--', status: 'abbreviation', checked: false },
    { id: 'asr',     name: 'Asr',     arabicName: 'العصر',   time: '--:--', status: 'abbreviation', checked: false },
    { id: 'maghrib', name: 'Maghrib', arabicName: 'المغرب',  time: '--:--', status: 'abbreviation', checked: false },
    { id: 'isha',    name: 'Isha',    arabicName: 'العشاء',  time: '--:--', status: 'abbreviation', checked: false }
  ];

  @State extraTimings: ExtraTiming[] = [
    { id: 'imsak',      name: 'Imsak',       arabicName: 'الإمساك',     time: '--:--', status: 'abbreviation', icon: '🌙' },
    { id: 'sunrise',    name: 'Sunrise',     arabicName: 'الشروق',      time: '--:--', status: 'abbreviation', icon: '🌅' },
    { id: 'sunset',     name: 'Sunset',      arabicName: 'المغرب',      time: '--:--', status: 'abbreviation', icon: '🌇' },
    { id: 'firstThird', name: 'First Third', arabicName: 'الثلث الأول', time: '--:--', status: 'abbreviation', icon: '🌃' },
    { id: 'midnight',   name: 'Midnight',    arabicName: 'منتصف الليل', time: '--:--', status: 'abbreviation', icon: '🌌' },
    { id: 'lastThird',  name: 'Last Third',  arabicName: 'الثلث الأخير', time: '--:--', status: 'abbreviation', icon: '🌠' }
  ];

  @State calcMethod: CalculationMethod = CalculationMethod.KARACHI;
  @State asrRule: AsrShadowRule = AsrShadowRule.STANDARD;
  @State calcSource: CalculationSource = CalculationSource.LOCAL;
  @State locationMode: LocationMode = LocationMode.GPS;
  @State offsets: PrayerOffsets = { fajr: 0, dhuhr: 0, asr: 0, maghrib: 0, isha: 0 };

  @State showExtraTimings: boolean = true;
  @State showIslamicEvents: boolean = true;
  @State showBottomSheet: boolean = false;
  @State private isRefreshingHome: boolean = false;
  @State highLatRule: HighLatitudeRule = HighLatitudeRule.NONE;

  private statusTimerId: number = -1;
  private settingsLoaded: boolean = false;
  private settingsLoading: boolean = false;

  private tr(key: string): string {
    return L.get(key, this.appLanguage);
  }

  /**
   * Reformat an internal 12-hour time string for display. Reads
   * this.ClockFormat to establish a reactive dependency so that
   * changing the format re-renders every time call site.
   */
  private dt(t: string): string {
    if (this.clockFormat.length === 0) {
      return t;
    }
    return ClockFormatHelper.reformat(t);
  }

  private onClockFormatChanged(): void {
    // Re-render is handled by the @StorageLink.
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
    // Notifications disabled pending AGC approval.
  }

  private onHijriOffsetChangedInHome(): void {
    this.refreshHijriDates();
    this.upcomingImportantDates =
      DateHelper.getUpcomingImportantDates(this.hijriOffset);
  }

  private async onAppForegrounded(): Promise<void> {
    this.refreshHijriDates();
    this.upcomingImportantDates = DateHelper.getUpcomingImportantDates(this.hijriOffset);

    if (this.dateOffset === 0) {
      // ... (viewing date check unchanged)
    }

    await this.loadSettingsAndLocation();
    this.prayers = PrayerManager.updateStatuses(
      this.prayers, this.viewingDate, this.getLocationOffsetHours()
    );
    this.updateTodayHeaderData();
    this.refreshPrayerTimes();

    // Silently refresh GPS on foreground. Non-blocking.
    this.refreshLocationSilently();
  }

  aboutToAppear(): void {
    this.colors = PageTheme.compute(this.themeMode);
    this.systemDarkListener = PageTheme.installSystemListener(this.themeMode, (c) => {
      this.colors = c;
    });

    this.refreshHijriDates();
    this.upcomingImportantDates = DateHelper.getUpcomingImportantDates(this.hijriOffset);

    this.refreshViewingDate(true);
    this.initialize();
    this.startStatusTimer();

    // Silently refresh GPS on first load. Non-blocking.
    this.refreshLocationSilently();
  }

  aboutToDisappear(): void {
    PageTheme.uninstallSystemListener(this.systemDarkListener);
    this.systemDarkListener = null;
    if (this.statusTimerId !== -1) {
      clearInterval(this.statusTimerId);
      this.statusTimerId = -1;
    }
  }

  onPageShow(): void {
    this.colors = PageTheme.compute(this.themeMode);

    if (this.dateOffset === 0) {
      const now = new Date();
      const viewDay = new Date(this.viewingDate);
      viewDay.setHours(0, 0, 0, 0);
      const todayMidnight = new Date(now);
      todayMidnight.setHours(0, 0, 0, 0);
      if (viewDay.getTime() !== todayMidnight.getTime()) {
        this.refreshViewingDate(true);
      }
    }

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

  /**
   * Snap the view back to today. Only meaningful when viewing a past
   * or future day; guarded so a redundant tap does not trigger an
   * unnecessary reload.
   */
  private goToToday(): void {
    if (this.dateOffset === 0) {
      return;
    }
    this.dateOffset = 0;
    this.refreshViewingDate();
  }

  private async loadSettingsAndLocation(): Promise<void> {
    if (this.settingsLoading) return;
    this.settingsLoading = true;

    try {
      const data = await SettingsHelper.loadAll();
      const mode = await SettingsHelper.getLocationMode();

      this.calcMethod = data.method;
      this.asrRule    = data.asr;
      this.calcSource = data.source;
      this.locationMode = mode;
      this.showExtraTimings  = data.showExtraTimings;
      this.showIslamicEvents = data.showIslamicEvents;
      this.offsets = await SettingsHelper.getPrayerOffsets();
      this.highLatRule = await SettingsHelper.getHighLatRule();

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
    }
  }

  private refreshPrayerTimes(): void {
    if (this.calcSource !== CalculationSource.LOCAL) return;

    const snap = HomeController.buildPrayersForDate(
      this.viewingDate, this.latitude, this.longitude,
      this.calcMethod, this.asrRule, this.highLatRule,
      this.offsets, this.prayers
    );
    if (snap) this.prayers = snap.prayers;

    this.extraTimings = HomeController.buildExtraTimings(
      this.viewingDate, this.latitude, this.longitude,
      this.calcMethod, this.asrRule, this.highLatRule,
      this.offsets, this.extraTimings
    );
  }

  private updateTodayHeaderData(): void {
    if (this.calcSource !== CalculationSource.LOCAL) return;
    const hdr = HomeController.buildTodayHeader(
      this.latitude, this.longitude, this.calcMethod, this.asrRule,
      this.highLatRule, this.offsets, this.prayers
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

    if (this.showExtraTimings) {
      for (const t of this.extraTimings) {
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

  /**
   * Silently refresh the device location from GPS. Called on page
   * load and on every background-to-foreground transition.
   *
   * Non-blocking, non-interactive: if the fetch fails for any reason
   * (GPS off, permission denied, timeout), the cached location is
   * kept and prayer times are not recalculated. The user can always
   * trigger an interactive refresh by tapping the 📡 button or
   * pulling to refresh.
   *
   * When the fetch succeeds and the coordinates differ from the
   * cached values, the prayer list, timeline, header, and sun path
   * are all refreshed.
   */
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
      // Silent — keep cached location.
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
        return {
          id: p.id, name: p.name, arabicName: p.arabicName,
          time: p.time,
          status: p.status,
          checked: checked
        } as PrayerModel;
      }
      return p;
    });

    PrayerManager.saveStateForDate(this.viewingDateKey, this.prayers);

    // If the last remaining prayer for today was just marked, run an
    // immediate reschedule so tomorrow's reminders are queued before
    // the user closes the app. Otherwise use the debounced version
    // to coalesce rapid toggles.
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

  private hasUncheckedCheckablePrayers(): boolean {
    for (const p of this.prayers) {
      if (!p.checked
        && PrayerManager.isPrayerCheckable(p, this.viewingDate)) {
        return true;
      }
    }
    return false;
  }

  /**
   * True when every prayer in the current viewing date is checked.
   * Used to detect the moment the last prayer of the day is marked,
   * which triggers an immediate reschedule instead of the debounced
   * one.
   */
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
      return {
        id: p.id,
        name: p.name,
        arabicName: p.arabicName,
        time: p.time,
        status: p.status,
        checked: true
      } as PrayerModel;
    });

    if (!changed) {
      return;
    }
    PrayerManager.saveStateForDate(this.viewingDateKey, this.prayers);

    // "Mark all as prayed" always completes the day. Run the
    // reschedule immediately so tomorrow's reminders are queued.
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

  private closeBottomSheet(): void {
    this.showBottomSheet = false;
  }

  private closeBottomSheetAndNavigate(url: string): void {
    this.showBottomSheet = false;
    setTimeout(() => {
      NavHelper.prepareForward();
      router.pushUrl({ url })
        .catch((err: Error) =>
        console.error('Navigation failed:', JSON.stringify(err)));
    }, 350);
  }

  private navigateToSettings(): void {
    this.closeBottomSheetAndNavigate('pages/SettingsPage');
  }

  private exitApp(): void {
    promptAction.showDialog({
      title: this.tr('exit'),
      message: this.tr('exit_confirm_message'),
      buttons: [
        { text: this.tr('cancel'), color: this.colors.dialogCancel },
        { text: this.tr('exit'), color: this.colors.accentGold }
      ]
    }).then((result: DialogResult) => {
      if (result.index === 1) {
        const context = getContext(this) as common.UIAbilityContext;
        context.terminateSelf().catch((err: Error) =>
        console.error('Terminate failed:', JSON.stringify(err)));
      }
    }).catch((err: Error) => {
      console.error('Dialog error:', JSON.stringify(err));
    });
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

  private getFirstThirdTime(): string {
    for (const t of this.extraTimings) {
      if (t.id === 'firstThird') {
        return t.time;
      }
    }
    return '--:--';
  }

  private getMidnightTime(): string {
    for (const t of this.extraTimings) {
      if (t.id === 'midnight') {
        return t.time;
      }
    }
    return '--:--';
  }

  private getLastThirdTime(): string {
    for (const t of this.extraTimings) {
      if (t.id === 'lastThird') {
        return t.time;
      }
    }
    return '--:--';
  }

  private getSunriseTime(): string {
    for (const t of this.extraTimings) {
      if (t.id === 'sunrise') {
        return t.time;
      }
    }
    return '--:--';
  }

  private getSunsetTime(): string {
    for (const t of this.extraTimings) {
      if (t.id === 'sunset') {
        return t.time;
      }
    }
    return '--:--';
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
                      firstThirdTime: this.getFirstThirdTime(),
                      midnightTime: this.getMidnightTime(),
                      lastThirdTime: this.getLastThirdTime(),
                      currentLanguage: this.appLanguage,
                      isDarkMode: this.isDarkMode()
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
                      firstThirdTime: this.getFirstThirdTime(),
                      midnightTime: this.getMidnightTime(),
                      lastThirdTime: this.getLastThirdTime(),
                      currentLanguage: this.appLanguage,
                      isDarkMode: this.isDarkMode()
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

        Row() {
          Text('✓').fontSize(12).fontColor(this.colors.accentGold)
            .fontWeight(FontWeight.Bold).margin({ right: 4 })
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
        Text('◀')
          .fontSize(14)
          .fontColor(this.colors.accentGold)
          .width(36).height(36).textAlign(TextAlign.Center).borderRadius(18)
          .backgroundColor(this.colors.cardDark)
          .border({ width: 1, color: this.colors.borderSoft })
          .onClick(() => { this.goToPreviousDay(); })

        Text(this.viewingHijriDate)
          .fontSize(13)
          .fontColor(this.colors.accentGold)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1).textAlign(TextAlign.Center).maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text('▶')
          .fontSize(14)
          .fontColor(this.colors.accentGold)
          .width(36).height(36).textAlign(TextAlign.Center).borderRadius(18)
          .backgroundColor(this.colors.cardDark)
          .border({ width: 1, color: this.colors.borderSoft })
          .onClick(() => { this.goToNextDay(); })

        // "Today" shortcut — only shown when viewing a non-current day.
        // Tapping it snaps the view back to today's date and re-reads
        // the current day's prayer state.
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
          Text('✓')
            .fontSize(14)
            .fontColor(this.colors.textOnAccent)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
            .width('100%')
            .height('100%')
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
      Text(timing.icon ?? '•')
        .fontSize(15)
        .width(20)
        .height(20)
        .textAlign(TextAlign.Center)
        .opacity(0.85)

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
      Text('🌐').fontSize(56).margin({ bottom: 12 })
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
    .shadow({ radius: 12, color: this.colors.shadowCard, offsetX: 0, offsetY: 4 })
    .margin({ top: 4, bottom: 24 })
    .alignItems(HorizontalAlign.Center)
  }

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