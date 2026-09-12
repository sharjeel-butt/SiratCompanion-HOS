// entry/src/main/ets/pages/Index.ets

import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { mediaquery } from '@kit.ArkUI';
import { Theme, ThemeColors, ThemeMode } from '../common/Theme';
import { Prayer, ExtraTiming } from '../models/Prayer';
import { DateHelper } from '../utils/DateUtils';
import { LocationHelper, LocationData } from '../utils/LocationUtils';
import { UpcomingImportantDate } from '../models/DateModels';
import { PrayerTimeCalculator, CalculationMethod, AsrShadowRule, DailyPrayerTimes } from '../utils/PrayerTimeCalculator';
import { PrayerManager } from '../utils/PrayerManager';
import { SettingsHelper, PrayerOffsets } from '../utils/SettingsHelper';
import { LocationCache, FALLBACK_LOCATION } from '../utils/LocationCache';
import { CalculationSource, LocationMode } from '../models/SettingsModels';
import { STORAGE_KEY_THEME_MODE } from '../common/StorageKeys';

interface DialogResult {
  index: number;
}

@Entry
@Component
struct Index {

  // ============================================================
  // THEME
  // ============================================================

  @StorageLink(STORAGE_KEY_THEME_MODE)
  @Watch('onThemeModeChanged')
  themeMode: string = ThemeMode.SYSTEM;

  @State colors: ThemeColors = Theme.getColors(ThemeMode.LIGHT, false);
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

  @State prayers: Prayer[] = [
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

  // ---- Floating bar ----
  @State activeFloatingTab: string = 'home';

  private statusTimerId: number = -1;
  private settingsLoaded: boolean = false;

  // ============================================================
  // THEME HELPERS
  // ============================================================

  private isSystemDark(): boolean {
    try {
      const listener = mediaquery.matchMediaSync('(dark-mode: true)');
      return listener.matches;
    } catch (err) {
      return false;
    }
  }

  private isDarkMode(): boolean {
    if (this.themeMode === ThemeMode.DARK) return true;
    if (this.themeMode === ThemeMode.LIGHT) return false;
    return this.isSystemDark();
  }

  private applyTheme(): void {
    this.colors = Theme.getColors(this.themeMode, this.isSystemDark());
  }

  private onThemeModeChanged(): void {
    this.colors = Theme.getColors(this.themeMode, this.isSystemDark());
  }

  // ============================================================
  // LIFECYCLE
  // ============================================================

  aboutToAppear(): void {
    this.applyTheme();

    try {
      this.systemDarkListener = mediaquery.matchMediaSync('(dark-mode: true)');
      this.systemDarkListener.on('change', (result: mediaquery.MediaQueryResult) => {
        if (this.themeMode === ThemeMode.SYSTEM) {
          this.colors = Theme.getColors(this.themeMode, result.matches);
        }
      });
    } catch (err) { /* ignore */ }

    this.hijriDateString = DateHelper.getFormattedHijriDate();
    this.upcomingImportantDates = DateHelper.getUpcomingImportantDates();

    this.refreshViewingDate(true);
    this.initialize();

    this.statusTimerId = setInterval(() => {
      if (this.dateOffset === 0) {
        this.prayers = PrayerManager.updateStatuses(this.prayers, this.viewingDate);
      }
      this.updateTodayHeaderData();
    }, 60000);
  }

  aboutToDisappear(): void {
    if (this.systemDarkListener) {
      this.systemDarkListener.off('change');
      this.systemDarkListener = null;
    }
    if (this.statusTimerId !== -1) {
      clearInterval(this.statusTimerId);
      this.statusTimerId = -1;
    }
  }

  onPageShow(): void {
    this.applyTheme();
    this.loadSettingsAndLocation();
    this.prayers = PrayerManager.updateStatuses(this.prayers, this.viewingDate);
    this.activeFloatingTab = 'home';
  }

  private async initialize(): Promise<void> {
    await this.loadSettingsAndLocation();
  }

  // ============================================================
  // DATE NAVIGATION
  // ============================================================

  private refreshViewingDate(skipReload: boolean = false): void {
    const d = new Date();
    d.setDate(d.getDate() + this.dateOffset);
    this.viewingDate = d;
    this.viewingDateKey = PrayerManager.getDateKeyForDate(d);
    this.viewingHijriDate = DateHelper.getFormattedHijriDateFor(d);

    if (!skipReload) {
      this.prayers = PrayerManager.loadStateForDate(this.viewingDateKey, this.prayers, this.viewingDate);
      this.prayers = PrayerManager.updateStatuses(this.prayers, this.viewingDate);
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

  // ============================================================
  // SETTINGS + LOCATION
  // ============================================================

  private async loadSettingsAndLocation(): Promise<void> {
    const data = await SettingsHelper.loadAll();
    const mode = await SettingsHelper.getLocationMode();

    this.calcMethod = data.method;
    this.asrRule    = data.asr;
    this.calcSource = data.source;
    this.locationMode = mode;

    this.showExtraTimings  = data.showExtraTimings;
    this.showIslamicEvents = data.showIslamicEvents;

    this.offsets = await SettingsHelper.getPrayerOffsets();

    if (mode === LocationMode.MANUAL) {
      const coords = await SettingsHelper.getManualCoords();
      this.latitude = coords.lat;
      this.longitude = coords.lng;
      if (coords.lat !== 0 || coords.lng !== 0) {
        const city = coords.cityName.length > 0 ? coords.cityName : 'Manual Location';
        this.currentLocation = `${city} (Manual)`;
      } else {
        this.currentLocation = 'Set Manual Location in Settings';
      }
      this.isLoadingLocation = false;
    } else {
      const cached = await LocationCache.load();
      if (cached) {
        this.latitude = cached.latitude;
        this.longitude = cached.longitude;
        this.currentLocation = cached.cityName;
      } else {
        this.latitude = FALLBACK_LOCATION.latitude;
        this.longitude = FALLBACK_LOCATION.longitude;
        this.currentLocation = FALLBACK_LOCATION.cityName;
      }
      if (!this.settingsLoaded) {
        this.fetchLocationInBackground();
      }
    }

    this.prayers = PrayerManager.loadStateForDate(
      this.viewingDateKey,
      this.prayers,
      this.viewingDate
    );

    this.refreshPrayerTimes();
    this.updateTodayHeaderData();
    this.settingsLoaded = true;
  }

  // ============================================================
  // TODAY'S HEADER DATA
  // ============================================================

  private updateTodayHeaderData(): void {
    if (this.latitude === 0 && this.longitude === 0) return;
    if (this.calcSource !== CalculationSource.LOCAL) return;

    try {
      const times: DailyPrayerTimes = PrayerTimeCalculator.calculateWithDeviceTimezone(
        new Date(), this.latitude, this.longitude, this.calcMethod, this.asrRule
      );

      const todayPrayers: Prayer[] = [
        { id: 'fajr',    name: 'Fajr',    arabicName: 'الفجر',   time: times.fajr,    status: 'abbreviation', checked: false },
        { id: 'dhuhr',   name: 'Dhuhr',   arabicName: 'الظهر',   time: times.dhuhr,   status: 'abbreviation', checked: false },
        { id: 'asr',     name: 'Asr',     arabicName: 'العصر',   time: times.asr,     status: 'abbreviation', checked: false },
        { id: 'maghrib', name: 'Maghrib', arabicName: 'المغرب',  time: times.maghrib, status: 'abbreviation', checked: false },
        { id: 'isha',    name: 'Isha',    arabicName: 'العشاء',  time: times.isha,    status: 'abbreviation', checked: false }
      ];

      const withOffsets = PrayerManager.applyTimesToPrayers(todayPrayers, times, this.offsets, new Date());
      const withStatus = PrayerManager.updateStatuses(withOffsets, new Date());

      const current = PrayerManager.getCurrentPrayer(withStatus);
      const next = PrayerManager.getNextPrayer(withStatus);

      if (current) {
        this.todayCurrentPrayerName = current.name;
        this.todayCurrentPrayerTime = current.time;
      }
      if (next) {
        this.todayNextPrayerName = next.name;
        this.todayNextPrayerTime = next.time;
      }
    } catch (err) {
      console.error('Failed to update today header:', JSON.stringify(err));
    }
  }

  // ============================================================
  // PRAYER CALCULATION
  // ============================================================

  private refreshPrayerTimes(): void {
    if (this.latitude === 0 && this.longitude === 0) return;
    if (this.calcSource !== CalculationSource.LOCAL) return;

    try {
      const times: DailyPrayerTimes = PrayerTimeCalculator.calculateWithDeviceTimezone(
        this.viewingDate, this.latitude, this.longitude, this.calcMethod, this.asrRule
      );

      const updatedPrayers = PrayerManager.applyTimesToPrayers(
        this.prayers, times, this.offsets, this.viewingDate
      );
      this.extraTimings = PrayerManager.applyTimesToExtraTimings(
        this.extraTimings, times, this.offsets
      );
      this.prayers = PrayerManager.updateStatuses(updatedPrayers, this.viewingDate);
    } catch (err) {
      console.error(`Prayer calculation failed: ${(err as Error).message}`);
    }
  }

  // ============================================================
  // GPS FETCH
  // ============================================================

  private async fetchLocationInBackground(): Promise<void> {
    if (this.locationMode === LocationMode.MANUAL) return;
    try {
      const data: LocationData = await LocationHelper.fetchLocationData(getContext(this));
      const changed =
        Math.abs(data.latitude - this.latitude) > 0.01 ||
          Math.abs(data.longitude - this.longitude) > 0.01 ||
          data.cityName !== this.currentLocation;

      this.latitude = data.latitude;
      this.longitude = data.longitude;
      this.currentLocation = data.cityName;
      this.isLoadingLocation = false;
      LocationCache.save(data.latitude, data.longitude, data.cityName);

      if (changed) {
        this.refreshPrayerTimes();
        this.updateTodayHeaderData();
      }
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

  // ============================================================
  // REFRESH LOCATION
  // ============================================================

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
        this.currentLocation = `${cityName} (Manual)`;
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
      LocationCache.save(data.latitude, data.longitude, data.cityName);
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
  // EVENT HANDLERS
  // ============================================================

  private togglePrayer(id: string): void {
    const target = this.prayers.find(p => p.id === id);
    if (!target || !PrayerManager.isPrayerCheckable(target, this.viewingDate)) return;

    this.prayers = this.prayers.map((p): Prayer => {
      if (p.id === id) {
        return {
          id: p.id, name: p.name, arabicName: p.arabicName,
          time: p.time, status: p.status, checked: !p.checked
        } as Prayer;
      }
      return p;
    });

    PrayerManager.saveStateForDate(this.viewingDateKey, this.prayers);
    this.prayers = PrayerManager.updateStatuses(this.prayers, this.viewingDate);
  }

  private closeBottomSheet(): void {
    animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
      this.showBottomSheet = false;
    });
  }

  private navigateToQibla(): void {
    this.closeBottomSheet();
    setTimeout(() => {
      router.pushUrl({ url: 'pages/QiblaPage' })
        .catch((err: Error) => console.error('Navigation failed:', JSON.stringify(err)));
    }, 320);
  }

  private navigateToCustomize(): void {
    this.closeBottomSheet();
    setTimeout(() => {
      router.pushUrl({ url: 'pages/CustomizePage' })
        .catch((err: Error) => console.error('Navigation failed:', JSON.stringify(err)));
    }, 320);
  }

  private navigateToSettings(): void {
    this.closeBottomSheet();
    setTimeout(() => {
      router.pushUrl({ url: 'pages/SettingsPage' })
        .catch((err: Error) => console.error('Navigation failed:', JSON.stringify(err)));
    }, 320);
  }

  private exitApp(): void {
    promptAction.showDialog({
      title: 'Exit',
      message: 'Are you sure you want to exit Sirat Companion?',
      buttons: [
        { text: 'Cancel', color: this.colors.dialogCancel },
        { text: 'Exit', color: this.colors.accentGold }
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
      router.pushUrl({ url: 'pages/TasbihPage' })
        .catch((err: Error) => console.error('Navigation failed:', JSON.stringify(err)));
      return;
    }
    if (tabId === 'compass') {
      this.navigateToQibla();
      return;
    }
  }

  // ============================================================
  // UI LOOKUPS
  // ============================================================

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
      case 'next':    return 'NEXT';
      case 'pray':    return 'Pray';
      case 'both':    return 'Pray  ·  NEXT';
      case 'prayed':  return '✓ Prayed';
      case 'express': return 'Express';
      default:        return '';
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  build() {
    Stack() {
      Column() {
        this.HeaderWithHamburger();

        Scroll() {
          Column() {
            this.NextPrayerSection();

            if (this.calcSource === CalculationSource.LOCAL) {
              this.PrayersSection();
              if (this.showExtraTimings) {
                this.ExtraTimingsSection();
              }
            } else {
              this.ComingSoonCard();
            }

            if (this.showIslamicEvents) {
              this.ImportantDatesCard();
            }

            // Bottom spacer — leaves room for the floating bar
            Column().height(110);
          }
          .width('100%')
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor(this.colors.primaryGreen)
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%').height('100%').backgroundColor(this.colors.primaryGreen)

      // ============================================================
      // FLOATING BAR — centered + frosted glass (3 tabs)
      // ============================================================
      Row() {
        Row() {
          // ---- Home ----
          Column() {
            Text('🏠')
              .fontSize(24)
              .opacity(this.activeFloatingTab === 'home' ? 1.0 : 0.7)

            Text('Home')
              .fontSize(11)
              .fontWeight(this.activeFloatingTab === 'home' ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.activeFloatingTab === 'home'
                ? (this.isDarkMode() ? '#4ADE80' : '#0F5132')
                : (this.isDarkMode() ? 'rgba(241,245,249,0.65)' : 'rgba(26,26,26,0.55)'))
              .margin({ top: 3 })
          }
          .layoutWeight(1)
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .onClick(() => { this.onFloatingBarTap('home'); })

          // Divider
          Divider()
            .vertical(true)
            .height(28)
            .color(this.isDarkMode() ? 'rgba(74,222,128,0.20)' : 'rgba(15,81,50,0.12)')

          // ---- Tasbih ----
          Column() {
            Text('📿')
              .fontSize(24)
              .opacity(this.activeFloatingTab === 'tasbih' ? 1.0 : 0.7)

            Text('Tasbih')
              .fontSize(11)
              .fontWeight(this.activeFloatingTab === 'tasbih' ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.activeFloatingTab === 'tasbih'
                ? (this.isDarkMode() ? '#4ADE80' : '#0F5132')
                : (this.isDarkMode() ? 'rgba(241,245,249,0.65)' : 'rgba(26,26,26,0.55)'))
              .margin({ top: 3 })
          }
          .layoutWeight(1)
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .onClick(() => { this.onFloatingBarTap('tasbih'); })

          // Divider
          Divider()
            .vertical(true)
            .height(28)
            .color(this.isDarkMode() ? 'rgba(74,222,128,0.20)' : 'rgba(15,81,50,0.12)')

          // ---- Compass ----
          Column() {
            Text('🧭')
              .fontSize(24)
              .opacity(this.activeFloatingTab === 'compass' ? 1.0 : 0.7)

            Text('Compass')
              .fontSize(11)
              .fontWeight(this.activeFloatingTab === 'compass' ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.activeFloatingTab === 'compass'
                ? (this.isDarkMode() ? '#4ADE80' : '#0F5132')
                : (this.isDarkMode() ? 'rgba(241,245,249,0.65)' : 'rgba(26,26,26,0.55)'))
              .margin({ top: 3 })
          }
          .layoutWeight(1)
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .onClick(() => { this.onFloatingBarTap('compass'); })
        }
        .width('84%')
        .height(68)
        .backgroundBlurStyle(
          BlurStyle.Thin,
          {
            colorMode: this.isDarkMode() ? ThemeColorMode.DARK : ThemeColorMode.LIGHT,
            adaptiveColor: AdaptiveColor.DEFAULT,
            scale: 1.0
          }
        )
        .backgroundColor(
          this.isDarkMode()
            ? 'rgba(20, 27, 46, 0.50)'
            : 'rgba(255, 255, 255, 0.35)'
        )
        .borderRadius(34)
        .border({
          width: 1,
          color: this.isDarkMode()
            ? 'rgba(74, 222, 128, 0.35)'
            : 'rgba(255, 255, 255, 0.65)'
        })
        .shadow({
          radius: 28,
          color: this.isDarkMode()
            ? 'rgba(0, 0, 0, 0.50)'
            : 'rgba(0, 0, 0, 0.14)',
          offsetX: 0,
          offsetY: 10
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .position({ bottom: 24 })

      // Dimmer
      if (this.showBottomSheet) {
        Column()
          .width('100%').height('100%')
          .backgroundColor(this.colors.overlayDim)
          .onClick(() => { this.closeBottomSheet(); })
          .transition({ type: TransitionType.Insert, opacity: 0 })
          .transition({ type: TransitionType.Delete, opacity: 1 })
      }

      // Bottom sheet
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
            this.BottomSheetItem('✏️', 'Customize', () => { this.navigateToCustomize(); })
            this.BottomSheetItem('⚙️', 'Settings', () => { this.navigateToSettings(); })
            this.BottomSheetItem('🚪', 'Exit', () => {
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
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  // ============================================================
  // HEADER
  // ============================================================

  @Builder
  HeaderWithHamburger() {
    Column() {
      Row() {
        Column() {
          // Date pill
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

          // Location pill
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

      // Current Prayer card
      Column() {
        Row() {
          Text('CURRENT PRAYER')
            .fontSize(12).fontColor(this.colors.textMuted).letterSpacing(2).fontWeight(FontWeight.Medium)
          Blank()
          Row() {
            Text(this.todayCurrentPrayerName)
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

      // ============================================================
      // Settings pills — values only, single row, clickable
      // ============================================================
      Row() {
        // ---- Convention value pill ----
        Row() {
          Text('🕌').fontSize(13).margin({ right: 6 })
          Text(SettingsHelper.getCalcMethodLabel(this.calcMethod))
            .fontSize(12)
            .fontColor(this.colors.accentGold)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .layoutWeight(1)
        .height(34).padding({ left: 12, right: 12 })
        .backgroundColor(this.colors.cardDark).borderRadius(17)
        .border({ width: 1, color: this.colors.borderSoft })
        .margin({ right: 4 })
        .onClick(() => { this.navigateToSettings(); })

        // ---- Madhab value pill ----
        Row() {
          Text('🌅').fontSize(13).margin({ right: 6 })
          Text(SettingsHelper.getAsrRuleLabel(this.asrRule))
            .fontSize(12)
            .fontColor(this.colors.accentGold)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .layoutWeight(1)
        .height(34).padding({ left: 12, right: 12 })
        .backgroundColor(this.colors.cardDark).borderRadius(17)
        .border({ width: 1, color: this.colors.borderSoft })
        .margin({ right: 4 })
        .onClick(() => { this.navigateToSettings(); })

        // ---- Source value pill ----
        Row() {
          Text('🌐').fontSize(13).margin({ right: 6 })
          Text(SettingsHelper.getCalcSourceLabel(this.calcSource))
            .fontSize(12)
            .fontColor(this.colors.accentGold)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .layoutWeight(1)
        .height(34).padding({ left: 12, right: 12 })
        .backgroundColor(this.colors.cardDark).borderRadius(17)
        .border({ width: 1, color: this.colors.borderSoft })
        .onClick(() => { this.navigateToSettings(); })
      }
      .width('100%')
      .padding({ bottom: 8 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%').padding({ left: 16, right: 16 }).backgroundColor(this.colors.primaryGreen)
  }

  @Builder
  NextPrayerSection() {
    Column() {
      Row() {
        Text('NEXT PRAYER')
          .fontSize(12).fontColor(this.colors.textMuted).letterSpacing(2).fontWeight(FontWeight.Medium)
        Blank()
        Row() {
          Text(this.todayNextPrayerName).fontSize(16).fontColor(this.colors.accentGold).fontWeight(FontWeight.Bold)
          Text('   ')
          Text(this.todayNextPrayerTime).fontSize(16).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
        }
      }
      .width('100%').padding({ top: 12, bottom: 12, left: 16, right: 16 })
      .backgroundColor(this.colors.cardDark).borderRadius(Theme.radiusMedium)
      .border({ width: 1, color: this.colors.borderSoft })
    }
    .width('100%').padding({ left: 16, right: 16 }).margin({ top: 4, bottom: 12 })
  }

  @Builder
  PrayersSection() {
    Column() {
      Row() {
        Text(`TODAY'S PRAYERS  ${this.prayers.filter(p => p.checked).length} of ${this.prayers.length}`)
          .fontSize(14).fontColor(this.colors.textWhite).fontWeight(FontWeight.Bold)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%').justifyContent(FlexAlign.Start).padding({ bottom: 8 })

      Row() {
        Text('◀').fontSize(14).fontColor(this.colors.accentGold)
          .width(36).height(36).textAlign(TextAlign.Center).borderRadius(18)
          .backgroundColor(this.colors.cardDark).border({ width: 1, color: this.colors.borderSoft })
          .onClick(() => { this.goToPreviousDay(); })

        Text(this.viewingHijriDate)
          .fontSize(13).fontColor(this.colors.accentGold).fontWeight(FontWeight.Medium)
          .layoutWeight(1).textAlign(TextAlign.Center).maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text('▶').fontSize(14).fontColor(this.colors.accentGold)
          .width(36).height(36).textAlign(TextAlign.Center).borderRadius(18)
          .backgroundColor(this.colors.cardDark).border({ width: 1, color: this.colors.borderSoft })
          .onClick(() => { this.goToNextDay(); })
      }
      .width('100%').padding({ bottom: 12 }).alignItems(VerticalAlign.Center)

      Column() {
        ForEach(this.prayers, (prayer: Prayer) => {
          this.PrayerItem(prayer)
        }, (prayer: Prayer) => `${this.viewingDateKey}-${prayer.id}-${prayer.name}-${prayer.status}-${prayer.checked ? '1' : '0'}-${prayer.time}`)
      }
      .width('100%').backgroundColor(this.colors.cardDark).borderRadius(Theme.radiusMedium)
      .border({ width: 1, color: this.colors.borderSoft })
      .padding({ left: 4, right: 4, top: 4, bottom: 4 })
    }
    .width('100%').padding({ left: 16, right: 16 }).alignItems(HorizontalAlign.Start)
    .margin({ bottom: 12 })
  }

  @Builder
  PrayerItem(prayer: Prayer) {
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
          Text(prayer.name)
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

  @Builder
  ExtraTimingsSection() {
    Column() {
      Text('EXTRA TIMINGS')
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
          Text(timing.name).fontSize(16).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
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

  @Builder
  ImportantDatesCard() {
    Column() {
      Row() {
        Text('📅').fontSize(16).margin({ right: 8 })
        Text('UPCOMING ISLAMIC EVENTS')
          .fontSize(14).fontColor(this.colors.accentGold).fontWeight(FontWeight.Bold).letterSpacing(1.5)
      }
      .width('100%').justifyContent(FlexAlign.Start).padding({ left: 4, bottom: 14 })

      Column() {
        if (this.upcomingImportantDates.length === 0) {
          Text('Loading important dates...').fontSize(14).fontColor(this.colors.textMuted)
        } else {
          Text(this.upcomingImportantDates[0].name.toUpperCase())
            .fontSize(14).fontColor(this.colors.accentGoldLight).fontWeight(FontWeight.Medium).textAlign(TextAlign.Center)
          Text(this.upcomingImportantDates[0].hijriDate)
            .fontSize(12).fontColor(this.colors.textMuted).margin({ top: 4 }).textAlign(TextAlign.Center)

          if (this.upcomingImportantDates.length > 1) {
            Divider().width('80%').color(this.colors.borderSoft).margin({ top: 14, bottom: 14 })
            Text(this.upcomingImportantDates[1].name.toUpperCase())
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

  @Builder
  ComingSoonCard() {
    Column() {
      Text('🌐').fontSize(56).margin({ bottom: 12 })
      Text('Online Prayer Times').fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
      Text('Coming Soon').fontSize(13).fontColor(this.colors.accentGold).letterSpacing(1).margin({ top: 4 })
      Divider().width('60%').color(this.colors.borderSoft).margin({ top: 16, bottom: 16 })
      Text('Switch back to Local Formula in Settings to see prayer times for your location.')
        .fontSize(12).fontColor(this.colors.textMuted).textAlign(TextAlign.Center).lineHeight(18).maxLines(4)
    }
    .width('92%').padding(28).backgroundColor(this.colors.cardDark)
    .borderRadius(Theme.radiusLarge).border({ width: 1, color: this.colors.borderSoft })
    .shadow({ radius: 12, color: this.colors.shadowCard, offsetX: 0, offsetY: 4 })
    .margin({ top: 4, bottom: 24 }).alignItems(HorizontalAlign.Center)
  }

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