// entry/src/main/ets/pages/CustomizePage.ets

import { mediaquery, router } from '@kit.ArkUI';
import { Theme, ThemeColors, ThemeMode, ThemePreset } from '../common/Theme';
import { PageTheme } from '../common/PageTheme';
import { SettingsHelper } from '../helper/SettingsHelper';
import { PickerItem } from '../models/SettingsModels';
import {
  STORAGE_KEY_APP_FOREGROUND_TICK,
  STORAGE_KEY_APP_THEME,
  STORAGE_KEY_AUTO_SHOW_RAMADAN_VIEW,
  STORAGE_KEY_BREAKPOINT,
  STORAGE_KEY_EVENT_PERSPECTIVE,
  STORAGE_KEY_LANGUAGE,
  STORAGE_KEY_SHOW_FIRST_THIRD_LIST,
  STORAGE_KEY_SHOW_FIRST_THIRD_SUNPATH,
  STORAGE_KEY_SHOW_IMSAK_LIST,
  STORAGE_KEY_SHOW_IMSAK_SUNPATH,
  STORAGE_KEY_SHOW_ISLAMIC_EVENTS,
  STORAGE_KEY_SHOW_LAST_THIRD_LIST,
  STORAGE_KEY_SHOW_LAST_THIRD_SUNPATH,
  STORAGE_KEY_SHOW_MIDNIGHT_LIST,
  STORAGE_KEY_SHOW_MIDNIGHT_SUNPATH,
  STORAGE_KEY_SYSTEM_HAPTICS_ENABLED,
  STORAGE_KEY_SYSTEM_SOUND_ENABLED,
  STORAGE_KEY_THEME_MODE,
  STORAGE_KEY_TIME_FORMAT
} from '../common/StorageKeys';
import { AppLanguage, L } from '../i8n/LocalizationHelper';
import { SoundHelper } from '../helper/SoundHelper';
import { SoundOptions, TASBIH_SOUND_OPTIONS, TasbihSoundOption } from '../common/SoundOptions';
import { Breakpoints } from '../common/Breakpoints';
import { ClockFormat } from '../common/ClockFormat';
import { SubsectionHeader } from '../components/SubsectionHeader';
import { ExtraTimingToggleRow } from '../components/ExtraTimingToggleRow';

@Entry
@Component
struct CustomizePage {
  // ============================================================
  // STORAGE LINKS
  // ============================================================

  @StorageLink(STORAGE_KEY_THEME_MODE)
  @Watch('onThemeModeChanged')
  themeMode: string = ThemeMode.SYSTEM;
  @StorageLink(STORAGE_KEY_AUTO_SHOW_RAMADAN_VIEW)
  @Watch('onAutoShowRamadanViewChanged')
  autoShowRamadanView: boolean = true;

  @StorageLink(STORAGE_KEY_LANGUAGE)
  @Watch('onLanguageChanged')
  appLanguage: string = AppLanguage.ENGLISH;

  @StorageLink(STORAGE_KEY_APP_THEME)
  @Watch('onAppThemePresetChanged')
  appTheme: string = ThemePreset.CURRENT;

  @StorageLink(STORAGE_KEY_SYSTEM_SOUND_ENABLED)
  @Watch('onSystemFeedbackChanged')
  systemSoundEnabled: boolean = true;

  @StorageLink(STORAGE_KEY_SYSTEM_HAPTICS_ENABLED)
  @Watch('onSystemFeedbackChanged')
  systemHapticsEnabled: boolean = true;

  @StorageLink(STORAGE_KEY_APP_FOREGROUND_TICK)
  @Watch('onAppForegrounded')
  appForegroundTick: number = 0;

  @StorageLink(STORAGE_KEY_BREAKPOINT)
  breakpoint: string = 'sm';

  @StorageLink(STORAGE_KEY_TIME_FORMAT)
  @Watch('onClockFormatChanged')
  ClockFormat: string = ClockFormat.SYSTEM;

  @StorageLink(STORAGE_KEY_SHOW_ISLAMIC_EVENTS)
  @Watch('onShowIslamicEventsChanged')
  showIslamicEvents: boolean = true;

  @StorageLink(STORAGE_KEY_EVENT_PERSPECTIVE)
  @Watch('onEventPerspectiveChanged')
  eventPerspective: string = 'universal';
  // ---- Per-timing visibility — prayer list ----
  @StorageLink(STORAGE_KEY_SHOW_IMSAK_LIST)
  @Watch('onShowImsakListChanged')
  showImsakList: boolean = true;
  @StorageLink(STORAGE_KEY_SHOW_FIRST_THIRD_LIST)
  @Watch('onShowFirstThirdListChanged')
  showFirstThirdList: boolean = true;
  @StorageLink(STORAGE_KEY_SHOW_MIDNIGHT_LIST)
  @Watch('onShowMidnightListChanged')
  showMidnightList: boolean = true;
  @StorageLink(STORAGE_KEY_SHOW_LAST_THIRD_LIST)
  @Watch('onShowLastThirdListChanged')
  showLastThirdList: boolean = true;
  // ---- Per-timing visibility — sun path ----
  @StorageLink(STORAGE_KEY_SHOW_IMSAK_SUNPATH)
  @Watch('onShowImsakSunpathChanged')
  showImsakSunpath: boolean = true;
  @StorageLink(STORAGE_KEY_SHOW_FIRST_THIRD_SUNPATH)
  @Watch('onShowFirstThirdSunpathChanged')
  showFirstThirdSunpath: boolean = true;
  @StorageLink(STORAGE_KEY_SHOW_MIDNIGHT_SUNPATH)
  @Watch('onShowMidnightSunpathChanged')
  showMidnightSunpath: boolean = true;
  @StorageLink(STORAGE_KEY_SHOW_LAST_THIRD_SUNPATH)
  @Watch('onShowLastThirdSunpathChanged')
  showLastThirdSunpath: boolean = true;

  // ============================================================
  // UI STATE
  // ============================================================

  @State colors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);
  @State currentLanguage: string = AppLanguage.ENGLISH;
  @State showClockFormatPicker: boolean = false;
  @State vibrationEnabled: boolean = true;
  @State soundEnabled: boolean = true;
  @State selectedSound: string = SoundOptions.DEFAULT_ID;
  @State expandedCategory: string | null = 'UI Customization';
  @State showThemePicker: boolean = false;
  @State showLanguagePicker: boolean = false;
  @State showAppThemePicker: boolean = false;
  @State showSoundPicker: boolean = false;
  @State showEventPerspectivePicker: boolean = false;

  private systemDarkListener: mediaquery.MediaQueryListener | null = null;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  aboutToAppear(): void {
    this.currentLanguage = this.appLanguage;
    this.applyTheme();

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
    this.applyTheme();
    this.reload();
  }

  // ============================================================
  // WATCHERS
  // ============================================================

  private onClockFormatChanged(): void {
    // No state to update — the @StorageLink re-render is enough.
  }

  private onShowIslamicEventsChanged(): void {
    // Re-render is handled by the @StorageLink.
  }

  private onEventPerspectiveChanged(): void {
    // Re-render is handled by the @StorageLink.
  }

  private onShowImsakListChanged(): void {
  }

  private onAutoShowRamadanViewChanged(): void {
    // Re-render is handled by the @StorageLink.
  }

  private onShowFirstThirdListChanged(): void {
  }

  private onShowMidnightListChanged(): void {
  }

  private onShowLastThirdListChanged(): void {
  }

  private onShowImsakSunpathChanged(): void {
  }

  private onShowFirstThirdSunpathChanged(): void {
  }

  private onShowMidnightSunpathChanged(): void {
  }

  private onShowLastThirdSunpathChanged(): void {
  }

  private pickClockFormat(id: string): void {
    this.ClockFormat = id;
    SettingsHelper.saveClockFormat(id);
    this.showClockFormatPicker = false;
  }

  private ClockFormatLabel(): string {
    switch (this.ClockFormat) {
      case ClockFormat.TWELVE_HOUR:
        return this.tr('time_format_12h');
      case ClockFormat.TWENTY_FOUR_HOUR:
        return this.tr('time_format_24h');
      default:
        return this.tr('time_format_system');
    }
  }

  private pickEventPerspective(id: string): void {
    this.eventPerspective = id;
    SettingsHelper.saveEventPerspective(id);
    this.showEventPerspectivePicker = false;
  }

  // ============================================================
  // BUILD
  // ============================================================

  build() {
    Stack() {
      Column() {
        this.TopBar()

        Scroll() {
          Row() {
            Column() {
              // ==================================================
              // UI Customization — header inlined
              // ==================================================
              Row() {
                Image($r('app.media.ic_ui_customize'))
                  .width(20)
                  .height(20)
                  .fillColor(this.colors.accentGold)
                  .width(40)
                  .height(40)
                  .padding(10)
                  .backgroundColor(this.colors.tintSoft)
                  .borderRadius(12)
                  .border({ width: 1, color: this.colors.borderSoft })
                  .backgroundColor(this.colors.tintSoft)
                  .borderRadius(12)
                  .border({ width: 1, color: this.colors.borderSoft })

                Text(this.tr('category_ui_customization'))
                  .fontSize(17)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.colors.textWhite)
                  .margin({ left: 14 })
                  .layoutWeight(1)

                Text(this.expandedCategory === 'UI Customization' ? '▲' : '▼')
                  .fontSize(12).fontColor(this.colors.accentGold).opacity(0.8)
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
                this.expandedCategory = this.expandedCategory === 'UI Customization'
                  ? null : 'UI Customization';
              })

              if (this.expandedCategory === 'UI Customization') {
                this.UICustomizationContent()
              }

              // ==================================================
              // Appearance — header inlined
              // ==================================================
              Row() {
                Image($r('app.media.ic_ui_appearance'))
                  .width(20)
                  .height(20)
                  .fillColor(this.colors.accentGold)
                  .width(40)
                  .height(40)
                  .padding(10)
                  .backgroundColor(this.colors.tintSoft)
                  .borderRadius(12)
                  .border({ width: 1, color: this.colors.borderSoft })
                  .backgroundColor(this.colors.tintSoft)
                  .borderRadius(12)
                  .border({ width: 1, color: this.colors.borderSoft })

                Text(this.tr('category_appearance'))
                  .fontSize(17)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.colors.textWhite)
                  .margin({ left: 14 })
                  .layoutWeight(1)

                Text(this.expandedCategory === 'Appearance' ? '▲' : '▼')
                  .fontSize(12).fontColor(this.colors.accentGold).opacity(0.8)
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
                this.expandedCategory = this.expandedCategory === 'Appearance'
                  ? null : 'Appearance';
              })

              if (this.expandedCategory === 'Appearance') {
                this.AppearanceContent()
              }

              Column().height(40)
            }
            .width('100%')
            .constraintSize({ maxWidth: Breakpoints.maxContentWidth(this.breakpoint) })
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
      .width('100%').height('100%').backgroundColor(this.colors.primaryGreen)

      if (this.showThemePicker) {
        this.PickerOverlay(
          this.tr('dark_mode'),
          '🎨',
          this.buildThemeItems(),
          (id: string) => {
            this.pickThemeMode(id);
          },
          () => {
            this.showThemePicker = false;
          }
        )
      }

      if (this.showLanguagePicker) {
        this.PickerOverlay(
          this.tr('language'),
          '🌐',
          this.buildLanguageItems(),
          (id: string) => {
            this.pickLanguage(id);
          },
          () => {
            this.showLanguagePicker = false;
          }
        )
      }

      if (this.showAppThemePicker) {
        this.AppThemePicker()
      }

      if (this.showSoundPicker) {
        this.SoundPicker()
      }

      if (this.showClockFormatPicker) {
        this.PickerOverlay(
          this.tr('time_format'),
          '🕐',
          SettingsHelper.buildClockFormatPickerItems(this.ClockFormat),
          (id: string) => {
            this.pickClockFormat(id);
          },
          () => {
            this.showClockFormatPicker = false;
          }
        )
      }

      if (this.showEventPerspectivePicker) {
        this.PickerOverlay(
          this.tr('event_perspective'),
          '🌙',
          SettingsHelper.buildEventPerspectivePickerItems(this.eventPerspective),
          (id: string) => {
            this.pickEventPerspective(id);
          },
          () => {
            this.showEventPerspectivePicker = false;
          }
        )
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.primaryGreen)
    .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  ClockFormatRow() {
    Row() {
      Column() {
        Text(this.tr('time_format'))
          .fontSize(15).fontColor(this.colors.textWhite)
          .fontWeight(FontWeight.Medium)
        Text(this.tr('time_format_desc'))
          .fontSize(11)
          .fontColor(this.colors.textMuted)
          .margin({ top: 2 })
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.ClockFormatLabel())
          .fontSize(12)
          .fontColor(this.colors.accentGold)
          .maxLines(1)
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
    .onClick(() => {
      this.showClockFormatPicker = true;
    })
  }

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

      Text(this.tr('title_customize'))
        .fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
        .margin({ left: 16 })
    }
    .width('100%').height(72).backgroundColor(this.colors.cardDark)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  UICustomizationContent() {
    Column() {
      // ============ Home Page UI ============
      SubsectionHeader({
        colors: this.colors,
        titleKey: 'subsection_home_ui',
        currentLanguage: this.currentLanguage
      })
      this.ShowIslamicEventsRow()
      this.AutoShowRamadanViewRow()
      this.EventPerspectiveRow()

      // ============ Prayer UI ============
      SubsectionHeader({
        colors: this.colors,
        titleKey: 'subsection_prayer_ui',
        currentLanguage: this.currentLanguage
      })

      SubsectionHeader({
        colors: this.colors,
        titleKey: 'subsection_prayer_list',
        currentLanguage: this.currentLanguage
      })
      this.ShowImsakListRow()
      this.ShowFirstThirdListRow()
      this.ShowMidnightListRow()
      this.ShowLastThirdListRow()

      SubsectionHeader({
        colors: this.colors,
        titleKey: 'subsection_sun_path',
        currentLanguage: this.currentLanguage
      })
      this.ShowImsakSunpathRow()
      this.ShowFirstThirdSunpathRow()
      this.ShowMidnightSunpathRow()
      this.ShowLastThirdSunpathRow()

      // ============ Sound & Feedback ============
      SubsectionHeader({
        colors: this.colors,
        titleKey: 'subsection_feedback',
        currentLanguage: this.currentLanguage
      })
      this.VibrationRow()
      this.SoundRow()
      this.SoundStyleRow()

      // ============ Language & Time Format ============
      SubsectionHeader({
        colors: this.colors,
        titleKey: 'subsection_language',
        currentLanguage: this.currentLanguage
      })
      this.LanguageRow()
      this.ClockFormatRow()
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(16)
    .border({ width: 1, color: this.colors.borderSoft })
    .margin({ bottom: 12 })
  }

  // ---- Each toggle is its own parameterless builder so it re-reads
  // state on every parent render. Passing the value as a builder
  // parameter would freeze it at first render.

  @Builder
  ShowIslamicEventsRow() {
    Row() {
      Column() {
        Text(this.tr('show_islamic_events'))
          .fontSize(15).fontColor(this.colors.textWhite)
          .fontWeight(FontWeight.Medium)
        Text(this.tr('show_islamic_events_desc'))
          .fontSize(11)
          .fontColor(this.colors.textMuted)
          .margin({ top: 2 })
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: this.showIslamicEvents })
        .selectedColor(this.colors.accentGold)
        .onChange((isOn: boolean) => {
          this.toggleShowIslamicEvents(isOn);
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
  }

  @Builder
  EventPerspectiveRow() {
    Row() {
      Column() {
        Text(this.tr('event_perspective'))
          .fontSize(15).fontColor(this.colors.textWhite)
          .fontWeight(FontWeight.Medium)
        Text(this.tr('event_perspective_desc'))
          .fontSize(11)
          .fontColor(this.colors.textMuted)
          .margin({ top: 2 })
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.eventPerspectiveLabel())
          .fontSize(12)
          .fontColor(this.colors.accentGold)
          .maxLines(1)
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
    .onClick(() => {
      this.showEventPerspectivePicker = true;
    })
  }

  // ---- Per-timing visibility — prayer list ----

  @Builder
  ShowImsakListRow() {
    ExtraTimingToggleRow({
      colors: this.colors,
      titleKey: 'show_imsak',
      descriptionKey: 'show_imsak_desc',
      currentLanguage: this.currentLanguage,
      isOn: this.showImsakList,
      onToggle: (isOn: boolean) => this.toggleShowImsakList(isOn)
    })
  }

  @Builder
  ShowFirstThirdListRow() {
    ExtraTimingToggleRow({
      colors: this.colors,
      titleKey: 'show_first_third',
      descriptionKey: 'show_first_third_desc',
      currentLanguage: this.currentLanguage,
      isOn: this.showFirstThirdList,
      onToggle: (isOn: boolean) => this.toggleShowFirstThirdList(isOn)
    })
  }

  @Builder
  ShowMidnightListRow() {
    ExtraTimingToggleRow({
      colors: this.colors,
      titleKey: 'show_midnight',
      descriptionKey: 'show_midnight_desc',
      currentLanguage: this.currentLanguage,
      isOn: this.showMidnightList,
      onToggle: (isOn: boolean) => this.toggleShowMidnightList(isOn)
    })
  }

  @Builder
  ShowLastThirdListRow() {
    ExtraTimingToggleRow({
      colors: this.colors,
      titleKey: 'show_last_third',
      descriptionKey: 'show_last_third_desc',
      currentLanguage: this.currentLanguage,
      isOn: this.showLastThirdList,
      onToggle: (isOn: boolean) => this.toggleShowLastThirdList(isOn)
    })
  }

  // ---- Per-timing visibility — sun path ----

  @Builder
  ShowImsakSunpathRow() {
    ExtraTimingToggleRow({
      colors: this.colors,
      titleKey: 'show_imsak',
      descriptionKey: 'show_imsak_desc',
      currentLanguage: this.currentLanguage,
      isOn: this.showImsakSunpath,
      onToggle: (isOn: boolean) => this.toggleShowImsakSunpath(isOn)
    })
  }

  @Builder
  ShowFirstThirdSunpathRow() {
    ExtraTimingToggleRow({
      colors: this.colors,
      titleKey: 'show_first_third',
      descriptionKey: 'show_first_third_desc',
      currentLanguage: this.currentLanguage,
      isOn: this.showFirstThirdSunpath,
      onToggle: (isOn: boolean) => this.toggleShowFirstThirdSunpath(isOn)
    })
  }

  @Builder
  ShowMidnightSunpathRow() {
    ExtraTimingToggleRow({
      colors: this.colors,
      titleKey: 'show_midnight',
      descriptionKey: 'show_midnight_desc',
      currentLanguage: this.currentLanguage,
      isOn: this.showMidnightSunpath,
      onToggle: (isOn: boolean) => this.toggleShowMidnightSunpath(isOn)
    })
  }

  @Builder
  ShowLastThirdSunpathRow() {
    ExtraTimingToggleRow({
      colors: this.colors,
      titleKey: 'show_last_third',
      descriptionKey: 'show_last_third_desc',
      currentLanguage: this.currentLanguage,
      isOn: this.showLastThirdSunpath,
      onToggle: (isOn: boolean) => this.toggleShowLastThirdSunpath(isOn)
    })
  }

  // ---- Sound & feedback ----

  @Builder
  VibrationRow() {
    Row() {
      Column() {
        Text(this.tr('haptic_feedback'))
          .fontSize(15).fontColor(this.colors.textWhite)
          .fontWeight(FontWeight.Medium)
        Text(this.tr('haptic_feedback_desc'))
          .fontSize(11).fontColor(this.colors.textMuted)
          .margin({ top: 2 })
        if (!this.systemHapticsEnabled) {
          Text(this.tr('controlled_by_system'))
            .fontSize(10).fontColor(this.colors.accentGold)
            .fontStyle(FontStyle.Italic).margin({ top: 4 })
        }
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: this.vibrationEnabled })
        .selectedColor(this.colors.accentGold)
        .enabled(this.systemHapticsEnabled)
        .opacity(this.systemHapticsEnabled ? 1.0 : 0.5)
        .onChange((isOn: boolean) => {
          this.toggleVibration(isOn);
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
  }

  @Builder
  SoundRow() {
    Row() {
      Column() {
        Text(this.tr('sound_feedback'))
          .fontSize(15).fontColor(this.colors.textWhite)
          .fontWeight(FontWeight.Medium)
        Text(this.tr('sound_feedback_desc'))
          .fontSize(11).fontColor(this.colors.textMuted)
          .margin({ top: 2 })
        if (!this.systemSoundEnabled) {
          Text(this.tr('controlled_by_system'))
            .fontSize(10).fontColor(this.colors.accentGold)
            .fontStyle(FontStyle.Italic).margin({ top: 4 })
        }
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: this.soundEnabled })
        .selectedColor(this.colors.accentGold)
        .enabled(this.systemSoundEnabled)
        .opacity(this.systemSoundEnabled ? 1.0 : 0.5)
        .onChange((isOn: boolean) => {
          this.toggleSound(isOn);
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
  }

  @Builder
  SoundStyleRow() {
    if (this.soundEnabled && this.systemSoundEnabled) {
      Row() {
        Column() {
          Text(this.tr('sound_style'))
            .fontSize(15).fontColor(this.colors.textWhite)
            .fontWeight(FontWeight.Medium)
          Text(this.tr('sound_style_desc'))
            .fontSize(11).fontColor(this.colors.textMuted)
            .margin({ top: 2 })
          Text(this.soundDisplayName(this.selectedSound))
            .fontSize(12)
            .fontColor(this.colors.accentGold)
            .maxLines(1)
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
      .onClick(() => {
        this.showSoundPicker = true;
      })
    }
  }

  @Builder
  LanguageRow() {
    Row() {
      Column() {
        Text(this.tr('language'))
          .fontSize(15).fontColor(this.colors.textWhite)
          .fontWeight(FontWeight.Medium)
        Text(this.tr('language_desc'))
          .fontSize(11).fontColor(this.colors.textMuted)
          .margin({ top: 2 })
        Text(this.currentLanguageLabel())
          .fontSize(12)
          .fontColor(this.colors.accentGold)
          .maxLines(1)
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
    .onClick(() => {
      this.showLanguagePicker = true;
    })
  }

  @Builder
  AppearanceContent() {
    Column() {
      // ---- App Theme preset ----
      Row() {
        Column() {
          Text(this.tr('theme_preset'))
            .fontSize(15).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
          Text(this.tr('theme_preset_desc'))
            .fontSize(11).fontColor(this.colors.textMuted).margin({ top: 2 })
          Row() {
            Row()
              .width(14)
              .height(14)
              .borderRadius(7)
              .backgroundColor(this.appThemeSwatch(this.appTheme))
              .border({ width: 1, color: this.colors.borderSoft })
            Text(this.appThemeLabel())
              .fontSize(12)
              .fontColor(this.colors.accentGold)
              .margin({ left: 8 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .margin({ top: 6 })
          .alignItems(VerticalAlign.Center)
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        Text('›').fontSize(22).fontColor(this.colors.accentGold).opacity(0.7)
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
      .onClick(() => {
        this.showAppThemePicker = true;
      })

      // ---- Dark Mode ----
      Row() {
        Column() {
          Text(this.tr('dark_mode'))
            .fontSize(15).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
          Text(this.tr('dark_mode_desc'))
            .fontSize(11).fontColor(this.colors.textMuted).margin({ top: 2 })
          Text(this.themeModeLabel())
            .fontSize(12)
            .fontColor(this.colors.accentGold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        Text('›').fontSize(22).fontColor(this.colors.accentGold).opacity(0.7)
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
      .onClick(() => {
        this.showThemePicker = true;
      })
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(16)
    .border({ width: 1, color: this.colors.borderSoft })
    .margin({ bottom: 12 })
  }

  @Builder
  AppThemePicker() {
    Column()
      .width('100%').height('100%')
      .backgroundColor(this.colors.overlayDim)
      .onClick(() => {
        this.showAppThemePicker = false;
      })

    Column() {
      Row()
        .width(44)
        .height(4)
        .backgroundColor(this.colors.overlayDimSoft)
        .borderRadius(2)
        .margin({ top: 10 })

      Row() {
        Text('🎨')
          .fontSize(22)
          .width(44)
          .height(44)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.colors.tintSoft)
          .borderRadius(12)
          .border({ width: 1, color: this.colors.borderSoft })

        Text(this.tr('theme_preset'))
          .fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
          .margin({ left: 14 })
      }
      .width('100%').padding({ left: 20, top: 20, bottom: 20 })

      Divider().color(this.colors.borderSoft).width('90%')

      Column() {
        ForEach(
          [ThemePreset.SIRAT, ThemePreset.CURRENT, ThemePreset.HARMONY_7,
            ThemePreset.HARMONY_6, ThemePreset.HARMONY_5],
          (preset: string) => {
            Row() {
              Row()
                .width(34)
                .height(34)
                .borderRadius(17)
                .backgroundColor(this.appThemeSwatch(preset))
                .border({
                  width: 2,
                  color: preset === this.appTheme
                    ? this.colors.accentGold
                    : this.colors.borderSoft
                })

              Column() {
                Text(SettingsHelper.getAppThemeLabel(preset))
                  .fontSize(15)
                  .fontColor(preset === this.appTheme
                    ? this.colors.accentGold
                    : this.colors.textWhite)
                  .fontWeight(preset === this.appTheme
                    ? FontWeight.Bold
                    : FontWeight.Normal)
                  .width('100%')

                Text(this.appThemeSubtitle(preset))
                  .fontSize(11)
                  .fontColor(this.colors.textMuted)
                  .margin({ top: 2 })
                  .width('100%')
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1).margin({ left: 14 })

              if (preset === this.appTheme) {
                Text('✓')
                  .fontSize(18)
                  .fontColor(this.colors.accentGold)
                  .fontWeight(FontWeight.Bold)
              }
            }
            .width('100%')
            .padding({
              top: 14,
              bottom: 14,
              left: 20,
              right: 20
            })
            .backgroundColor(preset === this.appTheme
              ? this.colors.tintSoft
              : 'transparent')
            .borderRadius(12)
            .margin({ bottom: 4 })
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.pickAppTheme(preset);
            })
          },
          (preset: string) => `preset-${preset}`
        )
      }
      .width('100%')
      .padding({
        left: 8,
        right: 8,
        top: 12,
        bottom: 12
      })

      Button(this.tr('cancel'))
        .width('90%')
        .height(48)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textWhite)
        .backgroundColor(this.colors.tintSoft)
        .borderRadius(12)
        .margin({ top: 8, bottom: 24 })
        .onClick(() => {
          this.showAppThemePicker = false;
        })
    }
    .width('100%')
    .backgroundColor(this.colors.cardDark)
    .borderRadius({ topLeft: 28, topRight: 28 })
    .shadow({
      radius: 24,
      color: this.colors.shadowFloating,
      offsetX: 0,
      offsetY: -6
    })
    .border({ width: { top: 1 }, color: this.colors.borderSoft })
    .position({ bottom: 0 })
  }

  @Builder
  SoundPicker() {
    Column()
      .width('100%').height('100%')
      .backgroundColor(this.colors.overlayDim)
      .onClick(() => {
        this.showSoundPicker = false;
      })

    Column() {
      Row()
        .width(44)
        .height(4)
        .backgroundColor(this.colors.overlayDimSoft)
        .borderRadius(2)
        .margin({ top: 10 })

      Row() {
        Text('🔊')
          .fontSize(22)
          .width(44)
          .height(44)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.colors.tintSoft)
          .borderRadius(12)
          .border({ width: 1, color: this.colors.borderSoft })

        Text(this.tr('sound_style'))
          .fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
          .margin({ left: 14 })
      }
      .width('100%').padding({ left: 20, top: 20, bottom: 20 })

      Divider().color(this.colors.borderSoft).width('90%')

      Column() {
        ForEach(TASBIH_SOUND_OPTIONS, (opt: TasbihSoundOption) => {
          Row() {
            Stack() {
              Text('▶')
                .fontSize(14)
                .fontColor(this.colors.accentGold)
            }
            .width(38)
            .height(38)
            .borderRadius(19)
            .backgroundColor(this.colors.tintSoft)
            .border({ width: 1, color: this.colors.borderSoft })
            .alignContent(Alignment.Center)
            .onClick(() => {
              SoundHelper.preview(opt.id);
            })

            Column() {
              Text(this.soundDisplayName(opt.id))
                .fontSize(15)
                .fontColor(opt.id === this.selectedSound
                  ? this.colors.accentGold
                  : this.colors.textWhite)
                .fontWeight(opt.id === this.selectedSound
                  ? FontWeight.Bold
                  : FontWeight.Normal)
                .width('100%')

              Text(this.soundDescription(opt.id))
                .fontSize(11)
                .fontColor(this.colors.textMuted)
                .margin({ top: 2 })
                .width('100%')
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1).margin({ left: 14 })

            if (opt.id === this.selectedSound) {
              Text('✓')
                .fontSize(18)
                .fontColor(this.colors.accentGold)
                .fontWeight(FontWeight.Bold)
            }
          }
          .width('100%')
          .padding({
            top: 12,
            bottom: 12,
            left: 20,
            right: 20
          })
          .backgroundColor(opt.id === this.selectedSound
            ? this.colors.tintSoft
            : 'transparent')
          .borderRadius(12)
          .margin({ bottom: 4 })
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.pickSound(opt.id);
          })
        }, (opt: TasbihSoundOption) => `sound-${opt.id}`)
      }
      .width('100%')
      .padding({
        left: 8,
        right: 8,
        top: 12,
        bottom: 12
      })

      Button(this.tr('cancel'))
        .width('90%')
        .height(48)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textWhite)
        .backgroundColor(this.colors.tintSoft)
        .borderRadius(12)
        .margin({ top: 8, bottom: 24 })
        .onClick(() => {
          this.showSoundPicker = false;
        })
    }
    .width('100%')
    .backgroundColor(this.colors.cardDark)
    .borderRadius({ topLeft: 28, topRight: 28 })
    .shadow({
      radius: 24,
      color: this.colors.shadowFloating,
      offsetX: 0,
      offsetY: -6
    })
    .border({ width: { top: 1 }, color: this.colors.borderSoft })
    .position({ bottom: 0 })
  }

  @Builder
  PickerOverlay(
    title: string,
    icon: string,
    items: PickerItem[],
    onSelect: (id: string) => void,
    onCancel: () => void
  ) {
    Column()
      .width('100%').height('100%')
      .backgroundColor(this.colors.overlayDim)
      .onClick(() => {
        onCancel();
      })

    Column() {
      Row()
        .width(44)
        .height(4)
        .backgroundColor(this.colors.overlayDimSoft)
        .borderRadius(2)
        .margin({ top: 10 })

      Row() {
        Text(icon)
          .fontSize(22)
          .width(44)
          .height(44)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.colors.tintSoft)
          .borderRadius(12)
          .border({ width: 1, color: this.colors.borderSoft })

        Text(title)
          .fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
          .margin({ left: 14 })
      }
      .width('100%').padding({ left: 20, top: 20, bottom: 20 })

      Divider().color(this.colors.borderSoft).width('90%')

      Column() {
        ForEach(items, (item: PickerItem) => {
          Row() {
            Row() {
              if (item.selected) {
                Row()
                  .width(10).height(10).borderRadius(5)
                  .backgroundColor(this.colors.accentGold)
              }
            }
            .width(22)
            .height(22)
            .borderRadius(11)
            .border({
              width: item.selected ? 2 : 1.5,
              color: item.selected ? this.colors.accentGold : this.colors.borderStrong
            })
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)

            Text(item.label)
              .fontSize(15)
              .fontColor(item.selected ? this.colors.accentGold : this.colors.textWhite)
              .fontWeight(item.selected ? FontWeight.Bold : FontWeight.Normal)
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
          .backgroundColor(item.selected ? this.colors.tintSoft : 'transparent')
          .borderRadius(12)
          .margin({ bottom: 4 })
          .onClick(() => {
            onSelect(item.id);
          })
        }, (item: PickerItem) => item.id)
      }
      .width('100%')
      .padding({
        left: 8,
        right: 8,
        top: 12,
        bottom: 12
      })

      Button(this.tr('cancel'))
        .width('90%')
        .height(48)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textWhite)
        .backgroundColor(this.colors.tintSoft)
        .borderRadius(12)
        .margin({ top: 8, bottom: 24 })
        .onClick(() => {
          onCancel();
        })
    }
    .width('100%')
    .backgroundColor(this.colors.cardDark)
    .borderRadius({ topLeft: 28, topRight: 28 })
    .shadow({
      radius: 24,
      color: this.colors.shadowFloating,
      offsetX: 0,
      offsetY: -6
    })
    .border({ width: { top: 1 }, color: this.colors.borderSoft })
    .position({ bottom: 0 })
  }

  @Builder
  AutoShowRamadanViewRow() {
    Row() {
      Column() {
        Text(this.tr('auto_show_ramadan_view'))
          .fontSize(15).fontColor(this.colors.textWhite)
          .fontWeight(FontWeight.Medium)
        Text(this.tr('auto_show_ramadan_view_desc'))
          .fontSize(11)
          .fontColor(this.colors.textMuted)
          .margin({ top: 2 })
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: this.autoShowRamadanView })
        .selectedColor(this.colors.accentGold)
        .onChange((isOn: boolean) => {
          this.autoShowRamadanView = isOn;
          SettingsHelper.saveAutoShowRamadanView(isOn);
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

  private isTablet(): boolean {
    return Breakpoints.isTablet(this.breakpoint);
  }

  private onThemeModeChanged(): void {
    this.colors = PageTheme.compute(this.themeMode);
  }

  private onLanguageChanged(): void {
    this.currentLanguage = this.appLanguage;
  }

  private onAppThemePresetChanged(): void {
    this.colors = PageTheme.compute(this.themeMode);
  }

  private onSystemFeedbackChanged(): void {
    // UI reacts via the @StorageLink binding itself.
  }

  private async onAppForegrounded(): Promise<void> {
    this.currentLanguage = this.appLanguage;
    this.applyTheme();
    await this.reload();
  }

  private applyTheme(): void {
    this.colors = PageTheme.compute(this.themeMode);
  }

  private pickThemeMode(id: string): void {
    this.themeMode = id;
    this.colors = PageTheme.compute(id);
    SettingsHelper.saveThemeMode(id);
    this.showThemePicker = false;
  }

  private pickLanguage(id: string): void {
    this.appLanguage = id;
    this.currentLanguage = id;
    SettingsHelper.saveLanguage(id);
    this.showLanguagePicker = false;
  }

  private pickAppTheme(id: string): void {
    this.appTheme = id;
    SettingsHelper.saveAppTheme(id);
    this.colors = PageTheme.compute(this.themeMode);
    this.showAppThemePicker = false;
  }

  private pickSound(id: string): void {
    this.selectedSound = id;
    SettingsHelper.saveTasbihSound(id);
    this.showSoundPicker = false;
    setTimeout(() => {
      SoundHelper.preview(id);
    }, 150);
  }

  private async reload(): Promise<void> {
    const data = await SettingsHelper.loadAll();
    this.showIslamicEvents = data.showIslamicEvents;

    this.showImsakList = data.showImsakList;
    this.showFirstThirdList = data.showFirstThirdList;
    this.showMidnightList = data.showMidnightList;
    this.showLastThirdList = data.showLastThirdList;
    this.showImsakSunpath = data.showImsakSunpath;
    this.showFirstThirdSunpath = data.showFirstThirdSunpath;
    this.showMidnightSunpath = data.showMidnightSunpath;
    this.showLastThirdSunpath = data.showLastThirdSunpath;
    this.autoShowRamadanView = data.autoShowRamadanView;

    this.vibrationEnabled = SettingsHelper.getVibrationEnabled();
    this.soundEnabled = SettingsHelper.getSoundEnabled();
    this.selectedSound = SettingsHelper.getTasbihSound();

    const preset = await SettingsHelper.getAppTheme();
    this.appTheme = preset;
  }

  private toggleShowIslamicEvents(value: boolean): void {
    this.showIslamicEvents = value;
    SettingsHelper.saveShowIslamicEvents(value);
  }

  private toggleShowImsakList(value: boolean): void {
    this.showImsakList = value;
    SettingsHelper.saveShowImsakList(value);
  }

  private toggleShowFirstThirdList(value: boolean): void {
    this.showFirstThirdList = value;
    SettingsHelper.saveShowFirstThirdList(value);
  }

  private toggleShowMidnightList(value: boolean): void {
    this.showMidnightList = value;
    SettingsHelper.saveShowMidnightList(value);
  }

  private toggleShowLastThirdList(value: boolean): void {
    this.showLastThirdList = value;
    SettingsHelper.saveShowLastThirdList(value);
  }

  private toggleShowImsakSunpath(value: boolean): void {
    this.showImsakSunpath = value;
    SettingsHelper.saveShowImsakSunpath(value);
  }

  private toggleShowFirstThirdSunpath(value: boolean): void {
    this.showFirstThirdSunpath = value;
    SettingsHelper.saveShowFirstThirdSunpath(value);
  }

  private toggleShowMidnightSunpath(value: boolean): void {
    this.showMidnightSunpath = value;
    SettingsHelper.saveShowMidnightSunpath(value);
  }

  private toggleShowLastThirdSunpath(value: boolean): void {
    this.showLastThirdSunpath = value;
    SettingsHelper.saveShowLastThirdSunpath(value);
  }

  private toggleVibration(value: boolean): void {
    this.vibrationEnabled = value;
    SettingsHelper.saveVibrationEnabled(value);
  }

  private toggleSound(value: boolean): void {
    this.soundEnabled = value;
    SettingsHelper.saveSoundEnabled(value);
  }

  private soundDisplayName(id: string): string {
    const opt = SoundOptions.byId(id);
    if (!opt) {
      return id;
    }

    const base = opt.file.replace(/^tasbih_/, '').replace(/\.ogg$/, '');
    const key = `sound_${base}_name`;
    const localized = this.tr(key);
    if (localized !== key) {
      return localized;
    }

    return SoundOptions.deriveDisplayName(opt.file);
  }

  private soundDescription(id: string): string {
    const opt = SoundOptions.byId(id);
    if (!opt) {
      return '';
    }

    const base = opt.file.replace(/^tasbih_/, '').replace(/\.ogg$/, '');
    const key = `sound_${base}_desc`;
    const localized = this.tr(key);
    if (localized !== key) {
      return localized;
    }

    return SoundOptions.deriveDescription(opt.file);
  }

  private buildLanguageItems(): PickerItem[] {
    const langs = [AppLanguage.ENGLISH, AppLanguage.CHINESE, AppLanguage.ARABIC];
    return langs.map((l): PickerItem => {
      const item: PickerItem = {
        id: l,
        label: L.get(`lang_${l}`, this.currentLanguage),
        selected: l === this.appLanguage
      };
      return item;
    });
  }

  private currentLanguageLabel(): string {
    return L.get(`lang_${this.appLanguage}`, this.currentLanguage);
  }

  private buildThemeItems(): PickerItem[] {
    // Only Light and System are exposed in the UI.
    const modes = [ThemeMode.LIGHT, ThemeMode.SYSTEM];

    return modes.map((m): PickerItem => {
      const item: PickerItem = {
        id: m,
        label: m === ThemeMode.LIGHT ? this.tr('theme_light')
          : this.tr('theme_system'),
        selected: m === this.themeMode
      };
      return item;
    });
  }

  private themeModeLabel(): string {
    switch (this.themeMode) {
      case ThemeMode.LIGHT:
        return this.tr('theme_light');
      case ThemeMode.DARK:
        return this.tr('theme_dark');
      case ThemeMode.SYSTEM:
        return this.tr('theme_system');
      default:
        return this.tr('theme_system');
    }
  }

  private appThemeLabel(): string {
    return SettingsHelper.getAppThemeLabel(this.appTheme);
  }

  private appThemeSwatch(preset: string): string {
    const preview = Theme.getColors(
      this.themeMode,
      PageTheme.isSystemDark(),
      preset
    );
    return preview.accentGold;
  }

  private appThemeSubtitle(preset: string): string {
    switch (preset) {
      case ThemePreset.SIRAT:
        return this.tr('theme_preset_sirat_desc');
      case ThemePreset.HARMONY_7:
        return this.tr('theme_preset_harmony7_desc');
      case ThemePreset.HARMONY_6:
        return this.tr('theme_preset_harmony6_desc');
      case ThemePreset.HARMONY_5:
        return this.tr('theme_preset_harmony5_desc');
      case ThemePreset.CURRENT:
      default:
        return this.tr('theme_preset_current_desc');
    }
  }

  /**
   * Resolve the Event Perspective value label through this.tr(...)
   * rather than SettingsHelper.getEventPerspectiveLabel, so the
   * text node depends on currentLanguage and re-renders when the
   * language changes.
   */
  private eventPerspectiveLabel(): string {
    switch (this.eventPerspective) {
      case SettingsHelper.EVENT_PERSPECTIVE_SUNNI:
        return this.tr('event_perspective_sunni');
      case SettingsHelper.EVENT_PERSPECTIVE_SHIA:
        return this.tr('event_perspective_shia');
      case SettingsHelper.EVENT_PERSPECTIVE_ALL:
        return this.tr('event_perspective_all');
      case SettingsHelper.EVENT_PERSPECTIVE_UNIVERSAL:
      default:
        return this.tr('event_perspective_universal');
    }
  }
}