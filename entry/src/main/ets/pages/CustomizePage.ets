// entry/src/main/ets/pages/CustomizePage.ets

import { router } from '@kit.ArkUI';
import { mediaquery } from '@kit.ArkUI';
import { Theme, ThemeColors, ThemeMode } from '../common/Theme';
import { SettingsHelper } from '../utils/SettingsHelper';
import { PickerItem } from '../models/SettingsModels';
import { STORAGE_KEY_THEME_MODE } from '../common/StorageKeys';

@Entry
@Component
struct CustomizePage {

  // ============================================================
  // THEME
  // ============================================================

  @StorageLink(STORAGE_KEY_THEME_MODE)
  @Watch('onThemeModeChanged')
  themeMode: string = ThemeMode.SYSTEM;

  @State colors: ThemeColors = Theme.getColors(ThemeMode.LIGHT, false);

  private systemDarkListener: mediaquery.MediaQueryListener | null = null;

  // ============================================================
  // UI CUSTOMIZATION STATE
  // ============================================================

  @State showExtraTimings: boolean = true;
  @State showIslamicEvents: boolean = true;

  // ============================================================
  // UI STATE
  // ============================================================

  @State expandedCategory: string | null = 'UI Customization';
  @State showThemePicker: boolean = false;

  // ============================================================
  // THEME HELPERS
  // ============================================================

  private isSystemDark(): boolean {
    try {
      const listener = mediaquery.matchMediaSync('(dark-mode: true)');
      return listener.matches;
    } catch (err) {
      return false;
    }
  }

  private applyTheme(): void {
    this.colors = Theme.getColors(this.themeMode, this.isSystemDark());
  }

  private onThemeModeChanged(): void {
    this.colors = Theme.getColors(this.themeMode, this.isSystemDark());
  }

  private pickThemeMode(id: string): void {
    this.themeMode = id;
    SettingsHelper.saveThemeMode(id);
    this.colors = Theme.getColors(id, this.isSystemDark());
    this.showThemePicker = false;
  }

  // ============================================================
  // LIFECYCLE
  // ============================================================

  aboutToAppear(): void {
    this.applyTheme();

    // React to system dark-mode changes (for System mode)
    try {
      this.systemDarkListener = mediaquery.matchMediaSync('(dark-mode: true)');
      this.systemDarkListener.on('change', (result: mediaquery.MediaQueryResult) => {
        if (this.themeMode === ThemeMode.SYSTEM) {
          this.colors = Theme.getColors(this.themeMode, result.matches);
        }
      });
    } catch (err) { /* ignore */ }

    this.reload();
  }

  aboutToDisappear(): void {
    if (this.systemDarkListener) {
      this.systemDarkListener.off('change');
      this.systemDarkListener = null;
    }
  }

  onPageShow(): void {
    this.applyTheme();
    this.reload();
  }

  private async reload(): Promise<void> {
    const data = await SettingsHelper.loadAll();
    this.showExtraTimings  = data.showExtraTimings;
    this.showIslamicEvents = data.showIslamicEvents;
  }

  // ============================================================
  // EVENT HANDLERS
  // ============================================================

  private toggleShowExtraTimings(value: boolean): void {
    this.showExtraTimings = value;
    SettingsHelper.saveShowExtraTimings(value);
  }

  private toggleShowIslamicEvents(value: boolean): void {
    this.showIslamicEvents = value;
    SettingsHelper.saveShowIslamicEvents(value);
  }

  // ============================================================
  // BUILD
  // ============================================================

  build() {
    Stack() {
      Column() {
        this.TopBar()

        Scroll() {
          Column() {
            // ---- UI Customization ----
            this.CategoryHeader(
              'UI Customization',
              '🎛️',
              this.colors.categoryUICustomization,
              'UI Customization'
            )
            if (this.expandedCategory === 'UI Customization') {
              this.UICustomizationContent()
            }

            // ---- Appearance (Dark Mode) ----
            this.CategoryHeader(
              'Appearance',
              '🎨',
              this.colors.categoryAppearance,
              'Appearance'
            )
            if (this.expandedCategory === 'Appearance') {
              this.AppearanceContent()
            }

            Column().height(40)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 20 })
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

      // ---- Theme picker overlay ----
      if (this.showThemePicker) {
        this.PickerOverlay(
          'Dark Mode',
          '🎨',
          SettingsHelper.buildThemePickerItems(this.themeMode),
          (id: string) => { this.pickThemeMode(id); },
          () => { this.showThemePicker = false; }
        )
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.primaryGreen)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  // ============================================================
  // @BUILDER METHODS
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

      Text('Customize')
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
  CategoryHeader(title: string, icon: string, iconColor: string, categoryKey: string) {
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
    .padding({ top: 12, bottom: 12, left: 12, right: 16 })
    .backgroundColor(this.colors.cardDark)
    .borderRadius(16)
    .border({ width: 1, color: this.colors.borderSoft })
    .margin({ bottom: 8 })
    .onClick(() => {
      this.expandedCategory = this.expandedCategory === categoryKey ? null : categoryKey;
    })
  }

  @Builder
  UICustomizationContent() {
    Column() {
      // Show Extra Timings
      Row() {
        Column() {
          Text('Show Extra Timings')
            .fontSize(15)
            .fontColor(this.colors.textWhite)
            .fontWeight(FontWeight.Medium)
          Text('Imsak, Sunrise, Sunset and night times')
            .fontSize(11)
            .fontColor(this.colors.textMuted)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Toggle({ type: ToggleType.Switch, isOn: this.showExtraTimings })
          .selectedColor(this.colors.accentGold)
          .onChange((isOn: boolean) => { this.toggleShowExtraTimings(isOn); })
      }
      .width('100%')
      .padding({ top: 14, bottom: 14, left: 16, right: 16 })
      .backgroundColor(this.colors.tintSubtle)
      .borderRadius(12)
      .margin({ bottom: 8 })

      // Show Islamic Events
      Row() {
        Column() {
          Text('Show Islamic Events')
            .fontSize(15)
            .fontColor(this.colors.textWhite)
            .fontWeight(FontWeight.Medium)
          Text('Upcoming Islamic events on home screen')
            .fontSize(11)
            .fontColor(this.colors.textMuted)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Toggle({ type: ToggleType.Switch, isOn: this.showIslamicEvents })
          .selectedColor(this.colors.accentGold)
          .onChange((isOn: boolean) => { this.toggleShowIslamicEvents(isOn); })
      }
      .width('100%')
      .padding({ top: 14, bottom: 14, left: 16, right: 16 })
      .backgroundColor(this.colors.tintSubtle)
      .borderRadius(12)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(16)
    .border({ width: 1, color: this.colors.borderSoft })
    .margin({ bottom: 12 })
  }

  @Builder
  AppearanceContent() {
    Column() {
      Row() {
        Column() {
          Text('Dark Mode')
            .fontSize(15)
            .fontColor(this.colors.textWhite)
            .fontWeight(FontWeight.Medium)
          Text('Choose how the app looks')
            .fontSize(11)
            .fontColor(this.colors.textMuted)
            .margin({ top: 2 })
          Text(SettingsHelper.getThemeModeLabel(this.themeMode))
            .fontSize(12)
            .fontColor(this.colors.accentGold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text('›')
          .fontSize(22)
          .fontColor(this.colors.accentGold)
          .opacity(0.7)
      }
      .width('100%')
      .padding({ top: 14, bottom: 14, left: 16, right: 16 })
      .backgroundColor(this.colors.tintSubtle)
      .borderRadius(12)
      .onClick(() => { this.showThemePicker = true; })
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(16)
    .border({ width: 1, color: this.colors.borderSoft })
    .margin({ bottom: 12 })
  }

  @Builder
  PickerOverlay(
    title: string,
    icon: string,
    items: PickerItem[],
    onSelect: (id: string) => void,
    onCancel: () => void
  ) {
    // Dimmer
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor(this.colors.overlayDim)
      .onClick(() => { onCancel(); })

    // Bottom sheet
    Column() {
      Row()
        .width(44).height(4)
        .backgroundColor(this.colors.overlayDimSoft)
        .borderRadius(2)
        .margin({ top: 10 })

      Row() {
        Text(icon)
          .fontSize(22)
          .width(44).height(44)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.colors.tintSoft)
          .borderRadius(12)
          .border({ width: 1, color: this.colors.borderSoft })

        Text(title)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textWhite)
          .margin({ left: 14 })
      }
      .width('100%')
      .padding({ left: 20, top: 20, bottom: 20 })

      Divider()
        .color(this.colors.borderSoft)
        .width('90%')

      Column() {
        ForEach(items, (item: PickerItem) => {
          Row() {
            Row() {
              if (item.selected) {
                Row()
                  .width(10).height(10)
                  .borderRadius(5)
                  .backgroundColor(this.colors.accentGold)
              }
            }
            .width(22).height(22)
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
          .padding({ top: 16, bottom: 16, left: 20, right: 20 })
          .backgroundColor(item.selected ? this.colors.tintSoft : 'transparent')
          .borderRadius(12)
          .margin({ bottom: 4 })
          .onClick(() => { onSelect(item.id); })
        }, (item: PickerItem) => item.id)
      }
      .width('100%')
      .padding({ left: 8, right: 8, top: 12, bottom: 12 })

      Button('Cancel')
        .width('90%')
        .height(48)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textWhite)
        .backgroundColor(this.colors.tintSoft)
        .borderRadius(12)
        .margin({ top: 8, bottom: 24 })
        .onClick(() => { onCancel(); })
    }
    .width('100%')
    .backgroundColor(this.colors.cardDark)
    .borderRadius({ topLeft: 28, topRight: 28 })
    .shadow({ radius: 24, color: this.colors.shadowFloating, offsetX: 0, offsetY: -6 })
    .border({ width: { top: 1 }, color: this.colors.borderSoft })
    .position({ bottom: 0 })
  }
}