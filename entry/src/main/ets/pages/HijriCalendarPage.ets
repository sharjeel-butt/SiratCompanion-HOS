// entry/src/main/ets/pages/HijriCalendarPage.ets

import { mediaquery } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { Theme, ThemeColors, ThemeMode, ThemePreset } from '../common/Theme';
import { PageTheme } from '../common/PageTheme';
import {
  STORAGE_KEY_APP_FOREGROUND_TICK,
  STORAGE_KEY_APP_THEME,
  STORAGE_KEY_BREAKPOINT,
  STORAGE_KEY_EVENT_SETTINGS_VERSION,
  STORAGE_KEY_HIJRI_CALENDAR_TYPE,
  STORAGE_KEY_HIJRI_CALENDAR_VERSION,
  STORAGE_KEY_HIJRI_OFFSET,
  STORAGE_KEY_LANGUAGE,
  STORAGE_KEY_THEME_MODE
} from '../common/StorageKeys';
import { CalendarDay, HijriDate } from '../hijricalendar/HijriCalendarModels';
import { IslamicEvent } from '../models/DateModels';
import { HijriCalendarHelper } from '../hijricalendar/HijriCalendarHelper';
import { L } from '../i8n/LocalizationHelper';
import { Breakpoints } from '../common/Breakpoints';
import { HijriCalendarType } from '../hijricalendar/HijriCalendarType';
import { SettingsHelper } from '../helper/SettingsHelper';
import { PdfExportHelper } from '../utils/PdfExportHelper';
import { EventPerspectiveNotifier } from '../utils/EventPerspectiveNotifier';

// Interface for PDF Export
export interface CalendarExportDay {
  hijriDay: string;
  gregorianDay: string;
  hasEvents: boolean;
  dayOfWeek: number;
}

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
  @State currentLanguage: string = 'en';
  @StorageLink(STORAGE_KEY_HIJRI_CALENDAR_VERSION)
  @Watch('onCalendarVersionChanged')
  calendarVersion: number = 0;
  @StorageLink(STORAGE_KEY_EVENT_SETTINGS_VERSION)
  @Watch('onEventSettingsVersionChanged')
  eventSettingsVersion: number = 0;


  @State colors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);

  @State viewingHijriYear: number = 1447;
  @State viewingHijriMonth: number = 1;
  @State monthDays: CalendarDay[] = [];
  private systemDarkListener: mediaquery.MediaQueryListener | null = null;
  // Export States
  @State isExporting: boolean = false;
  @State pdfWeeks: Array<Array<CalendarExportDay | null>> = [];
  @State pdfColors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);

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

  private onEventSettingsVersionChanged(): void {
    if (this.monthDays.length > 0) {
      this.rebuildFromAnchor(this.monthDays[0].gregorianDate);
    } else {
      this.jumpToToday();
    }
  }

  private eventPerspectiveListener: () => void = (): void => {
    if (this.monthDays.length > 0) {
      // Rebuild the currently viewed month
      this.rebuildFromAnchor(this.monthDays[0].gregorianDate);
    } else {
      this.jumpToToday();
    }
  };


  // ============================================================
  // WEEKEND LOGIC
  // ============================================================
  private isWeekend(dayOfWeek: number): boolean {
    const weekendDays = L.getArray('weekend_days', this.appLanguage);
    if (weekendDays && weekendDays.length > 0) {
      for (let i = 0; i < weekendDays.length; i++) {
        if (parseInt(weekendDays[i], 10) === dayOfWeek) {
          return true;
        }
      }
      return false;
    }
    if (this.appLanguage === 'ar') {
      return dayOfWeek === 5 || dayOfWeek === 6;
    }
    return dayOfWeek === 0 || dayOfWeek === 6;
  }

  private onCalendarVersionChanged(): void {
    this.jumpToToday();
  }


  // ============================================================
  // LIFECYCLE
  // ============================================================
  aboutToAppear(): void {
    this.currentLanguage = this.appLanguage;
    this.colors = PageTheme.compute(this.themeMode);
    this.systemDarkListener = PageTheme.installSystemListener(this.themeMode, (c) => {
      this.colors = c;
    });
    EventPerspectiveNotifier.subscribe(this.eventPerspectiveListener);
    this.jumpToToday();
  }

  aboutToDisappear(): void {
    EventPerspectiveNotifier.unsubscribe(this.eventPerspectiveListener);
    PageTheme.uninstallSystemListener(this.systemDarkListener);
    this.systemDarkListener = null;
  }

  onPageShow(): void {
    this.currentLanguage = this.appLanguage;
    this.colors = PageTheme.compute(this.themeMode);
    if (this.monthDays.length > 0) {
      this.rebuildFromAnchor(this.monthDays[0].gregorianDate);
    } else {
      this.jumpToToday();
    }
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
    if (this.monthDays.length > 0) {
      this.rebuildFromAnchor(this.monthDays[0].gregorianDate);
    } else {
      this.jumpToToday();
    }
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
    return HijriCalendarHelper.eventsInMonth(
      this.viewingHijriMonth,
      SettingsHelper.getEventPerspective() // Read directly, not from a stale @State
    );
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

  // ============================================================
  // EXPORT PDF LOGIC
  // ============================================================
  private getGregorianMonthName(): string {
    if (this.monthDays.length === 0) {
      return '';
    }
    const d = this.monthDays[0].gregorianDate;
    const locale = this.appLanguage === 'zh' ? 'zh-CN' : (this.appLanguage === 'ar' ? 'ar' : 'en-US');
    return d.toLocaleString(locale, { month: 'long', year: 'numeric' });
  }

  private async handleExport(): Promise<void> {
    if (this.isExporting || this.monthDays.length === 0) {
      return;
    }
    this.isExporting = true;
    this.pdfWeeks = [];
    this.pdfColors = PageTheme.compute(ThemeMode.LIGHT);

    try {
      const padded = this.buildPaddedWeeks();
      const exportWeeks: Array<Array<CalendarExportDay | null>> = [];

      for (let w = 0; w < padded.length; w++) {
        const week = padded[w];
        const rw: Array<CalendarExportDay | null> = [];
        for (let d = 0; d < week.length; d++) {
          const cell = week[d];
          if (cell === null) {
            rw.push(null);
          } else {
            rw.push({
              hijriDay: `${cell.hijri.day}`,
              gregorianDay: `${cell.gregorianDate.getDate()}`,
              hasEvents: cell.events.length > 0,
              dayOfWeek: cell.gregorianDate.getDay()
            });
          }
        }
        exportWeeks.push(rw);
      }

      this.pdfWeeks = exportWeeks;

      const ctx = getContext(this) as common.UIAbilityContext;
      await new Promise<void>((resolve) => setTimeout(() => resolve(), 100));

      await PdfExportHelper.exportBuilderToPdf(
        ctx, this.getUIContext(), this.CalendarExportLayout.bind(this), 'Hijri_Calendar'
      );
    } catch (err) {
      console.error('Export failed', JSON.stringify(err));
    } finally {
      this.isExporting = false;
    }
  }

  // ============================================================
  // BUILD UI
  // ============================================================
  build() {
    Stack() {
      Column() {
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
            Text(`${this.viewingHijriYear} ${this.tr('hijri_year_suffix')}`)
              .fontSize(13).fontColor(this.colors.accentGold)

            Text('·')
              .fontSize(11).fontColor(this.colors.textMuted)
              .margin({ left: 6, right: 6 })

            Text(SettingsHelper.getHijriCalendarTypeLabel(this.hijriCalendarType, this.currentLanguage))
              .fontSize(11)
              .fontColor(this.colors.accentGold)
              .fontWeight(FontWeight.Medium)
          }
          .justifyContent(FlexAlign.Center)
          .width('100%')
          .margin({ top: 2 })

          Text(HijriCalendarHelper.formatGregorianSpan(this.monthDays, this.currentLanguage))
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

        if (this.isExporting) {
          LoadingProgress()
            .width(24).height(24)
            .color(this.colors.accentGold)
            .margin({ left: 12 })
        } else {
          Image($r('app.media.ic_printer'))
            .width(16)
            .height(16)
            .fillColor(this.colors.accentGold)
            .width(32)
            .height(32)
            .padding(8)
            .borderRadius(16)
            .backgroundColor(this.colors.cardDark)
            .border({ width: 1, color: this.colors.borderSoft })
            .margin({ right: 8 })
            .onClick(() => {
              this.handleExport();
            })
        }
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
            if (cell === null) {
              return `e-${wi}-${di}`;
            }
            return `c-${cell.hijri.year}-${cell.hijri.month}-${cell.hijri.day}` +
              `-${cell.isToday ? 'T' : 'f'}-${cell.events.length}`;
          })
        }
        .width('100%').margin({ bottom: 4 })
      }, (week: Array<CalendarDay | null>, wi: number) => {
        // Key encodes the week's actual Hijri data so that ANY change
        // (calendar type switch, offset, month navigation, event
        // perspective, today rollover) forces ArkUI to re-render the
        // week's cells. A key based only on `viewingHijriYear/Month`
        // is stable across calendar type changes and would leave the
        // grid showing the previous engine's dates.
        const parts: string[] = [];
        for (const cell of week) {
          if (cell === null) {
            parts.push('_');
          } else {
            parts.push(
              `${cell.hijri.year}-${cell.hijri.month}-${cell.hijri.day}-` +
                `${cell.isToday ? 'T' : 'f'}-${cell.events.length}`
            );
          }
        }
        return `w${wi}-${parts.join('|')}`;
      })
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
      : (this.isWeekend(cell.gregorianDate.getDay()) ? this.colors.tintSubtle : Color.Transparent))
    .borderRadius(10)
    .border(this.isWeekend(cell.gregorianDate.getDay()) && !cell.isToday
      ? { width: 1, color: this.colors.borderSoft } : { width: 0 })
    .margin({ left: 2, right: 2 })
  }

  @Builder
  EventsList() {
    Column() {
      Row() {
        Image($r('app.media.ic_nav_calendar'))
          .width(16).height(16)
          .fillColor(this.colors.accentGold)
          .margin({ left: this.isRtl() ? 8 : 0, right: this.isRtl() ? 0 : 8 })
        Text(this.tr('important_dates'))
          .fontSize(12).fontColor(this.colors.accentGold)
          .fontWeight(FontWeight.Bold).letterSpacing(1.5)
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

  // ============================================================
  // PDF BUILDER
  // ============================================================
  @Builder
  CalendarExportLayout() {
    Column() {
      // Header
      Row() {
        Image($r('app.media.foreground'))
          .syncLoad(true)
          .width(44)
          .height(44)
          .borderRadius(10)
          .margin({ right: 16 })

        Column() {
          // Localized Hijri Year Suffix
          Text(`${this.getLocalizedMonthName()} ${this.viewingHijriYear} ${this.tr('hijri_year_suffix')}`)
            .fontSize(24).fontWeight(FontWeight.Bold).fontColor(this.pdfColors.textWhite)

          Row() {
            Text(this.getLocalizedGregorianSpan())
              .fontSize(12).fontColor(this.pdfColors.accentGold).fontWeight(FontWeight.Medium)
            Text(' · ')
              .fontSize(12).fontColor(this.pdfColors.textMuted)
            Text(SettingsHelper.getHijriCalendarTypeLabel(this.hijriCalendarType, this.currentLanguage))
              .fontSize(12).fontColor(this.pdfColors.accentGold)
          }.margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        // Localized Footer
        Text(this.tr('generated_by'))
          .fontSize(9).fontColor(this.pdfColors.textMuted).alignSelf(ItemAlign.Start).margin({ top: 4 })
      }
      .width('100%')
      .padding({
        top: 30,
        bottom: 20,
        left: 24,
        right: 24
      })
      .backgroundColor(this.pdfColors.cardDark)

      Row().width('100%').height(4).backgroundColor(this.pdfColors.accentGold)

      // Calendar Grid (Using Row/Column to match padding)
      Column() {
        // Weekday Headers
        Row() {
          ForEach(this.getLocalizedDaysOfWeek(), (day: string) => {
            Text(day)
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.pdfColors.textMuted)
              .margin({ bottom: 6 })
          })
        }
        .width('100%')

        // Weeks
        ForEach(this.pdfWeeks, (week: Array<CalendarExportDay | null>, wi: number) => {
          Row() {
            ForEach(week, (day: CalendarExportDay | null, di: number) => {
              if (day === null) {
                Column().layoutWeight(1).height(55).margin({ left: 2, right: 2 })
              } else {
                Column() {
                  Text(day.hijriDay)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(day.hasEvents ? this.pdfColors.accentGold : this.pdfColors.textWhite)

                  Text(day.gregorianDay)
                    .fontSize(9)
                    .fontColor(this.pdfColors.textMuted)
                    .margin({ top: 2 })

                  if (day.hasEvents) {
                    Row()
                      .width(4)
                      .height(4)
                      .borderRadius(2)
                      .backgroundColor(this.pdfColors.accentGold)
                      .margin({ top: 3 })
                  }
                }
                .layoutWeight(1)
                .height(55)
                .justifyContent(FlexAlign.Center)
                .backgroundColor(this.isWeekend(day.dayOfWeek) ? this.pdfColors.tintSoft : Color.Transparent)
                .borderRadius(6)
                .border({ width: this.isWeekend(day.dayOfWeek) ? 1 : 0, color: this.pdfColors.borderSoft })
                .margin({ left: 2, right: 2 })
              }
            }, (day: CalendarExportDay | null, di: number) => `pdf-cell-${wi}-${di}`)
          }
          .width('100%')
          .margin({ bottom: 4 })
        }, (week: Array<CalendarExportDay | null>, wi: number) => `pdf-week-${wi}`)
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 10 })

      // Important Dates
      Column() {
        Text(this.tr('important_dates'))
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.pdfColors.accentGold)
          .width('100%')
          .margin({ bottom: 8 })

        if (this.getMonthEvents().length === 0) {
          Text(this.tr('no_events_this_month')).fontSize(10).fontColor(this.pdfColors.textMuted)
        } else {
          ForEach(this.getMonthEvents(), (e: IslamicEvent) => {
            Row() {
              Text(`${e.day}`)
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.pdfColors.accentGold)
                .width(24)
                .margin({ top: 2 })

              Column() {
                Text(this.translateEventName(e))
                  .fontSize(11)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.pdfColors.textWhite)
                Text(this.tr('event_' + e.key + '_desc'))
                  .fontSize(9)
                  .fontColor(this.pdfColors.textMuted)
                  .margin({ top: 2 })
                  .lineHeight(12)
              }.alignItems(HorizontalAlign.Start).layoutWeight(1)
            }
            .width('100%').padding({ top: 6, bottom: 6 }).alignItems(VerticalAlign.Top)
          })
        }
      }
      .width('100%')
      .padding(16)
      .layoutWeight(1)
      .backgroundColor(this.pdfColors.tintSubtle)
      .borderRadius(12)
      .margin({ left: 24, right: 24, bottom: 10 })
    }
    .width(595).height(842).backgroundColor(this.pdfColors.primaryGreen)
  }

  private getLocalizedGregorianSpan(): string {
    if (this.monthDays.length === 0) {
      return '';
    }
    const first = this.monthDays[0].gregorianDate;
    const last = this.monthDays[this.monthDays.length - 1].gregorianDate;

    const locale = this.appLanguage === 'zh' ? 'zh-CN' : (this.appLanguage === 'ar' ? 'ar' : 'en-US');

    // Format month names according to locale
    const firstMonth = first.toLocaleString(locale, { month: 'short' });
    const lastMonth = last.toLocaleString(locale, { month: 'short' });
    const year = last.getFullYear();

    if (first.getMonth() === last.getMonth() && first.getFullYear() === last.getFullYear()) {
      return `${firstMonth} ${first.getDate()} – ${last.getDate()}, ${year}`;
    }
    return `${firstMonth} ${first.getDate()} – ${lastMonth} ${last.getDate()}, ${year}`;
  }
}