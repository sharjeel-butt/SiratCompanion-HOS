// entry/src/main/ets/pages/MainTabs.ets

import { display, mediaquery } from '@kit.ArkUI';
import { deviceInfo } from '@kit.BasicServicesKit';
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
import { MaterialHelper } from '../helper/MaterialHelper';

import { HomePage } from './HomePage';
import { Prayer } from './Prayer';
import { HijriCalendarPage } from './HijriCalendarPage';
import { QiblaPage } from './QiblaPage';
import { TasbihPage } from './TasbihPage';

/**
 * MainTabs — the application's root page.
 *
 * Hosts the five primary screens inside a single Tabs container.
 *
 * ## API compatibility
 *
 *   API 26.0.0+  → native Tabs.barFloatingStyle + systemMaterial
 *                  (HOS7 immersive glass)
 *   API 20–25    → Tabs with barOverlap + barBackgroundBlurStyle
 *                  (translucent fallback, no system material)
 *
 * Both branches share the same TabContents() builder, so the tab set
 * stays in sync. Only the bar styling differs.
 *
 * ## Why not use deviceInfo.apiAvailable()?
 *
 * apiAvailable() is itself @since 26.0.0 and would throw on API 20.
 * deviceInfo.sdkApiVersion exists on every API level and is the correct
 * guard here.
 */
@Entry
@Component
struct MainTabs {
  // ============================================================
  // STORAGE LINKS
  // ============================================================

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
  breakpoint: string = 'sm';
  @State private currentLanguage: string = 'en';
  @State colors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);
  /** Active tab index. Mirrors the Tabs controller. */
  @State private currentIndex: number = 0;
  /** Computed bar width, matched to all three breakpoints. */
  @State private barWidth: number = 340;
  /**
   * True when the device supports native barFloatingStyle.
   * Resolved once at first build; the SDK version cannot change
   * while the app is running.
   */
  private readonly useFloatingStyle: boolean =
    deviceInfo.sdkApiVersion >= MaterialHelper.MIN_API_FOR_MATERIAL;
  private tabsController: TabsController = new TabsController();
  private systemDarkListener: mediaquery.MediaQueryListener | null = null;

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

    try {
      const info = display.getDefaultDisplaySync();
      const screenW = px2vp(info.width);
      this.barWidth = Math.min(screenW - 32, 560);
    } catch (err) {
      this.barWidth = 340;
    }

    // One-line diagnostic: confirms which bar path is active on this device.
    console.info(
      `[MainTabs] sdkApiVersion=${deviceInfo.sdkApiVersion}, ` +
        `useFloatingStyle=${this.useFloatingStyle}`
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

  // ============================================================
  // WATCHERS
  // ============================================================

  private onThemeModeChanged(): void {
    this.colors = PageTheme.compute(this.themeMode);
  }

  private onAppThemePresetChanged(): void {
    this.colors = PageTheme.compute(this.themeMode);
  }

  private onLanguageChanged(): void {
    this.currentLanguage = this.appLanguage;
  }

  // ============================================================
  // TAB BAR COLOURS
  // ============================================================

  /** Resolve dark from the user's theme choice, not the OS alone. */
  private isDark(): boolean {
    return PageTheme.isDarkFor(this.themeMode);
  }

  /**
   * Active tab colour, taken from the current theme's accent.
   *
   * `this.colors` is recomputed by `onThemeModeChanged` whenever the
   * user switches preset or mode, so the tab bar follows the theme
   * automatically. There is no per-theme hard-coding here.
   */
  private activeColor(): string {
    return this.colors.accentGold;
  }

  /**
   * Inactive tab colour. Uses the theme's muted text tone so that the
   * tab bar reads as part of the same visual system as the rest of the
   * UI, rather than a separate grey.
   */
  private inactiveColor(): string {
    return this.colors.textMuted;
  }

  /** Fallback bar fill — translucent, colour-matched to the theme. */
  private fallbackBarColor(): string {
    return this.isDark()
      ? 'rgba(20, 27, 46, 0.55)'
      : 'rgba(255, 255, 255, 0.55)';
  }

  // ============================================================
  // BUILD
  // ============================================================

  build() {
    if (this.useFloatingStyle) {
      this.TabsWithFloatingStyle()
    } else {
      this.TabsWithFallbackBar()
    }
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

  // ============================================================
  // API 26.0.0+ — NATIVE FLOATING STYLE + IMMERSIVE MATERIAL
  // ============================================================

  @Builder
  TabsWithFloatingStyle() {
    Tabs({
      barPosition: BarPosition.End,
      controller: this.tabsController
    }) {
      this.TabContents()
    }
    // The three structural preconditions for barFloatingStyle:
    .barOverlap(true)
    .vertical(false)
    .barPosition(BarPosition.End)
    .barHeight(80)
    // systemMaterial supplies the HOS7 immersive glass.
    // Do NOT also set barBackgroundColor or barBackgroundBlurStyle —
    // the docs say those fight the material.
    .barFloatingStyle({
      barBottomMargin: 24,
      barWidth: {
        smallBarWidth: this.barWidth,
        mediumBarWidth: this.barWidth,
        largeBarWidth: this.barWidth
      },
      maskColor: Color.Transparent,
      maskHeight: 0,
      systemMaterial: MaterialHelper.tabBarMaterial()
    })
    .scrollable(false)
    .onChange((index: number) => {
      this.currentIndex = index;
    })
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.primaryGreen)

    // Do NOT expand BOTTOM — the floating bar needs the gesture area.
  }

  // ============================================================
  // API 20–25 — TRANSLUCENT FALLBACK BAR
  // ============================================================

  @Builder
  TabsWithFallbackBar() {
    Tabs({
      barPosition: BarPosition.End,
      controller: this.tabsController
    }) {
      this.TabContents()
    }
    .barOverlap(true)
    .vertical(false)
    .barPosition(BarPosition.End)
    .barHeight(80)
    // Blur + semi-transparent fill emulate the material wisthout
    // requiring API 26. barBackgroundBlurStyle is available on the
    // API levels this branch targets.
    .barBackgroundBlurStyle(BlurStyle.Thin)
    .barBackgroundColor(this.fallbackBarColor())
    .scrollable(false)
    .onChange((index: number) => {
      this.currentIndex = index;
    })
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.primaryGreen)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  // ============================================================
  // TAB BAR ITEM
  // ============================================================

  @Builder
  TabBarItem(
    index: number,
    icon: Resource,
    label: string
  ) {
    Column() {
      Image(icon)
        .width(26)
        .height(26)
        .fillColor(this.currentIndex === index
          ? this.activeColor()
          : this.inactiveColor())
        .objectFit(ImageFit.Contain)

      Text(label)
        .fontSize(11)
        .fontWeight(this.currentIndex === index
          ? FontWeight.Bold
          : FontWeight.Medium)
        .fontColor(this.currentIndex === index
          ? this.activeColor()
          : this.inactiveColor())
        .margin({ top: 4 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height(68)
    .justifyContent(FlexAlign.Center)
  }
}