// entry/src/main/ets/common/TasbihThemes.ets

/**
 * Tasbih bead themes.
 *
 * A theme has two orthogonal parts:
 *   1. Colour  — one of nine palettes
 *   2. Finish  — Matte (soft sphere) or Metallic (conic brushed look)
 *
 * Nine presets ship out of the box. Each tasbih can carry its own
 * preset via Tasbih.themePresetId; when it doesn't, the app-wide
 * default preset from STORAGE_KEY_TASBIH_THEME_PRESET is used.
 *
 * Every palette is chosen so the bead reads clearly in both light
 * and dark mode:
 *   • hi   — near-white or very bright, for the specular highlight
 *   • base — the mid colour the bead reads as
 *   • lo   — a deep value for dimension and shadow
 */

export enum TasbihColor {
  AMBER = 'amber',
  CHARCOAL = 'charcoal',
  EMERALD = 'emerald',
  PEARL = 'pearl',
  GOLD = 'gold',
  WHITE = 'white',
  SAPPHIRE = 'sapphire',
  ROSE = 'rose',
  SILVER = 'silver'
}

export enum TasbihFinish {
  MATTE = 'matte',
  METALLIC = 'metallic'
}

export interface TasbihTheme {
  color: TasbihColor;
  finish: TasbihFinish;
}

/** Colours used by the canvas renderer. hi → base → lo. */
export interface BeadColors {
  hi: string;
  base: string;
  lo: string;
}

/** A named preset shown in the UI. */
export interface TasbihThemePreset {
  id: string;
  labelKey: string;
  color: TasbihColor;
  finish: TasbihFinish;
  swatch: string;
}

export const TASBIH_THEME_PRESETS: TasbihThemePreset[] = [
  // ---- Original five ----
  {
    id: 'amber',
    labelKey: 'theme_amber',
    color: TasbihColor.AMBER,
    finish: TasbihFinish.MATTE,
    swatch: '#E8A44C'
  },
  {
    id: 'charcoal',
    labelKey: 'theme_charcoal',
    color: TasbihColor.CHARCOAL,
    finish: TasbihFinish.MATTE,
    swatch: '#3A3A3A'
  },
  {
    id: 'emerald',
    labelKey: 'theme_emerald',
    color: TasbihColor.EMERALD,
    finish: TasbihFinish.MATTE,
    swatch: '#1E7A4E'
  },
  {
    id: 'pearl',
    labelKey: 'theme_pearl',
    color: TasbihColor.PEARL,
    finish: TasbihFinish.MATTE,
    swatch: '#D4E4F0'
  },
  {
    id: 'gold',
    labelKey: 'theme_gold',
    color: TasbihColor.GOLD,
    finish: TasbihFinish.METALLIC,
    swatch: '#FFD54F'
  },
  // ---- New: white and dark-mode friendly additions ----
  {
    id: 'white',
    labelKey: 'theme_white',
    color: TasbihColor.WHITE,
    finish: TasbihFinish.MATTE,
    swatch: '#F0F2F5'
  },
  {
    id: 'sapphire',
    labelKey: 'theme_sapphire',
    color: TasbihColor.SAPPHIRE,
    finish: TasbihFinish.MATTE,
    swatch: '#3B82F6'
  },
  {
    id: 'rose',
    labelKey: 'theme_rose',
    color: TasbihColor.ROSE,
    finish: TasbihFinish.MATTE,
    swatch: '#EC4899'
  },
  {
    id: 'silver',
    labelKey: 'theme_silver',
    color: TasbihColor.SILVER,
    finish: TasbihFinish.METALLIC,
    swatch: '#C0C5CE'
  }
];

/**
 * Colour palettes consumed by the canvas renderer.
 *
 * Every base value reads at roughly the same perceived luminance so
 * no single theme feels "washed out" next to the others. The `lo`
 * values are all dark enough to create contrast against the dark
 * card background (#141B2E) and against the light card (#FFFFFF).
 */
export const THEME_PALETTES: Map<string, BeadColors> = new Map<string, BeadColors>([
  [TasbihColor.AMBER, { hi: '#F5C57A', base: '#E8A44C', lo: '#8B5A1A' }],
  [TasbihColor.CHARCOAL, { hi: '#6B6B6B', base: '#3A3A3A', lo: '#141414' }],
  [TasbihColor.EMERALD, { hi: '#4ADE80', base: '#1E7A4E', lo: '#0B3B26' }],
  [TasbihColor.PEARL, { hi: '#FFFFFF', base: '#D4E4F0', lo: '#8AA5B8' }],
  [TasbihColor.GOLD, { hi: '#FFF4C2', base: '#FFD54F', lo: '#B8860B' }],
  // White — pure, high-key. Works on both themes because the base
  // is off-white and the low is a mid grey that gives dimension.
  [TasbihColor.WHITE, { hi: '#FFFFFF', base: '#E5E9EF', lo: '#9CA3AF' }],
  // Sapphire — vivid blue with a navy shadow for depth on dark bg.
  [TasbihColor.SAPPHIRE, { hi: '#BFDBFE', base: '#3B82F6', lo: '#1E3A8A' }],
  // Rose — bright pink with a deep rose shadow.
  [TasbihColor.ROSE, { hi: '#FBCFE8', base: '#EC4899', lo: '#9F1239' }],
  // Silver — brushed metal look, darker low so it stands out on
  // the dark card without looking like a flat grey circle.
  [TasbihColor.SILVER, { hi: '#F8FAFC', base: '#B8BFC9', lo: '#4B5563' }]
]);

export class TasbihThemes {
  static readonly DEFAULT_PRESET_ID = 'amber';

  static presetById(id: string): TasbihThemePreset {
    for (const p of TASBIH_THEME_PRESETS) {
      if (p.id === id) {
        return p;
      }
    }
    return TASBIH_THEME_PRESETS[0];
  }

  static themeForPreset(id: string): TasbihTheme {
    const p = TasbihThemes.presetById(id);
    return { color: p.color, finish: p.finish };
  }

  static palette(color: TasbihColor): BeadColors {
    const c = THEME_PALETTES.get(color);
    return c !== undefined ? c : THEME_PALETTES.get(TasbihColor.AMBER)!;
  }
}