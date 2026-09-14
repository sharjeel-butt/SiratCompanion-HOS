// entry/src/main/ets/pages/HijriCalendarPage.ets

import { router } from '@kit.ArkUI';
import { mediaquery } from '@kit.ArkUI';
import { Theme, ThemeColors, ThemeMode } from '../common/Theme';
import { PageTheme } from '../common/PageTheme';
import {
  STORAGE_KEY_THEME_MODE,
  STORAGE_KEY_NAV_DIRECTION,
  STORAGE_KEY_HIJRI_OFFSET,
  STORAGE_KEY_LANGUAGE
} from '../common/StorageKeys';
import { CalendarDay, HijriDate } from '../models/HijriCalendarModels';
import { IslamicEvent } from '../models/DateModels';
import { HijriCalendarHelper } from '../helper/HijriCalendarHelper';
import { SettingsHelper } from '../helper/SettingsHelper';
import { NavHelper } from '../helper/NavHelper';
import { L } from '../helper/LocalizationHelper';

@Entry
@Component
struct HijriCalendarPage {

  // ============================================================
  // THEME + NAV + LANGUAGE
  // ============================================================

  @StorageLink(STORAGE_KEY_THEME_MODE)
  @Watch('onThemeModeChanged')
  themeMode: string = ThemeMode.SYSTEM;

  @StorageLink(STORAGE_KEY_NAV_DIRECTION)
  navDirection: string = 'forward';

  @StorageLink(STORAGE_KEY_HIJRI_OFFSET)
  @Watch('onHijriOffsetChanged')
  offsetDays: number = 0;

  @StorageLink(STORAGE_KEY_LANGUAGE)
  @Watch('onLanguageChanged')
  appLanguage: string = 'en';

  /** Plain @State mirror — guarantees re-render on language change. */
  @State private currentLanguage: string = 'en';

  @State colors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);
  private systemDarkListener: mediaquery.MediaQueryListener | null = null;

  @State viewingHijriYear: number = 1447;
  @State viewingHijriMonth: number = 1;
  @State monthDays: CalendarDay[] = [];

  // ============================================================
  // LOCALIZATION + DIRECTION HELPERS
  // ============================================================

  private tr(key: string): string {
    return L.get(key, this.currentLanguage);
  }

  private trArray(key: string): string[] {
    return L.getArray(key, this.currentLanguage);
  }

  private isRtl(): boolean {
    return L.isRtlLang(this.currentLanguage);
  }

  // ============================================================
  // WATCHERS
  // ============================================================

  private onThemeModeChanged(): void {
    this.colors = PageTheme.compute(this.themeMode);
  }

  private onHijriOffsetChanged(): void {
    this.jumpToToday();
  }

  private onLanguageChanged(): void {
    this.currentLanguage = this.appLanguage;
  }

  // ============================================================
  // PAGE TRANSITION
  // ============================================================

  pageTransition() {
    PageTransitionEnter({ type: RouteType.Push, duration: 300, curve: Curve.Friction })
      .slide(this.navDirection === 'forward' ? SlideEffect.Right : SlideEffect.Left)
    PageTransitionExit({ type: RouteType.Push, duration: 300, curve: Curve.Friction })
      .slide(this.navDirection === 'forward' ? SlideEffect.Left : SlideEffect.Right)

    PageTransitionEnter({ type: RouteType.Pop, duration: 300, curve: Curve.Friction })
      .slide(SlideEffect.Left)
    PageTransitionExit({ type: RouteType.Pop, duration: 300, curve: Curve.Friction })
      .slide(SlideEffect.Right)
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

  onBackPress(): boolean {
    NavHelper.prepareBackward();
    return false;
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  private onFloatingBarTap(tabId: string): void {
    if (tabId === 'calendar') return;

    if (tabId === 'home') {
      NavHelper.prepareBackward();
      try { router.back({ url: 'pages/Index' }); }
      catch (err) {
        router.clear();
        NavHelper.prepare('home', 'calendar');
        router.pushUrl({ url: 'pages/Index' })
          .catch((e: Error) => console.error('Navigation failed:', JSON.stringify(e)));
      }
      return;
    }

    if (tabId === 'tasbih') {
      NavHelper.prepare('tasbih', 'calendar');
      router.pushUrl({ url: 'pages/TasbihPage' })
        .catch((err: Error) => console.error('Navigation failed:', JSON.stringify(err)));
      return;
    }

    if (tabId === 'compass') {
      NavHelper.prepare('compass', 'calendar');
      router.pushUrl({ url: 'pages/QiblaPage' })
        .catch((err: Error) => console.error('Navigation failed:', JSON.stringify(err)));
    }
  }

  // ============================================================
  // CALENDAR LOGIC
  // ============================================================

  private jumpToToday(): void {
    const today = new Date();
    const h: HijriDate = HijriCalendarHelper.getHijriDate(today, this.offsetDays);
    this.viewingHijriYear = h.year;
    this.viewingHijriMonth = h.month;
    this.rebuildFromAnchor(today);
  }

  private rebuildFromAnchor(anchor: Date): void {
    this.monthDays = HijriCalendarHelper.buildMonthDays(
      this.viewingHijriYear,
      this.viewingHijriMonth,
      this.offsetDays,
      anchor
    );
  }

  private navigate(delta: number): void {
    const shifted = HijriCalendarHelper.shiftMonth(
      this.viewingHijriYear, this.viewingHijriMonth, delta
    );
    const anchor = this.monthDays.length > 0
      ? this.monthDays[0].gregorianDate
      : new Date();

    this.viewingHijriYear = shifted.year;
    this.viewingHijriMonth = shifted.month;
    this.rebuildFromAnchor(anchor);
  }

  // ============================================================
  // DERIVED VALUES
  // ============================================================

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

  // ============================================================
  // BUILD
  // ============================================================

  build() {
    Stack() {
      Column() {
        this.TopBar()

        Scroll() {
          Column() {
            this.MonthHeader()
            this.WeekdayRow()
            this.Grid()
            this.EventsList()
            Column().height(130)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16 })
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor(this.colors.primaryGreen)
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%').height('100%')

      this.FloatingBar()
    }
    .width('100%').height('100%')
    .backgroundColor(this.colors.primaryGreen)
    .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  @Builder
  TopBar() {
    Row() {
      Text(this.tr('title_hijri_calendar'))
        .fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
        .margin({ left: 20 }).layoutWeight(1)

      Text(this.tr('today'))
        .fontSize(12).fontColor(this.colors.accentGold).fontWeight(FontWeight.Medium)
        .padding({ left: 14, right: 14, top: 6, bottom: 6 })
        .backgroundColor(this.colors.tintSoft)
        .borderRadius(14)
        .border({ width: 1, color: this.colors.borderSoft })
        .margin({ right: 16 })
        .onClick(() => { this.jumpToToday(); })
    }
    .width('100%').height(72).backgroundColor(this.colors.cardDark)
    .alignItems(VerticalAlign.Center)
  }

  // ============================================================
  // MONTH HEADER
  // ============================================================

  @Builder
  MonthHeader() {
    Column() {
      Row() {
        // Previous month — glyph swapped in RTL so it stays visually
        // on the "left" from the user's perspective.
        Text('◀')
          .fontSize(16).fontColor(this.colors.accentGold)
          .width(40).height(40).textAlign(TextAlign.Center)
          .borderRadius(20).backgroundColor(this.colors.tintSoft)
          .border({ width: 1, color: this.colors.borderSoft })
          .onClick(() => { this.navigate(-1); })

        Column() {
          Text(this.getLocalizedMonthName())
            .fontSize(22).fontWeight(FontWeight.Bold)
            .fontColor(this.colors.textWhite)
            .textAlign(TextAlign.Center).width('100%')
          Text(`${this.viewingHijriYear} AH`)
            .fontSize(13).fontColor(this.colors.accentGold)
            .textAlign(TextAlign.Center).width('100%').margin({ top: 2 })
          Text(HijriCalendarHelper.formatGregorianSpan(this.monthDays))
            .fontSize(11).fontColor(this.colors.textMuted)
            .textAlign(TextAlign.Center).width('100%').margin({ top: 4 })
        }
        .layoutWeight(1).alignItems(HorizontalAlign.Center)

        // Next month — glyph swapped in RTL.
        Text('▶')
          .fontSize(16).fontColor(this.colors.accentGold)
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

  // ============================================================
  // WEEKDAY HEADER
  // ============================================================
  //
  // Kept LTR regardless of language so the week always reads
  // Sunday → Saturday left-to-right. Matching the Gregorian
  // convention most users are familiar with.

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
    .width('100%')
    .padding({ bottom: 6 })
    .direction(Direction.Ltr)
  }

  // ============================================================
  // GRID
  // ============================================================
  //
  // Also kept LTR so Sunday stays in the first column.

  @Builder
  Grid() {
    Column() {
      ForEach(this.buildPaddedWeeks(), (week: Array<CalendarDay | null>, wi: number) => {
        Row() {
          ForEach(week, (cell: CalendarDay | null, di: number) => {
            if (cell !== null) {
              this.DayCell(cell)
            } else {
              Column()
                .layoutWeight(1)
                .height(56)
                .margin({ left: 2, right: 2 })
            }
          }, (cell: CalendarDay | null, di: number) => {
            const key = cell !== null
              ? `${cell.hijri.year}-${cell.hijri.month}-${cell.hijri.day}`
              : `empty-${wi}-${di}`;
            return `cell-${key}`;
          })
        }
        .width('100%')
        .margin({ bottom: 4 })
      }, (week: Array<CalendarDay | null>, wi: number) =>
      `week-${wi}-${this.viewingHijriYear}-${this.viewingHijriMonth}-${this.offsetDays}`
      )
    }
    .width('100%')
    .padding(8)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(Theme.radiusMedium)
    .border({ width: 1, color: this.colors.borderSoft })
    .direction(Direction.Ltr)
  }

  // ============================================================
  // DAY CELL
  // ============================================================

  @Builder
  DayCell(cell: CalendarDay) {
    Column() {
      Text(`${cell.hijri.day}`)
        .fontSize(17)
        .fontWeight(cell.isToday ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(cell.isToday
          ? this.colors.textOnAccent
          : (cell.events.length > 0 ? this.colors.accentGold : this.colors.textWhite))

      Text(`${cell.gregorianDate.getDate()}`)
        .fontSize(10)
        .fontColor(cell.isToday ? this.colors.textOnAccent : this.colors.textMuted)
        .opacity(cell.isToday ? 0.85 : 0.7)
        .margin({ top: -2 })

      if (cell.events.length > 0 && !cell.isToday) {
        Row()
          .width(5).height(5).borderRadius(3)
          .backgroundColor(this.colors.accentGold)
          .margin({ top: 3 })
      } else if (cell.events.length > 0 && cell.isToday) {
        Row()
          .width(5).height(5).borderRadius(3)
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
    .backgroundColor(cell.isToday
      ? this.colors.accentGold
      : (cell.isFriday ? this.colors.tintSubtle : Color.Transparent))
    .borderRadius(10)
    .border(cell.isFriday && !cell.isToday
      ? { width: 1, color: this.colors.borderSoft }
      : { width: 0 })
    .margin({ left: 2, right: 2 })
  }

  // ============================================================
  // EVENTS LIST
  // ============================================================

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
              .width(36).textAlign(TextAlign.Center)
            Text(this.translateEventName(e))
              .fontSize(14).fontColor(this.colors.textWhite)
              .layoutWeight(1)
          }
          .width('100%')
          .padding({ top: 10, bottom: 10, left: 4, right: 8 })
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
  // FLOATING BAR — 4 tabs, Calendar active
  // ============================================================

  @Builder
  FloatingBar() {
    Row() {
      Row() {
        // ---- Home ----
        Column() {
          Text('🏠').fontSize(22).opacity(0.7)
          Text(this.tr('tab_home'))
            .fontSize(10).fontWeight(FontWeight.Normal)
            .fontColor(PageTheme.isSystemDark()
              ? 'rgba(241,245,249,0.65)'
              : 'rgba(26,26,26,0.55)')
            .margin({ top: 2 })
        }
        .layoutWeight(1).height('100%').justifyContent(FlexAlign.Center)
        .onClick(() => { this.onFloatingBarTap('home'); })

        Divider().vertical(true).height(28)
          .color(PageTheme.isSystemDark()
            ? 'rgba(74,222,128,0.20)'
            : 'rgba(15,81,50,0.12)')

        // ---- Tasbih ----
        Column() {
          Text('📿').fontSize(22).opacity(0.7)
          Text(this.tr('tab_tasbih'))
            .fontSize(10).fontWeight(FontWeight.Normal)
            .fontColor(PageTheme.isSystemDark()
              ? 'rgba(241,245,249,0.65)'
              : 'rgba(26,26,26,0.55)')
            .margin({ top: 2 })
        }
        .layoutWeight(1).height('100%').justifyContent(FlexAlign.Center)
        .onClick(() => { this.onFloatingBarTap('tasbih'); })

        Divider().vertical(true).height(28)
          .color(PageTheme.isSystemDark()
            ? 'rgba(74,222,128,0.20)'
            : 'rgba(15,81,50,0.12)')

        // ---- Compass ----
        Column() {
          Text('🧭').fontSize(22).opacity(0.7)
          Text(this.tr('tab_compass'))
            .fontSize(10).fontWeight(FontWeight.Normal)
            .fontColor(PageTheme.isSystemDark()
              ? 'rgba(241,245,249,0.65)'
              : 'rgba(26,26,26,0.55)')
            .margin({ top: 2 })
        }
        .layoutWeight(1).height('100%').justifyContent(FlexAlign.Center)
        .onClick(() => { this.onFloatingBarTap('compass'); })

        Divider().vertical(true).height(28)
          .color(PageTheme.isSystemDark()
            ? 'rgba(74,222,128,0.20)'
            : 'rgba(15,81,50,0.12)')

        // ---- Calendar (active) ----
        Column() {
          Text('📅').fontSize(22).opacity(1.0)
          Text(this.tr('tab_calendar'))
            .fontSize(10).fontWeight(FontWeight.Bold)
            .fontColor(PageTheme.isSystemDark() ? '#4ADE80' : '#0F5132')
            .margin({ top: 2 })
        }
        .layoutWeight(1).height('100%').justifyContent(FlexAlign.Center)
        .onClick(() => { this.onFloatingBarTap('calendar'); })
      }
      .width('92%').height(68)
      .backgroundBlurStyle(
        BlurStyle.Thin,
        {
          colorMode: PageTheme.isSystemDark() ? ThemeColorMode.DARK : ThemeColorMode.LIGHT,
          adaptiveColor: AdaptiveColor.DEFAULT,
          scale: 1.0
        }
      )
      .backgroundColor(
        PageTheme.isSystemDark() ? 'rgba(20, 27, 46, 0.50)' : 'rgba(255, 255, 255, 0.35)'
      )
      .borderRadius(34)
      .border({
        width: 1,
        color: PageTheme.isSystemDark()
          ? 'rgba(74, 222, 128, 0.35)'
          : 'rgba(255, 255, 255, 0.65)'
      })
      .shadow({
        radius: 28,
        color: PageTheme.isSystemDark() ? 'rgba(0, 0, 0, 0.50)' : 'rgba(0, 0, 0, 0.14)',
        offsetX: 0, offsetY: 10
      })
    }
    .width('100%').justifyContent(FlexAlign.Center)
    .position({ bottom: 24 })
  }
}