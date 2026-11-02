/**
 * Registry of Tasbih click sounds.
 *
 * Each entry maps a stable id to a bundled .ogg file.
 */

export interface TasbihSoundOption {
  /** Stable id used for persistence. */
  id: string;

  /** Raw file path inside resources/rawfile/. */
  file: string;
}

export const TASBIH_SOUND_OPTIONS: TasbihSoundOption[] = [
  { id: 'glass_tap', file: 'sounds/tasbih/tasbih_glass_tap.ogg' },
  { id: 'light_chime', file: 'sounds/tasbih/tasbih_light_chime.ogg' },
  { id: 'muted_bead', file: 'sounds/tasbih/tasbih_muted_bead.ogg' },
  { id: 'soft_click', file: 'sounds/tasbih/tasbih_soft_click.ogg' },
  { id: 'warm_knock', file: 'sounds/tasbih/tasbih_warm_knock.ogg' }
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
   */
  static deriveDisplayName(file: string): string {
    // 1. Extract just the filename (e.g., "tasbih_glass_tap.ogg")
    // This handles files in subdirectories correctly.
    const filename = file.substring(file.lastIndexOf('/') + 1);

    // 2. Strip the prefix and extension
    const base = filename.replace(/^tasbih_/, '').replace(/\.ogg$/, '');

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
   */
  static deriveDescription(file: string): string {
    const name = SoundOptions.deriveDisplayName(file);
    return `${name} sound`;
  }
}