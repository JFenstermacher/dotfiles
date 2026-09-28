#!/usr/bin/env zsh
# Safe to re-source (`sz`): every step below is idempotent.

# PERSONAL_DIR contains computer specific configurations
PERSONAL_DIR=$HOME/.personal/zsh

# Load all the zsh goodness
source $ZDOTDIR/zsh-functions
source $ZDOTDIR/zsh-exports

# Brew - potentially installed mise with brew, so need brew to be available on path
# Otherwise, native install is available via $PATH update in the zsh-exports
brew_setup

# Mise (lazy: shims now, full activation after the first prompt)
mise_setup

source $ZDOTDIR/zsh-aliases

# Files to be loaded prior to Instant Prompt
zsh_load_directory $PERSONAL_DIR/before

##################################################################
# OPTIONS
##################################################################

# === History Configuration ===
setopt extended_history  # Write history in the ':start:elapsed;command' format (with timestamps).
setopt append_history    # Append new history to the file rather than replacing it.
setopt share_history     # Immediately synchronize history among all active shell sessions.

# === General Usability & Navigation ===
setopt autocd               # Allows typing just a directory name to 'cd' into it.
setopt interactive_comments # Allows using '#' for comments in an interactive session.

# === Completion and Correction ===
setopt extendedglob      # Enables powerful pattern matching (globbing) features.
setopt nomatch           # Output an error if a glob pattern finds no matches (safer than passing unexpanded pattern).

setopt auto_menu         # Automatically start the menu selection when completing (e.g., on second Tab).
setopt auto_param_keys   # Automatic completion for command parameters/options (e.g., ls -<Tab>).
setopt complete_in_word  # Allow completion anywhere within a word, not just at the end.
setopt correct           # Offer to correct typos in command names (e.g., 'dco' -> 'doc').

# === Disabling Shell Features (unsetopt) ===
unsetopt beep            # Shut off the annoying terminal bell.

##################################################################
# COMPLETIONS
##################################################################

CUSTOM_ZFUNC_DIR="$ZDATADIR/.zfunc"
ZCOMPDUMP_FILE="$ZCACHEDIR/zcompdump-$ZSH_VERSION"

[[ -d $CUSTOM_ZFUNC_DIR ]] || mkdir -p "$CUSTOM_ZFUNC_DIR"

# fpath is unique (typeset -U in .zshenv), so this never duplicates.
fpath=("$CUSTOM_ZFUNC_DIR" $fpath)

autoload -Uz bashcompinit compinit
zmodload zsh/complist

# Full fpath rescan at most once a day; otherwise trust the existing dump
# (-C), which skips a lot of filesystem work. The compiled .zwc doubles as
# the "last full rescan" timestamp, since compinit doesn't rewrite an
# unchanged dump.
if [[ -n $ZCOMPDUMP_FILE.zwc(#qN.mh-24) ]]; then
  compinit -C -d "$ZCOMPDUMP_FILE"
else
  compinit -u -d "$ZCOMPDUMP_FILE"
  [[ -s $ZCOMPDUMP_FILE ]] && zcompile "$ZCOMPDUMP_FILE"
fi
bashcompinit

# compinit resets _comp_options, so this must come after it.
(( ${_comp_options[(Ie)globdots]} )) || _comp_options+=(globdots)

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

starship_setup

# UV
uv_setup

zsh_load_directory $PERSONAL_DIR/after

# -U only dedupes array assignments; scalar `export PATH="$PATH:..."` (as in
# personal files and tool init scripts) bypasses it. Re-applying the flag
# collapses any duplicates, keeping each entry's first position.
typeset -U path fpath manpath
