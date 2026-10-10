// entry/src/main/ets/components/PageHeader.ets

import { Theme, ThemeColors } from '../common/Theme';
import { L } from '../helper/LocalizationHelper';
import { SettingsHelper } from '../helper/SettingsHelper';
import { AsrShadowRule, CalculationMethod } from '../utils/PrayerTimeCalculator';
import { CalculationSource } from '../models/SettingsModels';
import { ClockFormat, ClockFormatHelper } from '../common/ClockFormat';
import { STORAGE_KEY_TIME_FORMAT } from '../common/StorageKeys';

/**
 * Shared page header used by HomePage and Prayer.
 *
 * Contains:
 *   • Hijri date pill + Location pill + Hamburger icon
 *   • Current prayer row
 *   • Optional calculation-pill row (🕌 method / 🌅 asr / 🌐 source)
 *
 * Data flows in via @Prop, events flow out via callbacks.
 */
@Component
export struct PageHeader {
  @Prop colors: ThemeColors;
  @Prop currentLanguage: string = 'en';
  @Prop hijriDateString: string = '';
  @Prop currentLocation: string = '';
  @Prop isLoadingLocation: boolean = true;
  @Prop todayCurrentPrayerName: string = '—';
  @Prop todayCurrentPrayerTime: string = '--:--';
  @Prop calcMethod: CalculationMethod = CalculationMethod.KARACHI;
  @Prop asrRule: AsrShadowRule = AsrShadowRule.STANDARD;
  @Prop calcSource: CalculationSource = CalculationSource.LOCAL;
  /** Show the calculation-pill row. Both pages currently show it. */
  @Prop showCalcPills: boolean = true;
  @StorageLink(STORAGE_KEY_TIME_FORMAT)
  ClockFormat: string = ClockFormat.SYSTEM;
  onHamburger: () => void = () => {
  };
  onRefreshLocation: () => void = () => {
  };
  onOpenSettings: () => void = () => {
  };

  // ============================================================
  // HELPERS
  // ============================================================

  build() {
    Column() {
      // ============ Row 1: Hijri pill + Location pill + Hamburger ============
      Row() {
        Column() {
          // Hijri date pill
          Row() {
            Text('🌙').fontSize(12)
            Text(this.hijriDateString)
              .fontSize(13)
              .fontColor(this.colors.accentGold)
              .fontWeight(FontWeight.Medium)
              .margin({ left: 6 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .height(30)
          .padding({ left: 12, right: 12 })
          .backgroundColor(this.colors.cardDark)
          .borderRadius(15)
          .border({ width: 1, color: this.colors.borderSoft })
          .alignSelf(ItemAlign.Start)

          // Location pill
          Row() {
            Text('📍').fontSize(15)
            Text(this.currentLocation)
              .fontSize(16)
              .fontColor(this.colors.textWhite)
              .fontWeight(FontWeight.Bold)
              .margin({ left: 8 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            if (this.isLoadingLocation) {
              LoadingProgress()
                .width(16).height(16)
                .color(this.colors.accentGold)
                .margin({ left: 8 })
            } else {
              Text('📡').fontSize(16).margin({ left: 8 })
            }
          }
          .height(38)
          .padding({ left: 14, right: 12 })
          .backgroundColor(this.colors.cardDark)
          .borderRadius(19)
          .border({ width: 1, color: this.colors.borderSoft })
          .margin({ top: 6 })
          .alignSelf(ItemAlign.Start)
          .onClick(() => {
            this.onRefreshLocation();
          })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text('☰')
          .fontSize(28)
          .fontColor(this.colors.textWhite)
          .onClick(() => {
            this.onHamburger();
          })
      }
      .width('100%')
      .padding({ top: 32, bottom: 8 })
      .alignItems(VerticalAlign.Top)

      // ============ Row 2: Current prayer ============
      Column() {
        Row() {
          Text(this.tr('current_prayer'))
            .fontSize(12)
            .fontColor(this.colors.textMuted)
            .letterSpacing(1)
            .fontWeight(FontWeight.Medium)
          Blank()
          Row() {
            Text(this.translateEventName(this.todayCurrentPrayerName))
              .fontSize(16)
              .fontColor(this.colors.accentGold)
              .fontWeight(FontWeight.Bold)
            Text('   ')
            Text(ClockFormatHelper.reformat(this.todayCurrentPrayerTime))
              .fontSize(16)
              .fontColor(this.colors.textWhite)
              .fontWeight(FontWeight.Medium)
          }
        }
        .width('100%')
        .padding({
          top: 12,
          bottom: 12,
          left: 16,
          right: 16
        })
        .backgroundColor(this.colors.cardDark)
        .borderRadius(Theme.radiusMedium)
        .border({ width: 1, color: this.colors.borderSoft })
      }
      .width('100%')
      .margin({ top: 4, bottom: 12 })

      // ============ Row 3: Calc pills (optional) ============
      if (this.showCalcPills) {
        Row() {
          // Method
          Row() {
            Text('🕌').fontSize(13).margin({ right: 6 })
            Text(SettingsHelper.getCalcMethodShortLabel(this.calcMethod))
              .fontSize(12)
              .fontColor(this.colors.accentGold)
              .fontWeight(FontWeight.Medium)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
          }
          .layoutWeight(1)
          .height(34)
          .padding({ left: 12, right: 12 })
          .backgroundColor(this.colors.cardDark)
          .borderRadius(17)
          .border({ width: 1, color: this.colors.borderSoft })
          .margin({ right: 4 })
          .onClick(() => {
            this.onOpenSettings();
          })

          // Asr rule
          Row() {
            Text('🌅').fontSize(13).margin({ right: 6 })
            Text(SettingsHelper.getAsrRuleShortLabel(this.asrRule))
              .fontSize(12)
              .fontColor(this.colors.accentGold)
              .fontWeight(FontWeight.Medium)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
          }
          .layoutWeight(1)
          .height(34)
          .padding({ left: 12, right: 12 })
          .backgroundColor(this.colors.cardDark)
          .borderRadius(17)
          .border({ width: 1, color: this.colors.borderSoft })
          .margin({ right: 4 })
          .onClick(() => {
            this.onOpenSettings();
          })

          // Source
          Row() {
            Text('🌐').fontSize(13).margin({ right: 6 })
            Text(SettingsHelper.getCalcSourceShortLabel(this.calcSource))
              .fontSize(12)
              .fontColor(this.colors.accentGold)
              .fontWeight(FontWeight.Medium)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
          }
          .layoutWeight(1)
          .height(34)
          .padding({ left: 12, right: 12 })
          .backgroundColor(this.colors.cardDark)
          .borderRadius(17)
          .border({ width: 1, color: this.colors.borderSoft })
          .onClick(() => {
            this.onOpenSettings();
          })
        }
        .width('100%')
        .padding({ bottom: 8 })
        .alignItems(VerticalAlign.Center)
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.colors.primaryGreen)
  }

  private tr(key: string): string {
    return L.get(key, this.currentLanguage);
  }

  // ============================================================
  // BUILD
  // ============================================================

  private translateEventName(raw: string): string {
    switch (raw) {
      case 'Fajr':
        return this.tr('prayer_fajr');
      case 'Dhuhr':
        return this.tr('prayer_dhuhr');
      case 'Asr':
        return this.tr('prayer_asr');
      case 'Maghrib':
        return this.tr('prayer_maghrib');
      case 'Isha':
        return this.tr('prayer_isha');
      case 'Jummah':
        return this.tr('prayer_jummah');
      case 'Imsak':
        return this.tr('timing_imsak');
      case 'Sunrise':
        return this.tr('timing_sunrise');
      case 'Sunset':
        return this.tr('timing_sunset');
      case 'First Third':
        return this.tr('timing_first_third');
      case 'Midnight':
        return this.tr('timing_midnight');
      case 'Last Third':
        return this.tr('timing_last_third');
      default:
        return raw;
    }
  }
}