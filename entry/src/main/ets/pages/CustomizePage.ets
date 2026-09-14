// entry/src/main/ets/pages/CustomizePage.ets

import { router } from '@kit.ArkUI';
import { mediaquery } from '@kit.ArkUI';
import { Theme, ThemeColors, ThemeMode } from '../common/Theme';
import { PageTheme } from '../common/PageTheme';
import { SettingsHelper } from '../helper/SettingsHelper';
import { PickerItem } from '../models/SettingsModels';
import {
  STORAGE_KEY_THEME_MODE,
  STORAGE_KEY_LANGUAGE
} from '../common/StorageKeys';
import { L, AppLanguage } from '../helper/LocalizationHelper';

@Entry
@Component
struct CustomizePage {

  @StorageLink(STORAGE_KEY_THEME_MODE)
  @Watch('onThemeModeChanged')
  themeMode: string = ThemeMode.SYSTEM;

  @StorageLink(STORAGE_KEY_LANGUAGE)
  @Watch('onLanguageChanged')
  appLanguage: string = AppLanguage.ENGLISH;

  @State private currentLanguage: string = AppLanguage.ENGLISH;

  @State colors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);
  private systemDarkListener: mediaquery.MediaQueryListener | null = null;

  @State showExtraTimings: boolean = true;
  @State showIslamicEvents: boolean = true;

  @State expandedCategory: string | null = 'UI Customization';
  @State showThemePicker: boolean = false;
  @State showLanguagePicker: boolean = false;

  // ============================================================
  // LOCALIZATION + DIRECTION
  // ============================================================

  private tr(key: string): string {
    return L.get(key, this.currentLanguage);
  }

  private themeModeLabel(): string {
    switch (this.themeMode) {
      case ThemeMode.LIGHT:  return this.tr('theme_light');
      case ThemeMode.DARK:   return this.tr('theme_dark');
      case ThemeMode.SYSTEM: return this.tr('theme_system');
      default:               return this.tr('theme_system');
    }
  }

  private isRtl(): boolean {
    return L.isRtlLang(this.currentLanguage);
  }

  // ============================================================
  // WATCHERS
  // ============================================================

  private onThemeModeChanged(): void {
    this.colors = PageTheme.compute(this.themeMode);
  }

  private onLanguageChanged(): void {
    this.currentLanguage = this.appLanguage;
  }

  // ============================================================
  // THEME
  // ============================================================

  private applyTheme(): void {
    this.colors = PageTheme.compute(this.themeMode);
  }

  // ============================================================
  // PICK HANDLERS
  // ============================================================

  private pickThemeMode(id: string): void {
    this.themeMode = id;
    SettingsHelper.saveThemeMode(id);
    this.colors = PageTheme.compute(id);
    this.showThemePicker = false;
  }

  private pickLanguage(id: string): void {
    this.appLanguage = id;
    SettingsHelper.saveLanguage(id);
    this.showLanguagePicker = false;
  }

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

  private async reload(): Promise<void> {
    const data = await SettingsHelper.loadAll();
    this.showExtraTimings  = data.showExtraTimings;
    this.showIslamicEvents = data.showIslamicEvents;
  }

  private toggleShowExtraTimings(value: boolean): void {
    this.showExtraTimings = value;
    SettingsHelper.saveShowExtraTimings(value);
  }

  private toggleShowIslamicEvents(value: boolean): void {
    this.showIslamicEvents = value;
    SettingsHelper.saveShowIslamicEvents(value);
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
    const modes = [ThemeMode.LIGHT, ThemeMode.DARK, ThemeMode.SYSTEM];
    return modes.map((m): PickerItem => {
      const item: PickerItem = {
        id: m,
        label: m === ThemeMode.LIGHT ? this.tr('theme_light')
          : m === ThemeMode.DARK  ? this.tr('theme_dark')
            :                         this.tr('theme_system'),
        selected: m === this.themeMode
      };
      return item;
    });
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
            // ---- UI Customization header ----
            Row() {
              Text('🎛️')
                .fontSize(18).width(40).height(40).textAlign(TextAlign.Center)
                .backgroundColor(this.colors.tintSoft).borderRadius(12)
                .border({ width: 1, color: this.colors.borderSoft })

              Text(this.tr('category_ui_customization'))
                .fontSize(17).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
                .margin({ left: 14 }).layoutWeight(1)

              Text(this.expandedCategory === 'UI Customization' ? '▲' : '▼')
                .fontSize(12).fontColor(this.colors.accentGold).opacity(0.8)
            }
            .width('100%').padding({ top: 12, bottom: 12, left: 12, right: 16 })
            .backgroundColor(this.colors.cardDark).borderRadius(16)
            .border({ width: 1, color: this.colors.borderSoft })
            .margin({ bottom: 8 })
            .onClick(() => {
              this.expandedCategory = this.expandedCategory === 'UI Customization' ? null : 'UI Customization';
            })

            if (this.expandedCategory === 'UI Customization') {
              this.UICustomizationContent()
            }

            // ---- Appearance header ----
            Row() {
              Text('🎨')
                .fontSize(18).width(40).height(40).textAlign(TextAlign.Center)
                .backgroundColor(this.colors.tintSoft).borderRadius(12)
                .border({ width: 1, color: this.colors.borderSoft })

              Text(this.tr('category_appearance'))
                .fontSize(17).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
                .margin({ left: 14 }).layoutWeight(1)

              Text(this.expandedCategory === 'Appearance' ? '▲' : '▼')
                .fontSize(12).fontColor(this.colors.accentGold).opacity(0.8)
            }
            .width('100%').padding({ top: 12, bottom: 12, left: 12, right: 16 })
            .backgroundColor(this.colors.cardDark).borderRadius(16)
            .border({ width: 1, color: this.colors.borderSoft })
            .margin({ bottom: 8 })
            .onClick(() => {
              this.expandedCategory = this.expandedCategory === 'Appearance' ? null : 'Appearance';
            })

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
      .width('100%').height('100%').backgroundColor(this.colors.primaryGreen)

      if (this.showThemePicker) {
        this.PickerOverlay(
          this.tr('dark_mode'),
          '🎨',
          this.buildThemeItems(),
          (id: string) => { this.pickThemeMode(id); },
          () => { this.showThemePicker = false; }
        )
      }

      if (this.showLanguagePicker) {
        this.PickerOverlay(
          this.tr('language'),
          '🌐',
          this.buildLanguageItems(),
          (id: string) => { this.pickLanguage(id); },
          () => { this.showLanguagePicker = false; }
        )
      }
    }
    .width('100%').height('100%')
    .backgroundColor(this.colors.primaryGreen)
    .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  TopBar() {
    Row() {
      Text('←')
        .fontSize(26).fontColor(this.colors.textWhite)
        .width(40).height(40).textAlign(TextAlign.Center)
        .borderRadius(20).backgroundColor(this.colors.tintSoft)
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
      Row() {
        Column() {
          Text(this.tr('show_extra_timings'))
            .fontSize(15).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
          Text(this.tr('show_extra_timings_desc'))
            .fontSize(11).fontColor(this.colors.textMuted).margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        Toggle({ type: ToggleType.Switch, isOn: this.showExtraTimings })
          .selectedColor(this.colors.accentGold)
          .onChange((isOn: boolean) => { this.toggleShowExtraTimings(isOn); })
      }
      .width('100%')
      .padding({ top: 14, bottom: 14, left: 16, right: 16 })
      .backgroundColor(this.colors.tintSubtle).borderRadius(12).margin({ bottom: 8 })

      Row() {
        Column() {
          Text(this.tr('show_islamic_events'))
            .fontSize(15).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
          Text(this.tr('show_islamic_events_desc'))
            .fontSize(11).fontColor(this.colors.textMuted).margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        Toggle({ type: ToggleType.Switch, isOn: this.showIslamicEvents })
          .selectedColor(this.colors.accentGold)
          .onChange((isOn: boolean) => { this.toggleShowIslamicEvents(isOn); })
      }
      .width('100%')
      .padding({ top: 14, bottom: 14, left: 16, right: 16 })
      .backgroundColor(this.colors.tintSubtle).borderRadius(12).margin({ bottom: 8 })

      Row() {
        Column() {
          Text(this.tr('language'))
            .fontSize(15).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
          Text(this.tr('language_desc'))
            .fontSize(11).fontColor(this.colors.textMuted).margin({ top: 2 })
          Text(this.currentLanguageLabel())
            .fontSize(12).fontColor(this.colors.accentGold)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        Text('›').fontSize(22).fontColor(this.colors.accentGold).opacity(0.7)
      }
      .width('100%')
      .padding({ top: 14, bottom: 14, left: 16, right: 16 })
      .backgroundColor(this.colors.tintSubtle).borderRadius(12).margin({ bottom: 8 })
      .onClick(() => { this.showLanguagePicker = true; })

      Row() {
        Text('🌐').fontSize(14).margin({ right: 8 }).opacity(0.7)
        Text(this.tr('more_languages_coming'))
          .fontSize(11).fontColor(this.colors.textMuted).fontStyle(FontStyle.Italic)
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ top: 8, bottom: 8, left: 16, right: 16 })
      .margin({ bottom: 0 })
    }
    .width('100%').padding(12)
    .backgroundColor(this.colors.cardDark).borderRadius(16)
    .border({ width: 1, color: this.colors.borderSoft })
    .margin({ bottom: 12 })
  }

  @Builder
  AppearanceContent() {
    Column() {
      Row() {
        Column() {
          Text(this.tr('dark_mode'))
            .fontSize(15).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
          Text(this.tr('dark_mode_desc'))
            .fontSize(11).fontColor(this.colors.textMuted).margin({ top: 2 })
          Text(this.themeModeLabel())
            .fontSize(12).fontColor(this.colors.accentGold)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        Text('›').fontSize(22).fontColor(this.colors.accentGold).opacity(0.7)
      }
      .width('100%')
      .padding({ top: 14, bottom: 14, left: 16, right: 16 })
      .backgroundColor(this.colors.tintSubtle).borderRadius(12)
      .onClick(() => { this.showThemePicker = true; })
    }
    .width('100%').padding(12)
    .backgroundColor(this.colors.cardDark).borderRadius(16)
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
    Column()
      .width('100%').height('100%')
      .backgroundColor(this.colors.overlayDim)
      .onClick(() => { onCancel(); })

    Column() {
      Row().width(44).height(4)
        .backgroundColor(this.colors.overlayDimSoft)
        .borderRadius(2)
        .margin({ top: 10 })

      Row() {
        Text(icon)
          .fontSize(22).width(44).height(44).textAlign(TextAlign.Center)
          .backgroundColor(this.colors.tintSoft).borderRadius(12)
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
                Row().width(10).height(10).borderRadius(5)
                  .backgroundColor(this.colors.accentGold)
              }
            }
            .width(22).height(22).borderRadius(11)
            .border({
              width: item.selected ? 2 : 1.5,
              color: item.selected ? this.colors.accentGold : this.colors.borderStrong
            })
            .justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)

            Text(item.label)
              .fontSize(15)
              .fontColor(item.selected ? this.colors.accentGold : this.colors.textWhite)
              .fontWeight(item.selected ? FontWeight.Bold : FontWeight.Normal)
              .layoutWeight(1).maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ left: 14 })
          }
          .width('100%')
          .padding({ top: 16, bottom: 16, left: 20, right: 20 })
          .backgroundColor(item.selected ? this.colors.tintSoft : 'transparent')
          .borderRadius(12).margin({ bottom: 4 })
          .onClick(() => { onSelect(item.id); })
        }, (item: PickerItem) => item.id)
      }
      .width('100%').padding({ left: 8, right: 8, top: 12, bottom: 12 })

      Button(this.tr('cancel'))
        .width('90%').height(48).fontSize(15).fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textWhite).backgroundColor(this.colors.tintSoft)
        .borderRadius(12).margin({ top: 8, bottom: 24 })
        .onClick(() => { onCancel(); })
    }
    .width('100%').backgroundColor(this.colors.cardDark)
    .borderRadius({ topLeft: 28, topRight: 28 })
    .shadow({ radius: 24, color: this.colors.shadowFloating, offsetX: 0, offsetY: -6 })
    .border({ width: { top: 1 }, color: this.colors.borderSoft })
    .position({ bottom: 0 })
  }
}