import { insightIntent, InsightIntentExecutor } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { WidgetDataBuilder } from '../widgets/WidgetDataBuilder';
import { PreferencesHelper } from '../core/PreferencesHelper';
import { RamadanHelper, RamadanInfo } from '../ramadan/RamadanHelper';
import { L } from '../i18n/LocalizationHelper';
import {
  STORAGE_KEY_HIJRI_OFFSET,
  STORAGE_KEY_LANGUAGE,
  STORAGE_KEY_LANGUAGE_OVERRIDE
} from '../core/StorageKeys';

/**
 * XiaoYi insight-intent executor.
 *
 * Handles two intents declared in `intent_config.json`:
 *
 *   GetPrayerTimes  — "What is the next prayer time?"
 *   GetRamadanStatus — "When is Ramadan?" / "Is it Ramadan today?"
 *
 * Both run in foreground mode, which guarantees EntryAbility
 * has already initialised PreferencesHelper (via onCreate →
 * onWindowStageCreate). No explicit init() is needed here.
 *
 * Responses are plain strings in the app's language, so XiaoYi
 * can read them verbatim. The app language is resolved from
 * preferences on every call — a language change made in the
 * main app takes effect on the very next intent.
 */
export default class PrayerIntentExecutor extends InsightIntentExecutor {
  async onExecuteInUIAbilityForegroundMode(
    name: string,
    param: Record<string, Object>,
    pageLoader: window.WindowStage
  ): Promise<insightIntent.ExecuteResult> {
    if (name === 'GetPrayerTimes') {
      return PrayerIntentExecutor.handleGetPrayerTimes();
    }
    if (name === 'GetRamadanStatus') {
      return PrayerIntentExecutor.handleGetRamadanStatus();
    }
    // Fallback for unknown intents
    const defaultResult: insightIntent.ExecuteResult = {
      code: -1,
      result: {
        message: 'Unknown intent'
      }
    };
    return defaultResult;
  }

  // ============================================================
  // GetPrayerTimes
  // ============================================================

  private static async handleGetPrayerTimes(): Promise<insightIntent.ExecuteResult> {
    try {
      // WidgetDataBuilder.build() resolves location + calculates
      // prayer times + formats the next-prayer pair, all in one
      // pass. Reusing it here avoids duplicating the pipeline.
      const data: Record<string, Object> = await WidgetDataBuilder.build('2*2');

      const nextName: string = data.nextName as string;
      const nextTime: string = data.nextTime as string;
      const message: string = `The next prayer is ${nextName} at ${nextTime}.`;

      const result: insightIntent.ExecuteResult = {
        code: 0,
        result: {
          message: message
        }
      };
      return result;
    } catch (e) {
      const error: Error = e as Error;
      const result: insightIntent.ExecuteResult = {
        code: -1,
        result: {
          message: `Failed to calculate prayer times: ${error.message}`
        }
      };
      return result;
    }
  }

  // ============================================================
  // GetRamadanStatus
  // ============================================================

  private static async handleGetRamadanStatus(): Promise<insightIntent.ExecuteResult> {
    try {
      // Reload from disk so a language change made in the app
      // after the executor was last called is reflected. Cheap
      // (one getAll) and safe (no-op if store is null).
      await PreferencesHelper.reloadFromDisk();

      const lang = await PrayerIntentExecutor.resolveLanguage();
      const hijriOffset = await PreferencesHelper.getNumber(
        STORAGE_KEY_HIJRI_OFFSET, 0
      );

      const info: RamadanInfo | null =
        RamadanHelper.getRamadanInfo(hijriOffset);

      if (info === null) {
        const result: insightIntent.ExecuteResult = {
          code: -1,
          result: {
            message: 'Ramadan information is not available.'
          }
        };
        return result;
      }

      const message = await PrayerIntentExecutor.buildRamadanMessage(info, lang);

      const result: insightIntent.ExecuteResult = {
        code: 0,
        result: {
          message: message
        }
      };
      return result;
    } catch (e) {
      const error: Error = e as Error;
      const result: insightIntent.ExecuteResult = {
        code: -1,
        result: {
          message: `Failed to get Ramadan status: ${error.message}`
        }
      };
      return result;
    }
  }

  // ============================================================
  // RESPONSE BUILDER
  // ============================================================

  private static async buildRamadanMessage(
    info: RamadanInfo,
    lang: string
  ): Promise<string> {
    if (info.isRamadanNow) {
      // ---- Ramadan is currently active ----
      // Prefer the rich "day X of Y · next event" phrasing. The
      // next event (Suhoor or Iftar) is already computed by the
      // Ramadan widget builder — reusing it keeps the countdown
      // phrasing identical between the widget and the voice reply.
      try {
        const widgetData = await WidgetDataBuilder.buildRamadanWidget('2*2', lang);
        const targetName = widgetData.targetName as string;
        const targetTime = widgetData.targetTime as string;
        const countdown = widgetData.countdown as string;

        const hasEvent =
          targetName.length > 0 &&
            targetTime.length > 0 &&
            targetTime !== '--:--';

        if (hasEvent) {
          const countdownPart = countdown.length > 0 ? `, ${countdown}` : '';
          return `Ramadan is currently active. Today is day ${info.currentDayNumber} of ${info.totalDays}. ${targetName} at ${targetTime}${countdownPart}.`;
        }
      } catch (e) {
        // Fall through — a basic day-X-of-Y answer is still useful
        // if widget data resolution fails (e.g. no location).
      }

      return `Ramadan is currently active. Today is day ${info.currentDayNumber} of ${info.totalDays}.`;
    }

    // ---- Ramadan is not currently active ----
    // The user asked "when is Ramadan" / "how many days until Ramadan"
    // — answer both: the countdown is the primary answer, the date
    // is the supporting detail.
    const days = info.daysUntilStart;
    const startDateStr = PrayerIntentExecutor.formatGregorianDate(
      info.fastingStart, lang
    );

    if (days === 0) {
      return `Ramadan begins today, ${startDateStr}.`;
    }
    if (days === 1) {
      return `Ramadan begins tomorrow, ${startDateStr}.`;
    }
    if (days < 0) {
      // Defensive — should not be reachable (isRamadanNow handles
      // the "we are inside Ramadan" case above, and daysUntilStart
      // is 0 whenever isRamadanNow is true). Included so a
      // future RamadanHelper change can't produce a negative-day
      // response.
      return `Ramadan begins on ${startDateStr}.`;
    }
    return `${days} days remaining until Ramadan, which begins on ${startDateStr}.`;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  /**
   * Resolve the effective UI language for the response.
   *
   * Matches WidgetDataBuilder's resolution order so the voice
   * response uses the same language the widget shows: explicit
   * override wins, "system" falls through to the device locale,
   * and an empty override falls back to STORAGE_KEY_LANGUAGE
   * (which is always set by EntryAbility on first run).
   */
  private static async resolveLanguage(): Promise<string> {
    const override = await PreferencesHelper.getString(
      STORAGE_KEY_LANGUAGE_OVERRIDE, 'system'
    );

    if (override === 'system') {
      return L.matchSystemLocale();
    }
    if (override.length > 0) {
      return override;
    }
    return PreferencesHelper.getString(STORAGE_KEY_LANGUAGE, 'en');
  }

  /**
   * Locale-aware long Gregorian date, e.g. "March 1, 2026".
   *
   * Intl.DateTimeFormat is used (matching RamadanHelper.formatLong
   * and HijriCalendarHelper.formatGregorianSpan) so the intent
   * response and the in-app displays stay consistent.
   */
  private static formatGregorianDate(date: Date, lang: string): string {
    const locale = lang === 'zh' ? 'zh-CN'
      : lang === 'ar' ? 'ar'
        : lang === 'ur' ? 'ur'
          : lang === 'tr' ? 'tr'
            : lang === 'bn' ? 'bn'
              : lang === 'id' ? 'id'
                : 'en-US';
    try {
      const fmt = new Intl.DateTimeFormat(locale, {
        month: 'long',
        day: 'numeric',
        year: 'numeric'
      });
      return fmt.format(date);
    } catch (err) {
      return date.toDateString();
    }
  }
}