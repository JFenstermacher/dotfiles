#!/usr/bin/env zsh

# PERSONAL_DIR contains computer specific configurations
PERSONAL_DIR=$HOME/.personal/zsh

# Load all the zsh goodness
source $ZDOTDIR/zsh-functions
source $ZDOTDIR/zsh-exports

# Mise
mise_setup

source $ZDOTDIR/zsh-aliases

# Files to be loaded prior to Instant Prompt
zsh_load_directory $PERSONAL_DIR/before

##################################################################
# OPTIONS
##################################################################

# === History Configuration ===
# Your Existing Options:
setopt extended_history  # Write history in the ':start:elapsed;command' format (with timestamps).
setopt append_history    # Append new history to the file rather than replacing it.
setopt share_history     # Immediately synchronize history among all active shell sessions.

# === General Usability & Navigation ===
# Your Existing Options:
setopt autocd               # Allows typing just a directory name to 'cd' into it.
setopt interactive_comments # Allows using '#' for comments in an interactive session.

# === Completion and Correction ===
# Your Existing Option (for Globbing):
setopt extendedglob      # Enables powerful pattern matching (globbing) features.
setopt nomatch           # Output an error if a glob pattern finds no matches (safer than passing unexpanded pattern).

setopt auto_menu         # Automatically start the menu selection when completing (e.g., on second Tab).
setopt auto_param_keys   # Automatic completion for command parameters/options (e.g., ls -<Tab>).
setopt complete_in_word  # Allow completion anywhere within a word, not just at the end.
setopt correct           # Offer to correct typos in command names (e.g., 'dco' -> 'doc').

# === Disabling Shell Features (unsetopt) ===
# Your Existing Option:
unsetopt beep            # Shut off the annoying terminal bell.

##################################################################
# COMPLETIONS
##################################################################

# 1. Define custom paths BEFORE using them
CUSTOM_ZFUNC_DIR="$ZDATADIR/.zfunc"
# Recommended location for the completion dump file (cache)
export ZCOMPDUMP_FILE="$HOME/.cache/zsh/zcompdump-$ZSH_VERSION"

# 2. Setup paths and autoload functions
mkdir -p "$CUSTOM_ZFUNC_DIR"
mkdir -p "$(dirname $ZCOMPDUMP_FILE)" # Ensure the cache directory exists

# Set the function path (add your custom path first)
fpath=( "$CUSTOM_ZFUNC_DIR" "${fpath[@]}" )

# Autoload required functions
autoload bashcompinit && bashcompinit
autoload -Uz compinit

# 3. Load completions and modules
zmodload zsh/complist
_comp_options+=(globdots)

# 4. Final, SINGLE compinit call using the -d option
# This is the ONLY time compinit should be called!
compinit -d "$ZCOMPDUMP_FILE"

zsh_load_directory $PERSONAL_DIR

##################################################################
# PLUGINS
##################################################################

PLUGINS=(
  "zsh-users/zsh-autosuggestions"
  "zsh-users/zsh-syntax-highlighting"
  "hlissner/zsh-autopair"
  "jeffreytse/zsh-vi-mode"
)

zsh_add_plugins "${PLUGINS[@]}"

##################################################################
# TOOL SETUPS
##################################################################

eval "$(starship init zsh)"

# BREW
brew_setup

# UV
uv_setup

zsh_load_directory $PERSONAL_DIR/after
