#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Helper functions for dotfiles installation
ALREADY_INSTALLED_MSG="is already installed"

log_helpers(){ printf "[helpers] %s\n" "$*"; }

# Generic install wrapper: install_if_missing <binary> <command...>
install_if_missing(){
    local bin="$1"; shift
    if command -v "$bin" >/dev/null 2>&1; then
        log_helpers "$bin $ALREADY_INSTALLED_MSG"
        return 0
    fi
    log_helpers "Installing $bin"
    "$@"
}

codespaces_install_shellcheck(){
    local scversion="v0.10.0" # pinned for reproducibility
    if command -v shellcheck >/dev/null 2>&1; then
        log_helpers "shellcheck $ALREADY_INSTALLED_MSG"; return 0; fi
    local url="https://github.com/koalaman/shellcheck/releases/download/${scversion}/shellcheck-${scversion}.linux.x86_64.tar.xz"
    local tmpdir
    tmpdir="$(mktemp -d)"
    curl -fsSL "$url" | tar -xJ -C "$tmpdir"
    sudo install -m 0755 "$tmpdir/shellcheck-${scversion}/shellcheck" /usr/local/bin/shellcheck
    shellcheck --version
}

local_install_shellcheck(){
    if command -v shellcheck >/dev/null 2>&1; then
        log_helpers "shellcheck $ALREADY_INSTALLED_MSG"; return 0; fi
    if command -v brew >/dev/null 2>&1; then
        brew install shellcheck
    else
        log_helpers "brew not found; skipping shellcheck"
    fi
}

codespaces_setup(){
    log_helpers "*** Codespaces setup ***"
    install_if_missing tmux bash -c 'sudo apt-get update -y && sudo apt-get install -y tmux'
    install_if_missing bat sudo apt-get install -y bat
    install_if_missing rg sudo apt-get install -y ripgrep
    install_if_missing nvim sudo apt-get install -y neovim
    codespaces_install_shellcheck
    log_helpers "*** Codespaces setup done ***"
}

local_setup(){
    log_helpers "*** Local setup ***"
    install_if_missing tmux brew install tmux
    install_if_missing bat brew install bat
    install_if_missing rg brew install ripgrep
    install_if_missing rg brew install neovim
    local_install_shellcheck
    log_helpers "*** Local setup done ***"
}

setup(){
    if [[ -n "${CODESPACES:-}" ]]; then
        codespaces_setup
    else
        local_setup
    fi
}

install_neovim(){
  section "Setting up Neovim"
  if command -v nvim >/dev/null 2>&1; then
    log "nvim $ALREADY_INSTALLED_MSG"; return 0; fi
  if [[ -n "${CODESPACES:-}" ]]; then
    mkdir -p "$HOME/bin"
    local nvim_cache_dir="$HOME/.local/share/neovim-appimage"
    mkdir -p "$nvim_cache_dir"
    local appimage_url="https://github.com/neovim/neovim/releases/latest/download/nvim.appimage"
    local appimage_path="$nvim_cache_dir/nvim.appimage"
    if [[ ! -f "$appimage_path" ]]; then
      curl -fsSL -o "$appimage_path" "$appimage_url"
      chmod +x "$appimage_path"
    fi
    if [[ ! -d "$nvim_cache_dir/squashfs-root" ]]; then
      (cd "$nvim_cache_dir" && "$appimage_path" --appimage-extract >/dev/null)
    fi
    ln -sfn "$nvim_cache_dir/squashfs-root/usr/bin/nvim" "$HOME/bin/nvim"
  else
    command -v brew >/dev/null 2>&1 || { err "Homebrew is required to install neovim"; return 1; }
    brew install neovim
  fi
  if [[ ! -f "$HOME/.config/nvim/init.lua" && ! -f "$HOME/.config/nvim/init.vim" ]]; then
    mkdir -p "$HOME/.config/nvim"
    cat > "$HOME/.config/nvim/init.lua" <<'EOF'
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
EOF
  fi
  log "Neovim installed"
}

install_git_delta(){
  section "Installing git delta"
  if command -v delta >/dev/null 2>&1; then
    log "delta $ALREADY_INSTALLED_MSG"; return 0; fi
  if [[ -n "${CODESPACES:-}" ]]; then
    curl -fsSL https://github.com/dandavison/delta/releases/latest/download/delta-linux.tar.gz -o /tmp/delta.tgz || { warn "delta download failed"; return 0; }
    tar -xzf /tmp/delta.tgz -C /tmp
    local bin_path
    bin_path="$(find /tmp -maxdepth 2 -type f -name delta | head -n1)"
    install -m 0755 "$bin_path" "$HOME/bin/delta"
  else
    brew install git-delta
  fi
}

install_gh_copilot(){
  section "Installing GitHub Copilot CLI extension"
  if ! command -v gh >/dev/null 2>&1; then
    warn "gh not installed; skipping Copilot extension"; return 0; fi
  if gh extension list | grep -q "github/gh-copilot"; then
    log "GitHub Copilot CLI extension $ALREADY_INSTALLED_MSG"; return 0; fi
  gh extension install github/gh-copilot || warn "Failed to install gh-copilot extension"
}