export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"
# macOS has no XDG_RUNTIME_DIR; without it Neovim falls back to the long
# $TMPDIR/nvim.<user>/... path, which overflows the 104-char unix socket
# limit and breaks fzf-lua's serverstart(). Keep this short.
export XDG_RUNTIME_DIR="$HOME/.local/run"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
# Child shells inherit ZDOTDIR and so read $ZDOTDIR/.zshenv instead of this
# file; zsh/.config/zsh/.zshenv is a symlink back here so both paths agree.

export ZCACHEDIR="$XDG_CACHE_HOME/zsh"
export ZDATADIR="$XDG_DATA_HOME/zsh"
export ZSTATEDIR="$XDG_STATE_HOME/zsh"

# Keep path-like arrays free of duplicates (array assignments only; .zshrc
# re-applies this after scalar `export PATH=...` edits).
typeset -U path fpath manpath

# macOS /etc/zshrc_Apple_Terminal writes per-session state and history into
# ${ZDOTDIR}/.zsh_sessions (i.e. this repo). share_history already covers it.
SHELL_SESSIONS_DISABLE=1

# Test before mkdir: .zshenv runs for every zsh (including scripts), and
# each external command is an exec.
[[ -d $ZCACHEDIR ]] || mkdir -p "$ZCACHEDIR"
[[ -d $ZDATADIR ]] || mkdir -p "$ZDATADIR"
[[ -d $ZSTATEDIR ]] || mkdir -p "$ZSTATEDIR"
[[ -d $XDG_RUNTIME_DIR ]] || mkdir -m 700 -p "$XDG_RUNTIME_DIR"
