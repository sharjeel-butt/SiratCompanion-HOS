// entry/src/main/ets/pages/AdvancedCalcPage.ets

import { mediaquery, router } from '@kit.ArkUI';
import { ThemeColors, ThemeMode, ThemePreset } from '../common/Theme';
import { PageTheme } from '../common/PageTheme';
import {
  STORAGE_KEY_APP_THEME,
  STORAGE_KEY_BREAKPOINT,
  STORAGE_KEY_LANGUAGE,
  STORAGE_KEY_THEME_MODE
} from '../common/StorageKeys';
import { SettingsHelper } from '../helper/SettingsHelper';
import { PickerItem } from '../models/SettingsModels';
import {
  CustomAngles,
  MidnightMethod,
  PolarResolution,
  RoundingMethod,
  Shafaq
} from '../models/AdvancedCalcModels';
import {
  CalculationMethod, HighLatitudeRule
} from '../utils/PrayerTimeCalculator';
import { L } from '../helper/LocalizationHelper';
import { Breakpoints } from '../common/Breakpoints';

type SheetKind = 'none' | 'rounding' | 'midnight' | 'polar'
  | 'shafaq' | 'highlat';

@Entry
@Component
struct AdvancedCalcPage {
  @StorageLink(STORAGE_KEY_THEME_MODE)
  @Watch('onThemeModeChanged')
  themeMode: string = ThemeMode.SYSTEM;

  @StorageLink(STORAGE_KEY_LANGUAGE)
  @Watch('onLanguageChanged')
  appLanguage: string = 'en';

  @StorageLink(STORAGE_KEY_APP_THEME)
  @Watch('onAppThemePresetChanged')
  appThemePreset: string = ThemePreset.SIRAT;

  @StorageLink(STORAGE_KEY_BREAKPOINT)
  breakpoint: string = 'sm';

  @State colors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);
  @State currentLanguage: string = 'en';

  @State roundingMethod: RoundingMethod = RoundingMethod.NEAREST;
  @State midnightMethod: MidnightMethod = MidnightMethod.STANDARD;
  @State polarResolution: PolarResolution = PolarResolution.UNRESOLVED;
  @State shafaqValue: Shafaq = Shafaq.GENERAL;
  @State highLatRule: HighLatitudeRule = HighLatitudeRule.NONE;
  /**
   * Read-only mirror of the current calculation method. Controls
   * whether the Custom Angles block shows. The method picker itself
   * lives in Settings → Prayer Times.
   */
  @State calcMethod: CalculationMethod = CalculationMethod.KARACHI;

  @State activeSheet: SheetKind = 'none';

  @State customFajrInput: string = '18';
  @State customIshaInput: string = '18';
  @State customIntervalInput: string = '0';

  private systemDarkListener: mediaquery.MediaQueryListener | null = null;

  aboutToAppear(): void {
    this.currentLanguage = this.appLanguage;
    this.colors = PageTheme.compute(this.themeMode);
    this.systemDarkListener = PageTheme.installSystemListener(
      this.themeMode, (c) => {
      this.colors = c;
    }
    );
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

  build() {
    Stack() {
      Column() {
        this.TopBar()

        Scroll() {
          Row() {
            Column() {
              Column() {
                this.RoundingRow()
                this.MidnightRow()
                this.HighLatRow()
                this.PolarRow()
                this.ShafaqRow()

                if (this.calcMethod === CalculationMethod.CUSTOM) {
                  Divider().color(this.colors.borderSoft)
                    .margin({ top: 4, bottom: 8 })
                  this.CustomAnglesBlock()
                }
              }
              .width('100%')
              .padding(12)
              .backgroundColor(this.colors.cardDark)
              .borderRadius(16)
              .border({ width: 1, color: this.colors.borderSoft })
              .margin({ bottom: 12 })

              Column().height(40)
            }
            .width('100%')
            .constraintSize({ maxWidth: this.isTablet() ? 720 : 100000 })
            .padding({ left: 16, right: 16, top: 20 })
          }
          .width('100%').justifyContent(FlexAlign.Center)
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor(this.colors.primaryGreen)
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%').height('100%')
      .backgroundColor(this.colors.primaryGreen)

      if (this.activeSheet !== 'none') {
        this.PickerOverlay(
          this.sheetTitle(),
          this.sheetIcon(),
          this.sheetItems(),
          (id: string) => {
            this.pickItem(id);
          },
          () => {
            this.activeSheet = 'none';
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

      Text(this.tr('advanced_calc_title'))
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.colors.textWhite)
        .margin({ left: 16 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
    }
    .width('100%').height(72).backgroundColor(this.colors.cardDark)
    .alignItems(VerticalAlign.Center)
  }

  // ============================================================
  // ROWS — each is its own parameterless @Builder so ArkUI
  // correctly re-renders the label whenever the backing @State
  // changes. Passing computed values into a @Builder with
  // parameters causes the value to be snapshotted once.
  // ============================================================

  @Builder
  RoundingRow() {
    Row() {
      Column() {
        Text(this.tr('rounding_method'))
          .fontSize(15).fontColor(this.colors.textWhite)
          .fontWeight(FontWeight.Medium)
        Text(this.tr('rounding_method_desc'))
          .fontSize(11).fontColor(this.colors.textMuted)
          .margin({ top: 2 })
        Text(this.roundingLabel())
          .fontSize(12).fontColor(this.colors.accentGold)
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
    .margin({ bottom: 8 })
    .onClick(() => {
      this.activeSheet = 'rounding';
    })
  }

  @Builder
  MidnightRow() {
    Row() {
      Column() {
        Text(this.tr('midnight_method'))
          .fontSize(15).fontColor(this.colors.textWhite)
          .fontWeight(FontWeight.Medium)
        Text(this.tr('midnight_method_desc'))
          .fontSize(11).fontColor(this.colors.textMuted)
          .margin({ top: 2 })
        Text(this.midnightLabel())
          .fontSize(12).fontColor(this.colors.accentGold)
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
    .margin({ bottom: 8 })
    .onClick(() => {
      this.activeSheet = 'midnight';
    })
  }

  @Builder
  HighLatRow() {
    Row() {
      Column() {
        Text(this.tr('high_latitude'))
          .fontSize(15).fontColor(this.colors.textWhite)
          .fontWeight(FontWeight.Medium)
        Text(this.tr('high_latitude_desc'))
          .fontSize(11).fontColor(this.colors.textMuted)
          .margin({ top: 2 })
        Text(SettingsHelper.getHighLatRuleLabel(this.highLatRule))
          .fontSize(12).fontColor(this.colors.accentGold)
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
    .margin({ bottom: 8 })
    .onClick(() => {
      this.activeSheet = 'highlat';
    })
  }

  @Builder
  PolarRow() {
    Row() {
      Column() {
        Text(this.tr('polar_resolution'))
          .fontSize(15).fontColor(this.colors.textWhite)
          .fontWeight(FontWeight.Medium)
        Text(this.tr('polar_resolution_desc'))
          .fontSize(11).fontColor(this.colors.textMuted)
          .margin({ top: 2 })
        Text(this.polarLabel())
          .fontSize(12).fontColor(this.colors.accentGold)
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
    .margin({ bottom: 8 })
    .onClick(() => {
      this.activeSheet = 'polar';
    })
  }

  @Builder
  ShafaqRow() {
    Row() {
      Column() {
        Text(this.tr('shafaq'))
          .fontSize(15).fontColor(this.colors.textWhite)
          .fontWeight(FontWeight.Medium)
        Text(this.tr('shafaq_desc'))
          .fontSize(11).fontColor(this.colors.textMuted)
          .margin({ top: 2 })
        Text(this.shafaqLabel())
          .fontSize(12).fontColor(this.colors.accentGold)
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
    .margin({ bottom: 8 })
    .onClick(() => {
      this.activeSheet = 'shafaq';
    })
  }

  // ============================================================
  // CUSTOM ANGLES
  // ============================================================

  @Builder
  CustomAnglesBlock() {
    Column() {
      Text(this.tr('custom_angles'))
        .fontSize(11)
        .fontColor(this.colors.accentGold)
        .fontWeight(FontWeight.Bold)
        .letterSpacing(1)
        .width('100%')
        .padding({ bottom: 10 })

      Column() {
        Text(this.tr('custom_fajr_angle')).fontSize(11)
          .fontColor(this.colors.textMuted)
          .width('100%').margin({ bottom: 4 })
        TextInput({ text: this.customFajrInput, placeholder: '18' })
          .type(InputType.Normal)
          .inputFilter('[0-9\\.]')
          .direction(Direction.Ltr)
          .onChange((v: string) => {
            this.customFajrInput = v;
            this.persistCustomAngles();
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
        Text(this.tr('custom_isha_angle')).fontSize(11)
          .fontColor(this.colors.textMuted)
          .width('100%').margin({ bottom: 4 })
        TextInput({ text: this.customIshaInput, placeholder: '18' })
          .type(InputType.Normal)
          .inputFilter('[0-9\\.]')
          .direction(Direction.Ltr)
          .onChange((v: string) => {
            this.customIshaInput = v;
            this.persistCustomAngles();
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
        Text(this.tr('custom_isha_interval')).fontSize(11)
          .fontColor(this.colors.textMuted)
          .width('100%').margin({ bottom: 4 })
        TextInput({ text: this.customIntervalInput, placeholder: '0' })
          .type(InputType.Normal)
          .inputFilter('[0-9]')
          .direction(Direction.Ltr)
          .onChange((v: string) => {
            this.customIntervalInput = v;
            this.persistCustomAngles();
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
      .width('100%').margin({ bottom: 8 })

      Text(this.tr('custom_isha_interval_hint'))
        .fontSize(10)
        .fontColor(this.colors.textMuted)
        .fontStyle(FontStyle.Italic)
        .width('100%')
        .margin({ top: 2 })
    }
    .width('100%')
    .padding(14)
    .backgroundColor(this.colors.tintSubtle)
    .borderRadius(12)
    .border({ width: 1, color: this.colors.borderSoft })
  }

  // ============================================================
  // PICKER OVERLAY
  // ============================================================

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
          .fontSize(20).fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textWhite).margin({ left: 14 })
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
            onSelect(item.id);
          })
        }, (item: PickerItem) =>
        `adv-${this.activeSheet}-${item.id}-${item.selected ? 's' : 'u'}`)
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

  // ============================================================
  // SHEET METADATA
  // ============================================================

  private sheetTitle(): string {
    switch (this.activeSheet) {
      case 'rounding':
        return this.tr('rounding_method');
      case 'midnight':
        return this.tr('midnight_method');
      case 'polar':
        return this.tr('polar_resolution');
      case 'shafaq':
        return this.tr('shafaq');
      case 'highlat':
        return this.tr('high_latitude');
      default:
        return '';
    }
  }

  private sheetIcon(): string {
    switch (this.activeSheet) {
      case 'rounding':
        return '🔢';
      case 'midnight':
        return '🌃';
      case 'polar':
        return '❄️';
      case 'shafaq':
        return '🌆';
      case 'highlat':
        return '🧭';
      default:
        return '⚙️';
    }
  }

  private sheetItems(): PickerItem[] {
    const items: PickerItem[] = [];

    switch (this.activeSheet) {
      case 'rounding': {
        const a: PickerItem = {
          id: RoundingMethod.NEAREST,
          label: this.tr('rounding_nearest'),
          selected: this.roundingMethod === RoundingMethod.NEAREST
        };
        items.push(a);
        const b: PickerItem = {
          id: RoundingMethod.UP,
          label: this.tr('rounding_up'),
          selected: this.roundingMethod === RoundingMethod.UP
        };
        items.push(b);
        const c: PickerItem = {
          id: RoundingMethod.NONE,
          label: this.tr('rounding_none'),
          selected: this.roundingMethod === RoundingMethod.NONE
        };
        items.push(c);
        break;
      }

      case 'midnight': {
        const a: PickerItem = {
          id: MidnightMethod.STANDARD,
          label: `${this.tr('midnight_standard')} (${this.tr('midnight_standard_desc')})`,
          selected: this.midnightMethod === MidnightMethod.STANDARD
        };
        items.push(a);
        const b: PickerItem = {
          id: MidnightMethod.JAFARI,
          label: this.tr('midnight_jafari'),
          selected: this.midnightMethod === MidnightMethod.JAFARI
        };
        items.push(b);
        break;
      }

      case 'polar': {
        const a: PickerItem = {
          id: PolarResolution.UNRESOLVED,
          label: `${this.tr('polar_unresolved')} (${this.tr('polar_unresolved_desc')})`,
          selected: this.polarResolution === PolarResolution.UNRESOLVED
        };
        items.push(a);
        const b: PickerItem = {
          id: PolarResolution.AQRAB_BALAD,
          label: this.tr('polar_aqrab_balad'),
          selected: this.polarResolution === PolarResolution.AQRAB_BALAD
        };
        items.push(b);
        const c: PickerItem = {
          id: PolarResolution.AQRAB_YAUM,
          label: this.tr('polar_aqrab_yaum'),
          selected: this.polarResolution === PolarResolution.AQRAB_YAUM
        };
        items.push(c);
        break;
      }

      case 'shafaq': {
        const a: PickerItem = {
          id: Shafaq.GENERAL,
          label: `${this.tr('shafaq_general')} (${this.tr('shafaq_general_desc')})`,
          selected: this.shafaqValue === Shafaq.GENERAL
        };
        items.push(a);
        const b: PickerItem = {
          id: Shafaq.AHMER,
          label: this.tr('shafaq_ahmer'),
          selected: this.shafaqValue === Shafaq.AHMER
        };
        items.push(b);
        const c: PickerItem = {
          id: Shafaq.ABYAD,
          label: this.tr('shafaq_abyad'),
          selected: this.shafaqValue === Shafaq.ABYAD
        };
        items.push(c);
        break;
      }

      case 'highlat': {
        const opts: PickerItem[] =
          SettingsHelper.buildHighLatPickerItems(this.highLatRule);
        for (const o of opts) {
          items.push(o);
        }
        break;
      }

      default:
        break;
    }

    return items;
  }

  private pickItem(id: string): void {
    switch (this.activeSheet) {
      case 'rounding':
        this.roundingMethod = id as RoundingMethod;
        SettingsHelper.saveRounding(this.roundingMethod);
        break;
      case 'midnight':
        this.midnightMethod = id as MidnightMethod;
        SettingsHelper.saveMidnight(this.midnightMethod);
        break;
      case 'polar':
        this.polarResolution = id as PolarResolution;
        SettingsHelper.savePolarResolution(this.polarResolution);
        break;
      case 'shafaq':
        this.shafaqValue = id as Shafaq;
        SettingsHelper.saveShafaq(this.shafaqValue);
        break;
      case 'highlat':
        this.highLatRule = id as HighLatitudeRule;
        SettingsHelper.saveHighLatRule(this.highLatRule);
        break;
      default:
        break;
    }
    this.activeSheet = 'none';
  }

  // ============================================================
  // LABEL HELPERS
  // ============================================================

  private roundingLabel(): string {
    switch (this.roundingMethod) {
      case RoundingMethod.UP:
        return this.tr('rounding_up');
      case RoundingMethod.NONE:
        return this.tr('rounding_none');
      default:
        return this.tr('rounding_nearest');
    }
  }

  private midnightLabel(): string {
    return this.midnightMethod === MidnightMethod.STANDARD
      ? `${this.tr('midnight_standard')} (${this.tr('midnight_standard_desc')})`
      : this.tr('midnight_jafari');
  }

  private polarLabel(): string {
    switch (this.polarResolution) {
      case PolarResolution.AQRAB_BALAD:
        return this.tr('polar_aqrab_balad');
      case PolarResolution.AQRAB_YAUM:
        return this.tr('polar_aqrab_yaum');
      default:
        return `${this.tr('polar_unresolved')} (${this.tr('polar_unresolved_desc')})`;
    }
  }

  private shafaqLabel(): string {
    switch (this.shafaqValue) {
      case Shafaq.AHMER:
        return this.tr('shafaq_ahmer');
      case Shafaq.ABYAD:
        return this.tr('shafaq_abyad');
      default:
        return `${this.tr('shafaq_general')} (${this.tr('shafaq_general_desc')})`;
    }
  }

  // ============================================================
  // LOAD + SAVE
  // ============================================================

  private reload(): void {
    SettingsHelper.getAdvancedCalcSettings()
      .then((adv) => {
        this.roundingMethod = adv.rounding;
        this.midnightMethod = adv.midnight;
        this.polarResolution = adv.polarResolution;
        this.shafaqValue = adv.shafaq;

        this.customFajrInput = String(adv.customAngles.fajr);
        this.customIshaInput = String(adv.customAngles.isha);
        this.customIntervalInput = String(adv.customAngles.ishaInterval);
      })
      .catch((err: Error) => {
        console.error('[AdvancedCalcPage] reload advanced failed: '
          + err.message);
      });

    SettingsHelper.getHighLatRule()
      .then((rule) => {
        this.highLatRule = rule;
      })
      .catch((err: Error) => {
        console.error('[AdvancedCalcPage] reload highLat failed: '
          + err.message);
      });

    SettingsHelper.loadAll()
      .then((data) => {
        this.calcMethod = data.method;
      })
      .catch((err: Error) => {
        console.error('[AdvancedCalcPage] reload base failed: '
          + err.message);
      });
  }

  private persistCustomAngles(): void {
    const fajr = parseFloat(this.customFajrInput);
    const isha = parseFloat(this.customIshaInput);
    const interval = parseInt(this.customIntervalInput, 10);

    const angles: CustomAngles = {
      fajr: isNaN(fajr) ? 18 : fajr,
      isha: isNaN(isha) ? 18 : isha,
      ishaInterval: isNaN(interval) ? 0 : interval
    };
    SettingsHelper.saveCustomAngles(angles);
  }

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

  private onAppThemePresetChanged(): void {
    this.colors = PageTheme.compute(this.themeMode);
  }

  private onLanguageChanged(): void {
    this.currentLanguage = this.appLanguage;
  }
}