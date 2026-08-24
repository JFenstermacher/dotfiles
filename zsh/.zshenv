export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"
# macOS has no XDG_RUNTIME_DIR; without it Neovim falls back to the long
# $TMPDIR/nvim.<user>/... path, which overflows the 104-char unix socket
# limit and breaks fzf-lua's serverstart(). Keep this short.
export XDG_RUNTIME_DIR="$HOME/.local/run"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

export ZCACHEDIR="$XDG_CACHE_HOME/zsh"
export ZDATADIR="$XDG_DATA_HOME/zsh"
export ZSTATEDIR="$XDG_STATE_HOME/zsh"

mkdir -p "$ZCACHEDIR"
mkdir -p "$ZDATADIR"
mkdir -p "$ZSTATEDIR"

mkdir -p "$XDG_RUNTIME_DIR" && chmod 700 "$XDG_RUNTIME_DIR"
