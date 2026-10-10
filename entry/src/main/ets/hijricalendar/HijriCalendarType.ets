// entry/src/main/ets/common/HijriCalendarType.ets

/**
 * Which Hijri calendar engine to use for date conversion.
 *
 * UMM_AL_QURA — the official calendar of Saudi Arabia. Uses a
 *   pre-computed table of month lengths covering 1318–1500 AH
 *   (Gregorian 1900–2076), based on KACST astronomical data.
 *   Outside this range, falls back to the tabular algorithm.
 *
 * TABULAR — the arithmetical (Kuwaiti) calendar. Pure arithmetic:
 *   twelve months alternating 30 and 29 days, with 11 leap years
 *   in a 30-year cycle (intercalary years 2, 5, 7, 10, 13, 16, 18,
 *   21, 24, 26, 29). Civil (Friday) epoch: 1 Muharram 1 AH =
 *   16 July 622 CE (Julian) = 19 July 622 CE (Gregorian).
 *
 * The tabular calendar is deterministic and valid for all years,
 * but can differ from the Umm al-Qura calendar by 1–2 days.
 */
export enum HijriCalendarType {
  UMM_AL_QURA = 'UmmAlQura',
  TABULAR = 'Tabular'
}