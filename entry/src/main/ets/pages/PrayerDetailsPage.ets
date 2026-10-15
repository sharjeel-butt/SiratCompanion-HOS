// entry/src/main/ets/pages/PrayerDetailsPage.ets

import { mediaquery, router } from '@kit.ArkUI';
import { Theme, ThemeColors, ThemeMode, ThemePreset } from '../common/Theme';
import { PageTheme } from '../common/PageTheme';
import {
  STORAGE_KEY_APP_FOREGROUND_TICK,
  STORAGE_KEY_APP_THEME,
  STORAGE_KEY_BREAKPOINT,
  STORAGE_KEY_LANGUAGE,
  STORAGE_KEY_PRAYER_STATE_VERSION,
  STORAGE_KEY_THEME_MODE
} from '../common/StorageKeys';
import { L } from '../helper/LocalizationHelper';
import { Breakpoints } from '../common/Breakpoints';
import {
  MonthDayCell, PerPrayerCount, PrayerDetailsSnapshot, ProgressHelper
} from '../utils/ProgressHelper';

type Period = 'week' | 'month' | 'year';

@Entry
@Component
struct PrayerDetailsPage {
  @StorageLink(STORAGE_KEY_THEME_MODE)
  @Watch('onThemeModeChanged')
  themeMode: string = ThemeMode.SYSTEM;
  @StorageLink(STORAGE_KEY_LANGUAGE)
  appLanguage: string = 'en';
  @StorageLink(STORAGE_KEY_APP_THEME)
  @Watch('onAppThemePresetChanged')
  appThemePreset: string = ThemePreset.SIRAT;
  @StorageLink(STORAGE_KEY_APP_FOREGROUND_TICK)
  @Watch('onAppForegrounded')
  appForegroundTick: number = 0;
  @StorageLink(STORAGE_KEY_PRAYER_STATE_VERSION)
  @Watch('onPrayerStateChanged')
  prayerStateVersion: number = 0;
  @StorageLink(STORAGE_KEY_BREAKPOINT)
  breakpoint: string = 'sm';
  @State colors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);
  @State period: Period = 'week';
  @State snapshot: PrayerDetailsSnapshot = {
    weekPerPrayer: {
      fajr: 0,
      dhuhr: 0,
      asr: 0,
      maghrib: 0,
      isha: 0
    },
    monthPerPrayer: {
      fajr: 0,
      dhuhr: 0,
      asr: 0,
      maghrib: 0,
      isha: 0
    },
    yearPerPrayer: {
      fajr: 0,
      dhuhr: 0,
      asr: 0,
      maghrib: 0,
      isha: 0
    },
    weekTotal: 0,
    weekPossible: 35,
    monthTotal: 0,
    monthPossible: 0,
    yearTotal: 0,
    yearPossible: 0,
    currentStreak: 0,
    bestStreak: 0,
    monthProgress: {
      year: 2026,
      monthIndex: 0,
      cells: [],
      weeks: [],
      totalCompleted: 0,
      perfectDays: 0,
      daysElapsed: 0,
      daysInMonth: 0
    }
  };
  private systemDarkListener: mediaquery.MediaQueryListener | null = null;

  aboutToAppear(): void {
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
    this.colors = PageTheme.compute(this.themeMode);
    this.reload();
  }

  private reload(): void {
    this.snapshot = ProgressHelper.getPrayerDetails();
  }

  private onThemeModeChanged(): void {
    this.colors = PageTheme.compute(this.themeMode);
  }

  private onAppThemePresetChanged(): void {
    this.colors = PageTheme.compute(this.themeMode);
  }

  private onAppForegrounded(): void {
    this.reload();
  }

  private onPrayerStateChanged(): void {
    this.reload();
  }

  private tr(key: string): string {
    return L.get(key, this.appLanguage);
  }

  private isRtl(): boolean {
    return L.isRtlLang(this.appLanguage);
  }

  private perPrayerForPeriod(): PerPrayerCount {
    if (this.period === 'month') {
      return this.snapshot.monthPerPrayer;
    }
    if (this.period === 'year') {
      return this.snapshot.yearPerPrayer;
    }
    return this.snapshot.weekPerPrayer;
  }

  private totalForPeriod(): number {
    if (this.period === 'month') {
      return this.snapshot.monthTotal;
    }
    if (this.period === 'year') {
      return this.snapshot.yearTotal;
    }
    return this.snapshot.weekTotal;
  }

  private possibleForPeriod(): number {
    if (this.period === 'month') {
      return this.snapshot.monthPossible;
    }
    if (this.period === 'year') {
      return this.snapshot.yearPossible;
    }
    return this.snapshot.weekPossible;
  }

  private percentForPeriod(): number {
    const possible = this.possibleForPeriod();
    if (possible === 0) {
      return 0;
    }
    return Math.round(this.totalForPeriod() / possible * 100);
  }

  private prayerLabel(id: string): string {
    if (id === 'fajr') {
      return this.tr('prayer_fajr');
    }
    if (id === 'dhuhr') {
      return this.tr('prayer_dhuhr');
    }
    if (id === 'asr') {
      return this.tr('prayer_asr');
    }
    if (id === 'maghrib') {
      return this.tr('prayer_maghrib');
    }
    return this.tr('prayer_isha');
  }

  private cellBg(cell: MonthDayCell): string {
    if (cell.isPadding || cell.isFuture) {
      return 'transparent';
    }
    if (cell.completed === 5) {
      return this.colors.accentGold;
    }
    if (cell.completed >= 3) {
      return this.colors.tintMedium;
    }
    if (cell.completed >= 1) {
      return this.colors.tintSubtle;
    }
    return 'transparent';
  }

  private cellTextColor(cell: MonthDayCell): string {
    if (cell.isFuture) {
      return this.colors.textMuted;
    }
    if (cell.completed === 5) {
      return this.colors.textOnAccent;
    }
    if (cell.isToday) {
      return this.colors.accentGold;
    }
    if (cell.completed > 0) {
      return this.colors.accentGold;
    }
    return this.colors.textMuted;
  }

  build() {
    Stack() {
      Column() {
        this.TopBar()

        Scroll() {
          Row() {
            Column() {
              this.PeriodSelector()
              this.SummaryCard()
              this.PerPrayerCard()
              this.MonthHeatmapCard()
              Column().height(40)
            }
            .width('100%')
            .constraintSize({
              maxWidth: Breakpoints.maxContentWidth(this.breakpoint)
            })
            .padding({ left: 16, right: 16, top: 16 })
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
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.primaryGreen)
    .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
  }

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

      Text(this.tr('title_prayer_details'))
        .fontSize(22).fontWeight(FontWeight.Bold)
        .fontColor(this.colors.textWhite)
        .margin({ left: 16 })
    }
    .width('100%').height(72)
    .backgroundColor(this.colors.cardDark)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  PeriodSelector() {
    Row() {
      this.PeriodChip('week', this.tr('details_period_week'))
      this.PeriodChip('month', this.tr('details_period_month'))
      this.PeriodChip('year', this.tr('details_period_year'))
    }
    .width('100%')
    .padding(4)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(12)
    .border({ width: 1, color: this.colors.borderSoft })
    .margin({ bottom: 14 })
  }

  @Builder
  PeriodChip(id: string, label: string) {
    Text(label)
      .fontSize(13)
      .fontWeight(this.period === id ? FontWeight.Bold : FontWeight.Normal)
      .fontColor(this.period === id
        ? this.colors.textOnAccent : this.colors.textWhite)
      .backgroundColor(this.period === id
        ? this.colors.accentGold : Color.Transparent)
      .textAlign(TextAlign.Center)
      .height(38)
      .layoutWeight(1)
      .borderRadius(9)
      .onClick(() => {
        this.period = id as Period;
      })
  }

  @Builder
  SummaryCard() {
    Column() {
      Row() {
        Column() {
          Row() {
            Text(`${this.totalForPeriod()}`)
              .fontSize(48).fontWeight(FontWeight.Bold)
              .fontColor(this.colors.textWhite)
            Text(` / ${this.possibleForPeriod()}`)
              .fontSize(20).fontColor(this.colors.textMuted)
              .margin({ left: 4, bottom: 8 })
          }
          .alignItems(VerticalAlign.Bottom)

          Text(this.tr('details_prayers_completed'))
            .fontSize(12).fontColor(this.colors.textMuted)
            .margin({ top: -4 })
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        Stack() {
          Circle()
            .width(72)
            .height(72)
            .fill(Color.Transparent)
            .stroke(this.colors.tintMedium)
            .strokeWidth(6)
          Circle()
            .width(72)
            .height(72)
            .fill(Color.Transparent)
            .stroke(this.colors.accentGold)
            .strokeWidth(6)
            .strokeDashArray([
              this.percentForPeriod() / 100 * 226.2, 500
            ])
            .strokeLineCap(LineCapStyle.Round)
            .rotate({ angle: -90 })
          Text(`${this.percentForPeriod()}%`)
            .fontSize(15).fontWeight(FontWeight.Bold)
            .fontColor(this.colors.textWhite)
        }
        .width(72).height(72)
      }
      .width('100%')

      Row() {
        Row() {
          Text('🔥').fontSize(16).margin({ right: 6 })
          Column() {
            Row() {
              Text(`${this.snapshot.currentStreak}`)
                .fontSize(18).fontWeight(FontWeight.Bold)
                .fontColor(this.colors.accentGold)
              Text(` ${this.tr('home_days')}`)
                .fontSize(10).fontColor(this.colors.textMuted)
                .margin({ left: 2, bottom: 3 })
            }.alignItems(VerticalAlign.Bottom)

            Text(this.tr('home_streak'))
              .fontSize(10).fontColor(this.colors.textMuted)
          }
          .alignItems(HorizontalAlign.Start).margin({ left: 6 })
        }
        .layoutWeight(1)

        Divider().vertical(true).height(36).color(this.colors.borderSoft)

        Row() {
          Text('🏆').fontSize(16).margin({ right: 6 })
          Column() {
            Row() {
              Text(`${this.snapshot.bestStreak}`)
                .fontSize(18).fontWeight(FontWeight.Bold)
                .fontColor(this.colors.accentGoldLight)
              Text(` ${this.tr('home_days')}`)
                .fontSize(10).fontColor(this.colors.textMuted)
                .margin({ left: 2, bottom: 3 })
            }.alignItems(VerticalAlign.Bottom)

            Text(this.tr('details_best_streak'))
              .fontSize(10).fontColor(this.colors.textMuted)
          }
          .alignItems(HorizontalAlign.Start).margin({ left: 6 })
        }
        .layoutWeight(1).padding({ left: 12 })
      }
      .width('100%').margin({ top: 18 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(18)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(Theme.radiusLarge)
    .border({ width: 1, color: this.colors.borderSoft })
    .shadow({
      radius: 12,
      color: this.colors.shadowCard,
      offsetX: 0,
      offsetY: 4
    })
    .margin({ bottom: 14 })
  }

  @Builder
  PerPrayerCard() {
    Column() {
      Text(this.tr('details_per_prayer'))
        .fontSize(11)
        .fontColor(this.colors.accentGold)
        .fontWeight(FontWeight.Bold)
        .letterSpacing(1.2)
        .width('100%')
        .padding({ bottom: 12 })

      this.PrayerRow('fajr', this.perPrayerForPeriod().fajr, this.prayerLabel('fajr'))
      this.PrayerRow('dhuhr', this.perPrayerForPeriod().dhuhr, this.prayerLabel('dhuhr'))
      this.PrayerRow('asr', this.perPrayerForPeriod().asr, this.prayerLabel('asr'))
      this.PrayerRow('maghrib', this.perPrayerForPeriod().maghrib, this.prayerLabel('maghrib'))
      this.PrayerRow('isha', this.perPrayerForPeriod().isha, this.prayerLabel('isha'))
    }
    .width('100%')
    .padding(18)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(Theme.radiusLarge)
    .border({ width: 1, color: this.colors.borderSoft })
    .shadow({
      radius: 12,
      color: this.colors.shadowCard,
      offsetX: 0,
      offsetY: 4
    })
    .margin({ bottom: 14 })
  }

  @Builder
  PrayerRow(id: string, count: number, label: string) {
    Column() {
      Row() {
        Text(label)
          .fontSize(14).fontColor(this.colors.textWhite)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
        Text(`${count} / ${this.periodPossible()}`)
          .fontSize(13).fontColor(this.colors.accentGold)
          .fontWeight(FontWeight.Bold)
          .direction(Direction.Ltr)
      }
      .width('100%')

      Row() {
        Row()
          .width(`${this.periodPossible() > 0
            ? Math.round(count / this.periodPossible() * 100) : 0}%`)
          .height(6)
          .backgroundColor(this.colors.accentGold)
          .borderRadius(3)
      }
      .width('100%')
      .height(6)
      .backgroundColor(this.colors.tintMedium)
      .borderRadius(3)
      .margin({ top: 6 })
    }
    .width('100%')
    .margin({ bottom: 12 })
  }

  private periodPossible(): number {
    if (this.period === 'month') {
      return this.snapshot.monthProgress.daysElapsed;
    }
    if (this.period === 'year') {
      return Math.max(1, Math.round(this.snapshot.yearPossible / 5));
    }
    return 7;
  }

  @Builder
  MonthHeatmapCard() {
    Column() {
      Row() {
        Text('📊').fontSize(14).margin({ right: 8 })
        Text(this.tr('details_this_month'))
          .fontSize(12)
          .fontColor(this.colors.textMuted)
          .fontWeight(FontWeight.Bold)
          .letterSpacing(1.2)
          .layoutWeight(1)
        Text(ProgressHelper.formatGregorianMonth(
          this.snapshot.monthProgress.year,
          this.snapshot.monthProgress.monthIndex,
          this.appLanguage
        ))
          .fontSize(12).fontColor(this.colors.accentGold)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%').padding({ bottom: 14 })

      Column() {
        ForEach(this.snapshot.monthProgress.weeks, (week: MonthDayCell[], wi: number) => {
          Row() {
            ForEach(week, (cell: MonthDayCell, di: number) => {
              if (cell.isPadding) {
                Column().layoutWeight(1).height(32).margin({ left: 2, right: 2 })
              } else {
                Column() {
                  Text(`${cell.dayOfMonth}`)
                    .fontSize(12)
                    .fontWeight(cell.isToday ? FontWeight.Bold : FontWeight.Normal)
                    .fontColor(this.cellTextColor(cell))
                    .opacity(cell.isFuture ? 0.45 : 1.0)
                }
                .layoutWeight(1)
                .height(32)
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .backgroundColor(this.cellBg(cell))
                .borderRadius(8)
                .border({
                  width: cell.isToday ? 2 : 0,
                  color: this.colors.accentGold
                })
                .margin({ left: 2, right: 2 })
              }
            }, (cell: MonthDayCell, di: number) =>
            `d-${wi}-${di}-${cell.dayOfMonth}-${cell.completed}-${cell.isToday ? 'T' : ''}`)
          }
          .width('100%').margin({ bottom: 4 })
        }, (week: MonthDayCell[], wi: number) => {
          let sig = '';
          for (const c of week) {
            sig += c.completed;
          }
          return `dw-${wi}-${this.snapshot.monthProgress.year}-${this.snapshot.monthProgress.monthIndex}-${sig}`;
        })
      }
      .width('100%').direction(Direction.Ltr)

      Row() {
        Text(`${this.snapshot.monthProgress.perfectDays}`)
          .fontSize(18).fontWeight(FontWeight.Bold)
          .fontColor(this.colors.accentGold)
        Text(`  ${this.tr('details_perfect_days')}`)
          .fontSize(11).fontColor(this.colors.textMuted)
          .margin({ left: 6, bottom: 2 })
      }
      .width('100%').margin({ top: 14 })
      .alignItems(VerticalAlign.Bottom)
    }
    .width('100%')
    .padding(18)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(Theme.radiusLarge)
    .border({ width: 1, color: this.colors.borderSoft })
    .shadow({
      radius: 12,
      color: this.colors.shadowCard,
      offsetX: 0,
      offsetY: 4
    })
  }
}