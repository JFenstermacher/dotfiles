---
description: Classify a work prompt (fix/feat/chore/featb/fixb), create a sessionizer branch + herdr workspace, and dispatch the work to that workspace's agent pane.
---

Dispatch work to a fresh sessionizer workspace.

## Preflight (all checks must pass before doing anything else)

1. `command -v sessionizer` — if it fails, stop and tell the user sessionizer is not installed.
2. `test "${HERDR_ENV:-}" = 1` — if it fails, stop: this skill only works when running inside a herdr-managed pane. Never control a herdr session from outside herdr.
3. `git rev-parse --show-toplevel` — if it fails, stop: this skill must be run from within a repository checkout. Do NOT ask the user for `--owner`/`--name`; sessionizer infers them from the current checkout.

## 1. Classify the prompt

Classify the user's work prompt into exactly one of:

- `fix` — a bug fix
- `feat` — a new feature or enhancement
- `chore` — maintenance, tooling, deps, refactor, docs, no behavior change
- `featb` — a breaking feature (API/behavior change that breaks consumers)
- `fixb` — a breaking bug fix (the fix itself breaks existing behavior/contracts)

If the prompt is genuinely ambiguous between two classes, pick the one matching what the user literally asked for and note the choice.

## 2. Create the branch

Map the class to a branch prefix (matches the repo's existing `<type>/<slug>` convention and the user's conventional-commit style):

- `fix` → `fix/`
- `feat` → `feat/`
- `chore` → `chore/`
- `featb` → `featb/`
- `fixb` → `fixb/`

Derive a short kebab-case slug from the prompt (3–6 words, lowercase, imperative, e.g. `fix/sessionizer-sync-branch`, `featb/drop-v1-api`). Then:

1. Check for collisions with `sessionizer list branch` (and `git branch --list <name>`). If the branch already exists, append `-2`, `-3`, ... until unique. Never reuse an existing branch.
2. Run `sessionizer add br --branch <name>` from the repo root. This creates the branch, the git worktree, and the herdr workspace (two tabs: code, agent). Do not pass `--switch`; stay in the current workspace.
3. If it fails, report the error verbatim and stop. Do not fall back to plain `git worktree add`.

## 3. Find the new workspace's agent

1. `herdr workspace list` — find the workspace whose `label` equals the branch name (worktree workspaces are labeled by branch, e.g. `feat/ghtokens-cloudflare`). Read its `workspace_id` from the JSON; do not guess it. Cross-check with `sessionizer list workspaces` if ambiguous.
2. `herdr agent list` — find the agent whose `workspace_id` matches. Worktree workspaces normally have an `omp` agent on the agent tab.
3. If no agent exists yet, find the agent tab via `herdr tab list --workspace <workspace_id>` (tab `label` is `agent`), take its `tab_id`, then pick the matching pane from `herdr pane list --workspace <workspace_id>` (pane's `tab_id`) and start one: `herdr agent start <unique-name> --kind omp --pane <pane-id>` (name must match `[a-z][a-z0-9_-]{0,31}` and be unique; derive it from the slug, e.g. `sync-branch-fix`). Do not create tabs, panes, or split layout.

## 4. Dispatch the prompt

Send the work prompt prefixed with its classification so the agent knows the intent:

```
herdr agent prompt <agent-name-or-pane-id> "(<class>) <original work prompt>"
```

Do NOT use `--wait` (that blocks until the work settles). Instead confirm the agent picked it up:

```
herdr agent wait <target> --until working --timeout 15000
```

If the wait times out, read `herdr agent get <target>` and `herdr agent read <target> --source recent-unwrapped --lines 60` to see why, and report to the user.

Finally report: the classification, the branch name, the workspace ID, and the agent target that received the prompt.
