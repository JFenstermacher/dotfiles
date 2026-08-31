---
description: Search code in a GitHub repository by using a local sessionizer checkout at ~/workspaces/{owner}/{repo} instead of remote code search. Use whenever you need to search, grep, list, or read code from a remote GitHub repo (named explicitly, from a github.com URL, or via an issue/PR).
---

Search code in a GitHub repository locally rather than via remote codesearch (GitHub search API/web). Works for any `{owner}/{repo}` target, whether the user names it explicitly or it comes from a URL, issue, or PR.

## Preflight

1. `command -v sessionizer` — if it fails, stop and tell the user sessionizer is not installed. Do not fall back to remote search or a bare `git clone`.

## 1. Resolve {owner}/{repo}

Determine the GitHub owner and repo name from the user's request (explicit mention, `github.com/{owner}/{repo}` URL, or the repo an issue/PR belongs to). Strip a `.git` suffix if present. If you cannot determine both parts, stop and ask.

## 2. Ensure a local checkout

1. Check for an existing checkout: `test -d ~/workspaces/{owner}/{repo}`.
2. If it exists, skip to step 4.
3. If not, check it out with sessionizer:

   ```
   sessionizer add repo {owner}/{repo}
   ```

   This clones to `~/workspaces/{owner}/{repo}`. If it fails, report the error verbatim and stop. Never `git clone` manually into `~/workspaces/`.

## 3. Refresh from main

1. `git -C ~/workspaces/{owner}/{repo} fetch origin main`
2. If the checkout's current branch (`git -C ... branch --show-current`) is `main` or `master`, fast-forward it:
   `git -C ~/workspaces/{owner}/{repo} pull --ff-only origin main`
3. If it is on another branch, do NOT switch branches — search against the fetched ref instead:
   `git -C ~/workspaces/{owner}/{repo} grep <pattern> origin/main` (and `git -C ... ls-tree -r --name-only origin/main` for file listing).

## 4. Codesearch locally

Run all search, file listing, and reads rooted at `~/workspaces/{owner}/{repo}` using the normal local tools (`grep`, `glob`, `read`). Never call remote code search for this repo while the local checkout is available.

Report results with paths relative to the repo root (e.g. `src/foo.ts:42`).
