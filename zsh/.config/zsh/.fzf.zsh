# Setup fzf
# ---------

FZF_DIR="$HOME/.fzf"

# Clone FZF to .fzf directory
if command -v git &> /dev/null && [[ ! -d "$FZF_DIR" ]]; then
  git clone https://github.com/junegunn/fzf.git $FZF_DIR
fi

# Append fzf bin to PATH, and source completions
if [[ -f "$FZF_DIR" ]]; then
  if [[ ! "$PATH" == *$HOME/.fzf/bin* ]]; then
    export PATH="${PATH:+${PATH}:}$HOME/.fzf/bin"
  fi

  # Auto-completion
  # ---------------
  [[ $- == *i* ]] && source "$HOME/.fzf/shell/completion.zsh" 2> /dev/null

  # Key bindings
  # ------------
  source "$HOME/.fzf/shell/key-bindings.zsh"
fi
