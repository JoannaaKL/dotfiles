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
    scversion="latest"
    wget -qO- "https://github.com/koalaman/shellcheck/releases/download/${scversion?}/shellcheck-${scversion?}.linux.x86_64.tar.xz" | tar -xJv
    cp "shellcheck-${scversion}/shellcheck" /usr/bin/
    shellcheck --version
}

local_install_shellcheck() {
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