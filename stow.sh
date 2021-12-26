#!/bin/sh

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [[ "$#" -eq 0 ]]; then
  echo "[ERROR] Please specify one or more dotfiles to link"
  echo "[ERROR] Specify 'all' as first arg to link everything"
  exit 1
fi

TO_STOW=()

# Determining which directories to stow
if [[ "$1" == "all" ]]; then
  for f in $SCRIPT_DIR/*; do
    TO_STOW+=(basename $f)
  done
else
  for dir in "$@"; do
    if [ ! -d "$SCRIPT_DIR/$dir" ]; then
      echo "[WARN] $dir doesn't exist. Skipping."
    else
      TO_STOW+=($dir)
    fi
  done
fi

# Stow directory
for dir in "${TO_STOW[@]}"; do
  echo "[INFO] Stowing $dir"
  stow -t $HOME $dir
done
