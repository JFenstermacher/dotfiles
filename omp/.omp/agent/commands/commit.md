---
description: Stage all unstaged/staged changes, commit them with a conventional message, and push on non-main branches.
---

Commit all pending changes in this repository.

1. Run `git status --porcelain` to list every staged and unstaged/untracked change. If it is empty, report "Nothing to commit" and stop.
2. Stage everything with `git add -A`.
3. Inspect the changes with `git diff --cached` (and `git diff` for any remaining unstaged hunks) to understand what was done.
4. Create the commit with a conventional-commit message following the pattern `<type>(<scope>): <subject>`:
   - `type`: choose the most accurate from `fix`, `feat`, `fix!`, `feat!`, `perf`, `ci`, `refactor`, `docs`, `build`, `test`, `style`, `chore` — append `!` only for a real breaking change.
   - `scope`: your call as the agent — the area of the repo the change belongs to (a top-level directory, module, component, or none at all). Omit it when no single scope clearly applies (e.g. cross-cutting changes, repo-wide chores); never invent one for form's sake.
   - `subject`: a short imperative summary, e.g. `feat(nvim): update fzf-lua config`.
   - Commit with `git commit -m "<message>"`. Do not add a body unless a reason is non-obvious.
5. Then determine the current branch (`git branch --show-current`). If it is `main` or `master`, stop — do NOT push; tell the user the commit is local and they should push. Otherwise, push to the remote with `git push`.