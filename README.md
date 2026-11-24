# dotfiles

A collection of configuration files for a modern, efficient development environment on macOS and Linux.

## Overview

This repository uses [mise](https://mise.jdx.dev/) to manage runtimes and CLI tools, and links configuration files into place via the `[dotfiles]` section of `mise.toml`. It is designed to be a "one-command" setup for new machines.

### Key Components

- **Shell:** `zsh` with custom functions and aliases.
- **Editor:** `Neovim` (LazyVim based).
- **Terminal Emulators:** `Ghostty`, `Rex`.
- **Status Line:** `starship`.
- **Interactive tools:** `television`, `herdr`.
- **Tool Management:** `mise` for managing runtimes and CLI tools.

## Getting Started

To set up a new machine, clone this repository and run the bootstrap script:

```bash
git clone https://github.com/JFenstermacher/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./bootstrap
```

### What the Bootstrap Script Does:

1.  **Installs Mise:** The primary tool manager.
2.  **Installs Dependencies:** Uses `mise install` to fetch all required CLI tools.
3.  **Applies Dotfiles:** Uses `mise bootstrap dotfiles apply` to symlink the entries declared under `[dotfiles]` in `mise.toml` into `$HOME`.

## Rex Copy Mode

Press `Ctrl-a`, then `[` to open the focused pane's screen and retained scrollback in a read-only Neovim overlay with the terminal colors preserved. It starts at the newest output and uses standard Neovim motions and `/` search. Select with `v`, `V`, or `Ctrl-v`; yanking (`y`, `yy`, or `y{motion}`) copies plain text to the Rex client's clipboard without color codes and closes the overlay. Press `q` to close it without copying.

Copy mode loads at most the newest 5,000 lines or 128 KiB of styled output, whichever limit it hits first. The status line shows `[capped]` when older output was omitted. This only limits the Neovim view; Rex keeps its own scrollback.

If the pane is running a full-screen app on the alternate screen, Rex captures only that screen. Run `rex config reload` after changing the Rex bindings.

## Per-Machine Overrides

Shared dotfiles live in the repo and apply to every machine. Where a machine needs to diverge, add a machine-local file that the shared config picks up conditionally:

- **git identity:** `git/.gitconfig` includes `~/.gitconfig.work`. Create that file only on the work machine (git silently skips a missing `[include]` path, so the file's presence is the switch). `.gitconfig.work` is gitignored, so it never gets committed.
- **Environment-split configs:** `mise.<env>.toml` files are committed (e.g. `mise.personal.toml`) and loaded when `MISE_ENV=<env>` is set on that machine. Use these for per-machine divergence beyond git.

## Dotfile Modules

Managed under `[dotfiles]` in `mise.toml`:

| Source | Target | Mode |
|---|---|---|
| `ghostty/` | `~/.config/ghostty` | symlink |
| `rex/` | `~/.config/rex` | symlink |
| `mise/` | `~/.config/mise` | symlink-each |
| `git/` | `~/.gitconfig`, `~/.gitignore_global` | symlink |
| `starship/` | `~/.config/starship.toml` | symlink |
| `television/` | `~/.config/television` | symlink-each |
| `zsh/` | `~/.config/zsh`, `~/.zshenv` | symlink |
| `nvim/` | `~/.config/nvim`, `~/.config/nvim-writing` | symlink |
| `herdr/` | `~/.config/herdr` | symlink-each |

Run `mise bootstrap dotfiles apply` after editing any of these to sync them out.