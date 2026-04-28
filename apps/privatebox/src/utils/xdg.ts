import { mkdirSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

function home(): string {
  return homedir();
}

function getEnv(key: string, fallback: string): string {
  const value = process.env[key];
  return value && value.length > 0 ? value : fallback;
}

function ensureDir(path: string): string {
  mkdirSync(path, { recursive: true });
  return path;
}

// ── Base XDG directories ────────────────────────────────────────────────────

export function xdgConfigHome(): string {
  return getEnv("XDG_CONFIG_HOME", join(home(), ".config"));
}

export function xdgDataHome(): string {
  return getEnv("XDG_DATA_HOME", join(home(), ".local", "share"));
}

export function xdgCacheHome(): string {
  return getEnv("XDG_CACHE_HOME", join(home(), ".cache"));
}

// ── PrivateBox sub-paths ────────────────────────────────────────────────────

export function configDir(): string {
  return ensureDir(join(xdgConfigHome(), "privatebox"));
}

export function configsDir(): string {
  return ensureDir(join(configDir(), "configs"));
}

export function configPath(name: string): string {
  return join(configsDir(), `${name}.yml`);
}

export function dataDir(): string {
  return ensureDir(join(xdgDataHome(), "privatebox"));
}

export function stackDirPath(name: string): string {
  return join(dataDir(), "stacks", name);
}

export function stackDir(name: string): string {
  return ensureDir(stackDirPath(name));
}

export function pulumiBackendDir(): string {
  return ensureDir(join(dataDir(), "pulumi-state"));
}

export function keyDir(name: string): string {
  return ensureDir(join(dataDir(), "keys", name));
}

export function cacheDir(): string {
  return ensureDir(join(xdgCacheHome(), "privatebox"));
}
