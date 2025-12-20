export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

export ZCACHEDIR="$XDG_CACHE_HOME/zsh"
export ZDATADIR="$XDG_DATA_HOME/zsh"
export ZSTATEDIR="$XDG_STATE_HOME/zsh"

mkdir -p "$ZCACHEDIR"
mkdir -p "$ZDATADIR"
mkdir -p "$ZSTATEDIR"
