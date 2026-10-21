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
} from '../prayer/PrayerTimeCalculator';
import { L } from '../i8n/LocalizationHelper';
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
            .constraintSize({ maxWidth: Breakpoints.maxContentWidth(this.breakpoint) })
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

  private isMidnightLocked(): boolean {
    return this.calcMethod === CalculationMethod.JAFARI ||
      this.calcMethod === CalculationMethod.TEHRAN;
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  @Builder
  TopBar() {
    Row() {
      Image($r('app.media.ic_arrow_left')) // <--- SVG
        .width(20)
        .height(20)
        .fillColor(this.colors.textWhite)
        .width(40)
        .height(40)
        .padding(10)
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
  // ROWS
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

      Image($r('app.media.ic_chevron_right')) // <--- SVG
        .width(20).height(20)
        .fillColor(this.colors.accentGold).opacity(0.7)
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
          .fontSize(15)
          .fontColor(this.isMidnightLocked() ? this.colors.textMuted : this.colors.textWhite)
          .fontWeight(FontWeight.Medium)
        Text(this.tr('midnight_method_desc'))
          .fontSize(11).fontColor(this.colors.textMuted)
          .margin({ top: 2 })
        Text(this.isMidnightLocked() ? this.tr('midnight_jafari') : this.midnightLabel())
          .fontSize(12).fontColor(this.colors.accentGold)
          .margin({ top: 6 })
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)

      Image($r('app.media.ic_chevron_right')) // <--- SVG
        .width(20).height(20)
        .fillColor(this.isMidnightLocked() ? this.colors.textMuted : this.colors.accentGold)
        .opacity(this.isMidnightLocked() ? 0.3 : 0.7)
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
    .opacity(this.isMidnightLocked() ? 0.55 : 1.0)
    .onClick(() => {
      if (!this.isMidnightLocked()) {
        this.activeSheet = 'midnight';
      }
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

      Image($r('app.media.ic_chevron_right')) // <--- SVG
        .width(20).height(20)
        .fillColor(this.colors.accentGold).opacity(0.7)
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

      Image($r('app.media.ic_chevron_right')) // <--- SVG
        .width(20).height(20)
        .fillColor(this.colors.accentGold).opacity(0.7)
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
          .fontSize(15)
          .fontColor(this.isShafaqApplicable()
            ? this.colors.textWhite
            : this.colors.textMuted)
          .fontWeight(FontWeight.Medium)

        Text(this.tr('shafaq_desc'))
          .fontSize(11)
          .fontColor(this.colors.textMuted)
          .margin({ top: 2 })

        Text(this.shafaqLabel())
          .fontSize(12)
          .fontColor(this.isShafaqApplicable()
            ? this.colors.accentGold
            : this.colors.textMuted)
          .margin({ top: 6 })

        if (!this.isShafaqApplicable()) {
          Text(this.tr('shafaq_method_unavailable'))
            .fontSize(10)
            .fontColor(this.colors.textMuted)
            .fontStyle(FontStyle.Italic)
            .margin({ top: 4 })
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Image($r('app.media.ic_chevron_right')) // <--- SVG
        .width(20).height(20)
        .fillColor(this.isShafaqApplicable()
          ? this.colors.accentGold
          : this.colors.textMuted)
        .opacity(this.isShafaqApplicable() ? 0.7 : 0.3)
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
    .opacity(this.isShafaqApplicable() ? 1.0 : 0.55)
    .onClick(() => {
      if (this.isShafaqApplicable()) {
        this.activeSheet = 'shafaq';
      }
    })
  }

  // ============================================================
  // PICKER OVERLAY
  // ============================================================

  @Builder
  PickerOverlay(
    title: string,
    icon: Resource, // <--- Changed to Resource
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
        Image(icon) // <--- Now uses Image
          .width(22)
          .height(22)
          .fillColor(this.colors.accentGold)
          .width(44)
          .height(44)
          .padding(11)
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

  private sheetIcon(): Resource { // <--- Changed to Resource
    switch (this.activeSheet) {
      case 'rounding':
        return $r('app.media.ic_numeric');
      case 'midnight':
        return $r('app.media.ic_night');
      case 'polar':
        return $r('app.media.ic_snowflake');
      case 'shafaq':
        return $r('app.media.ic_sunset');
      case 'highlat':
        return $r('app.media.ic_compass');
      default:
        return $r('app.media.ic_settings');
    }
  }

  private sheetItems(): PickerItem[] {
    // ... unchanged ...
    const items: PickerItem[] = [];

    switch (this.activeSheet) {
      case 'rounding': {
        const a: PickerItem = {
          id: RoundingMethod.NEAREST,
          label: this.tr('rounding_nearest'),
          selected: this.roundingMethod === RoundingMethod.NEAREST
        };
        items.push(a);
        const b: PickerItem =
          { id: RoundingMethod.UP, label: this.tr('rounding_up'), selected: this.roundingMethod === RoundingMethod.UP };
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
        const b: PickerItem =
          { id: Shafaq.AHMER, label: this.tr('shafaq_ahmer'), selected: this.shafaqValue === Shafaq.AHMER };
        items.push(b);
        const c: PickerItem =
          { id: Shafaq.ABYAD, label: this.tr('shafaq_abyad'), selected: this.shafaqValue === Shafaq.ABYAD };
        items.push(c);
        break;
      }
      case 'highlat': {
        const opts: PickerItem[] = SettingsHelper.buildHighLatPickerItems(this.highLatRule);
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
    // ... unchanged ...
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

  private isShafaqApplicable(): boolean {
    return this.calcMethod === CalculationMethod.MOONSIGHTING_COMMITTEE;
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
        console.error('[AdvancedCalcPage] reload advanced failed: ' + err.message);
      });

    SettingsHelper.getHighLatRule()
      .then((rule) => {
        this.highLatRule = rule;
      })
      .catch((err: Error) => {
        console.error('[AdvancedCalcPage] reload highLat failed: ' + err.message);
      });

    SettingsHelper.loadAll()
      .then((data) => {
        this.calcMethod = data.method;
        if (this.isMidnightLocked()) {
          this.midnightMethod = MidnightMethod.JAFARI;
        }
      })
      .catch((err: Error) => {
        console.error('[AdvancedCalcPage] reload base failed: ' + err.message);
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