sudo apt update
sudo apt install -y git zsh libatomic1

sudo chsh -s "$(which zsh)" ${username}

HOME_DIR="/home/${username}"
DOTFILES_DIR="$HOME_DIR/.dotfiles"

sudo -u ${username} git clone https://github.com/JFenstermacher/dotfiles $DOTFILES_DIR
sudo -u ${username} $DOTFILES_DIR/bootstrap
