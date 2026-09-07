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
    (
      local tmpdir
      tmpdir="$(mktemp -d)"
      trap 'rm -rf "$tmpdir"' EXIT
      curl -fsSL "$url" | tar -xJ -C "$tmpdir"
      sudo install -m 0755 "$tmpdir/shellcheck-${scversion}/shellcheck" /usr/local/bin/shellcheck
    )
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

# Host comes from GOPROXY_NETRC_HOST (set in ~/.zshrc.local); no-op when unset.
ensure_goproxy_netrc(){
  local proxy_host="${GOPROXY_NETRC_HOST:-}"
  if [[ -z "$proxy_host" ]]; then
    log_helpers "GOPROXY_NETRC_HOST not set; skipping goproxy netrc entry"
    return 0
  fi
  if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    log_helpers "GITHUB_TOKEN not set; skipping goproxy netrc entry"
    return 0
  fi
  local netrc_path="${HOME}/.netrc"
  if [[ -f "$netrc_path" ]] && grep -q "$proxy_host" "$netrc_path"; then
    log_helpers "goproxy netrc entry detected; skipping update"
    return 0
  fi
  echo "machine $proxy_host login nobody password ${GITHUB_TOKEN}" >> "$netrc_path"
  log_helpers "goproxy netrc entry configured"
}

codespaces_setup(){
    log_helpers "*** Codespaces setup ***"
    install_if_missing tmux bash -c 'sudo apt-get update -y && sudo apt-get install -y tmux'
    install_if_missing bat sudo apt-get install -y bat
    install_if_missing rg sudo apt-get install -y ripgrep
    install_if_missing nvim sudo apt-get install -y neovim
    install_if_missing fzf sudo apt-get install -y fzf
    codespaces_install_shellcheck
    log_helpers "*** Codespaces setup done ***"
}

local_setup(){
    log_helpers "*** Local setup ***"
    ensure_goproxy_netrc
    install_if_missing tmux brew install tmux
    install_if_missing bat brew install bat
    install_if_missing rg brew install ripgrep
    install_if_missing nvim brew install neovim
    install_if_missing fzf brew install fzf
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
  section "Configuring Neovim"
  command -v nvim >/dev/null 2>&1 || { err "Neovim installation failed"; return 1; }
  if [[ ! -f "$HOME/.config/nvim/init.lua" && ! -f "$HOME/.config/nvim/init.vim" ]]; then
    mkdir -p "$HOME/.config/nvim"
    cat > "$HOME/.config/nvim/init.lua" <<'EOF'
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
EOF
  fi
  log "Neovim configured"
}
