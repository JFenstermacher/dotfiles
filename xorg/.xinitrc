#!/bin/sh

if [ -d /etc/X11/xinit/xinitrc.d ]; then
  for f in /etc/X11/xinit/xinitrc.d/*; do
    [ -x "$f" ] && source "$f"
  done

  unset f
fi

# On XMONAD startup, bind CapsLock to Control_R
KEYBINDING_REMAP_FILE="$HOME/.Xmodmap"

if [ -f $KEYBINDING_REMAP_FILE ]; then
  xmodmap $KEYBINDING_REMAP_FILE
fi

exec xmonad
