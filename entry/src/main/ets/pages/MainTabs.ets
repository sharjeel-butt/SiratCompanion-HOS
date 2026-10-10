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
  STORAGE_KEY_LANGUAGE,
  STORAGE_KEY_THEME_MODE
} from '../common/StorageKeys';
import { L } from '../helper/LocalizationHelper';
import { NavHelper } from '../helper/NavHelper';

import { HomePage } from './HomePage';
import { Prayer } from './Prayer';
import { HijriCalendarPage } from './HijriCalendarPage';
import { QiblaPage } from './QiblaPage';
import { TasbihPage } from './TasbihPage';

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

      // Custom hamburger button positioned over the title bar area.
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
  }

  // ============================================================
  // FALLBACK HOST (API 20–22)
  // ============================================================

  @Builder
  TabsFallbackHost() {
    Column() {
      // Fallback title bar — mirrors the HdsNavigation MINI bar.
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
      this.buildMenuOptions()
    )
  }

  /**
   * Menu options for the hamburger popup.
   *
   * The app declares "ohos.arkui.UIMaterial.state": "enable" in
   * module.json5, so on API 26+ the framework applies immersive
   * material to the menu automatically. On pre-API-26 devices the
   * material is not available and the menu falls back to the
   * plain cardDark background.
   *
   * Placement is BottomRight so the menu opens below the button,
   * aligning its right edge with the button's right edge.
   */
  private buildMenuOptions(): MenuOptions {
    const opts: MenuOptions = {
      placement: Placement.BottomRight,
      enableArrow: false,
      backgroundColor: this.colors.cardDark,
      onDisappear: () => {
        this.isMenuVisible = false;
      }
    };
    return opts;
  }

  @Builder
  HamburgerMenuContent() {
    Menu() {
      this.HamburgerMenuItem(
        $r('app.media.ic_menu_customize'),
        L.get('title_customize', this.currentLanguage),
        () => {
          this.isMenuVisible = false;
          this.closeMenuAndNavigate('pages/CustomizePage');
        }
      )

      this.HamburgerMenuItem(
        $r('app.media.ic_menu_settings'),
        L.get('title_settings', this.currentLanguage),
        () => {
          this.isMenuVisible = false;
          this.closeMenuAndNavigate('pages/SettingsPage');
        }
      )

      this.HamburgerMenuItem(
        $r('app.media.ic_menu_exit'),
        L.get('exit', this.currentLanguage),
        () => {
          this.isMenuVisible = false;
          this.exitApp();
        }
      )
    }
  }

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

      Text(label)
        .fontSize(15)
        .fontColor(this.colors.textWhite)
        .fontWeight(FontWeight.Medium)
        .margin({ left: 12 })
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding({
      top: 10,
      bottom: 10,
      left: 14,
      right: 20
    })
    .hoverEffect(HoverEffect.Highlight)
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
    .tabBar(this.TabBarItem(0, $r('app.media.tab_home'),
      L.get('tab_home', this.currentLanguage)))

    TabContent() {
      Prayer()
    }
    .tabBar(this.TabBarItem(1, $r('app.media.tab_prayers'),
      L.get('tab_prayers', this.currentLanguage)))

    TabContent() {
      HijriCalendarPage()
    }
    .tabBar(this.TabBarItem(2, $r('app.media.tab_calendar'),
      L.get('tab_calendar', this.currentLanguage)))

    TabContent() {
      QiblaPage()
    }
    .tabBar(this.TabBarItem(3, $r('app.media.tab_compass'),
      L.get('tab_compass', this.currentLanguage)))

    TabContent() {
      TasbihPage()
    }
    .tabBar(this.TabBarItem(4, $r('app.media.tab_tasbih'),
      L.get('tab_tasbih', this.currentLanguage)))
  }

  @Builder
  TabBarItem(index: number, icon: Resource, label: string) {
    Column() {
      Image(icon)
        .width(26)
        .height(26)
        .fillColor(this.currentIndex === index
          ? this.colors.accentGold
          : this.colors.textMuted)
        .objectFit(ImageFit.Contain)

      Text(label)
        .fontSize(10)
        .fontWeight(this.currentIndex === index
          ? FontWeight.Bold
          : FontWeight.Medium)
        .fontColor(this.currentIndex === index
          ? this.colors.accentGold
          : this.colors.textMuted)
        .margin({ top: 4 })
        .maxLines(2)
        .textAlign(TextAlign.Center)
        .lineHeight(11)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height(68)
    .justifyContent(FlexAlign.Center)
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