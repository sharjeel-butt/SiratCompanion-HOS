// entry/src/main/ets/pages/Index.ets

import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { Theme } from '../common/Theme';
import { Prayer, ExtraTiming } from '../models/Prayer';
import { DateHelper } from '../utils/DateUtils';
import { LocationHelper, LocationData } from '../utils/LocationUtils';
import { UpcomingImportantDate } from '../models/DateModels';
import { PrayerTimeCalculator, CalculationMethod, AsrShadowRule, DailyPrayerTimes } from '../utils/PrayerTimeCalculator';
import { PrayerManager } from '../utils/PrayerManager';
import { SettingsHelper } from '../utils/SettingsHelper';
import { LocationCache, FALLBACK_LOCATION } from '../utils/LocationCache';
import { CalculationSource } from '../models/SettingsModels';
import {
  STORAGE_KEY_CALC_METHOD,
  STORAGE_KEY_ASR_RULE,
  STORAGE_KEY_CALC_SOURCE
} from '../common/StorageKeys';

// ============================================================
// INTERFACES
// ============================================================

interface DialogResult {
  index: number;
}

// ============================================================
// PAGE
// ============================================================

@Entry
@Component
struct Index {

  // ============================================================
  // STATE
  // ============================================================

  @State currentLocation: string = 'Loading...';
  @State isLoadingLocation: boolean = true;
  @State latitude: number = 0;
  @State longitude: number = 0;

  @State fullDateString: string = '';
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

  // ---- Preferences: live-linked to AppStorage ----
  @StorageLink(STORAGE_KEY_CALC_METHOD)
  @Watch('onCalcMethodChanged')
  calcMethod: CalculationMethod = CalculationMethod.KARACHI;

  @StorageLink(STORAGE_KEY_ASR_RULE)
  @Watch('onAsrRuleChanged')
  asrRule: AsrShadowRule = AsrShadowRule.STANDARD;

  @StorageLink(STORAGE_KEY_CALC_SOURCE)
  @Watch('onSourceChanged')
  calcSource: CalculationSource = CalculationSource.LOCAL;

  @State showBottomSheet: boolean = false;

  private statusTimerId: number = -1;
  private lastDateKey: string = '';

  // ============================================================
  // LIFECYCLE
  // ============================================================

  aboutToAppear(): void {
    SettingsHelper.initializeDefaults();

    this.fullDateString = DateHelper.getFormattedFullDate();
    this.upcomingImportantDates = DateHelper.getUpcomingImportantDates();

    const cached = LocationCache.load();
    if (cached) {
      this.latitude = cached.latitude;
      this.longitude = cached.longitude;
      this.currentLocation = cached.cityName;
    } else {
      this.latitude = FALLBACK_LOCATION.latitude;
      this.longitude = FALLBACK_LOCATION.longitude;
      this.currentLocation = FALLBACK_LOCATION.cityName;
    }

    this.prayers = PrayerManager.loadTodayState(this.prayers);

    this.refreshPrayerTimes();
    this.fetchLocationInBackground();

    this.lastDateKey = PrayerManager.getDateKey();

    this.statusTimerId = setInterval(() => {
      this.handleDateChange();
      this.prayers = PrayerManager.updateStatuses(this.prayers);
    }, 60000);
  }

  aboutToDisappear(): void {
    if (this.statusTimerId !== -1) {
      clearInterval(this.statusTimerId);
      this.statusTimerId = -1;
    }
  }

  onPageShow(): void {
    this.prayers = PrayerManager.updateStatuses(this.prayers);
  }

  // ============================================================
  // WATCH CALLBACKS
  // ============================================================

  private onCalcMethodChanged(): void {
    this.refreshPrayerTimes();
  }

  private onAsrRuleChanged(): void {
    this.refreshPrayerTimes();
  }

  private onSourceChanged(): void {
    this.refreshPrayerTimes();
  }

  // ============================================================
  // CORE
  // ============================================================

  private refreshPrayerTimes(): void {
    if (this.latitude === 0 && this.longitude === 0) return;
    if (this.calcSource !== CalculationSource.LOCAL) return;

    try {
      const times: DailyPrayerTimes = PrayerTimeCalculator.calculateWithDeviceTimezone(
        new Date(),
        this.latitude,
        this.longitude,
        this.calcMethod,
        this.asrRule
      );

      const updatedPrayers = PrayerManager.applyTimesToPrayers(this.prayers, times);
      this.extraTimings = PrayerManager.applyTimesToExtraTimings(this.extraTimings, times);
      this.prayers = PrayerManager.updateStatuses(updatedPrayers);

    } catch (err) {
      const error = err as Error;
      console.error(`Prayer calculation failed: ${error.message}`);
    }
  }

  private async fetchLocationInBackground(): Promise<void> {
    try {
      const data: LocationData = await LocationHelper.fetchLocationData(getContext(this));

      const changed = Math.abs(data.latitude - this.latitude) > 0.01 ||
        Math.abs(data.longitude - this.longitude) > 0.01 ||
        data.cityName !== this.currentLocation;

      this.latitude = data.latitude;
      this.longitude = data.longitude;
      this.currentLocation = data.cityName;
      this.isLoadingLocation = false;

      LocationCache.save(data.latitude, data.longitude, data.cityName);

      if (changed) {
        this.refreshPrayerTimes();
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

  private handleDateChange(): void {
    const today = PrayerManager.getDateKey();
    if (this.lastDateKey === '') {
      this.lastDateKey = today;
      return;
    }

    if (today !== this.lastDateKey) {
      this.lastDateKey = today;

      this.prayers = this.prayers.map((p): Prayer => ({
        id: p.id, name: p.name, arabicName: p.arabicName,
        time: p.time, status: p.status, checked: false
      } as Prayer));

      this.prayers = PrayerManager.loadTodayState(this.prayers);
      this.prayers = PrayerManager.updateStatuses(this.prayers);
    }
  }

  // ============================================================
  // EVENT HANDLERS
  // ============================================================

  private togglePrayer(id: string): void {
    const target = this.prayers.find(p => p.id === id);
    if (!target || !PrayerManager.isPrayerCheckable(target)) return;

    this.prayers = this.prayers.map((p): Prayer => {
      if (p.id === id) {
        return {
          id: p.id, name: p.name, arabicName: p.arabicName,
          time: p.time, status: p.status, checked: !p.checked
        } as Prayer;
      }
      return p;
    });

    PrayerManager.saveTodayState(this.prayers);
    this.prayers = PrayerManager.updateStatuses(this.prayers);
  }

  private closeBottomSheet(): void {
    animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
      this.showBottomSheet = false;
    });
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
        { text: 'Cancel', color: '#666666' },
        { text: 'Exit', color: Theme.accentGold }
      ]
    }).then((result: DialogResult) => {
      if (result.index === 1) {
        const context = getContext(this) as common.UIAbilityContext;
        context.terminateSelf()
          .catch((err: Error) => console.error('Terminate failed:', JSON.stringify(err)));
      }
    }).catch((err: Error) => {
      console.error('Dialog error:', JSON.stringify(err));
    });
  }

  // ============================================================
  // UI LOOKUPS
  // ============================================================

  private getCurrentPrayerName(): string {
    const p = PrayerManager.getCurrentPrayer(this.prayers);
    return p ? p.name : '—';
  }

  private getCurrentPrayerTime(): string {
    const p = PrayerManager.getCurrentPrayer(this.prayers);
    return p ? p.time : '--:--';
  }

  private getNextPrayerName(): string {
    const p = PrayerManager.getNextPrayer(this.prayers);
    return p ? p.name : '—';
  }

  private getNextPrayerTime(): string {
    const p = PrayerManager.getNextPrayer(this.prayers);
    return p ? p.time : '--:--';
  }

  private getStatusColor(status: string): string {
    switch (status) {
      case 'next':    return Theme.accentGold;
      case 'pray':    return '#4CAF50';
      case 'both':    return '#4CAF50';
      case 'prayed':  return Theme.accentGoldLight;
      case 'express': return '#FF9800';
      default:        return Theme.textMuted;
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
      // ---- Scrollable content ----
      Scroll() {
        Column() {
          this.HeaderWithHamburger();
          this.CurrentSettingsBar();       // <-- Current settings
          this.NextPrayerSection();

          if (this.calcSource === CalculationSource.LOCAL) {
            this.PrayersSection();
            this.ExtraTimingsSection();
          } else {
            this.ComingSoonCard();
          }

          this.ImportantDatesCard();

          Column().height(32);
        }
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Theme.primaryGreen)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)

      // ---- Dimmer ----
      if (this.showBottomSheet) {
        Column()
          .width('100%').height('100%')
          .backgroundColor('rgba(0,0,0,0.5)')
          .onClick(() => { this.closeBottomSheet(); })
          .transition({ type: TransitionType.Insert, opacity: 0 })
          .transition({ type: TransitionType.Delete, opacity: 1 })
      }

      // ---- Bottom sheet ----
      if (this.showBottomSheet) {
        Column() {
          Row()
            .width(40).height(4)
            .backgroundColor(Theme.textMuted)
            .borderRadius(2)
            .margin({ top: 8 })

          Row() {
            Text('Sirat').fontSize(24).fontWeight(FontWeight.Bold).fontColor(Theme.textWhite)
            Text('Companion').fontSize(24).fontWeight(FontWeight.Bold).fontColor(Theme.accentGold)
          }
          .width('100%').padding({ top: 16, bottom: 16 })
          .justifyContent(FlexAlign.Center)

          Divider()
            .color(Theme.textMuted).opacity(0.2).width('80%').margin({ bottom: 16 })

          Column() {
            this.BottomSheetItem('⚙️', 'Settings', () => { this.navigateToSettings(); })
            this.BottomSheetItem('🚪', 'Exit', () => {
              this.closeBottomSheet();
              setTimeout(() => { this.exitApp(); }, 320);
            })
          }
          .width('100%').padding({ left: 16, right: 16 })

          Blank()
        }
        .width('100%')
        .height(220)
        .backgroundColor(Theme.primaryGreen)
        .borderRadius({ topLeft: Theme.radiusLarge, topRight: Theme.radiusLarge })
        .shadow({ radius: 12, color: 'rgba(0,0,0,0.3)', offsetX: 0, offsetY: -4 })
        .position({ bottom: 0 })
        .transition({ type: TransitionType.Insert, translate: { x: 0, y: 220 } })
        .transition({ type: TransitionType.Delete, translate: { x: 0, y: 220 } })
      }
    }
    .width('100%').height('100%')
    .backgroundColor(Theme.primaryGreen)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  // ============================================================
  // @BUILDER METHODS
  // ============================================================

  @Builder
  HeaderWithHamburger() {
    Column() {
      Row() {
        Column() {
          Text(this.fullDateString)
            .fontSize(14)
            .fontColor(Theme.accentGold)
            .fontWeight(FontWeight.Medium)

          Row() {
            Text(this.currentLocation)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.textWhite)
            if (this.isLoadingLocation) {
              LoadingProgress()
                .width(16).height(16)
                .color(Theme.accentGold)
                .margin({ left: 8 })
            }
          }.margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .padding({ left: 16 })

        Text('☰')
          .fontSize(28)
          .fontColor(Theme.textWhite)
          .margin({ right: 16 })
          .onClick(() => { this.showBottomSheet = !this.showBottomSheet; })
      }
      .width('100%')
      .padding({ top: 32, bottom: 8, left: 8, right: 20 })
      .alignItems(VerticalAlign.Center)

      Row() {
        Text(this.getCurrentPrayerName())
          .fontSize(18).fontColor(Theme.textWhite).fontWeight(FontWeight.Medium)
        Text('  ')
        Text(this.getCurrentPrayerTime())
          .fontSize(18).fontColor(Theme.accentGold).fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .padding({ left: 20, right: 20, top: 6, bottom: 12 })
    }
    .width('100%')
    .backgroundColor(Theme.primaryGreen)
  }

  // ============================================================
  // CURRENT SETTINGS BAR (full labels)
  // ============================================================

  @Builder
  CurrentSettingsBar() {
    Column() {
      // Convention row
      Row() {
        Text('🕌')
          .fontSize(14)
        Text('Convention')
          .fontSize(11)
          .fontColor(Theme.textMuted)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 8 })
          .layoutWeight(1)
        Text(SettingsHelper.getCalcMethodLabel(this.calcMethod))
          .fontSize(11)
          .fontColor(Theme.accentGold)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .padding({ top: 6, bottom: 6, left: 12, right: 12 })

      Divider()
        .color('rgba(201,169,110,0.15)')
        .width('90%')

      // Madhab row
      Row() {
        Text('🌅')
          .fontSize(14)
        Text('Madhab')
          .fontSize(11)
          .fontColor(Theme.textMuted)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 8 })
          .layoutWeight(1)
        Text(SettingsHelper.getAsrRuleLabel(this.asrRule))
          .fontSize(11)
          .fontColor(Theme.accentGold)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .padding({ top: 6, bottom: 6, left: 12, right: 12 })

      Divider()
        .color('rgba(201,169,110,0.15)')
        .width('90%')

      // Source row
      Row() {
        Text('🌐')
          .fontSize(14)
        Text('Source')
          .fontSize(11)
          .fontColor(Theme.textMuted)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 8 })
          .layoutWeight(1)
        Text(SettingsHelper.getCalcSourceLabel(this.calcSource))
          .fontSize(11)
          .fontColor(Theme.accentGold)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .padding({ top: 6, bottom: 6, left: 12, right: 12 })
    }
    .width('92%')
    .margin({ top: 4, bottom: 12 })
    .backgroundColor('rgba(201,169,110,0.06)')
    .borderRadius(12)
    .border({ width: 1, color: 'rgba(201,169,110,0.2)' })
  }

  @Builder
  NextPrayerSection() {
    Column() {
      Row() {
        Text('NEXT PRAYER')
          .fontSize(12)
          .fontColor(Theme.textMuted)
          .letterSpacing(2)
          .fontWeight(FontWeight.Medium)

        Blank()

        Row() {
          Text(this.getNextPrayerName())
            .fontSize(16).fontColor(Theme.accentGold).fontWeight(FontWeight.Bold)
          Text('   ')
          Text(this.getNextPrayerTime())
            .fontSize(16).fontColor(Theme.textWhite).fontWeight(FontWeight.Medium)
        }
      }
      .width('100%')
      .padding({ top: 12, bottom: 12, left: 16, right: 16 })
      .backgroundColor(Theme.cardDark)
      .borderRadius(Theme.radiusMedium)
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .margin({ top: 4, bottom: 12 })
  }

  @Builder
  PrayersSection() {
    Column() {
      Row() {
        Text(`TODAY'S PRAYERS  ${this.prayers.filter(p => p.checked).length} of ${this.prayers.length}`)
          .fontSize(16)
          .fontColor(Theme.textWhite)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center)
      .padding({ left: 16, right: 16, bottom: 12 })

      Column() {
        ForEach(this.prayers, (prayer: Prayer) => {
          this.PrayerItem(prayer)
        }, (prayer: Prayer) => `${prayer.id}-${prayer.status}-${prayer.checked ? '1' : '0'}-${prayer.time}`)
      }
      .width('100%')
      .backgroundColor(Theme.cardDark)
      .borderRadius(Theme.radiusMedium)
      .padding({ left: 4, right: 4, top: 4, bottom: 4 })
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 12 })
  }

  @Builder
  PrayerItem(prayer: Prayer) {
    Row() {
      Checkbox({ name: prayer.id })
        .width(20).height(20)
        .selectedColor(Theme.accentGold)
        .select(prayer.checked || false)
        .enabled(PrayerManager.isPrayerCheckable(prayer))
        .onChange((value: boolean) => {
          if (PrayerManager.isPrayerCheckable(prayer)) {
            this.togglePrayer(prayer.id);
          }
        })

      Column() {
        Row() {
          Text(prayer.name)
            .fontSize(16)
            .fontColor(Theme.textWhite)
            .fontWeight(prayer.checked ? FontWeight.Normal : FontWeight.Medium)
            .opacity(prayer.checked ? 0.5 : 1.0)
          Text('  ')
          Text(prayer.arabicName)
            .fontSize(14)
            .fontColor(Theme.textMuted)
        }
        Text(this.getStatusLabel(prayer.status))
          .fontSize(11)
          .fontColor(this.getStatusColor(prayer.status))
          .letterSpacing(1)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(prayer.time)
        .fontSize(16)
        .fontColor(Theme.textWhite)
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .padding(12)
    .justifyContent(FlexAlign.SpaceBetween)
    .borderRadius(Theme.radiusSmall)
    .backgroundColor(prayer.checked ? 'rgba(201,169,110,0.1)' : 'transparent')
    .margin({ bottom: 4 })
  }

  @Builder
  ExtraTimingsSection() {
    Column() {
      Text('EXTRA TIMINGS')
        .fontSize(16)
        .fontColor(Theme.textWhite)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 12 })

      Column() {
        ForEach(this.extraTimings, (timing: ExtraTiming) => {
          this.ExtraTimingItem(timing)
        }, (timing: ExtraTiming) => `${timing.id}-${timing.time}`)
      }
      .width('100%')
      .backgroundColor(Theme.cardDark)
      .borderRadius(Theme.radiusMedium)
      .padding({ top: 4, bottom: 4, left: 4, right: 4 })
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .margin({ bottom: 16 })
  }

  @Builder
  ExtraTimingItem(timing: ExtraTiming) {
    Row() {
      Text(timing.icon ?? '•')
        .fontSize(22)
        .width(36)
        .textAlign(TextAlign.Center)

      Column() {
        Row() {
          Text(timing.name)
            .fontSize(16)
            .fontColor(Theme.textWhite)
            .fontWeight(FontWeight.Medium)
          Text('  ')
          Text(timing.arabicName)
            .fontSize(13)
            .fontColor(Theme.textMuted)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(timing.time)
        .fontSize(16)
        .fontColor(Theme.accentGoldLight)
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .padding({ top: 10, bottom: 10, left: 8, right: 12 })
    .alignItems(VerticalAlign.Center)
    .borderRadius(Theme.radiusSmall)
    .margin({ bottom: 2 })
  }

  @Builder
  @Builder
  ImportantDatesCard() {
    Column() {
      // ---- Section Title ----
      Row() {
        Text('📅')
          .fontSize(16)
          .margin({ right: 8 })
        Text('UPCOMING ISLAMIC EVENTS')
          .fontSize(14)
          .fontColor(Theme.accentGold)
          .fontWeight(FontWeight.Bold)
          .letterSpacing(1.5)
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .padding({ left: 4, bottom: 14 })

      // ---- Events Card ----
      Column() {
        if (this.upcomingImportantDates.length === 0) {
          Text('Loading important dates...')
            .fontSize(14)
            .fontColor(Theme.textMuted)
        } else {
          // First event
          Text(this.upcomingImportantDates[0].name.toUpperCase())
            .fontSize(14)
            .fontColor(Theme.accentGoldLight)
            .fontWeight(FontWeight.Medium)
            .textAlign(TextAlign.Center)
          Text(this.upcomingImportantDates[0].hijriDate)
            .fontSize(12)
            .fontColor(Theme.textMuted)
            .margin({ top: 4 })
            .textAlign(TextAlign.Center)

          if (this.upcomingImportantDates.length > 1) {
            Divider()
              .width('80%')
              .color(Theme.accentGoldLight)
              .opacity(0.2)
              .margin({ top: 14, bottom: 14 })

            // Second event
            Text(this.upcomingImportantDates[1].name.toUpperCase())
              .fontSize(14)
              .fontColor(Theme.accentGold)
              .fontWeight(FontWeight.Medium)
              .textAlign(TextAlign.Center)
            Text(this.upcomingImportantDates[1].hijriDate)
              .fontSize(12)
              .fontColor(Theme.textMuted)
              .margin({ top: 4 })
              .textAlign(TextAlign.Center)
          }
        }
      }
      .width('100%')
      .padding(20)
      .backgroundColor(Theme.cardDark)
      .borderRadius(Theme.radiusLarge)
      .shadow({ radius: 12, color: 'rgba(0,0,0,0.2)', offsetX: 0, offsetY: 4 })
      .alignItems(HorizontalAlign.Center)
    }
    .width('92%')
    .padding({ left: 4, right: 4 })
    .margin({ top: 4, bottom: 16 })
    .alignItems(HorizontalAlign.Start)
  }
  @Builder
  ComingSoonCard() {
    Column() {
      Text('🌐')
        .fontSize(56)
        .margin({ bottom: 12 })

      Text('Online Prayer Times')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Theme.textWhite)

      Text('Coming Soon')
        .fontSize(13)
        .fontColor(Theme.accentGold)
        .letterSpacing(1)
        .margin({ top: 4 })

      Divider()
        .width('60%')
        .color(Theme.accentGoldLight)
        .opacity(0.2)
        .margin({ top: 16, bottom: 16 })

      Text('Switch back to Local Formula in Settings to see prayer times for your location.')
        .fontSize(12)
        .fontColor(Theme.textMuted)
        .textAlign(TextAlign.Center)
        .lineHeight(18)
        .maxLines(4)
    }
    .width('92%')
    .padding(28)
    .backgroundColor(Theme.cardDark)
    .borderRadius(Theme.radiusLarge)
    .border({ width: 1, color: 'rgba(201,169,110,0.15)' })
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.2)', offsetX: 0, offsetY: 4 })
    .margin({ top: 4, bottom: 24 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  BottomSheetItem(icon: string, label: string, onClick: () => void) {
    Row() {
      Text(icon)
        .fontSize(22)
        .margin({ right: 16 })
      Text(label)
        .fontSize(16)
        .fontColor(Theme.textWhite)
    }
    .width('100%')
    .padding({ top: 12, bottom: 12, left: 16 })
    .borderRadius(Theme.radiusSmall)
    .onClick(() => { onClick(); })
  }
}