#!/bin/sh

# PERSONAL_DIR contains computer specific configurations
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

##################################################################
# OPTIONS
##################################################################

setopt autocd extendedglob nomatch
setopt interactive_comments
setopt appendhistory

unsetopt BEEP

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

# Load favorite theme
zsh_load_theme "romkatv/powerlevel10k"

##################################################################
# TOOL SETUPS
##################################################################

# Powerlevel10k customizations
[ -f $ZDOTDIR/.p10k.zsh ] && source $ZDOTDIR/.p10k.zsh

# FZF
[ -f "$ZDOTDIR/.fzf.zsh" ] && source "$ZDOTDIR/.fzf.zsh"

# BREW
brew_setup

# ASDF
asdf_setup 

# PDM
pdm_setup  
