// entry/src/main/ets/helper/AppLogger.ets

import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { buffer } from '@kit.ArkTS';

/** Maximum file size before the logger trims older entries. */
const MAX_FILE_BYTES = 200 * 1024; // 200 KB
/** When trimming, keep the most recent N bytes. */
const KEEP_BYTES = 100 * 1024; // 100 KB

/**
 * Device-side logger for Sirat Companion.
 *
 * Writes to `<filesDir>/sirat_log.txt` — a path inside the app's
 * sandbox that is:
 *   • visible to the app itself (read back for the in-app log viewer)
 *   • visible to DevEco Studio's Device File Explorer
 *   • not accessible to other apps
 *
 * No permissions required.
 */
export class AppLogger {
  private static logPath: string = '';
  private static initialized: boolean = false;

  /** Call once at app startup with the UIAbility context. */
  static init(context: common.UIAbilityContext): void {
    if (AppLogger.initialized) {
      return;
    }
    AppLogger.logPath = context.filesDir + '/sirat_log.txt';
    AppLogger.initialized = true;
    AppLogger.info('AppLogger', `Log file at ${AppLogger.logPath}`);
  }

  static getPath(): string {
    return AppLogger.logPath;
  }

  // ============================================================
  // LOG LEVELS
  // ============================================================

  static info(tag: string, message: string): void {
    AppLogger.write('INFO', tag, message);
  }

  static warn(tag: string, message: string): void {
    AppLogger.write('WARN', tag, message);
  }

  static error(tag: string, message: string): void {
    AppLogger.write('ERROR', tag, message);
  }

  // ============================================================
  // INTERNAL WRITE
  // ============================================================

  private static write(level: string, tag: string, message: string): void {
    // Always mirror to console for DevEco logs.
    const line = `[${AppLogger.timestamp()}] [${level}] [${tag}] ${message}`;
    console.info(line);

    if (!AppLogger.initialized || AppLogger.logPath.length === 0) {
      return;
    }

    try {
      // Ensure the file exists, then append.
      const file = fs.openSync(
        AppLogger.logPath,
        fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.APPEND
      );
      fs.writeSync(file.fd, line + '\n');
      fs.closeSync(file);

      // Trim if the file has grown too large.
      AppLogger.trimIfNeeded();
    } catch (err) {
      // Never let logging failures break the app.
      console.warn(`[AppLogger] write failed: ${JSON.stringify(err)}`);
    }
  }

  private static trimIfNeeded(): void {
    try {
      const stat = fs.statSync(AppLogger.logPath);
      if (stat.size <= MAX_FILE_BYTES) {
        return;
      }

      // Read the tail of the file and rewrite.
      const startOffset = stat.size - KEEP_BYTES;
      const file = fs.openSync(AppLogger.logPath, fs.OpenMode.READ_ONLY);
      const buf = new ArrayBuffer(KEEP_BYTES);
      fs.readSync(file.fd, buf, { offset: startOffset });
      fs.closeSync(file);

      // Drop any partial first line.
      let text = buffer.from(buf).toString('utf8');
      const firstNewline = text.indexOf('\n');
      if (firstNewline >= 0 && firstNewline < text.length - 1) {
        text = text.substring(firstNewline + 1);
      }

      const writeFile = fs.openSync(
        AppLogger.logPath,
        fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC
      );
      fs.writeSync(writeFile.fd, `--- log trimmed at ${AppLogger.timestamp()} ---\n${text}`);
      fs.closeSync(writeFile);
    } catch (err) {
      // Silently skip.
    }
  }

  private static timestamp(): string {
    const d = new Date();
    const pad = (n: number): string => n.toString().padStart(2, '0');
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ` +
      `${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
  }

  // ============================================================
  // READ / CLEAR
  // ============================================================

  static readAll(): string {
    if (!AppLogger.initialized || AppLogger.logPath.length === 0) {
      return '(logger not initialized)';
    }

    try {
      const stat = fs.statSync(AppLogger.logPath);
      if (stat.size === 0) {
        return '(log is empty)';
      }

      const file = fs.openSync(AppLogger.logPath, fs.OpenMode.READ_ONLY);
      const buf = new ArrayBuffer(stat.size);
      const bytesRead = fs.readSync(file.fd, buf);
      fs.closeSync(file);

      const u8 = new Uint8Array(buf, 0, bytesRead);
      return buffer.from(u8).toString('utf8');
    } catch (err) {
      return `(failed to read log: ${JSON.stringify(err)})`;
    }
  }

  static clear(): void {
    if (!AppLogger.initialized || AppLogger.logPath.length === 0) {
      return;
    }
    try {
      const file = fs.openSync(
        AppLogger.logPath,
        fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC
      );
      fs.closeSync(file);
      AppLogger.info('AppLogger', 'Log file cleared');
    } catch (err) {
      console.warn(`[AppLogger] clear failed: ${JSON.stringify(err)}`);
    }
  }
}