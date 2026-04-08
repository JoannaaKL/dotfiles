# ---------- PATH ----------
export GOPATH="$HOME/go"
export PATH="$HOME/.local/bin:$HOME/bin:$GOPATH/bin:/usr/local/opt/mysql-client/bin:/usr/local/bin:$PATH"

# ---------- Go ----------
export GOPROXY=https://goproxy.githubapp.com/mod,https://proxy.golang.org/,direct
export GOPRIVATE=
export GONOPROXY=
export GONOSUMDB='github.com/github/*'

# ---------- Oh My Zsh ----------
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="spaceship"
ENABLE_CORRECTION="true"

plugins=(git
         alias-finder
	 kubectl
         docker
	 gh
	 fzf
	)

source $ZSH/oh-my-zsh.sh

# ---------- Functions ----------
# Interactive git diff browser (https://medium.com/@GroundControl/better-git-diffs-with-fzf-89083739a9cb)
fd() {
  preview="git diff $@ --color=always -- {-1}"
  git diff $@ --name-only | fzf -m --ansi --preview $preview
}

# ---------- Aliases ----------
alias g="git"
alias cl="clear"
alias ccreate="gh codespace create"
alias cdelete="gh codespace delete"
alias clist="gh codespace list"
alias copen="gh codespace code"
alias cssh="gh codespace ssh --config"
alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

# ── Sparse checkout ──
alias sclone="sparse-checkout.sh clone"
alias sconvert="sparse-checkout.sh convert"
alias sbulk="sparse-checkout.sh bulk-convert"
alias slist="sparse-checkout.sh list"
alias sadd="sparse-checkout.sh add"
alias sremove="sparse-checkout.sh remove"
alias spull="sparse-checkout.sh pull"
alias sbpull="sparse-checkout.sh bulk-pull"

export SPACESHIP_CONFIG="$HOME/.spaceship.zsh"
export EDITOR=nvim
export GPG_TTY=$(tty)
export JETBRAINS_LICENSE_SERVER=https://github.jetbrains-ide-services.com
# Set SAVE_RESULTS_DIR in a local, gitignored file (e.g. ~/.zshrc.local)

# ---------- Goproxy netrc (idempotent) ----------
if [[ -n "${GITHUB_TOKEN:-}" ]] && ! grep -q "goproxy.githubapp.com" "$HOME/.netrc" 2>/dev/null; then
  echo "machine goproxy.githubapp.com login nobody password $GITHUB_TOKEN" >> "$HOME/.netrc"
fi

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# ---------- Local overrides (not tracked in git) ----------
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
