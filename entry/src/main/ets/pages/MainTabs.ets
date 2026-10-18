// entry/src/main/ets/pages/MainTabs.ets

import { display, mediaquery, promptAction, router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { deviceInfo } from '@kit.BasicServicesKit';
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
import { ThemeColors, ThemeMode, ThemePreset } from '../common/Theme';
import { PageTheme } from '../common/PageTheme';
import {
  STORAGE_KEY_APP_FOREGROUND_TICK,
  STORAGE_KEY_APP_THEME,
  STORAGE_KEY_BREAKPOINT,
  STORAGE_KEY_EVENT_SETTINGS_VERSION,
  STORAGE_KEY_HIJRI_CALENDAR_VERSION,
  STORAGE_KEY_LANGUAGE,
  STORAGE_KEY_THEME_MODE
} from '../common/StorageKeys';
import { L } from '../i8n/LocalizationHelper';
import { NavHelper } from '../helper/NavHelper';

import { HomePage } from './HomePage';
import { Prayer } from './Prayer';
import { HijriCalendarPage } from './HijriCalendarPage';
import { QiblaPage } from './QiblaPage';
import { TasbihPage } from './TasbihPage';
import { TypographyHelper } from '../helper/TypographyHelper';

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
    console.info(
      `[MainTabs] sdkApiVersion=${deviceInfo.sdkApiVersion}, ` +
        `hds=${this.useHds}`
    );
  }

  aboutToDisappear(): void {
    PageTheme.uninstallSystemListener(this.systemDarkListener);
    this.systemDarkListener = null;
  }

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
    AppStorage.setOrCreate(STORAGE_KEY_HIJRI_CALENDAR_VERSION, nextCal);
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

  private onBreakpointChanged(): void {
    this.recomputeBarWidth();
  }

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

  private menuTextColor(): string {
    return PageTheme.isSystemDark()
      ? '#FFFFFF'
      : '#1A1A1A';
  }

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

  // ============================================================
  // BUILD
  // ============================================================

  build() {
    if (this.useHds) {
      this.HdsNavigationHost()
    } else {
      this.TabsFallbackHost()
    }
  }

  // ============================================================
  // HDS HOST
  // ============================================================

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
        .barFloatingStyle(this.buildHdsFloatingStyle())
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
      .padding({ top: 8, right: 8 })
      .hitTestBehavior(HitTestMode.Transparent)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.primaryGreen)
    .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
  }

  // ============================================================
  // FALLBACK HOST (API 20–22)
  // ============================================================

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
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        this.HamburgerButton()
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 12 })
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

  private fallbackBarColor(): string {
    const dark = PageTheme.isDarkFor(this.themeMode);
    return dark
      ? 'rgba(20, 27, 46, 0.55)'
      : 'rgba(255, 255, 255, 0.55)';
  }

  // ============================================================
  // HAMBURGER BUTTON + MENU
  // ============================================================

  @Builder
  HamburgerButton() {
    Button({ type: ButtonType.Circle, stateEffect: true }) {
      Text('☰')
        .fontSize(22)
        .fontColor(this.colors.textWhite)
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
      MenuItem() {
        Row() {
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
            .margin(this.isRtl() ? { right: 12 } : { left: 12 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%')
        .padding({
          top: 10,
          bottom: 10,
          left: this.isRtl() ? 20 : 14,
          right: this.isRtl() ? 14 : 20
        })
        .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
      }
      .onClick(() => {
        this.isMenuVisible = false;
        this.closeMenuAndNavigate('pages/CustomizePage');
      })

      MenuItem() {
        Row() {
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
            .margin(this.isRtl() ? { right: 12 } : { left: 12 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%')
        .padding({
          top: 10,
          bottom: 10,
          left: this.isRtl() ? 20 : 14,
          right: this.isRtl() ? 14 : 20
        })
        .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
      }
      .onClick(() => {
        this.isMenuVisible = false;
        this.closeMenuAndNavigate('pages/SettingsPage');
      })

      MenuItem() {
        Row() {
          Image($r('app.media.ic_menu_exit'))
            .width(20)
            .height(20)
            .fillColor(this.menuIconColor())
            .objectFit(ImageFit.Contain)
            .flexShrink(0)

          Text(L.get('exit', this.currentLanguage))
            .fontSize(15)
            .fontColor(this.menuTextColor())
            .fontWeight(FontWeight.Medium)
            .margin(this.isRtl() ? { right: 12 } : { left: 12 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%')
        .padding({
          top: 10,
          bottom: 10,
          left: this.isRtl() ? 20 : 14,
          right: this.isRtl() ? 14 : 20
        })
        .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
      }
      .onClick(() => {
        this.isMenuVisible = false;
        this.exitApp();
      })
    }
  }

  /**
   * Menu item. The Row carries an explicit direction so the layout
   * mirrors in Arabic — icons move to the right, labels to the left.
   * The Menu system popup does not inherit the page's direction on
   * every SDK build, so the explicit direction is required.
   */
  @Builder
  HamburgerMenuItem(
    icon: Resource, label: string, onTap: () => void
  ) {
    Row() {
      Image(icon)
        .width(20)
        .height(20)
        .fillColor(this.colors.textWhite)
        .objectFit(ImageFit.Contain)
        .flexShrink(0)

      Text(label)
        .fontSize(15)
        .fontColor(this.colors.textWhite)
        .fontWeight(FontWeight.Medium)
        .margin(this.isRtl()
          ? { right: 12 }
          : { left: 12 })
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Blank()
    }
    .width('100%')
    .padding({
      top: 10,
      bottom: 10,
      left: this.isRtl() ? 20 : 14,
      right: this.isRtl() ? 14 : 20
    })
    .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
    .onClick(onTap)
  }

  // ============================================================
  // SHARED TAB CONTENT
  // ============================================================

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

  // ---- Five parameterless tab bar builders ----
  // Each reads this.currentLanguage and this.currentIndex directly
  // so the labels and the active state refresh on every parent
  // render. Passing them as builder parameters would cache the
  // resolved label at first render and the tab bar would stay in
  // the language that was active when the app launched.

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
        ctx.terminateSelf().catch((err: Error) =>
        console.error('Terminate failed:', JSON.stringify(err)));
      }
    }).catch((err: Error) =>
    console.error('Dialog error:', JSON.stringify(err)));
  }
}