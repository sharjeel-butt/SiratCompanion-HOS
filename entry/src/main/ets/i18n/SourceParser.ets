// entry/src/main/ets/core/SourceParser.ets
import { L } from './LocalizationHelper'

export interface SourceItem {
  type: string
  id?: string
  surah?: number
  ayah?: number
  display?: string
}

export class SourceParser {
  /**
   * Converts a SourceItem into a fully localized string based on the App UI Language.
   */
  static getLabel(src: SourceItem, lang: string): string {
    if (src.type === 'external') {
      return src.display ?? ''
    }

    if (src.type === 'quran') {
      const quranLabel = L.get('quran_full_title', lang) // e.g. "The Noble Quran"
      const finalQuran = quranLabel !== 'quran_full_title' ? quranLabel : 'Quran'
      return `${finalQuran} ${src.surah}:${src.ayah}`
    }

    if (src.type === 'hadith' && src.id) {
      const parts = src.id.split(':')
      if (parts.length === 2) {
        let col = parts[0]
        const num = parts[1]

        // Expand aliases
        if (col === 'bukh') {
          col = 'bukhari'
        } else if (col === 'musl') {
          col = 'muslim'
        } else if (col === 'abud') {
          col = 'abudawud'
        } else if (col === 'tirm') {
          col = 'tirmidhi'
        } else if (col === 'nasa') {
          col = 'nasai'
        } else if (col === 'ibnm') {
          col = 'ibnmajah'
        } else if (col === 'mali') {
          col = 'malik'
        }

        const colKey = 'collection_' + col
        const locCol = L.get(colKey, lang) // Fallback to capitalized English name if localized key is missing
        const finalCol = locCol !== colKey ? locCol : col.charAt(0).toUpperCase() + col.slice(1)

        return `${finalCol} ${num}`
      }
      return src.id
    }

    return ''
  }
}
