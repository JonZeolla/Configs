eval "$(/opt/homebrew/bin/brew shellenv)"

export TERM="xterm-256color"
# Update $? to account for the rightmost non-zero failure in a pipeline
set -o pipefail

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Generic path update
export PATH="${HOME}/bin:${HOME}/.local/bin:/usr/local/bin:/usr/local/sbin:${HOME}/.rd/bin:/usr/local/opt/ruby/bin:${PATH}"

# Go
export GOPATH="${HOME}/go"
export GOROOT="$(brew --prefix golang)/libexec"
export PATH="${PATH}:${GOPATH}/bin:${GOROOT}/bin"

# Python
export RYE_HOME="${HOME}/.rye"
export PATH="${RYE_HOME}/shims:${PATH}"

## AI stuff
export OLLAMA_API_BASE=http://127.0.0.1:11434
export AIDER_AUTO_COMMITS=False
alias aider="aider --model ollama/llama3:70b"


# Path to your oh-my-zsh installation.
export ZSH="${HOME}/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="spaceship"
# General Spaceship configs
SPACESHIP_ANSIBLE_SHOW=false
SPACESHIP_DOCKER_SHOW=false

# Uncomment the following line to use case-sensitive completion.
CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  aws
  brew
  direnv
  git
  golang
  jsontools
  macos
  python
  terraform
  vscode
)

source $ZSH/oh-my-zsh.sh

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='nvim'
else
  export EDITOR='nvim'
fi
alias vi='nvim'

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

## Additional zsh configs
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir vcs virtualenv aws azure kubecontext)
POWERLEVEL9K_KUBECONTEXT_BACKGROUND="006"
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
setopt no_share_history
unsetopt share_history

## Zenable
# Spaceship configs; must be later in this file to find `spaceship`
source "${HOME}/.zsh/zenable-spaceship-section/zenable.plugin.zsh"
spaceship add zenable
source "${HOME}/.zsh/zenable-spaceship-section/aws_custom.plugin.zsh"
spaceship add aws_custom
source "${HOME}/.zsh/zenable-spaceship-section/dir_custom.plugin.zsh"
spaceship add dir_custom
SPACESHIP_PROMPT_ORDER=(
  dir_custom
  git
  exec_time
  async
  zenable
  aws
  aws_custom
  line_sep
  char
)

export monorepo="TODO_change_your_zshrc"
export scripts_dir="${monorepo}/scripts"
function sethost() {
  ln -sf "${monorepo}/services/.envrc.host" "${monorepo}/services/.envrc"
  direnv allow "${monorepo}/services"
}
function setcontainer() {
  ln -sf "${monorepo}/services/.envrc.container" "${monorepo}/services/.envrc"
  direnv allow "${monorepo}/services"
}
function setsandbox() {
  ln -sf "${monorepo}/services/.envrc.sandbox" "${monorepo}/services/.envrc"
  direnv allow "${monorepo}/services"
}

## Configure things
# OS
alias ll="ls -al"
alias cls=clear # C-l
alias calc="bc -l"
alias sha1="openssl sha1"
#alias md5="openssl md5" # Native on macOS
alias thetime="date +\"%T\""
alias thedate="date +\"%Y-%m-%d\""
alias headers="curl -I"
alias brewupgrade='bubo ; brew upgrade --cask ; brew upgrade ; brew cleanup'
function copy() {
  if [[ $# -gt 0 ]]; then
    pbcopy < <(cat "$@")
  else
    echo "Usage: copy <file glob>"
  fi
}
function grepyml() {
  grep -r "$1" * --include \*.yml --include \*.yaml --exclude-dir=.venv --exclude-dir=.terraform
}
function greptoml() {
  grep -r "$1" * --include \*.toml --exclude-dir=.venv --exclude-dir=.terraform
}
function greppy() {
  grep -r "$1" * --include \*.py --exclude-dir=.venv --exclude-dir=.terraform
}
function grepmd() {
  grep -r "$1" * --include \*.md --exclude-dir=.venv --exclude-dir=.terraform
}

# Python
alias pip3upgrade="pip3 list --outdated --format=json | jq -r '.[] | \"\(.name)=\(.latest_version)\"' | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 pip3 install -U"
alias upgradepipx='pipx upgrade-all'

# k8s
alias kctx="kubectx"
alias kns="kubens"
alias k="kubectl"
export PATH="${PATH}:${HOME}/.krew/bin"
alias kkrewupgrade="k krew update && k krew upgrade"

# git
function newfeature() {
  if [[ $# -eq 1 ]]; then
    git checkout main
    git pull origin main --force --tags
    git checkout -b "$1"
  else
    echo "Usage: newfeature <new-branch-name>"
  fi
}
function movechanges() {
  if [[ $# -eq 1 ]]; then
    git stash
    newfeature "$1"
    git stash pop
  else
    echo "Usage: movechanges <new-branch-name>"
  fi
}
alias gpom="git push origin main"
alias gpomf="git push origin main --force"
alias gdc="git diff --cached"
export GITSIGN_CREDENTIAL_CACHE="${HOME}/Library/Caches/sigstore/gitsign/cache.sock"
alias gooffline="cp ~/.gitconfig.offline ~/.gitconfig"
alias goonline="cp ~/.gitconfig.online ~/.gitconfig"

# Docker
alias dps="docker ps"
alias docker-cleanup="docker system df; docker container prune ; docker builder prune -f; docker image prune; docker system df"
alias docker-cleanup-more="docker system df; docker container rm \$(docker ps -a -q) ; docker builder prune -f; docker image prune -a; docker system df"

# tmux
alias t="tmux"
alias tl="tmux ls"

# Powershell
alias pwsh="docker pull microsoft/powershell:latest && docker run -it -v $(pwd):/src microsoft/powershell:latest"

# goss/dgoss
export GOSS_PATH=~/bin/goss
function upgradegoss() {
  curl -L https://raw.githubusercontent.com/goss-org/goss/master/extras/dgoss/dgoss -o ~/bin/dgoss
  chmod 0755 ~/bin/dgoss
  latest_release=$(curl https://api.github.com/repos/goss-org/goss/releases/latest | jq -r '.tag_name' | sed 's_^v__')
  # Assumes arm64
  curl -L "https://github.com/goss-org/goss/releases/download/v${latest_release}/goss-linux-arm64" -o ~/bin/goss
  chmod 0755 ~/bin/goss
}

# Other
export COWPATH="/usr/local/Cellar/cowsay/*/share/cows"
alias happiness="while true; do fortune -n 1 | cowsay -f \`find $COWPATH -type f | sort -R | head -n1\` | lolcat -a -s 100; sleep 2; done"
alias asciicast2gif='docker run --rm -v "$PWD:/data" asciinema/asciicast2gif'
alias testssl="docker run -t --rm mvance/testssl"
alias upgradespaceship='pushd "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/spaceship-prompt" && git pull && popd'
alias upgradenvchad='pushd ~/.config/nvim && git pull && popd'
alias upgradenvimconfig='upgradenvchad ; pushd ~/.config/nvim/lua/custom && git pull && popd; nvim --headless "+MasonInstallAll" "+MasonUpdate" +qa; nvim --headless "+Lazy sync" +qa'
alias upgradetmux='~/.tmux/plugins/tpm/bin/update_plugins all'
alias upgradeallthethings="brewupgrade; omz update; kkrewupgrade; pip3upgrade; upgradenvimconfig; upgradetmux; upgradespaceship; upgradepipx; upgradegoss"
alias mastertomain="git branch -m master main && git push -u origin main && git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main && echo Successfully migrated from master to main"
alias chromermfavicons='rm -rf "$HOME/Library/Application Support/Google/Chrome/Default/Favicons"'
# common task typo
alias ask="task"
# Autocomplete
autoload -U compinit; compinit
autoload -U +X bashcompinit && bashcompinit

## Functions
function nvim_exrc_security_check() {
  if [[ -r .exrc ]]; then
    read -k "answer?.exrc file detected, this will modify your vim settings!  Are you sure (y/N)? "
    if [[ "${answer}" =~ ^[yY]$ ]]; then
      nvim "$@"
    else
      echo "\nNot opening nvim"
    fi
  else
    nvim "$@"
  fi
}

function unsetawstoken() {
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_SESSION_TOKEN
  unset AWS_PROFILE
  unset AWS_DEFAULT_REGION
  unset AWS_DEFAULT_OUTPUT
}
function setawstoken() {
  eval "$(cat /dev/stdin | aws_session_token_to_env.py)" ;
  if [[ -z "${AWS_PROFILE}" ]]; then
    export AWS_PROFILE='default'
  fi
  export AWS_DEFAULT_REGION='us-east-1'
  export AWS_DEFAULT_OUTPUT='json'
  docker pull seiso/easy_infra
}
function getawstoken() {
  if ! [[ $1 =~ ^[0-9]{6}$ ]]; then
    echo "Input must be six digits"
    return 1
  elif [[ $# > 2 ]]; then
    echo "Must provide either 1 or 2 inputs"
    return 1
  fi
  echo "You must modify this function to insert your account and IAM user (See the TODOs below)"
  if [[ $# == 1 ]]; then
    #docker run --rm -v ${HOME}/.aws:/root/.aws seiso/easy_infra "aws sts get-session-token --serial-number arn:aws:iam::TODO:mfa/TODO --token-code ${1}"
  else
    docker run --rm -v ${HOME}/.aws:/root/.aws seiso/easy_infra "aws sts get-session-token --serial-number "${2}" --token-code ${1}"
  fi
}
function setawsTODO() {
  unsetawstoken
  getawstoken "${1}" | setawstoken
  echo "TODO: Look in ~/.zshrc and update AWS_PROFILE so it uses your .aws/config, then uncomment"
  #export AWS_PROFILE="Organization -> Account"
  echo "TODO: Replace the TODO appropriately and uncomment"
  #docker run --rm --env-file <(env | grep ^AWS_) -v ${HOME}/.aws:/root/.aws seiso/easy_infra "aws sts assume-role --role-arn arn:aws:iam::TODO:role/TODO --role-session-name TODO" | setawstoken
}

## Other env vars
export DEFAULT_USER='jonzeolla'
export HISTCONTROL="ignorespace${HISTCONTROL:+:$HISTCONTROL}"
# This turns off all direnv stdout
export DIRENV_LOG_FORMAT=""

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
