// entry/src/main/ets/pages/MainTabs.ets

import { display, mediaquery, promptAction, router, window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import {
  STORAGE_KEY_APP_FOREGROUND_TICK,
  STORAGE_KEY_APP_THEME,
  STORAGE_KEY_BREAKPOINT,
  STORAGE_KEY_CALC_SETTINGS_VERSION,
  STORAGE_KEY_EVENT_SETTINGS_VERSION,
  STORAGE_KEY_HIJRI_CALENDAR_VERSION,
  STORAGE_KEY_LANGUAGE,
  STORAGE_KEY_LOCATION_VERSION,
  STORAGE_KEY_NAV_TARGET_TAB,
  STORAGE_KEY_THEME_MODE,
  STORAGE_KEY_TIME_FORMAT
} from '../core/StorageKeys';
import {
  HdsBarWidthRangeOptions,
  hdsMaterial,
  HdsNavigation,
  HdsNavigationTitleMode,
  HdsTabs,
  HdsTabsController,
  HdsTabsFloatingStyle,
  ScrollEffectType,
  SystemMaterialParams
} from '@kit.UIDesignKit';
import { ThemeColors, ThemeMode, ThemePreset } from '../core/Theme';
import { PageTheme } from '../core/PageTheme';
import { L } from '../i18n/LocalizationHelper';
import { NavHelper } from '../core/NavHelper';

import { HomePage } from './HomePage';
import { Prayer } from '../prayer/Prayer';
import { HijriCalendarPage } from '../hijricalendar/HijriCalendarPage';
import { QiblaPage } from '../qibla/QiblaPage';
import { TasbihPage } from '../tasbih/TasbihPage';
import { TypographyHelper } from '../core/TypographyHelper';
import { AppLogger } from '../core/AppLogger';
import { WidgetHelper } from '../widgets/WidgetHelper';

const HDS_MIN_API = 23;

@Entry
@Component
struct MainTabs {
  @StorageLink(STORAGE_KEY_THEME_MODE)
  @Watch('onThemeModeChanged')
  themeMode: string = ThemeMode.SYSTEM;
  @StorageLink(STORAGE_KEY_APP_THEME)
  @Watch('onAppThemePresetChanged')
  appThemePreset: string = ThemePreset.SIRAT;
  @StorageLink(STORAGE_KEY_LANGUAGE)
  @Watch('onLanguageChanged')
  appLanguage: string = 'en';
  @StorageLink(STORAGE_KEY_APP_FOREGROUND_TICK)
  appForegroundTick: number = 0;
  @StorageLink(STORAGE_KEY_BREAKPOINT)
  @Watch('onBreakpointChanged')
  breakpoint: string = 'sm';
  // NEW watchers — add these
  @StorageLink(STORAGE_KEY_CALC_SETTINGS_VERSION)
  @Watch('onCalcSettingsChanged')
  calcSettingsVersion: number = 0;
  @StorageLink(STORAGE_KEY_LOCATION_VERSION)
  @Watch('onLocationVersionChanged')
  locationVersion: number = 0;
  @StorageLink(STORAGE_KEY_HIJRI_CALENDAR_VERSION)
  @Watch('onHijriCalendarVersionChanged')
  calendarVersion: number = 0;
  @StorageLink(STORAGE_KEY_NAV_TARGET_TAB)
  @Watch('onNavTargetTabChanged')
  navTargetTab: string = '';
  @StorageLink(STORAGE_KEY_TIME_FORMAT)
  @Watch('onTimeFormatChanged')
  timeFormat: string = 'System';
  @State colors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);
  @State private currentLanguage: string = 'en';
  @State private currentIndex: number = 0;
  @State private barWidth: number = 340;
  @State private isMenuVisible: boolean = false;
  private readonly useHds: boolean =
    deviceInfo.sdkApiVersion >= HDS_MIN_API;
  private tabsController: TabsController = new TabsController();
  private hdsController: HdsTabsController = new HdsTabsController();
  private systemDarkListener: mediaquery.MediaQueryListener | null = null;
  @State private isPageVisible: boolean = false;

  aboutToAppear(): void {
    this.currentLanguage = this.appLanguage;
    this.colors = PageTheme.compute(this.themeMode);
    this.systemDarkListener = PageTheme.installSystemListener(
      this.themeMode,
      (c) => {
        this.colors = c;
      }
    );
    this.recomputeBarWidth();
    try {
      const context = getContext(this) as common.UIAbilityContext;
      context.eventHub.on('widget_nav_event', this.onWidgetNavEvent);
    } catch (e) {
      console.warn('MainTabs: EventHub listen failed');
    }
  }

  aboutToDisappear(): void {
    PageTheme.uninstallSystemListener(this.systemDarkListener);
    this.systemDarkListener = null;
    // Unregister EventHub listener
    try {
      const context = getContext(this) as common.UIAbilityContext;
      context.eventHub.off('widget_nav_event', this.onWidgetNavEvent);
    } catch (e) {
      // ignore
    }
  }

  private onWidgetNavEvent = (target: string): void => {
    console.info(`[MainTabs] Received widget_nav_event: '${target}'`);
    if (target && target.length > 0) {
      this.applyNavTarget(target, false);
      AppStorage.setOrCreate(STORAGE_KEY_NAV_TARGET_TAB, '');
    }
  };

  onPageShow(): void {
    this.currentLanguage = this.appLanguage;
    this.colors = PageTheme.compute(this.themeMode);

    // Force Event Settings refresh
    const prevEv = AppStorage.get<number>(STORAGE_KEY_EVENT_SETTINGS_VERSION);
    const nextEv = (prevEv === undefined ? 0 : prevEv) + 1;
    AppStorage.setOrCreate(STORAGE_KEY_EVENT_SETTINGS_VERSION, nextEv);

    // Force Hijri Calendar refresh
    const prevCal = AppStorage.get<number>(STORAGE_KEY_HIJRI_CALENDAR_VERSION);
    const nextCal = (prevCal === undefined ? 0 : prevCal) + 1;

    // Check for pending nav on Warm Start (returning from background)
    this.applyPendingNavTarget();
    AppStorage.setOrCreate(STORAGE_KEY_HIJRI_CALENDAR_VERSION, nextCal);
    AppLogger.info('MainTabs', `deviceType=${deviceInfo.deviceType}`);
  }

  onPageHide(): void {
    this.isPageVisible = false;
  }

  private applyPendingNavTarget(): void {
    const pendingTarget: string = AppStorage.get<string>(STORAGE_KEY_NAV_TARGET_TAB) ?? '';
    if (pendingTarget.length > 0) {
      AppLogger.info('MainTabs', `Applying pending nav target: '${pendingTarget}'`);
      this.applyNavTarget(pendingTarget, false);
      AppStorage.setOrCreate(STORAGE_KEY_NAV_TARGET_TAB, '');
    }
  }

  build() {
    if (this.useHds) {
      this.HdsNavigationHost()
    } else {
      this.TabsFallbackHost()
    }
  }

  @Builder
  HdsNavigationHost() {
    Stack() {
      HdsNavigation() {
        HdsTabs({
          barPosition: BarPosition.End,
          controller: this.hdsController
        }) {
          this.TabContents()
        }
        .barOverlap(true)
        .vertical(false)
        .barHeight(80)
        // Only apply floating style if HDS accepted it.
        // If buildHdsFloatingStyle() throws, we skip it and
        // HDS falls back to a plain tab bar — stable on every SDK.
        .barFloatingStyle(this.safeFloatingStyle())
        .scrollable(false)
        .onChange((index: number) => {
          this.currentIndex = index;
        })
        .width('100%')
        .height('100%')
      }
      .mode(NavigationMode.Stack)
      .titleBar({
        content: {
          title: {
            mainTitle: this.currentTabTitle()
          }
        },
        style: {
          scrollEffectOpts: {
            enableScrollEffect: false,
            scrollEffectType: ScrollEffectType.GRADIENT_BLUR
          },
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.ADAPTIVE,
            materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
          }
        },
        avoidLayoutSafeArea: false,
        enableComponentSafeArea: true
      })
      .hideBackButton(true)
      .titleMode(HdsNavigationTitleMode.MINI)
      .width('100%')
      .height('100%')

      Row() {
        Blank()
        this.HamburgerButton()
      }
      .width('100%')
      .height('100%')
      .alignItems(VerticalAlign.Top)
      .padding({
        top: 8,
        left: this.isRtl() ? 8 : 0,
        right: this.isRtl() ? 0 : 8
      })
      .hitTestBehavior(HitTestMode.Transparent)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.primaryGreen)
    .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
  }

  @Builder
  TabsFallbackHost() {
    Column() {
      Row() {
        Text(this.currentTabTitle())
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textWhite)
          .layoutWeight(1)
          .maxLines(1)
          .textAlign(this.isRtl() ? TextAlign.End : TextAlign.Start)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        this.HamburgerButton()
      }
      .width('100%')
      .height(56)
      .padding({
        left: this.isRtl() ? 12 : 16,
        right: this.isRtl() ? 16 : 12
      })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(this.colors.primaryGreen)

      Tabs({
        barPosition: BarPosition.End,
        controller: this.tabsController
      }) {
        this.TabContents()
      }
      .barOverlap(true)
      .vertical(false)
      .barHeight(80)
      .barBackgroundBlurStyle(BlurStyle.Thin)
      .barBackgroundColor(this.fallbackBarColor())
      .scrollable(false)
      .onChange((index: number) => {
        this.currentIndex = index;
      })
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.primaryGreen)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
    .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
  }

  @Builder
  HamburgerButton() {
    Button({ type: ButtonType.Circle, stateEffect: true }) {
      Image($r('app.media.ic_menu'))
        .width(22)
        .height(22)
        .fillColor(this.colors.textWhite)
        .objectFit(ImageFit.Contain)
    }
    .width(44)
    .height(44)
    .backgroundColor(this.colors.tintSoft)
    .border({ width: 1, color: this.colors.borderSoft })
    .onClick(() => {
      this.toggleMenu();
    })
    .bindMenu(
      this.isMenuVisible,
      this.HamburgerMenuContent(),
      {
        placement: Placement.BottomRight,
        enableArrow: false,
        backgroundColor: this.colors.cardDark,
        onDisappear: () => {
          this.isMenuVisible = false;
        }
      }
    )
  }

  @Builder
  HamburgerMenuContent() {
    Menu() {
      // ---- Customize ----
      MenuItem() {
        Row({ space: 12 }) {
          Image($r('app.media.ic_menu_customize'))
            .width(20)
            .height(20)
            .fillColor(this.menuIconColor())
            .objectFit(ImageFit.Contain)
            .flexShrink(0)

          Text(L.get('title_customize', this.currentLanguage))
            .fontSize(15)
            .fontColor(this.menuTextColor())
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .constraintSize({ minWidth: 90 }) // <-- Forces straight alignment
        }
        .padding({
          top: 10,
          bottom: 10,
          left: 16,
          right: 16
        })
        .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
        .alignItems(VerticalAlign.Center)
      }
      .onClick(() => {
        this.isMenuVisible = false;
        this.closeMenuAndNavigate('pages/CustomizePage');
      })

      // ---- Settings ----
      MenuItem() {
        Row({ space: 12 }) {
          Image($r('app.media.ic_menu_settings'))
            .width(20)
            .height(20)
            .fillColor(this.menuIconColor())
            .objectFit(ImageFit.Contain)
            .flexShrink(0)

          Text(L.get('title_settings', this.currentLanguage))
            .fontSize(15)
            .fontColor(this.menuTextColor())
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .constraintSize({ minWidth: 90 }) // <-- Forces straight alignment
        }
        .padding({
          top: 10,
          bottom: 10,
          left: 16,
          right: 16
        })
        .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
        .alignItems(VerticalAlign.Center)
      }
      .onClick(() => {
        this.isMenuVisible = false;
        this.closeMenuAndNavigate('pages/SettingsPage');
      })

      // ---- Exit ----
      MenuItem() {
        Row({ space: 12 }) {
          Image($r('app.media.ic_menu_exit'))
            .width(20)
            .height(20)
            .fillColor(this.menuIconColor())
            .objectFit(ImageFit.Contain)
            .flexShrink(0)
            .scale({ x: this.isRtl() ? -1 : 1 }) // <-- Flips the exit icon in RTL

          Text(L.get('exit', this.currentLanguage))
            .fontSize(15)
            .fontColor(this.menuTextColor())
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .constraintSize({ minWidth: 90 }) // <-- Forces straight alignment
        }
        .padding({
          top: 10,
          bottom: 10,
          left: 16,
          right: 16
        })
        .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
        .alignItems(VerticalAlign.Center)
      }
      .onClick(() => {
        this.isMenuVisible = false;
        this.exitApp();
      })
    }
  }

  @Builder
  TabContents() {
    TabContent() {
      HomePage()
    }
    .tabBar(this.HomeTabBar())

    TabContent() {
      Prayer()
    }
    .tabBar(this.PrayersTabBar())

    TabContent() {
      HijriCalendarPage()
    }
    .tabBar(this.CalendarTabBar())

    TabContent() {
      QiblaPage()
    }
    .tabBar(this.CompassTabBar())

    TabContent() {
      TasbihPage()
    }
    .tabBar(this.TasbihTabBar())
  }

  @Builder
  HomeTabBar() {
    Column() {
      Image($r('app.media.tab_home'))
        .width(26).height(26)
        .fillColor(this.currentIndex === 0
          ? this.colors.accentGold : this.colors.textMuted)
        .objectFit(ImageFit.Contain)
      Text(L.get('tab_home', this.currentLanguage))
        .fontSize(10)
        .fontFamily(TypographyHelper.getFont(this.currentLanguage, this.currentIndex === 0)) // <---
        .fontWeight(this.currentIndex === 0
          ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.currentIndex === 0
          ? this.colors.accentGold : this.colors.textMuted)
        .margin({ top: 4 })
        .maxLines(2)
        .textAlign(TextAlign.Center)
        .lineHeight(11)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%').height(68).justifyContent(FlexAlign.Center)
  }

  @Builder
  PrayersTabBar() {
    Column() {
      Image($r('app.media.tab_prayers'))
        .width(26).height(26)
        .fillColor(this.currentIndex === 1
          ? this.colors.accentGold : this.colors.textMuted)
        .objectFit(ImageFit.Contain)
      Text(L.get('tab_prayers', this.currentLanguage))
        .fontSize(10)
        .fontWeight(this.currentIndex === 1
          ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.currentIndex === 1
          ? this.colors.accentGold : this.colors.textMuted)
        .margin({ top: 4 })
        .maxLines(2)
        .textAlign(TextAlign.Center)
        .lineHeight(11)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%').height(68).justifyContent(FlexAlign.Center)
  }

  @Builder
  CalendarTabBar() {
    Column() {
      Image($r('app.media.tab_calendar'))
        .width(26).height(26)
        .fillColor(this.currentIndex === 2
          ? this.colors.accentGold : this.colors.textMuted)
        .objectFit(ImageFit.Contain)
      Text(L.get('tab_calendar', this.currentLanguage))
        .fontSize(10)
        .fontWeight(this.currentIndex === 2
          ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.currentIndex === 2
          ? this.colors.accentGold : this.colors.textMuted)
        .margin({ top: 4 })
        .maxLines(2)
        .textAlign(TextAlign.Center)
        .lineHeight(11)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%').height(68).justifyContent(FlexAlign.Center)
  }

  @Builder
  CompassTabBar() {
    Column() {
      Image($r('app.media.tab_compass'))
        .width(26).height(26)
        .fillColor(this.currentIndex === 3
          ? this.colors.accentGold : this.colors.textMuted)
        .objectFit(ImageFit.Contain)
      Text(L.get('tab_compass', this.currentLanguage))
        .fontSize(10)
        .fontWeight(this.currentIndex === 3
          ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.currentIndex === 3
          ? this.colors.accentGold : this.colors.textMuted)
        .margin({ top: 4 })
        .maxLines(2)
        .textAlign(TextAlign.Center)
        .lineHeight(11)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%').height(68).justifyContent(FlexAlign.Center)
  }

  @Builder
  TasbihTabBar() {
    Column() {
      Image($r('app.media.tab_tasbih'))
        .width(26).height(26)
        .fillColor(this.currentIndex === 4
          ? this.colors.accentGold : this.colors.textMuted)
        .objectFit(ImageFit.Contain)
      Text(L.get('tab_tasbih', this.currentLanguage))
        .fontSize(10)
        .fontWeight(this.currentIndex === 4
          ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.currentIndex === 4
          ? this.colors.accentGold : this.colors.textMuted)
        .margin({ top: 4 })
        .maxLines(2)
        .textAlign(TextAlign.Center)
        .lineHeight(11)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%').height(68).justifyContent(FlexAlign.Center)
  }

  private onNavTargetTabChanged(): void {
    if (!this.navTargetTab || this.navTargetTab.length === 0) {
      return;
    }

    // If the page is in the background, do nothing.
    // onPageShow will pick up the pending target when it returns.
    if (!this.isPageVisible) {
      return;
    }

    this.applyNavTarget(this.navTargetTab, false);
    AppStorage.setOrCreate(STORAGE_KEY_NAV_TARGET_TAB, '');
  }

  private tabIndexFor(target: string): number {
    switch (target) {
      case 'home':
        return 0;
      case 'prayers':
        return 1;
      case 'calendar':
        return 2;
      case 'compass':
        return 3;
      case 'tasbih':
        return 4;
      default:
        return -1;
    }
  }

  private applyNavTarget(target: string, deferred: boolean): void {
    const targetIndex: number = this.tabIndexFor(target);
    if (targetIndex < 0) {
      return;
    }

    this.currentIndex = targetIndex;

    // Always delay the controller switch slightly to ensure UI is ready
    setTimeout((): void => {
      this.hdsController.changeIndex(targetIndex);
      this.tabsController.changeIndex(targetIndex);
    }, 100);
  }

  private onThemeModeChanged(): void {
    this.colors = PageTheme.compute(this.themeMode);
  }

  private onAppThemePresetChanged(): void {
    this.colors = PageTheme.compute(this.themeMode);
  }

  private onCalcSettingsChanged(): void {
    WidgetHelper.refreshAllDebounced();
  }

  // ============================================================
  // BUILD
  // ============================================================

  private onLocationVersionChanged(): void {
    WidgetHelper.refreshAllDebounced();
  }

  // ============================================================
  // HDS HOST
  // ============================================================

  private onHijriCalendarVersionChanged(): void {
    WidgetHelper.refreshAllDebounced();
  }

  private onTimeFormatChanged(): void {
    WidgetHelper.refreshAllDebounced();
  }

  // ============================================================
  // FALLBACK HOST (API 20–22)
  // ============================================================

  private onLanguageChanged(): void {
    this.currentLanguage = this.appLanguage;
    WidgetHelper.refreshAllDebounced();
  }

  private onBreakpointChanged(): void {
    this.recomputeBarWidth();
  }

  // ============================================================
  // HAMBURGER BUTTON + MENU
  // ============================================================

  private recomputeBarWidth(): void {
    try {
      const info = display.getDefaultDisplaySync();
      const screenW = px2vp(info.width);
      this.barWidth = Math.min(screenW - 32, 560);
    } catch (err) {
      this.barWidth = 340;
    }
  }

  /**
   * Color for the menu popup's icons and labels.
   *
   * The menu popup's background tracks the system theme, not the
   * app's themeMode setting. So the icon and label colors are picked
   * from the system state directly, ensuring they always contrast.
   */
  private menuIconColor(): string {
    return PageTheme.isSystemDark()
      ? '#FFFFFF'
      : '#1A1A1A';
  }

  // ============================================================
  // SHARED TAB CONTENT
  // ============================================================

  private menuTextColor(): string {
    return PageTheme.isSystemDark()
      ? '#FFFFFF'
      : '#1A1A1A';
  }

  // ---- Five parameterless tab bar builders ----
  // Each reads this.currentLanguage and this.currentIndex directly
  // so the labels and the active state refresh on every parent
  // render. Passing them as builder parameters would cache the
  // resolved label at first render and the tab bar would stay in
  // the language that was active when the app launched.

  private currentTabTitle(): string {
    switch (this.currentIndex) {
      case 0:
        return L.get('tab_home', this.currentLanguage);
      case 1:
        return L.get('tab_prayers', this.currentLanguage);
      case 2:
        return L.get('tab_calendar', this.currentLanguage);
      case 3:
        return L.get('tab_compass', this.currentLanguage);
      case 4:
        return L.get('tab_tasbih', this.currentLanguage);
      default:
        return L.get('app_name', this.currentLanguage);
    }
  }

  private toggleMenu(): void {
    this.isMenuVisible = !this.isMenuVisible;
  }

  private isRtl(): boolean {
    return L.isRtlLang(this.currentLanguage);
  }

  /**
   * Build the HDS floating style, or return an empty object so HDS
   * uses its default tab bar. Guarding prevents a partial parse from
   * leaving HDS's internal fsTabBarHandler_ undefined, which used to
   * cause downstream components to crash on access.
   */
  private safeFloatingStyle(): HdsTabsFloatingStyle {
    try {
      return this.buildHdsFloatingStyle();
    } catch (err) {
      AppLogger.warn('MainTabs',
        `buildHdsFloatingStyle failed: ${(err as Error).message}`);
      // Return an empty style — HDS will not create the floating
      // handler, but it will still render a standard tab bar.
      const empty: HdsTabsFloatingStyle = {};
      return empty;
    }
  }

  private fallbackBarColor(): string {
    const dark = PageTheme.isDarkFor(this.themeMode);
    return dark
      ? 'rgba(20, 27, 46, 0.55)'
      : 'rgba(255, 255, 255, 0.55)';
  }

  private buildHdsFloatingStyle(): HdsTabsFloatingStyle {
    const widths: HdsBarWidthRangeOptions = {
      smallWidth: this.barWidth,
      mediumWidth: this.barWidth,
      largeWidth: this.barWidth
    };

    const material: SystemMaterialParams = {
      materialType: hdsMaterial.MaterialType.ADAPTIVE,
      materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
    };

    const style: HdsTabsFloatingStyle = {
      barBottomMargin: 24,
      barWidth: widths,
      systemMaterialEffect: material
    };
    return style;
  }

  // ============================================================
  // NAVIGATION HELPERS
  // ============================================================

  private closeMenuAndNavigate(url: string): void {
    setTimeout(() => {
      NavHelper.prepareForward();
      router.pushUrl({ url })
        .catch((err: Error) =>
        console.error('Navigation failed:', JSON.stringify(err)));
    }, 120);
  }

  private exitApp(): void {
    promptAction.showDialog({
      title: L.get('exit', this.currentLanguage),
      message: L.get('exit_confirm_message', this.currentLanguage),
      buttons: [
        {
          text: L.get('cancel', this.currentLanguage),
          color: this.colors.dialogCancel
        },
        {
          text: L.get('exit', this.currentLanguage),
          color: this.colors.accentGold
        }
      ]
    }).then((result: promptAction.ShowDialogSuccessResponse) => {
      if (result.index === 1) {
        const ctx = getContext(this) as common.UIAbilityContext;

        // Delay slightly to allow the dialog dismiss animation to finish.
        setTimeout(async () => {
          const isPC = deviceInfo.deviceType === '2in1' || deviceInfo.deviceType === 'tablet';

          if (isPC) {
            // On PC/2-in-1, explicitly destroy the window BEFORE terminating.
            // If destroyWindow fails (e.g., app running in split screen),
            // we STILL call terminateSelf unconditionally.
            try {
              const win = await window.getLastWindow(ctx);
              await win.destroyWindow();
            } catch (e) {
              console.warn('[Exit] window destroy failed: ' + (e as Error).message);
            }
          }

          try {
            await ctx.terminateSelf();
            console.info('[Exit] terminateSelf succeeded');
          } catch (e) {
            console.error('[Exit] terminateSelf failed: ' + (e as Error).message);
          }
        }, 250);
      }
    }).catch((err: Error) => {
      console.error('Dialog error:', JSON.stringify(err));
    });
  }
}