// entry/src/main/ets/components/PrayerSunPath.ets

import { ThemeColors } from '../common/Theme';
import { L } from '../helper/LocalizationHelper';
import { PrayerModel } from './PrayerModel';
import { PrayerManager } from './PrayerManager';
import { ClockFormat, ClockFormatHelper } from '../common/ClockFormat';
import { STORAGE_KEY_TIME_FORMAT } from '../common/StorageKeys';

interface PathPoint {
  x: number;
  y: number;
}

// ============================================================
// LAYOUT CONSTANTS
// ============================================================

/**
 * Single pair of text sizes for every label in the canvas.
 * Prayer names, sunrise/sunset names, and extra-timing names all
 * use LABEL_FONT_SIZE. Prayer times, sunrise/sunset times, and
 * extra-timing times all use TIME_FONT_SIZE.
 */
const LABEL_FONT_SIZE = 30;
const TIME_FONT_SIZE = 22;
const LABEL_TIME_GAP = 12;

/**
 * Ticker ("We are here") uses its own font sizes so it stays visually
 * subordinate to the prayer and sunrise/sunset labels.
 */
const TICKER_LABEL_FONT_SIZE = 30;
const TICKER_TIME_FONT_SIZE = 22;

/**
 * Extra timings (First Third, Midnight, Last Third) revert to the
 * smaller font so their labels do not crowd the arc horizontally.
 */
const EXTRA_LABEL_FONT_SIZE = 22;
const EXTRA_TIME_FONT_SIZE = 18;

/**
 * Padding on both sides of the arc. Kept small so the arc stretches
 * nearly edge-to-edge while still leaving a few vp of breathing room
 * for the hour-0 and hour-24 tick marks.
 */
const ARC_EDGE_PAD = 12;
const CANVAS_HEIGHT = 384;

/**
 * The arc is a single hump spanning the 24-hour day:
 *   hour 0   -> arc base, far left
 *   hour 12  -> arc peak (roughly Dhuhr)
 *   hour 24  -> arc base, far right
 */
const ARC_BASE_Y = 220;
const ARCH_HEIGHT = 90;

/** Small tick marks under the arc, one per hour. */
const HOUR_TICK_TOP = ARC_BASE_Y + 6;
const HOUR_TICK_LEN = 6;

/** Below-arc text rows. */
const SUN_LABEL_Y = 274;
const SUN_TIME_Y = 286;
const EXTRA_LABEL_Y = 318;
const EXTRA_TIME_Y = 330;
const TICKER_LABEL_Y = 356;
const TICKER_TIME_Y = 376;
const EXTRA_LINE_END_Y = 300;
const SUN_LEADER_GAP = 28;

/** Ticker update interval. 500 ms is smooth enough for a slow dot. */
const TICKER_TICK_MS = 500;
/** Update interval during the midnight wrap — 60 fps equivalent. */
const TICKER_WRAP_TICK_MS = 16;
/** How long the midnight wrap sweeps across the arc. */
const TICKER_WRAP_MS = 2400;

@Component
export struct PrayerSunPath {

  @Prop @Watch('onVisualChanged') colors: ThemeColors;
  @Prop @Watch('onPrayersChanged') prayers: PrayerModel[] = [];
  @Prop @Watch('onVisualChanged') sunriseTime: string = '--:--';
  @Prop @Watch('onVisualChanged') sunsetTime: string = '--:--';
  @Prop @Watch('onVisualChanged') firstThirdTime: string = '--:--';
  @Prop @Watch('onVisualChanged') midnightTime: string = '--:--';
  @Prop @Watch('onVisualChanged') lastThirdTime: string = '--:--';
  @Prop @Watch('onVisualChanged') currentLanguage: string = 'en';
  @Prop @Watch('onVisualChanged') isDarkMode: boolean = false;
  @StorageLink(STORAGE_KEY_TIME_FORMAT)
  @Watch('onVisualChanged')
  ClockFormat: string = ClockFormat.SYSTEM;

  private ctx: CanvasRenderingContext2D =
    new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private canvasWidth: number = 340;
  private canvasHeight: number = CANVAS_HEIGHT;
  private canvasReady: boolean = false;

  private tickerTimerId: number = -1;
  /**
   * Monotonic minute counter. Grows without wrapping, so the visual
   * position `monotonic % 1440` never jumps except at midnight — and
   * that single jump is smoothed by the wrap animation below.
   */
  private tickerMonotonicMinute: number = -1;
  /** Set to Date.now() when a midnight wrap begins. */
  private tickerWrapStartMs: number = -1;
  /** Minute value (0–1439) just before the wrap. */
  private tickerWrapFromMinute: number = -1;
  /** Tracks whether we were mid-wrap on the previous tick. */
  private tickerWasWrapping: boolean = false;

  aboutToAppear(): void {
    this.restartTickerTimer(TICKER_TICK_MS);
    this.tick();
  }

  aboutToDisappear(): void {
    if (this.tickerTimerId !== -1) {
      clearInterval(this.tickerTimerId);
      this.tickerTimerId = -1;
    }
  }

  private onPrayersChanged(_propName: string): void {
    this.redraw();
  }

  private onVisualChanged(_propName: string): void {
    this.redraw();
  }

  private isRtl(): boolean {
    return L.isRtlLang(this.currentLanguage);
  }

  private translatePrayerName(raw: string): string {
    switch (raw) {
      case 'Fajr':
        return L.get('prayer_fajr', this.currentLanguage);
      case 'Dhuhr':
        return L.get('prayer_dhuhr', this.currentLanguage);
      case 'Jummah':
        return L.get('prayer_jummah', this.currentLanguage);
      case 'Asr':
        return L.get('prayer_asr', this.currentLanguage);
      case 'Maghrib':
        return L.get('prayer_maghrib', this.currentLanguage);
      case 'Isha':
        return L.get('prayer_isha', this.currentLanguage);
      default:
        return raw;
    }
  }

  private formatNow(now: Date): string {
    const totalMinutes = now.getHours() * 60 + now.getMinutes();
    return ClockFormatHelper.formatMinutes(totalMinutes);
  }
  // ============================================================
  // TICKER — smooth movement, midnight wrap animation
  // ============================================================

  private tick(): void {
    const now = new Date();
    const rawMinute = now.getHours() * 60
      + now.getMinutes() + now.getSeconds() / 60;

    // Detect wrap end before touching the timer.
    const wrappingNow = this.tickerWrapStartMs > 0
      && (Date.now() - this.tickerWrapStartMs) < TICKER_WRAP_MS;

    if (this.tickerWasWrapping && !wrappingNow) {
      // The wrap just finished — restore the slow cadence and clear
      // the wrap markers so `drawTicker` falls back to normal
      // positioning on the next frame.
      this.restartTickerTimer(TICKER_TICK_MS);
      this.tickerWrapStartMs = -1;
      this.tickerWrapFromMinute = -1;
    }
    this.tickerWasWrapping = wrappingNow;

    if (this.tickerMonotonicMinute < 0) {
      this.tickerMonotonicMinute = rawMinute;
      this.redraw();
      return;
    }

    const prevRaw = this.tickerMonotonicMinute % 1440;
    let delta = rawMinute - prevRaw;

    if (delta < -720) {
      delta += 1440;

      if (delta < 60) {
        // Genuine midnight crossing during a live session. Kick off
        // the wrap animation and switch to the fast tick rate.
        this.tickerWrapStartMs = Date.now();
        this.tickerWrapFromMinute = prevRaw;
        this.tickerWasWrapping = true;
        this.restartTickerTimer(TICKER_WRAP_TICK_MS);
      }
    } else if (delta > 720) {
      delta -= 1440;
    } else if (delta < 0) {
      delta = 0;
    }

    this.tickerMonotonicMinute += delta;
    this.redraw();
  }

  private restartTickerTimer(intervalMs: number): void {
    if (this.tickerTimerId !== -1) {
      clearInterval(this.tickerTimerId);
    }
    this.tickerTimerId = setInterval(() => {
      this.tick();
    }, intervalMs);
  }

  // ============================================================
  // BUILD
  // ============================================================

  build() {
    Column() {
      Canvas(this.ctx)
        .width('100%')
        .height(this.canvasHeight)
        .onReady(() => {
          this.canvasReady = true;
          const w: number = this.ctx.width;
          const h: number = this.ctx.height;
          if (w > 0) {
            this.canvasWidth = w;
            if (h > 0) {
              this.canvasHeight = h;
            }
          }
          this.redraw();
        })
        .onAreaChange((oldArea: Area, newArea: Area) => {
          const w: number = parseFloat(String(newArea.width));
          const h: number = parseFloat(String(newArea.height));
          if (!isNaN(w) && w > 0 && w !== this.canvasWidth) {
            this.canvasWidth = w;
            if (!isNaN(h) && h > 0) {
              this.canvasHeight = h;
            }
            this.redraw();
          }
        })
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
    .backgroundColor(this.colors.cardDark)
    .borderRadius(20)
    .border({ width: 1, color: this.colors.borderSoft })
    .shadow({
      radius: 12,
      color: this.colors.shadowCard,
      offsetX: 0,
      offsetY: 4
    })
    .margin({ bottom: 14 })
  }

  // ============================================================
  // DRAW
  // ============================================================

  private redraw(): void {
    if (!this.canvasReady) {
      return;
    }
    if (this.canvasWidth <= 0) {
      return;
    }
    if (this.prayers.length < 5) {
      return;
    }

    const ctx = this.ctx;
    const W = this.canvasWidth;
    const H = this.canvasHeight;
    ctx.clearRect(0, 0, W, H);

    const rtl: boolean = this.isRtl();
    const px = (logicalX: number): number => rtl ? W - logicalX : logicalX;

    // ---- Time conversion ----
    const isValidTime = (s: string): boolean => {
      const t = s.trim();
      return t.length > 0 && t !== '--:--';
    };

    /** Convert "5:23 AM" to a decimal hour (5.3833). */
    const timeToHour = (s: string): number => {
      return PrayerManager.timeToMinutes(s) / 60;
    };

    // ---- Prayer hours ----
    const fajrHour = timeToHour(this.prayers[0].time);
    const dhuhrHour = timeToHour(this.prayers[1].time);
    const asrHour = timeToHour(this.prayers[2].time);
    const maghribHour = timeToHour(this.prayers[3].time);
    const ishaHour = timeToHour(this.prayers[4].time);

    if (fajrHour <= 0 || dhuhrHour <= 0 || ishaHour <= 0) {
      return;
    }

    // ---- Arc geometry (logical LTR) ----
    const arcStartX = ARC_EDGE_PAD;
    const arcEndX = W - ARC_EDGE_PAD;
    const arcW = arcEndX - arcStartX;

    const arcBaseY = ARC_BASE_Y;
    const archH = ARCH_HEIGHT;

    /**
     * Decimal hour (0..24) -> logical x. Hour 0 is at `arcStartX`,
     * hour 24 at `arcEndX`. Values outside [0,24) wrap, so a Last
     * Third at 02:00 plots on the left side just like it does on a
     * wall clock.
     */
    const xForHour = (h: number): number => {
      const normalized = ((h % 24) + 24) % 24;
      return arcStartX + (normalized / 24) * arcW;
    };

    /** Logical x -> y on the sine arc. */
    const yForX = (lx: number): number => {
      const p = Math.max(0, Math.min(1, (lx - arcStartX) / arcW));
      return arcBaseY - archH * Math.sin(Math.PI * p);
    };

    // ---- Colors ----
    const isDark: boolean = this.isDarkMode;
    const solidColor = isDark ? '#A5B8CC' : '#7B8FA3';
    const dotColor = isDark ? '#8892A6' : '#B0B8C0';
    const labelColor = isDark ? '#E8EDF4' : '#3F4754';
    const timeColor = isDark ? '#B4C0D0' : '#5A6270';
    const leaderColor = this.colors.textMuted;
    const activeLeader = this.colors.accentGold;
    const leaderAlpha = isDark ? 0.60 : 0.65;
    const activeAlpha = isDark ? 0.85 : 0.75;
    const activeDot = isDark ? '#FBBF24' : '#0F5132';
    const activeLabel = isDark ? '#FCD34D' : '#0F5132';
    const activeRing = isDark
      ? 'rgba(251,191,36,0.30)'
      : 'rgba(15,81,50,0.22)';
    const horizonColor = isDark ? '#FBBF24' : '#F59E0B';
    const tickerColor = isDark ? '#C4B5FD' : '#7C3AED';
    const hourTickColor = isDark
      ? 'rgba(180,192,208,0.40)'
      : 'rgba(120,128,140,0.50)';

    // ---- Draw the arc line ----
    const SAMPLES = 96;
    ctx.save();
    ctx.beginPath();
    for (let i = 0; i <= SAMPLES; i++) {
      const lx = arcStartX + (arcW * i / SAMPLES);
      const ly = yForX(lx);
      const x = px(lx);
      if (i === 0) {
        ctx.moveTo(x, ly);
      } else {
        ctx.lineTo(x, ly);
      }
    }
    ctx.strokeStyle = solidColor;
    ctx.lineWidth = 3;
    ctx.lineCap = 'round';
    ctx.stroke();
    ctx.restore();

    // ---- Hour tick marks (one per hour, 0..24) ----
    ctx.save();
    ctx.strokeStyle = hourTickColor;
    ctx.lineWidth = 1;
    for (let h = 0; h <= 24; h++) {
      const lx = xForHour(h % 24);
      const x = px(lx);
      const isMajor = (h % 3 === 0);
      const len = isMajor ? HOUR_TICK_LEN : HOUR_TICK_LEN - 2;
      ctx.beginPath();
      ctx.moveTo(x, HOUR_TICK_TOP);
      ctx.lineTo(x, HOUR_TICK_TOP + len);
      ctx.stroke();
    }
    ctx.restore();

    // ============================================================
    // EXTRA TIMINGS — dotted vertical lines from top to bottom
    // ============================================================

    const hasFirstThird = isValidTime(this.firstThirdTime);
    const hasMidnight = isValidTime(this.midnightTime);
    const hasLastThird = isValidTime(this.lastThirdTime);

    const firstThirdX = hasFirstThird
      ? px(xForHour(timeToHour(this.firstThirdTime)))
      : -1;
    const midnightX = hasMidnight
      ? px(xForHour(timeToHour(this.midnightTime)))
      : -1;
    const lastThirdX = hasLastThird
      ? px(xForHour(timeToHour(this.lastThirdTime)))
      : -1;

    const drawExtraLine = (x: number): void => {
      ctx.save();
      ctx.globalAlpha = leaderAlpha;
      ctx.beginPath();
      ctx.moveTo(x, 0);
      ctx.lineTo(x, EXTRA_LINE_END_Y);
      ctx.strokeStyle = leaderColor;
      ctx.lineWidth = 1.5;
      ctx.setLineDash([5, 5]);
      ctx.stroke();
      ctx.setLineDash([]);
      ctx.globalAlpha = 1.0;
      ctx.restore();
    };

    if (firstThirdX >= 0) {
      drawExtraLine(firstThirdX);
    }
    if (midnightX >= 0) {
      drawExtraLine(midnightX);
    }
    if (lastThirdX >= 0) {
      drawExtraLine(lastThirdX);
    }

    const drawExtraLabel = (
      x: number, label: string, time: string
    ): void => {
      ctx.textAlign = 'center';
      ctx.textBaseline = 'alphabetic';

      ctx.font = `bold ${EXTRA_LABEL_FONT_SIZE}px sans-serif`;
      ctx.fillStyle = this.colors.accentGold;
      ctx.fillText(label, x, EXTRA_LABEL_Y);

      ctx.font = `${EXTRA_TIME_FONT_SIZE}px sans-serif`;
      ctx.fillStyle = this.colors.accentGoldLight;
      ctx.fillText(ClockFormatHelper.reformat(time), x, EXTRA_TIME_Y);
    };

    if (firstThirdX >= 0) {
      drawExtraLabel(
        firstThirdX,
        L.get('timing_first_third', this.currentLanguage),
        this.firstThirdTime
      );
    }
    if (midnightX >= 0) {
      drawExtraLabel(
        midnightX,
        L.get('timing_midnight', this.currentLanguage),
        this.midnightTime
      );
    }
    if (lastThirdX >= 0) {
      drawExtraLabel(
        lastThirdX,
        L.get('timing_last_third', this.currentLanguage),
        this.lastThirdTime
      );
    }

    // ============================================================
    // CURRENT PRAYER INDEX
    // ============================================================

    const now = new Date();
    const nowMinute = now.getHours() * 60 + now.getMinutes();
    const prayerMinutes: number[] = [
      PrayerManager.timeToMinutes(this.prayers[0].time),
      PrayerManager.timeToMinutes(this.prayers[1].time),
      PrayerManager.timeToMinutes(this.prayers[2].time),
      PrayerManager.timeToMinutes(this.prayers[3].time),
      PrayerManager.timeToMinutes(this.prayers[4].time)
    ];
    let activeIdx: number = -1;
    for (let i = 0; i < prayerMinutes.length; i++) {
      if (prayerMinutes[i] > 0 && prayerMinutes[i] <= nowMinute) {
        activeIdx = i;
      }
    }

    // ============================================================
    // PRAYER DOTS + LABELS (above the arc)
    // ============================================================

    const names: string[] = [
      this.translatePrayerName(this.prayers[0].name),
      this.translatePrayerName(this.prayers[1].name),
      this.translatePrayerName(this.prayers[2].name),
      this.translatePrayerName(this.prayers[3].name),
      this.translatePrayerName(this.prayers[4].name)
    ];
    const times: string[] = [
      this.prayers[0].time,
      this.prayers[1].time,
      this.prayers[2].time,
      this.prayers[3].time,
      this.prayers[4].time
    ];
    const hours: number[] = [
      fajrHour, dhuhrHour, asrHour, maghribHour, ishaHour
    ];
    const leaderLengths: number[] = [30, 70, 55, 40, 30];

    for (let i = 0; i < hours.length; i++) {
      const lx = xForHour(hours[i]);
      const ly = yForX(lx);
      const x = px(lx);
      const y = ly;

      const isActive: boolean = (i === activeIdx);
      const leaderLen = leaderLengths[i];

      const leaderStartY = y - 12 - leaderLen;
      const timeY = leaderStartY - 10;
      const labelY = timeY - LABEL_TIME_GAP;

      // Dotted leader
      ctx.save();
      ctx.globalAlpha = isActive ? activeAlpha : leaderAlpha;
      ctx.beginPath();
      ctx.moveTo(x, leaderStartY);
      ctx.lineTo(x, y - 12);
      ctx.strokeStyle = isActive ? activeLeader : leaderColor;
      ctx.lineWidth = 1.5;
      ctx.setLineDash([2, 3]);
      ctx.stroke();
      ctx.setLineDash([]);
      ctx.globalAlpha = 1.0;
      ctx.restore();

      // Prayer name
      ctx.font = isActive
        ? `bold ${LABEL_FONT_SIZE}px sans-serif`
        : `${LABEL_FONT_SIZE}px sans-serif`;
      ctx.fillStyle = isActive ? activeLabel : labelColor;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'alphabetic';
      ctx.fillText(names[i], x, labelY);

      // Prayer time
      ctx.font = `${TIME_FONT_SIZE}px sans-serif`;
      ctx.fillStyle = isActive ? activeLabel : timeColor;
      ctx.fillText(ClockFormatHelper.reformat(times[i]), x, timeY);

      // Active glow ring
      if (isActive) {
        ctx.beginPath();
        ctx.arc(x, y, 14, 0, Math.PI * 2);
        ctx.fillStyle = activeRing;
        ctx.fill();
      }

      // Filled dot
      ctx.beginPath();
      ctx.arc(x, y, isActive ? 7 : 6, 0, Math.PI * 2);
      ctx.fillStyle = isActive ? activeDot : dotColor;
      ctx.fill();

      // Specular highlight on the active dot
      if (isActive) {
        ctx.beginPath();
        ctx.arc(x - 2, y - 2, 2.5, 0, Math.PI * 2);
        ctx.fillStyle = isDark
          ? 'rgba(20, 27, 46, 0.65)'
          : 'rgba(255, 255, 255, 0.65)';
        ctx.fill();
      }
    }

    // ============================================================
    // SUNRISE / SUNSET ring markers + labels below
    // ============================================================

    const hasSunrise = isValidTime(this.sunriseTime);
    const hasSunset = isValidTime(this.sunsetTime);

    const drawHorizonMarker = (
      hourVal: number, label: string, time: string
    ): void => {
      const lx = xForHour(hourVal);
      const ly = yForX(lx);
      const sx = px(lx);
      const sy = ly;

      // Ring + inner dot
      ctx.beginPath();
      ctx.arc(sx, sy, 7, 0, Math.PI * 2);
      ctx.strokeStyle = horizonColor;
      ctx.lineWidth = 2;
      ctx.stroke();
      ctx.beginPath();
      ctx.arc(sx, sy, 3, 0, Math.PI * 2);
      ctx.fillStyle = horizonColor;
      ctx.fill();

      // Dotted leader down to the label. Now descends the full
      // distance from the ring to just above the label baseline,
      // matching the visual weight of the extra-timing guides.
      ctx.save();
      ctx.beginPath();
      ctx.moveTo(sx, sy + 10);
      ctx.lineTo(sx, SUN_LABEL_Y - SUN_LEADER_GAP);
      ctx.strokeStyle = horizonColor;
      ctx.lineWidth = 1.2;
      ctx.setLineDash([2, 3]);
      ctx.stroke();
      ctx.setLineDash([]);
      ctx.restore();

      ctx.font = `bold ${LABEL_FONT_SIZE}px sans-serif`;
      ctx.fillStyle = horizonColor;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'alphabetic';
      ctx.fillText(label, sx, SUN_LABEL_Y);

      ctx.font = `${TIME_FONT_SIZE}px sans-serif`;
      ctx.fillStyle = horizonColor;
      ctx.fillText(ClockFormatHelper.reformat(time), sx, SUN_TIME_Y);
    };

    if (hasSunrise) {
      drawHorizonMarker(
        timeToHour(this.sunriseTime),
        L.get('timing_sunrise', this.currentLanguage),
        this.sunriseTime
      );
    }
    if (hasSunset) {
      drawHorizonMarker(
        timeToHour(this.sunsetTime),
        L.get('timing_sunset', this.currentLanguage),
        this.sunsetTime
      );
    }

    // ============================================================
    // "WE ARE HERE" — moving ticker across the full 24h arc
    // ============================================================

    this.drawTicker(
      ctx, W, arcStartX, arcW, arcBaseY, archH, rtl, tickerColor
    );
  }

  private drawTicker(
    ctx: CanvasRenderingContext2D,
    W: number,
    arcStartX: number,
    arcW: number,
    arcBaseY: number,
    archH: number,
    rtl: boolean,
    tickerColor: string
  ): void {
    if (this.tickerMonotonicMinute < 0) {
      return;
    }

    const px = (logicalX: number): number => rtl ? W - logicalX : logicalX;

    const yForX = (lx: number): number => {
      const p = Math.max(0, Math.min(1, (lx - arcStartX) / arcW));
      return arcBaseY - archH * Math.sin(Math.PI * p);
    };

    const wrapActive = this.tickerWrapStartMs > 0
      && (Date.now() - this.tickerWrapStartMs) < TICKER_WRAP_MS;

    let tickerFraction: number;

    if (wrapActive) {
      // Sweep from the pre-wrap position (near hour 23.99) to the
      // start of the arc (hour 0), over TICKER_WRAP_MS milliseconds.
      const t = (Date.now() - this.tickerWrapStartMs) / TICKER_WRAP_MS;
      const fromFrac = this.tickerWrapFromMinute / 1440;
      const toFrac = 0;
      tickerFraction = fromFrac + (toFrac - fromFrac) * t;
    } else {
      const currentMinute = this.tickerMonotonicMinute % 1440;
      tickerFraction = currentMinute / 1440;
    }

    const tickerLx = arcStartX + tickerFraction * arcW;
    const tickerLy = yForX(tickerLx);
    const tickerX = px(tickerLx);
    const tickerY = tickerLy;

    // Dotted leader from the ticker down to its label position
    ctx.save();
    ctx.beginPath();
    ctx.moveTo(tickerX, tickerY + 7);
    ctx.lineTo(tickerX, TICKER_LABEL_Y - 12);
    ctx.strokeStyle = tickerColor;
    ctx.lineWidth = 2.5;
    ctx.lineCap = 'round';
    ctx.setLineDash([5, 4]);
    ctx.stroke();
    ctx.setLineDash([]);
    ctx.restore();

    // Dot + outer ring
    ctx.beginPath();
    ctx.arc(tickerX, tickerY, 5, 0, Math.PI * 2);
    ctx.fillStyle = tickerColor;
    ctx.fill();
    ctx.beginPath();
    ctx.arc(tickerX, tickerY, 8, 0, Math.PI * 2);
    ctx.strokeStyle = tickerColor;
    ctx.lineWidth = 1.5;
    ctx.stroke();

    // Label
    ctx.font = `bold ${TICKER_LABEL_FONT_SIZE}px sans-serif`;
    ctx.fillStyle = tickerColor;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'alphabetic';
    ctx.fillText(
      L.get('sun_path_we_are_here', this.currentLanguage),
      tickerX, TICKER_LABEL_Y
    );

    // Time
    const now = new Date();
    ctx.font = `${TICKER_TIME_FONT_SIZE}px sans-serif`;
    ctx.fillStyle = tickerColor;
    ctx.fillText(this.formatNow(now), tickerX, TICKER_TIME_Y);
  }
}