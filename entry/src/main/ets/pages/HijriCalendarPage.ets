// entry/src/main/ets/pages/HijriCalendarPage.ets

import { mediaquery, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { Theme, ThemeColors, ThemeMode, ThemePreset } from '../common/Theme';
import { PageTheme } from '../common/PageTheme';
import { CustomEvent, RecurrenceType } from '../models/CustomEventModels';
import { CustomEventStorage } from '../helper/CustomEventStorage';
import { CustomEventNotifier } from '../helper/CustomEventNotifier';
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
  @State targetedDay: number = 0;
  @StorageLink('nav_target_hijri_day')
  @Watch('onNavTargetHijriDayChanged')
  navTargetHijriDay: number = 0;

  @State colors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);

  @State viewingHijriYear: number = 1447;
  @State viewingHijriMonth: number = 1;
  @State monthDays: CalendarDay[] = [];
  private systemDarkListener: mediaquery.MediaQueryListener | null = null;

  // Export States
  @State isExporting: boolean = false;
  @State pdfWeeks: Array<Array<CalendarExportDay | null>> = [];
  @State pdfColors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);
  @State customEvents: CustomEvent[] = [];
  // Add/Edit Event States
  @State showAddEventSheet: boolean = false;
  @State editingEventId: string = '';
  @State formTitle: string = '';
  @State formDateType: 'hijri' | 'gregorian' = 'hijri';
  @State formHijriMonth: string = '1';
  @State formHijriDay: string = '1';
  @State formHijriYear: string = '1447';
  @State formGregDay: string = '1';
  @State formGregMonth: string = '1';
  @State formGregYear: string = '2026';
  @State formNotify: boolean = true;
  @State formRecurrence: RecurrenceType = RecurrenceType.NONE;

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

  /**
   * Fires when Home taps a custom event. By this point year/month
   * have already been set by the same onClick handler (they are set
   * first, in order), so this is the single point where the full
   * target — year + month + day — is known to be complete.
   *
   * Handles the full navigation so it works even on SDK builds where
   * the Tabs host does not fire onPageShow() on tab switch.
   */
  private onNavTargetHijriDayChanged(): void {
    if (this.navTargetHijriDay <= 0) {
      return;
    }
    const year = AppStorage.get<number>('nav_target_hijri_year');
    const month = AppStorage.get<number>('nav_target_hijri_month');
    if (year === undefined || year <= 0 || month === undefined || month <= 0) {
      return;
    }

    this.viewingHijriYear = year;
    this.viewingHijriMonth = month;
    this.targetedDay = this.navTargetHijriDay;
    this.rebuildFromAnchor(new Date());

    // Clear all three so a subsequent onPageShow is idempotent
    // and does not re-trigger the navigation.
    AppStorage.setOrCreate('nav_target_hijri_year', 0);
    AppStorage.setOrCreate('nav_target_hijri_month', 0);
    AppStorage.setOrCreate('nav_target_hijri_day', 0);
  }

  private eventPerspectiveListener: () => void = (): void => {
    if (this.monthDays.length > 0) {
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
  async aboutToAppear(): Promise<void> {
    this.currentLanguage = this.appLanguage;
    this.colors = PageTheme.compute(this.themeMode);
    this.systemDarkListener = PageTheme.installSystemListener(this.themeMode, (c) => {
      this.colors = c;
    });
    EventPerspectiveNotifier.subscribe(this.eventPerspectiveListener);

    // Load events asynchronously before rebuilding the grid
    this.customEvents = await CustomEventStorage.load();

    // Apply any pending navigation target.
    //
    // The @Watch on nav_target_hijri_day cannot cover the FIRST
    // navigation from Home because TabContent is lazily built:
    // the Calendar page does not exist when HomePage sets the
    // target, so no Watch is registered to fire. When the page
    // finally mounts (tab switch), aboutToAppear is the only hook
    // that can see the still-set values and apply them.
    //
    // Clearing the target here is what makes subsequent navigations
    // fall through to the @Watch path — the value goes from 0 to N
    // instead of N to N (which would not fire a Watch).
    const targetYear = AppStorage.get<number>('nav_target_hijri_year');
    const targetMonth = AppStorage.get<number>('nav_target_hijri_month');
    const targetDay = AppStorage.get<number>('nav_target_hijri_day');

    if (targetYear !== undefined && targetYear > 0
      && targetMonth !== undefined && targetMonth > 0) {
      this.viewingHijriYear = targetYear;
      this.viewingHijriMonth = targetMonth;
      this.targetedDay = (targetDay !== undefined && targetDay > 0) ? targetDay : 0;
      this.rebuildFromAnchor(new Date());

      AppStorage.setOrCreate('nav_target_hijri_year', 0);
      AppStorage.setOrCreate('nav_target_hijri_month', 0);
      AppStorage.setOrCreate('nav_target_hijri_day', 0);
    } else {
      this.jumpToToday();
    }
  }

  aboutToDisappear(): void {
    EventPerspectiveNotifier.unsubscribe(this.eventPerspectiveListener);
    PageTheme.uninstallSystemListener(this.systemDarkListener);
    this.systemDarkListener = null;
  }

  onPageShow(): void {
    this.currentLanguage = this.appLanguage;
    this.colors = PageTheme.compute(this.themeMode);

    const targetYear = AppStorage.get<number>('nav_target_hijri_year');
    const targetMonth = AppStorage.get<number>('nav_target_hijri_month');
    const targetDay = AppStorage.get<number>('nav_target_hijri_day');

    if (targetYear !== undefined && targetYear > 0
      && targetMonth !== undefined && targetMonth > 0) {
      this.viewingHijriYear = targetYear;
      this.viewingHijriMonth = targetMonth;
      this.targetedDay = (targetDay !== undefined && targetDay > 0) ? targetDay : 0;
      this.rebuildFromAnchor(new Date());

      AppStorage.setOrCreate('nav_target_hijri_year', 0);
      AppStorage.setOrCreate('nav_target_hijri_month', 0);
      AppStorage.setOrCreate('nav_target_hijri_day', 0);
    } else {
      if (this.monthDays.length > 0) {
        this.rebuildFromAnchor(this.monthDays[0].gregorianDate);
      } else {
        this.jumpToToday();
      }
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

  private dayCellBorder(cell: CalendarDay): BorderOptions {
    // Priority 1 — targeted day from Home navigation (2 px ring).
    // Skipped on today because the background is already gold.
    if (this.targetedDay > 0
      && cell.hijri.day === this.targetedDay
      && !cell.isToday) {
      return { width: 2, color: this.colors.accentGold };
    }
    // Priority 2 — today has a filled background, no border.
    if (cell.isToday) {
      return { width: 0 };
    }
    // Priority 3 — weekend tint gets a subtle border.
    if (this.isWeekend(cell.gregorianDate.getDay())) {
      return { width: 1, color: this.colors.borderSoft };
    }
    return { width: 0 };
  }

  private jumpToToday(): void {
    this.targetedDay = 0;
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

  private eventMatchesDay(ev: CustomEvent, day: CalendarDay): boolean {
    const rec = ev.recurrence || RecurrenceType.NONE;

    if (rec === RecurrenceType.NONE) {
      return day.hijri.year === ev.hijriYear && day.hijri.month === ev.hijriMonth && day.hijri.day === ev.hijriDay;
    }
    if (rec === RecurrenceType.YEARLY) {
      return day.hijri.month === ev.hijriMonth && day.hijri.day === ev.hijriDay;
    }
    if (rec === RecurrenceType.MONTHLY) {
      return day.hijri.day === ev.hijriDay;
    }
    if (rec === RecurrenceType.WEEKLY) {
      return day.gregorianDate.getDay() === (ev.gregorianDayOfWeek ?? -1);
    }
    return false;
  }

  private hasCustomEvent(day: CalendarDay): boolean {
    for (const ev of this.customEvents) {
      if (this.eventMatchesDay(ev, day)) {
        return true;
      }
    }
    return false;
  }

  private navigate(delta: number): void {
    this.targetedDay = 0;
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
      SettingsHelper.getEventPerspective()
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
    if (e.key.startsWith('custom_')) {
      const id = e.key.replace('custom_', '');
      const custom = this.customEvents.find(c => c.id === id);
      return custom ? custom.title : 'Custom Event';
    }

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
              hasEvents: cell.events.length > 0 || this.hasCustomEvent(cell),
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
      // Main Content
      Column() {
        Scroll() {
          Row() {
            Column() {
              this.MonthHeader()
              this.WeekdayRow()
              this.Grid()
              this.EventsList()
              this.CustomEventsList()
              Column().height(140)
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

      // --- Floating Action Button ---
      Row() {
        Image($r('app.media.ic_add'))
          .width(24).height(24)
          .fillColor(this.colors.textOnAccent)
      }
      .width(56)
      .height(56)
      .backgroundColor(this.colors.accentGold)
      .borderRadius(28)
      .shadow({
        radius: 12,
        color: this.colors.shadowFloating,
        offsetX: 0,
        offsetY: 4
      })
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .zIndex(10)
      .position({
        right: this.isRtl() ? undefined : 24,
        left: this.isRtl() ? 24 : undefined,
        bottom: 100
      })
      .onClick(() => {
        this.openNewEventSheet();
      })
    }
    .width('100%').height('100%')
    .backgroundColor(this.colors.primaryGreen)
    .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
    .bindSheet($$this.showAddEventSheet, this.AddEventSheet(), {
      height: SheetSize.FIT_CONTENT,
      dragBar: true,
      backgroundColor: this.colors.cardDark,
      onDisappear: () => {
        this.showAddEventSheet = false;
      }
    })
  }

  @Builder
  MonthHeader() {
    Column() {
      Row() {
        // Previous Month
        Row() {
          Image($r('app.media.ic_chevron_right'))
            .width(16).height(16)
            .fillColor(this.colors.accentGold)
            .rotate({ angle: this.isRtl() ? 0 : 180 })
        }
        .width(40)
        .height(40)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .borderRadius(20)
        .backgroundColor(this.colors.tintSoft)
        .border({ width: 1, color: this.colors.borderSoft })
        .onClick(() => {
          this.navigate(-1);
        })

        Column() {
          Text(this.getLocalizedMonthName())
            .fontSize(22).fontWeight(FontWeight.Bold)
            .fontColor(this.colors.textWhite)
            .textAlign(TextAlign.Center)
            .width('100%')
          Row({ space: 6 }) {
            Text(`${this.viewingHijriYear} ${this.tr('hijri_year_suffix')}`)
              .fontSize(13).fontColor(this.colors.accentGold)

            Text('·')
              .fontSize(11).fontColor(this.colors.textMuted)

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

        // Next Month
        Row() {
          Image($r('app.media.ic_chevron_right'))
            .width(16).height(16)
            .fillColor(this.colors.accentGold)
            .rotate({ angle: this.isRtl() ? 180 : 0 })
        }
        .width(40)
        .height(40)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .borderRadius(20)
        .backgroundColor(this.colors.tintSoft)
        .border({ width: 1, color: this.colors.borderSoft })
        .onClick(() => {
          this.navigate(1);
        })

        if (this.isExporting) {
          LoadingProgress()
            .width(24).height(24)
            .color(this.colors.accentGold)
            .margin({
              left: this.isRtl() ? 0 : 12,
              right: this.isRtl() ? 12 : 0
            })
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
            .margin({
              left: this.isRtl() ? 0 : 8,
              right: this.isRtl() ? 8 : 0
            })
            .onClick(() => {
              this.handleExport();
            })
        }
      }
      .width('100%').alignItems(VerticalAlign.Center)
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
              `-${cell.isToday ? 'T' : 'f'}-${cell.events.length}-${this.hasCustomEvent(cell)}`;
          })
        }
        .width('100%').margin({ bottom: 4 })
      }, (week: Array<CalendarDay | null>, wi: number) => {
        const parts: string[] = [];
        for (const cell of week) {
          if (cell === null) {
            parts.push('_');
          } else {
            parts.push(
              `${cell.hijri.year}-${cell.hijri.month}-${cell.hijri.day}-` +
                `${cell.isToday ? 'T' : 'f'}-${cell.events.length}-${this.hasCustomEvent(cell)}`
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
          : (cell.events.length > 0 || this.hasCustomEvent(cell) ? this.colors.accentGold : this.colors.textWhite))

      Text(`${cell.gregorianDate.getDate()}`)
        .fontSize(10)
        .fontColor(cell.isToday ? this.colors.textOnAccent : this.colors.textMuted)
        .opacity(cell.isToday ? 0.85 : 0.7).margin({ top: -2 })

      if ((cell.events.length > 0 || this.hasCustomEvent(cell)) && !cell.isToday) {
        Row()
          .width(5)
          .height(5)
          .borderRadius(3)
          .backgroundColor(this.colors.accentGold)
          .margin({ top: 3 })
      } else if ((cell.events.length > 0 || this.hasCustomEvent(cell)) && cell.isToday) {
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
    .border(this.dayCellBorder(cell))
    .margin({ left: 2, right: 2 })
  }

  @Builder
  EventsList() {
    Column() {
      Row({ space: 8 }) {
        Image($r('app.media.ic_nav_calendar'))
          .width(16).height(16)
          .fillColor(this.colors.accentGold)
          .flexShrink(0)
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
          Row({ space: 8 }) {
            Text(`${e.day}`)
              .fontSize(16).fontWeight(FontWeight.Bold)
              .fontColor(this.colors.accentGold)
              .width(36)
              .textAlign(TextAlign.Center)
              .flexShrink(0)
            Text(this.translateEventName(e))
              .fontSize(14).fontColor(this.colors.textWhite).layoutWeight(1)
          }
          .width('100%')
          .padding({
            bottom: 20,
            left: this.isRtl() ? 20 : 16,
            right: this.isRtl() ? 16 : 20
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

  private getFilteredCustomEvents(): CustomEvent[] {
    // Now just returns the events for the currently viewed month
    return this.getCustomEventsForMonth();
  }

  @Builder
  CustomEventsList() {
    if (this.getFilteredCustomEvents().length > 0) {
      Column() {
        Row({ space: 8 }) {
          Image($r('app.media.ic_nav_calendar'))
            .width(16).height(16)
            .fillColor(this.colors.accentGold)
            .flexShrink(0)
          Text(this.tr('custom_events_title'))
            .fontSize(12)
            .fontColor(this.colors.accentGold)
            .fontWeight(FontWeight.Bold)
            .letterSpacing(1.5)
            .layoutWeight(1)
            .textAlign(TextAlign.Start)
        }
        .width('100%').padding({ bottom: 12 })

        ForEach(this.getFilteredCustomEvents(), (ev: CustomEvent) => {
          Row({ space: 8 }) {
            Text(this.eventDayLabel(ev))
              .fontSize(ev.recurrence === RecurrenceType.WEEKLY ? 12 : 16)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.colors.accentGold)
              .width(36)
              .textAlign(TextAlign.Center)
              .flexShrink(0)

            Column() {
              Text(ev.title)
                .fontSize(14)
                .fontColor(this.colors.textWhite)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .textAlign(TextAlign.Start)
                .width('100%')
              if (ev.recurrence && ev.recurrence !== RecurrenceType.NONE) {
                Text(this.tr('recur_' + ev.recurrence))
                  .fontSize(10).fontColor(this.colors.textMuted)
                  .textAlign(TextAlign.Start)
                  .width('100%')
              }
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            // Edit Button
            Row() {
              Image($r('app.media.ic_edit')).width(16).height(16).fillColor(this.colors.accentGold)
            }
            .width(32).height(32).justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.openEditEventSheet(ev);
            })

            // Delete Button
            Row() {
              Image($r('app.media.ic_delete')).width(16).height(16).fillColor(this.colors.statusExpress)
            }
            .width(32).height(32).justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.deleteCustomEvent(ev.id);
            })
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
          .alignItems(VerticalAlign.Center)
        }, (ev: CustomEvent) => `custom-${ev.id}-${ev.title}-${ev.hijriDay}`)
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

  private async deleteCustomEvent(id: string) {
    this.customEvents = this.customEvents.filter(ev => ev.id !== id);
    await CustomEventStorage.save(this.customEvents);
    await CustomEventNotifier.reschedule(this.customEvents, this.offsetDays);

    if (this.monthDays.length > 0) {
      this.rebuildFromAnchor(this.monthDays[0].gregorianDate);
    }
  }

  private openNewEventSheet(): void {
    this.editingEventId = '';
    this.formTitle = '';
    this.formNotify = true;
    this.formDateType = 'hijri';
    this.formRecurrence = RecurrenceType.NONE;

    const today = new Date();
    const h = HijriCalendarHelper.getHijriDate(today, this.offsetDays);

    this.formHijriDay = h.day.toString();
    this.formHijriMonth = h.month.toString();
    this.formHijriYear = h.year.toString();

    this.formGregDay = today.getDate().toString();
    this.formGregMonth = (today.getMonth() + 1).toString();
    this.formGregYear = today.getFullYear().toString();

    this.showAddEventSheet = true;
  }

  private openEditEventSheet(ev: CustomEvent): void {
    this.editingEventId = ev.id;
    this.formTitle = ev.title;
    this.formNotify = ev.notificationEnabled;
    this.formDateType = ev.inputType ?? 'hijri';
    this.formRecurrence = ev.recurrence ?? RecurrenceType.NONE;

    this.formHijriDay = ev.hijriDay.toString();
    this.formHijriMonth = ev.hijriMonth.toString();

    const today = new Date();
    const currentHijri = HijriCalendarHelper.getHijriDate(today, this.offsetDays);
    const targetHijriYear = ev.hijriYear === -1 ? currentHijri.year : ev.hijriYear;
    this.formHijriYear = targetHijriYear.toString();

    const greg = HijriCalendarHelper.findGregorianForHijri(
      targetHijriYear, ev.hijriMonth, ev.hijriDay, this.offsetDays, today
    );

    if (greg) {
      this.formGregDay = greg.getDate().toString();
      this.formGregMonth = (greg.getMonth() + 1).toString();
      this.formGregYear = greg.getFullYear().toString();
    } else {
      this.formGregDay = today.getDate().toString();
      this.formGregMonth = (today.getMonth() + 1).toString();
      this.formGregYear = today.getFullYear().toString();
    }

    this.showAddEventSheet = true;
  }

  private async saveCustomEvent(): Promise<void> {
    if (this.formTitle.trim().length === 0) {
      promptAction.showToast({ message: this.tr('event_title_required') });
      return;
    }

    let hYear = parseInt(this.formHijriYear);
    let hMonth = parseInt(this.formHijriMonth);
    let hDay = parseInt(this.formHijriDay);
    let gDayOfWeek = 0;

    if (this.formDateType === 'gregorian') {
      const gDay = parseInt(this.formGregDay);
      const gMonth = parseInt(this.formGregMonth);
      const gYear = parseInt(this.formGregYear);

      const gDate = new Date(gYear, gMonth - 1, gDay);
      if (isNaN(gDate.getTime()) || gDate.getDate() !== gDay) {
        promptAction.showToast({ message: this.tr('invalid_date') });
        return;
      }

      gDayOfWeek = gDate.getDay();
      const h = HijriCalendarHelper.getHijriDate(gDate, this.offsetDays);
      hYear = h.year;
      hMonth = h.month;
      hDay = h.day;
    } else {
      // If Hijri, we still need to calculate the Gregorian weekday for Weekly recurrence
      if (this.formRecurrence === RecurrenceType.WEEKLY) {
        const today = new Date();
        const gDate = HijriCalendarHelper.findGregorianForHijri(
          hYear, hMonth, hDay, this.offsetDays, today
        );
        if (gDate) {
          gDayOfWeek = gDate.getDay();
        }
      }
    }

    const finalYear = this.formRecurrence === RecurrenceType.NONE ? hYear : -1;

    if (this.editingEventId) {
      this.customEvents = this.customEvents.map((ev: CustomEvent): CustomEvent => {
        if (ev.id === this.editingEventId) {
          return {
            id: ev.id,
            title: this.formTitle,
            hijriYear: finalYear,
            hijriMonth: hMonth,
            hijriDay: hDay,
            notificationEnabled: this.formNotify,
            inputType: this.formDateType,
            recurrence: this.formRecurrence,
            gregorianDayOfWeek: gDayOfWeek
          };
        }
        return ev;
      });
    } else {
      const newEvent: CustomEvent = {
        id: CustomEventStorage.generateId(),
        title: this.formTitle,
        hijriYear: finalYear,
        hijriMonth: hMonth,
        hijriDay: hDay,
        notificationEnabled: this.formNotify,
        inputType: this.formDateType,
        recurrence: this.formRecurrence,
        gregorianDayOfWeek: gDayOfWeek
      };
      this.customEvents.push(newEvent);
    }

    await CustomEventStorage.save(this.customEvents);
    await CustomEventNotifier.reschedule(this.customEvents, this.offsetDays);

    this.showAddEventSheet = false;
    if (this.monthDays.length > 0) {
      this.rebuildFromAnchor(this.monthDays[0].gregorianDate);
    }
  }

  @Builder
  AddEventSheet() {
    Column() {
      // 1. Drag Bar
      Row()
        .width(44)
        .height(4)
        .backgroundColor(this.colors.overlayDimSoft)
        .borderRadius(2)
        .margin({ top: 10, bottom: 16 })

      // 2. Header
      Row({ space: 12 }) {
        Row() {
          Image($r('app.media.ic_nav_calendar'))
            .width(20).height(20)
            .fillColor(this.colors.accentGold)
        }
        .width(44)
        .height(44)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .backgroundColor(this.colors.tintSoft)
        .borderRadius(12)
        .border({ width: 1, color: this.colors.borderSoft })
        .flexShrink(0)

        // DYNAMIC TITLE
        Text(this.editingEventId ? this.tr('edit_custom_event') : this.tr('add_custom_event'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textWhite)
          .layoutWeight(1)
          .textAlign(TextAlign.Start)
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 20 })

      Divider().color(this.colors.borderSoft).width('90%').margin({ bottom: 20 })

      // 3. Scrollable Form Content
      Scroll() {
        Column({ space: 20 }) {

          // --- Event Title ---
          Column({ space: 8 }) {
            Text(this.tr('event_title'))
              .fontSize(13)
              .fontColor(this.colors.textMuted)
              .fontWeight(FontWeight.Medium)
              .width('100%')
              .textAlign(TextAlign.Start)
            TextInput({ text: this.formTitle, placeholder: this.tr('event_title_placeholder') })
              .onChange((v) => this.formTitle = v)
              .fontSize(15)
              .fontColor(this.colors.textWhite)
              .placeholderColor(this.colors.placeholder)
              .caretColor(this.colors.accentGold)
              .backgroundColor(this.colors.tintSoft)
              .borderRadius(10)
              .padding({
                left: 14,
                right: 14,
                top: 12,
                bottom: 12
              })
              .border({ width: 1, color: this.colors.borderSoft })
          }
          .width('100%')

          // --- Date Type Segmented Toggle ---
          Column({ space: 8 }) {
            Text(this.tr('date_type'))
              .fontSize(13)
              .fontColor(this.colors.textMuted)
              .fontWeight(FontWeight.Medium)
              .width('100%')
              .textAlign(TextAlign.Start)

            Row({ space: 4 }) {
              Text(this.tr('hijri_date'))
                .fontSize(14)
                .fontWeight(this.formDateType === 'hijri' ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.formDateType === 'hijri' ? this.colors.textOnAccent : this.colors.textWhite)
                .backgroundColor(this.formDateType === 'hijri' ? this.colors.accentGold : Color.Transparent)
                .layoutWeight(1)
                .textAlign(TextAlign.Center)
                .padding({ top: 10, bottom: 10 })
                .borderRadius(8)
                .onClick(() => this.formDateType = 'hijri')

              Text(this.tr('gregorian_date'))
                .fontSize(14)
                .fontWeight(this.formDateType === 'gregorian' ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.formDateType === 'gregorian' ? this.colors.textOnAccent : this.colors.textWhite)
                .backgroundColor(this.formDateType === 'gregorian' ? this.colors.accentGold : Color.Transparent)
                .layoutWeight(1)
                .textAlign(TextAlign.Center)
                .padding({ top: 10, bottom: 10 })
                .borderRadius(8)
                .onClick(() => this.formDateType = 'gregorian')
            }
            .width('100%')
            .padding(4)
            .backgroundColor(this.colors.tintSoft)
            .borderRadius(12)
            .border({ width: 1, color: this.colors.borderSoft })
          }
          .width('100%')

          // --- Date Inputs ---
          if (this.formDateType === 'hijri') {
            Row({ space: 10 }) {
              this.DateInput(this.tr('day'), this.formHijriDay, (v) => this.formHijriDay = v)
              this.DateInput(this.tr('month'), this.formHijriMonth, (v) => this.formHijriMonth = v)
              this.DateInput(this.tr('year'), this.formHijriYear, (v) => this.formHijriYear = v)
            }
            .width('100%')
          } else {
            Column({ space: 8 }) {
              Row({ space: 10 }) {
                this.DateInput(this.tr('day'), this.formGregDay, (v) => this.formGregDay = v)
                this.DateInput(this.tr('month'), this.formGregMonth, (v) => this.formGregMonth = v)
                this.DateInput(this.tr('year'), this.formGregYear, (v) => this.formGregYear = v)
              }
              .width('100%')

              // Live preview of resultant Hijri date
              if (this.getHijriPreviewFromGregorian().length > 0) {
                Row({ space: 6 }) {
                  Image($r('app.media.ic_nav_calendar'))
                    .width(14).height(14)
                    .fillColor(this.colors.accentGold)
                    .flexShrink(0)
                  Text(this.tr('hijri_equivalent'))
                    .fontSize(11).fontColor(this.colors.textMuted)
                  Text(this.getHijriPreviewFromGregorian())
                    .fontSize(12).fontColor(this.colors.accentGold)
                    .fontWeight(FontWeight.Medium)
                }
                .width('100%')
                .padding(8)
                .backgroundColor(this.colors.tintSubtle)
                .borderRadius(8)
                .border({ width: 1, color: this.colors.borderSoft })
              }
            }
            .width('100%')
          }

          // --- Notification Toggle ---
          Row() {
            Row() {
              Image($r('app.media.ic_bell'))
                .width(20).height(20)
                .fillColor(this.formNotify ? this.colors.accentGold : this.colors.textMuted)
            }
            .width(36)
            .height(36)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(this.colors.tintSoft)
            .borderRadius(10)
            .flexShrink(0)
            .margin({ right: this.isRtl() ? 0 : 12, left: this.isRtl() ? 12 : 0 })

            Column() {
              Text(this.tr('notify_me'))
                .fontSize(15)
                .fontColor(this.colors.textWhite)
                .fontWeight(FontWeight.Medium)
                .width('100%')
                .textAlign(TextAlign.Start)
              Text(this.tr('notify_me_desc'))
                .fontSize(11)
                .fontColor(this.colors.textMuted)
                .width('100%')
                .textAlign(TextAlign.Start)
                .margin({ top: 2 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Toggle({ type: ToggleType.Switch, isOn: this.formNotify })
              .selectedColor(this.colors.accentGold)
              .onChange(v => this.formNotify = v)
          }
          .width('100%')
          .padding(12)
          .backgroundColor(this.colors.tintSubtle)
          .borderRadius(12)
          .border({ width: 1, color: this.colors.borderSoft })

        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 20 })
      }
      .flexShrink(1)
      .width('100%')
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)

      Divider().color(this.colors.borderSoft).width('90%').margin({ top: 10 })

      // 4. Action Buttons
      Row({ space: 12 }) {
        Button(this.tr('cancel'))
          .layoutWeight(1)
          .height(48)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.textWhite)
          .backgroundColor(this.colors.tintSoft)
          .borderRadius(12)
          .onClick(() => {
            this.showAddEventSheet = false;
          })

        Button(this.tr('save'))
          .layoutWeight(1)
          .height(48)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textOnAccent)
          .backgroundColor(this.colors.accentGold)
          .borderRadius(12)
          .onClick(async () => {
            await this.saveCustomEvent();
          })
      }
      .width('100%')
      .padding({
        top: 16,
        bottom: 24,
        left: 20,
        right: 20
      })
    }
    .width('100%')
    .backgroundColor(this.colors.cardDark)
    .borderRadius({ topLeft: 24, topRight: 24 })
  }

  @Builder
  DateInput(label: string, value: string, onChange: (v: string) => void) {
    Column({ space: 6 }) {
      Text(label)
        .fontSize(12).fontColor(this.colors.textMuted)
        .width('100%').textAlign(TextAlign.Center)
      TextInput({ text: value })
        .type(InputType.Number)
        .onChange(onChange)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.colors.textWhite)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.colors.tintSoft)
        .borderRadius(10)
        .padding(12)
        .border({ width: 1, color: this.colors.borderSoft })
    }
    .layoutWeight(1)
  }

  // ============================================================
  // PDF BUILDER
  // ============================================================
  @Builder
  CalendarExportLayout() {
    Column() {
      // Header
      Row({ space: 16 }) {
        Image($r('app.media.foreground'))
          .syncLoad(true)
          .width(44)
          .height(44)
          .borderRadius(10)
          .flexShrink(0)

        Column() {
          Text(`${this.getLocalizedMonthName()} ${this.viewingHijriYear} ${this.tr('hijri_year_suffix')}`)
            .fontSize(24).fontWeight(FontWeight.Bold).fontColor(this.pdfColors.textWhite)
            .width('100%')

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

        Text(this.tr('generated_by'))
          .fontSize(9).fontColor(this.pdfColors.textMuted).alignSelf(ItemAlign.Start).margin({ top: 4 })
      }
      .width('100%')
      .padding({ top: 30, bottom: 20, left: 24, right: 24 })
      .backgroundColor(this.pdfColors.cardDark)
      .alignItems(VerticalAlign.Center)

      Row().width('100%').height(4).backgroundColor(this.pdfColors.accentGold)

      // Calendar Grid
      Column() {
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
                      .width(4).height(4).borderRadius(2)
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

      // Important Dates & Custom Events
      Column() {
        Text(this.tr('important_dates'))
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.pdfColors.accentGold)
          .width('100%')
          .margin({ bottom: 8 })

        if (this.getMonthEvents().length === 0 && this.getCustomEventsForMonth().length === 0) {
          Text(this.tr('no_events_this_month'))
            .fontSize(10)
            .fontColor(this.pdfColors.textMuted)
            .width('100%')
            .textAlign(TextAlign.Start)
        } else {
          // Built-in Events
          ForEach(this.getMonthEvents(), (e: IslamicEvent) => {
            Row({ space: 8 }) {
              Text(`${e.day}`)
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.pdfColors.accentGold)
                .width(24)
                .margin({ top: 2 })
                .flexShrink(0)

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

          // Custom Events
          ForEach(this.getCustomEventsForMonth(), (ev: CustomEvent) => {
            Row({ space: 8 }) {
              Text(`${ev.hijriDay}`)
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.pdfColors.accentGold)
                .width(24)
                .margin({ top: 2 })
                .flexShrink(0)

              Column() {
                Text(ev.title)
                  .fontSize(11)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.pdfColors.textWhite)
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
    .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
  }

  private getLocalizedGregorianSpan(): string {
    if (this.monthDays.length === 0) {
      return '';
    }
    const first = this.monthDays[0].gregorianDate;
    const last = this.monthDays[this.monthDays.length - 1].gregorianDate;

    const locale = this.appLanguage === 'zh' ? 'zh-CN' : (this.appLanguage === 'ar' ? 'ar' : 'en-US');

    const firstMonth = first.toLocaleString(locale, { month: 'short' });
    const lastMonth = last.toLocaleString(locale, { month: 'short' });
    const year = last.getFullYear();

    if (first.getMonth() === last.getMonth() && first.getFullYear() === last.getFullYear()) {
      return `${firstMonth} ${first.getDate()} – ${last.getDate()}, ${year}`;
    }
    return `${firstMonth} ${first.getDate()} – ${lastMonth} ${last.getDate()}, ${year}`;
  }

  private getHijriPreviewFromGregorian(): string {
    const gDay = parseInt(this.formGregDay);
    const gMonth = parseInt(this.formGregMonth);
    const gYear = parseInt(this.formGregYear);

    if (isNaN(gDay) || isNaN(gMonth) || isNaN(gYear)) {
      return '';
    }

    // Validate: reject impossible dates like Feb 31
    const testDate = new Date(gYear, gMonth - 1, gDay);
    if (testDate.getFullYear() !== gYear ||
      testDate.getMonth() !== gMonth - 1 ||
      testDate.getDate() !== gDay) {
      return this.tr('invalid_date');
    }

    const h = HijriCalendarHelper.getHijriDate(testDate, this.offsetDays);
    const monthNames = L.getArray('hijri_months', this.currentLanguage);
    const monthName = monthNames[h.month - 1] || '';
    return `${h.day} ${monthName} ${h.year} ${this.tr('hijri_year_suffix')}`;
  }

  private getCustomEventsForMonth(): CustomEvent[] {
    return this.customEvents.filter(ev => {
      const rec = ev.recurrence || RecurrenceType.NONE;
      // One-off and yearly events must match the current month
      if (rec === RecurrenceType.NONE) {
        return ev.hijriYear === this.viewingHijriYear && ev.hijriMonth === this.viewingHijriMonth;
      }
      if (rec === RecurrenceType.YEARLY) {
        return ev.hijriMonth === this.viewingHijriMonth;
      }
      // Monthly and weekly events always appear (they occur every month)
      return true;
    });
  }

  /**
   * Return the display label for a custom event's "date" pill.
   *
   * Weekly events carry a gregorianDayOfWeek (0–6), not a specific
   * Hijri day of the current month. Showing `ev.hijriDay` — the
   * day the event was originally created on — is misleading. Show
   * the localized short weekday name instead.
   *
   * Monthly and one-off/yearly events do have a specific Hijri
   * day, so they keep the numeric label.
   */
  private eventDayLabel(ev: CustomEvent): string {
    if (ev.recurrence === RecurrenceType.WEEKLY &&
      ev.gregorianDayOfWeek !== undefined &&
      ev.gregorianDayOfWeek >= 0 &&
      ev.gregorianDayOfWeek <= 6) {
      const weekdays = this.trArray('days_of_week_short');
      return weekdays[ev.gregorianDayOfWeek] || `${ev.hijriDay}`;
    }
    return `${ev.hijriDay}`;
  }
}