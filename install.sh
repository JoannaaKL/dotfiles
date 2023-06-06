#!/bin/bash
set -e
script_dir=$(dirname "$(readlink -f "$0")")
delimiter="***********"
create_symlinks() {
  # Get the directory in which this script lives.
  echo "$delimiter Creating symlinks $delimiter"
  echo $script_dir
  # Get a list of all files in this directory that start with a dot.
  files=$(find . -maxdepth 1 -type f -name ".*")

  # Create a symbolic link to each file in the home directory.
  for file in $files; do
    name=$(basename $file)
    if [ -n "${CODESPACES}" ]; then
      echo "Removing existing $name"
      rm -rf ~/$name
    fi
    if [ ! -e $script_dir/$name ]; then
      echo "Creating symlink to $name in home directory."
      ln -s $script_dir/$name ~/$name
    fi
  done
  echo "$delimiter Creating symlinks done $delimiter"
}

install_fonts() {
  if [ ! -d "$HOME/fonts" ]; then
    echo "$delimiter Installing fonts $delimiter"
    FONT_DIR="$HOME/fonts"
    git clone https://github.com/powerline/fonts.git $FONT_DIR --depth=1
    cd $FONT_DIR
    ./install.sh
    cd ..
    rm -rf $FONT_DIR
    echo "$delimiter Installing fonts done $delimiter"
  fi
}

install_spaceship() {
  ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
  if [ ! -d "$ZSH_CUSTOM/themes/spaceship-prompt" ]; then
    echo "$delimiter Setting up the Spaceship theme $delimiter"
    git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1
    ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
    echo "$delimiter Setting up the Spaceship theme done $delimiter"
  fi
}

install_fzf() {
  if [ ! -d ~/.fzf ]; then
    echo "$delimiter Setting up fzf $delimiter"
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --completion --no-key-bindings --no-update-rc
    echo "$delimiter Setting up fzf done $delimiter"
  fi
}

install_nvim() {
  echo "$delimiter Setting up nvim $delimiter"
  if [ -n "${CODESPACES}" ]; then
    mkdir -p ~/bin
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
    ./nvim.appimage --appimage-extract
    ./squashfs-root/AppRun --version

    sudo mv squashfs-root /
    sudo ln -s /squashfs-root/AppRun /usr/bin/nvim
  else
    brew install neovim
  fi
  echo "$delimiter Setting up nvim done $delimiter"
}

install_fzf
# install_nvim
create_symlinks
install_fonts
install_spaceship
export SPACESHIP_CONFIG="$(pwd)/.spaceship.zsh"
