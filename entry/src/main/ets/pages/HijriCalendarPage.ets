// entry/src/main/ets/pages/HijriCalendarPage.ets

import { mediaquery } from '@kit.ArkUI';
import { Theme, ThemeColors, ThemeMode, ThemePreset } from '../common/Theme';
import { PageTheme } from '../common/PageTheme';
import {
  STORAGE_KEY_APP_FOREGROUND_TICK,
  STORAGE_KEY_APP_THEME,
  STORAGE_KEY_BREAKPOINT,
  STORAGE_KEY_HIJRI_CALENDAR_TYPE,
  STORAGE_KEY_HIJRI_OFFSET,
  STORAGE_KEY_LANGUAGE,
  STORAGE_KEY_THEME_MODE
} from '../common/StorageKeys';
import { CalendarDay, HijriDate } from '../hijricalendar/HijriCalendarModels';
import { IslamicEvent } from '../models/DateModels';
import { HijriCalendarHelper } from '../hijricalendar/HijriCalendarHelper';
import { L } from '../helper/LocalizationHelper';
import { Breakpoints } from '../common/Breakpoints';
import { HijriCalendarType } from '../hijricalendar/HijriCalendarType';
import { SettingsHelper } from '../helper/SettingsHelper';

@Component
export struct HijriCalendarPage {

  @StorageLink(STORAGE_KEY_THEME_MODE)
  @Watch('onThemeModeChanged')
  themeMode: string = ThemeMode.SYSTEM;

  @StorageLink(STORAGE_KEY_HIJRI_OFFSET)
  @Watch('onHijriOffsetChanged')
  offsetDays: number = 0;

  @StorageLink(STORAGE_KEY_LANGUAGE)
  @Watch('onLanguageChanged')
  appLanguage: string = 'en';
  @StorageLink(STORAGE_KEY_APP_THEME)
  @Watch('onAppThemePresetChanged')
  appThemePreset: string = ThemePreset.SIRAT;

  @StorageLink(STORAGE_KEY_APP_FOREGROUND_TICK)
  @Watch('onAppForegrounded')
  appForegroundTick: number = 0;

  @StorageLink(STORAGE_KEY_BREAKPOINT)
  breakpoint: string = 'sm';
  @StorageLink(STORAGE_KEY_HIJRI_CALENDAR_TYPE)
  @Watch('onCalendarTypeChanged')
  hijriCalendarType: string = HijriCalendarType.UMM_AL_QURA;

  @State private currentLanguage: string = 'en';
  @State colors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);


  @State viewingHijriYear: number = 1447;
  @State viewingHijriMonth: number = 1;
  @State monthDays: CalendarDay[] = [];
  private systemDarkListener: mediaquery.MediaQueryListener | null = null;

  private tr(key: string): string {
    return L.get(key, this.currentLanguage);
  }

  private trArray(key: string): string[] {
    return L.getArray(key, this.currentLanguage);
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

  private onHijriOffsetChanged(): void {
    this.jumpToToday();
  }

  private onLanguageChanged(): void {
    this.currentLanguage = this.appLanguage;
  }

  private onCalendarTypeChanged(): void {
    this.jumpToToday();
  }

  private onAppForegrounded(): void {
    const today = new Date();
    const h: HijriDate = HijriCalendarHelper.getHijriDate(today, this.offsetDays);
    if (h.year !== this.viewingHijriYear || h.month !== this.viewingHijriMonth) {
      this.jumpToToday();
    } else {
      this.rebuildFromAnchor(today);
    }
  }

  aboutToAppear(): void {
    this.currentLanguage = this.appLanguage;
    this.colors = PageTheme.compute(this.themeMode);
    this.systemDarkListener = PageTheme.installSystemListener(this.themeMode, (c) => {
      this.colors = c;
    });
    this.jumpToToday();
  }

  aboutToDisappear(): void {
    PageTheme.uninstallSystemListener(this.systemDarkListener);
    this.systemDarkListener = null;
  }

  onPageShow(): void {
    this.currentLanguage = this.appLanguage;
    this.colors = PageTheme.compute(this.themeMode);
  }

  private jumpToToday(): void {
    const today = new Date();
    const h: HijriDate = HijriCalendarHelper.getHijriDate(today, this.offsetDays);
    this.viewingHijriYear = h.year;
    this.viewingHijriMonth = h.month;
    this.rebuildFromAnchor(today);
  }

  private rebuildFromAnchor(anchor: Date): void {
    this.monthDays = HijriCalendarHelper.buildMonthDays(
      this.viewingHijriYear, this.viewingHijriMonth, this.offsetDays, anchor
    );
  }

  private navigate(delta: number): void {
    const shifted = HijriCalendarHelper.shiftMonth(
      this.viewingHijriYear, this.viewingHijriMonth, delta
    );
    const anchor = this.monthDays.length > 0 ? this.monthDays[0].gregorianDate : new Date();
    this.viewingHijriYear = shifted.year;
    this.viewingHijriMonth = shifted.month;
    this.rebuildFromAnchor(anchor);
  }

  private getMonthEvents(): IslamicEvent[] {
    return HijriCalendarHelper.eventsInMonth(this.viewingHijriMonth);
  }

  private getLocalizedMonthName(): string {
    const names = this.trArray('hijri_months');
    return names[this.viewingHijriMonth - 1] || HijriCalendarHelper.monthName(this.viewingHijriMonth);
  }

  private getLocalizedDaysOfWeek(): string[] {
    return this.trArray('days_of_week');
  }

  private translateEventName(e: IslamicEvent): string {
    if (e.key && e.key.length > 0) {
      const translated = this.tr('event_' + e.key);
      if (translated !== 'event_' + e.key) return translated;
    }
    return e.name;
  }

  private buildPaddedWeeks(): Array<Array<CalendarDay | null>> {
    const days = this.monthDays;
    if (days.length === 0) return [];

    const weeks: Array<Array<CalendarDay | null>> = [];
    let current: Array<CalendarDay | null> = [];

    const firstDow = days[0].gregorianDate.getDay();
    for (let i = 0; i < firstDow; i++) current.push(null);

    for (const d of days) {
      current.push(d);
      if (current.length === 7) {
        weeks.push(current);
        current = [];
      }
    }
    if (current.length > 0) {
      while (current.length < 7) current.push(null);
      weeks.push(current);
    }
    return weeks;
  }

  build() {
    Stack() {
      Column() {
        // if (deviceInfo.sdkApiVersion < 23) {
        //   Column().height(72)
        // }
        Scroll() {
          Row() {
            Column() {
              this.MonthHeader()
              this.WeekdayRow()
              this.Grid()
              this.EventsList()
              Column().height(130)
            }
            .width('100%')
            .constraintSize({ maxWidth: Breakpoints.maxContentWidth(this.breakpoint) })
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
    }
    .width('100%').height('100%')
    .backgroundColor(this.colors.primaryGreen)
    .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
  }

  @Builder
  MonthHeader() {
    Column() {
      Row() {
        Text('◀')
          .fontSize(16)
          .fontColor(this.colors.accentGold)
          .width(40).height(40).textAlign(TextAlign.Center)
          .borderRadius(20).backgroundColor(this.colors.tintSoft)
          .border({ width: 1, color: this.colors.borderSoft })
          .onClick(() => { this.navigate(-1); })

        Column() {
          Text(this.getLocalizedMonthName())
            .fontSize(22).fontWeight(FontWeight.Bold)
            .fontColor(this.colors.textWhite)
            .textAlign(TextAlign.Center)
            .width('100%')
          Row() {
            Text(`${this.viewingHijriYear} AH`)
              .fontSize(13).fontColor(this.colors.accentGold)

            Text('·')
              .fontSize(11).fontColor(this.colors.textMuted)
              .margin({ left: 6, right: 6 })

            Text(SettingsHelper.getHijriCalendarTypeLabel(this.hijriCalendarType))
              .fontSize(11)
              .fontColor(this.colors.accentGold)
              .fontWeight(FontWeight.Medium)
          }
          .justifyContent(FlexAlign.Center)
          .width('100%')
          .margin({ top: 2 })
          Text(HijriCalendarHelper.formatGregorianSpan(this.monthDays))
            .fontSize(11).fontColor(this.colors.textMuted)
            .textAlign(TextAlign.Center).width('100%').margin({ top: 4 })
        }
        .layoutWeight(1).alignItems(HorizontalAlign.Center)

        Text('▶')
          .fontSize(16)
          .fontColor(this.colors.accentGold)
          .width(40).height(40).textAlign(TextAlign.Center)
          .borderRadius(20).backgroundColor(this.colors.tintSoft)
          .border({ width: 1, color: this.colors.borderSoft })
          .onClick(() => { this.navigate(1); })
      }
      .width('100%').alignItems(VerticalAlign.Center)
      .direction(Direction.Ltr)
    }
    .width('100%').padding({ top: 8, bottom: 16 })
  }

  @Builder
  WeekdayRow() {
    Row() {
      ForEach(this.getLocalizedDaysOfWeek(), (d: string, i: number) => {
        Text(d)
          .fontSize(11)
          .fontWeight(i === 5 ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(i === 5 ? this.colors.accentGold : this.colors.textMuted)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
      }, (d: string) => `dow-${d}`)
    }
    .width('100%').padding({ bottom: 6 }).direction(Direction.Ltr)
  }

  @Builder
  Grid() {
    Column() {
      ForEach(this.buildPaddedWeeks(), (week: Array<CalendarDay | null>, wi: number) => {
        Row() {
          ForEach(week, (cell: CalendarDay | null, di: number) => {
            if (cell !== null) {
              this.DayCell(cell)
            } else {
              Column().layoutWeight(1).height(56).margin({ left: 2, right: 2 })
            }
          }, (cell: CalendarDay | null, di: number) => {
            const key = cell !== null
              ? `${cell.hijri.year}-${cell.hijri.month}-${cell.hijri.day}`
              : `empty-${wi}-${di}`;
            return `cell-${key}`;
          })
        }
        .width('100%').margin({ bottom: 4 })
      }, (week: Array<CalendarDay | null>, wi: number) =>
      `week-${wi}-${this.viewingHijriYear}-${this.viewingHijriMonth}-${this.offsetDays}`)
    }
    .width('100%')
    .padding(8)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(Theme.radiusMedium)
    .border({ width: 1, color: this.colors.borderSoft })
    .direction(Direction.Ltr)
  }

  @Builder
  DayCell(cell: CalendarDay) {
    Column() {
      Text(`${cell.hijri.day}`)
        .fontSize(17)
        .fontWeight(cell.isToday ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(cell.isToday ? this.colors.textOnAccent
          : (cell.events.length > 0 ? this.colors.accentGold : this.colors.textWhite))

      Text(`${cell.gregorianDate.getDate()}`)
        .fontSize(10)
        .fontColor(cell.isToday ? this.colors.textOnAccent : this.colors.textMuted)
        .opacity(cell.isToday ? 0.85 : 0.7).margin({ top: -2 })

      if (cell.events.length > 0 && !cell.isToday) {
        Row()
          .width(5)
          .height(5)
          .borderRadius(3)
          .backgroundColor(this.colors.accentGold)
          .margin({ top: 3 })
      } else if (cell.events.length > 0 && cell.isToday) {
        Row()
          .width(5)
          .height(5)
          .borderRadius(3)
          .backgroundColor(this.colors.textOnAccent)
          .margin({ top: 3 })
      } else {
        Row().width(5).height(5).margin({ top: 3 })
      }
    }
    .layoutWeight(1)
    .height(56)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(cell.isToday ? this.colors.accentGold
      : (cell.isFriday ? this.colors.tintSubtle : Color.Transparent))
    .borderRadius(10)
    .border(cell.isFriday && !cell.isToday
      ? { width: 1, color: this.colors.borderSoft } : { width: 0 })
    .margin({ left: 2, right: 2 })
  }

  @Builder
  EventsList() {
    Column() {
      Row() {
        Text('📅').fontSize(14)
          .margin({ left: this.isRtl() ? 8 : 0, right: this.isRtl() ? 0 : 8 })
        Text(this.tr('important_dates'))
          .fontSize(12).fontColor(this.colors.accentGold)
          .fontWeight(FontWeight.Bold).letterSpacing(1.2)
      }
      .width('100%').padding({ bottom: 12 })

      if (this.getMonthEvents().length === 0) {
        Text(this.tr('no_events_this_month'))
          .fontSize(13).fontColor(this.colors.textMuted)
          .width('100%').padding({ top: 4, bottom: 4 })
      } else {
        ForEach(this.getMonthEvents(), (e: IslamicEvent) => {
          Row() {
            Text(`${e.day}`)
              .fontSize(16).fontWeight(FontWeight.Bold)
              .fontColor(this.colors.accentGold)
              .width(36)
              .textAlign(TextAlign.Center)
            Text(this.translateEventName(e))
              .fontSize(14).fontColor(this.colors.textWhite).layoutWeight(1)
          }
          .width('100%')
          .padding({
            top: 10,
            bottom: 10,
            left: 4,
            right: 8
          })
          .borderRadius(8)
          .margin({ bottom: 4 })
          .backgroundColor(this.colors.tintSubtle)
        }, (e: IslamicEvent) => `event-${e.month}-${e.day}-${e.name}`)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(Theme.radiusMedium)
    .border({ width: 1, color: this.colors.borderSoft })
    .margin({ top: 16 })
    .alignItems(HorizontalAlign.Start)
  }
}