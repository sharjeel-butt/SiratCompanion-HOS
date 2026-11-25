// entry/src/main/ets/core/FontPaths.ets
//
// Single source of truth for every bundled font.
// No other file should contain raw font paths.
//

export class FontPaths {
  // ============================================================
  // BASE
  // ============================================================

  static readonly BASE: string = 'assets/fonts';
  // ============================================================
  // LATIN
  // ============================================================

  static readonly OUTFIT: string = `${FontPaths.BASE}/latin/Outfit-Regular.ttf`;
  static readonly OUTFIT_BOLD: string = `${FontPaths.BASE}/latin/Outfit-Bold.ttf`;
  // ============================================================
  // BENGALI
  // ============================================================

  static readonly NOTO_SANS_BENGALI: string = `${FontPaths.BASE}/bengali/NotoSansBengali-Regular.ttf`;
  // ============================================================
  // CHINESE
  // ============================================================

  static readonly NOTO_SANS_SC: string = `${FontPaths.BASE}/chinese/NotoSansSC-Regular.ttf`;
  // ============================================================
  // URDU
  // ============================================================

  static readonly NOTO_NASTALIQ_URDU: string = `${FontPaths.BASE}/urdu/NotoNastaliqUrdu-Regular.ttf`;
  static readonly JAMEEL_NOORI: string = `${FontPaths.BASE}/urdu/JameelNooriNastaleeq.ttf`;
  // ============================================================
  // ARABIC
  // ============================================================

  static readonly AMIRI: string = `${FontPaths.BASE}/arabic/Amiri-Regular.ttf`;
  static readonly AMIRI_BOLD: string = `${FontPaths.BASE}/arabic/Amiri-Bold.ttf`;
  static readonly AMIRI_QURAN: string = `${FontPaths.BASE}/arabic/AmiriQuran-Regular.ttf`;
  static readonly SCHEHERAZADE_NEW: string = `${FontPaths.BASE}/arabic/ScheherazadeNew-Regular.ttf`;
  static readonly NOTO_NASKH_ARABIC: string = `${FontPaths.BASE}/arabic/NotoNaskhArabic-Regular.ttf`;
  static readonly HAFS_ARABIC: string = `${FontPaths.BASE}/arabic/HafsArabic-Regular.ttf`;
  static readonly LPMQ_ISEP_MISBAH: string = `${FontPaths.BASE}/arabic/LPMQ-Regular.ttf`;
  static readonly KFGQPC_WARSH: string = `${FontPaths.BASE}/arabic/KFGQPC-Regular.ttf`;
  static readonly QPC_HAFS: string = `${FontPaths.BASE}/arabic/QPC-Hafs.ttf`;
}