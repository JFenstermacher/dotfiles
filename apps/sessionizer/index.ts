import { Command } from "@cliffy/command";
import { Result } from "better-result";
import { Logger } from "@dotfiles/logger";
import * as Config from "./config.ts";
import { State } from "./state.ts";
import { App } from "./app.ts";

const config = await Config.load();
const logger = new Logger(config);

const state = new State(config);
const { dbPath } = state.init();
logger.debug("state initialized", { dbPath });

const app = new App(config, state, logger);

// ─── CLI ───────────────────────────────────────────────────────────────────

const sessionsListCmd = new Command()
  .description("List tmux sessions")
  .alias("ls")
  .action(async () => {
    const sessions = await app.listSessions();
    for (const session of sessions) {
      console.log(session.name);
    }
  });

const sessionsAddCmd = new Command()
  .description("Add a tmux session without switching")
  .option("-H, --home", "Add home session")
  .option("-w, --workspace <repo-slug>", "Workspace repo slug (owner/repo)")
  .option("-b, --branch <branch>", "Branch (bare repos only)")
  .action(async (opts: { home?: boolean; workspace?: string; branch?: string }) => {
    const result = await app.addSession(opts);
    if (Result.isError(result)) {
      logger.error(result.error.message);
    }
  });

const sessionsRemoveCmd = new Command()
  .description("Remove a tmux session")
  .alias("rm")
  .option("-H, --home", "Remove home session")
  .option("-w, --workspace <repo-slug>", "Workspace repo slug (owner/repo)")
  .option("-b, --branch <branch>", "Branch (bare repos only)")
  .action(async (opts: { home?: boolean; workspace?: string; branch?: string }) => {
    const result = await app.removeSession(opts);
    if (Result.isError(result)) {
      logger.error(result.error.message);
    }
  });

const sessionsSwitchCmd = new Command()
  .description("Switch to a tmux session")
  .alias("sw")
  .option("-H, --home", "Switch to home session")
  .option("-w, --workspace <repo-slug>", "Workspace repo slug (owner/repo)")
  .option("-b, --branch <branch>", "Branch (bare repos only)")
  .action(async (opts: { home?: boolean; workspace?: string; branch?: string }) => {
    const result = await app.switchSession(opts);
    if (Result.isError(result)) {
      logger.error(result.error.message);
    }
  });

const sessionsCmd = new Command()
  .description("Session management commands")
  .alias("session")
  .alias("s")
  .command("list", sessionsListCmd)
  .command("add", sessionsAddCmd)
  .command("remove", sessionsRemoveCmd)
  .command("switch", sessionsSwitchCmd);

const workspacesListCmd = new Command()
  .description("List workspaces")
  .alias("ls")
  .action(async () => {
    const workspaces = app.listWorkspaces();
    for (const workspace of workspaces) {
      console.log(workspace);
    }
  });

const workspacesSyncCmd = new Command()
  .description("Sync workspaces from disk")
  .option("-m, --mode <mode>", "Sync mode: all, local, remote", { default: "all" })
  .action(async (opts: { mode?: string }) => {
    const mode = opts.mode ?? "all";
    if (mode !== "all" && mode !== "local" && mode !== "remote") {
      logger.error(`Invalid mode "${mode}". Must be one of: all, local, remote`);
      return;
    }
    const result = await app.workspacesSync({ mode });
    if (Result.isError(result)) {
      logger.error(result.error.message);
    }
  });

const workspacesAddCmd = new Command()
  .description("Add a new workspace")
  .arguments("<repo-slug>")
  .option("--bare", "Clone as a bare repository")
  .action(async (opts: { bare?: boolean }, repoSlug: string) => {
    const result = await app.addWorkspace(repoSlug, opts);
    if (Result.isError(result)) {
      logger.error(result.error.message);
    }
  });

const workspacesRemoveCmd = new Command()
  .description("Remove a workspace")
  .alias("rm")
  .arguments("<repo-slug>")
  .action(async (_: void, repoSlug: string) => {
    const result = await app.removeWorkspace(repoSlug);
    if (Result.isError(result)) {
      logger.error(result.error.message);
    }
  });

const workspacesCmd = new Command()
  .description("Workspace management commands")
  .alias("workspace")
  .alias("ws")
  .command("list", workspacesListCmd)
  .command("sync", workspacesSyncCmd)
  .command("add", workspacesAddCmd)
  .command("remove", workspacesRemoveCmd);

const stateShowCmd = new Command()
  .description("Show current state")
  .action(async () => {
    console.log(app.showState());
  });

const stateClearCmd = new Command()
  .description("Clear all workspaces from state")
  .action(async () => {
    app.clearState();
  });

const stateCmd = new Command()
  .description("State management commands")
  .command("show", stateShowCmd)
  .command("clear", stateClearCmd);

const configShowCmd = new Command()
  .description("Show current config")
  .action(async () => {
    console.log(app.showConfig());
  });

const configEditCmd = new Command()
  .description("Edit config in \$EDITOR")
  .action(async () => {
    const result = await app.editConfig();
    if (Result.isError(result)) {
      logger.error(result.error.message);
    }
  });

const configCmd = new Command()
  .description("Config management commands")
  .command("show", configShowCmd)
  .command("edit", configEditCmd);

const worktreeAddCmd = new Command()
  .description("Add a worktree to a bare workspace")
  .option("-w, --workspace <repo-slug>", "Workspace repo slug (owner/repo)")
  .option("-b, --branch <branch>", "Branch to checkout", { required: true })
  .action(async (opts: { workspace?: string; branch: string }) => {
    const result = await app.addWorktree(opts);
    if (Result.isError(result)) {
      logger.error(result.error.message);
    }
  });

const worktreeRemoveCmd = new Command()
  .description("Remove a worktree from a bare workspace")
  .option("-w, --workspace <repo-slug>", "Workspace repo slug (owner/repo)")
  .option("-b, --branch <branch>", "Branch to remove", { required: true })
  .action(async (opts: { workspace?: string; branch: string }) => {
    const result = await app.removeWorktree(opts);
    if (Result.isError(result)) {
      logger.error(result.error.message);
    }
  });

const worktreeCmd = new Command()
  .description("Worktree management commands")
  .alias("worktree")
  .alias("wt")
  .command("add", worktreeAddCmd)
  .command("remove", worktreeRemoveCmd);

const branchesAddCmd = new Command()
  .description("Add a new branch")
  .option("-w, --workspace <repo-slug>", "Workspace repo slug (owner/repo)")
  .option("-b, --branch <branch>", "Branch name to add", { required: true })
  .option("-s, --start-point <ref>", "Starting point (commit or branch)")
  .action(async (opts: { workspace?: string; branch: string; startPoint?: string }) => {
    const result = await app.createBranch(opts);
    if (Result.isError(result)) {
      logger.error(result.error.message);
    }
  });

const branchesListCmd = new Command()
  .description("List branches")
  .alias("ls")
  .option("-w, --workspace <repo-slug>", "Workspace repo slug (owner/repo)")
  .action(async (opts: { workspace?: string }) => {
    try {
      const branches = await app.listBranches(opts);
      for (const branch of branches) {
        console.log(branch);
      }
    } catch {
      // Error already logged by app layer
    }
  });

const branchesSyncCmd = new Command()
  .description("Sync branches from remote and associate pull requests")
  .option("-w, --workspace <repo-slug>", "Workspace repo slug (owner/repo)")
  .action(async (opts: { workspace?: string }) => {
    const result = await app.branchesSync(opts);
    if (Result.isError(result)) {
      logger.error(result.error.message);
    }
  });

const branchesRemoveCmd = new Command()
  .description("Remove a branch")
  .alias("delete")
  .alias("rm")
  .option("-w, --workspace <repo-slug>", "Workspace repo slug (owner/repo)")
  .option("-b, --branch <branch>", "Branch to remove", { required: true })
  .option("--force", "Force delete even if not merged")
  .action(async (opts: { workspace?: string; branch: string; force?: boolean }) => {
    const result = await app.deleteBranch(opts);
    if (Result.isError(result)) {
      logger.error(result.error.message);
    }
  });

const branchesCmd = new Command()
  .description("Branch management commands")
  .alias("branch")
  .alias("br")
  .command("add", branchesAddCmd)
  .command("list", branchesListCmd)
  .command("sync", branchesSyncCmd)
  .command("remove", branchesRemoveCmd);

const serverStartCmd = new Command()
  .description("Start the sessionizer daemon (tmux server, home session, remote sync cron)")
  .action(async () => {
    const result = await app.serverStart();
    if (Result.isError(result)) {
      logger.error(result.error.message);
      process.exit(1);
    }
  });

const serverStatusCmd = new Command()
  .description("Check if the tmux server and home session are running")
  .action(async () => {
    const result = await app.serverStatus();
    if (Result.isError(result)) {
      logger.error(result.error.message);
      process.exit(1);
    }
    const status = result.value;
    if (status.running) {
      console.log(status.homeSession
        ? "Server is running, home session exists"
        : "Server is running, home session missing");
    } else {
      console.log("Server is not running");
    }
  });

const serverLogsCmd = new Command()
  .description("Show server logs")
  .option("-f, --follow", "Follow log output")
  .action(async (opts: { follow?: boolean }) => {
    const result = await app.serverLogs(opts);
    if (Result.isError(result)) {
      logger.error(result.error.message);
      process.exit(1);
    }
  });

const serverCmd = new Command()
  .description("Server management commands")
  .command("start", serverStartCmd)
  .command("status", serverStatusCmd)
  .command("logs", serverLogsCmd);

const initCmd = new Command()
  .description("Initialize the sessionizer database")
  .action(async () => {
    const { dbPath } = app.init();
    logger.info("database initialized", { dbPath });
  });

const main = new Command()
  .name("sessionizer")
  .description("Tmux workspace manager — syncs repos, branches, and PRs from GitHub, manages tmux sessions and worktrees")
  .version("0.1.0")
  .action(async () => {
    const result = await app.serverStart();
    if (Result.isError(result)) {
      logger.error(result.error.message);
      process.exit(1);
    }
  })
  .command("init", initCmd)
  .command("server", serverCmd)
  .command("sessions", sessionsCmd)
  .command("workspaces", workspacesCmd)
  .command("worktrees", worktreeCmd)
  .command("branches", branchesCmd)
  .command("state", stateCmd)
  .command("config", configCmd);

await main.parse(process.argv.slice(2));
