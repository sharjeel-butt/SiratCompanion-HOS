// entry/src/main/ets/pages/RamadanDetailsPage.ets

import { router } from '@kit.ArkUI';
import { Theme, ThemeColors, ThemeMode, ThemePreset } from '../common/Theme';
import { PageTheme } from '../common/PageTheme';
import { TaraweehManager } from '../utils/TaraweehManager';
import { STORAGE_KEY_TARAWEEH_STATE_VERSION } from '../common/StorageKeys';
import {
  STORAGE_KEY_APP_THEME,
  STORAGE_KEY_BREAKPOINT,
  STORAGE_KEY_FASTING_STATE_VERSION,
  STORAGE_KEY_HIJRI_OFFSET,
  STORAGE_KEY_LANGUAGE,
  STORAGE_KEY_THEME_MODE
} from '../common/StorageKeys';
import { L } from '../i8n/LocalizationHelper';
import { Breakpoints } from '../common/Breakpoints';
import { LaylatAlQadrNight, RamadanAshra, RamadanHelper, RamadanInfo } from '../helper/RamadanHelper';
import { FastingManager, FastingStats, MissedRecord, HistoryRecord, QadaStats } from '../utils/FastingManager';
import { HijriCalendarHelper } from '../hijricalendar/HijriCalendarHelper';
import { DUA_IFTAR, DUA_SUHOOR } from '../data/Duas';
import { DuaCard } from '../components/DuaCard';
import { SettingsHelper, PrayerOffsets } from '../helper/SettingsHelper';
import { HomeController } from '../utils/HomeController';
import {
  PrayerTimeCalculator,
  CalculationMethod,
  AsrShadowRule,
  HighLatitudeRule
} from '../prayer/PrayerTimeCalculator';
import { PrayerManager } from '../prayer/PrayerManager';
import { CalculationSource } from '../models/SettingsModels';
import { AdvancedCalcSettings, DEFAULT_ADVANCED_CALC } from '../models/AdvancedCalcModels';

interface RamadanDayCell {
  hijriDay: number;
  gregorianDate: Date;
  dateKey: string;
  status: 'fasted' | 'missed' | 'not_marked' | 'future';
  isToday: boolean;
}

@Entry
@Component
struct RamadanDetailsPage {
  @StorageLink(STORAGE_KEY_THEME_MODE) @Watch('onThemeChanged') themeMode: string = ThemeMode.SYSTEM;
  @StorageLink(STORAGE_KEY_APP_THEME) @Watch('onThemeChanged') appTheme: string = ThemePreset.SIRAT;
  @StorageLink(STORAGE_KEY_LANGUAGE) @Watch('onLanguageChanged') appLanguage: string = 'en';
  @StorageLink(STORAGE_KEY_HIJRI_OFFSET) @Watch('onHijriOffsetChanged') hijriOffset: number = 0;
  @StorageLink(STORAGE_KEY_BREAKPOINT) breakpoint: string = 'sm';
  @StorageLink(STORAGE_KEY_FASTING_STATE_VERSION) @Watch('refreshFastingState') fastingVersion: number = 0;
  @StorageLink(STORAGE_KEY_TARAWEEH_STATE_VERSION) @Watch('refreshTaraweehState') taraweehVersion: number = 0;
  @State private isTaraweehToday: boolean = false;
  @State colors: ThemeColors = PageTheme.compute(ThemeMode.LIGHT);
  @State currentLanguage: string = 'en';
  @State ramadanInfo: RamadanInfo | null = null;
  @State fastingStats: FastingStats = { fasted: 0, missed: 0, missedRecords: [] };
  @State ramadanWeeks: Array<Array<RamadanDayCell | null>> = [];
  // Bottom Sheet State
  @State showEditSheet: boolean = false;
  @State selectedCell: RamadanDayCell | null = null;
  @State editReason: string = '';
  // Past History State
  @State pastFasted: string[] = [];
  @State pastMissed: HistoryRecord[] = [];
  @State pastNotMarked: string[] = [];
  // Accordion State
  @State isFastedExpanded: boolean = false;
  @State isMissedExpanded: boolean = false;
  @State isNotMarkedExpanded: boolean = false;
  @State qadaStats: QadaStats = { totalMissed: 0, qadaDone: 0, remaining: 0 };
  // Calculation Settings (needed for today's times)
  @State private latitude: number = 0;
  @State private longitude: number = 0;
  @State private calcMethod: CalculationMethod = CalculationMethod.KARACHI;
  @State private asrRule: AsrShadowRule = AsrShadowRule.STANDARD;
  @State private highLatRule: HighLatitudeRule = HighLatitudeRule.NONE;
  @State private offsets: PrayerOffsets = {
    fajr: 0,
    dhuhr: 0,
    asr: 0,
    maghrib: 0,
    isha: 0
  };
  @State private advanced: AdvancedCalcSettings = DEFAULT_ADVANCED_CALC;
  @State private calcSource: CalculationSource = CalculationSource.LOCAL;
  // Countdown State
  @State private todayImsakTime: string = '--:--';
  @State private todayMaghribTime: string = '--:--';
  @State private countdownTarget: string = '';
  @State private countdownDisplay: string = '';
  @State private countdownHeld: boolean = false;
  private countdownTimerId: number = -1;

  aboutToAppear(): void {
    this.currentLanguage = this.appLanguage;
    this.colors = PageTheme.compute(this.themeMode);
    this.refreshAll();
    this.refreshTaraweehState();
    this.loadSettingsAndLocation();
    this.startCountdownTimer();
  }

  onPageShow(): void {
    this.colors = PageTheme.compute(this.themeMode);
    this.refreshAll();
    this.startCountdownTimer();
  }

  onPageHide(): void {
    this.stopCountdownTimer();
  }

  aboutToDisappear(): void {
    this.stopCountdownTimer();
  }

  private refreshAll(): void {
    this.ramadanInfo = RamadanHelper.getRamadanInfo(this.hijriOffset);
    this.refreshFastingState();
  }

  private refreshFastingState(): void {
    if (this.ramadanInfo !== null) {
      this.fastingStats = FastingManager.getStats(
        this.ramadanInfo.fastingStart,
        this.ramadanInfo.fastingEnd
      );
      this.qadaStats = FastingManager.getQadaStats(); // <--- Add this
      this.ramadanWeeks = this.buildRamadanWeeks();
      this.buildPastHistory();
    }
  }

  private refreshTaraweehState(): void {
    const todayKey = TaraweehManager.getDateKey(new Date());
    this.isTaraweehToday = TaraweehManager.isTaraweeh(todayKey);
  }

  private toggleTaraweeh(isOn: boolean): void {
    const todayKey = TaraweehManager.getDateKey(new Date());
    TaraweehManager.toggleTaraweeh(todayKey, isOn);
    this.isTaraweehToday = isOn;
  }

  private async loadSettingsAndLocation(): Promise<void> {
    const data = await SettingsHelper.loadAll();
    this.calcMethod = data.method;
    this.asrRule = data.asr;
    this.calcSource = data.source;
    this.highLatRule = await SettingsHelper.getHighLatRule();
    this.offsets = await SettingsHelper.getPrayerOffsets();
    this.advanced = await SettingsHelper.getAdvancedCalcSettings();

    const mode = await SettingsHelper.getLocationMode();
    const loc = await HomeController.loadLocationForMode(mode);
    this.latitude = loc.latitude;
    this.longitude = loc.longitude;

    this.refreshFastingWindow();
  }

  private refreshFastingWindow(): void {
    if (this.calcSource !== CalculationSource.LOCAL) {
      return;
    }
    if (this.latitude === 0 && this.longitude === 0) {
      return;
    }

    const targetDate = new Date();
    try {
      const times = PrayerTimeCalculator.calculateWithDeviceTimezone(
        targetDate, this.latitude, this.longitude,
        this.calcMethod, this.asrRule, this.highLatRule, this.advanced
      );
      this.todayImsakTime = PrayerManager.offsetTime(times.imsak, this.offsets.fajr);
      this.todayMaghribTime = PrayerManager.offsetTime(times.maghrib, this.offsets.maghrib);
      this.updateCountdown();
    } catch (err) {
      console.error('[RamadanDetailsPage] refreshFastingWindow failed:', err);
    }
  }

  private parseTimeToDateToday(timeStr: string): Date | null {
    const trimmed = timeStr.trim();
    if (trimmed === '' || trimmed === '--:--') {
      return null;
    }

    const parts = trimmed.split(' ');
    if (parts.length !== 2) {
      return null;
    }

    const tp = parts[0].split(':');
    if (tp.length !== 2) {
      return null;
    }

    let hours = parseInt(tp[0], 10);
    const minutes = parseInt(tp[1], 10);
    if (isNaN(hours) || isNaN(minutes)) {
      return null;
    }

    const period = parts[1].toUpperCase();
    if (period === 'PM' && hours !== 12) {
      hours += 12;
    }
    if (period === 'AM' && hours === 12) {
      hours = 0;
    }

    const d = new Date();
    d.setHours(hours, minutes, 0, 0);
    return d;
  }

  private updateCountdown(): void {
    if (this.ramadanInfo === null || !this.ramadanInfo.isRamadanNow) {
      this.clearCountdown();
      return;
    }

    const WINDOW_MS = 15 * 60 * 1000;
    const HOLD_MS = 5 * 60 * 1000;
    const nowMs = Date.now();

    const imsak = this.parseTimeToDateToday(this.todayImsakTime);
    const maghrib = this.parseTimeToDateToday(this.todayMaghribTime);

    let holdTarget = '';
    let holdRemainingMs = Number.MAX_VALUE;

    if (maghrib !== null) {
      const delta = nowMs - maghrib.getTime();
      if (delta >= 0 && delta < HOLD_MS) {
        const remaining = HOLD_MS - delta;
        if (remaining < holdRemainingMs) {
          holdRemainingMs = remaining;
          holdTarget = 'maghrib';
        }
      }
    }
    if (imsak !== null) {
      const delta = nowMs - imsak.getTime();
      if (delta >= 0 && delta < HOLD_MS) {
        const remaining = HOLD_MS - delta;
        if (remaining < holdRemainingMs) {
          holdRemainingMs = remaining;
          holdTarget = 'imsak';
        }
      }
    }

    if (holdTarget !== '') {
      if (this.countdownTarget !== holdTarget) {
        this.countdownTarget = holdTarget;
      }
      if (this.countdownDisplay !== '00:00') {
        this.countdownDisplay = '00:00';
      }
      if (!this.countdownHeld) {
        this.countdownHeld = true;
      }
      return;
    }

    let target = '';
    let diffMs = Number.MAX_VALUE;

    if (imsak !== null) {
      const d = imsak.getTime() - nowMs;
      if (d > 0 && d <= WINDOW_MS && d < diffMs) {
        target = 'imsak';
        diffMs = d;
      }
    }
    if (maghrib !== null) {
      const d = maghrib.getTime() - nowMs;
      if (d > 0 && d <= WINDOW_MS && d < diffMs) {
        target = 'maghrib';
        diffMs = d;
      }
    }

    if (target === '') {
      this.clearCountdown();
      return;
    }

    const totalSec = Math.max(0, Math.floor(diffMs / 1000));
    const mm = Math.floor(totalSec / 60);
    const ss = totalSec % 60;
    const display = `${mm.toString().padStart(2, '0')}:${ss.toString().padStart(2, '0')}`;

    if (this.countdownTarget !== target) {
      this.countdownTarget = target;
    }
    if (this.countdownDisplay !== display) {
      this.countdownDisplay = display;
    }
    if (this.countdownHeld) {
      this.countdownHeld = false;
    }
  }

  private clearCountdown(): void {
    if (this.countdownTarget !== '') {
      this.countdownTarget = '';
    }
    if (this.countdownDisplay !== '') {
      this.countdownDisplay = '';
    }
    if (this.countdownHeld) {
      this.countdownHeld = false;
    }
  }

  private startCountdownTimer(): void {
    if (this.countdownTimerId !== -1) {
      return;
    }
    this.updateCountdown();
    this.countdownTimerId = setInterval(() => {
      this.updateCountdown();
    }, 1000);
  }

  private stopCountdownTimer(): void {
    if (this.countdownTimerId !== -1) {
      clearInterval(this.countdownTimerId);
      this.countdownTimerId = -1;
    }
  }

  private onThemeChanged(): void {
    this.colors = PageTheme.compute(this.themeMode);
  }

  private onLanguageChanged(): void {
    this.currentLanguage = this.appLanguage;
  }

  private onHijriOffsetChanged(): void {
    this.refreshAll();
  }

  // ============================================================
  // HISTORY LOGIC
  // ============================================================

  private buildPastHistory(): void {
    if (!this.ramadanInfo) {
      return;
    }

    const currentStartKey = FastingManager.getDateKey(this.ramadanInfo.fastingStart);
    const pastRecords = FastingManager.getPastHistory(currentStartKey);

    const fasted: string[] = [];
    const missed: HistoryRecord[] = [];

    // 1. Populate Fasted and Missed
    for (let i = 0; i < pastRecords.length; i++) {
      const rec = pastRecords[i];
      if (rec.status === 'fasted') {
        fasted.push(rec.dateKey);
      } else if (rec.status === 'missed') {
        missed.push(rec);
      }
    }

    // 2. Calculate Not Marked (Previous Ramadan only)
    const notMarked: string[] = [];
    const prevYear = this.ramadanInfo.hijriYear - 1;

    // Find the start of the previous Ramadan
    // We search from roughly 1 year before the current Ramadan start
    const searchAnchor = new Date(this.ramadanInfo.fastingStart.getTime() - 400 * 86400000);
    const prevStart = HijriCalendarHelper.findGregorianForHijri(prevYear, 9, 1, this.hijriOffset, searchAnchor);

    if (prevStart) {
      // Find the start of the next month (Shawwal 1) to determine the end of Ramadan
      const prevNextMonth = HijriCalendarHelper.findGregorianForHijri(prevYear, 10, 1, this.hijriOffset, prevStart);

      if (prevNextMonth) {
        const endMs = prevNextMonth.getTime() - 86400000; // 1 day before Shawwal
        for (let ms = prevStart.getTime(); ms <= endMs; ms += 86400000) {
          const key = FastingManager.getDateKey(new Date(ms));

          // If it's not in fasted and not in missed, it's Not Marked
          const isFasted = fasted.indexOf(key) !== -1;
          const isMissed = missed.some((m: HistoryRecord) => m.dateKey === key);

          if (!isFasted && !isMissed) {
            notMarked.push(key);
          }
        }
      }
    }

    // Sort chronologically (newest first)
    fasted.sort((a, b) => a > b ? -1 : 1);
    missed.sort((a, b) => a.dateKey > b.dateKey ? -1 : 1);
    notMarked.sort((a, b) => a > b ? -1 : 1);

    this.pastFasted = fasted;
    this.pastMissed = missed;
    this.pastNotMarked = notMarked;
  }

  // ============================================================
  // CALENDAR GRID LOGIC
  // ============================================================

  private buildRamadanWeeks(): Array<Array<RamadanDayCell | null>> {
    if (!this.ramadanInfo) {
      return [];
    }
    const weeks: Array<Array<RamadanDayCell | null>> = [];
    let currentWeek: Array<RamadanDayCell | null> = [];

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const startDate = new Date(this.ramadanInfo.fastingStart);
    startDate.setHours(0, 0, 0, 0);

    const startDow = startDate.getDay();
    for (let i = 0; i < startDow; i++) {
      currentWeek.push(null);
    }

    for (let i = 0; i < this.ramadanInfo.totalDays; i++) {
      const date = new Date(startDate.getTime() + i * 86400000);
      const dateKey = FastingManager.getDateKey(date);
      const isToday = date.getTime() === today.getTime();
      const isFuture = date.getTime() > today.getTime();

      let status: 'fasted' | 'missed' | 'not_marked' | 'future' = 'not_marked';
      if (isFuture) {
        status = 'future';
      } else {
        const rec = FastingManager.getRecord(dateKey);
        if (rec) {
          status = rec.status;
        }
      }

      const cell: RamadanDayCell = {
        hijriDay: i + 1,
        gregorianDate: date,
        dateKey,
        status,
        isToday
      };

      currentWeek.push(cell);
      if (currentWeek.length === 7) {
        weeks.push(currentWeek);
        currentWeek = [];
      }
    }

    if (currentWeek.length > 0) {
      while (currentWeek.length < 7) {
        currentWeek.push(null);
      }
      weeks.push(currentWeek);
    }
    return weeks;
  }

  private getCellBg(cell: RamadanDayCell): string {
    if (cell.status === 'future') {
      return 'transparent';
    }
    if (cell.status === 'fasted') {
      return this.colors.accentGold;
    }
    if (cell.status === 'missed') {
      return this.colors.statusExpress;
    }
    return this.colors.tintSubtle;
  }

  private getCellBorderColor(cell: RamadanDayCell): string {
    if (!cell.isToday) {
      return 'transparent';
    }
    // If the day is marked, use the text color (white/dark) for a clean contrast
    if (cell.status === 'fasted' || cell.status === 'missed') {
      return this.colors.textOnAccent;
    }
    // If unmarked, use the theme's accent color for the "today" highlight
    return this.colors.accentGold;
  }

  private getCellTextColor(cell: RamadanDayCell): string {
    // 1. If the cell has a solid color background (fasted or missed),
    // the text MUST be the contrasting "textOnAccent" color.
    if (cell.status === 'fasted' || cell.status === 'missed') {
      return this.colors.textOnAccent;
    }

    // 2. If it's a future date, it's muted.
    if (cell.status === 'future') {
      return this.colors.textMuted;
    }

    // 3. If it's 'not_marked' but it IS today, highlight the text in gold.
    if (cell.isToday) {
      return this.colors.accentGold;
    }

    // 4. Default for 'not_marked' in the past.
    return this.colors.textWhite;
  }

  private onCellTap(cell: RamadanDayCell): void {
    if (cell.status === 'future') {
      return;
    }
    this.selectedCell = cell;
    const rec = FastingManager.getRecord(cell.dateKey);
    this.editReason = rec?.reason || '';
    this.showEditSheet = true;
  }

  private markStatus(status: 'fasted' | 'missed' | 'clear'): void {
    if (!this.selectedCell) {
      return;
    }
    if (status === 'clear') {
      FastingManager.clearRecord(this.selectedCell.dateKey);
    } else {
      FastingManager.saveRecord(this.selectedCell.dateKey, status, status === 'missed' ? this.editReason : '');
    }
    this.showEditSheet = false;
    this.selectedCell = null;
    this.editReason = '';
  }

  private isCurrentAshra(a: RamadanAshra): boolean {
    if (!this.ramadanInfo || !this.ramadanInfo.isRamadanNow) {
      return false;
    }
    return this.ramadanInfo.currentDayNumber >= a.startHijriDay && this.ramadanInfo.currentDayNumber <= a.endHijriDay;
  }

  private tr(key: string): string {
    return L.get(key, this.currentLanguage);
  }

  private isRtl(): boolean {
    return L.isRtlLang(this.currentLanguage);
  }

  // ============================================================
  // UI BUILDERS
  // ============================================================

  @Builder
  EditDaySheet() {
    Column() {
      Row()
        .width(44)
        .height(4)
        .backgroundColor(this.colors.overlayDimSoft)
        .borderRadius(2)
        .margin({ top: 10 })

      if (this.selectedCell) {
        Column() {
          Text(`${this.selectedCell.hijriDay} ${this.tr('ramadan_day_of_suffix')}`)
            .fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
          Text(RamadanHelper.formatLong(this.selectedCell.gregorianDate, this.currentLanguage))
            .fontSize(14).fontColor(this.colors.textMuted).margin({ top: 4, bottom: 20 })

          Button(this.tr('fasted'))
            .width('100%')
            .height(48)
            .fontSize(16)
            .backgroundColor(this.colors.accentGold)
            .fontColor(this.colors.textOnAccent)
            .borderRadius(12)
            .margin({ bottom: 12 })
            .onClick(() => this.markStatus('fasted'))

          Button(this.tr('missed'))
            .width('100%')
            .height(48)
            .fontSize(16)
            .backgroundColor(this.colors.statusExpress)
            .fontColor(this.colors.textOnAccent)
            .borderRadius(12)
            .margin({ bottom: 12 })
            .onClick(() => this.markStatus('missed'))

          TextInput({ text: this.editReason, placeholder: this.tr('fasting_missed_reason') })
            .height(48)
            .fontSize(14)
            .backgroundColor(this.colors.tintSubtle)
            .borderRadius(8)
            .margin({ bottom: 12 })
            .onChange((val: string) => {
              this.editReason = val;
            })

          Button(this.tr('save_reason'))
            .width('100%')
            .height(40)
            .fontSize(14)
            .backgroundColor(this.colors.tintSoft)
            .fontColor(this.colors.textWhite)
            .borderRadius(10)
            .margin({ bottom: 12 })
            .onClick(() => {
              if (this.selectedCell) {
                FastingManager.saveRecord(this.selectedCell.dateKey, 'missed', this.editReason);
                this.showEditSheet = false;
              }
            })

          Button(this.tr('clear'))
            .width('100%')
            .height(48)
            .fontSize(16)
            .backgroundColor(this.colors.tintSoft)
            .fontColor(this.colors.textMuted)
            .borderRadius(12)
            .margin({ bottom: 24 })
            .onClick(() => this.markStatus('clear'))
        }
        .width('100%').padding({ left: 20, right: 20 })
      }
    }
    .width('100%').backgroundColor(this.colors.cardDark)
    .borderRadius({ topLeft: 28, topRight: 28 })
    .shadow({
      radius: 24,
      color: this.colors.shadowFloating,
      offsetX: 0,
      offsetY: -6
    })
  }

  @Builder
  LiveCountdownBanner() {
    if (this.countdownTarget !== '' && this.ramadanInfo !== null && this.ramadanInfo.isRamadanNow) {
      Column() {
        Row() {
          Image(this.countdownTarget === 'maghrib' ? $r('app.media.ic_sunset') : $r('app.media.ic_sunrise'))
            .width(32).height(32)
            .fillColor(this.colors.accentGold)
            .margin({ right: 14 })

          Column() {
            Text(this.countdownHeld
              ? (this.countdownTarget === 'maghrib'
                ? this.tr('countdown_fast_ends_now')
                : this.tr('countdown_fast_starts_now'))
              : (this.countdownTarget === 'maghrib'
                ? this.tr('countdown_fast_ends')
                : this.tr('countdown_fast_starts')))
              .fontSize(12)
              .fontColor(this.countdownHeld ? this.colors.accentGold : this.colors.textMuted)
              .fontWeight(FontWeight.Medium)
              .letterSpacing(0.5)

            if (!this.countdownHeld) {
              Text(this.countdownTarget === 'maghrib'
                ? this.tr('countdown_fast_ends_desc')
                : this.tr('countdown_fast_starts_desc'))
                .fontSize(11)
                .fontColor(this.colors.textMuted)
                .fontStyle(FontStyle.Italic)
                .margin({ top: 2 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Text(this.countdownDisplay)
            .fontSize(38)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.colors.accentGold)
            .direction(Direction.Ltr)
            .margin({ left: 12 })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding(18)
      .backgroundColor(this.colors.cardDark)
      .borderRadius(Theme.radiusLarge)
      .border({ width: 2, color: this.colors.accentGold })
      .shadow({
        radius: 16,
        color: this.colors.shadowFloating,
        offsetX: 0,
        offsetY: 6
      })
      .margin({ bottom: 14 })
    }
  }

  @Builder
  QadaCard() {
    Column() {
      Row() {
        Image($r('app.media.ic_scales'))
          .width(16).height(16)
          .fillColor(this.colors.accentGold)
          .margin({ right: 8 })
        Text(this.tr('qada_tracking'))
          .fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
          .layoutWeight(1)
      }.width('100%').padding({ bottom: 12 })

      if (this.qadaStats.remaining === 0 && this.qadaStats.totalMissed === 0) {
        Text(this.tr('no_qada_needed'))
          .fontSize(13)
          .fontColor(this.colors.accentGold)
          .fontWeight(FontWeight.Medium)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 8, bottom: 8 })
      } else if (this.qadaStats.remaining === 0) {
        Text(this.tr('qada_completed'))
          .fontSize(13)
          .fontColor(this.colors.accentGold)
          .fontWeight(FontWeight.Medium)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 8, bottom: 8 })
      } else {
        // Progress Bar
        Row() {
          Row()
            .width(`${(this.qadaStats.qadaDone / this.qadaStats.totalMissed) * 100}%`)
            .height(6)
            .backgroundColor(this.colors.accentGold)
            .borderRadius(3)
        }
        .width('100%')
        .height(6)
        .backgroundColor(this.colors.tintMedium)
        .borderRadius(3)
        .margin({ bottom: 12 })

        Row() {
          Column() {
            Text(`${this.qadaStats.remaining}`)
              .fontSize(24).fontWeight(FontWeight.Bold).fontColor(this.colors.statusExpress)
            Text(this.tr('qada_remaining'))
              .fontSize(10).fontColor(this.colors.textMuted)
          }.layoutWeight(1).alignItems(HorizontalAlign.Start)

          Column() {
            Text(`${this.qadaStats.qadaDone} / ${this.qadaStats.totalMissed}`)
              .fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
            Text(this.tr('qada_done'))
              .fontSize(10).fontColor(this.colors.textMuted)
          }.layoutWeight(1).alignItems(HorizontalAlign.End)
        }
        .width('100%').margin({ bottom: 16 })

        // --- Only show the action buttons if it is NOT Ramadan ---
        if (this.ramadanInfo && !this.ramadanInfo.isRamadanNow) {
          Row() {
            Button(this.tr('log_qada'))
              .layoutWeight(1)
              .height(40)
              .fontSize(13)
              .backgroundColor(this.colors.accentGold)
              .fontColor(this.colors.textOnAccent)
              .borderRadius(8)
              .onClick(() => {
                FastingManager.logQada();
                this.qadaStats = FastingManager.getQadaStats();
              })

            if (this.qadaStats.qadaDone > 0) {
              Button(this.tr('undo'))
                .width(80)
                .height(40)
                .fontSize(13)
                .margin({ left: 8 })
                .backgroundColor(this.colors.tintSubtle)
                .fontColor(this.colors.textWhite)
                .borderRadius(8)
                .onClick(() => {
                  FastingManager.undoQada();
                  this.qadaStats = FastingManager.getQadaStats();
                })
            }
          }.width('100%')
        }
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(Theme.radiusLarge)
    .margin({ bottom: 14 })
  }

  @Builder
  PastHistorySection() {
    Column() {
      // --- Header ---
      Row() {
        Image($r('app.media.ic_calendar'))
          .width(16).height(16)
          .fillColor(this.colors.accentGold)
          .margin({ right: 8 })
        Text(this.tr('past_fasting_history'))
          .fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
          .layoutWeight(1)
      }
      .width('100%').padding({ bottom: 16 })

      // --- Empty State ---
      if (this.pastFasted.length === 0 && this.pastMissed.length === 0 && this.pastNotMarked.length === 0) {
        Text(this.tr('no_past_history'))
          .fontSize(12)
          .fontColor(this.colors.textMuted)
          .fontStyle(FontStyle.Italic)
          .textAlign(TextAlign.Center)
          .width('100%')
          .padding({ top: 20, bottom: 20 })
      } else {

        // --- Fasted Accordion ---
        Column() {
          Row() {
            Image($r('app.media.ic_check'))
              .width(14).height(14)
              .fillColor(this.colors.accentGold)
              .margin({ right: 8 })
            Text(this.tr('fasted'))
              .fontSize(14).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
            Text(` (${this.pastFasted.length})`)
              .fontSize(12).fontColor(this.colors.accentGold).layoutWeight(1)
            Image(this.isFastedExpanded ? $r('app.media.ic_chevron_up') : $r('app.media.ic_chevron_down'))
              .width(12).height(12)
              .fillColor(this.colors.textMuted)
          }
          .width('100%').padding({ top: 12, bottom: 12 })
          .onClick(() => {
            this.isFastedExpanded = !this.isFastedExpanded;
          })

          if (this.isFastedExpanded && this.pastFasted.length > 0) {
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.pastFasted, (dateKey: string) => {
                Text(dateKey)
                  .fontSize(11)
                  .fontColor(this.colors.accentGold)
                  .padding({
                    left: 8,
                    right: 8,
                    top: 4,
                    bottom: 4
                  })
                  .backgroundColor(this.colors.tintSubtle)
                  .borderRadius(6)
                  .border({ width: 1, color: this.colors.borderSoft })
                  .margin({ right: 6, bottom: 6 })
              }, (dateKey: string) => dateKey)
            }
            .width('100%').padding({ bottom: 8 })
          }
        }
        .width('100%')
        .border({ width: { bottom: 1 }, color: this.colors.borderSoft })

        // --- Missed Accordion ---
        Column() {
          Row() {
            Image($r('app.media.ic_alert'))
              .width(14).height(14)
              .fillColor(this.colors.statusExpress)
              .margin({ right: 8 })
            Text(this.tr('missed'))
              .fontSize(14).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
            Text(` (${this.pastMissed.length})`)
              .fontSize(12).fontColor(this.colors.statusExpress).layoutWeight(1)
            Image(this.isMissedExpanded ? $r('app.media.ic_chevron_up') : $r('app.media.ic_chevron_down'))
              .width(12).height(12)
              .fillColor(this.colors.textMuted)
          }
          .width('100%').padding({ top: 12, bottom: 12 })
          .onClick(() => {
            this.isMissedExpanded = !this.isMissedExpanded;
          })

          if (this.isMissedExpanded && this.pastMissed.length > 0) {
            Column() {
              ForEach(this.pastMissed, (rec: HistoryRecord, index: number) => {
                Row() {
                  Text(rec.dateKey)
                    .fontSize(11).fontColor(this.colors.textMuted).width(80)
                  Text(rec.reason.length > 0 ? rec.reason : '-')
                    .fontSize(12)
                    .fontColor(this.colors.textWhite)
                    .layoutWeight(1)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .width('100%').padding({ top: 8, bottom: 8 })
                .border({
                  width: { bottom: index === this.pastMissed.length - 1 ? 0 : 1 },
                  color: this.colors.borderSoft
                })
              }, (rec: HistoryRecord) => rec.dateKey)
            }
            .width('100%')
            .padding(12)
            .backgroundColor(this.colors.tintSubtle)
            .borderRadius(8)
            .margin({ bottom: 8 })
          }
        }
        .width('100%')
        .border({ width: { bottom: 1 }, color: this.colors.borderSoft })

        // --- Not Marked Accordion ---
        Column() {
          Row() {
            Image($r('app.media.ic_shield'))
              .width(14).height(14)
              .fillColor(this.colors.textMuted)
              .margin({ right: 8 })
            Text(this.tr('not_marked'))
              .fontSize(14).fontColor(this.colors.textWhite).fontWeight(FontWeight.Medium)
            Text(` (${this.pastNotMarked.length})`)
              .fontSize(12).fontColor(this.colors.textMuted).layoutWeight(1)
            Image(this.isNotMarkedExpanded ? $r('app.media.ic_chevron_up') : $r('app.media.ic_chevron_down'))
              .width(12).height(12)
              .fillColor(this.colors.textMuted)
          }
          .width('100%').padding({ top: 12, bottom: 12 })
          .onClick(() => {
            this.isNotMarkedExpanded = !this.isNotMarkedExpanded;
          })

          if (this.isNotMarkedExpanded && this.pastNotMarked.length > 0) {
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.pastNotMarked, (dateKey: string) => {
                Text(dateKey)
                  .fontSize(11)
                  .fontColor(this.colors.textMuted)
                  .padding({
                    left: 8,
                    right: 8,
                    top: 4,
                    bottom: 4
                  })
                  .backgroundColor(this.colors.tintSubtle)
                  .borderRadius(6)
                  .border({ width: 1, color: this.colors.borderSoft })
                  .margin({ right: 6, bottom: 6 })
              }, (dateKey: string) => dateKey)
            }
            .width('100%').padding({ bottom: 8 })
          }
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(Theme.radiusLarge)
    .margin({ bottom: 14 })
  }

  build() {
    Stack() {
      Column() {
        // ============================================================
        // Top Bar
        // ============================================================
        Row() {
          Image($r('app.media.ic_back'))
            .width(26)
            .height(26)
            .fillColor(this.colors.textWhite)
            .width(40)
            .height(40)
            .padding(7)
            .borderRadius(20)
            .backgroundColor(this.colors.tintSoft)
            .margin({ left: 16 })
            .onClick(() => router.back())

          Text(this.tr('ramadan_details_title'))
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.colors.textWhite)
            .margin({ left: 16 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%').height(72)
        .backgroundColor(this.colors.cardDark)
        .alignItems(VerticalAlign.Center)

        // ============================================================
        // Main Content
        // ============================================================
        Scroll() {
          Row() {
            Column() {
              if (this.ramadanInfo !== null) {

                // ------------------------------------------------------
                // STATE 1: RAMADAN IS CURRENTLY ACTIVE
                // ------------------------------------------------------
                if (this.ramadanInfo.isRamadanNow) {

                  this.LiveCountdownBanner()

                  // 1. Stats Summary
                  Row() {
                    Column() {
                      Text(`${this.fastingStats.fasted}`)
                        .fontSize(28).fontWeight(FontWeight.Bold).fontColor(this.colors.accentGold)
                      Text(this.tr('fasted')).fontSize(12).fontColor(this.colors.textMuted)
                    }.layoutWeight(1).alignItems(HorizontalAlign.Center)

                    Column() {
                      Text(`${this.fastingStats.missed}`)
                        .fontSize(28).fontWeight(FontWeight.Bold).fontColor(this.colors.statusExpress)
                      Text(this.tr('missed')).fontSize(12).fontColor(this.colors.textMuted)
                    }.layoutWeight(1).alignItems(HorizontalAlign.Center)

                    Column() {
                      Text(`${Math.max(0,
                        this.ramadanInfo.currentDayNumber - this.fastingStats.fasted - this.fastingStats.missed)}`)
                        .fontSize(28).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
                      Text(this.tr('not_marked')).fontSize(12).fontColor(this.colors.textMuted)
                    }.layoutWeight(1).alignItems(HorizontalAlign.Center)
                  }
                  .width('100%')
                  .padding(20)
                  .backgroundColor(this.colors.cardDark)
                  .borderRadius(Theme.radiusLarge)
                  .margin({ bottom: 14 })

                  // 2. Calendar Heatmap
                  Column() {
                    Text(this.tr('ramadan_fasting_tracking'))
                      .fontSize(12)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(this.colors.textMuted)
                      .letterSpacing(1.2)
                      .width('100%')
                      .padding({ bottom: 14 })

                    // Weekday Labels
                    Row() {
                      ForEach(L.getArray('days_of_week_short', this.currentLanguage), (d: string) => {
                        Text(d)
                          .fontSize(10)
                          .fontColor(this.colors.textMuted)
                          .layoutWeight(1)
                          .textAlign(TextAlign.Center)
                      })
                    }.width('100%').margin({ bottom: 8 })

                    // Calendar Grid
                    Column() {
                      ForEach(this.ramadanWeeks, (week: Array<RamadanDayCell | null>, wi: number) => {
                        Row() {
                          ForEach(week, (cell: RamadanDayCell | null, di: number) => {
                            if (cell === null) {
                              Column().layoutWeight(1).height(44).margin({ left: 2, right: 2 })
                            } else {
                              Column() {
                                Text(`${cell.hijriDay}`)
                                  .fontSize(14)
                                  .fontWeight(cell.isToday ? FontWeight.Bold : FontWeight.Medium)
                                  .fontColor(this.getCellTextColor(cell))
                                  .opacity(cell.status === 'future' ? 0.4 : 1.0)
                              }
                              .layoutWeight(1)
                              .height(44)
                              .justifyContent(FlexAlign.Center)
                              .alignItems(HorizontalAlign.Center)
                              .backgroundColor(this.getCellBg(cell))
                              .borderRadius(8)
                              .border({
                                width: cell.isToday ? 2 : 0,
                                color: this.getCellBorderColor(cell)
                              })
                              .margin({ left: 2, right: 2 })
                              .onClick(() => this.onCellTap(cell))
                            }
                          }, (cell: RamadanDayCell | null, di: number) =>
                          cell ? `cell-${cell.dateKey}-${cell.status}` : `empty-${wi}-${di}`)
                        }.width('100%').margin({ bottom: 4 })
                      }, (week: Array<RamadanDayCell | null>, wi: number) => `week-${wi}-${this.fastingVersion}`)
                    }.width('100%')
                  }
                  .width('100%')
                  .padding(20)
                  .backgroundColor(this.colors.cardDark)
                  .borderRadius(Theme.radiusLarge)
                  .margin({ bottom: 14 })

                } else if (RamadanHelper.isEidToday(this.hijriOffset)) {
                  this.EidSection()
                } else {
                  this.NotRamadanHeroCard()
                }

                // ------------------------------------------------------
                // ALWAYS VISIBLE SECTIONS
                // ------------------------------------------------------
                this.QadaCard()
                // Only show Taraweeh tracker during Ramadan
                if (this.ramadanInfo!.isRamadanNow) {
                  this.TaraweehCard()
                }
                this.DuasSection()
                this.PastHistorySection()
                this.AshrasSection()
                this.LaylatAlQadrSection()
                this.JummahTulWidahSection()

              }
            }
            .width('100%')
            .constraintSize({ maxWidth: Breakpoints.maxContentWidth(this.breakpoint) })
            .padding({
              left: 16,
              right: 16,
              top: 16,
              bottom: 40
            })
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
      .width('100%').height('100%').backgroundColor(this.colors.primaryGreen)
    }
    .width('100%').height('100%')
    // Bottom Sheet for Editing Days
    .bindSheet($$this.showEditSheet, this.EditDaySheet(), {
      height: 480,
      dragBar: true,
      showClose: false,
      backgroundColor: this.colors.cardDark,
      blurStyle: BlurStyle.Thick,
      maskColor: this.colors.overlayDim,
      onDisappear: () => {
        this.showEditSheet = false;
      }
    })
    .direction(this.isRtl() ? Direction.Rtl : Direction.Ltr)
  }

  @Builder
  DuasSection() {
    Column() {
      Text(this.tr('ramadan_duas'))
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.colors.textWhite)
        .width('100%')
        .padding({ bottom: 16 })

      DuaCard({
        dua: DUA_SUHOOR,
        colors: this.colors,
        currentLanguage: this.currentLanguage,
        showName: true
      })

      Divider().color(this.colors.borderSoft).margin({ top: 18, bottom: 18 })

      DuaCard({
        dua: DUA_IFTAR,
        colors: this.colors,
        currentLanguage: this.currentLanguage,
        showName: true
      })
    }
    .width('100%')
    .padding(20)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(Theme.radiusLarge)
    .margin({ bottom: 14 })
  }

  @Builder
  EidSection() {
    Column() {
      Image($r('app.media.ic_moon'))
        .width(48).height(48)
        .fillColor(this.colors.accentGold)
        .margin({ bottom: 12 })
      Text(this.tr('eid_mubarak'))
        .fontSize(24).fontWeight(FontWeight.Bold).fontColor(this.colors.accentGold)
      Text(this.tr('eid_zakat_reminder'))
        .fontSize(13)
        .fontColor(this.colors.textWhite)
        .textAlign(TextAlign.Center)
        .lineHeight(20)
        .margin({ top: 12, bottom: 16 })
      Text(this.tr('eid_takbeer'))
        .fontSize(12)
        .fontColor(this.colors.textMuted)
        .fontStyle(FontStyle.Italic)
        .textAlign(TextAlign.Center)
        .lineHeight(20)
    }
    .width('100%')
    .padding(24)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(Theme.radiusLarge)
    .margin({ bottom: 14 })
    .alignItems(HorizontalAlign.Center)
  }

  // --- Include the other builders from the previous step here ---
  // AshrasSection(), LaylatAlQadrSection(), JummahTulWidahSection()
  // (Keep them exactly as they were)
  @Builder
  AshrasSection() {
    Column() {
      Text(this.tr('ramadan_ashras'))
        .fontSize(11)
        .fontColor(this.colors.accentGold)
        .fontWeight(FontWeight.Bold)
        .letterSpacing(1.2)
        .width('100%')
        .padding({ bottom: 10 })

      ForEach(this.ramadanInfo!.ashras, (a: RamadanAshra) => {
        Row() {
          Text(`${a.number}`)
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isCurrentAshra(a) ? this.colors.textOnAccent : this.colors.accentGold)
            .width(24)
            .height(24)
            .textAlign(TextAlign.Center)
            .backgroundColor(this.isCurrentAshra(a) ? this.colors.accentGold : this.colors.tintSoft)
            .borderRadius(12)
            .border({ width: 1, color: this.isCurrentAshra(a) ? this.colors.accentGold : this.colors.borderSoft })

          Column() {
            Row() {
              Text(this.tr(a.nameKey))
                .fontSize(13).fontColor(this.colors.textWhite)
                .fontWeight(this.isCurrentAshra(a) ? FontWeight.Bold : FontWeight.Medium)
              Text('  ·  ').fontSize(11).fontColor(this.colors.textMuted)
              Text(this.tr(a.significanceKey))
                .fontSize(11)
                .fontColor(this.colors.accentGold)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
            }.width('100%')

            Text(
              `${RamadanHelper.formatShort(a.startDate, this.currentLanguage)} – ${RamadanHelper.formatShort(a.endDate,
                this.currentLanguage)}`)
              .fontSize(10).fontColor(this.colors.textMuted).margin({ top: 2 }).width('100%')
          }
          .layoutWeight(1).margin({ left: 10 }).alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding({
          top: 8,
          bottom: 8,
          left: 8,
          right: 8
        })
        .backgroundColor(this.isCurrentAshra(a) ? this.colors.tintSubtle : 'transparent')
        .borderRadius(10)
        .margin({ bottom: 4 })
        .alignItems(VerticalAlign.Center)
      }, (a: RamadanAshra) => `ashra-${a.number}-${a.startHijriDay}-${a.endHijriDay}`)
    }
    .width('100%')
    .padding(20)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(Theme.radiusLarge)
    .margin({ bottom: 14 })
  }

  @Builder
  TaraweehCard() {
    Row() {
      Column() {
        Text(this.tr('taraweeh_tracker'))
          .fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
        Text(this.tr('taraweeh_desc'))
          .fontSize(11).fontColor(this.colors.textMuted)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: this.isTaraweehToday })
        .selectedColor(this.colors.accentGold)
        .onChange((isOn: boolean) => {
          this.toggleTaraweeh(isOn);
        })
    }
    .width('100%')
    .padding(20)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(Theme.radiusLarge)
    .margin({ bottom: 14 })
  }

  @Builder
  LaylatAlQadrSection() {
    Column() {
      Row() {
        Image($r('app.media.ic_star'))
          .width(13).height(13)
          .fillColor(this.colors.accentGold)
          .margin({ right: 6 })
        Text(this.tr('ramadan_laylat_al_qadr'))
          .fontSize(11).fontColor(this.colors.accentGold)
          .fontWeight(FontWeight.Bold).letterSpacing(1.2)
      }.width('100%').padding({ bottom: 8 })

      Text(this.tr('ramadan_laylat_al_qadr_desc'))
        .fontSize(11)
        .fontColor(this.colors.textMuted)
        .lineHeight(16)
        .width('100%')
        .padding({ bottom: 12 })

      Row({ space: 6 }) {
        ForEach(this.ramadanInfo!.laylatAlQadrNights, (n: LaylatAlQadrNight) => {
          Column() {
            Text(`${n.hijriDay}`)
              .fontSize(14).fontWeight(n.isToday ? FontWeight.Bold : FontWeight.Medium)
              .fontColor(
                n.isToday ? this.colors.textOnAccent : n.isPast ? this.colors.textMuted : this.colors.accentGold)
            if (n.isToday) {
              Text(this.tr('ramadan_today')).fontSize(8).fontColor(this.colors.textOnAccent).margin({ top: 1 })
            } else {
              Text(RamadanHelper.formatShort(n.gregorianDate, this.currentLanguage))
                .fontSize(8).fontColor(this.colors.textMuted).margin({ top: 1 })
            }
          }
          .layoutWeight(1)
          .padding({ top: 8, bottom: 8 })
          .backgroundColor(n.isToday ? this.colors.accentGold : n.isPast ? 'transparent' : this.colors.tintSubtle)
          .borderRadius(10)
          .border({ width: n.isToday ? 0 : 1, color: n.isPast ? this.colors.borderSoft : this.colors.borderMedium })
          .opacity(n.isPast && !n.isToday ? 0.55 : 1.0)
          .alignItems(HorizontalAlign.Center)
        }, (n: LaylatAlQadrNight) => `laq-${n.hijriDay}-${n.isPast ? 'p' : n.isToday ? 't' : 'f'}`)
      }.width('100%').justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
    .padding(20)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(Theme.radiusLarge)
    .margin({ bottom: 14 })
  }

  @Builder
  JummahTulWidahSection() {
    if (this.ramadanInfo!.jummahTulWidah !== null) {
      Column() {
        Row() {
          Image($r('app.media.ic_mosque'))
            .width(13).height(13)
            .fillColor(this.colors.accentGold)
            .margin({ right: 6 })
          Text(this.tr('ramadan_jummah_tul_widah'))
            .fontSize(11)
            .fontColor(this.colors.accentGold)
            .fontWeight(FontWeight.Bold)
            .letterSpacing(1.2)
            .layoutWeight(1)
          Text(RamadanHelper.formatShort(this.ramadanInfo!.jummahTulWidah!, this.currentLanguage))
            .fontSize(11).fontColor(this.colors.accentGoldLight).fontWeight(FontWeight.Medium)
        }.width('100%').padding({ bottom: 4 })

        Text(this.tr('ramadan_jummah_tul_widah_desc'))
          .fontSize(11).fontColor(this.colors.textMuted).lineHeight(16).width('100%')
      }
      .width('100%')
      .padding(20)
      .backgroundColor(this.colors.cardDark)
      .borderRadius(Theme.radiusLarge)
      .margin({ bottom: 14 })
    }
  }

  @Builder
  NotRamadanHeroCard() {
    Column() {
      Image($r('app.media.ic_moon'))
        .width(48).height(48)
        .fillColor(this.colors.accentGold)
        .margin({ bottom: 16 })

      if (this.ramadanInfo!.daysUntilStart > 0) {
        Text(`${this.ramadanInfo!.daysUntilStart} ${this.tr('home_days')}`)
          .fontSize(36).fontWeight(FontWeight.Bold).fontColor(this.colors.accentGold)
        Text(this.tr('ramadan_days_until'))
          .fontSize(14).fontColor(this.colors.textWhite)
          .margin({ top: 4, bottom: 16 })
      } else {
        Text(this.tr('ramadan_has_ended'))
          .fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.colors.accentGold)
        Text(this.tr('ramadan_eid_mubarak'))
          .fontSize(14).fontColor(this.colors.textWhite)
          .margin({ top: 4, bottom: 16 })
      }

      Row() {
        Column() {
          Text(RamadanHelper.formatLong(this.ramadanInfo!.fastingStart, this.currentLanguage))
            .fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
          Text(this.tr('ramadan_calendar_start'))
            .fontSize(11).fontColor(this.colors.textMuted).margin({ top: 4 })
        }.layoutWeight(1).alignItems(HorizontalAlign.Center)

        Divider().vertical(true).height(40).color(this.colors.borderSoft)

        Column() {
          Text(RamadanHelper.formatLong(this.ramadanInfo!.fastingEnd, this.currentLanguage))
            .fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.colors.textWhite)
          Text(this.tr('ramadan_calendar_end'))
            .fontSize(11).fontColor(this.colors.textMuted).margin({ top: 4 })
        }.layoutWeight(1).alignItems(HorizontalAlign.Center)
      }
      .width('100%').margin({ top: 8 })
    }
    .width('100%')
    .padding(24)
    .backgroundColor(this.colors.cardDark)
    .borderRadius(Theme.radiusLarge)
    .border({ width: 1, color: this.colors.borderSoft })
    .alignItems(HorizontalAlign.Center)
    .margin({ bottom: 14 })
  }
}