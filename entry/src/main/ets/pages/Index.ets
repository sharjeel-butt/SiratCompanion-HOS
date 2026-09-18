// entry/src/main/ets/pages/Index.ets

import { router, promptAction } from '@kit.ArkUI';
import { NotificationHelper } from '../helper/NotificationHelper';
import { common } from '@kit.AbilityKit';
import { mediaquery } from '@kit.ArkUI';
import { Theme, ThemeColors, ThemeMode } from '../common/Theme';
import { PageTheme } from '../common/PageTheme';
import { PrayerModel, ExtraTiming } from '../models/PrayerModel';
import { DateHelper } from '../utils/DateUtils';
import { LocationHelper, LocationData } from '../utils/LocationUtils';
import { UpcomingImportantDate } from '../models/DateModels';
import { PrayerManager } from '../utils/PrayerManager';
import { SettingsHelper, PrayerOffsets } from '../helper/SettingsHelper';
import { LocationCache } from '../utils/LocationCache';
import { CalculationSource, LocationMode } from '../models/SettingsModels';
import {
  STORAGE_KEY_THEME_MODE,
  STORAGE_KEY_NAV_DIRECTION,
  STORAGE_KEY_LOCATION_VERSION,
  STORAGE_KEY_LANGUAGE,
  STORAGE_KEY_HIJRI_OFFSET
} from '../common/StorageKeys';
import { HomeController } from '../utils/HomeController';
import { CalculationMethod, AsrShadowRule, HighLatitudeRule } from '../utils/PrayerTimeCalculator';
import { NavHelper } from '../helper/NavHelper';
import { TimezoneResolver } from '../utils/TimezoneResolver';
import { L } from '../helper/LocalizationHelper';

interface DialogResult {
  index: number;
}

@Entry
@Component
struct Index {

  // ============================================================
  // THEME + NAV + LANGUAGE + HIJRI OFFSET
  // ============================================================

  @StorageLink(STORAGE_KEY_THEME_MODE)
  @Watch('onThemeModeChanged')
  themeMode: string = ThemeMode.SYSTEM;

  @StorageLink(STORAGE_KEY_NAV_DIRECTION)
  navDirection: string = 'forward';

  @StorageLink(STORAGE_KEY_LOCATION_VERSION)
  @Watch('onLocationVersionChanged')
  locationVersion: number = 0;

  @StorageLink(STORAGE_KEY_LANGUAGE)
  @Watch('onLanguageChangedInHome')
  appLanguage: string = 'en';

  @StorageLink(STORAGE_KEY_HIJRI_OFFSET)
  @Watch('onHijriOffsetChangedInHome')
  hijriOffset: number = 0;

  @State colors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);
  private systemDarkListener: mediaquery.MediaQueryListener | null = null;

  // ============================================================
  // STATE
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
  @State activeFloatingTab: string = 'home';
  @State private isRefreshingHome: boolean = false;
  @State highLatRule: HighLatitudeRule = HighLatitudeRule.NONE;

  private statusTimerId: number = -1;
  private settingsLoaded: boolean = false;
  private settingsLoading: boolean = false;

  // ============================================================
  // LOCALIZATION HELPERS
  // ============================================================

  private tr(key: string): string {
    return L.get(key, this.appLanguage);
  }

  private isRtl(): boolean {
    return L.isRtlLang(this.appLanguage);
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

  /**
   * Translate either a prayer name or an extra timing name.
   * Used by the Current / Next header rows, where the value could be
   * any of the 9 timeline events.
   */
  private translateEventName(raw: string): string {
    const asPrayer = this.translatePrayerName(raw);
    if (asPrayer !== raw) return asPrayer;
    return this.translateTimingName(raw);
  }

  /**
   * Translate a stored Islamic event into the current language.
   * Falls back to the stored English name if the key is missing.
   */
  private translateUpcomingEventName(e: UpcomingImportantDate): string {
    if (e.key && e.key.length > 0) {
      const translated = this.tr('event_' + e.key);
      if (translated !== 'event_' + e.key) return translated;
    }
    return e.name;
  }

  // ============================================================
  // THEME HANDLERS
  // ============================================================

  private isDarkMode(): boolean {
    if (this.themeMode === ThemeMode.DARK) return true;
    if (this.themeMode === ThemeMode.LIGHT) return false;
    return PageTheme.isSystemDark();
  }

  private onThemeModeChanged(): void {
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
    // Notification titles/content are localized at schedule time, so
    // they need to be rebuilt when the language changes.
    await NotificationHelper.rescheduleAll();
  }


  private onHijriOffsetChangedInHome(): void {
    // Re-render the Hijri date strings whenever the offset changes
    // (e.g. from Settings → Hijri Calendar).
    this.refreshHijriDates();
  }

  // ============================================================
  // PAGE TRANSITION
  // ============================================================

  pageTransition() {
    PageTransitionEnter({ type: RouteType.Push, duration: 300, curve: Curve.Friction })
      .slide(this.navDirection === 'forward' ? SlideEffect.Right : SlideEffect.Left)
    PageTransitionExit({ type: RouteType.Push, duration: 300, curve: Curve.Friction })
      .slide(this.navDirection === 'forward' ? SlideEffect.Left : SlideEffect.Right)

    PageTransitionEnter({ type: RouteType.Pop, duration: 300, curve: Curve.Friction })
      .slide(SlideEffect.Left)
    PageTransitionExit({ type: RouteType.Pop, duration: 300, curve: Curve.Friction })
      .slide(SlideEffect.Right)
  }

  // ============================================================
  // LIFECYCLE
  // ============================================================

  aboutToAppear(): void {
    this.colors = PageTheme.compute(this.themeMode);
    this.systemDarkListener = PageTheme.installSystemListener(this.themeMode, (c) => {
      this.colors = c;
    });

    this.refreshHijriDates();
    this.upcomingImportantDates = DateHelper.getUpcomingImportantDates();

    this.refreshViewingDate(true);
    this.initialize();
    this.startStatusTimer();
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

    // If the calendar day rolled over while the app was in the
    // background, snap the viewer back to today. Only do this when
    // the user was not intentionally browsing another date
    // (dateOffset === 0).
    if (this.dateOffset === 0) {
      const now = new Date();
      const viewDay = new Date(this.viewingDate);
      viewDay.setHours(0, 0, 0, 0);
      const todayMidnight = new Date(now);
      todayMidnight.setHours(0, 0, 0, 0);

      if (viewDay.getTime() !== todayMidnight.getTime()) {
        // Rebuild the viewing date, the date key, and the Hijri
        // string; skip the reload because loadSettingsAndLocation
        // runs right after and does a full refresh anyway.
        this.refreshViewingDate(true);
      }
    }

    this.loadSettingsAndLocation();

    // Force an immediate status + header refresh. The 60 s interval
    // is paused while the app is backgrounded, so without this the
    // header stays stale until the next tick.
    this.prayers = PrayerManager.updateStatuses(
      this.prayers, this.viewingDate, this.getLocationOffsetHours()
    );
    this.updateTodayHeaderData();
    this.refreshHijriDates();
    this.activeFloatingTab = 'home';
  }

  onBackPress(): boolean {
    NavHelper.prepareBackward();
    return false;
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

  // ============================================================
  // HIJRI DATE HELPERS
  // ============================================================

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

  // ============================================================
  // OFFSET LOOKUP
  // ============================================================

  private getLocationOffsetHours(): number {
    if (this.latitude === 0 && this.longitude === 0) return 0;
    return TimezoneResolver.effectiveOffsetForLocation(
      this.latitude, this.longitude, new Date()
    );
  }

  // ============================================================
  // DATE NAVIGATION
  // ============================================================

  private refreshViewingDate(skipReload: boolean = false): void {
    const d = new Date();
    d.setDate(d.getDate() + this.dateOffset);
    this.viewingDate = d;
    this.viewingDateKey = PrayerManager.getDateKeyForDate(d);

    const shifted = new Date(d);
    shifted.setDate(shifted.getDate() + this.hijriOffset);
    this.viewingHijriDate = DateHelper.getFormattedHijriDateFor(shifted);

    if (!skipReload) {
      this.prayers = PrayerManager.loadStateForDate(this.viewingDateKey, this.prayers, this.viewingDate);
      this.prayers = PrayerManager.updateStatuses(
        this.prayers, this.viewingDate, this.getLocationOffsetHours()
      );
      this.refreshPrayerTimes();
    }
  }

  private goToNextDay(): void { this.dateOffset += 1; this.refreshViewingDate(); }
  private goToPreviousDay(): void { this.dateOffset -= 1; this.refreshViewingDate(); }

  // ============================================================
  // SETTINGS + LOCATION
  // ============================================================

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

      if (!loc.isManual && !this.settingsLoaded) {
        this.fetchLocationInBackground();
      }

      this.prayers = PrayerManager.loadStateForDate(
        this.viewingDateKey, this.prayers, this.viewingDate
      );

      this.refreshPrayerTimes();
      this.updateTodayHeaderData();
      this.settingsLoaded = true;

      // Renew the notification queue every time settings or the app
      // open. Safe to call repeatedly — it cancels first, then
      // reschedules.
      await NotificationHelper.rescheduleAll();
    } finally {
      this.settingsLoading = false;
    }
  }

  // ============================================================
  // PRAYER CALCULATION
  // ============================================================

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

  // ============================================================
  // GPS
  // ============================================================

  private async fetchLocationInBackground(): Promise<void> {
    if (this.locationMode === LocationMode.MANUAL) return;
    try {
      const data: LocationData = await LocationHelper.fetchLocationData(getContext(this));
      this.latitude = data.latitude;
      this.longitude = data.longitude;
      this.currentLocation = data.cityName;
      this.isLoadingLocation = false;
      await LocationCache.save(data.latitude, data.longitude, data.cityName);
      this.refreshPrayerTimes();
      this.updateTodayHeaderData();
    } catch (err) {
      const error = err as Error;
      this.isLoadingLocation = false;
      if (this.currentLocation.toUpperCase().includes('DEFAULT')) {
        if (error.message === 'GPS_OFF') {
          await LocationHelper.showLocationDisabledDialog();
        } else if (error.message === 'PERMISSION_DENIED') {
          await LocationHelper.showPermissionDeniedDialog();
        }
      }
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
        let cityName = 'Manual Location';
        try { cityName = await LocationHelper.reverseGeocode(manual.lat, manual.lng); } catch (e) { }
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
      const data: LocationData = await LocationHelper.fetchLocationData(getContext(this));
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

  // ============================================================
  // SWIPE-TO-REFRESH
  // ============================================================

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

  // ============================================================
  // EVENT HANDLERS
  // ============================================================

  private togglePrayer(id: string): void {
    const target = this.prayers.find(p => p.id === id);
    if (!target || !PrayerManager.isPrayerCheckable(target, this.viewingDate)) return;

    this.prayers = this.prayers.map((p): PrayerModel => {
      if (p.id === id) {
        const updated: PrayerModel = {
          id: p.id, name: p.name, arabicName: p.arabicName,
          time: p.time, status: p.status, checked: !p.checked
        };
        return updated;
      }
      return p;
    });

    PrayerManager.saveStateForDate(this.viewingDateKey, this.prayers);
    this.prayers = PrayerManager.updateStatuses(
      this.prayers, this.viewingDate, this.getLocationOffsetHours()
    );

    // The Current / Next header always reflects TODAY. Toggling a
    // checkbox on a previous (or future) date must not touch it.
    if (this.dateOffset === 0) {
      this.updateTodayHeaderData();
    }
  }

  private closeBottomSheet(): void {
    animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
      this.showBottomSheet = false;
    });
  }

  private navigateToQibla(): void {
    this.closeBottomSheet();
    setTimeout(() => {
      NavHelper.prepare('compass', 'home');
      router.pushUrl({ url: 'pages/QiblaPage' })
        .catch((err: Error) => console.error('Navigation failed:', JSON.stringify(err)));
    }, 320);
  }

  private navigateToCustomize(): void {
    this.closeBottomSheet();
    setTimeout(() => {
      NavHelper.prepareForward();
      router.pushUrl({ url: 'pages/CustomizePage' })
        .catch((err: Error) => console.error('Navigation failed:', JSON.stringify(err)));
    }, 320);
  }

  private navigateToSettings(): void {
    this.closeBottomSheet();
    setTimeout(() => {
      NavHelper.prepareForward();
      router.pushUrl({ url: 'pages/SettingsPage' })
        .catch((err: Error) => console.error('Navigation failed:', JSON.stringify(err)));
    }, 320);
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
        context.terminateSelf().catch((err: Error) => console.error('Terminate failed:', JSON.stringify(err)));
      }
    }).catch((err: Error) => {
      console.error('Dialog error:', JSON.stringify(err));
    });
  }

  private onFloatingBarTap(tabId: string): void {
    if (tabId === 'home') {
      this.activeFloatingTab = 'home';
      return;
    }
    if (tabId === 'tasbih') {
      NavHelper.prepare('tasbih', 'home');
      router.pushUrl({ url: 'pages/TasbihPage' })
        .catch((err: Error) => console.error('Navigation failed:', JSON.stringify(err)));
      return;
    }
    if (tabId === 'compass') {
      this.navigateToQibla();
      return;
    }
    if (tabId === 'calendar') {
      NavHelper.prepare('calendar', 'home');
      router.pushUrl({ url: 'pages/HijriCalendarPage' })
        .catch((err: Error) => console.error('Navigation failed:', JSON.stringify(err)));
      return;
    }
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

  // ============================================================
  // BUILD
  // ============================================================

  build() {
    Stack() {
      Column() {
        this.HeaderWithHamburger()

        Refresh({ refreshing: $$this.isRefreshingHome }) {
          Scroll() {
            Column() {
              this.NextPrayerSection()

              if (this.calcSource === CalculationSource.LOCAL) {
                this.PrayersSection()
                if (this.showExtraTimings) this.ExtraTimingsSection()
              } else {
                this.ComingSoonCard()
              }

              if (this.showIslamicEvents) this.ImportantDatesCard()

              Column().height(130)
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

      this.FloatingBar()

      if (this.showBottomSheet) {
        Column()
          .width('100%').height('100%')
          .backgroundColor(this.colors.overlayDim)
          .onClick(() => { this.closeBottomSheet(); })
          .transition({ type: TransitionType.Insert, opacity: 0 })
          .transition({ type: TransitionType.Delete, opacity: 1 })
      }

      if (this.showBottomSheet) {
        Column() {
          Row().width(40).height(4).backgroundColor(this.colors.overlayDimSoft)
            .borderRadius(2).margin({ top: 8 })

          Row() {
            Text('Sirat').fontSize(24).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
            Text('Companion').fontSize(24).fontWeight(FontWeight.Bold).fontColor(this.colors.accentGold)
              .margin({ left: 8 })
          }
          .width('100%').padding({ top: 16, bottom: 16 }).justifyContent(FlexAlign.Center)

          Divider().color(this.colors.borderSoft).width('80%').margin({ bottom: 16 })

          Column() {
            this.BottomSheetItem('✏️', this.tr('title_customize'), () => { this.navigateToCustomize(); })
            this.BottomSheetItem('⚙️', this.tr('title_settings'), () => { this.navigateToSettings(); })
            this.BottomSheetItem('🚪', this.tr('exit'), () => {
              this.closeBottomSheet();
              setTimeout(() => { this.exitApp(); }, 320);
            })
          }
          .width('100%').padding({ left: 16, right: 16 })

          Blank()
        }
        .width('100%').height(280)
        .backgroundColor(this.colors.cardDark)
        .borderRadius({ topLeft: Theme.radiusLarge, topRight: Theme.radiusLarge })
        .shadow({ radius: 16, color: this.colors.shadowFloating, offsetX: 0, offsetY: -4 })
        .position({ bottom: 0 })
        .transition({ type: TransitionType.Insert, translate: { x: 0, y: 280 } })
        .transition({ type: TransitionType.Delete, translate: { x: 0, y: 280 } })
      }
    }
    .width('100%').height('100%')
    .backgroundColor(this.colors.primaryGreen)
    .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  // ============================================================
  // FLOATING BAR
  // ============================================================

  @Builder
  FloatingBar() {
    Row() {
      Row() {
        Column() {
          Text('🏠').fontSize(22).opacity(this.activeFloatingTab === 'home' ? 1.0 : 0.7)
          Text(this.tr('tab_home'))
            .fontSize(10)
            .fontWeight(this.activeFloatingTab === 'home' ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.activeFloatingTab === 'home'
              ? (this.isDarkMode() ? '#4ADE80' : '#0F5132')
              : (this.isDarkMode() ? 'rgba(241,245,249,0.65)' : 'rgba(26,26,26,0.55)'))
            .margin({ top: 2 })
        }
        .layoutWeight(1).height('100%').justifyContent(FlexAlign.Center)
        .onClick(() => { this.onFloatingBarTap('home'); })

        Divider().vertical(true).height(28)
          .color(this.isDarkMode() ? 'rgba(74,222,128,0.20)' : 'rgba(15,81,50,0.12)')

        Column() {
          Text('📿').fontSize(22).opacity(this.activeFloatingTab === 'tasbih' ? 1.0 : 0.7)
          Text(this.tr('tab_tasbih'))
            .fontSize(10)
            .fontWeight(this.activeFloatingTab === 'tasbih' ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.activeFloatingTab === 'tasbih'
              ? (this.isDarkMode() ? '#4ADE80' : '#0F5132')
              : (this.isDarkMode() ? 'rgba(241,245,249,0.65)' : 'rgba(26,26,26,0.55)'))
            .margin({ top: 2 })
        }
        .layoutWeight(1).height('100%').justifyContent(FlexAlign.Center)
        .onClick(() => { this.onFloatingBarTap('tasbih'); })

        Divider().vertical(true).height(28)
          .color(this.isDarkMode() ? 'rgba(74,222,128,0.20)' : 'rgba(15,81,50,0.12)')

        Column() {
          Text('🧭').fontSize(22).opacity(this.activeFloatingTab === 'compass' ? 1.0 : 0.7)
          Text(this.tr('tab_compass'))
            .fontSize(10)
            .fontWeight(this.activeFloatingTab === 'compass' ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.activeFloatingTab === 'compass'
              ? (this.isDarkMode() ? '#4ADE80' : '#0F5132')
              : (this.isDarkMode() ? 'rgba(241,245,249,0.65)' : 'rgba(26,26,26,0.55)'))
            .margin({ top: 2 })
        }
        .layoutWeight(1).height('100%').justifyContent(FlexAlign.Center)
        .onClick(() => { this.onFloatingBarTap('compass'); })

        Divider().vertical(true).height(28)
          .color(this.isDarkMode() ? 'rgba(74,222,128,0.20)' : 'rgba(15,81,50,0.12)')

        Column() {
          Text('📅').fontSize(22).opacity(this.activeFloatingTab === 'calendar' ? 1.0 : 0.7)
          Text(this.tr('tab_calendar'))
            .fontSize(10)
            .fontWeight(this.activeFloatingTab === 'calendar' ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.activeFloatingTab === 'calendar'
              ? (this.isDarkMode() ? '#4ADE80' : '#0F5132')
              : (this.isDarkMode() ? 'rgba(241,245,249,0.65)' : 'rgba(26,26,26,0.55)'))
            .margin({ top: 2 })
        }
        .layoutWeight(1).height('100%').justifyContent(FlexAlign.Center)
        .onClick(() => { this.onFloatingBarTap('calendar'); })
      }
      .width('92%').height(68)
      .backgroundBlurStyle(BlurStyle.Thin, {
        colorMode: this.isDarkMode() ? ThemeColorMode.DARK : ThemeColorMode.LIGHT,
        adaptiveColor: AdaptiveColor.DEFAULT,
        scale: 1.0
      })
      .backgroundColor(this.isDarkMode() ? 'rgba(20, 27, 46, 0.50)' : 'rgba(255, 255, 255, 0.35)')
      .borderRadius(34)
      .border({
        width: 1,
        color: this.isDarkMode() ? 'rgba(74, 222, 128, 0.35)' : 'rgba(255, 255, 255, 0.65)'
      })
      .shadow({
        radius: 28,
        color: this.isDarkMode() ? 'rgba(0, 0, 0, 0.50)' : 'rgba(0, 0, 0, 0.14)',
        offsetX: 0, offsetY: 10
      })
    }
    .width('100%').justifyContent(FlexAlign.Center)
    .position({ bottom: 24 })
  }

  // ============================================================
  // HEADER
  // ============================================================

  @Builder
  HeaderWithHamburger() {
    Column() {
      Row() {
        Column() {
          Row() {
            Text('🌙').fontSize(12)
            Text(this.hijriDateString)
              .fontSize(13).fontColor(this.colors.accentGold).fontWeight(FontWeight.Medium)
              .margin({ left: 6 }).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .height(30).padding({ left: 12, right: 12 })
          .backgroundColor(this.colors.cardDark).borderRadius(15)
          .border({ width: 1, color: this.colors.borderSoft })
          .alignSelf(ItemAlign.Start)

          Row() {
            Text('📍').fontSize(15)
            Text(this.currentLocation)
              .fontSize(16).fontColor(this.colors.textWhite).fontWeight(FontWeight.Bold)
              .margin({ left: 8 }).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            if (this.isLoadingLocation) {
              LoadingProgress().width(16).height(16).color(this.colors.accentGold).margin({ left: 8 })
            } else {
              Text('📡').fontSize(16).margin({ left: 8 })
                .onClick(() => { this.refreshLocation(); })
            }
          }
          .height(38).padding({ left: 14, right: 12 })
          .backgroundColor(this.colors.cardDark).borderRadius(19)
          .border({ width: 1, color: this.colors.borderSoft })
          .margin({ top: 6 }).alignSelf(ItemAlign.Start)
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        Text('☰').fontSize(28).fontColor(this.colors.textWhite)
          .onClick(() => { this.showBottomSheet = !this.showBottomSheet; })
      }
      .width('100%').padding({ top: 32, bottom: 8 }).alignItems(VerticalAlign.Top)

      Column() {
        Row() {
          Text(this.tr('current_prayer'))
            .fontSize(12).fontColor(this.colors.textMuted).letterSpacing(1).fontWeight(FontWeight.Medium)
          Blank()
          Row() {
            Text(this.translateEventName(this.todayCurrentPrayerName))
              .fontSize(16).fontColor(this.colors.accentGold).fontWeight(FontWeight.Bold)
            Text('   ')
            Text(this.todayCurrentPrayerTime)
              .fontSize(16).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
          }
        }
        .width('100%').padding({ top: 12, bottom: 12, left: 16, right: 16 })
        .backgroundColor(this.colors.cardDark).borderRadius(Theme.radiusMedium)
        .border({ width: 1, color: this.colors.borderSoft })
      }
      .width('100%').margin({ top: 4, bottom: 12 })

      Row() {
        Row() {
          Text('🕌').fontSize(13).margin({ right: 6 })
          Text(SettingsHelper.getCalcMethodShortLabel(this.calcMethod))
            .fontSize(12).fontColor(this.colors.accentGold).fontWeight(FontWeight.Medium)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
        }
        .layoutWeight(1).height(34).padding({ left: 12, right: 12 })
        .backgroundColor(this.colors.cardDark).borderRadius(17)
        .border({ width: 1, color: this.colors.borderSoft }).margin({ right: 4 })
        .onClick(() => { this.navigateToSettings(); })

        Row() {
          Text('🌅').fontSize(13).margin({ right: 6 })
          Text(SettingsHelper.getAsrRuleShortLabel(this.asrRule))
            .fontSize(12).fontColor(this.colors.accentGold).fontWeight(FontWeight.Medium)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
        }
        .layoutWeight(1).height(34).padding({ left: 12, right: 12 })
        .backgroundColor(this.colors.cardDark).borderRadius(17)
        .border({ width: 1, color: this.colors.borderSoft }).margin({ right: 4 })
        .onClick(() => { this.navigateToSettings(); })

        Row() {
          Text('🌐').fontSize(13).margin({ right: 6 })
          Text(SettingsHelper.getCalcSourceShortLabel(this.calcSource))
            .fontSize(12).fontColor(this.colors.accentGold).fontWeight(FontWeight.Medium)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
        }
        .layoutWeight(1).height(34).padding({ left: 12, right: 12 })
        .backgroundColor(this.colors.cardDark).borderRadius(17)
        .border({ width: 1, color: this.colors.borderSoft })
        .onClick(() => { this.navigateToSettings(); })
      }
      .width('100%').padding({ bottom: 8 }).alignItems(VerticalAlign.Center)
    }
    .width('100%').padding({ left: 16, right: 16 }).backgroundColor(this.colors.primaryGreen)
  }

  // ============================================================
  // NEXT PRAYER
  // ============================================================

  @Builder
  NextPrayerSection() {
    Column() {
      Row() {
        Text(this.tr('next_prayer'))
          .fontSize(12).fontColor(this.colors.textMuted).letterSpacing(1).fontWeight(FontWeight.Medium)
        Blank()
        Row() {
          Text(this.translateEventName(this.todayNextPrayerName))
            .fontSize(16).fontColor(this.colors.accentGold).fontWeight(FontWeight.Bold)
          Text('   ')
          Text(this.todayNextPrayerTime)
            .fontSize(16).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
        }
      }
      .width('100%').padding({ top: 12, bottom: 12, left: 16, right: 16 })
      .backgroundColor(this.colors.cardDark).borderRadius(Theme.radiusMedium)
      .border({ width: 1, color: this.colors.borderSoft })
    }
    .width('100%').padding({ left: 16, right: 16 }).margin({ top: 4, bottom: 12 })
  }

  // ============================================================
  // PRAYERS LIST
  // ============================================================

  @Builder
  PrayersSection() {
    Column() {
      Row({ space: 8 }) {
        Text(this.tr('todays_prayers'))
          .fontSize(14).fontColor(this.colors.textWhite).fontWeight(FontWeight.Bold)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`${this.prayers.filter(p => p.checked).length} / ${this.prayers.length}`)
          .fontSize(14).fontColor(this.colors.textWhite).fontWeight(FontWeight.Bold)
          .direction(Direction.Ltr)
      }
      .width('100%').justifyContent(FlexAlign.Start).padding({ bottom: 8 })

      Row() {
        Text('◀')
          .fontSize(14).fontColor(this.colors.accentGold)
          .width(36).height(36).textAlign(TextAlign.Center).borderRadius(18)
          .backgroundColor(this.colors.cardDark).border({ width: 1, color: this.colors.borderSoft })
          .onClick(() => { this.goToPreviousDay(); })

        Text(this.viewingHijriDate)
          .fontSize(13).fontColor(this.colors.accentGold).fontWeight(FontWeight.Medium)
          .layoutWeight(1).textAlign(TextAlign.Center).maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text('▶')
          .fontSize(14).fontColor(this.colors.accentGold)
          .width(36).height(36).textAlign(TextAlign.Center).borderRadius(18)
          .backgroundColor(this.colors.cardDark).border({ width: 1, color: this.colors.borderSoft })
          .onClick(() => { this.goToNextDay(); })
      }
      .width('100%').padding({ bottom: 12 }).alignItems(VerticalAlign.Center)
      .direction(Direction.Ltr)

      Column() {
        ForEach(this.prayers, (prayer: PrayerModel) => {
          this.PrayerItem(prayer)
        }, (prayer: PrayerModel) => `${this.viewingDateKey}-${prayer.id}-${prayer.name}-${prayer.status}-${prayer.checked ? '1' : '0'}-${prayer.time}`)
      }
      .width('100%').backgroundColor(this.colors.cardDark).borderRadius(Theme.radiusMedium)
      .border({ width: 1, color: this.colors.borderSoft })
      .padding({ left: 4, right: 4, top: 4, bottom: 4 })
    }
    .width('100%').padding({ left: 16, right: 16 }).alignItems(HorizontalAlign.Start)
    .margin({ bottom: 12 })
  }

  @Builder
  PrayerItem(prayer: PrayerModel) {
    Row() {
      Checkbox({ name: prayer.id })
        .width(20).height(20).selectedColor(this.colors.accentGold)
        .select(prayer.checked || false)
        .enabled(PrayerManager.isPrayerCheckable(prayer, this.viewingDate))
        .onChange((value: boolean) => {
          if (PrayerManager.isPrayerCheckable(prayer, this.viewingDate)) {
            this.togglePrayer(prayer.id);
          }
        })

      Column() {
        Row() {
          Text(this.translatePrayerName(prayer.name))
            .fontSize(16).fontColor(this.colors.textWhite)
            .fontWeight(prayer.checked ? FontWeight.Normal : FontWeight.Medium)
            .opacity(prayer.checked ? 0.5 : 1.0)
          Text('  ')
          Text(prayer.arabicName).fontSize(14).fontColor(this.colors.textMuted)
        }
        Text(this.getStatusLabel(prayer.status))
          .fontSize(11).fontColor(this.getStatusColor(prayer.status))
          .letterSpacing(1).margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)

      Text(prayer.time).fontSize(16).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
    }
    .width('100%').padding(12).justifyContent(FlexAlign.SpaceBetween)
    .borderRadius(Theme.radiusSmall)
    .backgroundColor(prayer.checked ? this.colors.tintSoft : 'transparent')
    .margin({ bottom: 4 })
  }

  // ============================================================
  // EXTRA TIMINGS
  // ============================================================

  @Builder
  ExtraTimingsSection() {
    Column() {
      Text(this.tr('extra_timings'))
        .fontSize(16).fontColor(this.colors.textWhite).fontWeight(FontWeight.Bold)
        .width('100%').padding({ left: 16, right: 16, bottom: 12 })

      Column() {
        ForEach(this.extraTimings, (timing: ExtraTiming) => {
          this.ExtraTimingItem(timing)
        }, (timing: ExtraTiming) => `${timing.id}-${timing.time}`)
      }
      .width('100%').backgroundColor(this.colors.cardDark).borderRadius(Theme.radiusMedium)
      .border({ width: 1, color: this.colors.borderSoft })
      .padding({ top: 4, bottom: 4, left: 4, right: 4 })
    }
    .width('100%').padding({ left: 16, right: 16 }).margin({ bottom: 16 })
  }

  @Builder
  ExtraTimingItem(timing: ExtraTiming) {
    Row() {
      Text(timing.icon ?? '•').fontSize(22).width(36).textAlign(TextAlign.Center)
      Column() {
        Row() {
          Text(this.translateTimingName(timing.name)).fontSize(16).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
          Text('  ')
          Text(timing.arabicName).fontSize(13).fontColor(this.colors.textMuted)
        }
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)

      Text(timing.time).fontSize(16).fontColor(this.colors.accentGoldLight).fontWeight(FontWeight.Medium)
    }
    .width('100%').padding({ top: 10, bottom: 10, left: 8, right: 12 })
    .alignItems(VerticalAlign.Center).borderRadius(Theme.radiusSmall).margin({ bottom: 2 })
  }

  // ============================================================
  // EVENTS CARD
  // ============================================================

  @Builder
  ImportantDatesCard() {
    Column() {
      Row() {
        Text('📅').fontSize(16)
          .margin({ left: this.isRtl() ? 8 : 0, right: this.isRtl() ? 0 : 8 })
        Text(this.tr('upcoming_islamic_events'))
          .fontSize(14).fontColor(this.colors.accentGold).fontWeight(FontWeight.Bold).letterSpacing(1.5)
      }
      .width('100%').justifyContent(FlexAlign.Start).padding({ left: 4, bottom: 14 })

      Column() {
        if (this.upcomingImportantDates.length === 0) {
          Text(this.tr('loading_location')).fontSize(14).fontColor(this.colors.textMuted)
        } else {
          Text(this.translateUpcomingEventName(this.upcomingImportantDates[0]).toUpperCase())
            .fontSize(14).fontColor(this.colors.accentGoldLight).fontWeight(FontWeight.Medium).textAlign(TextAlign.Center)
          Text(this.upcomingImportantDates[0].hijriDate)
            .fontSize(12).fontColor(this.colors.textMuted).margin({ top: 4 }).textAlign(TextAlign.Center)

          if (this.upcomingImportantDates.length > 1) {
            Divider().width('80%').color(this.colors.borderSoft).margin({ top: 14, bottom: 14 })
            Text(this.translateUpcomingEventName(this.upcomingImportantDates[1]).toUpperCase())
              .fontSize(14).fontColor(this.colors.accentGold).fontWeight(FontWeight.Medium).textAlign(TextAlign.Center)
            Text(this.upcomingImportantDates[1].hijriDate)
              .fontSize(12).fontColor(this.colors.textMuted).margin({ top: 4 }).textAlign(TextAlign.Center)
          }
        }
      }
      .width('100%').padding(20).backgroundColor(this.colors.cardDark)
      .borderRadius(Theme.radiusLarge).border({ width: 1, color: this.colors.borderSoft })
      .shadow({ radius: 12, color: this.colors.shadowCard, offsetX: 0, offsetY: 4 })
      .alignItems(HorizontalAlign.Center)
    }
    .width('92%').padding({ left: 4, right: 4 }).margin({ top: 4, bottom: 16 })
    .alignItems(HorizontalAlign.Start)
  }

  // ============================================================
  // COMING SOON CARD
  // ============================================================

  @Builder
  ComingSoonCard() {
    Column() {
      Text('🌐').fontSize(56).margin({ bottom: 12 })
      Text(this.tr('online_prayer_times')).fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
      Text(this.tr('coming_soon')).fontSize(13).fontColor(this.colors.accentGold).letterSpacing(1).margin({ top: 4 })
      Divider().width('60%').color(this.colors.borderSoft).margin({ top: 16, bottom: 16 })
      Text(this.tr('online_switch_hint'))
        .fontSize(12).fontColor(this.colors.textMuted).textAlign(TextAlign.Center).lineHeight(18).maxLines(4)
    }
    .width('92%').padding(28).backgroundColor(this.colors.cardDark)
    .borderRadius(Theme.radiusLarge).border({ width: 1, color: this.colors.borderSoft })
    .shadow({ radius: 12, color: this.colors.shadowCard, offsetX: 0, offsetY: 4 })
    .margin({ top: 4, bottom: 24 }).alignItems(HorizontalAlign.Center)
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
    .width('100%').padding({ top: 12, bottom: 12, left: 16 })
    .borderRadius(Theme.radiusSmall).onClick(() => { onClick(); })
  }
}