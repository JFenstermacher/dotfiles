export interface XdgVars {
  XDG_CONFIG_HOME: string;
  XDG_CACHE_HOME: string;
  XDG_DATA_HOME: string;
  XDG_STATE_HOME: string;
  XDG_RUNTIME_DIR: string | undefined;
  XDG_CONFIG_DIRS: string[];
  XDG_DATA_DIRS: string[];
}

/**
 * Resolve a single XDG environment variable with its default fallback.
 *
 * @param varName - The environment variable name (e.g. "XDG_CONFIG_HOME")
 * @param defaultPath - The fallback path relative to `$HOME`
 * @returns The resolved absolute path
 */
function resolveHomeVar(varName: string, defaultPath: string): string {
  const home = process.env.HOME;
  if (!home) {
    throw new Error("$HOME is not set — cannot resolve XDG base directories");
  }
  const value = process.env[varName];
  return value ?? `${home}/${defaultPath}`;
}

/**
 * Resolve an XDG path variable that is a colon-separated list (e.g. XDG_DATA_DIRS).
 *
 * @param varName - The environment variable name
 * @param defaults - The default colon-separated string
 * @returns Array of paths, in order
 */
function resolveListVar(varName: string, defaults: string): string[] {
  const raw = process.env[varName] ?? defaults;
  return raw.split(":").filter(Boolean);
}

// ─── Single path variables ────────────────────────────────────────────────

/**
 * Base directory relative to which user-specific configuration files should be stored.
 * Defaults to `$HOME/.config`.
 */
export const XDG_CONFIG_HOME: string = resolveHomeVar("XDG_CONFIG_HOME", ".config");

/**
 * Base directory relative to which user-specific non-essential (cached) data should be stored.
 * Defaults to `$HOME/.cache`.
 */
export const XDG_CACHE_HOME: string = resolveHomeVar("XDG_CACHE_HOME", ".cache");

/**
 * Base directory relative to which user-specific data files should be stored.
 * Defaults to `$HOME/.local/share`.
 */
export const XDG_DATA_HOME: string = resolveHomeVar("XDG_DATA_HOME", ".local/share");

/**
 * Base directory relative to which user-specific state files should be stored.
 * Defaults to `$HOME/.local/state`.
 *
 * @see https://specifications.freedesktop.org/basedir-spec/latest/
 */
export const XDG_STATE_HOME: string = resolveHomeVar("XDG_STATE_HOME", ".local/state");

/**
 * Base directory relative to which user-specific runtime files and other file objects
 * should be placed. May be `undefined` if neither the environment variable is set
 * nor a suitable default can be determined.
 *
 * Falls back to `/run/user/<uid>` when available on Unix-like systems,
 * or to `$TMPDIR` on macOS.
 */
export const XDG_RUNTIME_DIR: string | undefined = (() => {
  const env = process.env.XDG_RUNTIME_DIR;
  if (env) return env;

  // Linux: /run/user/<uid>
  if (process.platform === "linux") {
    const uid = process.getuid?.();
    if (uid !== undefined) return `/run/user/${uid}`;
  }

  // macOS: use $TMPDIR as a reasonable fallback
  if (process.platform === "darwin") {
    return process.env.TMPDIR ?? `/tmp`;
  }

  return undefined;
})();

// ─── List path variables ───────────────────────────────────────────────────

/**
 * Colon-separated set of base directories to search for configuration files.
 * Defaults to `/etc/xdg`.
 */
export const XDG_CONFIG_DIRS: string[] = resolveListVar("XDG_CONFIG_DIRS", "/etc/xdg");

/**
 * Colon-separated set of base directories to search for data files.
 * Defaults to `/usr/local/share:/usr/share`.
 */
export const XDG_DATA_DIRS: string[] = resolveListVar(
  "XDG_DATA_DIRS",
  "/usr/local/share:/usr/share",
);

// ─── Convenience helpers ───────────────────────────────────────────────────

/**
 * Resolve `path` relative to `XDG_CONFIG_HOME`.
 *
 * @param segments - Path segments to join
 * @returns Joined path
 *
 * @example xdgConfig("nvim")       // ~/.config/nvim
 * @example xdgConfig("git/config") // ~/.config/git/config
 */
export function xdgConfig(...segments: string[]): string {
  return join(XDG_CONFIG_HOME, ...segments);
}

/**
 * Resolve `path` relative to `XDG_CACHE_HOME`.
 *
 * @param segments - Path segments to join
 * @returns Joined path
 *
 * @example xdgCache("pnpm")        // ~/.cache/pnpm
 */
export function xdgCache(...segments: string[]): string {
  return join(XDG_CACHE_HOME, ...segments);
}

/**
 * Resolve `path` relative to `XDG_DATA_HOME`.
 *
 * @param segments - Path segments to join
 * @returns Joined path
 *
 * @example xdgData("nvim/site")    // ~/.local/share/nvim/site
 */
export function xdgData(...segments: string[]): string {
  return join(XDG_DATA_HOME, ...segments);
}

/**
 * Resolve `path` relative to `XDG_STATE_HOME`.
 *
 * @param segments - Path segments to join
 * @returns Joined path
 *
 * @example xdgState("zsh")         // ~/.local/state/zsh
 */
export function xdgState(...segments: string[]): string {
  return join(XDG_STATE_HOME, ...segments);
}

/**
 * Returns a plain object with all resolved XDG variables.
 * @returns All resolved XDG variables
 */
export function getXdgVars(): XdgVars {
  return {
    XDG_CONFIG_HOME,
    XDG_CACHE_HOME,
    XDG_DATA_HOME,
    XDG_STATE_HOME,
    XDG_RUNTIME_DIR,
    XDG_CONFIG_DIRS,
    XDG_DATA_DIRS,
  };
}

// ─── Internal helpers ──────────────────────────────────────────────────────

/**
 * Simple path-join that normalises slashes. Avoids pulling in Node `path` so
 * this module stays usable in edge runtimes (Deno, Bun, etc.) without shims.
 *
 * @param segments - Path segments to join
 * @returns Normalised joined path
 */
function join(...segments: string[]): string {
  return segments
    .filter((s) => s.length > 0)
    .join("/")
    .replace(/\/+/g, "/")
    .replace(/\/$/, "");
}
