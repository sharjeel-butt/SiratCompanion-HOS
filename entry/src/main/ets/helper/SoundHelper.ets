// entry/src/main/ets/helper/SoundHelper.ets

import { media } from '@kit.MediaKit';
import { audio } from '@kit.AudioKit';
import { common } from '@kit.AbilityKit';
import { resourceManager } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import {
  STORAGE_KEY_SOUND_ENABLED, STORAGE_KEY_TASBIH_SOUND
} from '../common/StorageKeys';
import { SoundOptions, TASBIH_SOUND_OPTIONS } from '../common/SoundOptions';
import { SystemFeedbackHelper } from './SystemFeedbackHelper';

/**
 * Plays a short click on each Tasbih count.
 *
 * Uses SoundPool — designed for multiple short sounds — so
 * playback latency is <10 ms and rapid counting never stutters.
 * All sounds are preloaded during app startup.
 *
 * Fire-and-forget. Never throws.
 */
export class SoundHelper {
  private static pool: media.SoundPool | null = null;
  /** soundId per option id (e.g. 'soft_click' → 3). */
  private static soundIds: Map<string, number> = new Map();
  private static ready: boolean = false;
  private static initializing: boolean = false;

  // ============================================================
  // INIT
  // ============================================================

  static async init(context: common.UIAbilityContext): Promise<void> {
    if (SoundHelper.ready || SoundHelper.initializing) {
      return;
    }
    SoundHelper.initializing = true;

    try {
      const audioRendererInfo: audio.AudioRendererInfo = {
        usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
        rendererFlags: 0
      };

      const pool: media.SoundPool = await media.createSoundPool(
        TASBIH_SOUND_OPTIONS.length + 2, // headroom for concurrent streams
        audioRendererInfo
      );

      const mgr: resourceManager.ResourceManager = context.resourceManager;

      for (const opt of TASBIH_SOUND_OPTIONS) {
        try {
          const fd: resourceManager.RawFileDescriptor =
            await mgr.getRawFd(opt.file);
          const sid: number = await pool.load(fd.fd, fd.offset, fd.length);
          SoundHelper.soundIds.set(opt.id, sid);
        } catch (err) {
          const e = err as BusinessError;
          console.warn(
            `[SoundHelper] failed to load ${opt.file}: ${e.code} ${e.message}`
          );
        }
      }

      SoundHelper.pool = pool;
      SoundHelper.ready = SoundHelper.soundIds.size > 0;
      console.info(
        `[SoundHelper] ready with ${SoundHelper.soundIds.size} sound(s)`
      );
    } catch (err) {
      const e = err as BusinessError;
      console.warn(`[SoundHelper] init failed: ${e.code} ${e.message}`);
      SoundHelper.ready = false;
    } finally {
      SoundHelper.initializing = false;
    }
  }

  // ============================================================
  // PLAYBACK
  // ============================================================

  /** Fire-and-forget tick using the currently selected sound. */
  static tick(): void {
    if (!SoundHelper.isEnabled()) {
      return;
    }
    // Respect the system's silent mode — when the ringer is set to
    // silent or vibrate, suppress our own sound entirely.
    if (!SystemFeedbackHelper.isSystemSoundEnabled()) {
      return;
    }
    SoundHelper.playById(SoundHelper.currentSoundId());
  }

  /** Play a specific sound by its option id — used by the picker preview. */
  static playById(id: string): void {
    if (!SoundHelper.ready || SoundHelper.pool === null) {
      return;
    }

    const sid = SoundHelper.soundIds.get(id);
    if (sid === undefined) {
      return;
    }

    SoundHelper.pool.play(sid).catch(() => { /* ignore */
    });
  }

  /** Play the sound regardless of the enable flag — used by the picker. */
  static preview(id: string): void {
    SoundHelper.playById(id);
  }

  // ============================================================
  // STATE
  // ============================================================

  private static isEnabled(): boolean {
    const v = AppStorage.get<boolean>(STORAGE_KEY_SOUND_ENABLED);
    return v === undefined ? true : v;
  }

  private static currentSoundId(): string {
    const v = AppStorage.get<string>(STORAGE_KEY_TASBIH_SOUND);
    if (v === undefined || v.length === 0) {
      return SoundOptions.DEFAULT_ID;
    }
    return v;
  }

  static release(): void {
    if (SoundHelper.pool !== null) {
      SoundHelper.pool.release();
      SoundHelper.pool = null;
    }
    SoundHelper.soundIds.clear();
    SoundHelper.ready = false;
  }
}