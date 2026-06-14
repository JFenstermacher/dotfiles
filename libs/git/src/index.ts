import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { Result, TaggedError } from "better-result";

const execFileAsync = promisify(execFile);

const GitError = TaggedError("GitError")<{
  message: string;
  command: string;
  cwd?: string;
  cause?: unknown;
}>();

type GitResult<T> = Result<T, InstanceType<typeof GitError>>;

// ─── Internal helpers ──────────────────────────────────────────────────────

async function runGitVoid(
  args: string[],
  cwd?: string,
): Promise<void> {
  await execFileAsync("git", args, cwd ? { cwd } : undefined);
}

async function runGitOutput(
  args: string[],
  cwd?: string,
): Promise<string> {
  const { stdout } = await execFileAsync("git", args, cwd ? { cwd } : undefined);
  return stdout.toString();
}

// ─── clone ───────────────────────────────────────────────────────────────────

export interface CloneOptions {
  /** Full repo slug in the form `{owner}/{repo_name}` */
  repoSlug: string;
  /** Whether to create a bare checkout */
  bare?: boolean;
  /** Directory path where the repo should be written */
  path: string;
  /** Base URL for the git remote (default: `https://github.com/`) */
  baseUrl?: string;
}

/**
 * Clone a repository from a remote.
 *
 * @param opts.repoSlug – `{owner}/{repo_name}`
 * @param opts.bare     – bare checkout
 * @param opts.path     – local destination
 * @param opts.baseUrl  – remote base URL
 *
 * @returns `Ok(void)` on success, `Err(GitError)` on failure.
 */
export async function clone(opts: CloneOptions): Promise<GitResult<void>> {
  const parts = opts.repoSlug.split("/");
  if (parts.length !== 2 || !parts[0] || !parts[1]) {
    return Result.err(
      new GitError({
        message: `Invalid repoSlug "${opts.repoSlug}" (expected {owner}/{repo_name})`,
        command: "clone",
      }),
    );
  }

  const url = `${opts.baseUrl ?? "https://github.com/"}${opts.repoSlug}.git`;
  const args = ["clone", ...(opts.bare ? ["--bare"] : []), url, opts.path];

  return Result.tryPromise({
    try: () => runGitVoid(args),
    catch: (cause) =>
      new GitError({
        message: `Failed to clone ${opts.repoSlug}`,
        command: `git ${args.join(" ")}`,
        cause,
      }),
  });
}

// ─── fetch ───────────────────────────────────────────────────────────────────

export interface FetchOptions {
  /** Directory of the git repository */
  cwd: string;
  /** Specific branch or tag to fetch */
  branchOrTag?: string;
  /** Fetch all remotes (`--all`) */
  all?: boolean;
}

/**
 * Fetch refs from the remote.
 *
 * @param opts.cwd         – working directory (git repo)
 * @param opts.branchOrTag – optional specific ref
 * @param opts.all         – fetch every remote
 *
 * @returns `Ok(void)` on success, `Err(GitError)` on failure.
 */
export async function fetch(opts: FetchOptions): Promise<GitResult<void>> {
  if (opts.all && opts.branchOrTag) {
    return Result.err(
      new GitError({
        message: "Cannot use both `all` and `branchOrTag`",
        command: "fetch",
        cwd: opts.cwd,
      }),
    );
  }

  const args = ["fetch"];
  if (opts.all) {
    args.push("--all");
  } else if (opts.branchOrTag) {
    args.push("origin", opts.branchOrTag);
  }

  return Result.tryPromise({
    try: () => runGitVoid(args, opts.cwd),
    catch: (cause) =>
      new GitError({
        message: "Failed to fetch",
        command: `git ${args.join(" ")}`,
        cwd: opts.cwd,
        cause,
      }),
  });
}

// ─── repo ──────────────────────────────────────────────────────────────────

/**
 * Check whether a directory is inside a git repository.
 *
 * @returns `Ok(true)` if it is a repo, `Ok(false)` if it is not, or
 *          `Err(GitError)` when the git command itself fails.
 */
export async function isRepo(cwd: string): Promise<GitResult<boolean>> {
  const args = ["rev-parse", "--git-dir"];

  try {
    await runGitOutput(args, cwd);
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
      (err as { code: unknown }).code === 128 &&
      /not a git repository/i.test(stderr)
    ) {
      return Result.ok(false);
    }

    return Result.err(
      new GitError({
        message: "Failed to check if directory is a git repository",
        command: `git ${args.join(" ")}`,
        cwd,
        cause: err,
      }),
    );
  }
}

/**
 * Check whether a git repository is bare.
 *
 * @returns `Ok(true)` if bare, `Ok(false)` if not, or `Err(GitError)` on
 *          failure (e.g. directory is not a repo).
 */
export async function isBareRepo(cwd: string): Promise<GitResult<boolean>> {
  const args = ["rev-parse", "--is-bare-repository"];

  return Result.tryPromise({
    try: async () => {
      const stdout = await runGitOutput(args, cwd);
      return stdout.trim() === "true";
    },
    catch: (cause) =>
      new GitError({
        message: "Failed to check if repo is bare",
        command: `git ${args.join(" ")}`,
        cwd,
        cause,
      }),
  });
}

/**
 * Get the name of the currently checked-out branch.
 *
 * @returns `Ok(branch)` on success, `Ok(undefined)` when HEAD is detached,
 *          or `Err(GitError)` on failure.
 */
export async function currentBranch(
  cwd: string,
): Promise<GitResult<string | undefined>> {
  const args = ["rev-parse", "--abbrev-ref", "HEAD"];

  return Result.tryPromise({
    try: async () => {
      const stdout = await runGitOutput(args, cwd);
      const branch = stdout.trim();
      return branch === "HEAD" ? undefined : branch;
    },
    catch: (cause) =>
      new GitError({
        message: "Failed to get current branch",
        command: `git ${args.join(" ")}`,
        cwd,
        cause,
      }),
  });
}

/**
 * Check whether a branch has a remote tracking branch configured.
 *
 * @returns `Ok(true)` if an upstream exists, `Ok(false)` if not, or
 *          `Err(GitError)` when the git command itself fails.
 */
export async function hasRemoteTrackingBranch(
  cwd: string,
  branch: string,
): Promise<GitResult<boolean>> {
  const args = [
    "rev-parse",
    "--abbrev-ref",
    "--symbolic-full-name",
    `${branch}@{upstream}`,
  ];

  try {
    await runGitOutput(args, cwd);
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
      (err as { code: unknown }).code === 128 &&
      /(does not point to a branch|no upstream configured|invalid upstream)/i.test(
        stderr,
      )
    ) {
      return Result.ok(false);
    }

    return Result.err(
      new GitError({
        message: `Failed to check remote tracking for ${branch}`,
        command: `git ${args.join(" ")}`,
        cwd,
        cause: err,
      }),
    );
  }
}

// ─── worktree ──────────────────────────────────────────────────────────────

export interface WorktreeCreateOptions {
  /** Directory of the git repository */
  cwd: string;
  /** Branch to check out in the new worktree */
  branch: string;
  /** Path for the new worktree */
  path: string;
}

/**
 * Create a new worktree.
 *
 * @returns `Ok(void)` on success, `Err(GitError)` on failure.
 */
export async function worktreeCreate(
  opts: WorktreeCreateOptions,
): Promise<GitResult<void>> {
  const args = ["worktree", "add", opts.path, opts.branch];

  return Result.tryPromise({
    try: () => runGitVoid(args, opts.cwd),
    catch: (cause) =>
      new GitError({
        message: `Failed to create worktree at ${opts.path}`,
        command: `git ${args.join(" ")}`,
        cwd: opts.cwd,
        cause,
      }),
  });
}

export interface WorktreeEntry {
  /** Absolute path of the worktree */
  path: string;
  /** Current HEAD commit */
  head: string;
  /** Checked-out branch (omitted when detached) */
  branch?: string;
  /** Whether HEAD is detached */
  detached: boolean;
}

export interface WorktreeListOptions {
  /** Directory of the git repository */
  cwd: string;
}

/**
 * List all worktrees for the repository.
 *
 * @returns `Ok(WorktreeEntry[])` on success, `Err(GitError)` on failure.
 */
export async function worktreeList(
  opts: WorktreeListOptions,
): Promise<GitResult<WorktreeEntry[]>> {
  const args = ["worktree", "list", "--porcelain"];

  return Result.tryPromise({
    try: async () => {
      const stdout = await runGitOutput(args, opts.cwd);
      return parseWorktreeList(stdout);
    },
    catch: (cause) =>
      new GitError({
        message: "Failed to list worktrees",
        command: `git ${args.join(" ")}`,
        cwd: opts.cwd,
        cause,
      }),
  });
}

function parseWorktreeList(output: string): WorktreeEntry[] {
  const entries: WorktreeEntry[] = [];
  const blocks = output.split("\n\n").filter((b) => b.trim().length > 0);

  for (const block of blocks) {
    const lines = block.split("\n");
    const entry: Partial<WorktreeEntry> = { detached: false };

    for (const line of lines) {
      const [key, ...rest] = line.split(" ");
      const value = rest.join(" ");

      if (key === "worktree") entry.path = value;
      else if (key === "HEAD") entry.head = value;
      else if (key === "branch")
        entry.branch = value.replace("refs/heads/", "");
      else if (key === "detached") entry.detached = true;
    }

    if (entry.path && entry.head) {
      entries.push(entry as WorktreeEntry);
    }
  }

  return entries;
}

export interface WorktreeDeleteOptions {
  /** Directory of the git repository */
  cwd: string;
  /** Path of the worktree to remove */
  path: string;
  /** Force removal even if dirty or has untracked files */
  force?: boolean;
}

/**
 * Remove a worktree.
 *
 * @returns `Ok(void)` on success, `Err(GitError)` on failure.
 */
export async function worktreeDelete(
  opts: WorktreeDeleteOptions,
): Promise<GitResult<void>> {
  const args = [
    "worktree",
    "remove",
    ...(opts.force ? ["--force"] : []),
    opts.path,
  ];

  return Result.tryPromise({
    try: () => runGitVoid(args, opts.cwd),
    catch: (cause) =>
      new GitError({
        message: `Failed to delete worktree at ${opts.path}`,
        command: `git ${args.join(" ")}`,
        cwd: opts.cwd,
        cause,
      }),
  });
}

// ─── switch ──────────────────────────────────────────────────────────────────

export interface SwitchOptions {
  /** Directory of the git repository */
  cwd: string;
  /** Branch to switch to */
  branch: string;
  /** Create the branch if it doesn't exist */
  create?: boolean;
}

/**
 * Switch to a branch.
 *
 * @returns `Ok(void)` on success, `Err(GitError)` on failure.
 */
export async function switchBranch(
  opts: SwitchOptions,
): Promise<GitResult<void>> {
  const args = ["switch", ...(opts.create ? ["-c"] : []), opts.branch];

  return Result.tryPromise({
    try: () => runGitVoid(args, opts.cwd),
    catch: (cause) =>
      new GitError({
        message: `Failed to switch to branch ${opts.branch}`,
        command: `git ${args.join(" ")}`,
        cwd: opts.cwd,
        cause,
      }),
  });
}

// ─── branch ──────────────────────────────────────────────────────────────────

export interface BranchCreateOptions {
  /** Directory of the git repository */
  cwd: string;
  /** Name of the new branch */
  name: string;
  /** Starting point (commit or branch) */
  startPoint?: string;
}

/**
 * Create a new branch.
 *
 * @returns `Ok(void)` on success, `Err(GitError)` on failure.
 */
export async function branchCreate(
  opts: BranchCreateOptions,
): Promise<GitResult<void>> {
  const args = ["branch", opts.name, ...(opts.startPoint ? [opts.startPoint] : [])];

  return Result.tryPromise({
    try: () => runGitVoid(args, opts.cwd),
    catch: (cause) =>
      new GitError({
        message: `Failed to create branch ${opts.name}`,
        command: `git ${args.join(" ")}`,
        cwd: opts.cwd,
        cause,
      }),
  });
}

export interface BranchListOptions {
  /** Directory of the git repository */
  cwd: string;
  /** List remote branches */
  remote?: boolean;
}

/**
 * List branches.
 *
 * @returns `Ok(string[])` with branch names on success, `Err(GitError)` on failure.
 */
export async function branchList(
  opts: BranchListOptions,
): Promise<GitResult<string[]>> {
  const args = ["branch", opts.remote ? "-r" : "-l"];

  return Result.tryPromise({
    try: async () => {
      const stdout = await runGitOutput(args, opts.cwd);
      return stdout
        .split("\n")
        .map((l) => l.trim())
        .filter((l) => l.length > 0)
        .map((l) => l.replace(/^[\*+\s]+/, ""))
        .filter((l) => !l.includes("HEAD ->"));
    },
    catch: (cause) =>
      new GitError({
        message: "Failed to list branches",
        command: `git ${args.join(" ")}`,
        cwd: opts.cwd,
        cause,
      }),
  });
}

export interface BranchDeleteOptions {
  /** Directory of the git repository */
  cwd: string;
  /** Name of the branch to delete */
  name: string;
  /** Also delete the branch on the remote */
  remote?: boolean;
  /** Force delete (even if not merged) */
  force?: boolean;
}

/**
 * Delete a branch.
 *
 * @param opts.remote – pushes `git push origin --delete <name>`
 * @param opts.force  – uses `-D` locally instead of `-d`
 *
 * @returns `Ok(void)` on success, `Err(GitError)` on failure.
 */
export async function branchDelete(
  opts: BranchDeleteOptions,
): Promise<GitResult<void>> {
  if (opts.remote) {
    const args = ["push", "origin", "--delete", opts.name];
    return Result.tryPromise({
      try: () => runGitVoid(args, opts.cwd),
      catch: (cause) =>
        new GitError({
          message: `Failed to delete remote branch ${opts.name}`,
          command: `git ${args.join(" ")}`,
          cwd: opts.cwd,
          cause,
        }),
    });
  }

  const args = ["branch", opts.force ? "-D" : "-d", opts.name];
  return Result.tryPromise({
    try: () => runGitVoid(args, opts.cwd),
    catch: (cause) =>
      new GitError({
        message: `Failed to delete branch ${opts.name}`,
        command: `git ${args.join(" ")}`,
        cwd: opts.cwd,
        cause,
      }),
  });
}
