// entry/src/main/ets/data/Duas.ets

/**
 * Registry of Duas used throughout the app.
 *
 * Each Dua has a stable key, the Arabic source, a phonetic
 * transliteration, and a localization key for the translation.
 *
 * To surface these in a future "Duas" tab, iterate over
 * DUA_REGISTRY and render each entry with the DuaCard component.
 * No other changes are needed — the data and the renderer are
 * both feature-agnostic.
 */

export interface DuaEntry {
  /** Stable id, also the base for the localization keys. */
  key: string;

  /** Arabic source. Same across all UI languages. */
  arabic: string;

  /** Romanized transliteration. Same across all UI languages. */
  transliteration: string;

  /** Localization key for the translation. */
  translationKey: string;

  /** Localization key for the dua's display name. */
  nameKey: string;
}

// ============================================================
// IFTAR — recited when breaking the fast (at Maghrib)
// ============================================================

export const DUA_IFTAR: DuaEntry = {
  key: 'dua_iftar',
  arabic: 'ذَهَبَ الظَّمَأُ وَابْتَلَّتِ الْعُرُوقُ وَثَبَتَ الْأَجْرُ إِنْ شَاءَ اللَّهُ',
  transliteration: 'Dhahaba adh-dhama\u2019u wabtallatil-\u2018urooqu wa thabata al-ajru in sha Allah.',
  translationKey: 'dua_iftar_translation',
  nameKey: 'dua_iftar_name'
};

// ============================================================
// SUHOOR — the intention for beginning the fast
// ============================================================

export const DUA_SUHOOR: DuaEntry = {
  key: 'dua_suhoor',
  arabic: 'وَبِصَوْمِ غَدٍ نَّوَيْتُ مِنْ شَهْرِ رَمَضَانَ',
  transliteration: 'Wa bisawmi ghadinn nawaiytu min shahri Ramadan.',
  translationKey: 'dua_suhoor_translation',
  nameKey: 'dua_suhoor_name'
};

// ============================================================
// REGISTRY
// ============================================================
// A future Duas tab can simply do:
//
//   ForEach(DUA_REGISTRY, (d: DuaEntry) => {
//     DuaCard({ dua: d, colors: this.colors,
//               currentLanguage: this.currentLanguage })
//   })
//
// Order here is the display order.

export const DUA_REGISTRY: DuaEntry[] = [
  DUA_IFTAR,
  DUA_SUHOOR
];

export class Duas {
  static byKey(key: string): DuaEntry | null {
    for (const d of DUA_REGISTRY) {
      if (d.key === key) {
        return d;
      }
    }
    return null;
  }
}