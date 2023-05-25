#!/bin/bash
set -e
create_symlinks() {
    # Get the directory in which this script lives.
    script_dir=$(dirname "$(readlink -f "$0")")
    echo $script_dir	
    # Get a list of all files in this directory that start with a dot.
    files=$(find . -maxdepth 1 -type f -name ".*")

    # Create a symbolic link to each file in the home directory.
    for file in $files; do
        name=$(basename $file)
        echo "Creating symlink to $name in home directory."
        if [ -n "${CODESPACES}" ]; then
            echo "Removing existing $name"
            rm -rf ~/$name
        fi
        ln -s $script_dir/$name ~/$name
    done
}

install_fonts() {
    if [ ! -d "$HOME/fonts" ]; then
        echo "Installing fonts."    
        FONT_DIR="$HOME/fonts"
        git clone git@github.com:powerline/fonts.git $FONT_DIR --depth=1
        cd $FONT_DIR
        ./install.sh
        # cd ..
        # rm -rf $FONT_DIR
    fi
}

install_spaceship() {
    ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
    if [ ! -d "$ZSH_CUSTOM/themes/spaceship-prompt" ]; then
        echo "Setting up the Spaceship theme."
        git clone git@github.com:spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1
        ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme" 
    fi
}

create_symlinks
install_fonts
install_spaceship
