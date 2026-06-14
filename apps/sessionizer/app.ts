import { Result, TaggedError } from "better-result";
import { readdir, access, rm, readFile } from "node:fs/promises";
import type { Dirent } from "node:fs"
import { execFile, spawn } from "node:child_process";
import {
  clone,
  isRepo,
  isBareRepo,
  currentBranch,
  worktreeList,
  worktreeCreate,
  worktreeDelete,
  hasRemoteTrackingBranch,
  branchCreate,
  branchList,
  branchDelete,
} from "@dotfiles/git";
import { schedule } from "node-cron";
import { listSessions, killSession, hasSession, newSession, switchClient, startServer } from "@dotfiles/tmux";
import { xdgState } from "@dotfiles/envs";
import type { Logger } from "@dotfiles/logger";
import type { Config } from "./config.ts";
import { edit, load } from "./config.ts";
import { State } from "./state.ts";
import type { Workspace } from "./workspaces.ts";
import { WORKSPACES_ROOT } from "./workspaces.ts";
import { listRepositories } from "./github.ts";

export const AppError = TaggedError("AppError")<{
  message: string;
  cause?: unknown;
}>();

export type Session = {
  name: string;
  workspace?: Workspace;
};

export type AppResult<T = void> = Result<T, InstanceType<typeof AppError>>;

// ─── Session naming helpers ────────────────────────────────────────────────

function isHomeSession(name: string): boolean {
  return name === process.env.USER;
}

function parseRepoSlug(
  name: string,
): { owner: string; repo: string; branch?: string } | undefined {
  if (isHomeSession(name)) return undefined;

  const [slug, branch] = name.split("@");
  const [owner, repo] = slug.split("/");

  if (!owner || !repo) return undefined;
  return branch ? { owner, repo, branch } : { owner, repo };
}

// ─── App class ─────────────────────────────────────────────────────────────

export class App {
  config: Config;
  state: State;
  logger: Logger;

  constructor(config: Config, state: State, logger: Logger) {
    this.config = config;
    this.state = state;
    this.logger = logger;
  }

  init(): { dbPath: string } {
    return this.state.init();
  }

  // ─── Actions ─────────────────────────────────────────────────────
  async listSessions(): Promise<Session[]> {
    this.logger.debug("listing sessions");
    return this.#buildSessions();
  }

  listWorkspaces(): string[] {
    const slugs = this.state.listWorkspaces();
    this.logger.debug("listing workspaces", {
      count: slugs.length,
    });
    return slugs;
  }

  showConfig(): string {
    this.logger.debug("showing config");
    return JSON.stringify(this.config, null, 2);
  }

  async editConfig(): Promise<AppResult> {
    this.logger.debug("opening config in editor");
    const result = await edit();
    if (Result.isError(result)) {
      this.logger.error("config edit failed", { error: result.error.message });
      return Result.err(
        new AppError({
          message: result.error.message,
          cause: result.error,
        }),
      );
    }
    const reloaded = await load();
    Object.assign(this.config, reloaded);
    this.logger.info("config updated and reloaded");
    return Result.ok(undefined);
  }

  showState(): string {
    this.logger.debug("showing state");
    return JSON.stringify(this.state.dump(), null, 2);
  }

  clearState(): void {
    this.logger.info("clearing state");
    this.state.clear();
  }

  async workspacesSync(opts: { mode: "all" | "local" | "remote" }): Promise<AppResult> {
    if (opts.mode === "local") {
      await this.#syncLocal();
      return Result.ok(undefined);
    }

    if (opts.mode === "remote") {
      return this.#syncRemote();
    }

    // mode === "all"
    await this.#syncLocal();
    return this.#syncRemote();
  }

  async #syncLocal(): Promise<void> {
    const root = WORKSPACES_ROOT;
    this.logger.info("workspaces local sync started", { root });

    const ownerDirs = await readdir(root, { withFileTypes: true })
      .catch(() => [] as Dirent[]);

    for (const ownerDir of ownerDirs) {
      if (!ownerDir.isDirectory()) continue;

      const owner = String(ownerDir.name);
      const ownerPath = `${root}/${owner}`;
      this.logger.debug("scanning owner", { owner });

      const repoDirs = await readdir(ownerPath, { withFileTypes: true })
        .catch(() => [] as Dirent[]);

      for (const repoDir of repoDirs) {
        if (!repoDir.isDirectory()) continue;

        const repo = String(repoDir.name);
        const repoPath = `${ownerPath}/${repo}`;
        const slug = `${owner}/${repo}`;
        this.logger.debug("found repo", { slug, path: repoPath });

        const bareResult = await isBareRepo(repoPath);
        if (Result.isError(bareResult)) {
          this.logger.warn("failed to check bare status", {
            slug,
            error: bareResult.error.message,
          });
          continue;
        }
        const isBare = bareResult.value;

        const existing = this.state.getWorkspace(slug);
        if (!existing) {
          this.logger.info("adding workspace", { slug, isBare });
          const workspace: Workspace = {
            path: repoPath,
            owner,
            repo,
            isCheckedOut: !isBare,
            isBareRepo: isBare,
            defaultBranch: await this.#resolveDefaultBranch(repoPath, isBare),
          };

          if (isBare) {
            workspace.worktrees = await this.#buildWorktrees(repoPath);
          } else {
            const branchResult = await currentBranch(repoPath);
            if (Result.isOk(branchResult)) {
              workspace.activeBranch = branchResult.value as string | undefined;
            }
          }

          this.state.insertWorkspace(workspace);
        } else if (existing.isBareRepo) {
          this.logger.debug("syncing worktrees", { slug });
          const current = await this.#buildWorktrees(repoPath);
          this.state.syncBranches(slug, current);
        }
      }
    }

    this.logger.info("workspaces local sync complete", {
      count: this.state.listWorkspaces().length,
    });
  }

  async #syncRemote(): Promise<AppResult> {
    const token = process.env.GITHUB_TOKEN;
    if (!token) {
      this.logger.error("GITHUB_TOKEN not set");
      return Result.err(
        new AppError({ message: "GITHUB_TOKEN environment variable is required for remote sync" }),
      );
    }

    this.logger.info("workspaces remote sync started", {
      owners: this.config.githubOwners.join(","),
    });

    for (const owner of this.config.githubOwners) {
      this.logger.debug("fetching repos", { owner });
      const result = await listRepositories(owner);
      if (Result.isError(result)) {
        this.logger.warn("failed to list repos", {
          owner,
          error: result.error.message,
        });
        continue;
      }

      for (const info of result.value) {
        const slug = info.slug;
        if (this.state.getWorkspace(slug)) {
          this.logger.debug("workspace already exists, skipping", { slug });
          continue;
        }

        const repoPath = `${WORKSPACES_ROOT}/${info.owner}/${info.name}`;
        const workspace: Workspace = {
          path: repoPath,
          owner: info.owner,
          repo: info.name,
          isCheckedOut: false,
          isBareRepo: false,
          defaultBranch: info.defaultBranch,
        };

        this.logger.info("adding remote workspace", { slug });
        this.state.insertWorkspace(workspace);
      }
    }

    this.logger.info("workspaces remote sync complete", {
      count: this.state.listWorkspaces().length,
    });

    return Result.ok(undefined);
  }

  async addWorkspace(repoSlug: string, opts?: { bare?: boolean }): Promise<AppResult> {
    const parts = repoSlug.split("/");
    if (parts.length !== 2 || !parts[0] || !parts[1]) {
      this.logger.error("invalid repo slug", { repoSlug });
      return Result.err(
        new AppError({ message: `Invalid repoSlug "${repoSlug}" (expected {owner}/{repo})` }),
      );
    }

    const [owner, repo] = parts;
    const repoPath = `${WORKSPACES_ROOT}/${owner}/${repo}`;
    const slug = `${owner}/${repo}`;

    const existing = this.state.getWorkspace(slug);
    if (existing) {
      this.logger.warn("workspace already exists", { slug });
      return Result.err(new AppError({ message: `Workspace ${slug} already exists` }));
    }

    try {
      await access(repoPath);
      this.logger.warn("directory already exists on disk", { path: repoPath });
      return Result.err(new AppError({ message: `Directory ${repoPath} already exists` }));
    } catch {
      // expected — directory does not exist
    }

    this.logger.info("cloning repo", { repoSlug, bare: opts?.bare ?? false });
    const result = await clone({ repoSlug, path: repoPath, bare: opts?.bare });
    if (Result.isError(result)) {
      this.logger.error("clone failed", { repoSlug, error: result.error.message });
      return Result.err(
        new AppError({
          message: `Failed to clone ${repoSlug}: ${result.error.message}`,
          cause: result.error,
        }),
      );
    }

    const bareResult = await isBareRepo(repoPath);
    if (Result.isError(bareResult)) {
      this.logger.error("failed to check bare status after clone", {
        repoSlug,
        error: bareResult.error.message,
      });
      return Result.err(
        new AppError({
          message: `Clone succeeded but failed to inspect repo: ${bareResult.error.message}`,
          cause: bareResult.error,
        }),
      );
    }
    const isBare = bareResult.value;

    const workspace: Workspace = {
      path: repoPath,
      owner,
      repo,
      isCheckedOut: !isBare,
      isBareRepo: isBare,
      defaultBranch: await this.#resolveDefaultBranch(repoPath, isBare),
    };

    if (isBare) {
      workspace.worktrees = await this.#buildWorktrees(repoPath);
    } else {
      const branchResult = await currentBranch(repoPath);
      if (Result.isOk(branchResult)) {
        workspace.activeBranch = branchResult.value as string | undefined;
      }
    }

    this.state.insertWorkspace(workspace);
    this.logger.info("workspace added", { slug, isBare });
    return Result.ok(undefined);
  }

  async removeWorkspace(repoSlug: string): Promise<AppResult> {
    const parts = repoSlug.split("/");
    if (parts.length !== 2 || !parts[0] || !parts[1]) {
      this.logger.error("invalid repo slug", { repoSlug });
      return Result.err(
        new AppError({ message: `Invalid repoSlug "${repoSlug}" (expected {owner}/{repo})` }),
      );
    }

    const slug = repoSlug;
    const workspace = this.state.getWorkspace(slug);
    if (!workspace) {
      this.logger.warn("workspace not found", { slug });
      return Result.err(new AppError({ message: `Workspace ${slug} not found` }));
    }

    const repoPath = workspace.path;

    // Kill tmux sessions matching prefix
    const sessionsResult = await listSessions();
    if (Result.isOk(sessionsResult)) {
      const sessions = sessionsResult.value;
      for (const sessionName of sessions) {
        if (sessionName === slug || sessionName.startsWith(`${slug}@`)) {
          this.logger.info("killing tmux session", { session: sessionName });
          const killResult = await killSession({ session: sessionName });
          if (Result.isError(killResult)) {
            this.logger.warn("failed to kill session", {
              session: sessionName,
              error: killResult.error.message,
            });
          }
        }
      }
    }

    // Delete directory
    this.logger.info("deleting workspace directory", { path: repoPath });
    await rm(repoPath, { recursive: true, force: true });

    // Remove from db (branches cascade via FK)
    this.state.removeWorkspace(slug);
    this.logger.info("workspace removed", { slug });
    return Result.ok(undefined);
  }

  async addWorktree(opts: { workspace: string; branch: string }): Promise<AppResult> {
    const slug = opts.workspace;
    const workspace = this.state.getWorkspace(slug);

    if (!workspace) {
      this.logger.error("workspace not found", { slug });
      return Result.err(new AppError({ message: `Workspace ${slug} not found` }));
    }

    if (!workspace.isBareRepo) {
      this.logger.error("workspace is not a bare checkout", { slug });
      return Result.err(
        new AppError({ message: `Workspace ${slug} is not a bare checkout` }),
      );
    }

    const branch = opts.branch;
    const worktreePath = `${workspace.path}/${branch}`;

    this.logger.info("adding worktree", { slug, branch, path: worktreePath });
    const result = await worktreeCreate({
      cwd: workspace.path,
      branch,
      path: worktreePath,
    });

    if (Result.isError(result)) {
      this.logger.error("worktree add failed", {
        slug,
        branch,
        error: result.error.message,
      });
      return Result.err(
        new AppError({
          message: `Failed to add worktree ${branch} to ${slug}: ${result.error.message}`,
          cause: result.error,
        }),
      );
    }

    const hasRemote = await hasRemoteTrackingBranch(workspace.path, branch);
    const entry = {
      name: branch,
      hasRemote: Result.isOk(hasRemote) ? (hasRemote.value as boolean) : false,
    };

    this.state.insertBranch(slug, entry);

    this.logger.info("worktree added", { slug, branch });
    return Result.ok(undefined);
  }

  async removeWorktree(opts: { workspace: string; branch: string }): Promise<AppResult> {
    const slug = opts.workspace;
    const workspace = this.state.getWorkspace(slug);

    if (!workspace) {
      this.logger.error("workspace not found", { slug });
      return Result.err(new AppError({ message: `Workspace ${slug} not found` }));
    }

    if (!workspace.isBareRepo) {
      this.logger.error("workspace is not a bare checkout", { slug });
      return Result.err(
        new AppError({ message: `Workspace ${slug} is not a bare checkout` }),
      );
    }

    const branch = opts.branch;
    const worktreePath = `${workspace.path}/${branch}`;

    const existing = this.state.listBranches(slug);
    const idx = existing.findIndex((e) => e.name === branch);
    if (idx === -1) {
      this.logger.warn("worktree not found", { slug, branch });
      return Result.err(
        new AppError({ message: `Worktree ${branch} not found in ${slug}` }),
      );
    }

    // Kill tmux sessions matching slug@branch
    const sessionName = `${slug}@${branch}`;
    this.logger.info("killing tmux session", { session: sessionName });
    const killResult = await killSession({ session: sessionName });
    if (Result.isError(killResult)) {
      this.logger.warn("failed to kill session", {
        session: sessionName,
        error: killResult.error.message,
      });
    }

    this.logger.info("removing worktree", { slug, branch, path: worktreePath });
    const result = await worktreeDelete({
      cwd: workspace.path,
      path: worktreePath,
    });

    if (Result.isError(result)) {
      this.logger.error("worktree remove failed", {
        slug,
        branch,
        error: result.error.message,
      });
      return Result.err(
        new AppError({
          message: `Failed to remove worktree ${branch} from ${slug}: ${result.error.message}`,
          cause: result.error,
        }),
      );
    }

    this.state.removeBranch(slug, branch);

    this.logger.info("worktree removed", { slug, branch });
    return Result.ok(undefined);
  }

  // ─── Branches ──────────────────────────────────────────────────────

  async createBranch(opts: {
    workspace: string;
    branch: string;
    startPoint?: string;
  }): Promise<AppResult> {
    const slug = opts.workspace;
    const workspace = this.state.getWorkspace(slug);

    if (!workspace) {
      this.logger.error("workspace not found", { slug });
      return Result.err(new AppError({ message: `Workspace ${slug} not found` }));
    }

    const branch = opts.branch;

    if (workspace.isBareRepo) {
      this.logger.info("creating worktree for bare repo", { slug, branch });
      return this.addWorktree({ workspace: slug, branch });
    }

    // Standard repo — create a local branch
    this.logger.info("creating branch", { slug, branch, startPoint: opts.startPoint ?? null });
    const result = await branchCreate({
      cwd: workspace.path,
      name: branch,
      startPoint: opts.startPoint,
    });

    if (Result.isError(result)) {
      this.logger.error("branch create failed", { slug, branch, error: result.error.message });
      return Result.err(
        new AppError({
          message: `Failed to create branch ${branch}: ${result.error.message}`,
          cause: result.error,
        }),
      );
    }

    const hasRemote = await hasRemoteTrackingBranch(workspace.path, branch);
    this.state.insertBranch(slug, {
      name: branch,
      hasRemote: Result.isOk(hasRemote) ? (hasRemote.value as boolean) : false,
    });

    this.logger.info("branch created", { slug, branch });
    return Result.ok(undefined);
  }

  async listBranches(opts: { workspace: string }): Promise<string[]> {
    const slug = opts.workspace;
    const workspace = this.state.getWorkspace(slug);

    if (!workspace) {
      this.logger.error("workspace not found", { slug });
      throw new Error(`Workspace ${slug} not found`);
    }

    this.logger.debug("listing branches", { slug });

    if (workspace.isBareRepo) {
      const entries = this.state.listBranches(slug);
      return entries.map((e) => e.name);
    }

    const result = await branchList({ cwd: workspace.path });
    if (Result.isError(result)) {
      this.logger.warn("failed to list branches", { slug, error: result.error.message });
      return [];
    }

    return result.value;
  }

  async deleteBranch(opts: {
    workspace: string;
    branch: string;
    force?: boolean;
  }): Promise<AppResult> {
    const slug = opts.workspace;
    const workspace = this.state.getWorkspace(slug);

    if (!workspace) {
      this.logger.error("workspace not found", { slug });
      return Result.err(new AppError({ message: `Workspace ${slug} not found` }));
    }

    const branch = opts.branch;

    if (workspace.isBareRepo) {
      this.logger.info("deleting worktree for bare repo", { slug, branch });
      return this.removeWorktree({ workspace: slug, branch });
    }

    const existing = await branchList({ cwd: workspace.path });
    if (Result.isOk(existing) && !existing.value.includes(branch)) {
      this.logger.warn("branch not found", { slug, branch });
      return Result.err(
        new AppError({ message: `Branch ${branch} not found in ${slug}` }),
      );
    }

    this.logger.info("deleting branch", { slug, branch, force: opts.force ?? false });
    const result = await branchDelete({
      cwd: workspace.path,
      name: branch,
      force: opts.force,
    });

    if (Result.isError(result)) {
      this.logger.error("branch delete failed", { slug, branch, error: result.error.message });
      return Result.err(
        new AppError({
          message: `Failed to delete branch ${branch}: ${result.error.message}`,
          cause: result.error,
        }),
      );
    }

    this.state.removeBranch(slug, branch);
    this.logger.info("branch deleted", { slug, branch });
    return Result.ok(undefined);
  }

  async serverStart(): Promise<AppResult> {
    this.logger.setFilePath(xdgState("sessionizer", "server.jsonl"));
    this.logger.info("starting sessionizer daemon");

    // Ensure tmux server is running
    const serverResult = await startServer();
    if (Result.isError(serverResult)) {
      this.logger.error("failed to start tmux server", { error: serverResult.error.message });
      return Result.err(
        new AppError({
          message: `Failed to start tmux server: ${serverResult.error.message}`,
          cause: serverResult.error,
        }),
      );
    }
    this.logger.debug("tmux server running");

    // Ensure home session exists
    const homeSession = process.env.USER!;
    const homePath = process.env.HOME!;

    const hasHomeResult = await hasSession({ session: homeSession });
    if (Result.isError(hasHomeResult)) {
      this.logger.error("failed to check home session", { error: hasHomeResult.error.message });
      return Result.err(
        new AppError({
          message: `Failed to check home session: ${hasHomeResult.error.message}`,
          cause: hasHomeResult.error,
        }),
      );
    }

    if (!hasHomeResult.value) {
      this.logger.info("creating home session", { session: homeSession, path: homePath });
      const createResult = await newSession({
        sessionName: homeSession,
        path: homePath,
      });
      if (Result.isError(createResult)) {
        this.logger.error("failed to create home session", { error: createResult.error.message });
        return Result.err(
          new AppError({
            message: `Failed to create home session: ${createResult.error.message}`,
            cause: createResult.error,
          }),
        );
      }
      this.logger.info("home session created");
    } else {
      this.logger.debug("home session already exists");
    }

    // Switch to the home session
    this.logger.info("switching to home session", { session: homeSession });
    const switchResult = await switchClient({ session: homeSession });
    if (Result.isError(switchResult)) {
      this.logger.warn("failed to switch to home session", { error: switchResult.error.message });
    } else {
      this.logger.info("switched to home session", { session: homeSession });
    }

    // Start remote sync cronjob (every hour)
    const job = schedule("0 * * * *", async () => {
      this.logger.info("cron: syncing remote workspaces");
      const result = await this.workspacesSync({ mode: "remote" });
      if (Result.isError(result)) {
        this.logger.error("cron: remote sync failed", { error: result.error.message });
      } else {
        this.logger.info("cron: remote sync complete");
      }
    });

    this.logger.info("cron scheduled");

    // Keep process alive until interrupted
    return new Promise<AppResult>((resolve) => {
      const cleanup = () => {
        this.logger.info("stopping sessionizer daemon");
        job.stop();
        resolve(Result.ok(undefined));
      };

      process.on("SIGINT", cleanup);
      process.on("SIGTERM", cleanup);
    });
  }

  async serverStatus(): Promise<AppResult<{ running: boolean; homeSession: boolean }>> {
    const isRunning = await new Promise<boolean>((resolve) => {
      execFile("tmux", ["info"], (err) => resolve(!err));
    });

    if (!isRunning) {
      return Result.ok({ running: false, homeSession: false });
    }

    const homeResult = await hasSession({ session: process.env.USER! });
    if (Result.isError(homeResult)) {
      return Result.err(
        new AppError({
          message: `Failed to check home session: ${homeResult.error.message}`,
          cause: homeResult.error,
        }),
      );
    }

    return Result.ok({ running: true, homeSession: homeResult.value });
  }

  async serverLogs(opts: { follow?: boolean }): Promise<AppResult> {
    const logPath = xdgState("sessionizer", "server.jsonl");

    if (opts.follow) {
      return new Promise<AppResult>((resolve) => {
        const child = spawn("tail", ["-f", logPath], { stdio: "inherit" });
        child.on("close", (code) => {
          resolve(code === 0 ? Result.ok(undefined) : Result.err(
            new AppError({ message: `tail exited with code ${code}` }),
          ));
        });
        child.on("error", (err) => {
          resolve(Result.err(
            new AppError({ message: `Failed to follow logs: ${err.message}`, cause: err }),
          ));
        });
      });
    }

    const result = await Result.tryPromise({
      try: async () => {
        const content = await readFile(logPath, "utf-8");
        return content;
      },
      catch: (cause) =>
        new AppError({
          message: "Failed to read server logs",
          cause,
        }),
    });

    if (Result.isError(result)) {
      return Result.err(result.error);
    }

    console.log(result.value);
    return Result.ok(undefined);
  }

  async switchSession(opts: {
    home?: boolean;
    workspace?: string;
    branch?: string;
  }): Promise<AppResult> {
    if (opts.home) {
      if (opts.workspace || opts.branch) {
        this.logger.error("--home is exclusive with --workspace and --branch");
        return Result.err(
          new AppError({ message: "--home is exclusive with --workspace and --branch" }),
        );
      }

      const sessionName = process.env.USER!;
      const homePath = process.env.HOME!;

      this.logger.info("switching to home session", { session: sessionName });
      const exists = await hasSession({ session: sessionName });
      if (Result.isError(exists)) {
        return Result.err(
          new AppError({ message: exists.error.message, cause: exists.error }),
        );
      }

      if (!exists.value) {
        const createResult = await newSession({
          sessionName,
          path: homePath,
        });
        if (Result.isError(createResult)) {
          return Result.err(
            new AppError({
              message: createResult.error.message,
              cause: createResult.error,
            }),
          );
        }
      }

      const switchResult = await switchClient({ session: sessionName });
      if (Result.isError(switchResult)) {
        return Result.err(
          new AppError({ message: switchResult.error.message, cause: switchResult.error }),
        );
      }

      this.logger.info("switched to home session", { session: sessionName });
      return Result.ok(undefined);
    }

    if (!opts.workspace) {
      this.logger.error("--workspace is required when --home is not provided");
      return Result.err(
        new AppError({ message: "--workspace is required when --home is not provided" }),
      );
    }

    const slug = opts.workspace;
    const workspace = this.state.getWorkspace(slug);

    if (!workspace) {
      this.logger.error("workspace not found", { slug });
      return Result.err(new AppError({ message: `Workspace ${slug} not found` }));
    }

    let sessionName: string;
    let sessionPath: string;

    if (workspace.isBareRepo) {
      const branch =
        opts.branch ?? workspace.activeBranch ?? workspace.defaultBranch;

      if (opts.branch) {
        const worktrees = this.state.listBranches(slug);
        if (!worktrees.some((w) => w.name === opts.branch)) {
          this.logger.error("branch not found in workspace worktrees", {
            slug,
            branch: opts.branch,
          });
          return Result.err(
            new AppError({
              message: `Branch ${opts.branch} not found in workspace ${slug}`,
            }),
          );
        }
      }

      this.state.updateActiveBranch(slug, branch);

      sessionName = `${slug}@${branch}`;
      sessionPath = `${workspace.path}/${branch}`;
    } else {
      if (opts.branch) {
        this.logger.error("--branch is only valid for bare checkouts", { slug });
        return Result.err(
          new AppError({ message: `--branch is only valid for bare checkouts` }),
        );
      }

      sessionName = slug;
      sessionPath = workspace.path;
    }

    this.logger.info("switching session", {
      session: sessionName,
      path: sessionPath,
    });

    const exists = await hasSession({ session: sessionName });
    if (Result.isError(exists)) {
      return Result.err(
        new AppError({ message: exists.error.message, cause: exists.error }),
      );
    }

    if (!exists.value) {
      const createResult = await newSession({
        sessionName,
        path: sessionPath,
      });
      if (Result.isError(createResult)) {
        return Result.err(
          new AppError({
            message: createResult.error.message,
            cause: createResult.error,
          }),
        );
      }
    }

    const switchResult = await switchClient({ session: sessionName });
    if (Result.isError(switchResult)) {
      return Result.err(
        new AppError({ message: switchResult.error.message, cause: switchResult.error }),
      );
    }

    this.logger.info("switched session", { session: sessionName });
    return Result.ok(undefined);
  }

  async #resolveDefaultBranch(repoPath: string, isBare?: boolean): Promise<string> {
    const refPath = isBare
      ? `${repoPath}/refs/heads/main`
      : `${repoPath}/.git/refs/heads/main`;
    try {
      await access(refPath);
      return "main";
    } catch {
      return "master";
    }
  }

  async #buildWorktrees(
    repoPath: string,
  ): Promise<NonNullable<Workspace["worktrees"]>> {
    const result = await worktreeList({ cwd: repoPath });
    if (Result.isError(result)) {
      this.logger.warn("failed to list worktrees", {
        path: repoPath,
        error: result.error.message,
      });
      return [];
    }

    const worktrees: NonNullable<Workspace["worktrees"]> = [];

    for (const entry of result.value) {
      if (!entry.branch) continue;

      const hasRemote = await hasRemoteTrackingBranch(repoPath, entry.branch);
      worktrees.push({
        name: entry.branch,
        hasRemote: Result.isOk(hasRemote) ? (hasRemote.value as boolean) : false,
      });
    }

    return worktrees;
  }

  // ─── Session helpers ─────────────────────────────────────────────────────

  async #buildSessions(): Promise<Session[]> {
    this.logger.debug("fetching tmux sessions");
    const result = await listSessions();
    if (Result.isError(result)) {
      this.logger.warn("failed to list tmux sessions", {
        error: result.error.message,
      });
      return [];
    }
    return result.value.map((name) => ({
      name,
      workspace: this.#findWorkspace(name),
    }));
  }

  #findWorkspace(name: string): Workspace | undefined {
    const parsed = parseRepoSlug(name);
    if (!parsed) return undefined;

    const { owner, repo } = parsed;
    const slug = `${owner}/${repo}`;

    return this.state.getWorkspace(slug) ?? undefined;
  }

  /** Resolve the starting directory for a new session. */
  #resolvePath(name: string, workspace?: Workspace): string | undefined {
    if (isHomeSession(name)) {
      return process.env.HOME;
    }

    if (!workspace) return undefined;

    const parsed = parseRepoSlug(name);
    if (workspace.isBareRepo && parsed?.branch) {
      return `${workspace.path}/${parsed.branch}`;
    }

    return workspace.path;
  }
}
