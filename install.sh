#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Portable script directory resolution (macOS + Linux)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPT_DIR

# Source helper functions (defines ALREADY_INSTALLED_MSG & setup)
source "$SCRIPT_DIR/helpers.sh"

# ------------- Logging helpers -------------
log(){ printf "\033[1;34m[dotfiles]\033[0m %s\n" "$*"; }
warn(){ printf "\033[1;33m[warn]\033[0m %s\n" "$*"; }
err(){ printf "\033[1;31m[err]\033[0m %s\n" "$*" >&2; }
section(){ printf "\n\033[1;32m== %s ==\033[0m\n" "$*"; }
trap 'err "Failed near line $LINENO"' ERR

# ------------- Config -------------
DOTFILES=(.gitconfig .gitignore .gitmessage .zshrc .tmux.conf .spaceship.zsh)

symlink_dotfiles(){
  section "Symlinking dotfiles"
  for name in "${DOTFILES[@]}"; do
    local source_path="$SCRIPT_DIR/$name"
    local target_path="$HOME/$name"
    [[ -e "$source_path" ]] || { warn "Skipping missing $source_path"; continue; }
    if [[ -L "$target_path" && "$(readlink "$target_path")" == "$source_path" ]]; then
      log "$name already linked"; continue; fi
    if [[ -e "$target_path" && ! -L "$target_path" ]]; then
      local backup
      backup="${target_path}.bak.$(date +%Y%m%d%H%M%S)"
      mv "$target_path" "$backup"
      log "Backed up $target_path -> $backup"
    fi
    ln -sfn "$source_path" "$target_path"
    log "Linked $target_path -> $source_path"
  done
}

install_fonts(){
  section "Installing fonts (Meslo Nerd Font)"
  local dest="$HOME/.local/share/fonts"
  mkdir -p "$dest"
  # Detect existing Meslo Nerd Font via glob
  (
    shopt -s nullglob nocaseglob 2>/dev/null || true
    local meslo_candidates=("$dest"/*Meslo*"Nerd Font"*.ttf)
    if (( ${#meslo_candidates[@]} > 0 )); then
      log "Meslo Nerd Font already present"
      exit 0
    fi
  )
  if [[ $? -eq 0 ]]; then
    return 0
  fi
  local tmp_zip
  tmp_zip="$(mktemp)"
  if curl -fsSL -o "$tmp_zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip; then
    unzip -oq "$tmp_zip" -d "$dest"
    command -v fc-cache >/dev/null && fc-cache -f >/dev/null 2>&1 || true
    log "Fonts installed"
  else
    warn "Font download failed; skipping"
  fi
}

install_spaceship(){
  section "Setting up Spaceship theme"
  local zsh_custom="$HOME/.oh-my-zsh/custom"
  local theme_dir="$zsh_custom/themes/spaceship-prompt"
  if [[ -d "$theme_dir" ]]; then
    log "Spaceship theme $ALREADY_INSTALLED_MSG"; return 0; fi
  git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$theme_dir" --depth=1
  ln -sfn "$theme_dir/spaceship.zsh-theme" "$zsh_custom/themes/spaceship.zsh-theme"
  log "Spaceship theme installed"
}

preflight(){
  section "Preflight checks"
  local required=(git curl)
  for c in "${required[@]}"; do
    command -v "$c" >/dev/null 2>&1 || { err "Missing required tool: $c"; exit 1; }
  done
  log "Preflight OK"
}

main(){
  preflight
  setup             # environment-specific base install (helpers.sh)
  symlink_dotfiles
  install_fonts
  install_spaceship
  export SPACESHIP_CONFIG="$HOME/.spaceship.zsh"
  export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
  section "Bootstrap complete"
  log "Start a new shell or run: source ~/.zshrc"
}

main "$@"
