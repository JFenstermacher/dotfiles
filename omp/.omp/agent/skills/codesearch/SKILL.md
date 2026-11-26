---
description: Search code in a GitHub repository locally via Regent checkout at ~/dev/workspaces/github/{owner}/{repo} instead of remote code search. Use whenever you need to search, grep, list, or read code from a remote GitHub repo (named explicitly, from a github.com URL, or via an issue/PR).
---

Search code in a GitHub repository locally rather than via remote codesearch (GitHub search API or web fetches). Works for any `{owner}/{repo}` target, whether the user names it explicitly or it comes from a URL, issue, or PR.

## 1. Ensure a local checkout via `codesearch_checkout`

Call the `codesearch_checkout` tool with the target (`owner/repo`, `https://github.com/owner/repo`, or SSH URL).

It uses the Regent library to clone missing repos into `~/dev/workspaces/github/{owner}/{repo}` (never overwriting an existing checkout) and refreshes the default branch (`origin/main` or `origin/master`).

- If `codesearch_checkout` fails, report the error verbatim and stop. Do not fall back to remote search or a bare `git clone`.

## 2. Codesearch locally

- When the tool reports `Search mode: local files under <path>`, use normal local tools (`grep`, `glob`, `read`, `find`) rooted at that path.
- When the tool reports `Search mode: git ref origin/<default>`, the local checkout is on another branch — do NOT switch branches. Inspect the fetched ref with `git -C <path> grep <pattern> origin/<default>`, `git -C <path> ls-tree -r --name-only origin/<default>`, and `git -C <path> show origin/<default>:<file>`.
- Never call remote code search for this repo while the local checkout is available.
- Report results with paths relative to the repo root (e.g. `src/foo.ts:42`).
