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
  .option("--json", "Output as JSON")
  .action(async (opts: { json?: boolean }) => {
    const sessions = await app.listSessions();
    if (opts.json) {
      console.log(JSON.stringify(sessions, null, 2));
    } else {
      for (const session of sessions) {
        console.log(session.name);
      }
    }
  });

const sessionsAddCmd = new Command()
  .description("Add a tmux session without switching")
  .option("-w, --workspace <repo-slug>", "Workspace repo slug (owner/repo)")
  .option("-b, --branch <branch>", "Branch (bare repos only)")
  .action(async (opts: { workspace?: string; branch?: string }) => {
    const result = await app.addSession(opts);
    if (Result.isError(result)) {
      logger.error(result.error.message);
    }
  });

const sessionsRemoveCmd = new Command()
  .description("Remove a tmux session")
  .alias("rm")
  .option("-w, --workspace <repo-slug>", "Workspace repo slug (owner/repo)")
  .option("-b, --branch <branch>", "Branch (bare repos only)")
  .action(async (opts: { workspace?: string; branch?: string }) => {
    const result = await app.removeSession(opts);
    if (Result.isError(result)) {
      logger.error(result.error.message);
    }
  });

const sessionsSwitchCmd = new Command()
  .description("Switch to a tmux session")
  .alias("sw")
  .option("-w, --workspace <repo-slug>", "Workspace repo slug (owner/repo)")
  .option("-b, --branch <branch>", "Branch (bare repos only)")
  .action(async (opts: { workspace?: string; branch?: string }) => {
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
  .option("--json", "Output as JSON")
  .action(async (opts: { json?: boolean }) => {
    const workspaces = await app.listWorkspaces();
    if (opts.json) {
      console.log(JSON.stringify(workspaces, null, 2));
    } else {
      for (const ws of workspaces) {
        const emojiMap: Record<number, string> = {
          0: "*",
          1: "+",
          2: "-",
          3: " ",
        };
        const priority = ws.isActive ? 0 : ws.hasSession ? 1 : ws.isCheckedOut ? 2 : 3;
        const prefix = emojiMap[priority];
        console.log(prefix ? `${prefix} ${ws.slug}` : ws.slug);
      }
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
  .option("--json", "Output as JSON")
  .action(async (opts: { workspace?: string; json?: boolean }) => {
    try {
      const branches = await app.listBranches(opts);
      if (opts.json) {
        console.log(JSON.stringify(branches, null, 2));
      } else {
        for (const branch of branches) {
          let prefix: string;
          if (branch.isActive) {
            prefix = "*";
          } else if (branch.isWorktree && branch.hasPR) {
            prefix = "^";
          } else if (branch.isWorktree) {
            prefix = "+";
          } else if (branch.hasPR) {
            prefix = "~";
          } else {
            prefix = " ";
          }
          console.log(`${prefix} ${branch.name}`);
        }
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

const branchesCleanupCmd = new Command()
  .description("Clean up branches, worktrees, and sessions for merged pull requests")
  .action(async () => {
    const result = await app.cleanupMergedPRs();
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
  .command("remove", branchesRemoveCmd)
  .command("cleanup", branchesCleanupCmd);

const daemonStartCmd = new Command()
  .description("Start the sessionizer daemon (remote sync cron, branch sync cron)")
  .action(async () => {
    const result = await app.daemonStart();
    if (Result.isError(result)) {
      logger.error(result.error.message);
      process.exit(1);
    }
  });

const daemonStopCmd = new Command()
  .description("Stop the sessionizer daemon")
  .action(async () => {
    const result = await app.daemonStop();
    if (Result.isError(result)) {
      logger.error(result.error.message);
      process.exit(1);
    }
    console.log("Sessionizer daemon stopped");
  });

const daemonStatusCmd = new Command()
  .description("Check if the sessionizer daemon is running")
  .action(async () => {
    const result = await app.daemonStatus();
    if (Result.isError(result)) {
      logger.error(result.error.message);
      process.exit(1);
    }
    const status = result.value;
    if (status.running) {
      console.log("Daemon is running");
    } else {
      console.log("Daemon is not running");
      process.exit(2);
    }
  });

const daemonLogsCmd = new Command()
  .description("Show daemon logs")
  .option("-f, --follow", "Follow log output")
  .action(async (opts: { follow?: boolean }) => {
    const result = await app.daemonLogs(opts);
    if (Result.isError(result)) {
      logger.error(result.error.message);
      process.exit(1);
    }
  });

const daemonCmd = new Command()
  .description("Daemon management commands")
  .command("start", daemonStartCmd)
  .command("stop", daemonStopCmd)
  .command("status", daemonStatusCmd)
  .command("logs", daemonLogsCmd);

const actionsWorkspaceEnterCmd = new Command()
  .description("Enter a workspace (clone if needed, then switch session)")
  .arguments("<repo-slug>")
  .option("--bare", "Clone as a bare repository")
  .action(async (opts: { bare?: boolean }, repoSlug: string) => {
    const result = await app.workspaceEnter(repoSlug, opts);
    if (Result.isError(result)) {
      logger.error(result.error.message);
      process.exit(1);
    }
  });

const actionsBranchEnterCmd = new Command()
  .description("Enter a branch (create branch/worktree/session if needed, then switch)")
  .arguments("<branch>")
  .option("-w, --workspace <repo-slug>", "Workspace repo slug (owner/repo)")
  .action(async (opts: { workspace?: string }, branch: string) => {
    const result = await app.branchEnter({ workspace: opts.workspace, branch });
    if (Result.isError(result)) {
      logger.error(result.error.message);
      process.exit(1);
    }
  });

const actionsCmd = new Command()
  .description("Action commands")
  .command("workspace-enter", actionsWorkspaceEnterCmd)
  .command("branch-enter", actionsBranchEnterCmd);

const main = new Command()
  .name("sessionizer")
  .description("Tmux workspace manager — syncs repos, branches, and PRs from GitHub, manages tmux sessions and worktrees")
  .version("0.1.0")
  .action(async () => {
    const result = await app.attach();
    if (Result.isError(result)) {
      logger.error(result.error.message);
      process.exit(1);
    }
  })
  .command("actions", actionsCmd)
  .command("daemon", daemonCmd)
  .command("sessions", sessionsCmd)
  .command("workspaces", workspacesCmd)
  .command("branches", branchesCmd)
  .command("state", stateCmd)
  .command("config", configCmd);

await main.parse(process.argv.slice(2));
