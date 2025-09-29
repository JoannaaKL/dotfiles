#!/bin/bash

# Helper functions for dotfiles installation

# Constants
ALREADY_INSTALLED_MSG="is already installed"

codespaces_setup(){
	echo "***Codespaces setup***"
    merge_zsh_config
    install "tmux" "apt install tmux"
	install "bat" "apt install bat"
	install "rg" "apt-get install ripgrep"
    codespaces_install_shellcheck
	echo "***Codespaces setup done***"
}

local_setup(){
	echo "***Local setup***"
	install "tmux" "brew install tmux"
	install "bat" "brew install bat"
    install "rg" "brew install ripgrep"
    local_install_shellcheck
	echo "***Local setup done***"
}

codespaces_install_shellcheck() {
    if command -v shellcheck &> /dev/null; then
        echo "shellcheck $ALREADY_INSTALLED_MSG"
        return
    fi

    scversion="latest"
    tmp_dir=$(mktemp -d)
    (
        cd "$tmp_dir" || exit 1
        wget -qO- "https://github.com/koalaman/shellcheck/releases/download/${scversion?}/shellcheck-${scversion?}.linux.x86_64.tar.xz" | tar -xJ
        cp "shellcheck-${scversion}/shellcheck" /usr/bin/
    )
    rm -rf "$tmp_dir"
    shellcheck --version
}

local_install_shellcheck() {
   if command -v shellcheck &> /dev/null; then
       echo "shellcheck $ALREADY_INSTALLED_MSG"
       return
   fi

   brew install shellcheck
}

install(){
    pkg_name=$1
    cmd_if_not_installed=$2	
    if command -v "$pkg_name" &> /dev/null
    then
        echo "$pkg_name $ALREADY_INSTALLED_MSG"
    else
        echo "$pkg_name is not installed, installing..."
	eval "$cmd_if_not_installed"
    fi
}

setup(){
    if [ -n "$CODESPACES" ]; then
        codespaces_setup
    else
        local_setup
    fi
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