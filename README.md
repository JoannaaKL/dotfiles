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

## Quick Start

Clone then run:

```bash
./install.sh
```

Start a new shell (or `source ~/.zshrc`) to pick up changes.

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
