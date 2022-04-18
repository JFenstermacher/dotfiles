#!/bin/sh

# For whatever reason sometimes the root .zshrc doesn't get read
# Setting ZDOTDIR once more here
# PERSONAL_DIR contains computer specific configurations
export ZDOTDIR=$HOME/.config/zsh
PERSONAL_DIR=$ZDOTDIR/personal

# Load useful functions
source $ZDOTDIR/zsh-functions

# Files to be loaded prior to Instant Prompt
zsh_load_directory $PERSONAL_DIR/before

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

zsh_add_file "zsh-exports"
zsh_add_file "zsh-aliases"

# Useful Options
setopt autocd extendedglob nomatch menucomplete
setopt interactive_comments
setopt appendhistory

# Be silent
unsetopt BEEP

# Completions
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
_comp_options+=(globdots)

zsh_load_directory $PERSONAL_DIR

# Load some plugins
PLUGINS=(
  "zsh-users/zsh-autosuggestions"
  "zsh-users/zsh-syntax-highlighting"
  "hlissner/zsh-autopair"
)

zsh_add_plugins "${PLUGINS[@]}"

# Load favorite theme
zsh_load_theme "romkatv/powerlevel10k"

# Powerlevel10k customizations
[[ ! -f $ZDOTDIR/.p10k.zsh ]] || source $ZDOTDIR/.p10k.zsh

# FZF
[ -f "$ZDOTDIR/.fzf.zsh" ] && source "$ZDOTDIR/.fzf.zsh"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# ASDF
source /opt/homebrew/opt/asdf/libexec/asdf.sh
