import { existsSync, statSync } from "node:fs";
import path from "node:path";

export function shellQuote(value) {
  const str = String(value ?? "");
  return `'${str.replace(/'/g, `'\\''`)}'`;
}

export function execCapture(cmd) {
  const proc = Bun.spawnSync(["sh", "-c", cmd], {
    stdout: "pipe",
    stderr: "inherit",
  });
  return proc.stdout ? new TextDecoder().decode(proc.stdout) : "";
}

export function exec(cmd) {
  const proc = Bun.spawnSync(["sh", "-c", cmd], {
    stdin: "inherit",
    stdout: "inherit",
    stderr: "inherit",
  });
  return proc.exitCode ?? 1;
}

export function trim(str) {
  return String(str ?? "").replace(/\s+$/g, "");
}

function isDir(p) {
  try {
    return existsSync(p) && statSync(p).isDirectory();
  } catch {
    return false;
  }
}

function isFile(p) {
  try {
    return existsSync(p) && statSync(p).isFile();
  } catch {
    return false;
  }
}

export function findGitDir(start = trim(execCapture("pwd"))) {
  let current = start;
  while (current !== "/") {
    if (current.endsWith(".git") && isDir(current)) {
      return current;
    }

    const found = trim(
      execCapture(`find ${shellQuote(current)} -maxdepth 2 -name "*.git" -type d 2>/dev/null | head -n 1`),
    );
    if (found !== "") {
      return found;
    }

    current = path.dirname(current);
  }
  return null;
}

export function repoContext(gitDir) {
  const parentDir = path.dirname(gitDir);
  const repoName = path.basename(parentDir);
  const orgDir = path.dirname(parentDir);
  const orgName = path.basename(orgDir);
  return { parentDir, repoName, orgName };
}

export function getWorktreeBranches(gitDir) {
  const output = execCapture(`git -C ${shellQuote(gitDir)} worktree list --porcelain`);
  const worktrees = [];
  let currentPath = null;

  for (const line of output.split(/\n/)) {
    const wtPath = line.match(/^worktree (.+)/)?.[1];
    if (wtPath) {
      currentPath = wtPath;
    }

    const branch = line.match(/^branch refs\/heads\/(.+)/)?.[1];
    if (branch && currentPath) {
      worktrees.push({ path: currentPath, branch });
      currentPath = null;
    }
  }

  return worktrees;
}

export function sessionName(orgName, repoName, branchName) {
  return `${orgName}/${repoName}@${branchName}`.replace(/[. ]/g, "_");
}

export function trustMise(worktreePath) {
  if (exec("command -v mise >/dev/null 2>&1") !== 0) {
    return;
  }

  const dotMise = path.join(worktreePath, ".mise.toml");
  const mise = path.join(worktreePath, "mise.toml");
  if (isFile(dotMise)) {
    exec(`mise trust -q ${shellQuote(dotMise)} 2>/dev/null`);
  } else if (isFile(mise)) {
    exec(`mise trust -q ${shellQuote(mise)} 2>/dev/null`);
  }
}

export function requireGitDir() {
  const gitDir = findGitDir();
  if (!gitDir) {
    console.error("Error: Could not find a .git directory.");
    process.exit(1);
  }
  return gitDir;
}

export function requireBareRepo() {
  const gitDir = requireGitDir();
  if (!isDir(path.join(gitDir, "worktrees"))) {
    console.error("Error: This does not appear to be a bare repository with worktrees.");
    console.error("Re-clone with: git-clone --bare <repo>");
    process.exit(1);
  }
  return gitDir;
}

export function createWorktree(gitDir, worktreePath, branchName) {
  const localExists = exec(
    `git -C ${shellQuote(gitDir)} rev-parse --verify ${shellQuote(branchName)} >/dev/null 2>&1`,
  ) === 0;

  if (localExists) {
    console.log(`Branch '${branchName}' exists locally.`);
    exec(`git -C ${shellQuote(gitDir)} worktree add ${shellQuote(worktreePath)} ${shellQuote(branchName)}`);
    return;
  }

  const remoteBranch = trim(
    execCapture(
      `git -C ${shellQuote(gitDir)} branch -r --no-color | grep ${shellQuote(`/${branchName}$`)} | head -n 1`,
    ).replace(/^\s+/g, ""),
  );

  if (remoteBranch !== "") {
    console.log(`Branch '${branchName}' exists on remote as ${remoteBranch}.`);
    exec(
      `git -C ${shellQuote(gitDir)} worktree add -b ${shellQuote(branchName)} ${shellQuote(worktreePath)} ${shellQuote(remoteBranch)}`,
    );
  } else {
    console.log(`Branch '${branchName}' does not exist. Creating new branch.`);
    exec(`git -C ${shellQuote(gitDir)} worktree add -b ${shellQuote(branchName)} ${shellQuote(worktreePath)}`);
  }
}

export function inTmux() {
  return process.env.TMUX != null;
}

export function tmuxSwitchOrCreate(name, worktreePath) {
  if (!inTmux()) {
    return false;
  }

  if (exec(`tmux has-session -t ${shellQuote(name)} 2>/dev/null`) === 0) {
    exec(`tmux switch-client -t ${shellQuote(name)}`);
  } else {
    exec(`TMUX="" tmux new-session -d -s ${shellQuote(name)} -c ${shellQuote(worktreePath)}`);
    exec(`tmux send-keys -t ${shellQuote(name)} "nvim" Enter`);
    exec(`tmux switch-client -t ${shellQuote(name)}`);
  }
  return true;
}

export function tmuxKillSession(name) {
  if (!inTmux()) {
    return;
  }
  if (exec(`tmux has-session -t ${shellQuote(name)} 2>/dev/null`) === 0) {
    console.log(`Killing tmux session '${name}'...`);
    exec(`tmux kill-session -t ${shellQuote(name)}`);
  }
}

export function fzf(lines, opts = "") {
  const input = `${lines.join("\n")}\n`;
  const proc = Bun.spawnSync(["sh", "-c", `fzf ${opts}`], {
    stdin: new TextEncoder().encode(input),
    stdout: "pipe",
    stderr: "inherit",
  });
  const output = proc.stdout ? new TextDecoder().decode(proc.stdout) : "";
  return trim(output);
}

export function defaultBranch(gitDir) {
  return trim(
    execCapture(
      `git -C ${shellQuote(gitDir)} symbolic-ref --short HEAD 2>/dev/null || git -C ${shellQuote(gitDir)} rev-parse --abbrev-ref HEAD`,
    ),
  );
}

export function execLines(cmd) {
  const output = execCapture(cmd);
  return output.replace(/\n$/g, "").split(/\n/).filter((line) => line.length > 0);
}
