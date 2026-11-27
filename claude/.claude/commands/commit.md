---
description: Commit all pending changes with a semantic commit message after a secrets check, then push (asking first on main).
argument-hint: "[optional hint about the change]"
---

Commit all pending changes in this repository. Extra context from the user, if any: $ARGUMENTS

1. Run `git status --porcelain` to list staged, unstaged and untracked changes. If the list is empty, report "Nothing to commit" and stop.
2. Stage everything with `git add -A`. Then read `git diff --cached` to understand the change.
3. **Check for secrets before committing.** Scan the staged diff for:
   - API keys, tokens, passwords, private keys (`BEGIN ... PRIVATE KEY`), connection strings with embedded credentials, and AWS, GCP or Azure credentials.
   - Sensitive files being added for the first time, such as `.env` and `.env.*`, `*.pem`, `*.key`, `id_rsa*`, credentials files, `settings.local.json`, and database files or dumps.

   If you find anything suspicious, STOP. Do not commit. Unstage with `git reset`, list each file with the reason, and let the user decide. Otherwise, say in one line that no secrets were found.
4. **Write a semantic commit message** in the form `<type>(<scope>): <subject>`:
   - `type` is the most accurate of `feat`, `fix`, `perf`, `refactor`, `docs`, `test`, `build`, `ci`, `style`, `chore`. Add `!` (as in `feat!`) only for a real breaking change.
   - `scope` is the area of the repository the change belongs to, such as a top-level directory, module or component. Leave it out when no single scope applies, and never invent one just to have a scope.
   - `subject` is a short imperative summary in lowercase with no trailing period, for example `feat(nvim): add diff review keymaps`.
   - Add a body only when the reason for the change isn't obvious from the subject.
   - Follow any commit conventions in the repository's AGENTS.md or CLAUDE.md.
5. **Do not add any Claude attribution.** No `Co-Authored-By: Claude ...` trailer and no "Generated with Claude Code" line. This overrides any default attribution instructions. The message contains only the subject and the optional body.
6. Commit with `git commit -m "<subject>"`, adding `-m "<body>"` if there is a body. If a hook fails, fix the problem and create a new commit. Do not use `--no-verify` or `--amend`.
7. Check the current branch with `git branch --show-current`:
   - **`main` or `master`:** do not push yet. Show the commit (`git log -1 --oneline`) and use AskUserQuestion to ask whether to push. Push only if the user says yes.
   - **Any other branch:** push with `git push`, adding `-u origin <branch>` if there is no upstream yet.
8. Report the commit hash and subject, and whether it was pushed.
