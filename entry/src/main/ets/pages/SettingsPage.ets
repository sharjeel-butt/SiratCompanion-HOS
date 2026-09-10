// entry/src/main/ets/pages/SettingsPage.ets

import { router, promptAction } from '@kit.ArkUI';
import { Theme } from '../common/Theme';
import { CalculationMethod, AsrShadowRule } from '../utils/PrayerTimeCalculator';
import { SettingsHelper } from '../utils/SettingsHelper';
import { PickerItem, CalculationSource } from '../models/SettingsModels';

@Entry
@Component
struct SettingsPage {

  // ============================================================
  // STATE
  // ============================================================

  @State calcMethod: CalculationMethod = CalculationMethod.KARACHI;
  @State asrRule: AsrShadowRule = AsrShadowRule.STANDARD;
  @State calcSource: CalculationSource = CalculationSource.LOCAL;
  @State counter: number = 0;

  @State expandedCategory: string | null = 'Prayer Times';
  @State showMethodPicker: boolean = false;
  @State showAsrPicker: boolean = false;
  @State showSourcePicker: boolean = false;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  aboutToAppear(): void {
    SettingsHelper.initializeDefaults();
    this.reload();
  }

  onPageShow(): void {
    this.reload();
  }

  private reload(): void {
    this.calcMethod = SettingsHelper.getCalcMethod();
    this.asrRule = SettingsHelper.getAsrRule();
    this.calcSource = SettingsHelper.getCalcSource();
    this.counter = SettingsHelper.getCounter();
  }

  // ============================================================
  // EVENT HANDLERS
  // ============================================================

  private pickMethod(id: string): void {
    const method = id as CalculationMethod;
    this.calcMethod = method;
    SettingsHelper.setCalcMethod(method);
    this.showMethodPicker = false;
    promptAction.showToast({ message: `Set to ${SettingsHelper.getCalcMethodLabel(method)}` });
  }

  private pickAsrRule(id: string): void {
    const rule = Number(id) as AsrShadowRule;
    this.asrRule = rule;
    SettingsHelper.setAsrRule(rule);
    this.showAsrPicker = false;
    promptAction.showToast({ message: `Set to ${SettingsHelper.getAsrRuleLabel(rule)}` });
  }

  // 🔴 FIX: API option only shows a popup, doesn't change the selection
  private pickSource(id: string): void {
    const source = id as CalculationSource;

    // API (Online) is not yet available – show popup and keep Local selected
    if (source === CalculationSource.API) {
      this.showSourcePicker = false;
      promptAction.showToast({
        message: '🌐 Online API is coming soon',
        duration: 2500
      });
      return;
    }

    // Apply Local Formula selection
    this.calcSource = source;
    SettingsHelper.setCalcSource(source);
    this.showSourcePicker = false;
    promptAction.showToast({ message: 'Using Local Formula' });
  }

  private changeCounter(delta: number): void {
    this.counter = Math.max(0, this.counter + delta);
    SettingsHelper.setCounter(this.counter);
  }

  private resetCounter(): void {
    this.counter = 0;
    SettingsHelper.setCounter(0);
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
            // ---- Prayer Times ----
            this.CategoryHeader('Prayer Times', '🕌', Theme.accentGold, 'Prayer Times')
            if (this.expandedCategory === 'Prayer Times') {
              this.PrayerTimesContent()
            }

            // ---- Appearance ----
            this.CategoryHeader('Appearance', '🎨', '#9C88FF', 'Appearance')
            if (this.expandedCategory === 'Appearance') {
              this.AppearanceContent()
            }

            // ---- Counter ----
            this.CategoryHeader('Counter', '🔢', '#4CC9F0', 'Counter')
            if (this.expandedCategory === 'Counter') {
              this.CounterContent()
            }

            // ---- About ----
            this.CategoryHeader('About', 'ℹ️', '#F4A261', 'About')
            if (this.expandedCategory === 'About') {
              this.AboutContent()
            }

            Column().height(40)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 20 })
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor(Theme.primaryGreen)
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%').height('100%').backgroundColor(Theme.primaryGreen)

      // ---- Picker overlays ----
      if (this.showMethodPicker) {
        this.PickerOverlay(
          'Convention',
          '🕌',
          SettingsHelper.buildMethodPickerItems(this.calcMethod),
          (id: string) => { this.pickMethod(id); },
          () => { this.showMethodPicker = false; }
        )
      }

      if (this.showAsrPicker) {
        this.PickerOverlay(
          'Madhab',
          '🌅',
          SettingsHelper.buildAsrPickerItems(this.asrRule),
          (id: string) => { this.pickAsrRule(id); },
          () => { this.showAsrPicker = false; }
        )
      }

      if (this.showSourcePicker) {
        this.PickerOverlay(
          'Source',
          '🌐',
          SettingsHelper.buildSourcePickerItems(this.calcSource),
          (id: string) => { this.pickSource(id); },
          () => { this.showSourcePicker = false; }
        )
      }
    }
    .width('100%').height('100%').backgroundColor(Theme.primaryGreen)
  }

  // ============================================================
  // @BUILDER METHODS
  // ============================================================

  @Builder
  TopBar() {
    Row() {
      Text('←')
        .fontSize(26).fontColor(Theme.textWhite)
        .width(40).height(40).textAlign(TextAlign.Center)
        .borderRadius(20).backgroundColor('rgba(255,255,255,0.08)')
        .margin({ left: 16 })
        .onClick(() => router.back())

      Text('Settings')
        .fontSize(22).fontWeight(FontWeight.Bold).fontColor(Theme.textWhite)
        .margin({ left: 16 })
    }
    .width('100%').height(72).backgroundColor(Theme.cardDark)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  CategoryHeader(title: string, icon: string, iconColor: string, categoryKey: string) {
    Row() {
      Text(icon)
        .fontSize(18).width(40).height(40).textAlign(TextAlign.Center)
        .backgroundColor(iconColor + '22').borderRadius(12)
        .border({ width: 1, color: iconColor + '44' })

      Text(title)
        .fontSize(17).fontWeight(FontWeight.Bold).fontColor(Theme.textWhite)
        .margin({ left: 14 }).layoutWeight(1)

      Text(this.expandedCategory === categoryKey ? '▲' : '▼')
        .fontSize(12).fontColor(Theme.accentGold).opacity(0.8)
    }
    .width('100%').padding({ top: 12, bottom: 12, left: 12, right: 16 })
    .backgroundColor(Theme.cardDark).borderRadius(16)
    .border({ width: 1, color: 'rgba(201,169,110,0.15)' })
    .margin({ bottom: 8 })
    .onClick(() => {
      this.expandedCategory = this.expandedCategory === categoryKey ? null : categoryKey;
    })
  }

  // ============================================================
  // PRAYER TIMES CONTENT
  // ============================================================

  @Builder
  PrayerTimesContent() {
    Column() {
      // --- Source ---
      Row() {
        Column() {
          Text('Source')
            .fontSize(15).fontColor(Theme.textWhite).fontWeight(FontWeight.Medium)
          Text('Local Formula or Online')
            .fontSize(11).fontColor(Theme.textMuted)
            .margin({ top: 2 })
          Text(SettingsHelper.getCalcSourceLabel(this.calcSource))
            .fontSize(12).fontColor(Theme.accentGold)
            .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        Text('›').fontSize(22).fontColor(Theme.accentGold).opacity(0.7)
      }
      .width('100%')
      .padding({ top: 14, bottom: 14, left: 16, right: 16 })
      .backgroundColor('rgba(255,255,255,0.03)').borderRadius(12)
      .margin({ bottom: 8 })
      .onClick(() => { this.showSourcePicker = true; })

      // --- Convention (Calculation Method) ---
      Row() {
        Column() {
          Text('Convention')
            .fontSize(15).fontColor(Theme.textWhite).fontWeight(FontWeight.Medium)
          Text('Used for calculation of Fajr and Isha')
            .fontSize(11).fontColor(Theme.textMuted)
            .margin({ top: 2 })
          Text(SettingsHelper.getCalcMethodLabel(this.calcMethod))
            .fontSize(12).fontColor(Theme.accentGold)
            .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        Text('›').fontSize(22).fontColor(Theme.accentGold).opacity(0.7)
      }
      .width('100%')
      .padding({ top: 14, bottom: 14, left: 16, right: 16 })
      .backgroundColor('rgba(255,255,255,0.03)').borderRadius(12)
      .margin({ bottom: 8 })
      .onClick(() => { this.showMethodPicker = true; })

      // --- Madhab (Asr Shadow Rule) ---
      Row() {
        Column() {
          Text('Madhab')
            .fontSize(15).fontColor(Theme.textWhite).fontWeight(FontWeight.Medium)
          Text('Asr Shadow Rule used in the calculation')
            .fontSize(11).fontColor(Theme.textMuted)
            .margin({ top: 2 })
          Text(SettingsHelper.getAsrRuleLabel(this.asrRule))
            .fontSize(12).fontColor(Theme.accentGold)
            .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        Text('›').fontSize(22).fontColor(Theme.accentGold).opacity(0.7)
      }
      .width('100%')
      .padding({ top: 14, bottom: 14, left: 16, right: 16 })
      .backgroundColor('rgba(255,255,255,0.03)').borderRadius(12)
      .onClick(() => { this.showAsrPicker = true; })
    }
    .width('100%').padding(12).backgroundColor(Theme.cardDark)
    .borderRadius(16).border({ width: 1, color: 'rgba(201,169,110,0.15)' })
    .margin({ bottom: 12 })
  }

  // ============================================================
  // APPEARANCE / COUNTER / ABOUT
  // ============================================================

  @Builder
  AppearanceContent() {
    Column() {
      Row() {
        Column() {
          Text('Theme')
            .fontSize(15).fontColor(Theme.textWhite).fontWeight(FontWeight.Medium)
          Text('Choose how the app looks')
            .fontSize(11).fontColor(Theme.textMuted).margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        Text('System')
          .fontSize(13).fontColor(Theme.textMuted)
          .padding({ left: 12, right: 12, top: 4, bottom: 4 })
          .backgroundColor('rgba(255,255,255,0.05)').borderRadius(8)
      }
      .width('100%').padding({ top: 14, bottom: 14, left: 16, right: 16 })
      .backgroundColor('rgba(255,255,255,0.03)').borderRadius(12)

      Text('More themes coming soon')
        .fontSize(11).fontColor(Theme.textMuted).margin({ top: 8, left: 4 })
    }
    .width('100%').padding(12).backgroundColor(Theme.cardDark)
    .borderRadius(16).border({ width: 1, color: 'rgba(201,169,110,0.15)' })
    .margin({ bottom: 12 })
  }

  @Builder
  CounterContent() {
    Column() {
      Row() {
        Button('−')
          .width(48).height(48).fontSize(24).fontColor(Theme.textWhite)
          .backgroundColor('rgba(255,255,255,0.06)').borderRadius(12)
          .onClick(() => { this.changeCounter(-1); })

        Text(`${this.counter}`)
          .fontSize(36).fontWeight(FontWeight.Bold).fontColor(Theme.accentGold)
          .layoutWeight(1).textAlign(TextAlign.Center)

        Button('+')
          .width(48).height(48).fontSize(24).fontColor('#1B1B1B')
          .backgroundColor(Theme.accentGold).borderRadius(12)
          .onClick(() => { this.changeCounter(1); })
      }
      .width('100%').padding({ top: 12, bottom: 12 })

      Button('Reset Counter')
        .width('100%').height(40).fontSize(14).fontColor(Theme.textWhite)
        .backgroundColor('rgba(255,255,255,0.05)').borderRadius(10)
        .margin({ top: 4 })
        .onClick(() => { this.resetCounter(); })
    }
    .width('100%').padding(12).backgroundColor(Theme.cardDark)
    .borderRadius(16).border({ width: 1, color: 'rgba(201,169,110,0.15)' })
    .margin({ bottom: 12 })
  }

  @Builder
  AboutContent() {
    Column() {
      Column() {
        Text('Sirat Companion')
          .fontSize(20).fontWeight(FontWeight.Bold).fontColor(Theme.textWhite)
        Text('Your Daily Islamic Companion')
          .fontSize(12).fontColor(Theme.accentGold).margin({ top: 4 })

        Divider()
          .color('rgba(201,169,110,0.15)').width('80%')
          .margin({ top: 14, bottom: 14 })

        this.AboutRow('Version', '1.0.0')
        this.AboutRow('Platform', 'HarmonyOS')
        this.AboutRow('© 2026', 'Sirat Companion')
      }
      .width('100%').padding(20).backgroundColor('rgba(255,255,255,0.03)')
      .borderRadius(12).alignItems(HorizontalAlign.Center)
    }
    .width('100%').padding(12).backgroundColor(Theme.cardDark)
    .borderRadius(16).border({ width: 1, color: 'rgba(201,169,110,0.15)' })
    .margin({ bottom: 12 })
  }

  @Builder
  AboutRow(label: string, value: string) {
    Row() {
      Text(label).fontSize(13).fontColor(Theme.textMuted)
      Blank()
      Text(value).fontSize(13).fontColor(Theme.textWhite).fontWeight(FontWeight.Medium)
    }
    .width('100%').padding({ left: 8, right: 8 }).margin({ top: 6 })
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
      .backgroundColor('rgba(0,0,0,0.65)')
      .onClick(() => { onCancel(); })

    Column() {
      Row().width(44).height(4)
        .backgroundColor('rgba(255,255,255,0.25)').borderRadius(2).margin({ top: 10 })

      Row() {
        Text(icon)
          .fontSize(22).width(44).height(44).textAlign(TextAlign.Center)
          .backgroundColor(Theme.accentGold + '22').borderRadius(12)
          .border({ width: 1, color: Theme.accentGold + '44' })

        Text(title)
          .fontSize(20).fontWeight(FontWeight.Bold).fontColor(Theme.textWhite)
          .margin({ left: 14 })
      }
      .width('100%').padding({ left: 20, top: 20, bottom: 20 })

      Divider().color('rgba(255,255,255,0.08)').width('90%')

      Column() {
        ForEach(items, (item: PickerItem) => {
          Row() {
            Row() {
              if (item.selected) {
                Row().width(10).height(10).borderRadius(5).backgroundColor(Theme.accentGold)
              }
            }
            .width(22).height(22).borderRadius(11)
            .border({
              width: item.selected ? 2 : 1.5,
              color: item.selected ? Theme.accentGold : 'rgba(255,255,255,0.3)'
            })
            .justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)

            Text(item.label)
              .fontSize(15)
              .fontColor(item.selected ? Theme.accentGold : Theme.textWhite)
              .fontWeight(item.selected ? FontWeight.Bold : FontWeight.Normal)
              .layoutWeight(1).maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ left: 14 })
          }
          .width('100%')
          .padding({ top: 16, bottom: 16, left: 20, right: 20 })
          .backgroundColor(item.selected ? Theme.accentGold + '15' : 'transparent')
          .borderRadius(12).margin({ bottom: 4 })
          .onClick(() => { onSelect(item.id); })
        }, (item: PickerItem) => item.id)
      }
      .width('100%').padding({ left: 8, right: 8, top: 12, bottom: 12 })

      Button('Cancel')
        .width('90%').height(48).fontSize(15).fontWeight(FontWeight.Medium)
        .fontColor(Theme.textWhite).backgroundColor('rgba(255,255,255,0.06)')
        .borderRadius(12).margin({ top: 8, bottom: 24 })
        .onClick(() => { onCancel(); })
    }
    .width('100%').backgroundColor(Theme.primaryGreen)
    .borderRadius({ topLeft: 28, topRight: 28 })
    .shadow({ radius: 24, color: 'rgba(0,0,0,0.5)', offsetX: 0, offsetY: -6 })
    .border({ width: { top: 1 }, color: 'rgba(201,169,110,0.25)' })
    .position({ bottom: 0 })
  }
}