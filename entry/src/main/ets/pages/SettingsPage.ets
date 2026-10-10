// entry/src/main/ets/pages/SettingsPage.ets

import { mediaquery, promptAction, router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { pasteboard } from '@kit.BasicServicesKit';
import { ThemeColors, ThemeMode, ThemePreset } from '../common/Theme';
import { PageTheme } from '../common/PageTheme';
import {
  AsrShadowRule, CalculationMethod
} from '../prayer/PrayerTimeCalculator';
import { PrayerOffsets, SettingsHelper } from '../helper/SettingsHelper';
import { LocationData, LocationHelper } from '../utils/LocationUtils';
import { LocationCache } from '../utils/LocationCache';
import {
  CalculationSource, LocationMode, PickerItem
} from '../models/SettingsModels';
import {
  STORAGE_KEY_APP_FOREGROUND_TICK,
  STORAGE_KEY_APP_THEME,
  STORAGE_KEY_BREAKPOINT,
  STORAGE_KEY_HIJRI_CALENDAR_TYPE,
  STORAGE_KEY_HIJRI_OFFSET,
  STORAGE_KEY_LANGUAGE,
  STORAGE_KEY_THEME_MODE
} from '../common/StorageKeys';
import { HijriCalendarType } from '../hijricalendar/HijriCalendarType';
import {
  OffsetKey, PrayerOffsetsHelper
} from '../prayer/PrayerOffsetsHelper';
import {
  MAX_BEFORE_MINUTES,
  MIN_BEFORE_MINUTES,
  NotificationHelper,
  STEP_BEFORE_MINUTES
} from '../helper/NotificationHelper';
import { AppLogger } from '../helper/AppLogger';
import { AppInfoHelper, AppInfoSnapshot } from '../helper/AppInfoHelper';
import { L } from '../helper/LocalizationHelper';
import { Breakpoints } from '../common/Breakpoints';
import {
  CALENDAR_REMINDERS_ENABLED, NOTIFICATIONS_ENABLED
} from '../common/FeatureFlags';
import { NavHelper } from '../helper/NavHelper';

const MAX_HIJRI_OFFSET = 3;

type PickerKind = 'none' | 'method' | 'asr' | 'source' | 'hijriType';

@Entry
@Component
struct SettingsPage {
  // ---- storage links ----
  @StorageLink(STORAGE_KEY_THEME_MODE)
  @Watch('onThemeModeChanged')
  themeMode: string = ThemeMode.SYSTEM;
  @StorageLink(STORAGE_KEY_LANGUAGE)
  @Watch('onLanguageChanged')
  appLanguage: string = 'en';
  @StorageLink(STORAGE_KEY_HIJRI_OFFSET)
  hijriOffset: number = 0;
  @StorageLink(STORAGE_KEY_HIJRI_CALENDAR_TYPE)
  hijriCalendarType: string = HijriCalendarType.UMM_AL_QURA;
  @StorageLink(STORAGE_KEY_APP_FOREGROUND_TICK)
  @Watch('onAppForegrounded')
  appForegroundTick: number = 0;
  @StorageLink(STORAGE_KEY_BREAKPOINT)
  breakpoint: string = 'sm';
  @StorageLink(STORAGE_KEY_APP_THEME)
  @Watch('onAppThemePresetChanged')
  appThemePreset: string = ThemePreset.SIRAT;
  // ---- state ----
  @State colors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);
  @State calcMethod: CalculationMethod = CalculationMethod.KARACHI;
  @State asrRule: AsrShadowRule = AsrShadowRule.STANDARD;
  @State calcSource: CalculationSource = CalculationSource.LOCAL;
  @State showOffsets: boolean = false;
  @State offsets: PrayerOffsets = {
    fajr: 0,
    dhuhr: 0,
    asr: 0,
    maghrib: 0,
    isha: 0
  };
  @State locationMode: LocationMode = LocationMode.GPS;
  @State manualLatInput: string = '';
  @State manualLngInput: string = '';
  @State manualCityInput: string = '';
  @State effectiveLat: number = 0;
  @State effectiveLng: number = 0;
  @State effectiveCity: string = '';
  @State lastRefreshTime: number = 0;
  @State isRefreshing: boolean = false;

  @State notifMaster: boolean = false;
  @State notifBefore: number = 10;
  @State notifFajr: boolean = true;
  @State notifDhuhr: boolean = true;
  @State notifAsr: boolean = true;
  @State notifMaghrib: boolean = true;
  @State notifIsha: boolean = true;
  @State notifDiagnostic: string = '';

  @State showLogViewer: boolean = false;
  @State showPickerSheet: boolean = false;
  @State logContents: string = '';

  @State expandedCategory: string | null = 'Location';
  @State activePicker: PickerKind = 'none';

  @State private currentLanguage: string = 'en';
  private systemDarkListener: mediaquery.MediaQueryListener | null = null;

  @State private appInfo: AppInfoSnapshot = {
    name: '—',
    versionName: '—',
    versionCode: 0,
    bundleName: '—'
  };

  // ============================================================
  // LIFECYCLE
  // ============================================================

  aboutToAppear(): void {
    this.currentLanguage = this.appLanguage;
    this.colors = PageTheme.compute(this.themeMode);
    this.systemDarkListener = PageTheme.installSystemListener(
      this.themeMode,
      (c) => {
        this.colors = c;
      }
    );
    const ctx = getContext(this) as common.UIAbilityContext;
    this.appInfo = AppInfoHelper.get(ctx);
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

  // ============================================================
  // BUILD
  // ============================================================

  build() {
    Column() {
      this.TopBar()

      Scroll() {
        Row() {
          Column() {
            this.CategoryHeader(
              this.tr('category_location'), '📍', 'Location'
            )
            if (this.expandedCategory === 'Location') {
              this.LocationContent()
            }

            this.CategoryHeader(
              this.tr('category_prayer_times'), '🕌', 'Prayer Times'
            )
            if (this.expandedCategory === 'Prayer Times') {
              this.PrayerTimesContent()
            }

            if (NOTIFICATIONS_ENABLED || CALENDAR_REMINDERS_ENABLED) {
              this.CategoryHeader(
                this.tr('category_notifications'), '🔔', 'Notifications'
              )
              if (this.expandedCategory === 'Notifications') {
                this.NotificationsContent()
              }
            }

            this.CategoryHeader(
              this.tr('category_hijri_calendar'), '📅', 'Hijri Calendar'
            )
            if (this.expandedCategory === 'Hijri Calendar') {
              this.HijriCalendarContent()
            }

            this.CategoryHeader(
              this.tr('category_about'), 'ℹ️', 'About'
            )
            if (this.expandedCategory === 'About') {
              this.AboutContent()
            }

            if (!NOTIFICATIONS_ENABLED && !CALENDAR_REMINDERS_ENABLED) {
              this.LogAccessRow()
            }

            Column().height(40)
          }
          .width('100%')
          .constraintSize({
            maxWidth: Breakpoints.maxContentWidth(this.breakpoint)
          })
          .padding({ left: 16, right: 16, top: 20 })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor(this.colors.primaryGreen)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.primaryGreen)
    .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
    .bindSheet($$this.showPickerSheet, this.PickerSheet(), {
      height: 520,
      dragBar: true,
      showClose: false,
      backgroundColor: this.colors.cardDark,
      blurStyle: BlurStyle.Thick,
      maskColor: this.colors.overlayDim,
      onDisappear: () => {
        this.showPickerSheet = false;
        this.activePicker = 'none';
      }
    })
    .bindSheet($$this.showLogViewer, this.LogViewerSheet(), {
      height: 640,
      dragBar: true,
      showClose: false,
      backgroundColor: this.colors.cardDark,
      blurStyle: BlurStyle.Thick,
      maskColor: this.colors.overlayDim,
      onDisappear: () => {
        this.showLogViewer = false;
      }
    })
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  @Builder
  TopBar() {
    Row() {
      Text('←')
        .fontSize(26)
        .fontColor(this.colors.textWhite)
        .width(40)
        .height(40)
        .textAlign(TextAlign.Center)
        .borderRadius(20)
        .backgroundColor(this.colors.tintSoft)
        .margin({ left: 16 })
        .onClick(() => router.back())

      Text(this.tr('title_settings'))
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.colors.textWhite)
        .margin({ left: 16 })
    }
    .width('100%')
    .height(72)
    .backgroundColor(this.colors.cardDark)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  CategoryHeader(title: string, icon: string, categoryKey: string) {
    Row() {
      Text(icon)
        .fontSize(18)
        .width(40)
        .height(40)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.colors.tintSoft)
        .borderRadius(12)
        .border({ width: 1, color: this.colors.borderSoft })

      Text(title)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.colors.textWhite)
        .margin({ left: 14 })
        .layoutWeight(1)

      Text(this.expandedCategory === categoryKey ? '▲' : '▼')
        .fontSize(12)
        .fontColor(this.colors.accentGold)
        .opacity(0.8)
    }
    .width('100%')
    .padding({
      top: 12,
      bottom: 12,
      left: 12,
      right: 16
    })
    .backgroundColor(this.colors.cardDark)
    .borderRadius(16)
    .border({ width: 1, color: this.colors.borderSoft })
    .margin({ bottom: 8 })
    .onClick(() => {
      this.expandedCategory =
        this.expandedCategory === categoryKey ? null : categoryKey;
    })
  }

  // ============================================================
  // LOCATION
  // ============================================================

  @Builder
  LocationContent() {
    Column() {
      Row() {
        Text(this.tr('location_desc'))
          .fontSize(11).fontColor(this.colors.textMuted)
          .layoutWeight(1)

        Button() {
          if (this.isRefreshing) {
            LoadingProgress()
              .width(18).height(18)
              .color(this.colors.accentGold)
          } else {
            Text('📡').fontSize(18).fontColor(this.colors.accentGold)
          }
        }
        .width(36)
        .height(36)
        .backgroundColor(this.colors.tintMedium)
        .borderRadius(10)
        .border({ width: 1, color: this.colors.borderStrong })
        .onClick(() => {
          this.refreshLocation();
        })
      }
      .width('100%')
      .padding({ bottom: 14 })
      .alignItems(VerticalAlign.Center)

      Row() {
        this.ModeButton(this.tr('gps'), LocationMode.GPS)
        this.ModeButton(this.tr('manual_location'), LocationMode.MANUAL)
      }
      .width('100%')
      .padding({ bottom: 14 })

      if (this.locationMode === LocationMode.MANUAL) {
        Column() {
          Column() {
            Text(this.tr('latitude_hint'))
              .fontSize(11).fontColor(this.colors.textMuted)
              .width('100%').margin({ bottom: 4 })
            TextInput({
              text: this.manualLatInput,
              placeholder: 'e.g. 33.6844'
            })
              .type(InputType.Normal)
              .inputFilter('[\\-0-9\\.]')
              .direction(Direction.Ltr)
              .onChange((v: string) => {
                this.manualLatInput = v;
              })
              .fontSize(14)
              .fontColor(this.colors.textWhite)
              .placeholderColor(this.colors.placeholder)
              .caretColor(this.colors.accentGold)
              .backgroundColor(this.colors.tintSoft)
              .borderRadius(8)
              .padding({
                left: 12,
                right: 12,
                top: 8,
                bottom: 8
              })
          }
          .width('100%').margin({ bottom: 10 })

          Column() {
            Text(this.tr('longitude_hint'))
              .fontSize(11).fontColor(this.colors.textMuted)
              .width('100%').margin({ bottom: 4 })
            TextInput({
              text: this.manualLngInput,
              placeholder: 'e.g. 73.0479'
            })
              .type(InputType.Normal)
              .inputFilter('[\\-0-9\\.]')
              .direction(Direction.Ltr)
              .onChange((v: string) => {
                this.manualLngInput = v;
              })
              .fontSize(14)
              .fontColor(this.colors.textWhite)
              .placeholderColor(this.colors.placeholder)
              .caretColor(this.colors.accentGold)
              .backgroundColor(this.colors.tintSoft)
              .borderRadius(8)
              .padding({
                left: 12,
                right: 12,
                top: 8,
                bottom: 8
              })
          }
          .width('100%').margin({ bottom: 10 })

          Column() {
            Text(this.tr('city_name_optional'))
              .fontSize(11).fontColor(this.colors.textMuted)
              .width('100%').margin({ bottom: 4 })
            TextInput({
              text: this.manualCityInput,
              placeholder: this.tr('city_name_placeholder')
            })
              .type(InputType.Normal)
              .onChange((v: string) => {
                this.manualCityInput = v;
              })
              .fontSize(14)
              .fontColor(this.colors.textWhite)
              .placeholderColor(this.colors.placeholder)
              .caretColor(this.colors.accentGold)
              .backgroundColor(this.colors.tintSoft)
              .borderRadius(8)
              .padding({
                left: 12,
                right: 12,
                top: 8,
                bottom: 8
              })
          }
          .width('100%').margin({ bottom: 12 })

          Button() {
            Text(this.tr('save_coordinates'))
              .fontSize(14).fontWeight(FontWeight.Medium)
              .fontColor(this.colors.textOnAccent)
          }
          .width('100%')
          .height(44)
          .backgroundColor(this.colors.accentGold)
          .borderRadius(10)
          .onClick(() => {
            this.saveManualCoords();
          })
        }
        .width('100%').padding({ bottom: 14 })
      }

      Column() {
        Row() {
          Text(this.tr('current_position'))
            .fontSize(11).fontColor(this.colors.accentGold)
            .fontWeight(FontWeight.Medium).letterSpacing(1)
        }
        .width('100%').padding({ bottom: 8 })

        Row() {
          Text(this.tr('latitude'))
            .fontSize(12).fontColor(this.colors.textMuted)
          Blank()
          Text(this.formatCoord(this.effectiveLat))
            .fontSize(12).fontColor(this.colors.textWhite)
            .fontWeight(FontWeight.Medium).direction(Direction.Ltr)
        }
        .width('100%').padding({ top: 4, bottom: 4 })

        Row() {
          Text(this.tr('longitude'))
            .fontSize(12).fontColor(this.colors.textMuted)
          Blank()
          Text(this.formatCoord(this.effectiveLng))
            .fontSize(12).fontColor(this.colors.textWhite)
            .fontWeight(FontWeight.Medium).direction(Direction.Ltr)
        }
        .width('100%').padding({ top: 4, bottom: 4 })

        Row() {
          Text(this.tr('city'))
            .fontSize(12).fontColor(this.colors.textMuted)
          Blank()
          Text(this.effectiveCity)
            .fontSize(12).fontColor(this.colors.textWhite)
            .fontWeight(FontWeight.Medium)
        }
        .width('100%').padding({ top: 4, bottom: 4 })

        Row() {
          Text(this.tr('last_refreshed'))
            .fontSize(12).fontColor(this.colors.textMuted)
          Blank()
          Text(this.formatRefreshTime(this.lastRefreshTime))
            .fontSize(12).fontColor(this.colors.accentGold)
            .fontWeight(FontWeight.Medium).direction(Direction.Ltr)
        }
        .width('100%').padding({ top: 4, bottom: 4 })
      }
      .width('100%')
      .padding(12)
      .backgroundColor(this.colors.tintSubtle)
      .borderRadius(10)
      .border({ width: 1, color: this.colors.borderSoft })
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(16)
    .border({ width: 1, color: this.colors.borderSoft })
    .margin({ bottom: 12 })
  }

  @Builder
  ModeButton(label: string, mode: LocationMode) {
    Text(label)
      .fontSize(12)
      .fontWeight(this.locationMode === mode
        ? FontWeight.Bold : FontWeight.Normal)
      .fontColor(this.locationMode === mode
        ? this.colors.textOnAccent : this.colors.textWhite)
      .backgroundColor(this.locationMode === mode
        ? this.colors.accentGold : this.colors.tintSoft)
      .textAlign(TextAlign.Center)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .height(38)
      .layoutWeight(1)
      .borderRadius(10)
      .margin({
        right: mode === LocationMode.GPS ? 6 : 0,
        left: mode === LocationMode.MANUAL ? 6 : 0
      })
      .onClick(() => {
        this.pickLocationMode(mode);
      })
  }

  // ============================================================
  // PRAYER TIMES
  // ============================================================

  @Builder
  PrayerTimesContent() {
    Column() {
      this.SettingsRow(
        this.tr('convention'),
        this.tr('convention_desc'),
        SettingsHelper.getCalcMethodLabel(this.calcMethod),
        () => {
          this.activePicker = 'method';
          this.showPickerSheet = true;
        }
      )

      this.SettingsRow(
        this.tr('madhab'),
        this.tr('madhab_desc'),
        SettingsHelper.getAsrRuleLabel(this.asrRule),
        () => {
          this.activePicker = 'asr';
          this.showPickerSheet = true;
        }
      )

      this.SettingsRow(
        this.tr('source'),
        this.tr('source_desc'),
        SettingsHelper.getCalcSourceLabel(this.calcSource),
        () => {
          this.activePicker = 'source';
          this.showPickerSheet = true;
        }
      )

      this.PrayerOffsetsCard()

      this.SettingsRow(
        this.tr('advanced_calc_title'),
        '',
        this.tr('rounding_method') + ' · '
          + this.tr('midnight_method') + ' · '
          + this.tr('high_latitude'),
        () => {
          NavHelper.prepareForward();
          router.pushUrl({ url: 'pages/AdvancedCalcPage' })
            .catch((err: Error) =>
            console.error('Navigation failed: ' + err.message));
        }
      )
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(16)
    .border({ width: 1, color: this.colors.borderSoft })
    .margin({ bottom: 12 })
  }

  @Builder
  SettingsRow(
    title: string, description: string, value: string,
    onTap: () => void
  ) {
    Row() {
      Column() {
        Text(title)
          .fontSize(15).fontColor(this.colors.textWhite)
          .fontWeight(FontWeight.Medium)
        if (description.length > 0) {
          Text(description)
            .fontSize(11)
            .fontColor(this.colors.textMuted)
            .margin({ top: 2 })
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        Text(value)
          .fontSize(12)
          .fontColor(this.colors.accentGold)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 6 })
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)

      Text('›').fontSize(22)
        .fontColor(this.colors.accentGold).opacity(0.7)
    }
    .width('100%')
    .padding({
      top: 14,
      bottom: 14,
      left: 16,
      right: 16
    })
    .backgroundColor(this.colors.tintSubtle)
    .borderRadius(12)
    .margin({ bottom: 8 })
    .onClick(onTap)
  }

  @Builder
  PrayerOffsetsCard() {
    Column() {
      Row() {
        Column() {
          Text(this.tr('prayer_offsets'))
            .fontSize(15).fontColor(this.colors.textWhite)
            .fontWeight(FontWeight.Medium)
          Text(this.tr('prayer_offsets_desc'))
            .fontSize(11).fontColor(this.colors.textMuted)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        Text(this.showOffsets ? '▲' : '▼')
          .fontSize(12).fontColor(this.colors.accentGold).opacity(0.8)
      }
      .width('100%')
      .padding({
        top: 14,
        bottom: 14,
        left: 16,
        right: 16
      })
      .onClick(() => {
        this.showOffsets = !this.showOffsets;
      })

      if (this.showOffsets) {
        Divider().color(this.colors.borderSoft).width('90%')
        Column() {
          Text(this.tr('offsets_hint'))
            .fontSize(11)
            .fontColor(this.colors.textMuted)
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 10, bottom: 8 })

          this.OffsetRow(this.tr('prayer_fajr'), 'fajr')
          this.OffsetRow(this.tr('prayer_dhuhr'), 'dhuhr')
          this.OffsetRow(this.tr('prayer_asr'), 'asr')
          this.OffsetRow(this.tr('prayer_maghrib'), 'maghrib')
          this.OffsetRow(this.tr('prayer_isha'), 'isha')

          Button() {
            Text(this.tr('reset_all_offsets'))
              .fontSize(13).fontWeight(FontWeight.Medium)
              .fontColor(this.colors.textWhite)
          }
          .width('100%')
          .height(38)
          .backgroundColor(this.colors.tintSoft)
          .borderRadius(10)
          .margin({ top: 10, bottom: 4 })
          .onClick(() => {
            this.resetOffsets();
          })
        }
        .width('100%').padding({ left: 8, right: 8, bottom: 12 })
      }
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
    .backgroundColor(this.colors.tintSubtle)
    .borderRadius(12)
    .margin({ top: 8, bottom: 8 })
  }

  @Builder
  OffsetRow(label: string, key: OffsetKey) {
    Row() {
      Text(label).fontSize(14).fontColor(this.colors.textWhite)
        .layoutWeight(1)

      Button() {
        Text('\u2212').fontSize(24).fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textWhite)
      }
      .width(38)
      .height(38)
      .backgroundColor(this.colors.tintMedium)
      .borderRadius(10)
      .border({ width: 1, color: this.colors.borderMedium })
      .onClick(() => {
        this.changeOffset(key, -1);
      })

      Text(PrayerOffsetsHelper.format(
        PrayerOffsetsHelper.get(this.offsets, key)))
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(PrayerOffsetsHelper.get(this.offsets, key) === 0
          ? this.colors.textMuted : this.colors.accentGold)
        .width(56)
        .textAlign(TextAlign.Center)

      Button() {
        Text('+').fontSize(24).fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textOnAccent)
      }
      .width(38)
      .height(38)
      .backgroundColor(this.colors.accentGold)
      .borderRadius(10)
      .onClick(() => {
        this.changeOffset(key, 1);
      })
    }
    .width('100%')
    .padding({
      top: 8,
      bottom: 8,
      left: 8,
      right: 8
    })
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  @Builder
  NotificationsContent() {
    Column() {
      Row() {
        Column() {
          Text(this.tr('notifications_master'))
            .fontSize(15).fontColor(this.colors.textWhite)
            .fontWeight(FontWeight.Medium)
          Text(this.tr('notifications_master_desc'))
            .fontSize(11).fontColor(this.colors.textMuted)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        Toggle({ type: ToggleType.Switch, isOn: this.notifMaster })
          .selectedColor(this.colors.accentGold)
          .onChange((isOn: boolean) => {
            this.toggleNotifMaster(isOn);
          })
      }
      .width('100%')
      .padding({
        top: 14,
        bottom: 14,
        left: 16,
        right: 16
      })
      .backgroundColor(this.colors.tintSubtle)
      .borderRadius(12)
      .margin({ bottom: 8 })

      Button() {
        Text(this.tr('notif_test_button'))
          .fontSize(14).fontWeight(FontWeight.Medium)
          .fontColor(this.colors.textOnAccent)
      }
      .width('100%')
      .height(42)
      .backgroundColor(this.colors.accentGold)
      .borderRadius(10)
      .margin({ bottom: 8 })
      .enabled(this.notifMaster)
      .opacity(this.notifMaster ? 1.0 : 0.5)
      .onClick(() => {
        this.sendTestNotification();
      })

      if (this.notifDiagnostic.length > 0) {
        Row() {
          Text('⚠️').fontSize(12).margin({ right: 6 })
          Text(this.notifDiagnostic)
            .fontSize(11)
            .fontColor(this.colors.textMuted)
            .layoutWeight(1)
            .maxLines(4)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .padding(10)
        .backgroundColor(this.colors.tintSubtle)
        .borderRadius(8)
        .margin({ bottom: 8 })
        .alignItems(VerticalAlign.Top)
      }

      if (this.notifMaster) {
        Column() {
          Row() {
            Column() {
              Text(this.tr('notify_before'))
                .fontSize(15).fontColor(this.colors.textWhite)
                .fontWeight(FontWeight.Medium)
              Text(this.tr('notify_before_desc'))
                .fontSize(11).fontColor(this.colors.textMuted)
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start).layoutWeight(1)

            Button() {
              Text('\u2212').fontSize(20).fontWeight(FontWeight.Bold)
                .fontColor(this.notifBefore <= MIN_BEFORE_MINUTES
                  ? this.colors.textMuted : this.colors.textWhite)
            }
            .width(38)
            .height(38)
            .backgroundColor(this.colors.tintMedium)
            .borderRadius(10)
            .border({ width: 1, color: this.colors.borderMedium })
            .enabled(this.notifBefore > MIN_BEFORE_MINUTES)
            .onClick(() => {
              this.changeNotifBefore(-STEP_BEFORE_MINUTES);
            })

            Column() {
              Text(this.formatNotifBefore())
                .fontSize(18).fontWeight(FontWeight.Bold)
                .fontColor(this.notifBefore === 0
                  ? this.colors.textMuted : this.colors.accentGold)
              Text(this.tr('notif_minutes_suffix'))
                .fontSize(10).fontColor(this.colors.textMuted)
            }
            .width(64).alignItems(HorizontalAlign.Center)

            Button() {
              Text('+').fontSize(20).fontWeight(FontWeight.Bold)
                .fontColor(this.notifBefore >= MAX_BEFORE_MINUTES
                  ? this.colors.textMuted : this.colors.textOnAccent)
            }
            .width(38)
            .height(38)
            .backgroundColor(this.notifBefore >= MAX_BEFORE_MINUTES
              ? this.colors.tintMedium : this.colors.accentGold)
            .borderRadius(10)
            .enabled(this.notifBefore < MAX_BEFORE_MINUTES)
            .onClick(() => {
              this.changeNotifBefore(STEP_BEFORE_MINUTES);
            })
          }
          .width('100%').alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .padding({
          top: 14,
          bottom: 14,
          left: 16,
          right: 16
        })
        .backgroundColor(this.colors.tintSubtle)
        .borderRadius(12)
        .margin({ bottom: 8 })

        Column() {
          Row() {
            Column() {
              Text(this.tr('notify_prayers'))
                .fontSize(15).fontColor(this.colors.textWhite)
                .fontWeight(FontWeight.Medium)
              Text(this.tr('notify_prayers_desc'))
                .fontSize(11).fontColor(this.colors.textMuted)
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start).layoutWeight(1)
          }
          .width('100%').padding({ bottom: 8 })

          this.NotifPrayerRow('fajr')
          this.NotifPrayerRow('dhuhr')
          this.NotifPrayerRow('asr')
          this.NotifPrayerRow('maghrib')
          this.NotifPrayerRow('isha')
        }
        .width('100%')
        .padding(14)
        .backgroundColor(this.colors.tintSubtle)
        .borderRadius(12)
        .margin({ bottom: 8 })

        Row() {
          Text('ℹ️').fontSize(12).margin({ right: 6 }).opacity(0.7)
          Text(CALENDAR_REMINDERS_ENABLED
            ? this.tr('notifications_footer_calendar')
            : this.tr('notifications_footer'))
            .fontSize(10)
            .fontColor(this.colors.textMuted)
            .fontStyle(FontStyle.Italic)
            .layoutWeight(1)
            .lineHeight(15)
        }
        .width('100%')
        .padding({
          left: 6,
          right: 6,
          top: 4,
          bottom: 8
        })
        .alignItems(VerticalAlign.Top)
      }

      this.LogAccessRowInternal()
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(16)
    .border({ width: 1, color: this.colors.borderSoft })
    .margin({ bottom: 12 })
  }

  @Builder
  NotifPrayerRow(prayerId: string) {
    Row() {
      Text(this.tr('prayer_' + prayerId))
        .fontSize(14).fontColor(this.colors.textWhite)
        .layoutWeight(1)

      Toggle({
        type: ToggleType.Switch,
        isOn: this.getNotifPrayerValue(prayerId)
      })
        .selectedColor(this.colors.accentGold)
        .onChange((isOn: boolean) =>
        this.toggleNotifPrayer(prayerId, isOn))
    }
    .width('100%')
    .padding({
      top: 6,
      bottom: 6,
      left: 2,
      right: 2
    })
  }

  @Builder
  LogAccessRowInternal() {
    Row() {
      Text('📄').fontSize(14).margin({ right: 8 })
      Column() {
        Text(this.tr('log_view_button'))
          .fontSize(13).fontColor(this.colors.textWhite)
          .fontWeight(FontWeight.Medium).width('100%')
        Text(this.tr('log_view_desc'))
          .fontSize(10).fontColor(this.colors.textMuted)
          .margin({ top: 2 }).width('100%')
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)

      Text('›').fontSize(20)
        .fontColor(this.colors.accentGold).opacity(0.7)
    }
    .width('100%')
    .padding(14)
    .backgroundColor(this.colors.tintSubtle)
    .borderRadius(12)
    .onClick(() => {
      this.openLogViewer();
    })
  }

  @Builder
  LogAccessRow() {
    Row() {
      Text('📄').fontSize(14).margin({ right: 8 })
      Column() {
        Text(this.tr('log_view_button'))
          .fontSize(13).fontColor(this.colors.textWhite)
          .fontWeight(FontWeight.Medium).width('100%')
        Text(this.tr('log_view_desc'))
          .fontSize(10).fontColor(this.colors.textMuted)
          .margin({ top: 2 }).width('100%')
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)

      Text('›').fontSize(20)
        .fontColor(this.colors.accentGold).opacity(0.7)
    }
    .width('100%')
    .padding(14)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(16)
    .border({ width: 1, color: this.colors.borderSoft })
    .margin({ bottom: 12 })
    .onClick(() => {
      this.openLogViewer();
    })
  }

  // ============================================================
  // HIJRI CALENDAR
  // ============================================================

  @Builder
  HijriCalendarContent() {
    Column() {
      this.SettingsRow(
        this.tr('hijri_calendar_type'),
        this.tr('hijri_calendar_type_desc'),
        SettingsHelper.getHijriCalendarTypeLabel(this.hijriCalendarType),
        () => {
          this.activePicker = 'hijriType';
          this.showPickerSheet = true;
        }
      )

      Row() {
        Column() {
          Text(this.tr('hijri_offset'))
            .fontSize(15).fontColor(this.colors.textWhite)
            .fontWeight(FontWeight.Medium)
          Text(this.tr('hijri_offset_desc'))
            .fontSize(11)
            .fontColor(this.colors.textMuted)
            .margin({ top: 2 })
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        Row() {
          Button() {
            Text('\u2212').fontSize(20).fontWeight(FontWeight.Bold)
              .fontColor(this.hijriOffset <= -MAX_HIJRI_OFFSET
                ? this.colors.textMuted : this.colors.textWhite)
          }
          .width(38)
          .height(38)
          .backgroundColor(this.colors.tintMedium)
          .borderRadius(10)
          .border({ width: 1, color: this.colors.borderMedium })
          .enabled(this.hijriOffset > -MAX_HIJRI_OFFSET)
          .onClick(() => {
            this.changeHijriOffset(-1);
          })

          Text(this.formatHijriOffset())
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.hijriOffset === 0
              ? this.colors.textMuted : this.colors.accentGold)
            .width(48)
            .textAlign(TextAlign.Center)

          Button() {
            Text('+').fontSize(20).fontWeight(FontWeight.Bold)
              .fontColor(this.hijriOffset >= MAX_HIJRI_OFFSET
                ? this.colors.textMuted : this.colors.textOnAccent)
          }
          .width(38)
          .height(38)
          .backgroundColor(this.hijriOffset >= MAX_HIJRI_OFFSET
            ? this.colors.tintMedium : this.colors.accentGold)
          .borderRadius(10)
          .enabled(this.hijriOffset < MAX_HIJRI_OFFSET)
          .onClick(() => {
            this.changeHijriOffset(1);
          })
        }
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding({
        top: 14,
        bottom: 14,
        left: 16,
        right: 16
      })
      .backgroundColor(this.colors.tintSubtle)
      .borderRadius(12)
      .margin({ bottom: 8 })
      .alignItems(VerticalAlign.Center)

      Text(this.hijriOffsetDescription())
        .fontSize(11)
        .fontColor(this.colors.textMuted)
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 12 })
        .backgroundColor(this.colors.tintSubtle)
        .borderRadius({ bottomLeft: 12, bottomRight: 12 })
    }
    .width('100%')
    .padding(12)
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
        Text(this.appInfo.name)
          .fontSize(20).fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textWhite)
        Text(this.tr('app_tagline'))
          .fontSize(12).fontColor(this.colors.accentGold)
          .margin({ top: 4 })

        Divider().color(this.colors.borderSoft).width('80%')
          .margin({ top: 14, bottom: 14 })

        this.AboutRow(this.tr('about_version'), this.appInfo.versionName)
        this.AboutRow(this.tr('about_build'), `${this.appInfo.versionCode}`)
        this.AboutRow(this.tr('about_bundle'), this.appInfo.bundleName)
        this.AboutRow(this.tr('about_platform'),
          this.tr('about_platform_value'))
        this.AboutRow(this.tr('about_copyright'), this.appInfo.name)
      }
      .width('100%')
      .padding(20)
      .backgroundColor(this.colors.tintSubtle)
      .borderRadius(12)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(16)
    .border({ width: 1, color: this.colors.borderSoft })
    .margin({ bottom: 12 })
  }

  @Builder
  AboutRow(label: string, value: string) {
    Row() {
      Text(label).fontSize(13).fontColor(this.colors.textMuted)
      Blank()
      Text(value)
        .fontSize(12)
        .fontColor(this.colors.textWhite)
        .fontWeight(FontWeight.Medium)
        .direction(Direction.Ltr)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .padding({ left: 8, right: 8 })
    .margin({ top: 6 })
  }

  // ============================================================
  // PICKER SHEET
  // ============================================================

  @Builder
  PickerSheet() {
    Column() {
      Row()
        .width(44)
        .height(4)
        .backgroundColor(this.colors.overlayDimSoft)
        .borderRadius(2)
        .margin({ top: 10 })

      Row() {
        Text(this.pickerIcon())
          .fontSize(22)
          .width(44)
          .height(44)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.colors.tintSoft)
          .borderRadius(12)
          .border({ width: 1, color: this.colors.borderSoft })

        Text(this.pickerTitle())
          .fontSize(20).fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textWhite)
          .margin({ left: 14 })
      }
      .width('100%')
      .padding({ left: 20, top: 20, bottom: 20 })

      Divider().color(this.colors.borderSoft).width('90%')

      Scroll() {
        Column() {
          ForEach(this.pickerItems(), (item: PickerItem) => {
            Row() {
              Row() {
                if (item.selected) {
                  Row().width(10).height(10).borderRadius(5)
                    .backgroundColor(this.colors.accentGold)
                }
              }
              .width(22)
              .height(22)
              .borderRadius(11)
              .border({
                width: item.selected ? 2 : 1.5,
                color: item.selected
                  ? this.colors.accentGold : this.colors.borderStrong
              })
              .justifyContent(FlexAlign.Center)
              .alignItems(VerticalAlign.Center)

              Text(item.label)
                .fontSize(15)
                .fontColor(item.selected
                  ? this.colors.accentGold : this.colors.textWhite)
                .fontWeight(item.selected
                  ? FontWeight.Bold : FontWeight.Normal)
                .layoutWeight(1)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({ left: 14 })
            }
            .width('100%')
            .padding({
              top: 16,
              bottom: 16,
              left: 20,
              right: 20
            })
            .backgroundColor(item.selected
              ? this.colors.tintSoft : 'transparent')
            .borderRadius(12)
            .margin({ bottom: 4 })
            .onClick(() => {
              this.pickItem(item.id);
            })
          }, (item: PickerItem) =>
          `${this.activePicker}-${item.id}-${item.selected ? 's' : 'u'}`)
        }
        .width('100%')
        .padding({
          left: 8,
          right: 8,
          top: 8,
          bottom: 8
        })
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)

      Button() {
        Text(this.tr('cancel'))
          .fontSize(15).fontWeight(FontWeight.Medium)
          .fontColor(this.colors.textWhite)
      }
      .width('90%')
      .height(48)
      .backgroundColor(this.colors.tintSoft)
      .borderRadius(12)
      .margin({ top: 8, bottom: 24 })
      .onClick(() => {
        this.showPickerSheet = false;
        this.activePicker = 'none';
      })
    }
    .width('100%').height('100%')
    .backgroundColor(this.colors.cardDark)
  }

  private pickerTitle(): string {
    switch (this.activePicker) {
      case 'method':
        return this.tr('convention');
      case 'asr':
        return this.tr('madhab');
      case 'source':
        return this.tr('source');
      case 'hijriType':
        return this.tr('hijri_calendar_type');
      default:
        return '';
    }
  }

  private pickerIcon(): string {
    switch (this.activePicker) {
      case 'method':
        return '🕌';
      case 'asr':
        return '🌅';
      case 'source':
        return '🌐';
      case 'hijriType':
        return '📅';
      default:
        return '⚙️';
    }
  }

  private pickerItems(): PickerItem[] {
    switch (this.activePicker) {
      case 'method':
        return SettingsHelper.buildMethodPickerItems(this.calcMethod);
      case 'asr':
        return SettingsHelper.buildAsrPickerItems(this.asrRule);
      case 'source':
        return SettingsHelper.buildSourcePickerItems(this.calcSource);
      case 'hijriType':
        return SettingsHelper.buildHijriCalendarTypePickerItems(
          this.hijriCalendarType
        );
      default:
        return [];
    }
  }

  private pickItem(id: string): void {
    switch (this.activePicker) {
      case 'method':
        this.pickMethod(id);
        break;
      case 'asr':
        this.pickAsrRule(id);
        break;
      case 'source':
        this.pickSource(id);
        break;
      case 'hijriType':
        this.pickHijriCalendarType(id);
        break;
      default:
        break;
    }
    this.showPickerSheet = false;
    this.activePicker = 'none';
  }

  // ============================================================
  // LOG VIEWER
  // ============================================================

  @Builder
  LogViewerSheet() {
    Column() {
      Row()
        .width(44)
        .height(4)
        .backgroundColor(this.colors.overlayDimSoft)
        .borderRadius(2)
        .margin({ top: 10 })

      Row() {
        Text('📄').fontSize(20).margin({ right: 10 })
        Text(this.tr('log_view_title'))
          .fontSize(18).fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textWhite)
          .layoutWeight(1)
        Text('✕')
          .fontSize(20)
          .fontColor(this.colors.textMuted)
          .width(36)
          .height(36)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.showLogViewer = false;
          })
      }
      .width('100%')
      .padding({
        left: 20,
        right: 12,
        top: 16,
        bottom: 12
      })
      .alignItems(VerticalAlign.Center)

      Text(AppLogger.getPath())
        .fontSize(10)
        .fontColor(this.colors.textMuted)
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 10 })
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(1)

      Divider().color(this.colors.borderSoft).width('90%')

      Scroll() {
        Text(this.logContents.length > 0
          ? this.logContents : this.tr('log_empty'))
          .fontSize(11)
          .fontColor(this.colors.textWhite)
          .lineHeight(16)
          .width('100%')
          .padding(14)
          .textAlign(TextAlign.Start)
      }
      .layoutWeight(1)
      .width('100%')
      .margin({ left: 20, right: 20, top: 12 })
      .backgroundColor(this.colors.tintSubtle)
      .borderRadius(10)
      .border({ width: 1, color: this.colors.borderSoft })
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)

      Row() {
        Button() {
          Text(this.tr('log_copy'))
            .fontSize(14).fontWeight(FontWeight.Medium)
            .fontColor(this.colors.textOnAccent)
        }
        .layoutWeight(1)
        .height(44)
        .backgroundColor(this.colors.accentGold)
        .borderRadius(10)
        .onClick(() => {
          this.copyLogsToClipboard();
        })

        Button() {
          Text(this.tr('log_clear'))
            .fontSize(14).fontWeight(FontWeight.Medium)
            .fontColor(this.colors.textWhite)
        }
        .layoutWeight(1)
        .height(44)
        .backgroundColor(this.colors.tintSoft)
        .borderRadius(10)
        .margin({ left: 8 })
        .onClick(() => {
          this.clearLogs();
        })
      }
      .width('100%')
      .padding({
        left: 20,
        right: 20,
        top: 12,
        bottom: 24
      })
    }
    .width('100%').height('100%')
    .backgroundColor(this.colors.cardDark)
  }

  // ============================================================
  // HELPERS
  // ============================================================

  private tr(key: string): string {
    return L.get(key, this.currentLanguage);
  }

  private isRtl(): boolean {
    return L.isRtlLang(this.currentLanguage);
  }

  private onThemeModeChanged(): void {
    this.colors = PageTheme.compute(this.themeMode);
  }

  private onAppThemePresetChanged(): void {
    this.colors = PageTheme.compute(this.themeMode);
  }

  private onLanguageChanged(): void {
    this.currentLanguage = this.appLanguage;
  }

  private async onAppForegrounded(): Promise<void> {
    const ctx = getContext(this) as common.UIAbilityContext;
    this.appInfo = AppInfoHelper.get(ctx);
    await this.reload();
  }

  private async reload(): Promise<void> {
    const data = await SettingsHelper.loadAll();
    this.calcMethod = data.method;
    this.asrRule = data.asr;
    this.calcSource = data.source;
    this.offsets = await SettingsHelper.getPrayerOffsets();

    const ns = await SettingsHelper.getNotificationSettings();
    this.notifMaster = ns.masterEnabled;
    this.notifBefore = ns.beforeMinutes;
    this.notifFajr = ns.fajrEnabled;
    this.notifDhuhr = ns.dhuhrEnabled;
    this.notifAsr = ns.asrEnabled;
    this.notifMaghrib = ns.maghribEnabled;
    this.notifIsha = ns.ishaEnabled;

    const mode = await SettingsHelper.getLocationMode();
    this.locationMode = mode;

    const manual = await SettingsHelper.getManualCoords();
    this.manualLatInput = manual.lat !== 0 ? manual.lat.toString() : '';
    this.manualLngInput = manual.lng !== 0 ? manual.lng.toString() : '';
    this.manualCityInput = manual.cityName;

    if (mode === LocationMode.MANUAL) {
      this.effectiveLat = manual.lat;
      this.effectiveLng = manual.lng;
      if (manual.lat !== 0 || manual.lng !== 0) {
        const city = manual.cityName.length > 0
          ? manual.cityName : this.tr('manual_location');
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

  private pickMethod(id: string): void {
    const method = id as CalculationMethod;
    this.calcMethod = method;
    SettingsHelper.saveMethod(method);
  }

  private pickAsrRule(id: string): void {
    const rule = Number(id) as AsrShadowRule;
    this.asrRule = rule;
    SettingsHelper.saveAsrRule(rule);
  }

  private pickSource(id: string): void {
    const source = id as CalculationSource;
    if (source === CalculationSource.API) {
      promptAction.showToast({
        message: this.tr('coming_soon'), duration: 1800
      });
      return;
    }
    this.calcSource = source;
    SettingsHelper.saveSource(source);
  }

  private pickHijriCalendarType(id: string): void {
    this.hijriCalendarType = id;
    SettingsHelper.saveHijriCalendarType(id);
  }

  private async pickLocationMode(mode: LocationMode): Promise<void> {
    this.locationMode = mode;
    SettingsHelper.saveLocationMode(mode);
    await this.reload();
  }

  private getStorageKeyForOffset(key: OffsetKey): string {
    switch (key) {
      case 'fajr':
        return SettingsHelper.OFFSET_KEYS.fajr;
      case 'dhuhr':
        return SettingsHelper.OFFSET_KEYS.dhuhr;
      case 'asr':
        return SettingsHelper.OFFSET_KEYS.asr;
      case 'maghrib':
        return SettingsHelper.OFFSET_KEYS.maghrib;
      case 'isha':
        return SettingsHelper.OFFSET_KEYS.isha;
      default:
        return '';
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
    promptAction.showToast({
      message: this.tr('reset_all_offsets'), duration: 1800
    });
  }

  private changeHijriOffset(delta: number): void {
    const next = this.hijriOffset + delta;
    if (next < -MAX_HIJRI_OFFSET) {
      return;
    }
    if (next > MAX_HIJRI_OFFSET) {
      return;
    }
    this.hijriOffset = next;
    SettingsHelper.saveHijriOffset(next);
  }

  private formatHijriOffset(): string {
    if (this.hijriOffset === 0) {
      return '+0';
    }
    if (this.hijriOffset > 0) {
      return `+${this.hijriOffset}`;
    }
    return `\u2212${Math.abs(this.hijriOffset)}`;
  }

  private hijriOffsetDescription(): string {
    if (this.hijriOffset === 0) {
      return this.tr('matching_standard');
    }
    const n = Math.abs(this.hijriOffset);
    if (this.hijriOffset > 0) {
      return `${n} ${this.tr('offset_days_ahead')}`;
    }
    return `${n} ${this.tr('offset_days_behind')}`;
  }

  private async saveManualCoords(): Promise<void> {
    const lat = parseFloat(this.manualLatInput.trim());
    const lng = parseFloat(this.manualLngInput.trim());

    if (isNaN(lat) || lat < -90 || lat > 90) {
      promptAction.showToast({
        message: this.tr('latitude_hint'), duration: 2500
      });
      return;
    }
    if (isNaN(lng) || lng < -180 || lng > 180) {
      promptAction.showToast({
        message: this.tr('longitude_hint'), duration: 2500
      });
      return;
    }

    this.isRefreshing = true;

    let cityName = this.manualCityInput.trim();
    if (cityName.length === 0) {
      try {
        cityName = await LocationHelper.reverseGeocode(lat, lng);
      } catch (e) { /* fall through */
      }
      const unknownLabel = L.get('unknown_location', this.currentLanguage);
      if (cityName === unknownLabel || cityName.length === 0) {
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

    promptAction.showToast({
      message: `${this.tr('save')}: ${saved.cityName}`, duration: 2000
    });
  }

  private async refreshLocation(): Promise<void> {
    if (this.isRefreshing) {
      return;
    }
    this.isRefreshing = true;

    if (this.locationMode === LocationMode.MANUAL) {
      const manual = await SettingsHelper.getManualCoords();
      if (manual.lat === 0 && manual.lng === 0) {
        promptAction.showToast({
          message: this.tr('location_desc'), duration: 2000
        });
        this.isRefreshing = false;
        return;
      }
      let cityName = this.tr('manual_location');
      try {
        cityName = await LocationHelper.reverseGeocode(
          manual.lat, manual.lng
        );
      } catch (e) { /* fall through */
      }
      const saved = await SettingsHelper.saveManualCoords(
        manual.lat, manual.lng, cityName
      );
      this.effectiveLat = saved.lat;
      this.effectiveLng = saved.lng;
      this.effectiveCity = `${saved.cityName} (${this.tr('manual_location')})`;
      this.lastRefreshTime = saved.refresh;
      promptAction.showToast({
        message: `${this.tr('save')}: ${saved.cityName}`, duration: 2000
      });
      this.isRefreshing = false;
      return;
    }

    try {
      const data: LocationData =
        await LocationHelper.fetchLocationData(getContext(this));
      await LocationCache.save(data.latitude, data.longitude, data.cityName);
      this.effectiveLat = data.latitude;
      this.effectiveLng = data.longitude;
      this.effectiveCity = data.cityName;
      this.lastRefreshTime = Date.now();
      promptAction.showToast({
        message: `GPS: ${data.cityName}`, duration: 2000
      });
    } catch (err) {
      const error = err as Error;
      let msgKey = 'error_gps_fetch_failed';
      if (error.message === 'GPS_OFF') {
        msgKey = 'error_gps_off';
      } else if (error.message === 'PERMISSION_DENIED') {
        msgKey = 'error_location_permission_denied';
      }
      promptAction.showToast({
        message: this.tr(msgKey), duration: 2500
      });
    } finally {
      this.isRefreshing = false;
    }
  }

  private formatCoord(n: number): string {
    if (n === 0) {
      return '—';
    }
    return n.toFixed(4);
  }

  private formatRefreshTime(ts: number): string {
    if (ts === 0) {
      return '—';
    }
    const d = new Date(ts);
    const now = new Date();
    const isToday =
      d.getDate() === now.getDate() &&
        d.getMonth() === now.getMonth() &&
        d.getFullYear() === now.getFullYear();
    const hh = d.getHours().toString().padStart(2, '0');
    const mm = d.getMinutes().toString().padStart(2, '0');
    const time = `${hh}:${mm}`;
    if (isToday) {
      return `${this.tr('today')} ${time}`;
    }
    const m2 = (d.getMonth() + 1).toString().padStart(2, '0');
    const dd = d.getDate().toString().padStart(2, '0');
    return `${d.getFullYear()}-${m2}-${dd} ${time}`;
  }

  private async sendTestNotification(): Promise<void> {
    const ctx = getContext(this) as common.UIAbilityContext;
    const granted = await NotificationHelper.isPermissionGranted(ctx);
    if (!granted) {
      const requested = await NotificationHelper.requestPermission(ctx);
      if (!requested) {
        const msgKey = CALENDAR_REMINDERS_ENABLED
          ? 'calendar_permission_denied'
          : 'notification_permission_denied';
        promptAction.showToast({
          message: this.tr(msgKey), duration: 2500
        });
        return;
      }
    }

    promptAction.showToast({
      message: this.tr('notif_test_sending'), duration: 1500
    });

    const result = await NotificationHelper.publishTestNotification();

    if (result.ok) {
      this.notifDiagnostic = '';
      const okMsg = CALENDAR_REMINDERS_ENABLED
        ? 'notif_test_ok_calendar'
        : 'notif_test_ok';
      promptAction.showToast({
        message: this.tr(okMsg), duration: 3000
      });
    } else {
      this.notifDiagnostic = result.errorMessage;
      promptAction.showToast({
        message: `${this.tr('notif_test_failed')} (code ${result.errorCode})`,
        duration: 4000
      });
    }
  }

  private async toggleNotifMaster(value: boolean): Promise<void> {
    if (value) {
      const ctx = getContext(this) as common.UIAbilityContext;
      const granted = await NotificationHelper.requestPermission(ctx);
      if (!granted) {
        this.notifMaster = false;
        const msgKey = CALENDAR_REMINDERS_ENABLED
          ? 'calendar_permission_denied'
          : 'notification_permission_denied';
        promptAction.showToast({
          message: this.tr(msgKey), duration: 2500
        });
        return;
      }
    }
    this.notifMaster = value;
    await SettingsHelper.saveNotifMaster(value);
    await NotificationHelper.rescheduleAll();
  }

  private async changeNotifBefore(delta: number): Promise<void> {
    let next = this.notifBefore + delta;
    if (next < MIN_BEFORE_MINUTES) {
      next = MIN_BEFORE_MINUTES;
    }
    if (next > MAX_BEFORE_MINUTES) {
      next = MAX_BEFORE_MINUTES;
    }
    if (next === this.notifBefore) {
      return;
    }

    this.notifBefore = next;
    await SettingsHelper.saveNotifBeforeMinutes(next);
    await NotificationHelper.rescheduleAll();
  }

  private async toggleNotifPrayer(
    prayerId: string, value: boolean
  ): Promise<void> {
    switch (prayerId) {
      case 'fajr':
        this.notifFajr = value;
        break;
      case 'dhuhr':
        this.notifDhuhr = value;
        break;
      case 'asr':
        this.notifAsr = value;
        break;
      case 'maghrib':
        this.notifMaghrib = value;
        break;
      case 'isha':
        this.notifIsha = value;
        break;
    }
    await SettingsHelper.saveNotifPrayer(prayerId, value);
    await NotificationHelper.rescheduleAll();
  }

  private getNotifPrayerValue(prayerId: string): boolean {
    switch (prayerId) {
      case 'fajr':
        return this.notifFajr;
      case 'dhuhr':
        return this.notifDhuhr;
      case 'asr':
        return this.notifAsr;
      case 'maghrib':
        return this.notifMaghrib;
      case 'isha':
        return this.notifIsha;
      default:
        return false;
    }
  }

  private formatNotifBefore(): string {
    return `${this.notifBefore}`;
  }

  private openLogViewer(): void {
    try {
      const content = AppLogger.readAll();
      this.logContents = (typeof content === 'string')
        ? content
        : '(log read returned an unexpected type)';
      this.showLogViewer = true;
    } catch (err) {
      const e = err as Error;
      promptAction.showToast({
        message: `Log read failed: ${e.message}`,
        duration: 3000
      });
      this.logContents = '';
      this.showLogViewer = true;
    }
  }

  private copyLogsToClipboard(): void {
    try {
      const data = pasteboard.createData(
        pasteboard.MIMETYPE_TEXT_PLAIN, this.logContents
      );
      pasteboard.getSystemPasteboard().setData(data)
        .then(() => {
          promptAction.showToast({
            message: this.tr('log_copied'), duration: 1500
          });
        })
        .catch((err: Error) => {
          console.error('[SettingsPage] clipboard failed: ' + err.message);
        });
    } catch (err) {
      const e = err as Error;
      console.error('[SettingsPage] clipboard threw: ' + e.message);
    }
  }

  private clearLogs(): void {
    try {
      AppLogger.clear();
      const content = AppLogger.readAll();
      this.logContents = (typeof content === 'string') ? content : '';
      promptAction.showToast({
        message: this.tr('log_cleared'), duration: 1500
      });
    } catch (err) {
      const e = err as Error;
      promptAction.showToast({
        message: `Log clear failed: ${e.message}`,
        duration: 3000
      });
    }
  }
}