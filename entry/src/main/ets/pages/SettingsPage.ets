// entry/src/main/ets/pages/SettingsPage.ets

import { router } from '@kit.ArkUI';
import { mediaquery } from '@kit.ArkUI';
import { Theme, ThemeColors, ThemeMode } from '../common/Theme';
import { CalculationMethod, AsrShadowRule } from '../utils/PrayerTimeCalculator';
import { SettingsHelper, PrayerOffsets } from '../utils/SettingsHelper';
import { LocationHelper, LocationData } from '../utils/LocationUtils';
import { LocationCache } from '../utils/LocationCache';
import { PickerItem, CalculationSource, LocationMode } from '../models/SettingsModels';
import { STORAGE_KEY_THEME_MODE } from '../common/StorageKeys';

@Entry
@Component
struct SettingsPage {

  // ---- Theme (kept for reactivity + rendering) ----
  @StorageLink(STORAGE_KEY_THEME_MODE)
  @Watch('onThemeModeChanged')
  themeMode: string = ThemeMode.SYSTEM;

  @State colors: ThemeColors = Theme.getColors(ThemeMode.LIGHT, false);
  private systemDarkListener: mediaquery.MediaQueryListener | null = null;

  // ---- General ----
  @State calcMethod: CalculationMethod = CalculationMethod.KARACHI;
  @State asrRule: AsrShadowRule = AsrShadowRule.STANDARD;
  @State calcSource: CalculationSource = CalculationSource.LOCAL;
  @State counter: number = 0;

  // ---- Prayer offsets ----
  @State showOffsets: boolean = false;
  @State offsets: PrayerOffsets = { fajr: 0, dhuhr: 0, asr: 0, maghrib: 0, isha: 0 };

  // ---- Location ----
  @State locationMode: LocationMode = LocationMode.GPS;
  @State manualLatInput: string = '';
  @State manualLngInput: string = '';

  @State effectiveLat: number = 0;
  @State effectiveLng: number = 0;
  @State effectiveCity: string = '';
  @State lastRefreshTime: number = 0;
  @State isRefreshing: boolean = false;

  // ---- UI state ----
  @State expandedCategory: string | null = 'Prayer Times';
  @State showMethodPicker: boolean = false;
  @State showAsrPicker: boolean = false;
  @State showSourcePicker: boolean = false;

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

    this.reload();
  }

  aboutToDisappear(): void {
    if (this.systemDarkListener) {
      this.systemDarkListener.off('change');
      this.systemDarkListener = null;
    }
  }

  onPageShow(): void {
    this.applyTheme();
    this.reload();
  }

  private async reload(): Promise<void> {
    const data = await SettingsHelper.loadAll();
    this.calcMethod = data.method;
    this.asrRule    = data.asr;
    this.calcSource = data.source;
    this.counter    = data.counter;

    this.offsets = await SettingsHelper.getPrayerOffsets();

    const mode = await SettingsHelper.getLocationMode();
    this.locationMode = mode;

    const manual = await SettingsHelper.getManualCoords();
    this.manualLatInput = manual.lat !== 0 ? manual.lat.toString() : '';
    this.manualLngInput = manual.lng !== 0 ? manual.lng.toString() : '';

    if (mode === LocationMode.MANUAL) {
      this.effectiveLat = manual.lat;
      this.effectiveLng = manual.lng;
      if (manual.lat !== 0 || manual.lng !== 0) {
        const city = manual.cityName.length > 0 ? manual.cityName : 'Manual Location';
        this.effectiveCity = `${city} (Manual)`;
      } else {
        this.effectiveCity = 'Not set';
      }
      this.lastRefreshTime = manual.refresh;
    } else {
      const cached = await LocationCache.load();
      if (cached) {
        this.effectiveLat = cached.latitude;
        this.effectiveLng = cached.longitude;
        this.effectiveCity = cached.cityName;
        this.lastRefreshTime = cached.lastRefreshTime;
      } else {
        this.effectiveLat = 0;
        this.effectiveLng = 0;
        this.effectiveCity = 'Not set';
        this.lastRefreshTime = 0;
      }
    }
  }

  // ============================================================
  // EVENT HANDLERS
  // ============================================================

  private pickMethod(id: string): void {
    const method = id as CalculationMethod;
    this.calcMethod = method;
    SettingsHelper.saveMethod(method);
    this.showMethodPicker = false;
  }

  private pickAsrRule(id: string): void {
    const rule = Number(id) as AsrShadowRule;
    this.asrRule = rule;
    SettingsHelper.saveAsrRule(rule);
    this.showAsrPicker = false;
  }

  private pickSource(id: string): void {
    const source = id as CalculationSource;
    if (source === CalculationSource.API) {
      this.showSourcePicker = false;
      return;
    }
    this.calcSource = source;
    SettingsHelper.saveSource(source);
    this.showSourcePicker = false;
  }

  private async pickLocationMode(mode: LocationMode): Promise<void> {
    this.locationMode = mode;
    SettingsHelper.saveLocationMode(mode);
    await this.reload();
  }

  // ---- Offsets ----
  private getOffsetValue(key: string): number {
    switch (key) {
      case 'fajr':    return this.offsets.fajr;
      case 'dhuhr':   return this.offsets.dhuhr;
      case 'asr':     return this.offsets.asr;
      case 'maghrib': return this.offsets.maghrib;
      case 'isha':    return this.offsets.isha;
      default: return 0;
    }
  }

  private withOffset(key: string, value: number): PrayerOffsets {
    return {
      fajr:    key === 'fajr'    ? value : this.offsets.fajr,
      dhuhr:   key === 'dhuhr'   ? value : this.offsets.dhuhr,
      asr:     key === 'asr'     ? value : this.offsets.asr,
      maghrib: key === 'maghrib' ? value : this.offsets.maghrib,
      isha:    key === 'isha'    ? value : this.offsets.isha
    };
  }

  private getStorageKeyForOffset(key: string): string {
    switch (key) {
      case 'fajr':    return SettingsHelper.OFFSET_KEYS.fajr;
      case 'dhuhr':   return SettingsHelper.OFFSET_KEYS.dhuhr;
      case 'asr':     return SettingsHelper.OFFSET_KEYS.asr;
      case 'maghrib': return SettingsHelper.OFFSET_KEYS.maghrib;
      case 'isha':    return SettingsHelper.OFFSET_KEYS.isha;
      default: return '';
    }
  }

  private changeOffset(key: string, delta: number): void {
    const current = this.getOffsetValue(key);
    let next = current + delta;
    if (next > 60) next = 60;
    if (next < -60) next = -60;
    this.offsets = this.withOffset(key, next);
    const storageKey = this.getStorageKeyForOffset(key);
    if (storageKey.length > 0) {
      SettingsHelper.saveOffset(storageKey, next);
    }
  }

  private async resetOffsets(): Promise<void> {
    const zero: PrayerOffsets = { fajr: 0, dhuhr: 0, asr: 0, maghrib: 0, isha: 0 };
    this.offsets = zero;
    await SettingsHelper.saveAllOffsets(zero);
    this.getUIContext().getPromptAction().showToast({ message: 'All offsets reset to 0', duration: 1800 });
  }

  private formatOffset(value: number): string {
    if (value === 0) return '0';
    if (value > 0) return `+${value}`;
    return `${value}`;
  }

  // ---- Manual coordinates ----
  private async saveManualCoords(): Promise<void> {
    const lat = parseFloat(this.manualLatInput.trim());
    const lng = parseFloat(this.manualLngInput.trim());

    if (isNaN(lat) || lat < -90 || lat > 90) {
      this.getUIContext().getPromptAction().showToast({
        message: 'Latitude must be a decimal between −90 and 90', duration: 2500
      });
      return;
    }
    if (isNaN(lng) || lng < -180 || lng > 180) {
      this.getUIContext().getPromptAction().showToast({
        message: 'Longitude must be a decimal between −180 and 180', duration: 2500
      });
      return;
    }

    this.isRefreshing = true;
    let cityName = 'Manual Location';
    try { cityName = await LocationHelper.reverseGeocode(lat, lng); } catch (e) { }
    const saved = await SettingsHelper.saveManualCoords(lat, lng, cityName);

    this.effectiveLat = saved.lat;
    this.effectiveLng = saved.lng;
    this.effectiveCity = `${saved.cityName} (Manual)`;
    this.lastRefreshTime = saved.refresh;
    this.isRefreshing = false;

    this.getUIContext().getPromptAction().showToast({ message: `Saved: ${saved.cityName}`, duration: 2000 });
  }

  private async refreshLocation(): Promise<void> {
    if (this.isRefreshing) return;
    this.isRefreshing = true;

    if (this.locationMode === LocationMode.MANUAL) {
      const manual = await SettingsHelper.getManualCoords();
      if (manual.lat === 0 && manual.lng === 0) {
        this.getUIContext().getPromptAction().showToast({ message: 'No manual coordinates saved yet', duration: 2000 });
        this.isRefreshing = false;
        return;
      }
      let cityName = 'Manual Location';
      try { cityName = await LocationHelper.reverseGeocode(manual.lat, manual.lng); } catch (e) { }
      const saved = await SettingsHelper.saveManualCoords(manual.lat, manual.lng, cityName);
      this.effectiveLat = saved.lat;
      this.effectiveLng = saved.lng;
      this.effectiveCity = `${saved.cityName} (Manual)`;
      this.lastRefreshTime = saved.refresh;
      this.getUIContext().getPromptAction().showToast({ message: `Reloaded: ${saved.cityName}`, duration: 2000 });
      this.isRefreshing = false;
      return;
    }

    try {
      const data: LocationData = await LocationHelper.fetchLocationData(getContext(this));
      LocationCache.save(data.latitude, data.longitude, data.cityName);
      this.effectiveLat = data.latitude;
      this.effectiveLng = data.longitude;
      this.effectiveCity = data.cityName;
      this.lastRefreshTime = Date.now();
      this.getUIContext().getPromptAction().showToast({ message: `GPS updated: ${data.cityName}`, duration: 2000 });
    } catch (err) {
      const error = err as Error;
      let msg = 'Failed to fetch GPS location';
      if (error.message === 'GPS_OFF') msg = 'Please turn on location services';
      else if (error.message === 'PERMISSION_DENIED') msg = 'Location permission denied';
      this.getUIContext().getPromptAction().showToast({ message: msg, duration: 2500 });
    } finally {
      this.isRefreshing = false;
    }
  }

  // ---- Counter ----
  private changeCounter(delta: number): void {
    this.counter = Math.max(0, this.counter + delta);
    SettingsHelper.saveCounter(this.counter);
  }

  private resetCounter(): void {
    this.counter = 0;
    SettingsHelper.saveCounter(0);
  }

  // ---- Formatters ----
  private formatCoord(n: number): string {
    if (n === 0) return '—';
    return n.toFixed(4);
  }

  private formatRefreshTime(ts: number): string {
    if (ts === 0) return 'Never';
    const d = new Date(ts);
    const now = new Date();
    const isToday = d.getDate() === now.getDate() && d.getMonth() === now.getMonth() && d.getFullYear() === now.getFullYear();
    const hh = d.getHours().toString().padStart(2, '0');
    const mm = d.getMinutes().toString().padStart(2, '0');
    const time = `${hh}:${mm}`;
    if (isToday) return `Today at ${time}`;
    const mm2 = (d.getMonth() + 1).toString().padStart(2, '0');
    const dd = d.getDate().toString().padStart(2, '0');
    return `${d.getFullYear()}-${mm2}-${dd} ${time}`;
  }

  // ============================================================
  // BUILD
  // ============================================================

  build() {
    Stack() {
      Column() {
        this.TopBar()

        Scroll() {
          Column() {
            // ---- Prayer Times ----
            this.CategoryHeader('Prayer Times', '🕌', this.colors.categoryPrayerTimes, 'Prayer Times')
            if (this.expandedCategory === 'Prayer Times') {
              this.PrayerTimesContent()
            }

            // ---- Counter ----
            this.CategoryHeader('Counter', '🔢', this.colors.categoryCounter, 'Counter')
            if (this.expandedCategory === 'Counter') {
              this.CounterContent()
            }

            // ---- About ----
            this.CategoryHeader('About', 'ℹ️', this.colors.categoryAbout, 'About')
            if (this.expandedCategory === 'About') {
              this.AboutContent()
            }

            Column().height(40)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 20 })
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor(this.colors.primaryGreen)
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%').height('100%').backgroundColor(this.colors.primaryGreen)

      // ---- Pickers ----
      if (this.showMethodPicker) {
        this.PickerOverlay('Convention', '🕌',
          SettingsHelper.buildMethodPickerItems(this.calcMethod),
          (id: string) => { this.pickMethod(id); },
          () => { this.showMethodPicker = false; })
      }

      if (this.showAsrPicker) {
        this.PickerOverlay('Madhab', '🌅',
          SettingsHelper.buildAsrPickerItems(this.asrRule),
          (id: string) => { this.pickAsrRule(id); },
          () => { this.showAsrPicker = false; })
      }

      if (this.showSourcePicker) {
        this.PickerOverlay('Source', '🌐',
          SettingsHelper.buildSourcePickerItems(this.calcSource),
          (id: string) => { this.pickSource(id); },
          () => { this.showSourcePicker = false; })
      }
    }
    .width('100%').height('100%').backgroundColor(this.colors.primaryGreen)
  }

  // ============================================================
  // @BUILDER METHODS
  // ============================================================

  @Builder
  TopBar() {
    Row() {
      Text('←')
        .fontSize(26).fontColor(this.colors.textWhite)
        .width(40).height(40).textAlign(TextAlign.Center)
        .borderRadius(20).backgroundColor(this.colors.tintSoft)
        .margin({ left: 16 })
        .onClick(() => router.back())

      Text('Settings')
        .fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
        .margin({ left: 16 })
    }
    .width('100%').height(72).backgroundColor(this.colors.cardDark)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  CategoryHeader(title: string, icon: string, iconColor: string, categoryKey: string) {
    Row() {
      Text(icon)
        .fontSize(18).width(40).height(40).textAlign(TextAlign.Center)
        .backgroundColor(this.colors.tintSoft).borderRadius(12)
        .border({ width: 1, color: this.colors.borderSoft })

      Text(title)
        .fontSize(17).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
        .margin({ left: 14 }).layoutWeight(1)

      Text(this.expandedCategory === categoryKey ? '▲' : '▼')
        .fontSize(12).fontColor(this.colors.accentGold).opacity(0.8)
    }
    .width('100%').padding({ top: 12, bottom: 12, left: 12, right: 16 })
    .backgroundColor(this.colors.cardDark).borderRadius(16)
    .border({ width: 1, color: this.colors.borderSoft })
    .margin({ bottom: 8 })
    .onClick(() => {
      this.expandedCategory = this.expandedCategory === categoryKey ? null : categoryKey;
    })
  }

  @Builder
  PrayerTimesContent() {
    Column() {
      // Convention
      Row() {
        Column() {
          Text('Convention').fontSize(15).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
          Text('Used for calculation of Fajr and Isha').fontSize(11).fontColor(this.colors.textMuted).margin({ top: 2 })
          Text(SettingsHelper.getCalcMethodLabel(this.calcMethod)).fontSize(12).fontColor(this.colors.accentGold)
            .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)
        Text('›').fontSize(22).fontColor(this.colors.accentGold).opacity(0.7)
      }
      .width('100%')
      .padding({ top: 14, bottom: 14, left: 16, right: 16 })
      .backgroundColor(this.colors.tintSubtle).borderRadius(12).margin({ bottom: 8 })
      .onClick(() => { this.showMethodPicker = true; })

      // Madhab
      Row() {
        Column() {
          Text('Madhab').fontSize(15).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
          Text('Asr Shadow Rule used in the calculation').fontSize(11).fontColor(this.colors.textMuted).margin({ top: 2 })
          Text(SettingsHelper.getAsrRuleLabel(this.asrRule)).fontSize(12).fontColor(this.colors.accentGold)
            .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)
        Text('›').fontSize(22).fontColor(this.colors.accentGold).opacity(0.7)
      }
      .width('100%')
      .padding({ top: 14, bottom: 14, left: 16, right: 16 })
      .backgroundColor(this.colors.tintSubtle).borderRadius(12).margin({ bottom: 8 })
      .onClick(() => { this.showAsrPicker = true; })

      // Source
      Row() {
        Column() {
          Text('Source').fontSize(15).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
          Text('Local Formula or Online').fontSize(11).fontColor(this.colors.textMuted).margin({ top: 2 })
          Text(SettingsHelper.getCalcSourceLabel(this.calcSource)).fontSize(12).fontColor(this.colors.accentGold)
            .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)
        Text('›').fontSize(22).fontColor(this.colors.accentGold).opacity(0.7)
      }
      .width('100%')
      .padding({ top: 14, bottom: 14, left: 16, right: 16 })
      .backgroundColor(this.colors.tintSubtle).borderRadius(12).margin({ bottom: 8 })
      .onClick(() => { this.showSourcePicker = true; })

      Divider().color(this.colors.borderSoft).margin({ top: 8, bottom: 8 })
      this.LocationBlock()
      this.PrayerOffsetsCard()
    }
    .width('100%').padding(12).backgroundColor(this.colors.cardDark)
    .borderRadius(16).border({ width: 1, color: this.colors.borderSoft })
    .margin({ bottom: 12 })
  }

  @Builder
  PrayerOffsetsCard() {
    Column() {
      Row() {
        Column() {
          Text('Prayer Offsets').fontSize(15).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
          Text('Manually Shift calculated timings').fontSize(11).fontColor(this.colors.textMuted).margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)
        Text(this.showOffsets ? '▲' : '▼').fontSize(12).fontColor(this.colors.accentGold).opacity(0.8)
      }
      .width('100%').padding({ top: 14, bottom: 14, left: 16, right: 16 })
      .onClick(() => { this.showOffsets = !this.showOffsets; })

      if (this.showOffsets) {
        Divider().color(this.colors.borderSoft).width('90%')
        Column() {
          Text('Shift timings in minutes (−60 to +60)').fontSize(11).fontColor(this.colors.textMuted)
            .width('100%').textAlign(TextAlign.Center).padding({ top: 10, bottom: 8 })

          this.OffsetRow('Fajr',    'fajr')
          this.OffsetRow('Dhuhr',   'dhuhr')
          this.OffsetRow('Asr',     'asr')
          this.OffsetRow('Maghrib', 'maghrib')
          this.OffsetRow('Isha',    'isha')

          Button('Reset All Offsets').width('100%').height(38).fontSize(13).fontWeight(FontWeight.Medium)
            .fontColor(this.colors.textWhite).backgroundColor(this.colors.tintSoft)
            .borderRadius(10).margin({ top: 10, bottom: 4 })
            .onClick(() => { this.resetOffsets(); })
        }
        .width('100%').padding({ left: 8, right: 8, bottom: 12 })
      }
    }
    .width('100%').padding({ top: 4, bottom: 4 })
    .backgroundColor(this.colors.tintSubtle).borderRadius(12)
  }

  @Builder
  OffsetRow(label: string, key: string) {
    Row() {
      Text(label).fontSize(14).fontColor(this.colors.textWhite).layoutWeight(1)
      Button('−').width(32).height(32).fontSize(18).fontColor(this.colors.textWhite)
        .backgroundColor(this.colors.tintSoft).borderRadius(8)
        .onClick(() => { this.changeOffset(key, -1); })
      Text(this.formatOffset(this.getOffsetValue(key)))
        .fontSize(14).fontWeight(FontWeight.Bold)
        .fontColor(this.getOffsetValue(key) === 0 ? this.colors.textMuted : this.colors.accentGold)
        .width(50).textAlign(TextAlign.Center)
      Button('+').width(32).height(32).fontSize(18).fontColor(this.colors.textOnAccent)
        .backgroundColor(this.colors.accentGold).borderRadius(8)
        .onClick(() => { this.changeOffset(key, 1); })
    }
    .width('100%').padding({ top: 6, bottom: 6, left: 8, right: 8 })
  }

  @Builder
  LocationBlock() {
    Column() {
      Row() {
        Text('📍').fontSize(14)
        Text('Location').fontSize(15).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
          .margin({ left: 8 }).layoutWeight(1)
        Button() {
          if (this.isRefreshing) {
            LoadingProgress().width(18).height(18).color(this.colors.accentGold)
          } else {
            Text('📡').fontSize(18).fontColor(this.colors.accentGold)
          }
        }
        .width(36).height(36).backgroundColor(this.colors.tintMedium).borderRadius(10)
        .border({ width: 1, color: this.colors.borderStrong })
        .onClick(() => { this.refreshLocation(); })
      }
      .width('100%').padding({ bottom: 10 })

      Text('Choose how the app determines your location').fontSize(11).fontColor(this.colors.textMuted)
        .width('100%').padding({ bottom: 12 })

      Row() {
        this.ModeButton('GPS', LocationMode.GPS)
        this.ModeButton('Manual Location', LocationMode.MANUAL)
      }
      .width('100%').padding({ bottom: 14 })

      if (this.locationMode === LocationMode.MANUAL) {
        Column() {
          Column() {
            Text('Latitude  (−90 to 90)').fontSize(11).fontColor(this.colors.textMuted).width('100%').margin({ bottom: 4 })
            TextInput({ text: this.manualLatInput, placeholder: 'e.g. 33.6844' })
              .type(InputType.Normal).inputFilter('[\\-0-9\\.]')
              .onChange((value: string) => { this.manualLatInput = value; })
              .fontSize(14).fontColor(this.colors.textWhite).placeholderColor(this.colors.placeholder)
              .caretColor(this.colors.accentGold).backgroundColor(this.colors.tintSoft).borderRadius(8)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          }
          .width('100%').margin({ bottom: 10 })

          Column() {
            Text('Longitude  (−180 to 180)').fontSize(11).fontColor(this.colors.textMuted).width('100%').margin({ bottom: 4 })
            TextInput({ text: this.manualLngInput, placeholder: 'e.g. 73.0479' })
              .type(InputType.Normal).inputFilter('[\\-0-9\\.]')
              .onChange((value: string) => { this.manualLngInput = value; })
              .fontSize(14).fontColor(this.colors.textWhite).placeholderColor(this.colors.placeholder)
              .caretColor(this.colors.accentGold).backgroundColor(this.colors.tintSoft).borderRadius(8)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          }
          .width('100%').margin({ bottom: 12 })

          Button('Save Coordinates').width('100%').height(44).fontSize(14).fontWeight(FontWeight.Medium)
            .fontColor(this.colors.textOnAccent).backgroundColor(this.colors.accentGold).borderRadius(10)
            .onClick(() => { this.saveManualCoords(); })
        }
        .width('100%').padding({ bottom: 14 })
      }

      Column() {
        Row() {
          Text('Current Position').fontSize(11).fontColor(this.colors.accentGold).fontWeight(FontWeight.Medium).letterSpacing(1)
        }
        .width('100%').padding({ bottom: 8 })

        Row() { Text('Latitude').fontSize(12).fontColor(this.colors.textMuted).layoutWeight(1)
          Text(this.formatCoord(this.effectiveLat)).fontSize(12).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium) }
        .width('100%').padding({ top: 4, bottom: 4 })
        Row() { Text('Longitude').fontSize(12).fontColor(this.colors.textMuted).layoutWeight(1)
          Text(this.formatCoord(this.effectiveLng)).fontSize(12).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium) }
        .width('100%').padding({ top: 4, bottom: 4 })
        Row() { Text('City').fontSize(12).fontColor(this.colors.textMuted).layoutWeight(1)
          Text(this.effectiveCity).fontSize(12).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium) }
        .width('100%').padding({ top: 4, bottom: 4 })
        Row() { Text('Last refreshed').fontSize(12).fontColor(this.colors.textMuted).layoutWeight(1)
          Text(this.formatRefreshTime(this.lastRefreshTime)).fontSize(12).fontColor(this.colors.accentGold).fontWeight(FontWeight.Medium) }
        .width('100%').padding({ top: 4, bottom: 4 })
      }
      .width('100%').padding(12).backgroundColor(this.colors.tintSoft).borderRadius(10)
      .border({ width: 1, color: this.colors.borderSoft })
    }
    .width('100%').padding(14).backgroundColor(this.colors.tintSubtle).borderRadius(12)
  }

  @Builder
  ModeButton(label: string, mode: LocationMode) {
    Text(label).fontSize(12)
      .fontWeight(this.locationMode === mode ? FontWeight.Bold : FontWeight.Normal)
      .fontColor(this.locationMode === mode ? this.colors.textOnAccent : this.colors.textWhite)
      .backgroundColor(this.locationMode === mode ? this.colors.accentGold : this.colors.tintSoft)
      .textAlign(TextAlign.Center).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      .height(38).layoutWeight(1).borderRadius(10)
      .margin({ right: mode === LocationMode.GPS ? 6 : 0, left: mode === LocationMode.MANUAL ? 6 : 0 })
      .onClick(() => { this.pickLocationMode(mode); })
  }

  @Builder
  CounterContent() {
    Column() {
      Row() {
        Button('−').width(48).height(48).fontSize(24).fontColor(this.colors.textWhite)
          .backgroundColor(this.colors.tintSoft).borderRadius(12)
          .onClick(() => { this.changeCounter(-1); })
        Text(`${this.counter}`).fontSize(36).fontWeight(FontWeight.Bold)
          .fontColor(this.colors.accentGold).layoutWeight(1).textAlign(TextAlign.Center)
        Button('+').width(48).height(48).fontSize(24).fontColor(this.colors.textOnAccent)
          .backgroundColor(this.colors.accentGold).borderRadius(12)
          .onClick(() => { this.changeCounter(1); })
      }
      .width('100%').padding({ top: 12, bottom: 12 })

      Button('Reset Counter').width('100%').height(40).fontSize(14).fontColor(this.colors.textWhite)
        .backgroundColor(this.colors.tintSoft).borderRadius(10).margin({ top: 4 })
        .onClick(() => { this.resetCounter(); })
    }
    .width('100%').padding(12).backgroundColor(this.colors.cardDark)
    .borderRadius(16).border({ width: 1, color: this.colors.borderSoft }).margin({ bottom: 12 })
  }

  @Builder
  AboutContent() {
    Column() {
      Column() {
        Text('Sirat Companion').fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
        Text('Your Daily Islamic Companion').fontSize(12).fontColor(this.colors.accentGold).margin({ top: 4 })
        Divider().color(this.colors.borderSoft).width('80%').margin({ top: 14, bottom: 14 })
        this.AboutRow('Version', '1.0.0')
        this.AboutRow('Platform', 'HarmonyOS')
        this.AboutRow('© 2026', 'Sirat Companion')
      }
      .width('100%').padding(20).backgroundColor(this.colors.tintSubtle)
      .borderRadius(12).alignItems(HorizontalAlign.Center)
    }
    .width('100%').padding(12).backgroundColor(this.colors.cardDark)
    .borderRadius(16).border({ width: 1, color: this.colors.borderSoft }).margin({ bottom: 12 })
  }

  @Builder
  AboutRow(label: string, value: string) {
    Row() {
      Text(label).fontSize(13).fontColor(this.colors.textMuted)
      Blank()
      Text(value).fontSize(13).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
    }
    .width('100%').padding({ left: 8, right: 8 }).margin({ top: 6 })
  }

  @Builder
  PickerOverlay(title: string, icon: string, items: PickerItem[],
    onSelect: (id: string) => void, onCancel: () => void) {
    Column().width('100%').height('100%').backgroundColor(this.colors.overlayDim).onClick(() => { onCancel(); })

    Column() {
      Row().width(44).height(4).backgroundColor(this.colors.overlayDimSoft).borderRadius(2).margin({ top: 10 })

      Row() {
        Text(icon).fontSize(22).width(44).height(44).textAlign(TextAlign.Center)
          .backgroundColor(this.colors.tintSoft).borderRadius(12)
          .border({ width: 1, color: this.colors.borderSoft })
        Text(title).fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite).margin({ left: 14 })
      }
      .width('100%').padding({ left: 20, top: 20, bottom: 20 })

      Divider().color(this.colors.borderSoft).width('90%')

      Column() {
        ForEach(items, (item: PickerItem) => {
          Row() {
            Row() {
              if (item.selected) {
                Row().width(10).height(10).borderRadius(5).backgroundColor(this.colors.accentGold)
              }
            }
            .width(22).height(22).borderRadius(11)
            .border({
              width: item.selected ? 2 : 1.5,
              color: item.selected ? this.colors.accentGold : this.colors.borderStrong
            })
            .justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)
            Text(item.label).fontSize(15)
              .fontColor(item.selected ? this.colors.accentGold : this.colors.textWhite)
              .fontWeight(item.selected ? FontWeight.Bold : FontWeight.Normal)
              .layoutWeight(1).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ left: 14 })
          }
          .width('100%').padding({ top: 16, bottom: 16, left: 20, right: 20 })
          .backgroundColor(item.selected ? this.colors.tintSoft : 'transparent')
          .borderRadius(12).margin({ bottom: 4 }).onClick(() => { onSelect(item.id); })
        }, (item: PickerItem) => item.id)
      }
      .width('100%').padding({ left: 8, right: 8, top: 12, bottom: 12 })

      Button('Cancel').width('90%').height(48).fontSize(15).fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textWhite).backgroundColor(this.colors.tintSoft)
        .borderRadius(12).margin({ top: 8, bottom: 24 }).onClick(() => { onCancel(); })
    }
    .width('100%').backgroundColor(this.colors.cardDark)
    .borderRadius({ topLeft: 28, topRight: 28 })
    .shadow({ radius: 24, color: this.colors.shadowFloating, offsetX: 0, offsetY: -6 })
    .border({ width: { top: 1 }, color: this.colors.borderSoft })
    .position({ bottom: 0 })
  }
}