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
    install_if_missing tmux sudo apt-get update -y && sudo apt-get install -y tmux
    install_if_missing bat sudo apt-get install -y bat
    install_if_missing rg sudo apt-get install -y ripgrep
    codespaces_install_shellcheck
    log_helpers "*** Codespaces setup done ***"
}

local_setup(){
    log_helpers "*** Local setup ***"
    install_if_missing tmux brew install tmux
    install_if_missing bat brew install bat
    install_if_missing rg brew install ripgrep
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