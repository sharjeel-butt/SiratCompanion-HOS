// entry/src/main/ets/components/PageHeader.ets

import { Theme, ThemeColors, ThemeMode } from '../core/ui/themes/Theme'
import { L } from '../i18n/LocalizationHelper'
import { SettingsHelper } from '../settings/SettingsHelper'
import { AsrShadowRule, CalculationMethod } from './PrayerTimeCalculator'
import { CalculationSource } from '../settings/SettingsModels'
import { ClockFormat, ClockFormatHelper } from '../core/util/ClockFormat'
import { STORAGE_KEY_THEME_MODE, STORAGE_KEY_TIME_FORMAT } from '../core/common/StorageKeys'
import { TypographyHelper } from '../core/ui/themes/TypographyHelper'
import { router } from '@kit.ArkUI'

/**
 * Shared page header used by HomePage and Prayer.
 *
 * Contains:
 *   • Hijri date pill + Location pill
 *   • Current prayer row
 *   • Optional calculation-pill row (🕌 method / 🌅 asr / 🌐 source)
 *
 * Data flows in via @Prop, events flow out via callbacks.
 *
 * Time display: the Current Prayer time is passed in as an internal
 * 12-hour string and reformatted to the user's preference (12h, 24h,
 * or System) at render time. A @StorageLink on the time format key
 * makes this reactive — changing the setting in Customize updates
 * this row immediately.
 */
@Component
export struct PageHeader {
  @Prop colors: ThemeColors;
  @Prop currentLanguage: string = 'en';
  @Prop hijriDateString: string = '';
  @Prop currentLocation: string = '';
  @Prop isLoadingLocation: boolean = true;
  @Prop todayNextPrayerName: string = '—';
  @Prop todayCurrentPrayerName: string = '—';
  @Prop todayCurrentPrayerTime: string = '--:--';
  @Prop currentPrayerValidUntil: string = ''
  @Prop currentPrayerPreferredUntil: string = ''
  @Prop currentPrayerValidUntilTomorrow: boolean = false
  @Prop todayNextPrayerTime: string = '--:--';
  @Prop nextPrayerCountdown: string = '--:--:--';
  @Prop calcMethod: CalculationMethod = CalculationMethod.KARACHI;
  @Prop asrRule: AsrShadowRule = AsrShadowRule.STANDARD;
  @Prop calcSource: CalculationSource = CalculationSource.LOCAL;
  @Prop showCalcPills: boolean = true;
  @StorageLink(STORAGE_KEY_THEME_MODE) themeMode: string = ThemeMode.SYSTEM;
  @StorageLink(STORAGE_KEY_TIME_FORMAT) @Watch('onClockFormatChanged') clockFormat: string = ClockFormat.SYSTEM;
  @Prop isRamadan: boolean = false;
  @Prop fastingEndTime: string = '';
  onOpenLocationSettings: () => void = () => {
  };
  onOpenSettings: () => void = () => {
  };

  // ============================================================
  // HELPERS
  // ============================================================

  build() {

    Column() { // ============ Row 1: Hijri pill + Location pill ============
      Column() { // Hijri date pill
        Row({ space: 6 }) {
          Image($r('app.media.ic_nav_calendar')).width(14).height(14).fillColor(this.colors.accentGold)
          Text(this.hijriDateString)
            .fontSize(13)
            .fontFamily(TypographyHelper.getFont(this.currentLanguage, true))
            .fontColor(this.colors.accentGold)
            .fontWeight(FontWeight.Medium)
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
        Row({ space: 8 }) {
          Image($r('app.media.ic_pin')).width(16).height(16).fillColor(this.colors.accentGold)
          Text(this.currentLocation)
            .fontSize(16)
            .fontFamily(TypographyHelper.getFont(this.currentLanguage, true))
            .fontColor(this.colors.textWhite)
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (this.isLoadingLocation) {
            LoadingProgress().width(16).height(16).color(this.colors.accentGold)
          } else {
            Image($r('app.media.ic_chevron_right'))
              .width(16)
              .height(16)
              .fillColor(this.colors.accentGold)
              .opacity(0.7)
              .objectFit(ImageFit.Contain)
              .flexShrink(0)
              .rotate({ angle: L.isRtlLang(this.currentLanguage) ? 180 : 0 })
          }
        }
        .height(38)
        .alignItems(VerticalAlign.Center)
        .padding({ left: 14, right: 12 })
        .backgroundColor(this.colors.cardDark)
        .borderRadius(19)
        .border({ width: 1, color: this.colors.borderSoft })
        .margin({ top: 6 })
        .alignSelf(ItemAlign.Start)
        .hoverEffect(HoverEffect.Highlight)
        .onClick(() => {
          this.onOpenLocationSettings()
        })
      }.alignItems(HorizontalAlign.Start).width('100%')

      // ============ Row 2: Calc pills or Fasting Window ============
      if (this.isRamadan) {
        Row({ space: 8 }) {
          Image($r('app.media.ic_fast')).width(16).height(16).fillColor(this.colors.accentGold).flexShrink(0)

          Text(this.tr('fasting_ends_at')).fontSize(12).fontColor(this.colors.textMuted)

          Text(this.dt(this.fastingEndTime))
            .fontSize(14)
            .fontColor(this.colors.accentGold)
            .fontWeight(FontWeight.Bold)
            .direction(Direction.Ltr)

          Blank()

          Row({ space: 2 }) {
            Text(this.tr('details_view')).fontSize(11).fontColor(this.colors.accentGold).fontWeight(FontWeight.Medium)
            Image($r('app.media.ic_chevron_right'))
              .width(12)
              .height(12)
              .fillColor(this.colors.accentGold)
              .rotate({ angle: this.isRtl() ? 180 : 0 })
          }
        }
        .width('100%')
        .height(38)
        .padding({ left: 14, right: 14 })
        .backgroundColor(this.colors.cardDark)
        .borderRadius(12)
        .border({ width: 1, color: this.colors.accentGold })
        .margin({ bottom: 8 })
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          router.pushUrl({ url: 'pages/RamadanDetailsPage' }).catch((e: Error) => console.error(JSON.stringify(e)))
        })
      } else if (this.showCalcPills) {
        Row({ space: 4 }) { // Method
          Row({ space: 6 }) {
            Image($r('app.media.ic_nav_mosque')).width(14).height(14).fillColor(this.colors.accentGold).flexShrink(0)
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
          .hoverEffect(HoverEffect.Highlight)
          .onClick(() => {
            this.onOpenSettings()
          })

          // Asr rule
          Row({ space: 6 }) {
            Image($r('app.media.ic_asr_rule')).width(14).height(14).fillColor(this.colors.accentGold).flexShrink(0)
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
          .hoverEffect(HoverEffect.Highlight)
          .onClick(() => {
            this.onOpenSettings()
          })

          // Source
          Row({ space: 6 }) {
            Image($r('app.media.ic_globe')).width(14).height(14).fillColor(this.colors.accentGold).flexShrink(0)
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
          .hoverEffect(HoverEffect.Highlight)
          .onClick(() => {
            this.onOpenSettings()
          })

        }.width('100%').padding({ bottom: 4 }).margin({ top: 6 }).alignItems(VerticalAlign.Center)
      }

      // ============ Row 3: Prayer Cards ============
      Row({ space: 12 }) {

        // ==================================================
        // Current Prayer Card
        // ==================================================
        Column({ space: 4 }) {

          Text(this.tr('current_prayer'))
            .fontSize(10)
            .fontColor(this.colors.textMuted)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .textAlign(TextAlign.Start)

          Text(this.translateEventName(this.todayCurrentPrayerName))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.colors.accentGold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .textAlign(TextAlign.Start)

          Text(this.dt(this.todayCurrentPrayerTime))
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.colors.textWhite)
            .fontFeature('"tnum" 1')
            .width('100%')
            .textAlign(TextAlign.Start)

          if (this.currentPrayerPreferredUntil.length > 0) {

            Text(`${this.tr('preferred_until')} ${this.dt(this.currentPrayerPreferredUntil)}`)
              .fontSize(13)
              .fontColor(this.colors.textMuted)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
              .textAlign(TextAlign.Start)
          }

          if (this.currentPrayerValidUntil.length > 0) {

            Text(this.currentPrayerValidUntilTomorrow ?
              `${this.tr('valid_until')} ${this.dt(this.currentPrayerValidUntil)} (${this.tr('tomorrow')})` :
              `${this.tr('valid_until')} ${this.dt(this.currentPrayerValidUntil)}`)
              .fontSize(13)
              .fontColor(this.colors.textMuted)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
              .textAlign(TextAlign.Start)

          }

        }
        .layoutWeight(1)
        .height(135)
        .padding({
          left: 12,
          right: 12,
          top: 12,
          bottom: 12
        })
        .backgroundColor(this.colors.cardDark)
        .borderRadius(Theme.radiusMedium)
        .border({
          width: 1, color: this.colors.borderSoft
        })
        .alignItems(HorizontalAlign.Start)

        // ==================================================
        // Next Prayer Card
        // ==================================================
        Column({ space: 4 }) {

          Text(this.tr('next_prayer'))
            .fontSize(10)
            .fontColor(this.colors.textMuted)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .textAlign(TextAlign.Start)

          Text(this.translateEventName(this.todayNextPrayerName))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.colors.accentGold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .textAlign(TextAlign.Start)

          Text(this.dt(this.todayNextPrayerTime))
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.colors.textWhite)
            .fontFeature('"tnum" 1')
            .width('100%')
            .textAlign(TextAlign.Start)

          Text(this.nextPrayerCountdown)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.colors.accentGold)
            .fontFeature('"tnum" 1')
            .width('100%')
            .textAlign(TextAlign.Start)

          Text(this.tr('remaining'))
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.colors.textMuted)
            .width('100%')
            .textAlign(TextAlign.Start)

        }
        .layoutWeight(1)
        .height(135)
        .padding({
          left: 12,
          right: 12,
          top: 12,
          bottom: 12
        })
        .backgroundColor(this.colors.cardDark)
        .borderRadius(Theme.radiusMedium)
        .border({
          width: 1, color: this.colors.borderSoft
        })
        .alignItems(HorizontalAlign.Start)

      }.width('100%').margin({
        top: 4, bottom: 4
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16, bottom: 4 })
    .backgroundColor(this.colors.primaryGreen)
    .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
  }

  private tr(key: string): string {
    return L.get(key, this.currentLanguage)
  }

  private dt(t: string): string {
    if (this.clockFormat.length === 0) {
      return t
    }
    return ClockFormatHelper.reformat(t)
  }

  private onClockFormatChanged(): void { // Re-render is handled by the @StorageLink.
  }

  private isRtl(): boolean {
    return L.isRtlLang(this.currentLanguage)
  }

  // ============================================================
  // BUILD
  // ============================================================

  private translateEventName(raw: string): string {
    switch (raw) {
      case 'Fajr':
        return this.tr('prayer_fajr')
      case 'Dhuhr':
        return this.tr('prayer_dhuhr')
      case 'Asr':
        return this.tr('prayer_asr')
      case 'Maghrib':
        return this.tr('prayer_maghrib')
      case 'Isha':
        return this.tr('prayer_isha')
      case 'Jummah':
        return this.tr('prayer_jummah')
      case 'Imsak':
        return this.tr('timing_imsak')
      case 'Sunrise':
        return this.tr('timing_sunrise')
      case 'Sunset':
        return this.tr('timing_sunset')
      case 'First Third':
        return this.tr('timing_first_third')
      case 'Midnight':
        return this.tr('timing_midnight')
      case 'Last Third':
        return this.tr('timing_last_third')
      default:
        return raw
    }
  }
}
