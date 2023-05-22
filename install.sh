#!/bin/bash

export USERNAME=`whoami`
sudo chsh -s $(which zsh) $USERNAME

create_symlinks() {
    # Get the directory in which this script lives.
    script_dir=$(dirname "$(readlink -f "$0")")
    echo $script_dir	
    # Get a list of all files in this directory that start with a dot.
    files=$(find -maxdepth 1 -type f -name ".*")

    # Create a symbolic link to each file in the home directory.
    for file in $files; do
        name=$(basename $file)
        echo "Creating symlink to $name in home directory."
        rm -rf ~/$name
        ln -s $script_dir/$name ~/$name
    done
}

install_fonts() {
    echo "Installing fonts."
    FONT_DIR="$HOME/fonts"
    git clone https://github.com/powerline/fonts.git $FONT_DIR --depth=1
    cd $FONT_DIR
    ./install.sh
    cd ..
    rm -rf $FONT_DIR
}

create_symlinks
install_fonts

echo "Setting up the Spaceship theme."
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

if [ ! -d "$ZSH_CUSTOM/themes/spaceship-prompt" ]
then
    git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1
    ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme" 
fi

