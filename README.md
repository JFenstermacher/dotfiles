# dotfiles

A collection of configuration files for a modern, efficient development environment on macOS and Linux.

## Overview

This repository uses [mise](https://mise.jdx.dev/) and [fling](https://github.com/bbkane/fling) (via mise tasks) to manage and symlink configuration files. It is designed to be a "one-command" setup for new machines.

### Key Components

- **Shell:** `zsh` with custom functions and aliases.
- **Editor:** `Neovim` (LazyVim based).
- **Terminal Multiplexer:** `tmux` with a custom Tokyo Night themed status bar.
- **Terminal Emulator:** `Ghostty`.
- **Tool Management:** `mise` for managing runtimes and CLI tools.
- **Script Runtime:** `bun` for custom automation scripts in `bin/.config/bin/`.
- **Window Management:** `xmonad` (for Linux environments).

## Getting Started

To set up a new machine, clone this repository and run the bootstrap script:

```bash
git clone https://github.com/yourusername/dotfiles.git ~/workspace/dotfiles
cd ~/workspace/dotfiles
./bootstrap
```

### What the Bootstrap Script Does:

1.  **Installs Mise:** The primary tool manager.
2.  **Installs TPM:** Tmux Plugin Manager and its plugins.
3.  **Installs Dependencies:** Uses `mise install` to fetch all required CLI tools.
4.  **Symlinks Dotfiles:** Uses `mise stow` (which calls `fling`) to link configurations to their appropriate locations in `$HOME`.

## Custom Scripts

Custom automation scripts live in `bin/.config/bin/`. Scripts that were previously written for LuaJIT have been rewritten for [Bun](https://bun.sh/) because LuaJIT installation via mise is unreliable on some machines. Bun must be available on `PATH` for these scripts.

The Bun scripts share `utils.js`, which provides shell helpers, git worktree parsing, tmux integration, fzf integration, and mise trust helpers.

- `utils.js`: Shared Bun utility library.
- `sessionizer`: A smart project/session switcher for tmux.
- `list-workspaces`: Lists standard and bare Git repositories for the session switcher.
- `git-clone`: Clones a repository (optionally as a bare repo) and sets up a default worktree.
- `git-worktree-add`: Creates a new git worktree and associated tmux session.
- `git-worktree-remove`: Interactively removes worktrees and their associated tmux sessions.
- `git-worktree-switch`: Interactively switches between worktrees and their associated tmux sessions.
- `git-worktree-checkout`: Fuzzy-finds across all branches and either switches to an existing worktree or creates one.
- `git-worktree-purge`: Removes merged worktrees and deletes their merged branches.
- `home-session`: Creates or jumps to a default "home" tmux session.
- `privatebox`: Shell wrapper that runs the Privatebox Bun app.

## Tmux Keybindings

Note: The prefix key is configured as `Ctrl-a`.

- `Prefix + r`: Reload tmux configuration.
- `Prefix + p`: Open project switcher (`sessionizer`).
- `Prefix + j`: Jump to an existing tmux session.
- `Prefix + k`: Kill an existing tmux session.
- `Prefix + H`: Open home session.
- `Prefix + w`: Enter worktree mode. From here, you can use:
  - `c`: Create a new git worktree and session (`git-worktree-add`).
  - `d` / `k`: Remove existing git worktrees and sessions (`git-worktree-remove`).
  - `s` / `j`: Switch between git worktrees (`git-worktree-switch`).
  - `b`: Browse all branches and checkout/create worktree (`git-worktree-checkout`).
