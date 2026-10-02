// entry/src/main/ets/components/QiblaCalibrationOverlay.ets

import { ThemeColors } from '../common/Theme';
import { L } from '../helper/LocalizationHelper';

/**
 * Full-screen calibration overlay for the Qibla compass.
 *
 * Shows an animated figure-8 path with a moving phone icon. The
 * user is instructed to trace the same pattern with their physical
 * device. Dismisses automatically once accuracy improves, or after
 * a "Skip for now" tap once the grace period has elapsed.
 */
@Component
export struct QiblaCalibrationOverlay {
  /** How long the figure-8 trace takes, in ms. */
  private static readonly LOOP_MS = 2400;
  /** How long before "Skip for now" appears, in ms. */
  private static readonly GRACE_MS = 10_000;
  /** Visual dimensions — matched to the overlay layout. */
  private static readonly TRACE_W = 240;
  private static readonly TRACE_H = 140;
  private static cachedGhost: GhostPoint[] | null = null;
  @Prop colors: ThemeColors;
  @Prop currentLanguage: string = 'en';
  @Prop isDarkMode: boolean = false;
  // Whether the skip button should be visible (after grace period).
  @State showSkip: boolean = false;
  // Figure-8 animation state
  @State private tracerX: number = 0;
  @State private tracerY: number = 0;
  @State private tracerOpacity: number = 1.0;
  @State private pathProgress: number = 0;
  private animTimerId: number = -1;
  private graceTimerId: number = -1;
  private startTime: number = 0;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  /** Fires when the user taps "Skip for now". */
  onSkip: () => void = () => {
  };

  aboutToAppear(): void {
    this.startTime = Date.now();
    this.animateTracer();

    this.graceTimerId = setInterval(() => {
      const elapsed = Date.now() - this.startTime;
      if (elapsed >= QiblaCalibrationOverlay.GRACE_MS && !this.showSkip) {
        this.showSkip = true;
        clearInterval(this.graceTimerId);
        this.graceTimerId = -1;
      }
    }, 500);
  }

  // ============================================================
  // FIGURE-8 TRACER
  // ============================================================

  aboutToDisappear(): void {
    if (this.animTimerId !== -1) {
      clearInterval(this.animTimerId);
      this.animTimerId = -1;
    }
    if (this.graceTimerId !== -1) {
      clearInterval(this.graceTimerId);
      this.graceTimerId = -1;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  build() {
    Stack() {
      // ---- Dim backdrop ----
      Column()
        .width('100%').height('100%')
        .backgroundColor(this.isDarkMode
          ? 'rgba(0, 0, 0, 0.85)'
          : 'rgba(0, 0, 0, 0.72)')

      // ---- Centered card ----
      Column() {
        // Icon
        Text('🧭')
          .fontSize(48)
          .margin({ bottom: 16 })

        // Title
        Text(L.get('qibla_calibrate_title', this.currentLanguage))
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Center)
          .width('100%')

        // Instruction
        Text(L.get('qibla_calibrate_desc', this.currentLanguage))
          .fontSize(14)
          .fontColor('rgba(255, 255, 255, 0.78)')
          .textAlign(TextAlign.Center)
          .lineHeight(20)
          .width('100%')
          .margin({ top: 10 })
          .padding({ left: 24, right: 24 })

        // ---- Figure-8 animation track ----
        this.FigureEightTrack()

        // ---- Skip button (after grace period) ----
        if (this.showSkip) {
          Button(L.get('qibla_calibrate_skip', this.currentLanguage))
            .fontSize(13)
            .fontColor('rgba(255, 255, 255, 0.85)')
            .backgroundColor('rgba(255, 255, 255, 0.12)')
            .borderRadius(20)
            .height(38)
            .padding({ left: 22, right: 22 })
            .margin({ top: 8 })
            .onClick(() => {
              this.onSkip();
            })
        } else {
          // Placeholder keeps the layout height stable
          Row().height(38).margin({ top: 8 })
        }
      }
      .width('100%')
      .padding({ top: 40, bottom: 40 })
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%').height('100%')
    .alignContent(Alignment.Center)
  }

  // ============================================================
  // FIGURE-8 TRACK
  // ============================================================

  @Builder
  FigureEightTrack() {
    Stack() {
      // ---- Ghost path — the ∞ shape drawn with dots ----
      this.GhostPath()

      // ---- Animated tracer (a glowing dot with a phone glyph) ----
      Stack() {
        // Outer glow
        Column()
          .width(52)
          .height(52)
          .borderRadius(26)
          .backgroundColor('rgba(255, 210, 100, 0.22)')
          .position({ x: -14, y: -14 })

        // Inner disc
        Column()
          .width(28)
          .height(28)
          .borderRadius(14)
          .backgroundColor('#FFC107')
          .shadow({
            radius: 12,
            color: 'rgba(255, 193, 7, 0.6)',
            offsetX: 0,
            offsetY: 0
          })

        // Phone glyph
        Text('📱')
          .fontSize(14)
          .position({ x: 4, y: 4 })
      }
      .width(24).height(24)
      .translate({ x: this.tracerX, y: this.tracerY })

      // The tracer stays visible always — it's the focal point.
    }
    .width(QiblaCalibrationOverlay.TRACE_W)
    .height(QiblaCalibrationOverlay.TRACE_H)
    .margin({ top: 36, bottom: 36 })
    .direction(Direction.Ltr)
  }

  /**
   * The ghost figure-8 — drawn as ~48 evenly-spaced translucent
   * dots along the lemniscate. Gives the user a clear target to
   * trace with their physical device.
   */
  @Builder
  GhostPath() {
    Stack() {
      ForEach(this.ghostPoints(), (pt: GhostPoint, i: number) => {
        Column()
          .width(6)
          .height(6)
          .borderRadius(3)
          .backgroundColor(i <= Math.floor(this.pathProgress * 48)
            ? 'rgba(255, 193, 7, 0.75)'
            : 'rgba(255, 255, 255, 0.18)')
          .translate({ x: pt.x, y: pt.y })
      }, (pt: GhostPoint, i: number) => `pt-${i}`)
    }
    .width(QiblaCalibrationOverlay.TRACE_W)
    .height(QiblaCalibrationOverlay.TRACE_H)
    .direction(Direction.Ltr)
  }

  private animateTracer(): void {
    this.animTimerId = setInterval(() => {
      const elapsed = Date.now() - this.startTime;
      const t = (elapsed % QiblaCalibrationOverlay.LOOP_MS)
        / QiblaCalibrationOverlay.LOOP_MS;

      // Parametric figure-8:
      //   x = A · sin(2πt)
      //   y = B · sin(4πt)
      // This traces a lemniscate of Gerono — the classic ∞ shape.
      const angle = t * 2 * Math.PI;
      const x = Math.sin(angle) * (QiblaCalibrationOverlay.TRACE_W / 2 - 30);
      const y = Math.sin(2 * angle) * (QiblaCalibrationOverlay.TRACE_H / 2 - 20);

      this.tracerX = x;
      this.tracerY = y;
      this.pathProgress = t;
    }, 16);
  }

  /**
   * Compute the 48 sample points along the lemniscate once and
   * reuse them across renders. The array is stable — same x/y for
   * every rebuild.
   */
  private ghostPoints(): GhostPoint[] {
    if (QiblaCalibrationOverlay.cachedGhost !== null) {
      return QiblaCalibrationOverlay.cachedGhost;
    }

    const out: GhostPoint[] = [];
    const N = 48;
    const A = QiblaCalibrationOverlay.TRACE_W / 2 - 30;
    const B = QiblaCalibrationOverlay.TRACE_H / 2 - 20;

    for (let i = 0; i < N; i++) {
      const angle = (i / N) * 2 * Math.PI;
      const p: GhostPoint = {
        x: Math.sin(angle) * A,
        y: Math.sin(2 * angle) * B
      };
      out.push(p);
    }

    QiblaCalibrationOverlay.cachedGhost = out;
    return out;
  }
}

interface GhostPoint {
  x: number;
  y: number;
}