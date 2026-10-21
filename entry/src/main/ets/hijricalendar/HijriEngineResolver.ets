// entry/src/main/ets/utils/HijriEngineResolver.ets

import { HijriCalendarEngine } from './HijriCalendarEngine';
import { UmmAlQuraEngine } from './UmmAlQuraEngine';
import { TabularHijriEngine } from './TabularHijriEngine';
import { HijriCalendarType } from './HijriCalendarType';
import { STORAGE_KEY_HIJRI_CALENDAR_TYPE } from '../common/StorageKeys';

/**
 * Returns the Hijri calendar engine matching the user's current
 * calendar-type setting. Both engines are stateless and cheap to
 * keep alive for the process lifetime, so they are instantiated
 * once and reused.
 *
 * The type is read from AppStorage on every call rather than cached,
 * so switching the setting in Settings → Hijri Calendar takes
 * effect on the next conversion without any invalidation step.
 */
export class HijriEngineResolver {
  private static readonly ummAlQura: UmmAlQuraEngine =
    new UmmAlQuraEngine();
  private static readonly tabular: TabularHijriEngine =
    new TabularHijriEngine();

  static current(): HijriCalendarEngine {
    const type = AppStorage.get<string>(STORAGE_KEY_HIJRI_CALENDAR_TYPE);
    if (type === HijriCalendarType.TABULAR) {
      return HijriEngineResolver.tabular;
    }
    return HijriEngineResolver.ummAlQura;
  }
}