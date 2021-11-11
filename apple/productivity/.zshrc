export TERM="xterm-256color"
# Update $? to account for the rightmost non-zero failure in a pipeline
set -o pipefail

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Languages
export GOPATH="${HOME}/go"
export GOROOT="$(brew --prefix golang)/libexec"

# If you come from bash you might have to change your $PATH.
PYTHON_LOCAL=$(python3 -c "import site, pathlib; print(pathlib.Path(site.USER_BASE, 'bin'))")
export PATH="${HOME}/bin:/usr/local/bin:/usr/local/sbin:${GOPATH}/bin:${GOROOT}/bin:/usr/local/opt/ruby/bin:/usr/local/opt/grep/libexec/gnubin:${PYTHON_LOCAL}:$PATH"

# Path to your oh-my-zsh installation.
export ZSH="${HOME}/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  aws
  docker-compose
  docker
  jsontools
  vscode
  python
  terraform
  vagrant
  vault
  golang
  brew
  ansible
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='nvim'
else
  export EDITOR='nvim'
fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

## Additional zsh configs
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir vcs virtualenv aws kubecontext)
POWERLEVEL9K_KUBECONTEXT_BACKGROUND="006"
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
setopt no_share_history
unsetopt share_history

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
if type nvim > /dev/null 2>&1; then
  alias vi=nvim_exrc_security_check
fi
alias brewupgrade='bubo ; brew upgrade --cask ; bubc'

# Python
alias pri='pipenv run invoke'
alias pip3upgrade='pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 pip install -U'

# k8s
alias kctx="kubectx"
alias kns="kubens"
alias k="kubectl"
[[ $commands[kubectl] ]] && source <(kubectl completion zsh | sed 's/kubectl/k/g')
[[ $commands[kind] ]] && source <(kind completion zsh)
export PATH="${PATH}:${HOME}/.krew/bin"
alias kkrewupgrade="k krew update && k krew upgrade"

# git
alias gpom="git push origin main"
alias gpomf="git push origin main --force"
alias gdc="git diff --cached"

# Docker
alias dps="docker ps"
alias docker-cleanup="docker system df; docker container rm \$(docker ps -a -q) ; docker builder prune -f; docker image prune; docker system df"
alias docker-cleanup-more="docker system df; docker container rm \$(docker ps -a -q) ; docker builder prune -f; docker image prune -a; docker system df"

# Vagrant
alias vagrant-cleanup="vagrant global-status --prune && vagrant box list | cut -f 1 -d ' ' | xargs -L 1 vagrant box remove -f"

# Screen
alias s="screen -S"
alias sl="screen -ls"
alias sr="screen -r"

# Powershell
alias pwsh="docker pull microsoft/powershell:latest && docker run -it -v $(pwd):/src microsoft/powershell:latest"

# Other
export COWPATH="/usr/local/Cellar/cowsay/*/share/cows"
alias happiness="while true; do fortune -n 1 | cowsay -f \`find $COWPATH -type f | sort -R | head -n1\` | lolcat -a -s 100; sleep 2; done"
alias vinerd="vim +NERDTree"
alias asciicast2gif='docker run --rm -v $PWD:/data asciinema/asciicast2gif'
alias testssl="docker run -t --rm mvance/testssl"
alias upgradeallthethings="brewupgrade; kkrewupgrade; vagrant box prune; pip3upgrade"
alias mastertomain="git branch -m master main && git push -u origin main && git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main && echo Successfully migrated from master to main"

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

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
