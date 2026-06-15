import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { Result, TaggedError } from "better-result";

const execFileAsync = promisify(execFile);

export const TmuxError = TaggedError("TmuxError")<{
  message: string;
  command: string;
  cause?: unknown;
}>();

export type TmuxResult<T> = Result<T, InstanceType<typeof TmuxError>>;

// ─── Internal helpers ──────────────────────────────────────────────────────

async function runTmuxVoid(args: string[]): Promise<void> {
  await execFileAsync("tmux", args);
}

async function runTmuxOutput(args: string[]): Promise<string> {
  const { stdout } = await execFileAsync("tmux", args);
  return stdout.toString();
}

// ─── startServer ───────────────────────────────────────────────────────────

/**
 * Start the tmux server if it is not already running.
 *
 * This is a no-op when the server is already active.
 *
 * @returns `Ok(void)` on success, `Err(TmuxError)` on failure.
 */
export async function startServer(): Promise<TmuxResult<void>> {
  const args = ["start-server"];

  return Result.tryPromise({
    try: () => runTmuxVoid(args),
    catch: (cause) =>
      new TmuxError({
        message: "Failed to start tmux server",
        command: `tmux ${args.join(" ")}`,
        cause,
      }),
  });
}

// ─── hasSession ────────────────────────────────────────────────────────────

export interface HasSessionOptions {
  /** Name of the tmux session */
  session: string;
}

/**
 * Check whether a tmux session exists.
 *
 * @returns `Ok(true)` if the session exists, `Ok(false)` if it does not,
 *          or `Err(TmuxError)` when the tmux command itself fails.
 */
export async function hasSession(
  opts: HasSessionOptions,
): Promise<TmuxResult<boolean>> {
  const args = ["has-session", "-t", opts.session];

  try {
    await runTmuxVoid(args);
    return Result.ok(true);
  } catch (err: unknown) {
    const stderr =
      err && typeof err === "object" && "stderr" in err
        ? String((err as Record<string, unknown>).stderr)
        : "";

    if (
      typeof err === "object" &&
      err !== null &&
      "code" in err &&
      (err as { code: unknown }).code === 1 &&
      /(not found|does not exist|can't find session|no server running)/i.test(stderr)
    ) {
      return Result.ok(false);
    }

    return Result.err(
      new TmuxError({
        message: `Failed to check session ${opts.session}`,
        command: `tmux ${args.join(" ")}`,
        cause: err,
      }),
    );
  }
}

// ─── listSessions ────────────────────────────────────────────────────────────

/**
 * List all tmux session names.
 *
 * @returns `Ok(string[])` with session names, or an empty array when no
 *          tmux server is running.
 */
export async function listSessions(): Promise<TmuxResult<string[]>> {
  const args = ["list-sessions", "-F", "#{session_name}"];

  try {
    const stdout = await runTmuxOutput(args);
    return Result.ok(stdout.split("\n").filter((line) => line.length > 0));
  } catch (err: unknown) {
    const stderr =
      err && typeof err === "object" && "stderr" in err
        ? String((err as Record<string, unknown>).stderr)
        : "";

    if (
      typeof err === "object" &&
      err !== null &&
      "code" in err &&
      (err as { code: unknown }).code === 1 &&
      /no server running/i.test(stderr)
    ) {
      return Result.ok([]);
    }

    return Result.err(
      new TmuxError({
        message: "Failed to list sessions",
        command: `tmux ${args.join(" ")}`,
        cause: err,
      }),
    );
  }
}

// ─── switchClient ──────────────────────────────────────────────────────────

export interface SwitchClientOptions {
  /** Name of the tmux session to switch to */
  session: string;
}

/**
 * Switch the current tmux client to the given session.
 *
 * @returns `Ok(void)` on success, `Err(TmuxError)` on failure.
 */
export async function switchClient(
  opts: SwitchClientOptions,
): Promise<TmuxResult<void>> {
  const args = ["switch-client", "-t", opts.session];

  return Result.tryPromise({
    try: () => runTmuxVoid(args),
    catch: (cause) =>
      new TmuxError({
        message: `Failed to switch client to session ${opts.session}`,
        command: `tmux ${args.join(" ")}`,
        cause,
      }),
  });
}

// ─── sendKeys ──────────────────────────────────────────────────────────────

export interface SendKeysOptions {
  /** Target pane in tmux notation (e.g. `mysession:0.0`) */
  target: string;
  /** Keys to send (e.g. `["echo hello", "Enter"]`) */
  keys: string[];
}

/**
 * Send keystrokes to a tmux pane.
 *
 * @example
 * sendKeys({ target: "my-session:0.0", keys: ["echo hello", "Enter"] })
 *
 * @returns `Ok(void)` on success, `Err(TmuxError)` on failure.
 */
export async function sendKeys(
  opts: SendKeysOptions,
): Promise<TmuxResult<void>> {
  const args = ["send-keys", "-t", opts.target, ...opts.keys];

  return Result.tryPromise({
    try: () => runTmuxVoid(args),
    catch: (cause) =>
      new TmuxError({
        message: `Failed to send keys to ${opts.target}`,
        command: `tmux ${args.join(" ")}`,
        cause,
      }),
  });
}

// ─── killSession ───────────────────────────────────────────────────────────

export interface KillSessionOptions {
  /** Name of the tmux session to kill */
  session: string;
}

/**
 * Kill a tmux session.
 *
 * @returns `Ok(void)` on success, `Err(TmuxError)` on failure.
 */
export async function killSession(
  opts: KillSessionOptions,
): Promise<TmuxResult<void>> {
  const args = ["kill-session", "-t", opts.session];

  return Result.tryPromise({
    try: () => runTmuxVoid(args),
    catch: (cause) =>
      new TmuxError({
        message: `Failed to kill session ${opts.session}`,
        command: `tmux ${args.join(" ")}`,
        cause,
      }),
  });
}

// ─── newSession ──────────────────────────────────────────────────────────────

export interface NewSessionOptions {
  /** Name of the new session */
  sessionName: string;
  /** Working directory for the new session */
  path?: string;
  /** Name of the first window */
  windowName?: string;
  /** Create the session detached (default: true) */
  detached?: boolean;
  /** Command to run in the first window */
  command?: string;
}

/**
 * Create a new tmux session.
 *
 * @param opts.sessionName – required session name
 * @param opts.path        – optional working directory
 * @param opts.windowName  – optional first-window name
 * @param opts.detached    – create without attaching (default true)
 * @param opts.command     – optional command to run in the first window
 *
 * @returns `Ok(void)` on success, `Err(TmuxError)` on failure.
 */
export async function newSession(
  opts: NewSessionOptions,
): Promise<TmuxResult<void>> {
  const args = [
    "new-session",
    ...(opts.detached !== false ? ["-d"] : []),
    "-s",
    opts.sessionName,
    ...(opts.path ? ["-c", opts.path] : []),
    ...(opts.windowName ? ["-n", opts.windowName] : []),
    ...(opts.command ? [opts.command] : []),
  ];

  return Result.tryPromise({
    try: () => runTmuxVoid(args),
    catch: (cause) =>
      new TmuxError({
        message: `Failed to create session ${opts.sessionName}`,
        command: `tmux ${args.join(" ")}`,
        cause,
      }),
  });
}

// ─── newWindow ─────────────────────────────────────────────────────────────

export interface NewWindowOptions {
  /** Target session (or full target like `session:window`) */
  target?: string;
  /** Name for the new window */
  name?: string;
  /** Command to run in the new window */
  command?: string;
}

/**
 * Create a new tmux window.
 *
 * @param opts.target  – optional target session (default: current session)
 * @param opts.name    – optional window name
 * @param opts.command – optional command to run in the window
 *
 * @returns `Ok(void)` on success, `Err(TmuxError)` on failure.
 */
export async function newWindow(
  opts: NewWindowOptions,
): Promise<TmuxResult<void>> {
  const args = [
    "new-window",
    ...(opts.target ? ["-t", opts.target] : []),
    ...(opts.name ? ["-n", opts.name] : []),
    ...(opts.command ? [opts.command] : []),
  ];

  return Result.tryPromise({
    try: () => runTmuxVoid(args),
    catch: (cause) =>
      new TmuxError({
        message: "Failed to create new window",
        command: `tmux ${args.join(" ")}`,
        cause,
      }),
  });
}
