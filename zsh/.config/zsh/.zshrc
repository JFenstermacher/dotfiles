#!/bin/sh

# PERSONAL_DIR contains computer specific configurations
PERSONAL_DIR=$HOME/.personal/zsh

# Load useful functions
source $ZDOTDIR/zsh-functions

# Files to be loaded prior to Instant Prompt
zsh_load_directory $PERSONAL_DIR/before

# Mise
mise_setup
eval "$(starship init zsh)"

zsh_add_file "zsh-exports"
zsh_add_file "zsh-aliases"

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
setopt autocd            # Allows typing just a directory name to 'cd' into it.
setopt interactive_comments # Allows using '#' for comments in an interactive session.

# === Completion and Correction ===
# Your Existing Option (for Globbing):
setopt extendedglob      # Enables powerful pattern matching (globbing) features.
setopt nomatch           # Output an error if a glob pattern finds no matches (safer than passing unexpanded pattern).

# Recommended Additions:
setopt auto_menu         # Automatically start the menu selection when completing (e.g., on second Tab).
setopt auto_param_keys   # Automatic completion for command parameters/options (e.g., ls -<Tab>).
setopt complete_in_word  # Allow completion anywhere within a word, not just at the end.
setopt correct           # Offer to correct typos in command names (e.g., 'dco' -> 'doc').

# === Performance and Cleanup ===
# Recommended Additions:
setopt hash_list_all     # Hash the contents of all $path directories to speed up command lookups.

# === Disabling Shell Features (unsetopt) ===
# Your Existing Option:
unsetopt beep            # Shut off the annoying terminal bell.

##################################################################
# COMPLETIONS
##################################################################

CUSTOM_ZFUNC_DIR="$ZDOTDIR/.zfunc"
mkdir -p $CUSTOM_ZFUNC_DIR
fpath=( "$CUSTOM_ZFUNC_DIR" "${fpath[@]}" )

autoload bashcompinit && bashcompinit
autoload -Uz compinit && compinit
zmodload zsh/complist
_comp_options+=(globdots)

load_aws_completions

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

# FZF
[ -f "$ZDOTDIR/.fzf.zsh" ] && source "$ZDOTDIR/.fzf.zsh"

# BREW
brew_setup

# UV
uv_setup

zsh_load_directory $PERSONAL_DIR/after
