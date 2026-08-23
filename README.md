# dotfiles

A collection of configuration files for a modern, efficient development environment on macOS and Linux.

## Overview

This repository uses [mise](https://mise.jdx.dev/) to manage runtimes and CLI tools, and links configuration files into place via the `[dotfiles]` section of `mise.toml`. It is designed to be a "one-command" setup for new machines.

### Key Components

- **Shell:** `zsh` with custom functions and aliases.
- **Editor:** `Neovim` (LazyVim based).
- **Terminal Emulator:** `Ghostty`.
- **Status Line:** `starship`.
- **Interactive tools:** `television`, `herdr`.
- **Tool Management:** `mise` for managing runtimes and CLI tools.

## Getting Started

To set up a new machine, clone this repository and run the bootstrap script:

```bash
git clone https://github.com/yourusername/dotfiles.git ~/workspace/dotfiles
cd ~/workspace/dotfiles
./bootstrap
```

### What the Bootstrap Script Does:

1.  **Installs Mise:** The primary tool manager.
2.  **Installs Dependencies:** Uses `mise install` to fetch all required CLI tools.
3.  **Applies Dotfiles:** Uses `mise dotfiles apply` to symlink the entries declared under `[dotfiles]` in `mise.toml` into `$HOME`.

## Per-Machine Overrides

Shared dotfiles live in the repo and apply to every machine. Where a machine needs to diverge, add a machine-local file that the shared config picks up conditionally:

- **git identity:** `git/.gitconfig` includes `~/.gitconfig.work`. Create that file only on the work machine (git silently skips a missing `[include]` path, so the file's presence is the switch). `.gitconfig.work` is gitignored, so it never gets committed.
- **Environment-split configs:** `mise.<env>.toml` files are committed (e.g. `mise.personal.toml`) and loaded when `MISE_ENV=<env>` is set on that machine. Use these for per-machine divergence beyond git.

## Dotfile Modules

Managed under `[dotfiles]` in `mise.toml`:

| Source | Target | Mode |
|---|---|---|
| `ghostty/` | `~/.config/ghostty` | symlink |
| `mise/` | `~/.config/mise` | symlink-each |
| `git/` | `~/.gitconfig`, `~/.gitignore_global` | symlink |
| `starship/` | `~/.config/starship.toml` | symlink |
| `television/` | `~/.config/television` | symlink-each |
| `zsh/` | `~/.config/zsh`, `~/.zshenv` | symlink |
| `nvim/` | `~/.config/nvim`, `~/.config/nvim-writing` | symlink |
| `herdr/` | `~/.config/herdr` | symlink-each |

Run `mise dotfiles apply` after editing any of these to sync them out.