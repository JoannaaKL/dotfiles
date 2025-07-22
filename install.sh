#!/bin/bash
script_dir=$(dirname "$(readlink -f "$0")")
delimiter="***********"

# Source helper functions
source "$script_dir/helpers.sh"
create_symlinks() {
  # Get the directory in which this script lives.
  echo "$delimiter Creating symlinks $delimiter"
  echo "$script_dir"
  # Get a list of all files in this directory that start with a dot.
  files=$(find . -maxdepth 1 -type f -name ".*")

  # Create a symbolic link to each file in the home directory.
  for file in $files; do
    name="$(basename "$file")"
    if [ -n "${CODESPACES}" ]; then
      echo "Removing existing $name"
      rm -rf ~/"$name"
    fi
    echo "Creating symlink to $name in home directory."
    ln -s "$script_dir/$name" ~/"$name"
  done
  echo "$delimiter Creating symlinks done $delimiter"
}

install_fonts() {
  if [ ! -d "$HOME/fonts" ]; then
    echo "$delimiter Installing fonts $delimiter"
    FONT_DIR="$HOME/fonts"
    git clone https://github.com/powerline/fonts.git "$FONT_DIR" --depth=1
    cd "$FONT_DIR" || exit
    ./install.sh
    cd ..
    rm -rf "$FONT_DIR"
    echo "$delimiter Installing fonts done $delimiter"
  fi
}

install_spaceship() {
  echo "$delimiter Setting up the Spaceship theme $delimiter"
  ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
  
  if [ -d "$ZSH_CUSTOM/themes/spaceship-prompt" ]; then
    echo "Spaceship theme $ALREADY_INSTALLED_MSG"
    echo "$delimiter Setting up the Spaceship theme done $delimiter"
    return 0
  fi
  
  echo "Installing Spaceship theme..."
  git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1
  ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
  echo "$delimiter Setting up the Spaceship theme done $delimiter"
}

install_nvim() {
  echo "$delimiter Setting up nvim $delimiter"
  
  # Check if nvim is already installed
  if command -v nvim &> /dev/null; then
    echo "nvim $ALREADY_INSTALLED_MSG"
    echo "$delimiter Setting up nvim done $delimiter"
    return 0
  fi
  
  if [ -n "${CODESPACES}" ]; then
    mkdir -p ~/bin
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
    chmod u+x nvim.appimage
    ./nvim.appimage --appimage-extract

    ln -s "$(pwd)/squashfs-root/usr/bin/nvim" ~/bin/nvim
  else
    brew install neovim
  fi
  echo "$delimiter Setting up nvim done $delimiter"
}

install_git_delta() {
  if [ -z "${CODESPACES}" ]; then
    brew install git-delta
  else
    curl -sS https://webi.sh/delta | sh
    ln -s "$(pwd)/.local/share/delta" ".local/share/delta"
  fi
}

install_gh_copilot() {
  echo "$delimiter Installing GitHub Copilot CLI extension $delimiter"
  
  # Check if gh CLI is installed first
  if ! command -v gh &> /dev/null; then
    echo "GitHub CLI (gh) is not installed. Please install it first."
    return 1
  fi
  
  # Check if the extension is already installed
  if gh extension list | grep -q "github/gh-copilot"; then
    echo "GitHub Copilot CLI extension $ALREADY_INSTALLED_MSG"
  else
    echo "Installing GitHub Copilot CLI extension..."
    if ! gh extension install github/gh-copilot; then
      echo "Failed to install GitHub Copilot CLI extension"
      return 1
    fi
    echo "GitHub Copilot CLI extension installed successfully"
  fi
  
  echo "$delimiter Installing GitHub Copilot CLI extension done $delimiter"
}

merge_zsh_config(){
  echo "Copying contents of .zshrc from $HOME/.zshrc to $script_dir/.zshrc"
  if [[ -e "$HOME/.zshrc" ]]; then
    less "$HOME/.zshrc" >> "$script_dir/.zshrc"
  fi
}

setup
install_nvim
install_gh_copilot
create_symlinks
install_fonts
install_spaceship
SPACESHIP_CONFIG="$(pwd)/.spaceship.zsh"
PATH="$HOME/.local/bin:$PATH"
export SPACESHIP_CONFIG
export PATH
