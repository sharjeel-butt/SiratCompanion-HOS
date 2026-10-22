// entry/src/main/ets/helper/RamadanStorage.ets

import { PreferencesHelper } from './PreferencesHelper';
import { AppLogger } from './AppLogger';
import {
  FastingDay,
  FastingStatus,
  MissedReason,
  QadaSummary,
  QadaYearRow,
  RamadanLogStore,
  RamadanYearData
} from '../models/RamadanModels';
import {
  STORAGE_KEY_RAMADAN_LOG, STORAGE_KEY_RAMADAN_STATE_VERSION
} from '../common/StorageKeys';

/**
 * Persistence and pure helpers for the Ramadan tracker.
 *
 * ## Storage model
 *
 * The entire store lives under one preferences key (`ramadan_log`)
 * as a JSON string. The store is small (a few KB even after many
 * years), so a single read on load is cheaper than N per-year
 * reads.
 *
 * ## Concurrency
 *
 * Every write is serialized through a promise chain (`enqueue`).
 * Two rapid UI events (e.g. toggling taraweeh on two rows in
 * quick succession) would otherwise both read the pre-write state
 * and one would overwrite the other's change. The queue
 * guarantees read-modify-write cycles run one at a time.
 *
 * Reads (`load`) do not go through the queue — a read that lands
 * mid-write sees the pre-write state, which is corrected by the
 * version bump at the end of the write (every page observing
 * STORAGE_KEY_RAMADAN_STATE_VERSION re-reads on that bump).
 *
 * ## Version counter
 *
 * Every successful write bumps STORAGE_KEY_RAMADAN_STATE_VERSION.
 * This is the same pattern as STORAGE_KEY_PRAYER_STATE_VERSION —
 * pages bound via @StorageLink re-render when it changes, which
 * is the only reliable cross-tab refresh signal in an ArkUI Tabs
 * host.
 */
export class RamadanStorage {
  // ============================================================
  // SERIAL WRITE QUEUE
  // ============================================================

  /**
   * Serialises read-modify-write sequences. UI events that fire
   * "in parallel" from ArkUI's perspective still execute their
   * async tails interleaved on the JS thread; without this queue,
   * two rapid toggles could both read the pre-write state and one
   * would overwrite the other's change.
   */
  private static queue: Promise<void> = Promise.resolve();

  private static enqueue<T>(fn: () => Promise<T>): Promise<T> {
    const result = RamadanStorage.queue.then((): Promise<T> => fn());
    // Swallow rejection on the chain continuation so a failed
    // write cannot permanently block subsequent writes.
    RamadanStorage.queue = result.then(
      (): void => { /* noop */
      },
      (): void => { /* noop */
      }
    );
    return result;
  }

  // ============================================================
  // PUBLIC READ
  // ============================================================

  /**
   * Load the entire store. Never throws — malformed JSON or a
   * missing key both yield an empty store. A corrupt file therefore
   * degrades to "no data tracked yet" rather than crashing the app.
   */
  static async load(): Promise<RamadanLogStore> {
    return RamadanStorage.doLoad();
  }

  /**
   * Return the entry for a Hijri year, creating it (and persisting
   * it) if absent. Called from the Details page on open so the
   * heatmap has a full days[] array even before the user touches
   * anything.
   *
   * If the year exists but totalDays has changed (calendar-type
   * switch flipped a 30-day Ramadan to 29, or vice versa), the
   * existing days/nights are preserved and padded or trimmed.
   */
  static async getOrCreateYear(
    hijriYear: number,
    totalDays: number
  ): Promise<RamadanYearData> {
    return RamadanStorage.enqueue(async (): Promise<RamadanYearData> => {
      const store = await RamadanStorage.doLoad();

      const idx = RamadanStorage.findYearIndex(store, hijriYear);
      if (idx >= 0) {
        const existing = store.years[idx];
        if (existing.totalDays === totalDays
          && existing.days.length === totalDays
          && existing.taraweehNights.length === totalDays) {
          return existing;
        }
        // Resize — preserve what we have, pad/trim the tail.
        const resized = RamadanStorage.resizeYear(existing, totalDays);
        store.years[idx] = resized;
        await RamadanStorage.doSave(store);
        return resized;
      }

      const created = RamadanStorage.createEmptyYear(
        hijriYear, totalDays
      );
      store.years.push(created);
      await RamadanStorage.doSave(store);
      return created;
    });
  }

  /**
   * Load a year's data without creating it. Returns null if the
   * year is absent. Used by the year-detail sheet, which should not
   * create empty data just by opening.
   */
  static async getYear(
    hijriYear: number
  ): Promise<RamadanYearData | null> {
    const store = await RamadanStorage.load();
    for (const year of store.years) {
      if (year.hijriYear === hijriYear) {
        return year;
      }
    }
    return null;
  }

  // ============================================================
  // PUBLIC WRITES
  // ============================================================

  /**
   * Set a single day's fasting status.
   *
   * `reason` is only meaningful when status === MISSED.
   * `customReason` is only meaningful when reason === OTHER.
   * Both are silently ignored otherwise.
   *
   * Silently no-ops if the year has not been created yet, or if
   * `day` is outside 1..totalDays. Callers are expected to have
   * called getOrCreateYear first, and to supply a valid day.
   */
  static async markDay(
    hijriYear: number,
    day: number,
    status: FastingStatus,
    reason?: MissedReason,
    customReason?: string
  ): Promise<void> {
    return RamadanStorage.enqueue(async (): Promise<void> => {
      const store = await RamadanStorage.doLoad();
      const idx = RamadanStorage.findYearIndex(store, hijriYear);
      if (idx < 0) {
        AppLogger.warn('RamadanStorage',
          `markDay: year ${hijriYear} not found`);
        return;
      }
      const year = store.years[idx];
      if (day < 1 || day > year.totalDays) {
        AppLogger.warn('RamadanStorage',
          `markDay: day ${day} out of range 1..${year.totalDays}`);
        return;
      }

      const isMissed = status === FastingStatus.MISSED;
      const previous = year.days[day - 1];

      // Preserve the madeUp flag only when re-marking the same day
      // as MISSED with the same reason. Every other transition
      // (MISSED → FASTED, MISSED → UNMARKED, MISSED → MISSED with a
      // different reason) clears it — the user is correcting an
      // error and made-up status should start fresh.
      const sameMissed =
        isMissed
          && previous !== undefined
          && previous.status === FastingStatus.MISSED
          && previous.reason === reason
          && previous.customReason ===
          ((reason === MissedReason.OTHER) ? customReason : undefined);

      const preservedMadeUp = sameMissed
        ? (previous.madeUp === true)
        : false;
      const preservedMadeUpAt = sameMissed
        ? previous.madeUpAt
        : undefined;

      const entry: FastingDay = {
        status: status,
        reason: isMissed ? reason : undefined,
        customReason: (isMissed && reason === MissedReason.OTHER)
          ? customReason
          : undefined,
        madeUp: preservedMadeUp,
        madeUpAt: preservedMadeUpAt
      };
      year.days[day - 1] = entry;

      await RamadanStorage.doSave(store);
    });
  }

  /** Flip one night's taraweeh toggle. */
  static async toggleTaraweeh(
    hijriYear: number,
    night: number
  ): Promise<void> {
    return RamadanStorage.enqueue(async (): Promise<void> => {
      const store = await RamadanStorage.doLoad();
      const idx = RamadanStorage.findYearIndex(store, hijriYear);
      if (idx < 0) {
        return;
      }
      const year = store.years[idx];
      if (night < 1 || night > year.totalDays) {
        return;
      }
      year.taraweehNights[night - 1] =
        !year.taraweehNights[night - 1];
      await RamadanStorage.doSave(store);
    });
  }

  /**
   * Toggle the made-up state of a single missed day.
   *
   * Only meaningful when the day's status is MISSED. A no-op on
   * FASTED or UNMARKED days. Also a no-op if the year or day does
   * not exist.
   *
   * The counter model (adjustQadaMadeUp) was replaced with per-day
   * granularity so users can attribute make-ups to specific days.
   * Legacy counters are migrated to flags on first load — see
   * doLoad().
   */
  static async toggleDayMadeUp(
    hijriYear: number,
    day: number
  ): Promise<void> {
    return RamadanStorage.enqueue(async (): Promise<void> => {
      const store = await RamadanStorage.doLoad();
      const idx = RamadanStorage.findYearIndex(store, hijriYear);
      if (idx < 0) {
        return;
      }
      const year = store.years[idx];
      if (day < 1 || day > year.totalDays) {
        return;
      }
      const entry = year.days[day - 1];
      if (entry === undefined || entry.status !== FastingStatus.MISSED) {
        return;
      }
      if (entry.madeUp === true) {
        entry.madeUp = false;
        entry.madeUpAt = undefined;
      } else {
        entry.madeUp = true;
        entry.madeUpAt = Date.now();
      }
      await RamadanStorage.doSave(store);
    });
  }

  // ============================================================
  // PURE COMPUTATION — testable in isolation
  // ============================================================

  /**
   * Compute the Qada summary across every year in the store.
   *
   * Pure — no side effects, no I/O. Same input always produces
   * the same output.
   *
   * Example:
   *   store.years = [
   *     { hijriYear: 1445, days: [MISSED, MISSED, FASTED], qadaMadeUp: 1 },
   *     { hijriYear: 1446, days: [MISSED], qadaMadeUp: 0 },
   *   ]
   *   =>
   *   { totalMissed: 3, totalMadeUp: 1, remaining: 2,
   *     perYear: [
   *       { hijriYear: 1445, missed: 2, madeUp: 1 },
   *       { hijriYear: 1446, missed: 1, madeUp: 0 },
   *     ]}
   */
  static computeQadaSummary(store: RamadanLogStore): QadaSummary {
    let totalFasted = 0;
    let totalMissed = 0;
    let totalMadeUp = 0;
    let totalUnmarked = 0;
    const perYear: QadaYearRow[] = [];

    for (const year of store.years) {
      const fasted = RamadanStorage.countFasted(year);
      const missed = RamadanStorage.countMissed(year);
      const madeUp = RamadanStorage.countMadeUp(year);
      const unmarked = RamadanStorage.countUnmarked(year);
      const row: QadaYearRow = {
        hijriYear: year.hijriYear,
        fasted: fasted,
        missed: missed,
        madeUp: madeUp,
        unmarked: unmarked,
        outstanding: Math.max(0, missed - madeUp)
      };
      perYear.push(row);
      totalFasted += fasted;
      totalMissed += missed;
      totalMadeUp += madeUp;
      totalUnmarked += unmarked;
    }

    perYear.sort((a: QadaYearRow, b: QadaYearRow): number =>
    a.hijriYear - b.hijriYear
    );

    const remaining = Math.max(0, totalMissed - totalMadeUp);
    const summary: QadaSummary = {
      totalFasted: totalFasted,
      totalMissed: totalMissed,
      totalMadeUp: totalMadeUp,
      totalUnmarked: totalUnmarked,
      remaining: remaining,
      totalOutstanding: remaining,
      perYear: perYear
    };
    return summary;
  }

  /** Count MISSED days in a year. Pure. */
  static countMissed(year: RamadanYearData): number {
    let count = 0;
    for (const day of year.days) {
      if (day.status === FastingStatus.MISSED) {
        count++;
      }
    }
    return count;
  }

  /** Count FASTED days in a year. Pure. */
  static countFasted(year: RamadanYearData): number {
    let count = 0;
    for (const day of year.days) {
      if (day.status === FastingStatus.FASTED) {
        count++;
      }
    }
    return count;
  }

  /** Count UNMARKED days in a year. Pure. */
  static countUnmarked(year: RamadanYearData): number {
    let count = 0;
    for (const day of year.days) {
      if (day.status === FastingStatus.UNMARKED) {
        count++;
      }
    }
    return count;
  }

  /** Count MISSED days that have been made up. Pure. */
  static countMadeUp(year: RamadanYearData): number {
    let count = 0;
    for (const day of year.days) {
      if (day.status === FastingStatus.MISSED && day.madeUp === true) {
        count++;
      }
    }
    return count;
  }

  // ============================================================
  // INTERNALS
  // ============================================================

  private static async doLoad(): Promise<RamadanLogStore> {
    const raw = await PreferencesHelper.getString(
      STORAGE_KEY_RAMADAN_LOG, ''
    );
    if (raw.length === 0) {
      const empty: RamadanLogStore = { years: [] };
      return empty;
    }
    let parsed: RamadanLogStore;
    try {
      parsed = JSON.parse(raw) as RamadanLogStore;
    } catch (err) {
      AppLogger.warn('RamadanStorage',
        'load: parse failed, using empty store');
      const empty: RamadanLogStore = { years: [] };
      return empty;
    }
    if (!parsed.years || !Array.isArray(parsed.years)) {
      const empty: RamadanLogStore = { years: [] };
      return empty;
    }

    // ---- Migration: qadaMadeUp counter → per-day madeUp flags ----
    //
    // Pre-v3.5.0 data carried a simple `qadaMadeUp` counter with no
    // per-day attribution. Distribute that count to the first N
    // missed days of the year, then reset the counter to zero. After
    // migration, the flags are the single source of truth.
    //
    // This is best-effort attribution: we cannot know which specific
    // days the user had made up. If they disagree with the automatic
    // distribution, they can toggle individual days via the year sheet.
    let migrated = false;
    for (const year of parsed.years) {
      if (year.qadaMadeUp > 0) {
        let remaining = year.qadaMadeUp;
        for (let i = 0; i < year.days.length && remaining > 0; i++) {
          const d = year.days[i];
          if (d.status === FastingStatus.MISSED && d.madeUp !== true) {
            d.madeUp = true;
            d.madeUpAt = Date.now();
            remaining--;
          }
        }
        year.qadaMadeUp = 0;
        migrated = true;
      }
      // Also seed `madeUp: false` on every MISSED day that lacks the
      // field. `typeof` is used instead of `=== undefined` because
      // the interface types the field as required `boolean`, so a
      // direct comparison would fail type checking. At runtime the
      // field may still be missing on data written before this
      // migration, which is what this guards against.
      for (const d of year.days) {
        if (typeof d.madeUp !== 'boolean') {
          d.madeUp = false;
          migrated = true;
        }
      }
    }

    if (migrated) {
      AppLogger.info('RamadanStorage',
        'load: migrated legacy qadaMadeUp counters to per-day flags');
      // Persist the migration so it only runs once. Fire-and-forget.
      RamadanStorage.doPersistMigrated(parsed).catch(() => { /* logged inside */
      });
    }

    return parsed;
  }

  private static async doPersistMigrated(
    store: RamadanLogStore
  ): Promise<void> {
    try {
      const json = JSON.stringify(store);
      await PreferencesHelper.setString(STORAGE_KEY_RAMADAN_LOG, json);
      // Do not bump the version here — this is a background migration,
      // not a user action. Pages will read the migrated state on their
      // next natural load.
    } catch (err) {
      AppLogger.warn('RamadanStorage',
        'migration persist failed');
    }
  }

  private static async doSave(store: RamadanLogStore): Promise<void> {
    const json = JSON.stringify(store);
    await PreferencesHelper.setString(STORAGE_KEY_RAMADAN_LOG, json);
    RamadanStorage.bumpVersion();
  }

  private static bumpVersion(): void {
    const prev =
      AppStorage.get<number>(STORAGE_KEY_RAMADAN_STATE_VERSION);
    const next = (prev === undefined ? 0 : prev) + 1;
    AppStorage.setOrCreate(
      STORAGE_KEY_RAMADAN_STATE_VERSION, next
    );
  }

  private static findYearIndex(
    store: RamadanLogStore,
    hijriYear: number
  ): number {
    for (let i = 0; i < store.years.length; i++) {
      if (store.years[i].hijriYear === hijriYear) {
        return i;
      }
    }
    return -1;
  }

  private static createEmptyYear(
    hijriYear: number,
    totalDays: number
  ): RamadanYearData {
    const days: FastingDay[] = [];
    for (let i = 0; i < totalDays; i++) {
      const day: FastingDay = {
        status: FastingStatus.UNMARKED,
        madeUp: false
      };
      days.push(day);
    }
    const nights: boolean[] = [];
    for (let i = 0; i < totalDays; i++) {
      nights.push(false);
    }
    const year: RamadanYearData = {
      hijriYear: hijriYear,
      totalDays: totalDays,
      days: days,
      taraweehNights: nights,
      qadaMadeUp: 0
    };
    return year;
  }

  /**
   * Change a year's totalDays while preserving every entry that
   * still has a slot in the new length. Trims the tail when the
   * new length is shorter; pads with UNMARKED / false when longer.
   */
  private static resizeYear(
    year: RamadanYearData,
    newTotalDays: number
  ): RamadanYearData {
    const days: FastingDay[] = [];
    for (let i = 0; i < newTotalDays; i++) {
      if (i < year.days.length) {
        days.push(year.days[i]);
      } else {
        const fresh: FastingDay = {
          status: FastingStatus.UNMARKED,
          madeUp: false
        };
        days.push(fresh);
      }
    }
    const nights: boolean[] = [];
    for (let i = 0; i < newTotalDays; i++) {
      if (i < year.taraweehNights.length) {
        nights.push(year.taraweehNights[i]);
      } else {
        nights.push(false);
      }
    }
    const resized: RamadanYearData = {
      hijriYear: year.hijriYear,
      totalDays: newTotalDays,
      days: days,
      taraweehNights: nights,
      qadaMadeUp: year.qadaMadeUp
    };
    return resized;
  }
}