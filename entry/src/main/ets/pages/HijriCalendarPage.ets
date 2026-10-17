// entry/src/main/ets/pages/HijriCalendarPage.ets

import { mediaquery } from '@kit.ArkUI';
import { Theme, ThemeColors, ThemeMode, ThemePreset } from '../common/Theme';
import { PageTheme } from '../common/PageTheme';
import {
  STORAGE_KEY_APP_FOREGROUND_TICK,
  STORAGE_KEY_APP_THEME,
  STORAGE_KEY_BREAKPOINT,
  STORAGE_KEY_EVENT_SETTINGS_VERSION,
  STORAGE_KEY_HIJRI_CALENDAR_TYPE,
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
import { EventPerspectiveNotifier } from '../utils/EventPerspectiveNotifier';
import { CalendarDayCell } from '../components/CalendarDayCell';

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
  @StorageLink(STORAGE_KEY_EVENT_SETTINGS_VERSION)
  @Watch('onEventSettingsChanged')
  eventSettingsVersion: number = 0;

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
  @State private monthEvents: IslamicEvent[] = [];

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

  private onEventSettingsChanged(): void {
    this.rebuildFromAnchor(this.monthDays.length > 0
      ? this.monthDays[0].gregorianDate
      : new Date());
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

  private eventPerspectiveListener: () => void = (): void => {
    this.rebuildFromAnchor(
      this.monthDays.length > 0
        ? this.monthDays[0].gregorianDate
        : new Date()
    );
  };

  aboutToAppear(): void {
    this.currentLanguage = this.appLanguage;
    this.colors = PageTheme.compute(this.themeMode);
    this.systemDarkListener = PageTheme.installSystemListener(this.themeMode, (c) => {
      this.colors = c;
    });
    this.jumpToToday();
    EventPerspectiveNotifier.subscribe(this.eventPerspectiveListener);
  }

  aboutToDisappear(): void {
    PageTheme.uninstallSystemListener(this.systemDarkListener);
    this.systemDarkListener = null;
  }

  onPageShow(): void {
    this.currentLanguage = this.appLanguage;
    this.colors = PageTheme.compute(this.themeMode);
    EventPerspectiveNotifier.unsubscribe(this.eventPerspectiveListener);
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
      this.viewingHijriYear, this.viewingHijriMonth,
      this.offsetDays, anchor, SettingsHelper.getEventPerspective()
    );
    this.monthEvents = HijriCalendarHelper.eventsInMonth(
      this.viewingHijriMonth, SettingsHelper.getEventPerspective()
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
      this.viewingHijriMonth, SettingsHelper.getEventPerspective()
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

  private translateEventSignificance(key: string): string {
    const descKey = 'event_' + key + '_desc';
    const translated = this.tr(descKey);
    return translated === descKey ? '' : translated;
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
      ForEach(this.buildPaddedWeeks(),
        (week: Array<CalendarDay | null>, wi: number) => {
          Row() {
            ForEach(week, (cell: CalendarDay | null, di: number) => {
              if (cell !== null) {
                CalendarDayCell({
                  cell: cell,
                  colors: this.colors
                })
              } else {
                Column()
                  .layoutWeight(1)
                  .height(56)
                  .margin({ left: 2, right: 2 })
              }
            }, (cell: CalendarDay | null, di: number) => {
              if (cell === null) {
                return `empty-${wi}-${di}`;
              }
              // Include the event count so a cell rebuilds when its
              // events change, even though the date is unchanged.
              return `cell-${cell.hijri.year}-${cell.hijri.month}-${cell.hijri.day}-${cell.events.length}`;
            })
          }
          .width('100%')
          .margin({ bottom: 4 })
        },
        (week: Array<CalendarDay | null>, wi: number) => {
          // Event signature across the row. Forces the row to rebuild
          // whenever any cell's event list changes.
          let sig = '';
          for (const c of week) {
            sig += c === null ? '_' : c.events.length;
          }
          return `week-${wi}-${this.viewingHijriYear}-${this.viewingHijriMonth}-${this.offsetDays}-${sig}`;
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
  EventsList() {
    Column() {
      Row() {
        Text('📅').fontSize(14)
          .margin({
            left: this.isRtl() ? 8 : 0,
            right: this.isRtl() ? 0 : 8
          })
        Text(this.tr('important_dates'))
          .fontSize(12).fontColor(this.colors.accentGold)
          .fontWeight(FontWeight.Bold).letterSpacing(1.2)
      }
      .width('100%').padding({ bottom: 12 })

      if (this.monthEvents.length === 0) {
        Text(this.tr('no_events_this_month'))
          .fontSize(13).fontColor(this.colors.textMuted)
          .width('100%').padding({ top: 4, bottom: 4 })
      } else {
        ForEach(this.monthEvents, (e: IslamicEvent) => {
          Row() {
            Text(`${e.day}`)
              .fontSize(16).fontWeight(FontWeight.Bold)
              .fontColor(this.colors.accentGold)
              .width(36)
              .textAlign(TextAlign.Center)
              .margin({ top: 2 })

            Column() {
              Text(this.translateEventName(e))
                .fontSize(14).fontColor(this.colors.textWhite)
                .width('100%')

              if (this.translateEventSignificance(e.key).length > 0) {
                Text(this.translateEventSignificance(e.key))
                  .fontSize(11)
                  .fontColor(this.colors.textMuted)
                  .lineHeight(15)
                  .maxLines(3)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: 4 })
                  .width('100%')
              }
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
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
          .alignItems(VerticalAlign.Top)
        }, (e: IslamicEvent) => `event-${e.key}`)
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