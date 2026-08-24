# Agent Instructions

Always use semantic commit messages.

## Project Structure

Dotfiles repo managed by [mise](https://mise.jdx.dev/) via the `[dotfiles]` section of `mise.toml`, which maps each tool's config directory to its `$HOME`/`~/.config` location and is applied with `mise bootstrap dotfiles apply`.

Each directory holds configuration for one tool:

```
zsh/          Shell config
nvim/         Neovim
ghostty/      Terminal emulator
starship/     Status line
television/   Interactive tools
herdr/        Interactive tools
mise/         mise config + plugin
git/          .gitconfig, .gitignore_global
bin/          Scripts
bootstrap     One-command new-machine setup entry point
```

All configs are plain data/script files — there are no sources to compile and no runtime packages.