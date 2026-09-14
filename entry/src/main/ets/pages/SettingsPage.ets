// entry/src/main/ets/pages/SettingsPage.ets

import { router } from '@kit.ArkUI';
import { mediaquery } from '@kit.ArkUI';
import { Theme, ThemeColors, ThemeMode } from '../common/Theme';
import { PageTheme } from '../common/PageTheme';
import { CalculationMethod, AsrShadowRule } from '../utils/PrayerTimeCalculator';
import { SettingsHelper, PrayerOffsets } from '../helper/SettingsHelper';
import { LocationHelper, LocationData } from '../utils/LocationUtils';
import { LocationCache } from '../utils/LocationCache';
import { PickerItem, CalculationSource, LocationMode } from '../models/SettingsModels';
import {
  STORAGE_KEY_THEME_MODE,
  STORAGE_KEY_HIJRI_OFFSET,
  STORAGE_KEY_LANGUAGE
} from '../common/StorageKeys';
import { PrayerOffsetsHelper, OffsetKey } from '../helper/PrayerOffsetsHelper';
import { L } from '../helper/LocalizationHelper';

const MAX_HIJRI_OFFSET = 3;

@Entry
@Component
struct SettingsPage {

  // ============================================================
  // THEME + LANGUAGE
  // ============================================================

  @StorageLink(STORAGE_KEY_THEME_MODE)
  @Watch('onThemeModeChanged')
  themeMode: string = ThemeMode.SYSTEM;

  @StorageLink(STORAGE_KEY_LANGUAGE)
  @Watch('onLanguageChanged')
  appLanguage: string = 'en';

  @StorageLink(STORAGE_KEY_HIJRI_OFFSET)
  hijriOffset: number = 0;

  /** Plain @State mirror — guarantees a re-render on language change. */
  @State private currentLanguage: string = 'en';

  @State colors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);
  private systemDarkListener: mediaquery.MediaQueryListener | null = null;

  // ============================================================
  // GENERAL
  // ============================================================

  @State calcMethod: CalculationMethod = CalculationMethod.KARACHI;
  @State asrRule: AsrShadowRule = AsrShadowRule.STANDARD;
  @State calcSource: CalculationSource = CalculationSource.LOCAL;

  @State showOffsets: boolean = false;
  @State offsets: PrayerOffsets = { fajr: 0, dhuhr: 0, asr: 0, maghrib: 0, isha: 0 };

  @State locationMode: LocationMode = LocationMode.GPS;
  @State manualLatInput: string = '';
  @State manualLngInput: string = '';
  @State manualCityInput: string = '';

  @State effectiveLat: number = 0;
  @State effectiveLng: number = 0;
  @State effectiveCity: string = '';
  @State lastRefreshTime: number = 0;
  @State isRefreshing: boolean = false;

  @State expandedCategory: string | null = 'Prayer Times';
  @State showMethodPicker: boolean = false;
  @State showAsrPicker: boolean = false;
  @State showSourcePicker: boolean = false;

  // ============================================================
  // LOCALIZATION + DIRECTION HELPERS
  // ============================================================

  private tr(key: string): string {
    return L.get(key, this.currentLanguage);
  }

  private isRtl(): boolean {
    return L.isRtlLang(this.currentLanguage);
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

  // ============================================================
  // LIFECYCLE
  // ============================================================

  aboutToAppear(): void {
    this.currentLanguage = this.appLanguage;
    this.colors = PageTheme.compute(this.themeMode);
    this.systemDarkListener = PageTheme.installSystemListener(this.themeMode, (c) => {
      this.colors = c;
    });
    this.reload();
  }

  aboutToDisappear(): void {
    PageTheme.uninstallSystemListener(this.systemDarkListener);
    this.systemDarkListener = null;
  }

  onPageShow(): void {
    this.currentLanguage = this.appLanguage;
    this.colors = PageTheme.compute(this.themeMode);
    this.reload();
  }

  private async reload(): Promise<void> {
    const data = await SettingsHelper.loadAll();
    this.calcMethod = data.method;
    this.asrRule    = data.asr;
    this.calcSource = data.source;

    this.offsets = await SettingsHelper.getPrayerOffsets();

    const mode = await SettingsHelper.getLocationMode();
    this.locationMode = mode;

    const manual = await SettingsHelper.getManualCoords();
    this.manualLatInput  = manual.lat !== 0 ? manual.lat.toString() : '';
    this.manualLngInput  = manual.lng !== 0 ? manual.lng.toString() : '';
    this.manualCityInput = manual.cityName;

    if (mode === LocationMode.MANUAL) {
      this.effectiveLat = manual.lat;
      this.effectiveLng = manual.lng;
      if (manual.lat !== 0 || manual.lng !== 0) {
        const city = manual.cityName.length > 0 ? manual.cityName : this.tr('manual_location');
        this.effectiveCity = `${city} (${this.tr('manual_location')})`;
      } else {
        this.effectiveCity = '—';
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
        this.effectiveCity = '—';
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

  // ---- Prayer offsets ----

  private getStorageKeyForOffset(key: OffsetKey): string {
    switch (key) {
      case 'fajr':    return SettingsHelper.OFFSET_KEYS.fajr;
      case 'dhuhr':   return SettingsHelper.OFFSET_KEYS.dhuhr;
      case 'asr':     return SettingsHelper.OFFSET_KEYS.asr;
      case 'maghrib': return SettingsHelper.OFFSET_KEYS.maghrib;
      case 'isha':    return SettingsHelper.OFFSET_KEYS.isha;
      default:        return '';
    }
  }

  private changeOffset(key: OffsetKey, delta: number): void {
    const current = PrayerOffsetsHelper.get(this.offsets, key);
    const next = PrayerOffsetsHelper.clamp(current + delta);
    this.offsets = PrayerOffsetsHelper.set(this.offsets, key, next);

    const storageKey = this.getStorageKeyForOffset(key);
    if (storageKey.length > 0) {
      SettingsHelper.saveOffset(storageKey, next);
    }
  }

  private async resetOffsets(): Promise<void> {
    const zero = PrayerOffsetsHelper.ZERO;
    this.offsets = zero;
    await SettingsHelper.saveAllOffsets(zero);
    this.getUIContext().getPromptAction().showToast({
      message: this.tr('reset_all_offsets'), duration: 1800
    });
  }

  // ---- Hijri offset ----

  private changeHijriOffset(delta: number): void {
    const next = this.hijriOffset + delta;
    if (next < -MAX_HIJRI_OFFSET) return;
    if (next > MAX_HIJRI_OFFSET) return;
    this.hijriOffset = next;
    SettingsHelper.saveHijriOffset(next);
  }

  private formatHijriOffset(): string {
    if (this.hijriOffset === 0) return '+0';
    if (this.hijriOffset > 0) return `+${this.hijriOffset}`;
    return `\u2212${Math.abs(this.hijriOffset)}`;
  }

  private hijriOffsetDescription(): string {
    if (this.hijriOffset === 0) return this.tr('matching_standard');
    const n = Math.abs(this.hijriOffset);
    if (this.hijriOffset > 0) {
      return `${n} ${this.tr('offset_days_ahead')}`;
    }
    return `${n} ${this.tr('offset_days_behind')}`;
  }

  // ---- Manual coordinates ----

  private async saveManualCoords(): Promise<void> {
    const lat = parseFloat(this.manualLatInput.trim());
    const lng = parseFloat(this.manualLngInput.trim());

    if (isNaN(lat) || lat < -90 || lat > 90) {
      this.getUIContext().getPromptAction().showToast({
        message: this.tr('latitude_hint'), duration: 2500
      });
      return;
    }
    if (isNaN(lng) || lng < -180 || lng > 180) {
      this.getUIContext().getPromptAction().showToast({
        message: this.tr('longitude_hint'), duration: 2500
      });
      return;
    }

    this.isRefreshing = true;

    let cityName = this.manualCityInput.trim();
    if (cityName.length === 0) {
      try { cityName = await LocationHelper.reverseGeocode(lat, lng); } catch (e) { }
      if (cityName === 'Unknown location' || cityName.length === 0) {
        cityName = `${lat.toFixed(2)}, ${lng.toFixed(2)}`;
      }
    }

    const saved = await SettingsHelper.saveManualCoords(lat, lng, cityName);

    this.effectiveLat = saved.lat;
    this.effectiveLng = saved.lng;
    this.effectiveCity = `${saved.cityName} (${this.tr('manual_location')})`;
    this.lastRefreshTime = saved.refresh;
    this.manualCityInput = saved.cityName;
    this.isRefreshing = false;

    this.getUIContext().getPromptAction().showToast({
      message: `${this.tr('save')}: ${saved.cityName}`, duration: 2000
    });
  }

  private async refreshLocation(): Promise<void> {
    if (this.isRefreshing) return;
    this.isRefreshing = true;

    if (this.locationMode === LocationMode.MANUAL) {
      const manual = await SettingsHelper.getManualCoords();
      if (manual.lat === 0 && manual.lng === 0) {
        this.getUIContext().getPromptAction().showToast({
          message: this.tr('location_desc'), duration: 2000
        });
        this.isRefreshing = false;
        return;
      }
      let cityName = 'Manual Location';
      try { cityName = await LocationHelper.reverseGeocode(manual.lat, manual.lng); } catch (e) { }
      const saved = await SettingsHelper.saveManualCoords(manual.lat, manual.lng, cityName);
      this.effectiveLat = saved.lat;
      this.effectiveLng = saved.lng;
      this.effectiveCity = `${saved.cityName} (${this.tr('manual_location')})`;
      this.lastRefreshTime = saved.refresh;
      this.getUIContext().getPromptAction().showToast({
        message: `${this.tr('save')}: ${saved.cityName}`, duration: 2000
      });
      this.isRefreshing = false;
      return;
    }

    try {
      const data: LocationData = await LocationHelper.fetchLocationData(getContext(this));
      await LocationCache.save(data.latitude, data.longitude, data.cityName);
      this.effectiveLat = data.latitude;
      this.effectiveLng = data.longitude;
      this.effectiveCity = data.cityName;
      this.lastRefreshTime = Date.now();
      this.getUIContext().getPromptAction().showToast({
        message: `GPS: ${data.cityName}`, duration: 2000
      });
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

  // ---- Formatters ----

  private formatCoord(n: number): string {
    if (n === 0) return '—';
    return n.toFixed(4);
  }

  private formatRefreshTime(ts: number): string {
    if (ts === 0) return '—';
    const d = new Date(ts);
    const now = new Date();
    const isToday =
      d.getDate() === now.getDate() &&
        d.getMonth() === now.getMonth() &&
        d.getFullYear() === now.getFullYear();
    const hh = d.getHours().toString().padStart(2, '0');
    const mm = d.getMinutes().toString().padStart(2, '0');
    const time = `${hh}:${mm}`;
    if (isToday) return `${this.tr('today')} ${time}`;
    const m2 = (d.getMonth() + 1).toString().padStart(2, '0');
    const dd = d.getDate().toString().padStart(2, '0');
    return `${d.getFullYear()}-${m2}-${dd} ${time}`;
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
            this.CategoryHeader(
              this.tr('category_prayer_times'),
              '🕌',
              this.colors.categoryPrayerTimes,
              'Prayer Times'
            )
            if (this.expandedCategory === 'Prayer Times') {
              this.PrayerTimesContent()
            }

            // ---- Hijri Calendar ----
            this.CategoryHeader(
              this.tr('category_hijri_calendar'),
              '📅',
              this.colors.categoryHijriCalendar,
              'Hijri Calendar'
            )
            if (this.expandedCategory === 'Hijri Calendar') {
              this.HijriCalendarContent()
            }

            // ---- About ----
            this.CategoryHeader(
              this.tr('category_about'),
              'ℹ️',
              this.colors.categoryAbout,
              'About'
            )
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
        this.PickerOverlay(
          this.tr('convention'), '🕌',
          SettingsHelper.buildMethodPickerItems(this.calcMethod),
          (id: string) => { this.pickMethod(id); },
          () => { this.showMethodPicker = false; })
      }

      if (this.showAsrPicker) {
        this.PickerOverlay(
          this.tr('madhab'), '🌅',
          SettingsHelper.buildAsrPickerItems(this.asrRule),
          (id: string) => { this.pickAsrRule(id); },
          () => { this.showAsrPicker = false; })
      }

      if (this.showSourcePicker) {
        this.PickerOverlay(
          this.tr('source'), '🌐',
          SettingsHelper.buildSourcePickerItems(this.calcSource),
          (id: string) => { this.pickSource(id); },
          () => { this.showSourcePicker = false; })
      }
    }
    .width('100%').height('100%').backgroundColor(this.colors.primaryGreen)
    .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
  }

  // ============================================================
  // BUILDERS
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

      Text(this.tr('title_settings'))
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

  // ============================================================
  // PRAYER TIMES
  // ============================================================

  @Builder
  PrayerTimesContent() {
    Column() {
      // Convention
      Row() {
        Column() {
          Text(this.tr('convention')).fontSize(15).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
          Text(this.tr('convention_desc')).fontSize(11).fontColor(this.colors.textMuted).margin({ top: 2 })
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
          Text(this.tr('madhab')).fontSize(15).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
          Text(this.tr('madhab_desc')).fontSize(11).fontColor(this.colors.textMuted).margin({ top: 2 })
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
          Text(this.tr('source')).fontSize(15).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
          Text(this.tr('source_desc')).fontSize(11).fontColor(this.colors.textMuted).margin({ top: 2 })
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

      // Prayer Offsets
      this.PrayerOffsetsCard()

      Divider().color(this.colors.borderSoft).margin({ top: 8, bottom: 8 })
      this.LocationBlock()
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
          Text(this.tr('prayer_offsets')).fontSize(15).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
          Text(this.tr('prayer_offsets_desc')).fontSize(11).fontColor(this.colors.textMuted).margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)
        Text(this.showOffsets ? '▲' : '▼').fontSize(12).fontColor(this.colors.accentGold).opacity(0.8)
      }
      .width('100%').padding({ top: 14, bottom: 14, left: 16, right: 16 })
      .onClick(() => { this.showOffsets = !this.showOffsets; })

      if (this.showOffsets) {
        Divider().color(this.colors.borderSoft).width('90%')
        Column() {
          Text(this.tr('offsets_hint')).fontSize(11).fontColor(this.colors.textMuted)
            .width('100%').textAlign(TextAlign.Center).padding({ top: 10, bottom: 8 })

          this.OffsetRow('Fajr',    'fajr')
          this.OffsetRow('Dhuhr',   'dhuhr')
          this.OffsetRow('Asr',     'asr')
          this.OffsetRow('Maghrib', 'maghrib')
          this.OffsetRow('Isha',    'isha')

          Button(this.tr('reset_all_offsets')).width('100%').height(38).fontSize(13).fontWeight(FontWeight.Medium)
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
  OffsetRow(label: string, key: OffsetKey) {
    Row() {
      Text(label).fontSize(14).fontColor(this.colors.textWhite).layoutWeight(1)

      Button() {
        Text('\u2212').fontSize(24).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
      }
      .width(38).height(38)
      .backgroundColor(this.colors.tintMedium).borderRadius(10)
      .border({ width: 1, color: this.colors.borderMedium })
      .onClick(() => { this.changeOffset(key, -1); })

      Text(PrayerOffsetsHelper.format(PrayerOffsetsHelper.get(this.offsets, key)))
        .fontSize(15).fontWeight(FontWeight.Bold)
        .fontColor(PrayerOffsetsHelper.get(this.offsets, key) === 0
          ? this.colors.textMuted : this.colors.accentGold)
        .width(56).textAlign(TextAlign.Center)

      Button() {
        Text('+').fontSize(24).fontWeight(FontWeight.Bold).fontColor(this.colors.textOnAccent)
      }
      .width(38).height(38)
      .backgroundColor(this.colors.accentGold).borderRadius(10)
      .onClick(() => { this.changeOffset(key, 1); })
    }
    .width('100%').padding({ top: 8, bottom: 8, left: 8, right: 8 })
  }

  // ============================================================
  // LOCATION BLOCK
  // ============================================================

  @Builder
  LocationBlock() {
    Column() {
      Row() {
        Text('📍').fontSize(14)
        Text(this.tr('location')).fontSize(15).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
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

      Text(this.tr('location_desc')).fontSize(11).fontColor(this.colors.textMuted)
        .width('100%').padding({ bottom: 12 })

      Row() {
        this.ModeButton(this.tr('gps'), LocationMode.GPS)
        this.ModeButton(this.tr('manual_location'), LocationMode.MANUAL)
      }
      .width('100%').padding({ bottom: 14 })

      if (this.locationMode === LocationMode.MANUAL) {
        Column() {
          Column() {
            Text(this.tr('latitude_hint')).fontSize(11).fontColor(this.colors.textMuted).width('100%').margin({ bottom: 4 })
            TextInput({ text: this.manualLatInput, placeholder: 'e.g. 33.6844' })
              .type(InputType.Normal).inputFilter('[\\-0-9\\.]')
              .direction(Direction.Ltr)
              .onChange((value: string) => { this.manualLatInput = value; })
              .fontSize(14).fontColor(this.colors.textWhite).placeholderColor(this.colors.placeholder)
              .caretColor(this.colors.accentGold).backgroundColor(this.colors.tintSoft).borderRadius(8)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          }
          .width('100%').margin({ bottom: 10 })

          Column() {
            Text(this.tr('longitude_hint')).fontSize(11).fontColor(this.colors.textMuted).width('100%').margin({ bottom: 4 })
            TextInput({ text: this.manualLngInput, placeholder: 'e.g. 73.0479' })
              .type(InputType.Normal).inputFilter('[\\-0-9\\.]')
              .direction(Direction.Ltr)
              .onChange((value: string) => { this.manualLngInput = value; })
              .fontSize(14).fontColor(this.colors.textWhite).placeholderColor(this.colors.placeholder)
              .caretColor(this.colors.accentGold).backgroundColor(this.colors.tintSoft).borderRadius(8)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          }
          .width('100%').margin({ bottom: 10 })

          Column() {
            Text(this.tr('city_name_optional')).fontSize(11).fontColor(this.colors.textMuted).width('100%').margin({ bottom: 4 })
            TextInput({ text: this.manualCityInput, placeholder: this.tr('city_name_placeholder') })
              .type(InputType.Normal)
              .onChange((value: string) => { this.manualCityInput = value; })
              .fontSize(14).fontColor(this.colors.textWhite).placeholderColor(this.colors.placeholder)
              .caretColor(this.colors.accentGold).backgroundColor(this.colors.tintSoft).borderRadius(8)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          }
          .width('100%').margin({ bottom: 12 })

          Button(this.tr('save_coordinates')).width('100%').height(44).fontSize(14).fontWeight(FontWeight.Medium)
            .fontColor(this.colors.textOnAccent).backgroundColor(this.colors.accentGold).borderRadius(10)
            .onClick(() => { this.saveManualCoords(); })
        }
        .width('100%').padding({ bottom: 14 })
      }

      Column() {
        Row() {
          Text(this.tr('current_position')).fontSize(11).fontColor(this.colors.accentGold).fontWeight(FontWeight.Medium).letterSpacing(1)
        }
        .width('100%').padding({ bottom: 8 })

        Row() {
          Text(this.tr('latitude')).fontSize(12).fontColor(this.colors.textMuted)
          Blank()
          Text(this.formatCoord(this.effectiveLat)).fontSize(12).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
            .direction(Direction.Ltr)
        }
        .width('100%').padding({ top: 4, bottom: 4 })
        Row() {
          Text(this.tr('longitude')).fontSize(12).fontColor(this.colors.textMuted)
          Blank()
          Text(this.formatCoord(this.effectiveLng)).fontSize(12).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
            .direction(Direction.Ltr)
        }
        .width('100%').padding({ top: 4, bottom: 4 })
        Row() {
          Text(this.tr('city')).fontSize(12).fontColor(this.colors.textMuted)
          Blank()
          Text(this.effectiveCity).fontSize(12).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
        }
        .width('100%').padding({ top: 4, bottom: 4 })
        Row() {
          Text(this.tr('last_refreshed')).fontSize(12).fontColor(this.colors.textMuted)
          Blank()
          Text(this.formatRefreshTime(this.lastRefreshTime)).fontSize(12).fontColor(this.colors.accentGold).fontWeight(FontWeight.Medium)
            .direction(Direction.Ltr)
        }
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

  // ============================================================
  // HIJRI CALENDAR
  // ============================================================

  @Builder
  HijriCalendarContent() {
    Column() {
      Column() {
        Row() {
          Column() {
            Text(this.tr('hijri_offset'))
              .fontSize(15).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
            Text(this.tr('hijri_offset_desc'))
              .fontSize(11).fontColor(this.colors.textMuted).margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start).layoutWeight(1)

          Button() {
            Text('\u2212').fontSize(22).fontWeight(FontWeight.Bold)
              .fontColor(this.hijriOffset <= -MAX_HIJRI_OFFSET
                ? this.colors.textMuted : this.colors.textWhite)
          }
          .width(38).height(38)
          .backgroundColor(this.colors.tintMedium).borderRadius(10)
          .border({ width: 1, color: this.colors.borderMedium })
          .enabled(this.hijriOffset > -MAX_HIJRI_OFFSET)
          .onClick(() => { this.changeHijriOffset(-1); })

          Text(this.formatHijriOffset())
            .fontSize(16).fontWeight(FontWeight.Bold)
            .fontColor(this.hijriOffset === 0 ? this.colors.textMuted : this.colors.accentGold)
            .width(56).textAlign(TextAlign.Center)

          Button() {
            Text('+').fontSize(22).fontWeight(FontWeight.Bold)
              .fontColor(this.hijriOffset >= MAX_HIJRI_OFFSET
                ? this.colors.textMuted : this.colors.textOnAccent)
          }
          .width(38).height(38)
          .backgroundColor(this.hijriOffset >= MAX_HIJRI_OFFSET
            ? this.colors.tintMedium : this.colors.accentGold)
          .borderRadius(10)
          .enabled(this.hijriOffset < MAX_HIJRI_OFFSET)
          .onClick(() => { this.changeHijriOffset(1); })
        }
        .width('100%').alignItems(VerticalAlign.Center)

        Text(this.hijriOffsetDescription())
          .fontSize(11).fontColor(this.colors.textMuted)
          .width('100%').margin({ top: 10 })
      }
      .width('100%').padding(14)
      .backgroundColor(this.colors.tintSubtle).borderRadius(12)
    }
    .width('100%').padding(12)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(16)
    .border({ width: 1, color: this.colors.borderSoft })
    .margin({ bottom: 12 })
  }

  // ============================================================
  // ABOUT
  // ============================================================

  @Builder
  AboutContent() {
    Column() {
      Column() {
        Text(this.tr('app_name')).fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
        Text(this.tr('app_tagline')).fontSize(12).fontColor(this.colors.accentGold).margin({ top: 4 })
        Divider().color(this.colors.borderSoft).width('80%').margin({ top: 14, bottom: 14 })
        this.AboutRow(this.tr('about_version'), '1.2.0')
        this.AboutRow(this.tr('about_platform'), 'HarmonyOS')
        this.AboutRow(this.tr('about_copyright'), this.tr('app_name'))
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

  // ============================================================
  // PICKER OVERLAY
  // ============================================================

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

      Button(this.tr('cancel')).width('90%').height(48).fontSize(15).fontWeight(FontWeight.Medium)
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