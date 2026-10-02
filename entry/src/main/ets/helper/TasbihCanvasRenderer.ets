// entry/src/main/ets/helper/TasbihCanvasRenderer.ets

import {
  BeadColors, TasbihFinish, TasbihTheme, TasbihThemes
} from '../common/TasbihThemes';

export type BeadRenderStyle = 'classic' | 'premium';

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
  topShiftProgress: number;
  theme: TasbihTheme;
  bottomPrevCount: number;
  bottomFadeProgress: number;
  bottomPopProgress: number;
}

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

    // ---- Glossy string line ----
    TasbihCanvasRenderer.drawString(ctx, cx, H, cfg);

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

    const palette: BeadColors = TasbihThemes.palette(cfg.theme.color);

    // ---- TOP STACK ----
    const topColors: BeadColors = cfg.isComplete ? DONE_COLORS : palette;
    const topCount = cfg.topCount;
    if (topCount > 0) {
      const topScales: number[] = [];
      for (let i = 0; i < topCount; i++) {
        topScales.push(scaleFor(r + i * step));
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
            ctx, cx, finalY, r * topScales[i],
            topColors, cfg.renderStyle, cfg.theme.finish
          );
          ctx.restore();
        }
      }

      if (shift > 0) {
        const tailY = topCenters[topCount - 1];
        const extraY = tailY + step - shift * step;
        ctx.save();
        ctx.globalAlpha = shift;
        TasbihCanvasRenderer.drawBead(
          ctx, cx, extraY, r * topScales[topCount - 1],
          topColors, cfg.renderStyle, cfg.theme.finish
        );
        ctx.restore();
      }
    }

    // ---- BOTTOM STACK ----
    const botColors = cfg.isDark ? PEND_COLORS_DARK : PEND_COLORS_LIGHT;
    const botCount = cfg.bottomCount;

    const drawBottomCluster = (count: number, alpha: number): void => {
      if (count <= 0 || alpha <= 0.01) {
        return;
      }

      const scales: number[] = [];
      for (let i = 0; i < count; i++) {
        const ny = H - r - (count - 1 - i) * step;
        let s = scaleFor(ny);
        if (i === count - 1
          && cfg.bottomPopProgress > 0
          && cfg.bottomPopProgress < 1) {
          const bump = Math.sin(Math.PI * cfg.bottomPopProgress);
          s *= 1 + 0.28 * bump;
        }
        scales.push(s);
      }

      const centers: number[] = new Array(count).fill(0);
      centers[count - 1] = H - r * scales[count - 1];
      for (let i = count - 2; i >= 0; i--) {
        centers[i] =
          centers[i + 1] -
            r * scales[i + 1] -
            g * gapMult(scales[i], scales[i + 1]) -
            r * scales[i];
      }

      ctx.save();
      ctx.globalAlpha = alpha;
      for (let i = 0; i < count; i++) {
        TasbihCanvasRenderer.drawBead(
          ctx, cx, centers[i], r * scales[i],
          botColors, cfg.renderStyle, cfg.theme.finish
        );
      }
      ctx.restore();
    };

    drawBottomCluster(botCount, 1);

    // ---- Flying ghost bead (bottom → top) ----
    const prevBotCount = cfg.bottomPrevCount;
    const fly = cfg.bottomFadeProgress;
    if (prevBotCount > 0 && fly > 0 && fly < 1) {
      const startY = H - r - (prevBotCount - 1) * step;
      const targetY = r + 2 * step;
      const eased = fly < 0.5
        ? 2 * fly * fly
        : 1 - Math.pow(-2 * fly + 2, 2) / 2;
      const currentY = startY + (targetY - startY) * eased;
      const alpha = 1 - eased;

      if (alpha > 0.01) {
        // Halo — wide, warm amber glow that peaks mid-flight and
        // fades as the bead lands. The "arrival" feel of the reference.
        const haloRadius = r * 3.8;
        // Bloom peaks at ~55 % of the flight.
        const bloom = Math.sin(Math.PI * fly);
        const haloAlpha = (0.35 + 0.45 * bloom) * alpha;

        const halo = ctx.createRadialGradient(
          cx, currentY, r * 0.4,
          cx, currentY, haloRadius
        );
        halo.addColorStop(0, `rgba(255, 200, 110, ${0.85 * haloAlpha})`);
        halo.addColorStop(0.35, `rgba(245, 175, 80,  ${0.45 * haloAlpha})`);
        halo.addColorStop(0.70, `rgba(232, 150, 60,  ${0.15 * haloAlpha})`);
        halo.addColorStop(1, 'rgba(232, 150, 60, 0)');
        ctx.beginPath();
        ctx.arc(cx, currentY, haloRadius, 0, Math.PI * 2);
        ctx.fillStyle = halo;
        ctx.fill();

        // Bead itself.
        ctx.save();
        ctx.globalAlpha = alpha;
        TasbihCanvasRenderer.drawBead(
          ctx, cx, currentY, r * scaleFor(currentY),
          botColors, cfg.renderStyle, cfg.theme.finish
        );
        ctx.restore();
      }
    }
  }

  // ============================================================
  // GLOSSY STRING
  // ============================================================

  /**
   * Draws the string as a rounded, glossy line:
   *   • Wide dark base line
   *   • Narrow lighter strip in the center (highlight)
   * Produces the "cylinder" look seen in the reference.
   */
  private static drawString(
    ctx: CanvasRenderingContext2D,
    cx: number,
    H: number,
    cfg: BeadCanvasConfig
  ): void {
    const isDark = cfg.isDark;

    // Base — thin dark line, matching the reference.
    ctx.save();
    ctx.beginPath();
    ctx.moveTo(cx, 0);
    ctx.lineTo(cx, H);
    ctx.strokeStyle = isDark
      ? 'rgba(70, 70, 70, 0.70)'
      : 'rgba(130, 130, 130, 0.45)';
    ctx.lineWidth = 1.5;
    ctx.lineCap = 'round';
    ctx.stroke();
    ctx.restore();

    // Highlight — 1 px lighter strip, offset 1 px to the left.
    ctx.save();
    ctx.beginPath();
    ctx.moveTo(cx - 0.5, 0);
    ctx.lineTo(cx - 0.5, H);
    ctx.strokeStyle = isDark
      ? 'rgba(180, 180, 180, 0.28)'
      : 'rgba(255, 255, 255, 0.55)';
    ctx.lineWidth = 1;
    ctx.lineCap = 'round';
    ctx.stroke();
    ctx.restore();
  }

  // ============================================================
  // DISPATCH
  // ============================================================

  private static drawBead(
    ctx: CanvasRenderingContext2D,
    cx: number,
    cy: number,
    r: number,
    colors: BeadColors,
    style: BeadRenderStyle,
    finish: TasbihFinish
  ): void {
    if (style === 'classic') {
      TasbihCanvasRenderer.drawClassic(ctx, cx, cy, r, colors);
      return;
    }
    if (finish === TasbihFinish.METALLIC) {
      TasbihCanvasRenderer.drawMetallic(ctx, cx, cy, r, colors);
    } else {
      TasbihCanvasRenderer.drawMatte(ctx, cx, cy, r, colors);
    }
  }

  // ============================================================
  // CLASSIC
  // ============================================================

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

    // Bright specular hotspot, upper-left.
    ctx.beginPath();
    ctx.arc(cx - r * 0.28, cy - r * 0.28, r * 0.22, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(255, 255, 255, 0.65)';
    ctx.fill();
  }

  // ============================================================
  // MATTE — soft amber bead with strong specular
  // ============================================================

  private static drawMatte(
    ctx: CanvasRenderingContext2D,
    cx: number, cy: number, r: number, colors: BeadColors
  ): void {
    // Extrusion shadow.
    ctx.beginPath();
    ctx.arc(cx + 1.5, cy + 2.5, r, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(0, 0, 0, 0.42)';
    ctx.fill();

    // Base sphere — three-stop gradient, strong in the upper-left.
    const baseGrad = ctx.createRadialGradient(
      cx - r * 0.30, cy - r * 0.32, r * 0.05,
      cx, cy, r
    );
    baseGrad.addColorStop(0, colors.hi);
    baseGrad.addColorStop(0.5, colors.base);
    baseGrad.addColorStop(1, colors.lo);

    ctx.beginPath();
    ctx.arc(cx, cy, r, 0, Math.PI * 2);
    ctx.fillStyle = baseGrad;
    ctx.fill();

    // Bottom-right ambient occlusion for depth.
    ctx.save();
    ctx.beginPath();
    ctx.arc(cx, cy, r, 0, Math.PI * 2);
    ctx.clip();
    const ao = ctx.createRadialGradient(
      cx + r * 0.35, cy + r * 0.40, 0,
      cx + r * 0.35, cy + r * 0.40, r * 1.1
    );
    ao.addColorStop(0, 'rgba(0, 0, 0, 0.15)');
    ao.addColorStop(0.7, 'rgba(0, 0, 0, 0)');
    ctx.fillStyle = ao;
    ctx.fillRect(cx - r, cy - r, r * 2, r * 2);
    ctx.restore();

    // Sharp specular hotspot — upper-left. This is what gives the
    // bead its "polished" look, matching the reference.
    ctx.save();
    ctx.beginPath();
    ctx.arc(cx, cy, r, 0, Math.PI * 2);
    ctx.clip();
    const spec = ctx.createRadialGradient(
      cx - r * 0.35, cy - r * 0.40, 0,
      cx - r * 0.35, cy - r * 0.40, r * 0.55
    );
    spec.addColorStop(0, 'rgba(255, 255, 255, 0.95)');
    spec.addColorStop(0.25, 'rgba(255, 255, 255, 0.35)');
    spec.addColorStop(0.6, 'rgba(255, 255, 255, 0.05)');
    spec.addColorStop(1, 'rgba(255, 255, 255, 0)');
    ctx.fillStyle = spec;
    ctx.fillRect(cx - r, cy - r, r * 2, r * 2);
    ctx.restore();

    // Tight inner specular dot — the very bright pinpoint.
    ctx.beginPath();
    ctx.arc(cx - r * 0.35, cy - r * 0.40, r * 0.14, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(255, 255, 255, 0.85)';
    ctx.fill();
  }

  // ============================================================
  // METALLIC — brushed finish with conic rays
  // ============================================================

  private static drawMetallic(
    ctx: CanvasRenderingContext2D,
    cx: number, cy: number, r: number, colors: BeadColors
  ): void {
    ctx.beginPath();
    ctx.arc(cx + 1.5, cy + 3, r, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(0, 0, 0, 0.42)';
    ctx.fill();

    let usedConic = false;
    try {
      ctx.save();
      ctx.beginPath();
      ctx.arc(cx, cy, r, 0, Math.PI * 2);
      ctx.clip();

      const conic = ctx.createConicGradient(0, cx, cy);
      conic.addColorStop(0.000, colors.lo);
      conic.addColorStop(0.125, colors.hi);
      conic.addColorStop(0.250, colors.base);
      conic.addColorStop(0.375, colors.hi);
      conic.addColorStop(0.500, colors.lo);
      conic.addColorStop(0.625, colors.hi);
      conic.addColorStop(0.750, colors.base);
      conic.addColorStop(0.875, colors.hi);
      conic.addColorStop(1.000, colors.lo);

      ctx.fillStyle = conic;
      ctx.fillRect(cx - r, cy - r, r * 2, r * 2);
      ctx.restore();
      usedConic = true;
    } catch (e) {
      usedConic = false;
    }

    if (!usedConic) {
      const grad = ctx.createRadialGradient(
        cx - r * 0.3, cy - r * 0.3, r * 0.05, cx, cy, r
      );
      grad.addColorStop(0, colors.hi);
      grad.addColorStop(0.5, colors.base);
      grad.addColorStop(1, colors.lo);
      ctx.beginPath();
      ctx.arc(cx, cy, r, 0, Math.PI * 2);
      ctx.fillStyle = grad;
      ctx.fill();
    }

    // Radial darkening toward the edge.
    ctx.save();
    ctx.beginPath();
    ctx.arc(cx, cy, r, 0, Math.PI * 2);
    ctx.clip();
    const radial = ctx.createRadialGradient(cx, cy, r * 0.2, cx, cy, r);
    radial.addColorStop(0, 'rgba(255, 255, 255, 0.20)');
    radial.addColorStop(0.70, 'rgba(0, 0, 0, 0)');
    radial.addColorStop(1, 'rgba(0, 0, 0, 0.38)');
    ctx.fillStyle = radial;
    ctx.fillRect(cx - r, cy - r, r * 2, r * 2);
    ctx.restore();

    // Strong specular.
    ctx.save();
    ctx.beginPath();
    ctx.arc(cx, cy, r, 0, Math.PI * 2);
    ctx.clip();
    const spec = ctx.createRadialGradient(
      cx - r * 0.40, cy - r * 0.40, 0,
      cx - r * 0.40, cy - r * 0.40, r * 0.60
    );
    spec.addColorStop(0, 'rgba(255, 255, 255, 0.95)');
    spec.addColorStop(0.35, 'rgba(255, 255, 255, 0.22)');
    spec.addColorStop(1, 'rgba(255, 255, 255, 0)');
    ctx.fillStyle = spec;
    ctx.fillRect(cx - r, cy - r, r * 2, r * 2);
    ctx.restore();
  }
}