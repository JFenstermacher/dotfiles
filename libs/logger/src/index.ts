import { appendFile, access, rename, unlink, mkdir } from "node:fs/promises";
import { parse, join, dirname } from "node:path";

export const LogLevel = {
  TRACE: "TRACE",
  DEBUG: "DEBUG",
  INFO: "INFO",
  WARN: "WARN",
  ERROR: "ERROR",
} as const;

export type LogLevel = (typeof LogLevel)[keyof typeof LogLevel];

const LEVEL_ORDER: Record<LogLevel, number> = {
  TRACE: 0,
  DEBUG: 1,
  INFO: 2,
  WARN: 3,
  ERROR: 4,
};

export type LogAttrValue = string | number | boolean | null;

export type LogAttrs = Record<string, LogAttrValue>;

export type Config = {
  consoleEnabled: boolean;
  consoleLevel: LogLevel;
  fileEnabled: boolean;
  fileLevel: LogLevel;
  filePath: string;
};

export class Logger {
  private readonly config: Config;
  private entryCount = 0;
  private readonly maxEntries = 5;
  private readonly maxFiles = 5;

  constructor(config: Config) {
    this.config = config;
  }

  // ─── Public API ──────────────────────────────────────────────────────────

  trace(msg: string, attrs: LogAttrs = {}): void {
    this.log(LogLevel.TRACE, msg, attrs);
  }

  debug(msg: string, attrs: LogAttrs = {}): void {
    this.log(LogLevel.DEBUG, msg, attrs);
  }

  info(msg: string, attrs: LogAttrs = {}): void {
    this.log(LogLevel.INFO, msg, attrs);
  }

  setFilePath(filePath: string): void {
    this.config.filePath = filePath;
    this.entryCount = 0;
  }

  warn(msg: string, attrs: LogAttrs = {}): void {
    this.log(LogLevel.WARN, msg, attrs);
  }

  error(msg: string, attrs: LogAttrs = {}): void {
    this.log(LogLevel.ERROR, msg, attrs);
  }

  // ─── Internal ────────────────────────────────────────────────────────────

  private log(
    level: LogLevel,
    msg: string,
    attrs: LogAttrs,
  ): void {
    const levelOrder = LEVEL_ORDER[level];

    if (
      this.config.consoleEnabled &&
      levelOrder >= LEVEL_ORDER[this.config.consoleLevel]
    ) {
      this.writeConsole(level, msg, attrs);
    }

    if (
      this.config.fileEnabled &&
      levelOrder >= LEVEL_ORDER[this.config.fileLevel]
    ) {
      this.writeFile(level, msg, attrs).catch(() => {
        // Silently drop file write errors to avoid infinite loops
      });
    }
  }

  private writeConsole(
    level: LogLevel,
    msg: string,
    attrs: LogAttrs,
  ): void {
    const attrStr = Object.entries(attrs)
      .map(([k, v]) => `${k}=${v}`)
      .join(" ");

    const line = `[${level}] ${msg} ${attrStr}\n`;

    process.stderr.write(line);
  }

  private async writeFile(
    level: LogLevel,
    msg: string,
    attrs: LogAttrs,
  ): Promise<void> {
    await mkdir(dirname(this.config.filePath), { recursive: true });

    if (this.entryCount >= this.maxEntries) {
      await this.rotate();
    }

    const record = {
      level,
      timestamp: new Date().toISOString(),
      message: msg,
      attrs,
    };

    const line = JSON.stringify(record) + "\n";
    await appendFile(this.config.filePath, line, "utf-8");
    this.entryCount++;
  }

  private async rotate(): Promise<void> {
    const { dir, name, ext } = parse(this.config.filePath);

    // Delete the oldest rotated file if it exists
    const oldest = join(dir, `${name}.${this.maxFiles - 1}${ext}`);
    try {
      await access(oldest);
      await unlink(oldest);
    } catch {
      // Does not exist — safe to ignore
    }

    // Shift existing rotated files up by one
    for (let i = this.maxFiles - 2; i >= 1; i--) {
      const oldPath = join(dir, `${name}.${i}${ext}`);
      const newPath = join(dir, `${name}.${i + 1}${ext}`);
      try {
        await access(oldPath);
        await rename(oldPath, newPath);
      } catch {
        // Does not exist — safe to ignore
      }
    }

    // Rotate current file to .1
    const rotated = join(dir, `${name}.1${ext}`);
    try {
      await access(this.config.filePath);
      await rename(this.config.filePath, rotated);
    } catch {
      // Current file does not exist — safe to ignore
    }

    this.entryCount = 0;
  }
}
