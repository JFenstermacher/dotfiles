# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Useful functions
source $ZDOTDIR/zsh-functions

PLUGINS=(
  "zsh-users/zsh-autosuggestions"
  "zsh-users/zsh-syntax-highlighting"
)

zsh_add_plugins "${PLUGINS[@]}"

# Aliases
source $ZDOTDIR/zsh-aliases

# Load favorite theme
zsh_load_theme "romkatv/powerlevel10k"

# Powerlevel10k customizations
[[ ! -f $ZDOTDIR/.p10k.zsh ]] || source $ZDOTDIR/.p10k.zsh

# FZF
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'

[ -f $ZDOTDIR/.fzf.zsh ] && source $ZOTDIR/.fzf.zsh
