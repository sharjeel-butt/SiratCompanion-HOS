// entry/src/main/ets/helper/TypographyHelper.ets

import { font } from '@kit.ArkUI';

export class TypographyHelper {
  /**
   * Register custom fonts. Call this once in EntryAbility.
   */
  static init(): void {
    try {
      // English / Numbers
      font.registerFont({ familyName: 'Outfit', familySrc: $rawfile('fonts/Outfit-Regular.ttf') });
      font.registerFont({ familyName: 'Outfit-Bold', familySrc: $rawfile('fonts/Outfit-Bold.ttf') });

      // Arabic
      font.registerFont({ familyName: 'Amiri', familySrc: $rawfile('fonts/Amiri-Regular.ttf') });
      font.registerFont({ familyName: 'Amiri-Bold', familySrc: $rawfile('fonts/Amiri-Bold.ttf') });
    } catch (err) {
      console.error('[TypographyHelper] Font registration failed:', JSON.stringify(err));
    }
  }

  /**
   * Returns the appropriate font family string.
   * We use a font stack ("Font, sans-serif") so that if a character
   * (like a Chinese character) is missing from the custom font,
   * the system automatically falls back to the default sans-serif.
   */
  static getFont(lang: string, isBold: boolean = false): string {
    if (lang === 'ar') {
      return isBold ? 'Amiri-Bold, sans-serif' : 'Amiri, sans-serif';
    }
    // English and Chinese fallback
    return isBold ? 'Outfit-Bold, sans-serif' : 'Outfit, sans-serif';
  }
}