#!/bin/bash
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
    echo "Creating symlink to $name in home directory."
    ln -s $script_dir/$name ~/$name
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

install_nvim() {
  echo "$delimiter Setting up nvim $delimiter"
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

install_fx() {
 if [ -n "${CODESPACES}" ]; then
   curl https://fx.wtf/install.sh | sh
 else
   brew install fx
 fi;
}

install_git_delta() {
  if [ ! -n "${CODESPACES}" ]; then
    brew install git-delta
  else
    curl -sS https://webi.sh/delta | sh
    ln -s "$(pwd)/.local/share/delta .local/share/delta"
  fi
}
merge_zsh_config(){
  echo "Copying contents of .zshrc from $HOME/.zshrc to $script_dir/.zshrc"
  if [[ -n "$CODESPACES" && -e "$HOME/.zshrc" ]]; then
    less "$HOME/.zshrc" >> "$script_dir/.zshrc"
  fi
}

codespaces_setup(){
	if [ -n "$CODESPACES" ]; then
		echo "***Codespaces setup***"
		install "tmux" "apt install tmux"
		install "bat" "apt install bat"
		install "rg" "apt-get install ripgrep"
		echo "***Codespaces setup done***"
	fi;
}

local_setup(){
	if [ ! -n "$CODESPACES" ]; then
		echo "***Local setup***"
		install "tmux" "brew install tmux"
		install "bat" "brew install bat"
		install "rg" "brew install ripgrep"
		echo "***Local setup done***"
	fi;
}

install(){
    pkg_name=$1
    cmd_if_not_installed=$2	
    if command -v $pkg_name &> /dev/null
    then
        echo "$pkg_name is installed"
    else
        echo "$pkg_name is not installed, installing..."
	eval $cmd_if_not_installed
    fi
}

merge_zsh_config
local_setup
codespaces_setup
install_nvim
create_symlinks
install_fonts
install_spaceship
export SPACESHIP_CONFIG="$(pwd)/.spaceship.zsh"
export PATH="$HOME/.local/bin:$PATH"
