// entry/src/main/ets/common/TasbihThemes.ets

/**
 * Tasbih bead themes.
 *
 * A theme has two orthogonal parts:
 *   1. Colour  — one of five palettes (Amber, Charcoal, Emerald, Pearl, Gold)
 *   2. Finish  — Matte (soft sphere) or Metallic (conic brushed look)
 *
 * Five presets ship out of the box, matching the swatches shown in
 * Customize → Appearance. Each tasbih can carry its own preset via
 * Tasbih.themePresetId; when it doesn't, the app-wide default preset
 * from STORAGE_KEY_TASBIH_THEME_PRESET is used instead.
 */

export enum TasbihColor {
  AMBER = 'amber',
  CHARCOAL = 'charcoal',
  EMERALD = 'emerald',
  PEARL = 'pearl',
  GOLD = 'gold'
}

export enum TasbihFinish {
  MATTE = 'matte',
  METALLIC = 'metallic'
}

export interface TasbihTheme {
  color: TasbihColor;
  finish: TasbihFinish;
}

/** Colours used by the canvas renderer. hi → base → lo for the radial gradient. */
export interface BeadColors {
  hi: string;
  base: string;
  lo: string;
}

/** A named preset shown in the UI. */
export interface TasbihThemePreset {
  id: string; // stable id, used for storage
  labelKey: string; // localization key
  color: TasbihColor;
  finish: TasbihFinish;
  swatch: string; // hex used in the UI preview
}

export const TASBIH_THEME_PRESETS: TasbihThemePreset[] = [
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
  }
];

/** Colour palettes consumed by the canvas renderer. */
export const THEME_PALETTES: Map<string, BeadColors> = new Map<string, BeadColors>([
  [TasbihColor.AMBER, { hi: '#F5C57A', base: '#E8A44C', lo: '#8B5A1A' }],
  [TasbihColor.CHARCOAL, { hi: '#6B6B6B', base: '#3A3A3A', lo: '#141414' }],
  [TasbihColor.EMERALD, { hi: '#4ADE80', base: '#1E7A4E', lo: '#0B3B26' }],
  [TasbihColor.PEARL, { hi: '#FFFFFF', base: '#D4E4F0', lo: '#8AA5B8' }],
  [TasbihColor.GOLD, { hi: '#FFF4C2', base: '#FFD54F', lo: '#B8860B' }]
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