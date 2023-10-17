# If you come from bash you might have to change your $PATH.

export PATH=$HOME/bin:/usr/local/bin:$PATH
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
export GOPROXY=https://goproxy.githubapp.com/mod,https://proxy.golang.org/,direct
export GOPRIVATE=
export GONOPROXY=
export GONOSUMDB='github.com/github/*'
# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
export PATH="/usr/local/bin:$PATH"

ZSH_THEME="spaceship"
# ssh-add ~/.ssh/id_rsa

ENABLE_CORRECTION="true"

plugins=(git
         alias-finder
	 kubectl
         docker
	 gh
	)

source $ZSH/oh-my-zsh.sh

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
alias g="git"
alias ccreate="gh codespace create"
alias cdelete="gh codespace delete"
alias clist="gh codespace list"
alias copen="gh codespace code"
alias cssh="gh codespace ssh --config"
export PATH="/usr/local/opt/mysql-client/bin:$PATH"
export SPACESHIP_CONFIG="$HOME/.spaceship.zsh"
export EDITOR=nvim
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
echo "machine goproxy.githubapp.com login nobody password $GITHUB_TOKEN" >> $HOME/.netrc
export GPG_TTY=$(tty)
