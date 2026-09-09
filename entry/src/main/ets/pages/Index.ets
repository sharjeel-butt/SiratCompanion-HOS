// entry/src/main/ets/pages/Index.ets

import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { Theme } from '../common/Theme';
import { Prayer, ExtraTiming } from '../models/Prayer';
import { BottomNavItem } from '../models/BottomNavItem';
import { DateHelper } from '../utils/DateUtils';
import { LocationHelper } from '../utils/LocationUtils';
import { UpcomingImportantDate } from '../models/DateModels';
import { PrayerTimeCalculator, CalculationMethod, AsrShadowRule } from '../utils/PrayerTimeCalculator';
import {
  STORAGE_KEY_CALC_METHOD,
  STORAGE_KEY_ASR_RULE
} from '../common/StorageKeys';

// ----- Explicit interface to avoid object literal as type -----
interface DialogResult {
  index: number;
}

@Entry
@Component
struct Index {
  // ----- State -----
  @State currentLocation: string = 'Fetching location...';
  @State isLoadingLocation: boolean = true;
  @State fullDateString: string = '';
  @State upcomingImportantDates: UpcomingImportantDate[] = [];
  @State prayers: Prayer[] = [
    { id: 'fajr', name: 'Fajr', arabicName: 'الفجر', time: '4:17 AM', status: 'next', checked: false },
    { id: 'dhuhr', name: 'Dhuhr', arabicName: 'الظهر', time: '12:07 PM', status: 'pray', checked: false },
    { id: 'asr', name: 'Asr', arabicName: 'العصر', time: '3:42 PM', status: 'express', checked: false },
    { id: 'maghrib', name: 'Maghrib', arabicName: 'المغرب', time: '6:29 PM', status: 'abbreviation', checked: false },
    { id: 'isha', name: 'Isha', arabicName: 'العشاء', time: '7:55 PM', status: 'abbreviation', checked: false }
  ];
  @State extraTimings: ExtraTiming[] = [
    { id: 'imsak', name: 'Imsak', arabicName: 'الإمساك', time: '4:07 AM', status: 'abbreviation' },
    { id: 'sunrise', name: 'Sunrise', arabicName: 'الشروق', time: '5:43 AM', status: 'abbreviation' },
    { id: 'sunset', name: 'Sunset', arabicName: 'المغرب', time: '6:29 PM', status: 'abbreviation' }
  ];
  @State bottomNavItems: BottomNavItem[] = [
    { id: 'home', label: 'Home', icon: '🏠', active: true },
    { id: 'qibla', label: 'Qibla', icon: '🕋', active: false },
    { id: 'mosques', label: 'Mosques', icon: '🕌', active: false },
    { id: 'events', label: 'Events', icon: '📅', active: false }
  ];

  // ----- Bottom sheet state -----
  @State showBottomSheet: boolean = false;

  // ----- Preferences (loaded from AppStorage) -----
  @State calcMethod: CalculationMethod = CalculationMethod.KARACHI;
  @State asrRule: AsrShadowRule = AsrShadowRule.STANDARD;

  // ----- Computed -----
  get completedCount(): number {
    return this.prayers.filter(p => p.checked).length;
  }

  // ----- Lifecycle -----
  aboutToAppear(): void {
    // Load stored preferences
    const storedMethod = AppStorage.get<string>(STORAGE_KEY_CALC_METHOD);
    if (storedMethod) {
      const methodEnum = Object.values(CalculationMethod).find(v => v === storedMethod);
      if (methodEnum !== undefined) this.calcMethod = methodEnum;
    }
    const storedAsr = AppStorage.get<number>(STORAGE_KEY_ASR_RULE);
    if (storedAsr !== undefined) this.asrRule = storedAsr;

    this.fullDateString = DateHelper.getFormattedHijriDate();
    this.upcomingImportantDates = DateHelper.getUpcomingImportantDates();
    this.fetchLocation();
    this.updatePrayerTimes();
  }

  // ----- Location handling -----
  async fetchLocation(): Promise<void> {
    try {
      const city = await LocationHelper.fetchCityName(getContext(this));
      this.currentLocation = city;
    } catch (err) {
      const error = err as Error;
      if (error.message === 'GPS_OFF') {
        this.currentLocation = 'GPS is off';
        await LocationHelper.showLocationDisabledDialog();
      } else if (error.message === 'PERMISSION_DENIED') {
        this.currentLocation = 'Permission denied';
        await LocationHelper.showPermissionDeniedDialog();
      } else {
        this.currentLocation = 'Location unavailable';
      }
    } finally {
      this.isLoadingLocation = false;
    }
  }

  // ----- Update prayer times (placeholder) -----
  updatePrayerTimes(): void {
    // TODO: Use PrayerTimeCalculator to set actual times based on calcMethod and asrRule
  }

  // ----- UI event handlers -----
  togglePrayer(id: string): void {
    this.prayers = this.prayers.map(p => {
      if (p.id === id) {
        return {
          id: p.id,
          name: p.name,
          arabicName: p.arabicName,
          time: p.time,
          status: p.status,
          checked: !p.checked
        } as Prayer;
      }
      return p;
    });
  }

  selectBottomNav(id: string): void {
    this.bottomNavItems = this.bottomNavItems.map(item => ({
      id: item.id,
      label: item.label,
      icon: item.icon,
      active: item.id === id
    } as BottomNavItem));
  }

  getStatusColor(status: string): string {
    switch (status) {
      case 'next': return Theme.accentGold;
      case 'pray': return '#4CAF50';
      case 'express': return '#FF9800';
      default: return Theme.textMuted;
    }
  }

  getStatusLabel(status: string): string {
    switch (status) {
      case 'next': return 'NEXT';
      case 'pray': return 'Pray';
      case 'express': return 'Express';
      case 'abbreviation': return 'The Abbreviation';
      default: return '';
    }
  }

  // ----- Bottom sheet control -----
  private closeBottomSheet(): void {
    animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
      this.showBottomSheet = false;
    });
  }

  private navigateToSettings(): void {
    this.closeBottomSheet();
    setTimeout(() => {
      router.pushUrl({ url: 'pages/SettingsPage' })
        .then(() => console.info('Navigation to Settings succeeded'))
        .catch((err: Error) => console.error('Navigation failed:', JSON.stringify(err)));
    }, 320);
  }

  private navigateToAbout(): void {
    this.closeBottomSheet();
    setTimeout(() => {
      promptAction.showToast({ message: 'Sirat Companion v1.0.0' });
    }, 320);
  }

  // ----- Exit app with confirmation (FIXED: uses DialogResult interface) -----
  private exitApp(): void {
    promptAction.showDialog({
      title: 'Exit',
      message: 'Are you sure you want to exit Sirat Companion?',
      buttons: [
        { text: 'Cancel', color: '#666666' },
        { text: 'Exit', color: Theme.accentGold }
      ]
    }).then((result: DialogResult) => { // <-- FIXED: uses interface, not inline type
      if (result.index === 1) {
        const context = getContext(this) as common.UIAbilityContext;
        context.terminateSelf()
          .then(() => console.info('App terminated'))
          .catch((err: Error) => console.error('Terminate failed:', JSON.stringify(err)));
      }
    }).catch((err: Error) => {
      console.error('Dialog error:', JSON.stringify(err));
    });
  }

  // ----- Build -----
  build() {
    Stack() {
      // ---- Main content ----
      Column() {
        this.HeaderWithHamburger();
        Scroll() {
          Column() {
            this.HeaderSectionContent();
            this.ImportantDatesCard();
            this.PrayersSection();
            this.ExtraTimingsSection();
            this.BottomNavigation();
          }
          .width('100%')
        }
        .height('100%')
        .width('100%')
        .backgroundColor(Theme.primaryGreen)
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Theme.primaryGreen)

      // ---- Dimmer overlay (fades in/out) ----
      if (this.showBottomSheet) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0,0,0,0.5)')
          .onClick(() => {
            this.closeBottomSheet();
          })
          .transition({
            type: TransitionType.Insert,
            opacity: 0
          })
          .transition({
            type: TransitionType.Delete,
            opacity: 1
          })
      }

      // ---- Bottom sheet (slides up/down) ----
      if (this.showBottomSheet) {
        Column() {
          // Drag handle
          Row()
            .width(40)
            .height(4)
            .backgroundColor(Theme.textMuted)
            .borderRadius(2)
            .margin({ top: 8 })

          // App name header
          Row() {
            Text('Sirat')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.textWhite)
            Text('Companion')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.accentGold)
          }
          .width('100%')
          .padding({ top: 16, bottom: 16 })
          .justifyContent(FlexAlign.Center)

          Divider()
            .color(Theme.textMuted)
            .opacity(0.2)
            .width('80%')
            .margin({ bottom: 16 })

          // Menu items (Settings, About, Exit)
          Column() {
            this.BottomSheetItem('⚙️', 'Settings', () => { this.navigateToSettings(); })
            this.BottomSheetItem('ℹ️', 'About', () => { this.navigateToAbout(); })
            this.BottomSheetItem('🚪', 'Exit', () => {
              this.closeBottomSheet();
              setTimeout(() => {
                this.exitApp();
              }, 320);
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16 })

          Blank()
        }
        .width('100%')
        .height(280)
        .backgroundColor(Theme.primaryGreen)
        .borderRadius({ topLeft: Theme.radiusLarge, topRight: Theme.radiusLarge })
        .shadow({ radius: 12, color: 'rgba(0,0,0,0.3)', offsetX: 0, offsetY: -4 })
        .position({ bottom: 0 })
        .transition({
          type: TransitionType.Insert,
          translate: { x: 0, y: 280 }
        })
        .transition({
          type: TransitionType.Delete,
          translate: { x: 0, y: 280 }
        })
      }
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  // ----- @Builder methods -----

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

  @Builder
  HeaderWithHamburger() {
    Row() {
      Column() {
        Text(this.fullDateString)
          .fontSize(14)
          .fontColor(Theme.accentGold)
          .fontWeight(FontWeight.Medium)
        Text(this.currentLocation)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.textWhite)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .padding({ left: 16 })

      Text('☰')
        .fontSize(28)
        .fontColor(Theme.textWhite)
        .margin({ right: 16 })
        .onClick(() => {
          this.showBottomSheet = !this.showBottomSheet;
        })
    }
    .width('100%')
    .padding({ top: 32, bottom: 12, right: 20 })
    .backgroundColor(Theme.primaryGreen)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  HeaderSectionContent() {
    Column() {
      Row() {
        Text('Dhuhr')
          .fontSize(18)
          .fontColor(Theme.textWhite)
          .fontWeight(FontWeight.Medium)
        Text('  ')
        Text('12:07 PM')
          .fontSize(18)
          .fontColor(Theme.accentGold)
          .fontWeight(FontWeight.Bold)
      }
      .margin({ top: 8 })

      Divider()
        .width('60%')
        .color(Theme.accentGold)
        .opacity(0.3)
        .margin({ top: 12, bottom: 8 })

      Row() {
        Text('NEXT PRAYER')
          .fontSize(12)
          .fontColor(Theme.textMuted)
          .letterSpacing(2)
        Text('  ')
        Text('Asr')
          .fontSize(14)
          .fontColor(Theme.accentGold)
          .fontWeight(FontWeight.Bold)
        Text('  ')
        Text('3:42 PM')
          .fontSize(14)
          .fontColor(Theme.textWhite)
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20, bottom: 16 })
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(Theme.primaryGreen)
  }

  @Builder
  ImportantDatesCard() {
    Column() {
      if (this.upcomingImportantDates.length === 0) {
        Text('Loading important dates...')
          .fontSize(14)
          .fontColor(Theme.textMuted)
      } else {
        Text(this.upcomingImportantDates[0].name.toUpperCase())
          .fontSize(14)
          .fontColor(Theme.accentGoldLight)
          .fontWeight(FontWeight.Medium)
        Text(this.upcomingImportantDates[0].hijriDate)
          .fontSize(12)
          .fontColor(Theme.textMuted)
          .margin({ top: 2 })

        Divider()
          .width('80%')
          .color(Theme.accentGoldLight)
          .opacity(0.2)
          .margin({ top: 8, bottom: 8 })

        if (this.upcomingImportantDates.length > 1) {
          Text(this.upcomingImportantDates[1].name.toUpperCase())
            .fontSize(14)
            .fontColor(Theme.accentGold)
            .fontWeight(FontWeight.Medium)
          Text(this.upcomingImportantDates[1].hijriDate)
            .fontSize(12)
            .fontColor(Theme.textMuted)
            .margin({ top: 2 })
        }
      }
    }
    .width('92%')
    .padding(20)
    .backgroundColor(Theme.cardDark)
    .borderRadius(Theme.radiusLarge)
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.2)', offsetX: 0, offsetY: 4 })
    .margin({ top: 10, bottom: 16 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  PrayersSection() {
    Column() {
      Row() {
        Text(`TODAY'S PRAYERS  ${this.completedCount} of ${this.prayers.length}`)
          .fontSize(16)
          .fontColor(Theme.textWhite)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 12 })

      Column() {
        ForEach(this.prayers, (prayer: Prayer) => {
          this.PrayerItem(prayer)
        }, (prayer: Prayer) => prayer.id)
      }
      .width('100%')
      .backgroundColor(Theme.cardDark)
      .borderRadius(Theme.radiusMedium)
      .padding({ left: 4, right: 4, top: 4, bottom: 4 })
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .margin({ bottom: 12 })
  }

  @Builder
  PrayerItem(prayer: Prayer) {
    Row() {
      Checkbox({ name: prayer.id })
        .width(20)
        .height(20)
        .selectedColor(Theme.accentGold)
        .select(prayer.checked || false)
        .onChange((value: boolean) => {
          this.togglePrayer(prayer.id);
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
        }, (timing: ExtraTiming) => timing.id)
      }
      .width('100%')
      .backgroundColor(Theme.cardDark)
      .borderRadius(Theme.radiusMedium)
      .padding({ left: 4, right: 4, top: 4, bottom: 4 })
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .margin({ bottom: 16 })
  }

  @Builder
  ExtraTimingItem(timing: ExtraTiming) {
    Row() {
      Row() {
        Row()
          .width(20)
          .height(20)
          .borderRadius(2)
          .border({ width: 1, color: Theme.textMuted, style: BorderStyle.Solid })
          .opacity(0.3)
          .margin({ right: 12 })

        Column() {
          Row() {
            Text(timing.name)
              .fontSize(16)
              .fontColor(Theme.textWhite)
            Text('  ')
            Text(timing.arabicName)
              .fontSize(14)
              .fontColor(Theme.textMuted)
          }
          Text(this.getStatusLabel(timing.status))
            .fontSize(11)
            .fontColor(Theme.textMuted)
            .letterSpacing(1)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .layoutWeight(1)

      Text(timing.time)
        .fontSize(16)
        .fontColor(Theme.textWhite)
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .padding(12)
    .justifyContent(FlexAlign.SpaceBetween)
    .margin({ bottom: 4 })
  }

  @Builder
  BottomNavigation() {
    Row() {
      ForEach(this.bottomNavItems, (item: BottomNavItem) => {
        this.BottomNavItem(item)
      }, (item: BottomNavItem) => item.id)
    }
    .width('100%')
    .height(64)
    .backgroundColor(Theme.cardDark)
    .padding({ left: 16, right: 16 })
    .justifyContent(FlexAlign.SpaceAround)
    .borderRadius({ topLeft: Theme.radiusLarge, topRight: Theme.radiusLarge })
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.2)', offsetX: 0, offsetY: -4 })
  }

  @Builder
  BottomNavItem(item: BottomNavItem) {
    Column() {
      Text(item.icon)
        .fontSize(24)
        .fontColor(item.active ? Theme.accentGold : Theme.textMuted)
      Text(item.label)
        .fontSize(12)
        .fontColor(item.active ? Theme.accentGold : Theme.textMuted)
        .margin({ top: 4 })
    }
    .padding({ left: 12, right: 12 })
    .onClick(() => {
      this.selectBottomNav(item.id);
    })
    .opacity(item.active ? 1.0 : 0.6)
  }
}