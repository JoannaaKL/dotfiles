# Dotfiles

Personal dotfiles and development environment setup for both local machines and GitHub Codespaces.

## Overview

This repository automates the setup of a development environment by:
- Creating symlinks for configuration files (dotfiles)
- Installing essential development tools
- Configuring zsh with oh-my-zsh and spaceship theme
- Setting up tmux, neovim, and other productivity tools
- Managing GitHub Codespaces configurations

## Quick Start

```bash
git clone https://github.com/JoannaaKL/dotfiles.git
cd dotfiles
./install.sh
```

The installation script automatically detects whether you're running in GitHub Codespaces or a local environment and adjusts the installation accordingly.

## What Gets Installed/Configured

### Development Tools
- **tmux** - Terminal multiplexer
- **bat** - Cat clone with syntax highlighting
- **ripgrep (rg)** - Fast text search tool
- **shellcheck** - Shell script linter
- **neovim** - Modern vim-based editor
- **git-delta** - Enhanced git diff viewer
- **GitHub Copilot CLI** - AI-powered command line assistant

### Shell & Theme
- **oh-my-zsh** - Zsh framework
- **Spaceship prompt** - Minimalistic zsh theme
- **Powerline fonts** - Enhanced terminal fonts

### Configuration Files (Dotfiles)
- `.zshrc` - Zsh configuration with aliases and plugins
- `.tmux.conf` - Tmux configuration
- `.gitconfig` - Git configuration with useful aliases
- `.spaceship.zsh` - Spaceship theme configuration
- `.gitignore` - Global gitignore patterns
- `.gitmessage` - Git commit message template

**Note**: In GitHub Codespaces, any existing `.zshrc` will be merged with the repository's `.zshrc` to preserve existing configurations.

## Prerequisites

### Local Environment
- **macOS** with Homebrew installed
- **Git** installed
- **GitHub CLI (gh)** for Copilot functionality (optional)

### GitHub Codespaces
- No additional prerequisites - the script handles package installation via apt

## Environment-Specific Installation

### Local (macOS)
The script uses Homebrew to install packages:
```bash
brew install tmux bat ripgrep neovim git-delta shellcheck
```

### GitHub Codespaces
The script uses apt to install packages and downloads some tools manually:
```bash
apt install tmux bat ripgrep
# Downloads and installs shellcheck and neovim manually
```

## File Descriptions

| File | Description |
|------|-------------|
| `install.sh` | Main installation script that orchestrates the setup |
| `helpers.sh` | Helper functions for package installation and environment detection |
| `clean-codespaces.sh` | Utility to clean up shutdown GitHub Codespaces |
| `export_codespace_cfg` | Manages SSH configuration for GitHub Codespaces |
| `.zshrc` | Zsh configuration with custom aliases and oh-my-zsh setup |
| `.tmux.conf` | Tmux configuration for terminal multiplexing |
| `.gitconfig` | Git configuration with helpful aliases and settings |
| `.spaceship.zsh` | Spaceship prompt theme configuration |
| `.gitignore` | Global gitignore patterns |
| `.gitmessage` | Template for git commit messages |

## Useful Aliases

The `.zshrc` includes several helpful aliases:
- `g` → `git`
- `ccreate` → `gh codespace create`
- `cdelete` → `gh codespace delete`
- `clist` → `gh codespace list`
- `copen` → `gh codespace code`
- `cssh` → `gh codespace ssh --config`

## Codespaces Management

### SSH Configuration
Use `export_codespace_cfg` to update your local SSH config with active codespaces:
```bash
./export_codespace_cfg
```

### Cleanup Shutdown Codespaces
Remove all shutdown codespaces to free up resources:
```bash
./clean-codespaces.sh
```

## Customization

### Adding New Dotfiles
1. Add your dotfile to the repository root (must start with a dot)
2. Run `./install.sh` to create symlinks

### Modifying Tool Installation
Edit the relevant functions in `helpers.sh`:
- `local_setup()` - for local environment packages
- `codespaces_setup()` - for Codespaces environment packages

### Zsh Configuration
Modify `.zshrc` to add new aliases, plugins, or environment variables.

## Troubleshooting

### Permission Issues
If you encounter permission errors, ensure the scripts are executable:
```bash
chmod +x install.sh clean-codespaces.sh export_codespace_cfg
```

### Missing Dependencies
- **Local**: Ensure Homebrew is installed: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- **Codespaces**: The script should handle all dependencies automatically

### GitHub CLI Issues
If GitHub Copilot installation fails:
1. Ensure GitHub CLI is installed: `gh --version`
2. Authenticate with GitHub: `gh auth login`
3. Re-run the installation script

### Internet Connectivity
Some tools are downloaded from the internet during installation:
- **Neovim AppImage** (Codespaces only)
- **git-delta** via webi.sh installer (Codespaces only)
- **Shellcheck** from GitHub releases (Codespaces only)
- **Powerline fonts** from GitHub repository
- **Spaceship theme** from GitHub repository

Ensure you have a stable internet connection during installation.

### Font Issues
If powerline fonts don't display correctly:
1. Restart your terminal after installation
2. Configure your terminal to use a powerline-compatible font
3. In some terminals, you may need to manually select the font

## Contributing

Feel free to fork this repository and customize it for your own dotfiles setup. Pull requests for improvements are welcome!

## License

This project is open source and available for personal use.