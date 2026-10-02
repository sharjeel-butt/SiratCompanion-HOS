// entry/src/main/ets/helper/SystemFeedbackHelper.ets

import { audio } from '@kit.AudioKit';
import { BusinessError, settings } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { STORAGE_KEY_SYSTEM_HAPTICS_ENABLED, STORAGE_KEY_SYSTEM_SOUND_ENABLED } from '../common/StorageKeys';
import { AppLogger } from './AppLogger';

/**
 * Reads and monitors the system's sound & haptics state.
 *
 * Two independent system controls affect us:
 *
 *   1. Ringer mode (3-state: ring / vibrate / silent)
 *      Controlled via audioManager. Governs the alarm, ring,
 *      notification, and communication usage types. We use it
 *      as a proxy for "the user wants the phone to be silent" —
 *      when silent, we suppress our own sound.
 *
 *   2. Haptics toggle (设置 → 声音与振动 → 系统触感反馈)
 *      Read via @ohos.settings. Governs the unknown / touch /
 *      media usage types — which is exactly what HapticHelper
 *      uses. When off, all our vibrations become no-ops at the
 *      OS level already; we mirror it here so the UI can show
 *      the correct state.
 *
 * Both states are mirrored into AppStorage so the helper can
 * be queried synchronously from any page.
 */
export class SystemFeedbackHelper {
  private static context: common.UIAbilityContext | null = null;
  private static observerRegistered: boolean = false;
  private static ringerObserverRegistered: boolean = false;
  private static volumeGroupManager: audio.AudioVolumeGroupManager | null = null;

  // ============================================================
  // INIT
  // ============================================================

  /** Call once at app startup (after the ability context exists). */
  static init(context: common.UIAbilityContext): void {
    SystemFeedbackHelper.context = context;
    SystemFeedbackHelper.refresh();
    SystemFeedbackHelper.registerObservers();
  }

  /** Re-read the current system state. */
  static refresh(): void {
    if (SystemFeedbackHelper.context === null) {
      return;
    }

    SystemFeedbackHelper.refreshHaptics();
    SystemFeedbackHelper.refreshRingerMode();
  }

  // ============================================================
  // HAPTICS TOGGLE
  // ============================================================

  /** True when the system allows our app to play sound. */
  static isSystemSoundEnabled(): boolean {
    const v = AppStorage.get<boolean>(STORAGE_KEY_SYSTEM_SOUND_ENABLED);
    return v === undefined ? true : v;
  }

  // ============================================================
  // RINGER MODE
  // ============================================================

  /** True when the system's haptics toggle is on. */
  static isSystemHapticsEnabled(): boolean {
    const v = AppStorage.get<boolean>(STORAGE_KEY_SYSTEM_HAPTICS_ENABLED);
    return v === undefined ? true : v;
  }

  // ============================================================
  // LIVE OBSERVERS
  // ============================================================

  private static refreshHaptics(): void {
    if (SystemFeedbackHelper.context === null) {
      return;
    }
    try {
      // '1' = enabled, '0' = disabled. Default to enabled.
      const raw = settings.getValueSync(
        SystemFeedbackHelper.context,
        settings.sound.HAPTIC_FEEDBACK_STATUS,
        '1'
      );
      const enabled = raw === '1';
      AppStorage.setOrCreate(STORAGE_KEY_SYSTEM_HAPTICS_ENABLED, enabled);
    } catch (err) {
      const e = err as BusinessError;
      AppLogger.warn(
        'SystemFeedbackHelper',
        `haptics read failed: ${e.code} ${e.message}`
      );
      AppStorage.setOrCreate(STORAGE_KEY_SYSTEM_HAPTICS_ENABLED, true);
    }
  }

  /**
   * Read the current ringer mode synchronously.
   *
   * Chain:
   *   audioManager
   *     → getVolumeManager()           (AudioVolumeManager)
   *     → getVolumeGroupManager(id)    (AudioVolumeGroupManager)
   *     → getRingerModeSync()          (AudioRingMode)
   *
   * Requires SystemCapability.Multimedia.Audio.Volume.
   */
  private static refreshRingerMode(): void {
    try {
      const audioManager = audio.getAudioManager();
      const volumeManager = audioManager.getVolumeManager();
      const groupManager = volumeManager.getVolumeGroupManagerSync(
        audio.DEFAULT_VOLUME_GROUP_ID
      );

      const mode: audio.AudioRingMode = groupManager.getRingerModeSync();

      // NORMAL  → sound on
      // VIBRATE → sound off (silent mode, vibration only)
      // SILENT  → sound off
      const soundAllowed = (mode === audio.AudioRingMode.RINGER_MODE_NORMAL);
      AppStorage.setOrCreate(STORAGE_KEY_SYSTEM_SOUND_ENABLED, soundAllowed);

      // Cache the group manager so we can register the change listener.
      SystemFeedbackHelper.volumeGroupManager = groupManager;

      console.info(
        `[SystemFeedbackHelper] ringer mode = ${mode}, soundAllowed = ${soundAllowed}`
      );
    } catch (err) {
      const e = err as BusinessError;
      AppLogger.warn(
        'SystemFeedbackHelper',
        `ringer mode read failed: ${e.code} ${e.message}`
      );
      AppStorage.setOrCreate(STORAGE_KEY_SYSTEM_SOUND_ENABLED, true);
    }
  }

  private static registerObservers(): void {
    SystemFeedbackHelper.registerHapticsObserver();
    SystemFeedbackHelper.registerRingerModeObserver();
  }

  // ============================================================
  // PUBLIC READERS (synchronous)
  // ============================================================

  private static registerHapticsObserver(): void {
    if (SystemFeedbackHelper.observerRegistered) {
      return;
    }
    if (SystemFeedbackHelper.context === null) {
      return;
    }

    try {
      settings.registerKeyObserver(
        SystemFeedbackHelper.context,
        settings.sound.HAPTIC_FEEDBACK_STATUS,
        settings.domainName.USER_PROPERTY,
        () => {
          SystemFeedbackHelper.refreshHaptics();
        }
      );
      SystemFeedbackHelper.observerRegistered = true;
    } catch (err) {
      const e = err as BusinessError;
      AppLogger.warn(
        'SystemFeedbackHelper',
        `haptics observer registration failed: ${e.code} ${e.message}`
      );
    }
  }

  private static registerRingerModeObserver(): void {
    if (SystemFeedbackHelper.ringerObserverRegistered) {
      return;
    }
    if (SystemFeedbackHelper.volumeGroupManager === null) {
      // Try once more to obtain it — the initial read may have
      // failed before the audio service was fully available.
      SystemFeedbackHelper.refreshRingerMode();
      if (SystemFeedbackHelper.volumeGroupManager === null) {
        return;
      }
    }

    try {
      SystemFeedbackHelper.volumeGroupManager!.on(
        'ringerModeChange',
        (mode: audio.AudioRingMode) => {
          const soundAllowed = (mode === audio.AudioRingMode.RINGER_MODE_NORMAL);
          AppStorage.setOrCreate(STORAGE_KEY_SYSTEM_SOUND_ENABLED, soundAllowed);
          console.info(
            `[SystemFeedbackHelper] ringerModeChange → ${mode}, soundAllowed = ${soundAllowed}`
          );
        }
      );
      SystemFeedbackHelper.ringerObserverRegistered = true;
    } catch (err) {
      const e = err as BusinessError;
      AppLogger.warn(
        'SystemFeedbackHelper',
        `ringer observer registration failed: ${e.code} ${e.message}`
      );
    }
  }
}