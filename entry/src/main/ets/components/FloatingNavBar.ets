// entry/src/main/ets/components/FloatingNavBar.ets

import { ThemeColors } from '../common/Theme';
import { PageTheme } from '../common/PageTheme';
import { L } from '../helper/LocalizationHelper';

/**
 * Shared bottom navigation bar with a heavy frosted-glass effect,
 * closely matching the iOS-style floating pill bar.
 *
 * Glass construction (layered):
 *   1. Ultra-thick background blur — content behind is strongly
 *      softened but its colours still bleed through.
 *   2. Very low-opacity fill — the blur is the star, not the fill.
 *   3. Outer bright white border (1.5 px).
 *   4. Inner highlight ring (1 px, softer white) inset by 1.5 px.
 *      Creates the "double edge" that real glass catches light on.
 *   5. Soft drop shadow for lift off the page.
 */
@Component
export struct FloatingNavBar {

  @Prop activeTab: string = 'home';
  @Prop colors: ThemeColors;
  @Prop currentLanguage: string = 'en';
  onTabTap: (tabId: string) => void = (id: string) => {
  };

  // ============================================================
  // THEME HELPERS
  // ============================================================

  private isDark(): boolean {
    return PageTheme.isSystemDark();
  }

  /** Outer 1.5 px border colour — the sharp glass edge. */
  private outerBorder(): string {
    return this.isDark()
      ? 'rgba(255, 255, 255, 0.30)'
      : 'rgba(255, 255, 255, 0.92)';
  }

  /** Inner 1 px border colour — the softer highlight ring. */
  private innerBorder(): string {
    return this.isDark()
      ? 'rgba(255, 255, 255, 0.12)'
      : 'rgba(255, 255, 255, 0.50)';
  }

  /** Fill colour behind the blur. */
  private fillColor(): string {
    return this.isDark()
      ? 'rgba(20, 27, 46, 0.24)'
      : 'rgba(255, 255, 255, 0.20)';
  }

  private inactiveColor(): string {
    return this.isDark() ? 'rgba(241,245,249,0.78)' : 'rgba(26,26,26,0.70)';
  }

  private activeColor(): string {
    return this.isDark() ? '#4ADE80' : '#0F5132';
  }

  private dividerColor(): string {
    return this.isDark()
      ? 'rgba(255,255,255,0.10)'
      : 'rgba(0,0,0,0.08)';
  }

  // ============================================================
  // BUILD
  // ============================================================

  build() {
    Row() {
      Stack() {
        // ---- Inner highlight ring (inset by 1.5 px) ----
        Row()
          .width('100%')
          .height('100%')
          .borderRadius(32.5)
          .border({ width: 1, color: this.innerBorder() })
          .margin(1.5)

        // ---- Navigation items ----
        Row() {
          this.NavItem('home', '🏠', L.get('tab_home', this.currentLanguage))
          Divider().vertical(true).height(24).color(this.dividerColor())
          this.NavItem('prayers', '🕌', L.get('tab_prayers', this.currentLanguage))
          Divider().vertical(true).height(24).color(this.dividerColor())
          this.NavItem('calendar', '📅', L.get('tab_calendar', this.currentLanguage))
          Divider().vertical(true).height(24).color(this.dividerColor())
          this.NavItem('compass', '🧭', L.get('tab_compass', this.currentLanguage))
          Divider().vertical(true).height(24).color(this.dividerColor())
          this.NavItem('tasbih', '📿', L.get('tab_tasbih', this.currentLanguage))
        }
        .width('100%').height('100%')
      }
      .width('92%')
      .height(68)
      // ---- 1. Ultra-heavy blur ----
      .backgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THICK, {
        colorMode: this.isDark() ? ThemeColorMode.DARK : ThemeColorMode.LIGHT,
        adaptiveColor: AdaptiveColor.AVERAGE,
        scale: 1.8
      })
      // ---- 2. Near-invisible fill ----
      .backgroundColor(this.fillColor())
      .borderRadius(34)
      // ---- 3. Bright outer border ----
      .border({ width: 1.5, color: this.outerBorder() })
      // ---- 4. Soft drop shadow ----
      .shadow({
        radius: 32,
        color: this.isDark()
          ? 'rgba(0, 0, 0, 0.55)'
          : 'rgba(0, 0, 0, 0.14)',
        offsetX: 0,
        offsetY: 12
      })
    }
    .width('100%').justifyContent(FlexAlign.Center)
    .position({ bottom: 24 })
  }

  // ============================================================
  // NAV ITEM
  // ============================================================

  @Builder
  NavItem(id: string, icon: string, label: string) {
    Column() {
      Text(icon)
        .fontSize(20)
        .opacity(this.activeTab === id ? 1.0 : 0.78)

      Text(label)
        .fontSize(9)
        .fontWeight(this.activeTab === id ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.activeTab === id ? this.activeColor() : this.inactiveColor())
        .margin({ top: 2 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1).height('100%').justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.onTabTap(id);
    })
  }
}