export ZDOTDIR=$HOME/.config/zsh

if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then exec startx; fi

source $ZDOTDIR/.zshrc
