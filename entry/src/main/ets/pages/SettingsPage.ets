// entry/src/main/ets/pages/SettingsPage.ets

import { router, promptAction } from '@kit.ArkUI';
import { Theme } from '../common/Theme';
import { CalculationMethod, AsrShadowRule, PrayerTimeCalculator } from '../utils/PrayerTimeCalculator';
import {
  STORAGE_KEY_CALC_METHOD,
  STORAGE_KEY_ASR_RULE,
  STORAGE_KEY_COUNTER
} from '../common/StorageKeys';

// ----- Local interfaces for action menu -----
interface ActionButton {
  text: string;
  color?: string;
}

interface ActionMenuOptions {
  title: string;
  buttons: ActionButton[];
}

interface MenuResult {
  index: number;
}

@Entry
@Component
struct SettingsPage {
  // ----- Preferences -----
  @State calcMethod: CalculationMethod = CalculationMethod.KARACHI;
  @State asrRule: AsrShadowRule = AsrShadowRule.STANDARD;
  @State counter: number = 0;

  // ----- UI state -----
  @State expandedCategory: string | null = null;

  // ----- Lifecycle -----
  aboutToAppear(): void {
    this.loadPreferences();
  }

  private loadPreferences(): void {
    const storedMethod = AppStorage.get<string>(STORAGE_KEY_CALC_METHOD);
    if (storedMethod) {
      const methodEnum = Object.values(CalculationMethod).find(v => v === storedMethod);
      if (methodEnum !== undefined) this.calcMethod = methodEnum;
    }
    const storedAsr = AppStorage.get<number>(STORAGE_KEY_ASR_RULE);
    if (storedAsr !== undefined) this.asrRule = storedAsr;
    const storedCounter = AppStorage.get<number>(STORAGE_KEY_COUNTER);
    if (storedCounter !== undefined) this.counter = storedCounter;
  }

  private savePreferences(): void {
    AppStorage.setOrCreate(STORAGE_KEY_CALC_METHOD, this.calcMethod);
    AppStorage.setOrCreate(STORAGE_KEY_ASR_RULE, this.asrRule);
    AppStorage.setOrCreate(STORAGE_KEY_COUNTER, this.counter);
  }

  private onPreferenceChanged(): void {
    this.savePreferences();
  }

  // ----- Picker dialogs -----
  private showMethodPickerDialog(): void {
    const methods = PrayerTimeCalculator.getAvailableMethods();
    const buttons: ActionButton[] = methods.map((m): ActionButton => ({ text: m.label }));
    const options: ActionMenuOptions = { title: 'Select Calculation Method', buttons: buttons };
    promptAction.showActionMenu(options as promptAction.ActionMenuOptions)
      .then((result: MenuResult) => {
        if (result.index !== undefined && result.index < methods.length) {
          this.calcMethod = methods[result.index].value;
          this.onPreferenceChanged();
        }
      })
      .catch((err: Error) => console.error('Method picker error:', JSON.stringify(err)));
  }

  private showAsrPickerDialog(): void {
    const rules = PrayerTimeCalculator.getAvailableAsrRules();
    const buttons: ActionButton[] = rules.map((r): ActionButton => ({ text: r.label }));
    const options: ActionMenuOptions = { title: 'Select Asr Shadow Rule', buttons: buttons };
    promptAction.showActionMenu(options as promptAction.ActionMenuOptions)
      .then((result: MenuResult) => {
        if (result.index !== undefined && result.index < rules.length) {
          this.asrRule = rules[result.index].value;
          this.onPreferenceChanged();
        }
      })
      .catch((err: Error) => console.error('Asr rule picker error:', JSON.stringify(err)));
  }

  // ----- Build -----
  build() {
    Column() {
      // Top bar with back button
      Row() {
        Text('←')
          .fontSize(28)
          .fontColor(Theme.textWhite)
          .margin({ left: 16 })
          .onClick(() => router.back())

        Text('Settings')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.textWhite)
          .margin({ left: 16 })
      }
      .width('100%')
      .height(56)
      .backgroundColor(Theme.cardDark)
      .alignItems(VerticalAlign.Center)

      // Settings list
      List() {
        ListItem() {
          this.CategoryHeader('Prayer Times')
        }
        .onClick(() => {
          this.expandedCategory = this.expandedCategory === 'Prayer Times' ? null : 'Prayer Times';
        })

        if (this.expandedCategory === 'Prayer Times') {
          ListItem() { this.PrayerTimesSettings() }
        }

        ListItem() {
          this.CategoryHeader('Appearance')
        }
        .onClick(() => {
          this.expandedCategory = this.expandedCategory === 'Appearance' ? null : 'Appearance';
        })

        if (this.expandedCategory === 'Appearance') {
          ListItem() { this.AppearanceSettings() }
        }

        ListItem() {
          this.CategoryHeader('Counter')
        }
        .onClick(() => {
          this.expandedCategory = this.expandedCategory === 'Counter' ? null : 'Counter';
        })

        if (this.expandedCategory === 'Counter') {
          ListItem() { this.CounterSettings() }
        }

        ListItem() {
          this.CategoryHeader('About')
        }
        .onClick(() => {
          this.expandedCategory = this.expandedCategory === 'About' ? null : 'About';
        })

        if (this.expandedCategory === 'About') {
          ListItem() { this.AboutSettings() }
        }

        // Exit is removed from here – it lives in the main drawer now
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Theme.primaryGreen)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.primaryGreen)
  }

  // ----- Category header (collapsible) -----
  @Builder
  CategoryHeader(title: string) {
    Row() {
      Text(title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Theme.textWhite)
      Blank()
      Text(this.expandedCategory === title ? '▲' : '▼')
        .fontSize(16)
        .fontColor(Theme.accentGold)
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .backgroundColor(Theme.cardDark)
    .borderRadius(Theme.radiusSmall)
    .padding({ left: 16, right: 16 })
  }

  // ----- Settings content builders -----
  @Builder
  PrayerTimesSettings() {
    Column() {
      this.PreferenceRow('Calculation Method',
        PrayerTimeCalculator.getParameters(this.calcMethod).methodName,
        () => this.showMethodPickerDialog())
      this.PreferenceRow('Asr Shadow Rule',
        this.asrRule === AsrShadowRule.STANDARD ? 'Standard' : 'Hanafi',
        () => this.showAsrPickerDialog())
    }
    .width('100%')
    .padding(8)
    .backgroundColor(Theme.cardDark)
    .borderRadius(Theme.radiusSmall)
    .margin({ top: 4, bottom: 8 })
  }

  @Builder
  AppearanceSettings() {
    Column() {
      Text('Theme: System (coming soon)')
        .fontSize(16)
        .fontColor(Theme.textMuted)
        .padding(12)
        .backgroundColor(Theme.primaryGreen)
        .borderRadius(Theme.radiusSmall)
        .width('100%')
    }
    .width('100%')
    .padding(8)
    .backgroundColor(Theme.cardDark)
    .borderRadius(Theme.radiusSmall)
    .margin({ top: 4, bottom: 8 })
  }

  @Builder
  CounterSettings() {
    Column() {
      this.CounterItem()
    }
    .width('100%')
    .padding(8)
    .backgroundColor(Theme.cardDark)
    .borderRadius(Theme.radiusSmall)
    .margin({ top: 4, bottom: 8 })
  }

  @Builder
  AboutSettings() {
    Column() {
      Text('Sirat Companion')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Theme.textWhite)
      Text('Version 1.0.0')
        .fontSize(14)
        .fontColor(Theme.textMuted)
        .margin({ top: 4 })
      Text('© 2026 Sirat Companion')
        .fontSize(12)
        .fontColor(Theme.textMuted)
        .margin({ top: 2 })
      Text('Built with ❤️ for HarmonyOS')
        .fontSize(12)
        .fontColor(Theme.textMuted)
        .margin({ top: 2 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Theme.cardDark)
    .borderRadius(Theme.radiusSmall)
    .alignItems(HorizontalAlign.Center)
    .margin({ top: 4, bottom: 8 })
  }

  // ----- Reusable preference row -----
  @Builder
  PreferenceRow(label: string, value: string, onClick: () => void) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor(Theme.textWhite)
        .layoutWeight(1)
      Text(value)
        .fontSize(16)
        .fontColor(Theme.textMuted)
        .margin({ right: 8 })
      Text('›')
        .fontSize(20)
        .fontColor(Theme.textMuted)
    }
    .width('100%')
    .padding({ top: 12, bottom: 12, left: 8, right: 8 })
    .backgroundColor(Theme.primaryGreen)
    .borderRadius(Theme.radiusSmall)
    .margin({ bottom: 4 })
    .onClick(() => onClick())
  }

  // ----- Counter item -----
  @Builder
  CounterItem() {
    Row() {
      Button('−')
        .width(40)
        .height(40)
        .fontSize(24)
        .backgroundColor(Theme.cardMuted)
        .fontColor(Theme.textWhite)
        .borderRadius(Theme.radiusSmall)
        .onClick(() => {
          if (this.counter > 0) {
            this.counter--;
            this.onPreferenceChanged();
          }
        })

      Text(`${this.counter}`)
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(Theme.textWhite)
        .width(80)
        .textAlign(TextAlign.Center)

      Button('+')
        .width(40)
        .height(40)
        .fontSize(24)
        .backgroundColor(Theme.accentGold)
        .fontColor(Theme.textWhite)
        .borderRadius(Theme.radiusSmall)
        .onClick(() => {
          this.counter++;
          this.onPreferenceChanged();
        })

      Button('Reset')
        .fontSize(14)
        .backgroundColor(Theme.cardMuted)
        .fontColor(Theme.textWhite)
        .borderRadius(Theme.radiusSmall)
        .padding({ left: 16, right: 16 })
        .margin({ left: 16 })
        .onClick(() => {
          this.counter = 0;
          this.onPreferenceChanged();
        })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding(12)
    .backgroundColor(Theme.primaryGreen)
    .borderRadius(Theme.radiusSmall)
  }
}