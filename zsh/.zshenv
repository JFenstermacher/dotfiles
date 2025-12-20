export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# History handling
export HISTFILE="$XDG_STATE_HOME/zsh/history"
export HISTSIZE=50000
export SAVEHIST=50000

# Set the custom path for zcompdump
ZCOMPDUMP_FILE="$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"

# Create the directory if it doesn't exist
mkdir -p $HOME/.cache/zsh

# Call compinit with the -d option to specify the dump file
compinit -d $ZCOMPDUMP_FILE
