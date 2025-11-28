# Dotfiles

[![Shell Lint](https://github.com/JoannaaKL/dotfiles/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/JoannaaKL/dotfiles/actions/workflows/shellcheck.yml)

Opinionated workstation + Codespaces bootstrap.

## Features

- Idempotent `install.sh` with:
  - Environment detection (local vs Codespaces)
  - Neovim install + minimal config bootstrap
  - Spaceship ZSH theme setup
  - Meslo Nerd Font install (skips if present)
  - Safe dotfile symlinking (backs up existing files)
  - Optional GitHub Copilot CLI extension
  - Delta (syntax highlighted pager) install
- Managed Codespaces SSH config export (`export_codespace_cfg`)
- Codespace cleanup utility (`clean-codespaces.sh --dry-run`)
- Shell linting via GitHub Actions + local `make lint`.

## Libraries and Packages

### Shell & Terminal

- [Oh My Zsh](https://ohmyz.sh/) - Zsh framework for managing configuration
- [Spaceship Prompt](https://github.com/spaceship-prompt/spaceship-prompt) - Minimalistic and powerful Zsh prompt
- [tmux](https://github.com/tmux/tmux) - Terminal multiplexer
- [fzf](https://github.com/junegunn/fzf) - Command-line fuzzy finder

### Editors

- [Neovim](https://neovim.io/) - Hyperextensible Vim-based text editor

### CLI Utilities

- [bat](https://github.com/sharkdp/bat) - A cat clone with syntax highlighting
- [ripgrep](https://github.com/BurntSushi/ripgrep) - Fast line-oriented search tool
- [git-delta](https://github.com/dandavison/delta) - Syntax-highlighting pager for git
- [GitHub CLI](https://cli.github.com/) - GitHub's official command-line tool
- [GitHub Copilot CLI](https://github.com/github/gh-copilot) - AI-powered CLI extension for GitHub CLI

### Fonts

- [Meslo Nerd Font](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/Meslo) - Patched font with icons from Nerd Fonts

### Development Tools

- [ShellCheck](https://github.com/koalaman/shellcheck) - Static analysis tool for shell scripts

### Oh My Zsh Plugins

- [git](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git) - Git aliases and functions
- [alias-finder](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/alias-finder) - Find existing aliases
- [kubectl](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/kubectl) - Kubectl autocompletion and aliases
- [docker](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/docker) - Docker autocompletion and aliases
- [gh](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/gh) - GitHub CLI autocompletion

## Setup Instructions

### Prerequisites

- **macOS**: [Homebrew](https://brew.sh/) installed
- **Linux/Codespaces**: `apt-get` package manager available
- **Both**: `git`, `curl`, and `zsh` installed

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/JoannaaKL/dotfiles.git
   cd dotfiles
   ```

2. Run the install script:

   ```bash
   ./install.sh
   ```

3. Start a new shell or source the configuration:

   ```bash
   source ~/.zshrc
   ```

### What the Install Script Does

The `install.sh` script performs the following actions:

1. **Preflight checks** - Verifies required tools (`git`, `curl`) are available
2. **Environment-specific setup**:
   - **Codespaces**: Installs `tmux`, `bat`, `ripgrep`, `neovim`, and `shellcheck` via `apt-get`
   - **Local (macOS)**: Installs the same tools via Homebrew
3. **Symlinks dotfiles** - Creates symlinks for configuration files (`.gitconfig`, `.zshrc`, `.tmux.conf`, etc.) with automatic backup of existing files
4. **Installs fonts** - Downloads and installs Meslo Nerd Font
5. **Sets up Spaceship theme** - Clones and configures the Spaceship Zsh theme

### Manual Setup (Optional)

If you prefer to install components individually:

- **Oh My Zsh**: Follow the [installation guide](https://ohmyz.sh/#install)
- **Spaceship Prompt**: See the [installation instructions](https://spaceship-prompt.sh/getting-started/)
- **Nerd Fonts**: Download from [Nerd Fonts releases](https://github.com/ryanoasis/nerd-fonts/releases)

## Linting Shell Scripts

Run locally:

```bash
make lint
```

The CI workflow runs automatically on pushes and pull requests touching any `*.sh` files.

## Codespaces SSH Config Export

```bash
./export_codespace_cfg
```

This inserts/updates a managed block in `~/.ssh/config` between markers:

```text
# >>> codespaces (managed) >>>
# <<< codespaces (managed) <<<
```

## Cleaning Shutdown Codespaces

Preview:

```bash
./clean-codespaces.sh --dry-run
```

Execute deletions:

```bash
./clean-codespaces.sh
```

## Future Ideas

- Brewfile / apt manifest abstraction
- Tmux plugin manager integration
- Advanced Neovim config module
