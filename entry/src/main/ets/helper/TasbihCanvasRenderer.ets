// entry/src/main/ets/helper/TasbihCanvasRenderer.ets

export type BeadRenderStyle = 'classic' | 'premium';

export interface BeadColors {
  hi: string;
  base: string;
  lo: string;
}

export interface BeadCanvasConfig {
  topCount: number;
  bottomCount: number;
  isComplete: boolean;
  fingerY: number;
  fisheyeStrength: number;
  beadRadius: number;
  beadGap: number;
  renderStyle: BeadRenderStyle;
  isDark: boolean;
  stringColor: string;

  /** 0 → 1 during the rolling-window enter animation. 0 when idle. */
  topShiftProgress: number;
}

export const HEAD_COLORS: BeadColors = { hi: '#F5C57A', base: '#D18F35', lo: '#7A4A10' };

export const GOLD_COLORS: BeadColors = { hi: '#FFE0A0', base: '#E8A44C', lo: '#8B5A1A' };

export const DONE_COLORS: BeadColors = { hi: '#A7F3C0', base: '#4ADE80', lo: '#1E7A4E' };

export const PEND_COLORS_LIGHT: BeadColors = { hi: '#EFEAE0', base: '#C9C2B8', lo: '#8E8878' };

export const PEND_COLORS_DARK: BeadColors = { hi: '#5A5A5A', base: '#3A3A3A', lo: '#1A1A1A' };

export class TasbihCanvasRenderer {
  private static readonly FISHEYE_PEAK_SCALE = 1.65;
  private static readonly FISHEYE_SIGMA_MULT = 3.5;
  private static readonly FISHEYE_GAP_STRETCH = 0.55;

  static drawCanvas(
    ctx: CanvasRenderingContext2D,
    canvasWidth: number,
    canvasHeight: number,
    cfg: BeadCanvasConfig
  ): void {
    ctx.clearRect(0, 0, canvasWidth, canvasHeight);

    const cx = canvasWidth / 2;
    const r = cfg.beadRadius;
    const g = cfg.beadGap;
    const H = canvasHeight;
    const step = 2 * r + g;
    const shift = cfg.topShiftProgress;

    // ---- String line ----
    ctx.beginPath();
    ctx.moveTo(cx, 0);
    ctx.lineTo(cx, H);
    ctx.strokeStyle = cfg.stringColor;
    ctx.lineWidth = 2;
    ctx.stroke();

    // ---- Fisheye helpers ----
    const scaleFor = (naturalY: number): number => {
      if (cfg.fingerY < 0 || cfg.fisheyeStrength <= 0) {
        return 1;
      }
      const sigma = r * TasbihCanvasRenderer.FISHEYE_SIGMA_MULT;
      const d = naturalY - cfg.fingerY;
      const gauss = Math.exp(-(d * d) / (2 * sigma * sigma));
      return 1 + (TasbihCanvasRenderer.FISHEYE_PEAK_SCALE - 1) * gauss * cfg.fisheyeStrength;
    };

    const gapMult = (sa: number, sb: number): number => {
      return 1 + TasbihCanvasRenderer.FISHEYE_GAP_STRETCH * ((sa + sb) / 2 - 1);
    };

    // ---- TOP STACK ----
    const topColors = cfg.isComplete ? DONE_COLORS : GOLD_COLORS;
    const topCount = cfg.topCount;
    if (topCount > 0) {
      const topScales: number[] = [];
      const topNaturalYs: number[] = [];
      for (let i = 0; i < topCount; i++) {
        const ny = r + i * step;
        topNaturalYs.push(ny);
        topScales.push(scaleFor(ny));
      }
      const topCenters: number[] = [];
      topCenters.push(r * topScales[0]);
      for (let i = 1; i < topCount; i++) {
        topCenters.push(
          topCenters[i - 1] +
            r * topScales[i - 1] +
            g * gapMult(topScales[i - 1], topScales[i]) +
            r * topScales[i]
        );
      }

      for (let i = 0; i < topCount; i++) {
        const finalY = topCenters[i] - shift * step;
        const alpha = (i === 0 && shift > 0) ? (1 - shift) : 1;
        if (alpha > 0.01) {
          ctx.save();
          ctx.globalAlpha = alpha;
          TasbihCanvasRenderer.drawBead(
            ctx, cx, finalY, r * topScales[i], topColors, cfg.renderStyle
          );
          ctx.restore();
        }
      }

      // Extra bead entering from below the tail position
      if (shift > 0) {
        const tailY = topCenters[topCount - 1];
        const extraY = tailY + step - shift * step;
        ctx.save();
        ctx.globalAlpha = shift;
        TasbihCanvasRenderer.drawBead(
          ctx, cx, extraY, r * topScales[topCount - 1], topColors, cfg.renderStyle
        );
        ctx.restore();
      }
    }

    // ---- BOTTOM STACK ----
    const botColors = cfg.isDark ? PEND_COLORS_DARK : PEND_COLORS_LIGHT;
    const botCount = cfg.bottomCount;
    if (botCount > 0) {
      const botScales: number[] = [];
      const botNaturalYs: number[] = [];
      for (let i = 0; i < botCount; i++) {
        const ny = H - r - (botCount - 1 - i) * step;
        botNaturalYs.push(ny);
        botScales.push(scaleFor(ny));
      }
      const botCenters: number[] = new Array(botCount).fill(0);
      botCenters[botCount - 1] = H - r * botScales[botCount - 1];
      for (let i = botCount - 2; i >= 0; i--) {
        botCenters[i] =
          botCenters[i + 1] -
            r * botScales[i + 1] -
            g * gapMult(botScales[i], botScales[i + 1]) -
            r * botScales[i];
      }
      for (let i = 0; i < botCount; i++) {
        TasbihCanvasRenderer.drawBead(
          ctx, cx, botCenters[i], r * botScales[i], botColors, cfg.renderStyle
        );
      }
    }
  }

  private static drawBead(
    ctx: CanvasRenderingContext2D,
    cx: number,
    cy: number,
    r: number,
    colors: BeadColors,
    style: BeadRenderStyle
  ): void {
    if (style === 'classic') {
      TasbihCanvasRenderer.drawClassic(ctx, cx, cy, r, colors);
    } else {
      TasbihCanvasRenderer.drawPremium(ctx, cx, cy, r, colors);
    }
  }

  private static drawClassic(
    ctx: CanvasRenderingContext2D,
    cx: number, cy: number, r: number, colors: BeadColors
  ): void {
    const grad = ctx.createRadialGradient(
      cx - r * 0.28, cy - r * 0.28, r * 0.05,
      cx, cy, r
    );
    grad.addColorStop(0, colors.hi);
    grad.addColorStop(0.55, colors.base);
    grad.addColorStop(1, colors.lo);

    ctx.beginPath();
    ctx.arc(cx, cy, r, 0, Math.PI * 2);
    ctx.fillStyle = grad;
    ctx.fill();

    ctx.beginPath();
    ctx.arc(cx - r * 0.22, cy - r * 0.22, r * 0.22, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(255, 255, 255, 0.55)';
    ctx.fill();
  }

  private static drawPremium(
    ctx: CanvasRenderingContext2D,
    cx: number, cy: number, r: number, colors: BeadColors
  ): void {
    // 1. Extrusion shadow
    ctx.beginPath();
    ctx.arc(cx + 1.5, cy + 3, r, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(0, 0, 0, 0.38)';
    ctx.fill();

    // 2. Base sphere
    const baseGrad = ctx.createRadialGradient(
      cx - r * 0.30, cy - r * 0.30, r * 0.05,
      cx, cy, r
    );
    baseGrad.addColorStop(0, colors.hi);
    baseGrad.addColorStop(0.5, colors.base);
    baseGrad.addColorStop(1, colors.lo);

    ctx.beginPath();
    ctx.arc(cx, cy, r, 0, Math.PI * 2);
    ctx.fillStyle = baseGrad;
    ctx.fill();

    // 3. Chromatic aberration
    ctx.save();
    ctx.beginPath();
    ctx.arc(cx, cy, r, 0, Math.PI * 2);
    ctx.clip();
    ctx.globalCompositeOperation = 'screen';
    ctx.beginPath();
    ctx.arc(cx - r * 0.07, cy, r * 0.97, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(0, 200, 255, 0.10)';
    ctx.fill();
    ctx.beginPath();
    ctx.arc(cx + r * 0.07, cy, r * 0.97, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(255, 0, 200, 0.10)';
    ctx.fill();
    ctx.restore();

    // 4. Metallic sheen
    try {
      ctx.save();
      ctx.beginPath();
      ctx.arc(cx, cy, r, 0, Math.PI * 2);
      ctx.clip();
      const sheen = ctx.createConicGradient(0, cx, cy);
      sheen.addColorStop(0, 'rgba(0,0,0,0.22)');
      sheen.addColorStop(0.25, 'rgba(255,255,255,0.30)');
      sheen.addColorStop(0.5, 'rgba(0,0,0,0.22)');
      sheen.addColorStop(0.75, 'rgba(255,255,255,0.30)');
      sheen.addColorStop(1, 'rgba(0,0,0,0.22)');
      ctx.globalCompositeOperation = 'overlay';
      ctx.fillStyle = sheen;
      ctx.fillRect(cx - r, cy - r, r * 2, r * 2);
      ctx.restore();
    } catch (e) { /* conic gradient unsupported — skip */
    }

    // 5. Specular highlight
    ctx.save();
    ctx.beginPath();
    ctx.arc(cx, cy, r, 0, Math.PI * 2);
    ctx.clip();
    const spec = ctx.createRadialGradient(
      cx - r * 0.35, cy - r * 0.35, 0,
      cx - r * 0.35, cy - r * 0.35, r * 0.65
    );
    spec.addColorStop(0, 'rgba(255, 255, 255, 0.85)');
    spec.addColorStop(0.35, 'rgba(255, 255, 255, 0.15)');
    spec.addColorStop(1, 'rgba(255, 255, 255, 0)');
    ctx.fillStyle = spec;
    ctx.fillRect(cx - r, cy - r, r * 2, r * 2);
    ctx.restore();

    // 6. Bounce light
    ctx.save();
    ctx.beginPath();
    ctx.arc(cx, cy, r, 0, Math.PI * 2);
    ctx.clip();
    const bounce = ctx.createRadialGradient(
      cx + r * 0.20, cy + r * 0.40, 0,
      cx + r * 0.20, cy + r * 0.40, r * 0.60
    );
    bounce.addColorStop(0, 'rgba(255, 255, 255, 0.14)');
    bounce.addColorStop(1, 'rgba(255, 255, 255, 0)');
    ctx.fillStyle = bounce;
    ctx.fillRect(cx - r, cy - r, r * 2, r * 2);
    ctx.restore();
  }
}