// entry/src/main/ets/pages/RamadanDetailsPage.ets

import { mediaquery, router } from '@kit.ArkUI';
import { Theme, ThemeColors, ThemeMode, ThemePreset } from '../common/Theme';
import { PageTheme } from '../common/PageTheme';
import { HijriCalendarHelper } from '../hijricalendar/HijriCalendarHelper';
import { CalendarDay } from '../hijricalendar/HijriCalendarModels';
import {
  STORAGE_KEY_APP_FOREGROUND_TICK,
  STORAGE_KEY_APP_THEME,
  STORAGE_KEY_BREAKPOINT,
  STORAGE_KEY_HIJRI_OFFSET,
  STORAGE_KEY_LANGUAGE,
  STORAGE_KEY_RAMADAN_STATE_VERSION,
  STORAGE_KEY_THEME_MODE
} from '../common/StorageKeys';
import { DuaCard } from '../components/DuaCard';
import { DUA_IFTAR, DUA_SUHOOR } from '../data/Duas';
import { Breakpoints } from '../common/Breakpoints';
import { L } from '../i8n/LocalizationHelper';
import {
  LaylatAlQadrNight, RamadanAshra, RamadanHelper, RamadanInfo
} from '../helper/RamadanHelper';
import { RamadanStorage } from '../helper/RamadanStorage';
import {
  FastingDay,
  FastingStatus,
  MissedReason,
  QadaSummary,
  QadaYearRow,
  RamadanYearData
} from '../models/RamadanModels';

type SheetKind = 'none' | 'mark' | 'reason';

interface QadaDayEntry {
  dayNumber: number;
  gregorianDate: Date;
  reason: MissedReason | null;
  madeUp: boolean;
}

@Entry
@Component
struct RamadanDetailsPage {
  // ============================================================
  // STORAGE LINKS
  // ============================================================

  @StorageLink(STORAGE_KEY_THEME_MODE)
  @Watch('onThemeModeChanged')
  themeMode: string = ThemeMode.SYSTEM;
  @StorageLink(STORAGE_KEY_LANGUAGE)
  @Watch('onLanguageChanged')
  appLanguage: string = 'en';
  @StorageLink(STORAGE_KEY_APP_THEME)
  @Watch('onAppThemePresetChanged')
  appThemePreset: string = ThemePreset.SIRAT;
  @StorageLink(STORAGE_KEY_HIJRI_OFFSET)
  @Watch('onHijriOffsetChanged')
  hijriOffset: number = 0;
  @StorageLink(STORAGE_KEY_APP_FOREGROUND_TICK)
  @Watch('onAppForegrounded')
  appForegroundTick: number = 0;
  @StorageLink(STORAGE_KEY_RAMADAN_STATE_VERSION)
  @Watch('onRamadanStateChanged')
  ramadanStateVersion: number = 0;
  @StorageLink(STORAGE_KEY_BREAKPOINT)
  breakpoint: string = 'sm';
  // ============================================================
  // STATE
  // ============================================================

  @State colors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);
  @State currentLanguage: string = 'en';
  @State ramadanInfo: RamadanInfo | null = null;
  @State currentYear: RamadanYearData | null = null;
  @State isLoadingInfo: boolean = true;
  @State activeSheet: SheetKind = 'none';
  @State selectedDay: number = 0;
  @State selectedReason: MissedReason | null = null;
  @State customReasonText: string = '';
  // ---- Qada ----
  @State qadaSummary: QadaSummary | null = null;
  // Year-detail sheet (per-day marking)
  @State showQadaYearSheet: boolean = false;
  @State activeQadaYear: number = 0;
  @State qadaYearDays: QadaDayEntry[] = [];
  private systemDarkListener: mediaquery.MediaQueryListener | null = null;
  private scrollController: Scroller = new Scroller();

  // ============================================================
  // LIFECYCLE
  // ============================================================

  aboutToAppear(): void {
    this.currentLanguage = this.appLanguage;
    this.colors = PageTheme.compute(this.themeMode);
    this.systemDarkListener = PageTheme.installSystemListener(
      this.themeMode, (c) => {
      this.colors = c;
    }
    );
    this.loadRamadanInfo();

    // Check if we navigated here from the "Duas" link
    const params = router.getParams() as Record<string, Object>;
    if (params && params['scrollToDuas'] === true) {
      // Delay slightly to allow the page to render and measure content height
      setTimeout(() => {
        this.scrollController.scrollEdge(Edge.Bottom);
      }, 300);
    }
  }

  aboutToDisappear(): void {
    PageTheme.uninstallSystemListener(this.systemDarkListener);
    this.systemDarkListener = null;
  }

  onPageShow(): void {
    this.currentLanguage = this.appLanguage;
    this.colors = PageTheme.compute(this.themeMode);
    this.loadRamadanInfo();
  }

  // ============================================================
  // DATA LOADING
  // ============================================================

  private async loadRamadanInfo(): Promise<void> {
    this.isLoadingInfo = true;
    try {
      const info = RamadanHelper.getRamadanInfo(this.hijriOffset);
      this.ramadanInfo = info;
      if (info !== null && info.isRamadanNow) {
        this.currentYear = await RamadanStorage.getOrCreateYear(
          info.hijriYear, info.totalDays
        );
      } else {
        this.currentYear = null;
      }
      // Qada summary is loaded regardless of whether Ramadan is
      // currently active — the section is always visible so the
      // user can review and log make-ups year-round.
      await this.reloadQadaSummary();
    } finally {
      this.isLoadingInfo = false;
    }
  }

  private async reloadQadaSummary(): Promise<void> {
    const store = await RamadanStorage.load();
    this.qadaSummary = RamadanStorage.computeQadaSummary(store);
  }

  private async reloadCurrentYear(): Promise<void> {
    if (this.ramadanInfo === null) {
      return;
    }
    this.currentYear = await RamadanStorage.getOrCreateYear(
      this.ramadanInfo.hijriYear, this.ramadanInfo.totalDays
    );
  }

  // ============================================================
  // WATCHERS
  // ============================================================

  private onThemeModeChanged(): void {
    this.colors = PageTheme.compute(this.themeMode);
  }

  private onAppThemePresetChanged(): void {
    this.colors = PageTheme.compute(this.themeMode);
  }

  private onLanguageChanged(): void {
    this.currentLanguage = this.appLanguage;
  }

  private onHijriOffsetChanged(): void {
    this.loadRamadanInfo();
  }

  private onAppForegrounded(): void {
    this.loadRamadanInfo();
  }

  private onRamadanStateChanged(): void {
    // The version counter is bumped by every RamadanStorage write.
    // Reload currentYear so the heatmap re-renders with the new
    // state. This is the only reliable refresh signal across the
    // sheet → page transition (the sheet closes before the async
    // write completes, so the caller cannot await the reload).
    this.reloadCurrentYear();
    this.reloadQadaSummary();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  private tr(key: string): string {
    return L.get(key, this.currentLanguage);
  }

  private isRtl(): boolean {
    return L.isRtlLang(this.currentLanguage);
  }

  private ramadanSubtitle(): string {
    if (this.ramadanInfo === null) {
      return '';
    }
    const yearSuffix = this.tr('hijri_year_suffix');
    if (!this.ramadanInfo.isRamadanNow) {
      return `${this.ramadanInfo.hijriYear} ${yearSuffix}`;
    }
    return `${this.ramadanInfo.hijriYear} ${yearSuffix} · ` +
      `${this.ramadanInfo.currentDayNumber} / ${this.ramadanInfo.totalDays}`;
  }

  private countFasted(): number {
    if (this.currentYear === null) {
      return 0;
    }
    let n = 0;
    for (const d of this.currentYear.days) {
      if (d.status === FastingStatus.FASTED) {
        n++;
      }
    }
    return n;
  }

  private countMissed(): number {
    if (this.currentYear === null) {
      return 0;
    }
    return RamadanStorage.countMissed(this.currentYear);
  }

  private countUnmarked(): number {
    if (this.currentYear === null) {
      return 0;
    }
    return this.currentYear.totalDays
      - this.countFasted() - this.countMissed();
  }

  private allReasons(): MissedReason[] {
    return [
      MissedReason.TRAVEL,
      MissedReason.ILLNESS,
      MissedReason.MENSTRUATION,
      MissedReason.PREGNANCY_NURSING,
      MissedReason.FORGETFULNESS,
      MissedReason.OTHER
    ];
  }

  // ============================================================
  // QADA HELPERS
  // ============================================================

  /** Years with at least one missed fast. Used by the audit table. */
  private auditYears(): QadaYearRow[] {
    if (this.qadaSummary === null) {
      return [];
    }
    const out: QadaYearRow[] = [];
    for (const row of this.qadaSummary.perYear) {
      if (row.missed > 0) {
        out.push(row);
      }
    }
    return out;
  }

  private async openQadaYearSheet(year: number): Promise<void> {
    const yearData = await RamadanStorage.getYear(year);
    if (yearData === null) {
      return;
    }

    // Reconstruct the Gregorian dates for this Hijri month so each
    // row can show "Day 5 · Mar 15".
    let monthDays: CalendarDay[] = [];
    try {
      monthDays = HijriCalendarHelper.buildMonthDays(
        year, 9, this.hijriOffset, new Date()
      );
    } catch (err) {
      monthDays = [];
    }

    const entries: QadaDayEntry[] = [];
    for (const d of monthDays) {
      const dayData = yearData.days[d.hijri.day - 1];
      if (dayData === undefined) {
        continue;
      }
      if (dayData.status !== FastingStatus.MISSED) {
        continue;
      }
      entries.push({
        dayNumber: d.hijri.day,
        gregorianDate: d.gregorianDate,
        reason: dayData.reason !== undefined ? dayData.reason : null,
        madeUp: dayData.madeUp === true
      });
    }

    this.qadaYearDays = entries;
    this.activeQadaYear = year;
    this.showQadaYearSheet = true;
  }

  private closeQadaYearSheet(): void {
    this.showQadaYearSheet = false;
    this.activeQadaYear = 0;
    this.qadaYearDays = [];
  }

  private async toggleDayMadeUp(day: number): Promise<void> {
    if (this.activeQadaYear === 0) {
      return;
    }
    if (this.ramadanInfo !== null && this.ramadanInfo.isRamadanNow) {
      return;
    }
    try {
      await RamadanStorage.toggleDayMadeUp(this.activeQadaYear, day);
      // Refresh both the sheet list and the summary.
      await this.openQadaYearSheet(this.activeQadaYear);
      await this.reloadQadaSummary();
    } catch (err) {
      console.error('[RamadanDetailsPage] toggleDayMadeUp failed: ' +
        JSON.stringify(err));
    }
  }

  private countMadeUpInActiveYear(): number {
    let n = 0;
    for (const e of this.qadaYearDays) {
      if (e.madeUp) {
        n++;
      }
    }
    return n;
  }

  // ============================================================
  // TARAWEEH HELPERS
  // ============================================================

  private countTaraweeh(): number {
    if (this.currentYear === null) {
      return 0;
    }
    let n = 0;
    for (const on of this.currentYear.taraweehNights) {
      if (on) {
        n++;
      }
    }
    return n;
  }

  private async toggleTaraweehNight(night: number): Promise<void> {
    if (this.ramadanInfo === null) {
      return;
    }
    try {
      await RamadanStorage.toggleTaraweeh(
        this.ramadanInfo.hijriYear, night
      );
    } catch (err) {
      console.error('[RamadanDetailsPage] toggleTaraweeh failed: ' +
        JSON.stringify(err));
    }
  }

  /** True when this night is in the past or is today. */
  private isTaraweehToggleable(idx: number): boolean {
    if (this.ramadanInfo === null) {
      return false;
    }
    return (idx + 1) <= this.ramadanInfo.currentDayNumber;
  }

  // ============================================================
  // ASHRA HELPERS
  // ============================================================

  private currentAshra(): RamadanAshra | null {
    if (this.ramadanInfo === null || !this.ramadanInfo.isRamadanNow) {
      return null;
    }
    const day = this.ramadanInfo.currentDayNumber;
    for (const a of this.ramadanInfo.ashras) {
      if (day >= a.startHijriDay && day <= a.endHijriDay) {
        return a;
      }
    }
    return null;
  }

  private isCurrentAshra(a: RamadanAshra): boolean {
    const cur = this.currentAshra();
    return cur !== null && cur.number === a.number;
  }

  // ============================================================
  // MARK / CLEAR HANDLERS
  // ============================================================

  private openMarkSheet(day: number): void {
    this.selectedDay = day;
    this.selectedReason = null;
    this.customReasonText = '';
    this.activeSheet = 'mark';
  }

  private closeSheet(): void {
    this.activeSheet = 'none';
    this.selectedReason = null;
    this.customReasonText = '';
  }

  private async markFasted(): Promise<void> {
    if (this.ramadanInfo === null) {
      return;
    }
    const year = this.ramadanInfo.hijriYear;
    const day = this.selectedDay;
    this.closeSheet();
    try {
      await RamadanStorage.markDay(year, day, FastingStatus.FASTED);
    } catch (err) {
      console.error('[RamadanDetailsPage] markFasted failed: ' +
        JSON.stringify(err));
    }
  }

  private async clearDay(): Promise<void> {
    if (this.ramadanInfo === null) {
      return;
    }
    const year = this.ramadanInfo.hijriYear;
    const day = this.selectedDay;
    this.closeSheet();
    try {
      await RamadanStorage.markDay(year, day, FastingStatus.UNMARKED);
    } catch (err) {
      console.error('[RamadanDetailsPage] clearDay failed: ' +
        JSON.stringify(err));
    }
  }

  private async confirmMissed(): Promise<void> {
    if (this.ramadanInfo === null || this.selectedReason === null) {
      return;
    }
    const year = this.ramadanInfo.hijriYear;
    const day = this.selectedDay;
    const reason = this.selectedReason;
    const custom = reason === MissedReason.OTHER
      ? this.customReasonText.trim()
      : undefined;
    this.closeSheet();
    try {
      await RamadanStorage.markDay(
        year, day, FastingStatus.MISSED, reason, custom
      );
    } catch (err) {
      console.error('[RamadanDetailsPage] confirmMissed failed: ' +
        JSON.stringify(err));
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  build() {
    Stack() {
      Column() {
        this.TopBar()

        Scroll(this.scrollController) {
          Row() {
            Column() {
              this.FastingSection()
              if (this.ramadanInfo !== null && this.ramadanInfo.isRamadanNow) {
                this.TaraweehSection()
                this.AboutRamadanSection()
              }
              this.QadaSection()
              this.DuasSection()
              Column().height(40)
            }
            .width('100%')
            .constraintSize({
              maxWidth: Breakpoints.maxContentWidth(this.breakpoint)
            })
            .padding({ left: 16, right: 16, top: 20 })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
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

      if (this.activeSheet === 'mark') {
        this.MarkSheet()
      } else if (this.activeSheet === 'reason') {
        this.ReasonSheet()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.primaryGreen)
    .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
    .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
    .bindSheet($$this.showQadaYearSheet, this.QadaYearSheet(), {
      height: 620,
      dragBar: true,
      showClose: false,
      backgroundColor: this.colors.cardDark,
      blurStyle: BlurStyle.Thick,
      maskColor: this.colors.overlayDim,
      onDisappear: () => {
        this.showQadaYearSheet = false;
      }
    })
    .expandSafeArea([SafeAreaType.SYSTEM],
      [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  @Builder
  TopBar() {
    Row({ space: 16 }) {
      // Arrow points Right in Arabic, Left in English
      Text(this.isRtl() ? '→' : '←')
        .fontSize(26)
        .fontColor(this.colors.textWhite)
        .width(40)
        .height(40)
        .textAlign(TextAlign.Center)
        .borderRadius(20)
        .backgroundColor(this.colors.tintSoft)
        .flexShrink(0)
        .onClick(() => router.back())

      Column() {
        Text(this.tr('title_ramadan_details'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textWhite)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .textAlign(TextAlign.Start) // Start = Right in AR, Left in EN

        if (this.ramadanInfo !== null) {
          Text(this.ramadanSubtitle())
            .fontSize(12)
            .fontColor(this.colors.accentGold)
            .margin({ top: 2 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .textAlign(TextAlign.Start)
        }
      }
      .layoutWeight(1)
      .alignItems(this.isRtl() ? HorizontalAlign.End : HorizontalAlign.Start)
    }
    .width('100%')
    .height(72)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.colors.cardDark)
    .alignItems(VerticalAlign.Center)

    // Removed .direction(Direction.Ltr) so the system naturally flips it
  }

  // ============================================================
  // FASTING SECTION
  // ============================================================

  @Builder
  FastingSection() {
    Column() {
      Row({ space: 8 }) {
        Text('📿').fontSize(16).flexShrink(0)
        Text(this.tr('section_fasting'))
          .fontSize(12)
          .fontColor(this.colors.textMuted)
          .fontWeight(FontWeight.Bold)
          .letterSpacing(1.2)
          .layoutWeight(1)
        if (this.currentYear !== null) {
          Text(`${this.countFasted()} / ${this.currentYear.totalDays}`)
            .fontSize(12)
            .fontColor(this.colors.accentGold)
            .fontWeight(FontWeight.Medium)
            .direction(Direction.Ltr)
        }
      }
      .width('100%').padding({ bottom: 14 })

      if (this.isLoadingInfo) {
        this.LoadingState()
      } else if (this.ramadanInfo === null
        || !this.ramadanInfo.isRamadanNow) {
        this.EmptyState()
      } else if (this.currentYear !== null) {
        this.FastingHeatmap()
        this.FastingSummary()
      }
    }
    .width('100%')
    .padding(18)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(Theme.radiusLarge)
    .border({
      width: 1,
      color: PageTheme.isDarkFor(this.themeMode)
        ? 'rgba(255, 255, 255, 0.08)'
        : this.colors.borderSoft
    })
    .shadow({
      radius: 12,
      color: this.colors.shadowCard,
      offsetX: 0,
      offsetY: 4
    })
    .margin({ bottom: 14 })
  }

  // ============================================================
  // QADA SECTION
  // ============================================================

  @Builder
  QadaSection() {
    Column() {
      Row({ space: 8 }) {
        Text('🔄').fontSize(16).flexShrink(0)
        Text(this.tr('section_qada'))
          .fontSize(12)
          .fontColor(this.colors.textMuted)
          .fontWeight(FontWeight.Bold)
          .letterSpacing(1.2)
          .layoutWeight(1)
      }
      .width('100%').padding({ bottom: 14 })

      if (this.qadaSummary === null) {
        this.QadaEmptyState()
      } else if (this.qadaSummary.totalMissed === 0) {
        this.QadaEmptyState()
      } else if (this.qadaSummary.remaining === 0) {
        this.QadaAllDoneState()
      } else {
        this.QadaContent()
      }
    }
    .width('100%')
    .padding(18)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(Theme.radiusLarge)
    .border({
      width: 1,
      color: PageTheme.isDarkFor(this.themeMode)
        ? 'rgba(255, 255, 255, 0.08)'
        : this.colors.borderSoft
    })
    .shadow({
      radius: 12,
      color: this.colors.shadowCard,
      offsetX: 0,
      offsetY: 4
    })
    .margin({ bottom: 14 })
  }

  @Builder
  QadaEmptyState() {
    Column() {
      Text('🔄').fontSize(40).opacity(0.4)
      Text(this.tr('qada_no_data'))
        .fontSize(13)
        .fontColor(this.colors.textMuted)
        .textAlign(TextAlign.Center)
        .lineHeight(18)
        .padding({ top: 12, left: 24, right: 24 })
    }
    .width('100%')
    .padding({ top: 16, bottom: 16 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  QadaAllDoneState() {
    Column() {
      Text('✅').fontSize(40)
      Text(this.tr('qada_all_done'))
        .fontSize(14)
        .fontColor(this.colors.accentGold)
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)
        .padding({ top: 12 })
    }
    .width('100%')
    .padding({ top: 16, bottom: 16 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  QadaContent() {
    Column() {
      // Top row: big remaining number + 4-stat ledger
      Row() {
        Column() {
          Text(`${this.qadaSummary!.remaining}`)
            .fontSize(46).fontWeight(FontWeight.Bold)
            .fontColor(this.colors.accentGold)
            .fontFeature('"tnum" 1')
          Text(this.tr('qada_remaining'))
            .fontSize(11).fontColor(this.colors.textMuted)
            .margin({ top: -4 })
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        Column() {
          this.QadaStatRow(
            this.tr('qada_total_fasted'),
            `${this.qadaSummary!.totalFasted}`,
            this.colors.textWhite
          )
          this.QadaStatRow(
            this.tr('qada_total_missed'),
            `${this.qadaSummary!.totalMissed}`,
            this.colors.statusExpress
          )
          this.QadaStatRow(
            this.tr('qada_total_made_up'),
            `${this.qadaSummary!.totalMadeUp}`,
            this.colors.accentGoldLight
          )
          this.QadaStatRow(
            this.tr('qada_total_unmarked'),
            `${this.qadaSummary!.totalUnmarked}`,
            this.colors.textMuted
          )
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 16 })

      Divider().color(this.colors.borderSoft).width('100%')

      // Per-year audit table
      Text(this.tr('qada_per_year'))
        .fontSize(11)
        .fontColor(this.colors.textMuted)
        .fontWeight(FontWeight.Bold)
        .letterSpacing(1)
        .width('100%')
        .padding({ top: 14, bottom: 8 })

      Column() {
        ForEach(this.auditYears(), (row: QadaYearRow) => {
          this.QadaYearRowView(row)
        }, (row: QadaYearRow) =>
        `qy-${row.hijriYear}-${row.missed}-${row.madeUp}`)
      }
      .width('100%').margin({ bottom: 8 })

      // During Ramadan, the year rows remain tappable so the user can
      // view which days have been made up. Toggling is disabled inside
      // the year sheet — see toggleDayMadeUp(). Outside Ramadan, taps
      // open the sheet with full toggle access.
      if (this.ramadanInfo !== null && this.ramadanInfo.isRamadanNow) {
        Row() {
          Text('ℹ️').fontSize(12).margin({ right: 6 }).opacity(0.7)
          Text(this.tr('qada_not_during_ramadan'))
            .fontSize(11)
            .fontColor(this.colors.textMuted)
            .fontStyle(FontStyle.Italic)
            .lineHeight(15)
            .layoutWeight(1)
        }
        .width('100%')
        .padding({
          top: 10,
          bottom: 10,
          left: 6,
          right: 6
        })
        .alignItems(VerticalAlign.Top)
      } else {
        Row() {
          Text('ℹ️').fontSize(12).margin({ right: 6 }).opacity(0.7)
          Text(this.tr('qada_tap_year_hint'))
            .fontSize(11)
            .fontColor(this.colors.textMuted)
            .fontStyle(FontStyle.Italic)
            .lineHeight(15)
            .layoutWeight(1)
        }
        .width('100%')
        .padding({
          top: 10,
          bottom: 10,
          left: 6,
          right: 6
        })
        .alignItems(VerticalAlign.Top)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  QadaStatRow(label: string, value: string, valueColor: string) {
    Row() {
      Text(label)
        .fontSize(11)
        .fontColor(this.colors.textMuted)
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(value)
        .fontSize(13).fontColor(valueColor)
        .fontWeight(FontWeight.Medium)
        .direction(Direction.Ltr)
    }
    .width('100%')
    .padding({ top: 3, bottom: 3 })
  }

  @Builder
  QadaYearRowView(row: QadaYearRow) {
    Row() {
      Column() {
        Text(`${row.hijriYear}`)
          .fontSize(12)
          .fontColor(this.colors.textMuted)
          .fontWeight(FontWeight.Bold)
          .direction(Direction.Ltr)
          .width('100%')
          .margin({ bottom: 4 })

        Flex({
          wrap: FlexWrap.Wrap,
          justifyContent: FlexAlign.Start,
          alignItems: ItemAlign.Center
        }) {
          this.YearStatChip(
            row.fasted, this.tr('qada_row_fasted_suffix'),
            this.colors.textWhite
          )
          this.YearStatChip(
            row.missed, this.tr('qada_row_missed_suffix'),
            this.colors.statusExpress
          )
          this.YearStatChip(
            row.madeUp, this.tr('qada_row_made_up_suffix'),
            this.colors.accentGoldLight
          )
          this.YearStatChip(
            row.unmarked, this.tr('qada_row_unmarked_suffix'),
            this.colors.textMuted
          )
        }
        .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text('›')
        .fontSize(18).fontColor(this.colors.accentGold).opacity(0.7)
        .margin({ left: 8 })
        .rotate({ angle: L.isRtl() ? 180 : 0 })
    }
    .width('100%')
    .padding({
      top: 8,
      bottom: 8,
      left: 4,
      right: 4
    })
    .alignItems(VerticalAlign.Center)
    .onClick(() => this.openQadaYearSheet(row.hijriYear))
  }

  @Builder
  YearStatChip(value: number, label: string, valueColor: string) {
    Row() {
      Text(`${value}`)
        .fontSize(12).fontColor(valueColor)
        .fontWeight(FontWeight.Medium)
        .direction(Direction.Ltr)
      Text(` ${label}`)
        .fontSize(10).fontColor(this.colors.textMuted)
    }
    .margin({ right: 12, bottom: 2 })
  }

  // ============================================================
  // TARAWEEH SECTION
  // ============================================================

  @Builder
  TaraweehSection() {
    Column() {
      Row({ space: 8 }) {
        Text('🌙').fontSize(16).flexShrink(0)
        Text(this.tr('section_taraweeh'))
          .fontSize(12)
          .fontColor(this.colors.textMuted)
          .fontWeight(FontWeight.Bold)
          .letterSpacing(1.2)
          .layoutWeight(1)
        if (this.currentYear !== null) {
          Text(`${this.countTaraweeh()} / ${this.currentYear.totalDays}`)
            .fontSize(12)
            .fontColor(this.colors.accentGold)
            .fontWeight(FontWeight.Medium)
            .direction(Direction.Ltr)
        }
      }
      .width('100%').padding({ bottom: 14 })

      if (this.currentYear !== null) {
        this.TaraweehGrid()
      }
    }
    .width('100%')
    .padding(18)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(Theme.radiusLarge)
    .border({
      width: 1,
      color: PageTheme.isDarkFor(this.themeMode)
        ? 'rgba(255, 255, 255, 0.08)'
        : this.colors.borderSoft
    })
    .shadow({
      radius: 12,
      color: this.colors.shadowCard,
      offsetX: 0,
      offsetY: 4
    })
    .margin({ bottom: 14 })
  }

  @Builder
  TaraweehGrid() {
    Column({ space: 4 }) {
      // Header row
      Row({ space: 4 }) {
        ForEach(L.getArray('days_of_week_short', this.currentLanguage), (day: string) => {
          Text(day)
            .fontSize(10)
            .fontColor(this.colors.textMuted)
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
        })
      }
      .width('100%')
      .margin({ bottom: 4 })

      // Weeks
      ForEach(this.buildWeeks(), (week: number[], wi: number) => {
        Row({ space: 4 }) {
          ForEach(week, (dayIndex: number, di: number) => {
            if (dayIndex === -1) {
              Column().layoutWeight(1).height(this.cellSize())
            } else {
              this.TaraweehGridCell(dayIndex)
            }
          }, (dayIndex: number, di: number) => `td-${wi}-${di}-${dayIndex}`)
        }
        .width('100%')
      }, (week: number[], wi: number) => `tw-${wi}`)
    }
    .width('100%')
  }

  @Builder
  TaraweehGridCell(idx: number) {
    Column() {
      Text(`${idx + 1}`)
        .fontSize(12)
        .fontWeight(
          this.currentYear!.taraweehNights[idx]
            ? FontWeight.Bold
            : FontWeight.Medium
        )
        .fontColor(this.taraweehTextColor(idx))
    }
    .layoutWeight(1)
    .height(this.cellSize())
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.taraweehBgColor(idx))
    .borderRadius(8)
    .border({
      width: this.isToday(idx) ? 2 : 1,
      color: this.isToday(idx)
        ? this.colors.accentGold
        : (this.currentYear!.taraweehNights[idx]
          ? this.colors.accentGold
          : this.colors.borderSoft)
    })
    .opacity(this.isTaraweehToggleable(idx) ? 1.0 : 0.35)
    .onClick(() => {
      if (this.isTaraweehToggleable(idx)) {
        this.toggleTaraweehNight(idx + 1);
      }
    })
  }

  private taraweehBgColor(idx: number): string {
    if (this.currentYear === null) {
      return this.colors.tintSubtle;
    }
    return this.currentYear.taraweehNights[idx]
      ? this.colors.accentGold
      : this.colors.tintSubtle;
  }

  private taraweehTextColor(idx: number): string {
    if (this.currentYear === null) {
      return this.colors.textMuted;
    }
    if (this.currentYear.taraweehNights[idx]) {
      return this.colors.textOnAccent;
    }
    if (this.isToday(idx)) {
      return this.colors.accentGold;
    }
    return this.colors.textMuted;
  }

  @Builder
  LoadingState() {
    Column() {
      LoadingProgress()
        .width(32).height(32)
        .color(this.colors.accentGold)
    }
    .width('100%')
    .padding({ top: 32, bottom: 32 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  EmptyState() {
    Column() {
      Text('🌙').fontSize(48).opacity(0.5)
      Text(this.tr('ramadan_not_active'))
        .fontSize(14)
        .fontColor(this.colors.textMuted)
        .textAlign(TextAlign.Center)
        .lineHeight(20)
        .padding({ left: 24, right: 24, top: 16 })
    }
    .width('100%')
    .padding({ top: 24, bottom: 24 })
    .alignItems(HorizontalAlign.Center)
  }

  // ============================================================
  // HEATMAP
  // ============================================================

  @Builder
  FastingHeatmap() {
    Column({ space: 4 }) {
      // Header row
      Row({ space: 4 }) {
        ForEach(L.getArray('days_of_week_short', this.currentLanguage), (day: string) => {
          Text(day)
            .fontSize(10)
            .fontColor(this.colors.textMuted)
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
        })
      }
      .width('100%')
      .margin({ bottom: 4 })

      // Weeks
      ForEach(this.buildWeeks(), (week: number[], wi: number) => {
        Row({ space: 4 }) {
          ForEach(week, (dayIndex: number, di: number) => {
            if (dayIndex === -1) {
              Column().layoutWeight(1).height(this.cellSize())
            } else {
              this.FastingGridCell(dayIndex)
            }
          }, (dayIndex: number, di: number) => `fd-${wi}-${di}-${dayIndex}`)
        }
        .width('100%')
      }, (week: number[], wi: number) => `fw-${wi}`)
    }
    .width('100%')
  }

  @Builder
  FastingGridCell(dayIndex: number) {
    Column() {
      Text(`${dayIndex + 1}`)
        .fontSize(12)
        .fontWeight(this.isToday(dayIndex) ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.cellTextColor(dayIndex))
    }
    .layoutWeight(1)
    .height(this.cellSize())
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.cellBg(dayIndex))
    .borderRadius(8)
    .border({
      width: this.isToday(dayIndex) ? 2 : 0,
      color: this.colors.accentGold
    })
    .opacity(this.isFuture(dayIndex) ? 0.45 : 1.0)
    .onClick(() => {
      if (!this.isFuture(dayIndex)) {
        this.openMarkSheet(dayIndex + 1);
      }
    })
  }

  private rowIndices(): number[] {
    const out: number[] = [];
    for (let i = 0; i < 6; i++) {
      out.push(i);
    }
    return out;
  }

  private colIndices(): number[] {
    const out: number[] = [];
    for (let i = 0; i < 5; i++) {
      out.push(i);
    }
    return out;
  }

  private cellSize(): number {
    if (this.breakpoint === Breakpoints.LG) {
      return 48;
    }
    if (this.breakpoint === Breakpoints.MD) {
      return 44;
    }
    return 38; // Was 48 for the 5-column layout
  }

  private isToday(idx: number): boolean {
    if (this.currentYear === null || this.ramadanInfo === null) {
      return false;
    }
    return (idx + 1) === this.ramadanInfo.currentDayNumber;
  }

  private isFuture(idx: number): boolean {
    if (this.ramadanInfo === null) {
      return false;
    }
    return (idx + 1) > this.ramadanInfo.currentDayNumber;
  }

  private cellBg(idx: number): string {
    if (this.currentYear === null) {
      return this.colors.tintSubtle;
    }
    const entry: FastingDay = this.currentYear.days[idx];
    if (this.isToday(idx) && entry.status === FastingStatus.UNMARKED) {
      return this.colors.tintSoft;
    }
    if (entry.status === FastingStatus.FASTED) {
      return this.colors.accentGold;
    }
    if (entry.status === FastingStatus.MISSED) {
      return this.colors.statusExpress;
    }
    return this.colors.tintSubtle;
  }

  private cellTextColor(idx: number): string {
    if (this.currentYear === null) {
      return this.colors.textMuted;
    }
    const entry: FastingDay = this.currentYear.days[idx];
    if (entry.status === FastingStatus.FASTED) {
      return this.colors.textOnAccent;
    }
    if (entry.status === FastingStatus.MISSED) {
      return '#FFFFFF';
    }
    if (this.isToday(idx)) {
      return this.colors.accentGold;
    }
    return this.colors.textMuted;
  }

  // ============================================================
  // SUMMARY ROW
  // ============================================================

  @Builder
  FastingSummary() {
    Row() {
      Column() {
        Text(`${this.countFasted()}`)
          .fontSize(22).fontWeight(FontWeight.Bold)
          .fontColor(this.colors.accentGold)
        Text(this.tr('fasting_summary_fasted'))
          .fontSize(10).fontColor(this.colors.textMuted)
          .margin({ top: 2 })
      }
      .layoutWeight(1).alignItems(HorizontalAlign.Start)

      Column() {
        Text(`${this.countMissed()}`)
          .fontSize(22).fontWeight(FontWeight.Bold)
          .fontColor(this.colors.statusExpress)
        Text(this.tr('fasting_summary_missed'))
          .fontSize(10).fontColor(this.colors.textMuted)
          .margin({ top: 2 })
      }
      .layoutWeight(1).alignItems(HorizontalAlign.Start)

      Column() {
        Text(`${this.countUnmarked()}`)
          .fontSize(22).fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textMuted)
        Text(this.tr('fasting_summary_unmarked'))
          .fontSize(10).fontColor(this.colors.textMuted)
          .margin({ top: 2 })
      }
      .layoutWeight(1).alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ top: 16, bottom: 4 })
  }

  // ============================================================
  // MARK SHEET
  // ============================================================

  @Builder
  MarkSheet() {
    Column()
      .width('100%').height('100%')
      .backgroundColor(this.colors.overlayDim)
      .onClick(() => {
        this.closeSheet();
      })

    Column() {
      Row()
        .width(44)
        .height(4)
        .backgroundColor(this.colors.overlayDimSoft)
        .borderRadius(2)
        .margin({ top: 10 })

      Row({ space: 14 }) {
        Text('📿')
          .fontSize(22)
          .width(44)
          .height(44)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.colors.tintSoft)
          .borderRadius(12)
          .border({ width: 1, color: this.colors.borderSoft })
          .flexShrink(0)

        Column() {
          Text(this.tr('fasting_mark_title'))
            .fontSize(18).fontWeight(FontWeight.Bold)
            .fontColor(this.colors.textWhite)
          Text(`${this.tr('fasting_day_label')} ${this.selectedDay}`)
            .fontSize(12).fontColor(this.colors.accentGold)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding({
        top: 20,
        bottom: 20,
        left: this.isRtl() ? 20 : 16,
        right: this.isRtl() ? 16 : 20
      })

      Divider().color(this.colors.borderSoft).width('90%')

      Scroll() {
        Column() {
          this.MarkOption(
            '✓',
            this.tr('fasting_status_fasted'),
            this.colors.accentGold,
            (): void => {
              this.markFasted();
            }
          )
          this.MarkOption(
            '✗',
            this.tr('fasting_status_missed'),
            this.colors.statusExpress,
            (): void => {
              this.activeSheet = 'reason';
            }
          )
          this.MarkOption(
            '↺',
            this.tr('fasting_clear'),
            this.colors.textMuted,
            (): void => {
              this.clearDay();
            }
          )
        }
        .width('100%')
        .padding({
          left: 8,
          right: 8,
          top: 12,
          bottom: 12
        })
      }
      .flexShrink(1)
      .width('100%')
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)

      Button(this.tr('cancel'))
        .width('90%')
        .height(48)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textWhite)
        .backgroundColor(this.colors.tintSoft)
        .borderRadius(12)
        .margin({ top: 8, bottom: 24 })
        .onClick(() => {
          this.closeSheet();
        })
    }
    .width('100%')
    .backgroundColor(this.colors.cardDark)
    .borderRadius({ topLeft: 28, topRight: 28 })
    .shadow({
      radius: 24,
      color: this.colors.shadowFloating,
      offsetX: 0,
      offsetY: -6
    })
    .border({ width: { top: 1 }, color: this.colors.borderSoft })
    .position({ bottom: 0 })
  }

  @Builder
  MarkOption(
    icon: string,
    label: string,
    color: string,
    onTap: () => void
  ) {
    Row() {
      Text(icon)
        .fontSize(20)
        .fontColor(color)
        .width(40)
        .height(40)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.colors.tintSoft)
        .borderRadius(20)
        .border({ width: 1, color: this.colors.borderSoft })
      Text(label)
        .fontSize(16)
        .fontColor(this.colors.textWhite)
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
        .margin({ left: 14 })
      Text('›')
        .fontSize(22).fontColor(this.colors.accentGold).opacity(0.7)
        .rotate({ angle: L.isRtl() ? 180 : 0 })
    }
    .width('100%')
    .padding({
      top: 12,
      bottom: 12,
      left: 16,
      right: 20
    })
    .borderRadius(12)
    .margin({ bottom: 6 })
    .onClick(onTap)
  }

  // ============================================================
  // REASON SHEET
  // ============================================================

  @Builder
  ReasonSheet() {
    Column()
      .width('100%').height('100%')
      .backgroundColor(this.colors.overlayDim)
      .onClick(() => {
        this.closeSheet();
      })

    Column() {
      Row()
        .width(44)
        .height(4)
        .backgroundColor(this.colors.overlayDimSoft)
        .borderRadius(2)
        .margin({ top: 10 })

      Row({ space: 14 }) {
        Text('💭')
          .fontSize(22)
          .width(44)
          .height(44)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.colors.tintSoft)
          .borderRadius(12)
          .border({ width: 1, color: this.colors.borderSoft })
          .flexShrink(0)

        Column() {
          Text(this.tr('fasting_reason_title'))
            .fontSize(18).fontWeight(FontWeight.Bold)
            .fontColor(this.colors.textWhite)
          Text(`${this.tr('fasting_day_label')} ${this.selectedDay}`)
            .fontSize(12).fontColor(this.colors.accentGold)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding({
        top: 20,
        bottom: 20,
        left: this.isRtl() ? 20 : 16,
        right: this.isRtl() ? 16 : 20
      })

      Divider().color(this.colors.borderSoft).width('90%')

      Scroll() {
        Column() {
          ForEach(this.allReasons(), (reason: MissedReason) => {
            this.ReasonRow(reason)
          }, (reason: MissedReason) => `reason-${reason}`)
        }
        .width('100%')
        .padding({
          left: 8,
          right: 8,
          top: 12,
          bottom: 12
        })
      }
      .flexShrink(1)
      .width('100%')
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)

      if (this.selectedReason === MissedReason.OTHER) {
        Column() {
          Text(this.tr('fasting_reason_custom_label'))
            .fontSize(11).fontColor(this.colors.textMuted)
            .width('100%').margin({ bottom: 6 })
          TextInput({
            text: this.customReasonText,
            placeholder: this.tr('fasting_reason_custom_placeholder')
          })
            .type(InputType.Normal)
            .onChange((v: string) => {
              this.customReasonText = v;
            })
            .fontSize(14)
            .fontColor(this.colors.textWhite)
            .placeholderColor(this.colors.placeholder)
            .caretColor(this.colors.accentGold)
            .backgroundColor(this.colors.tintSoft)
            .borderRadius(8)
            .padding({
              left: 12,
              right: 12,
              top: 8,
              bottom: 8
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 12 })

        Button(this.tr('save'))
          .width('90%')
          .height(48)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.textOnAccent)
          .backgroundColor(this.colors.accentGold)
          .borderRadius(12)
          .margin({ top: 8, bottom: 8 })
          .onClick(() => {
            this.confirmMissed();
          })
      }

      Button(this.tr('cancel'))
        .width('90%')
        .height(44)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textWhite)
        .backgroundColor(this.colors.tintSoft)
        .borderRadius(12)
        .margin({ top: 4, bottom: 24 })
        .onClick(() => {
          this.closeSheet();
        })
    }
    .width('100%')
    .backgroundColor(this.colors.cardDark)
    .borderRadius({ topLeft: 28, topRight: 28 })
    .shadow({
      radius: 24,
      color: this.colors.shadowFloating,
      offsetX: 0,
      offsetY: -6
    })
    .border({ width: { top: 1 }, color: this.colors.borderSoft })
    .position({ bottom: 0 })
  }

  @Builder
  ReasonRow(reason: MissedReason) {
    Row() {
      Row() {
        if (this.selectedReason === reason) {
          Row()
            .width(10).height(10)
            .borderRadius(5)
            .backgroundColor(this.colors.accentGold)
        }
      }
      .width(22)
      .height(22)
      .borderRadius(11)
      .border({
        width: this.selectedReason === reason ? 2 : 1.5,
        color: this.selectedReason === reason
          ? this.colors.accentGold
          : this.colors.borderStrong
      })
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      Text(this.tr(`fasting_reason_${reason}`))
        .fontSize(15)
        .fontColor(this.selectedReason === reason
          ? this.colors.accentGold
          : this.colors.textWhite)
        .fontWeight(this.selectedReason === reason
          ? FontWeight.Bold
          : FontWeight.Normal)
        .layoutWeight(1)
        .margin({ left: 14 })
    }
    .width('100%')
    .padding({
      top: 14,
      bottom: 14,
      left: 16,
      right: 16
    })
    .backgroundColor(this.selectedReason === reason
      ? this.colors.tintSoft
      : 'transparent')
    .borderRadius(12)
    .margin({ bottom: 4 })
    .onClick(() => {
      if (reason === MissedReason.OTHER) {
        this.selectedReason = MissedReason.OTHER;
      } else {
        this.selectedReason = reason;
        this.confirmMissed();
      }
    })
  }

  // ============================================================
  // QADA YEAR SHEET — per-day made-up marking
  // ============================================================

  @Builder
  QadaYearSheet() {
    Column() {
      Row()
        .width(44)
        .height(4)
        .backgroundColor(this.colors.overlayDimSoft)
        .borderRadius(2)
        .margin({ top: 10 })

      Row({ space: 14 }) {
        Text('🔄')
          .fontSize(22)
          .width(44)
          .height(44)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.colors.tintSoft)
          .borderRadius(12)
          .border({ width: 1, color: this.colors.borderSoft })
          .flexShrink(0)

        Column() {
          Text(`${this.tr('qada_year_sheet_title_prefix')} ` +
            `${this.activeQadaYear} ${this.tr('hijri_year_suffix')}`)
            .fontSize(18).fontWeight(FontWeight.Bold)
            .fontColor(this.colors.textWhite)
          Text(this.qadaYearSheetSubtitle())
            .fontSize(11)
            .fontColor(this.colors.textMuted)
            .margin({ top: 2 })
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding({
        top: 20,
        bottom: 20,
        left: this.isRtl() ? 20 : 16,
        right: this.isRtl() ? 16 : 20
      })

      Divider().color(this.colors.borderSoft).width('90%')

      if (this.qadaYearDays.length === 0) {
        Column() {
          Text(this.tr('qada_year_sheet_empty'))
            .fontSize(13)
            .fontColor(this.colors.textMuted)
            .textAlign(TextAlign.Center)
            .lineHeight(18)
            .padding({
              top: 24,
              bottom: 24,
              left: 24,
              right: 24
            })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column() {
            ForEach(this.qadaYearDays, (entry: QadaDayEntry) => {
              this.QadaDayRowView(entry)
            }, (entry: QadaDayEntry) =>
            `qd-${entry.dayNumber}-${entry.madeUp ? 'y' : 'n'}-` +
              `${entry.reason ?? 'x'}`)
          }
          .width('100%')
          .padding({
            left: 8,
            right: 8,
            top: 8,
            bottom: 8
          })
        }
        .flexShrink(1)
        .width('100%')
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
      }

      Button(this.tr('close'))
        .width('90%')
        .height(44)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textWhite)
        .backgroundColor(this.colors.tintSoft)
        .borderRadius(12)
        .margin({ top: 8, bottom: 24 })
        .onClick(() => this.closeQadaYearSheet())
    }
    .width('100%').constraintSize({ maxHeight: '85%' })
    .backgroundColor(this.colors.cardDark)
  }

  private qadaYearSheetSubtitle(): string {
    const total = this.qadaYearDays.length;
    const done = this.countMadeUpInActiveYear();
    return `${done} ${this.tr('qada_of')} ${total} ` +
      `${this.tr('qada_made_up_of_total')}`;
  }

  @Builder
  QadaDayRowView(entry: QadaDayEntry) {
    Row() {
      Column() {
        Row() {
          Text(`${this.tr('fasting_day_label')} ${entry.dayNumber}`)
            .fontSize(14).fontColor(this.colors.textWhite)
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')

        Row() {
          Text(RamadanHelper.formatShort(
            entry.gregorianDate, this.currentLanguage))
            .fontSize(11).fontColor(this.colors.textMuted)
            .direction(Direction.Ltr)
          if (entry.reason !== null) {
            Text('  ·  ').fontSize(11).fontColor(this.colors.textMuted)
            Text(this.tr(`fasting_reason_${entry.reason}`))
              .fontSize(11)
              .fontColor(this.colors.accentGold)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
          }
        }
        .width('100%')
        .margin({ top: 2 })
        .alignItems(VerticalAlign.Center)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // Toggle state — button or badge
      if (entry.madeUp) {
        Row() {
          Text('✓').fontSize(12).fontColor(this.colors.textOnAccent)
            .fontWeight(FontWeight.Bold).margin({ right: 4 })
          Text(this.tr('qada_day_made_up'))
            .fontSize(11).fontColor(this.colors.textOnAccent)
            .fontWeight(FontWeight.Medium)
        }
        .padding({
          left: 12,
          right: 12,
          top: 6,
          bottom: 6
        })
        .backgroundColor(this.colors.accentGold)
        .borderRadius(14)
      } else {
        Row() {
          Text(this.tr('qada_day_mark_made_up'))
            .fontSize(11).fontColor(this.colors.accentGold)
            .fontWeight(FontWeight.Medium)
        }
        .padding({
          left: 12,
          right: 12,
          top: 6,
          bottom: 6
        })
        .backgroundColor(this.colors.tintSoft)
        .borderRadius(14)
        .border({ width: 1, color: this.colors.borderSoft })
      }
    }
    .width('100%')
    .padding({
      left: 12,
      right: 12,
      top: 10,
      bottom: 10
    })
    .backgroundColor(entry.madeUp
      ? this.colors.tintSubtle : 'transparent')
    .borderRadius(10)
    .margin({ bottom: 4 })
    .alignItems(VerticalAlign.Center)
    .opacity(this.isQadaToggleAllowed() ? 1.0 : 0.55)
    .onClick(() => {
      if (this.isQadaToggleAllowed()) {
        this.toggleDayMadeUp(entry.dayNumber);
      }
    })
  }

  private isQadaToggleAllowed(): boolean {
    if (this.ramadanInfo !== null && this.ramadanInfo.isRamadanNow) {
      return false;
    }
    return true;
  }

  // ============================================================
  // ABOUT THIS RAMADAN — grouped wrapper
  // ============================================================
  //
  // Ashras, Laylat al-Qadr, and Jummah tul Widah share one card
  // shell. Previously each occupied its own card, which gave the
  // page five near-identical visual blocks during Ramadan. Grouping
  // them under a single heading clarifies the hierarchy: primary
  // tracking (Fasting, Taraweeh) sits above; context/reference
  // (this group) sits below.

  @Builder
  AboutRamadanSection() {
    Column() {
      // Group heading
      Row() {
        Text(this.tr('ramadan_about_this_month'))
          .fontSize(11)
          .fontColor(this.colors.accentGold)
          .fontWeight(FontWeight.Bold)
          .letterSpacing(1.5)
          .width('100%')
      }
      .width('100%')
      .padding({ bottom: 14 })

      // ---- Ashras ----
      this.AshrasContent()

      Divider()
        .color(this.colors.borderSoft)
        .margin({ top: 16, bottom: 16 })

      // ---- Laylat al-Qadr ----
      this.LaylatAlQadrContent()

      // ---- Jummah tul Widah (only when present) ----
      if (this.ramadanInfo!.jummahTulWidah !== null) {
        Divider()
          .color(this.colors.borderSoft)
          .margin({ top: 16, bottom: 16 })
        this.JummahTulWidahContent()
      }
    }
    .width('100%')
    .padding(18)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(Theme.radiusLarge)
    .border({
      width: 1,
      color: PageTheme.isDarkFor(this.themeMode)
        ? 'rgba(255, 255, 255, 0.08)'
        : this.colors.borderSoft
    })
    .shadow({
      radius: 12,
      color: this.colors.shadowCard,
      offsetX: 0,
      offsetY: 4
    })
    .margin({ bottom: 14 })
  }

  // ---- Ashras content (no outer card) ----

  @Builder
  AshrasContent() {
    Column() {
      Row({ space: 6 }) {
        Text('📖').fontSize(14).flexShrink(0)
        Text(this.tr('ramadan_ashras'))
          .fontSize(11)
          .fontColor(this.colors.textMuted)
          .fontWeight(FontWeight.Bold)
          .letterSpacing(1.2)
          .layoutWeight(1)
        if (this.currentAshra() !== null) {
          Text(this.tr(this.currentAshra()!.nameKey))
            .fontSize(11).fontColor(this.colors.accentGold)
            .fontWeight(FontWeight.Medium)
        }
      }
      .width('100%').padding({ bottom: 12 })

      Column() {
        ForEach(this.ramadanInfo!.ashras, (a: RamadanAshra) => {
          this.AshraRow(a)
        }, (a: RamadanAshra) =>
        `ashra-${a.number}-${a.startHijriDay}-${a.endHijriDay}`)
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  // ---- Laylat al-Qadr content (no outer card) ----

  @Builder
  LaylatAlQadrContent() {
    Column() {
      Row({ space: 6 }) {
        Text('✨').fontSize(14).flexShrink(0)
        Text(this.tr('ramadan_laylat_al_qadr'))
          .fontSize(11)
          .fontColor(this.colors.accentGold)
          .fontWeight(FontWeight.Bold)
          .letterSpacing(1.2)
          .layoutWeight(1)
      }
      .width('100%').padding({ bottom: 8 })

      Text(this.tr('ramadan_laylat_al_qadr_desc'))
        .fontSize(11)
        .fontColor(this.colors.textMuted)
        .lineHeight(16)
        .width('100%')
        .padding({ bottom: 12 })

      Row({ space: 6 }) {
        ForEach(this.ramadanInfo!.laylatAlQadrNights,
          (n: LaylatAlQadrNight) => {
            this.LaylatNightCell(n)
          }, (n: LaylatAlQadrNight) =>
          `laq-${n.hijriDay}-${n.isPast ? 'p' : n.isToday ? 't' : 'f'}`)
      }
      .width('100%').justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  // ---- Jummah tul Widah content (no outer card) ----

  @Builder
  JummahTulWidahContent() {
    Column() {
      Row({ space: 6 }) {
        Text('🕌').fontSize(14).flexShrink(0)
        Text(this.tr('ramadan_jummah_tul_widah'))
          .fontSize(11)
          .fontColor(this.colors.accentGold)
          .fontWeight(FontWeight.Bold)
          .letterSpacing(1.2)
          .layoutWeight(1)
        Text(RamadanHelper.formatShort(
          this.ramadanInfo!.jummahTulWidah!, this.currentLanguage))
          .fontSize(12).fontColor(this.colors.accentGoldLight)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%').padding({ bottom: 8 })

      Text(this.tr('ramadan_jummah_tul_widah_desc'))
        .fontSize(12).fontColor(this.colors.textMuted)
        .lineHeight(18).width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  AshraRow(a: RamadanAshra) {
    Row({ space: 10 }) {
      Text(`${a.number}`)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isCurrentAshra(a)
          ? this.colors.textOnAccent : this.colors.accentGold)
        .width(24)
        .height(24)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.isCurrentAshra(a)
          ? this.colors.accentGold : this.colors.tintSoft)
        .borderRadius(12)
        .border({
          width: 1,
          color: this.isCurrentAshra(a)
            ? this.colors.accentGold : this.colors.borderSoft
        })
        .flexShrink(0) // <-- Prevents circle squishing

      Column() {
        Row() {
          Text(this.tr(a.nameKey))
            .fontSize(13).fontColor(this.colors.textWhite)
            .fontWeight(this.isCurrentAshra(a)
              ? FontWeight.Bold : FontWeight.Medium)
          Text('  ·  ').fontSize(11).fontColor(this.colors.textMuted)
          Text(this.tr(a.significanceKey))
            .fontSize(11)
            .fontColor(this.colors.accentGold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%')

        Text(`${RamadanHelper.formatShort(a.startDate, this.currentLanguage)} – ` +
          `${RamadanHelper.formatShort(a.endDate, this.currentLanguage)}`)
          .fontSize(10).fontColor(this.colors.textMuted)
          .margin({ top: 2 }).width('100%')
      }
      .layoutWeight(1) // <-- Removed margin({ left: 10 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({
      top: 8,
      bottom: 8,
      left: 8,
      right: 8
    })
    .backgroundColor(this.isCurrentAshra(a)
      ? this.colors.tintSubtle : 'transparent')
    .borderRadius(10)
    .margin({ bottom: 4 })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  LaylatNightCell(n: LaylatAlQadrNight) {
    Column() {
      Text(`${n.hijriDay}`)
        .fontSize(14)
        .fontWeight(n.isToday ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(n.isToday ? this.colors.textOnAccent
          : n.isPast ? this.colors.textMuted : this.colors.accentGold)
      if (n.isToday) {
        Text(this.tr('ramadan_today'))
          .fontSize(8).fontColor(this.colors.textOnAccent)
          .margin({ top: 1 })
      } else {
        Text(RamadanHelper.formatShort(
          n.gregorianDate, this.currentLanguage))
          .fontSize(8).fontColor(this.colors.textMuted)
          .margin({ top: 1 })
      }
    }
    .layoutWeight(1)
    .padding({ top: 8, bottom: 8 })
    .backgroundColor(n.isToday ? this.colors.accentGold
      : n.isPast ? 'transparent' : this.colors.tintSubtle)
    .borderRadius(10)
    .border({
      width: n.isToday ? 0 : 1,
      color: n.isPast
        ? this.colors.borderSoft : this.colors.borderMedium
    })
    .opacity(n.isPast && !n.isToday ? 0.55 : 1.0)
    .alignItems(HorizontalAlign.Center)
  }

  // ============================================================
  // DUAS SECTION
  // ============================================================

  @Builder
  DuasSection() {
    Column() {
      // FIX: Use Row({ space: 8 }) for consistent RTL/LTR alignment
      Row({ space: 8 }) {
        Text('🤲').fontSize(16).flexShrink(0)
        Text(this.tr('section_duas'))
          .fontSize(12)
          .fontColor(this.colors.textMuted)
          .fontWeight(FontWeight.Bold)
          .letterSpacing(1.2)
          .layoutWeight(1)
      }
      .width('100%').padding({ bottom: 14 })

      Column() {
        DuaCard({
          dua: DUA_SUHOOR,
          colors: this.colors,
          currentLanguage: this.currentLanguage,
          showName: true
        })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(this.colors.tintSubtle)
      .borderRadius(12)
      .margin({ bottom: 10 })

      Column() {
        DuaCard({
          dua: DUA_IFTAR,
          colors: this.colors,
          currentLanguage: this.currentLanguage,
          showName: true
        })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(this.colors.tintSubtle)
      .borderRadius(12)
    }
    .width('100%')
    .padding(18)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(Theme.radiusLarge)
    .border({
      width: 1,
      color: PageTheme.isDarkFor(this.themeMode)
        ? 'rgba(255, 255, 255, 0.08)'
        : this.colors.borderSoft
    })
    .shadow({
      radius: 12,
      color: this.colors.shadowCard,
      offsetX: 0,
      offsetY: 4
    })
    .margin({ bottom: 14 })
  }

  private buildWeeks(): number[][] {
    if (this.ramadanInfo === null || this.currentYear === null) {
      return [];
    }
    const totalDays = this.currentYear.totalDays;
    const firstDow = this.ramadanInfo.fastingStart.getDay(); // 0 = Sunday

    const padded: number[] = [];
    // Leading padding to align with the correct day of the week
    for (let i = 0; i < firstDow; i++) {
      padded.push(-1);
    }
    // Actual days (0-indexed)
    for (let i = 0; i < totalDays; i++) {
      padded.push(i);
    }
    // Trailing padding to complete the last row
    while (padded.length % 7 !== 0) {
      padded.push(-1);
    }

    const weeks: number[][] = [];
    for (let i = 0; i < padded.length; i += 7) {
      weeks.push(padded.slice(i, i + 7));
    }
    return weeks;
  }
}