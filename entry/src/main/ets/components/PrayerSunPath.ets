// entry/src/main/ets/components/PrayerSunPath.ets

import { ThemeColors } from '../common/Theme';
import { L } from '../helper/LocalizationHelper';
import { PrayerModel } from '../models/PrayerModel';
import { PrayerManager } from '../utils/PrayerManager';

/** A single sampled point on the sun-path arc. */
interface PathPoint {
  x: number;
  y: number;
}

// ============================================================
// UNIVERSAL FONT / LAYOUT CONSTANTS
// ============================================================

const LABEL_FONT_SIZE = 35;
const TIME_FONT_SIZE = 25;
const LABEL_TIME_GAP = 14;

const ARC_EDGE_PAD = 4;
const DOTS_INSET = 62;
const CANVAS_HEIGHT = 360;
const ARC_BASE_Y = 232;
const ARCH_HEIGHT = 60;

/**
 * Per-prayer leader lengths.
 *
 * The wedge shape runs from tallest in the middle (Dhuhr) down to the
 * shortest at the ends (Fajr and Isha). Fajr and Isha are deliberately
 * short so their labels sit close to their dots on the arc, giving
 * the layout a clear "rise and fall" silhouette.
 */
const LEADER_FAJR = 20;
const LEADER_DHUHR = 90;
const LEADER_ASR = 70;
const LEADER_MAGHRIB = 52;
const LEADER_ISHA = 20;

const LEADER_TIME_GAP = 15;
const LEADER_DOT_GAP = 12;

const TICKER_LABEL_Y = 275;
const TICKER_TIME_Y = TICKER_LABEL_Y + LABEL_TIME_GAP;
const TICKER_DOT_R = 5;
const TICKER_LINE_W = 2.5;
const TICKER_DASH_ON = 5;
const TICKER_DASH_OFF = 4;

const TICKER_REFRESH_MS = 3 * 60 * 1000;

const BOTTOM_LABEL_Y = 322;

@Component
export struct PrayerSunPath {

  @Prop @Watch('onVisualChanged') colors: ThemeColors;
  @Prop @Watch('onPrayersChanged') prayers: PrayerModel[] = [];
  @Prop @Watch('onVisualChanged') sunriseTime: string = '--:--';
  @Prop @Watch('onVisualChanged') sunsetTime: string = '--:--';
  @Prop @Watch('onVisualChanged') currentLanguage: string = 'en';
  @Prop @Watch('onVisualChanged') isDarkMode: boolean = false;

  private ctx: CanvasRenderingContext2D =
    new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private canvasWidth: number = 340;
  private canvasHeight: number = CANVAS_HEIGHT;
  private canvasReady: boolean = false;

  private tickerTimerId: number = -1;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  aboutToAppear(): void {
    if (this.tickerTimerId !== -1) {
      clearInterval(this.tickerTimerId);
      this.tickerTimerId = -1;
    }
    this.tickerTimerId = setInterval(() => {
      this.redraw();
    }, TICKER_REFRESH_MS);
  }

  aboutToDisappear(): void {
    if (this.tickerTimerId !== -1) {
      clearInterval(this.tickerTimerId);
      this.tickerTimerId = -1;
    }
  }

  // ============================================================
  // WATCHERS
  // ============================================================

  private onPrayersChanged(_propName: string): void {
    this.redraw();
  }

  private onVisualChanged(_propName: string): void {
    this.redraw();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  /** True when the active language reads right-to-left (Arabic). */
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
    let hours: number = now.getHours();
    const minutes: number = now.getMinutes();
    const ampm: string = hours >= 12 ? 'PM' : 'AM';
    hours = hours % 12;
    if (hours === 0) {
      hours = 12;
    }
    const mm: string = minutes.toString().padStart(2, '0');
    return `${hours}:${mm} ${ampm}`;
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
  // CANVAS DRAW
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

    /**
     * Physical x after RTL mirror.
     * Everything below is computed in LTR "logical" coordinates
     * and then projected through this function so the whole canvas
     * mirrors cleanly when the language is Arabic.
     */
    const px = (logicalX: number): number => rtl ? W - logicalX : logicalX;

    const fajrM = PrayerManager.timeToMinutes(this.prayers[0].time);
    const dhuhrM = PrayerManager.timeToMinutes(this.prayers[1].time);
    const asrM = PrayerManager.timeToMinutes(this.prayers[2].time);
    const maghribM = PrayerManager.timeToMinutes(this.prayers[3].time);
    const ishaM = PrayerManager.timeToMinutes(this.prayers[4].time);

    if (fajrM <= 0 || dhuhrM <= 0 || ishaM <= 0) {
      return;
    }

    const range = ishaM - fajrM;
    if (range <= 0) {
      return;
    }

    // ---- Arc geometry (logical, LTR) ----
    const arcStartX = ARC_EDGE_PAD;
    const arcEndX = W - ARC_EDGE_PAD;
    const arcW = arcEndX - arcStartX;

    const dotsStartX = DOTS_INSET;
    const dotsEndX = W - DOTS_INSET;
    const dotsW = dotsEndX - dotsStartX;

    const arcBaseY = ARC_BASE_Y;
    const archH = ARCH_HEIGHT;

    // Logical x for a prayer minute.
    const lxFor = (m: number): number =>
    dotsStartX + (m - fajrM) / range * dotsW;

    // Arc y for a logical x. The arc is horizontally symmetric, so
    // the same y is produced whether we sample at x or at W - x.
    const lyFor = (lx: number): number => {
      const p = Math.max(0, Math.min(1, (lx - arcStartX) / arcW));
      return arcBaseY - archH * Math.sin(Math.PI * p);
    };

    // ---- Sunrise / Sunset (logical positions) ----
    const sunriseM = PrayerManager.timeToMinutes(this.sunriseTime);
    const sunsetM = PrayerManager.timeToMinutes(this.sunsetTime);
    const hasSunrise = sunriseM > 0;
    const hasSunset = sunsetM > 0;

    const sunriseLx = hasSunrise
      ? Math.max(dotsStartX, Math.min(dotsEndX, lxFor(sunriseM)))
      : 0;
    const sunriseLy = hasSunrise ? lyFor(sunriseLx) : 0;
    const sunsetLx = hasSunset
      ? Math.max(dotsStartX, Math.min(dotsEndX, lxFor(sunsetM)))
      : 0;
    const sunsetLy = hasSunset ? lyFor(sunsetLx) : 0;

    // ---- Ticker (logical position) ----
    const now = new Date();
    const nowM = now.getHours() * 60 + now.getMinutes();
    let tickerM = nowM;
    if (tickerM < fajrM) {
      tickerM = fajrM;
    }
    if (tickerM > ishaM) {
      tickerM = ishaM;
    }
    const tickerLx = Math.max(dotsStartX, Math.min(dotsEndX, lxFor(tickerM)));
    const tickerLy = lyFor(tickerLx);

    // ---- Colours ----
    const isDark: boolean = this.isDarkMode;
    const solidColor = isDark ? '#A5B8CC' : '#7B8FA3';
    const dotColor = isDark ? '#8892A6' : '#B0B8C0';
    const labelColor = isDark ? '#E8EDF4' : '#3F4754';
    const timeColor = isDark ? '#B4C0D0' : '#5A6270';
    const leaderColor = isDark
      ? 'rgba(180,192,208,0.55)'
      : 'rgba(138,143,152,0.50)';
    const activeDot = isDark ? '#FBBF24' : '#0F5132';
    const activeLabel = isDark ? '#FCD34D' : '#0F5132';
    const activeLeader = isDark
      ? 'rgba(251,191,36,0.80)'
      : 'rgba(15,81,50,0.65)';
    const activeRing = isDark
      ? 'rgba(251,191,36,0.30)'
      : 'rgba(15,81,50,0.22)';
    const horizonColor = isDark ? '#FBBF24' : '#F59E0B';
    const horizonLeader = isDark
      ? 'rgba(251,191,36,0.60)'
      : 'rgba(245,158,11,0.70)';
    const tickerColor = isDark ? '#C4B5FD' : '#7C3AED';

    // ---- Sample the arc (logical coordinates) ----
    const SAMPLES = 80;
    const pts: PathPoint[] = [];
    for (let i = 0; i <= SAMPLES; i++) {
      const lx = arcStartX + (arcW * i / SAMPLES);
      const pt: PathPoint = { x: lx, y: lyFor(lx) };
      pts.push(pt);
    }

    // ---- Current prayer index ----
    const prayerMinutes: number[] = [fajrM, dhuhrM, asrM, maghribM, ishaM];
    let activeIdx: number = -1;
    for (let i = 0; i < prayerMinutes.length; i++) {
      if (prayerMinutes[i] > 0 && prayerMinutes[i] <= nowM) {
        activeIdx = i;
      }
    }

    // ---- Arc line (mirrored when RTL) ----
    ctx.save();
    ctx.beginPath();
    ctx.moveTo(px(pts[0].x), pts[0].y);
    for (let i = 1; i < pts.length; i++) {
      ctx.lineTo(px(pts[i].x), pts[i].y);
    }
    ctx.strokeStyle = solidColor;
    ctx.lineWidth = 3;
    ctx.lineCap = 'round';
    ctx.stroke();
    ctx.restore();

    // ============================================================
    // PRAYER LABELS + TIMES + LEADERS + DOTS
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

    const leaderLengths: number[] = [
      LEADER_FAJR,
      LEADER_DHUHR,
      LEADER_ASR,
      LEADER_MAGHRIB,
      LEADER_ISHA
    ];

    // Precompute logical and physical dot positions.
    const dotLxs: number[] = [];
    const dotLys: number[] = [];
    for (let i = 0; i < prayerMinutes.length; i++) {
      const lx = lxFor(prayerMinutes[i]);
      dotLxs.push(lx);
      dotLys.push(lyFor(lx));
    }

    for (let i = 0; i < prayerMinutes.length; i++) {
      const lx = dotLxs[i];
      const ly = dotLys[i];
      const x = px(lx); // physical x after mirroring
      const y = ly; // y is unaffected by mirroring
      const isActive: boolean = (i === activeIdx);
      const L = leaderLengths[i];

      const leaderStartY = y - LEADER_DOT_GAP - L;
      const timeY = leaderStartY - LEADER_TIME_GAP;
      const labelY = timeY - LABEL_TIME_GAP;

      // ---- Dotted leader ----
      ctx.save();
      ctx.beginPath();
      ctx.moveTo(x, leaderStartY);
      ctx.lineTo(x, y - LEADER_DOT_GAP);
      ctx.strokeStyle = isActive ? activeLeader : leaderColor;
      ctx.lineWidth = 1.5;
      ctx.setLineDash([2, 3]);
      ctx.stroke();
      ctx.setLineDash([]);
      ctx.restore();

      // ---- Prayer name ----
      ctx.font = isActive
        ? `bold ${LABEL_FONT_SIZE}px sans-serif`
        : `${LABEL_FONT_SIZE}px sans-serif`;
      ctx.fillStyle = isActive ? activeLabel : labelColor;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'alphabetic';
      ctx.fillText(names[i], x, labelY);

      // ---- Prayer time ----
      ctx.font = `${TIME_FONT_SIZE}px sans-serif`;
      ctx.fillStyle = isActive ? activeLabel : timeColor;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'alphabetic';
      ctx.fillText(times[i], x, timeY);

      // ---- Active glow ring ----
      if (isActive) {
        ctx.beginPath();
        ctx.arc(x, y, 14, 0, Math.PI * 2);
        ctx.fillStyle = activeRing;
        ctx.fill();
      }

      // ---- Filled dot ----
      ctx.beginPath();
      ctx.arc(x, y, isActive ? 7 : 6, 0, Math.PI * 2);
      ctx.fillStyle = isActive ? activeDot : dotColor;
      ctx.fill();

      // ---- Specular highlight on the active dot ----
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
    // MOVING TICKER — "We are here" + current time
    // ============================================================

    const tickerX = px(tickerLx);
    const tickerY = tickerLy;

    ctx.save();
    ctx.beginPath();
    ctx.moveTo(tickerX, tickerY + TICKER_DOT_R + 1);
    ctx.lineTo(tickerX, TICKER_LABEL_Y - 12);
    ctx.strokeStyle = tickerColor;
    ctx.lineWidth = TICKER_LINE_W;
    ctx.lineCap = 'round';
    ctx.setLineDash([TICKER_DASH_ON, TICKER_DASH_OFF]);
    ctx.stroke();
    ctx.setLineDash([]);
    ctx.restore();

    ctx.beginPath();
    ctx.arc(tickerX, tickerY, TICKER_DOT_R, 0, Math.PI * 2);
    ctx.fillStyle = tickerColor;
    ctx.fill();
    ctx.beginPath();
    ctx.arc(tickerX, tickerY, TICKER_DOT_R + 3, 0, Math.PI * 2);
    ctx.strokeStyle = tickerColor;
    ctx.lineWidth = 1.5;
    ctx.stroke();

    ctx.font = `bold ${TIME_FONT_SIZE}px sans-serif`;
    ctx.fillStyle = tickerColor;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'alphabetic';
    ctx.fillText(
      L.get('sun_path_we_are_here', this.currentLanguage),
      tickerX,
      TICKER_LABEL_Y
    );

    ctx.font = `${TIME_FONT_SIZE}px sans-serif`;
    ctx.fillStyle = tickerColor;
    ctx.fillText(this.formatNow(now), tickerX, TICKER_TIME_Y);

    // ============================================================
    // SUNRISE / SUNSET — LABEL + TIME + LEADER + RING
    // ============================================================

    const sunriseLabel = L.get('timing_sunrise', this.currentLanguage);
    const sunsetLabel = L.get('timing_sunset', this.currentLanguage);
    const botLabelY = BOTTOM_LABEL_Y;
    const botTimeY = botLabelY + LABEL_TIME_GAP;

    if (hasSunrise) {
      const sx = px(sunriseLx);
      const sy = sunriseLy;

      ctx.save();
      ctx.beginPath();
      ctx.moveTo(sx, sy + 12);
      ctx.lineTo(sx, botLabelY - 20);
      ctx.strokeStyle = horizonLeader;
      ctx.lineWidth = 1.5;
      ctx.setLineDash([2, 3]);
      ctx.stroke();
      ctx.setLineDash([]);
      ctx.restore();

      ctx.beginPath();
      ctx.arc(sx, sy, 7, 0, Math.PI * 2);
      ctx.strokeStyle = horizonColor;
      ctx.lineWidth = 2;
      ctx.stroke();
      ctx.beginPath();
      ctx.arc(sx, sy, 3, 0, Math.PI * 2);
      ctx.fillStyle = horizonColor;
      ctx.fill();

      ctx.font = `bold ${LABEL_FONT_SIZE}px sans-serif`;
      ctx.fillStyle = horizonColor;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'alphabetic';
      ctx.fillText(sunriseLabel, sx, botLabelY);

      ctx.font = `${TIME_FONT_SIZE}px sans-serif`;
      ctx.fillStyle = horizonColor;
      ctx.fillText(this.sunriseTime, sx, botTimeY);
    }

    if (hasSunset) {
      const sx = px(sunsetLx);
      const sy = sunsetLy;

      ctx.save();
      ctx.beginPath();
      ctx.moveTo(sx, sy + 12);
      ctx.lineTo(sx, botLabelY - 20);
      ctx.strokeStyle = horizonLeader;
      ctx.lineWidth = 1.5;
      ctx.setLineDash([2, 3]);
      ctx.stroke();
      ctx.setLineDash([]);
      ctx.restore();

      ctx.beginPath();
      ctx.arc(sx, sy, 7, 0, Math.PI * 2);
      ctx.strokeStyle = horizonColor;
      ctx.lineWidth = 2;
      ctx.stroke();
      ctx.beginPath();
      ctx.arc(sx, sy, 3, 0, Math.PI * 2);
      ctx.fillStyle = horizonColor;
      ctx.fill();

      ctx.font = `bold ${LABEL_FONT_SIZE}px sans-serif`;
      ctx.fillStyle = horizonColor;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'alphabetic';
      ctx.fillText(sunsetLabel, sx, botLabelY);

      ctx.font = `${TIME_FONT_SIZE}px sans-serif`;
      ctx.fillStyle = horizonColor;
      ctx.fillText(this.sunsetTime, sx, botTimeY);
    }

    // Reset defaults.
    ctx.textAlign = 'center';
    ctx.textBaseline = 'alphabetic';
  }
}