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

This repository includes several custom utility scripts located in `bin/.config/bin/`:

- `sessionizer`: A smart project/session switcher for tmux.
- `list-workspaces`: Lists standard and bare Git repositories for the session switcher.
- `git-clone-bare`: Clones a repository as a bare repo and sets up a default worktree.
- `git-worktree-add`: Creates a new git worktree and associated tmux session.
- `git-worktree-remove`: Interactively removes worktrees and their associated tmux sessions.

## Tmux Keybindings

- `Prefix + r`: Reload tmux configuration.
- `Prefix + p`: Open project switcher (`sessionizer`).
- `Prefix + w`: Create a new git worktree and session.
- `Prefix + W`: Remove existing git worktrees and sessions.
- `Prefix + j`: Jump to an existing tmux session.
- `Prefix + k`: Kill an existing tmux session.
