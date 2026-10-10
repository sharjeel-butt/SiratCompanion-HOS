// entry/src/main/ets/helper/AppLogger.ets

import { fileIo as fs, ReadOptions } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { buffer } from '@kit.ArkTS';

/** Maximum file size before the logger trims older entries. */
const MAX_FILE_BYTES = 200 * 1024; // 200 KB
/** When trimming, keep the most recent N bytes. */
const KEEP_BYTES = 100 * 1024; // 100 KB
/** Hard cap — anything above this is wiped on startup. */
const HARD_LIMIT_BYTES = 2 * 1024 * 1024; // 2 MB
/** Maximum bytes returned from readAll(). */
const MAX_READ_BYTES = 128 * 1024; // 128 KB

export class AppLogger {
  private static logPath: string = '';
  private static initialized: boolean = false;

  static init(context: common.UIAbilityContext): void {
    if (AppLogger.initialized) {
      return;
    }
    AppLogger.logPath = context.filesDir + '/sirat_log.txt';
    AppLogger.initialized = true;

    try {
      const stat = fs.statSync(AppLogger.logPath);
      if (stat.size > HARD_LIMIT_BYTES) {
        const file = fs.openSync(
          AppLogger.logPath,
          fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC
        );
        fs.closeSync(file);
      }
    } catch (err) {
      // File doesn't exist yet — normal on first launch.
    }

    AppLogger.info('AppLogger', `Log file at ${AppLogger.logPath}`);
  }

  static getPath(): string {
    return AppLogger.logPath;
  }

  static info(tag: string, message: string): void {
    AppLogger.write('INFO', tag, message);
  }

  static warn(tag: string, message: string): void {
    AppLogger.write('WARN', tag, message);
  }

  static error(tag: string, message: string): void {
    AppLogger.write('ERROR', tag, message);
  }

  static readAll(): string {
    try {
      if (!AppLogger.initialized || AppLogger.logPath.length === 0) {
        return '(logger not initialized)';
      }
      const stat = fs.statSync(AppLogger.logPath);
      if (stat.size === 0) {
        return '(log is empty)';
      }

      const readSize = Math.min(stat.size, MAX_READ_BYTES);
      const filePos = stat.size > MAX_READ_BYTES
        ? stat.size - MAX_READ_BYTES
        : 0;

      const file = fs.openSync(AppLogger.logPath, fs.OpenMode.READ_ONLY);
      const buf = new ArrayBuffer(readSize);
      const readOptions: ReadOptions = {
        offset: filePos,
        length: readSize
      };
      const bytesRead = fs.readSync(file.fd, buf, readOptions);
      fs.closeSync(file);

      const u8 = new Uint8Array(buf, 0, bytesRead);
      let text = buffer.from(u8).toString('utf8');

      if (filePos > 0) {
        const nl = text.indexOf('\n');
        if (nl >= 0 && nl < text.length - 1) {
          text = '... (earlier entries trimmed)\n'
            + text.substring(nl + 1);
        }
      }
      return text;
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

  private static write(level: string, tag: string, message: string): void {
    const line = `[${AppLogger.timestamp()}] [${level}] [${tag}] ${message}`;
    console.info(line);

    if (!AppLogger.initialized || AppLogger.logPath.length === 0) {
      return;
    }

    try {
      const file = fs.openSync(
        AppLogger.logPath,
        fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.APPEND
      );
      fs.writeSync(file.fd, line + '\n');
      fs.closeSync(file);

      AppLogger.trimIfNeeded();
    } catch (err) {
      console.warn(`[AppLogger] write failed: ${JSON.stringify(err)}`);
    }
  }

  private static trimIfNeeded(): void {
    try {
      const stat = fs.statSync(AppLogger.logPath);
      if (stat.size <= MAX_FILE_BYTES) {
        return;
      }

      const startOffset = stat.size - KEEP_BYTES;
      const file = fs.openSync(AppLogger.logPath, fs.OpenMode.READ_ONLY);
      const buf = new ArrayBuffer(KEEP_BYTES);
      const readOptions: ReadOptions = {
        offset: startOffset,
        length: KEEP_BYTES
      };
      const bytesRead = fs.readSync(file.fd, buf, readOptions);
      fs.closeSync(file);

      const u8 = new Uint8Array(buf, 0, bytesRead);
      let text = buffer.from(u8).toString('utf8');

      const firstNewline = text.indexOf('\n');
      if (firstNewline >= 0 && firstNewline < text.length - 1) {
        text = text.substring(firstNewline + 1);
      }

      const writeFile = fs.openSync(
        AppLogger.logPath,
        fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC
      );
      fs.writeSync(
        writeFile.fd,
        `--- log trimmed at ${AppLogger.timestamp()} ---\n${text}`
      );
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
}