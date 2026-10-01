// entry/src/main/ets/components/FloatingNavBar.ets

import { ThemeColors } from '../common/Theme';
import { PageTheme } from '../common/PageTheme';
import { L } from '../helper/LocalizationHelper';

/**
 * Shared bottom navigation bar with a frosted-glass effect.
 *
 * Usage:
 *   FloatingNavBar({
 *     activeTab: 'home',
 *     colors: this.colors,
 *     currentLanguage: this.currentLanguage,
 *     onTabTap: (id: string) => { this.onFloatingBarTap(id); }
 *   })
 */
@Component
export struct FloatingNavBar {
  @Prop activeTab: string = 'home';
  @Prop colors: ThemeColors;
  @Prop currentLanguage: string = 'en';
  onTabTap: (tabId: string) => void = (id: string) => {
  };

  private isDark(): boolean {
    return PageTheme.isSystemDark();
  }

  private inactiveColor(): string {
    return this.isDark() ? 'rgba(241,245,249,0.70)' : 'rgba(26,26,26,0.60)';
  }

  private activeColor(): string {
    return this.isDark() ? '#4ADE80' : '#0F5132';
  }

  private dividerColor(): string {
    return this.isDark() ? 'rgba(74,222,128,0.18)' : 'rgba(15,81,50,0.10)';
  }

  build() {
    Row() {
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
      .width('92%')
      .height(68)
      // ---- Frosted-glass effect ----
      .backgroundBlurStyle(BlurStyle.Thin, {
        colorMode: this.isDark() ? ThemeColorMode.DARK : ThemeColorMode.LIGHT,
        adaptiveColor: AdaptiveColor.AVERAGE,
        scale: 1.5
      })
      .backgroundColor(
        this.isDark() ? 'rgba(20, 27, 46, 0.32)' : 'rgba(255, 255, 255, 0.22)'
      )
      .borderRadius(34)
      .border({
        width: 1,
        color: this.isDark()
          ? 'rgba(74, 222, 128, 0.28)'
          : 'rgba(255, 255, 255, 0.55)'
      })
      .shadow({
        radius: 32,
        color: this.isDark() ? 'rgba(0, 0, 0, 0.55)' : 'rgba(0, 0, 0, 0.14)',
        offsetX: 0,
        offsetY: 12
      })
    }
    .width('100%').justifyContent(FlexAlign.Center)
    .position({ bottom: 24 })
  }

  @Builder
  NavItem(id: string, icon: string, label: string) {
    Column() {
      Text(icon).fontSize(20).opacity(this.activeTab === id ? 1.0 : 0.72)
      Text(label)
        .fontSize(9)
        .fontWeight(this.activeTab === id ? FontWeight.Bold : FontWeight.Normal)
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