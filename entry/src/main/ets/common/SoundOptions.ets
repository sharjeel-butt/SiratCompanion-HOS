// entry/src/main/ets/common/SoundOptions.ets

/**
 * Registry of Tasbih click sounds.
 *
 * Each entry maps a stable id to a bundled .ogg file. Names and
 * descriptions are auto-derived from the filename via
 * `SoundOptions.deriveDisplayName()` — you don't have to hand-craft
 * strings for each new sound.
 *
 * To add a sound later:
 *   1. Drop the .ogg into resources/rawfile/
 *   2. Append one line to TASBIH_SOUND_OPTIONS
 * Nothing else needs to change.
 */

export interface TasbihSoundOption {
  /** Stable id used for persistence. */
  id: string;

  /** Raw filename inside resources/rawfile/. */
  file: string;
}

export const TASBIH_SOUND_OPTIONS: TasbihSoundOption[] = [
  { id: 'glass_tap', file: 'tasbih_glass_tap.ogg' },
  { id: 'light_chime', file: 'tasbih_light_chime.ogg' },
  { id: 'muted_bead', file: 'tasbih_muted_bead.ogg' },
  { id: 'soft_click', file: 'tasbih_soft_click.ogg' },
  { id: 'warm_knock', file: 'tasbih_warm_knock.ogg' }
];

export class SoundOptions {
  /** Default sound used when nothing has been chosen. */
  static readonly DEFAULT_ID = 'soft_click';

  static byId(id: string): TasbihSoundOption | null {
    for (const opt of TASBIH_SOUND_OPTIONS) {
      if (opt.id === id) {
        return opt;
      }
    }
    return null;
  }

  /**
   * Derive a display name from the file name.
   *
   *   "tasbih_glass_tap.ogg"  →  "Glass Tap"
   *   "tasbih_soft_click.ogg" →  "Soft Click"
   */
  static deriveDisplayName(file: string): string {
    const base = file.replace(/^tasbih_/, '').replace(/\.ogg$/, '');
    const words = base.split('_');
    let out = '';
    for (let i = 0; i < words.length; i++) {
      const w = words[i];
      if (w.length === 0) {
        continue;
      }
      if (out.length > 0) {
        out += ' ';
      }
      out += w.charAt(0).toUpperCase() + w.slice(1);
    }
    return out;
  }

  /**
   * Derive a description from the file name.
   *
   *   "tasbih_glass_tap.ogg"  →  "Glass tap sound"
   *   "tasbih_soft_click.ogg" →  "Soft click sound"
   */
  static deriveDescription(file: string): string {
    const name = SoundOptions.deriveDisplayName(file);
    return `${name} sound`;
  }
}