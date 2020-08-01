export TERM="xterm-256color"

# Languages
export GOPATH="${HOME}/go"
export GOROOT="$(brew --prefix golang)/libexec"

# If you come from bash you might have to change your $PATH.
PYTHON_LOCAL=$(python3 -c "import site, os; print(os.path.join(site.USER_BASE, 'bin'))")
export PATH=${HOME}/bin:/usr/local/bin:/usr/local/sbin:${GOPATH}/bin:${GOROOT}/bin:/usr/local/opt/ruby/bin:/usr/local/opt/grep/libexec/gnubin:${PYTHON_LOCAL}:$PATH

# Path to your oh-my-zsh installation.
export ZSH="${HOME}/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="powerlevel9k/powerlevel9k"

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
  export EDITOR='vim'
else
  export EDITOR='vim'
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
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir newline vcs aws)
setopt no_share_history
unsetopt share_history

## Cloud things
# Fixes awscli
export DYLD_LIBRARY_PATH=/usr/local/opt/openssl/lib

## Configure some aliases
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
  alias vi='nvim'
fi
# Docker
alias dps="docker ps"
alias docker-cleanup="docker container rm \$(docker ps -a -q) ; docker builder prune -f; docker image prune"
alias docker-cleanup-more="docker container rm \$(docker ps -a -q) ; docker builder prune -f; docker image prune -a"
# Vagrant
alias vagrant-cleanup="vagrant global-status --prune && vagrant box list | cut -f 1 -d ' ' | xargs -L 1 vagrant box remove -f"
# Screen
alias s="screen -S"
alias sl="screen -ls"
alias sr="screen -r"
# Other
export COWPATH=/usr/local/Cellar/cowsay/*/share/cows
alias happiness="while true; do fortune -n 1 | cowsay -f \`find $COWPATH -type f | sort -R | head -n1\` | lolcat -a -s 100; sleep 2; done"
alias vinerd="vim +NERDTree"
alias asciicast2gif='docker run --rm -v $PWD:/data asciinema/asciicast2gif'
alias brewupgrade='bubo ; brew cask upgrade ; bubc'
alias testssl="docker run -t --rm mvance/testssl"

## Functions
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
  echo "You must modify this function to insert your account and IAM user (See the TODOs below)"
  #docker run --rm -v ${HOME}/.aws:/root/.aws seiso/easy_infra "aws sts get-session-token --serial-number arn:aws:iam::TODO:mfa/TODO --token-code ${1}"
}
function setawsTODO() {
  getawstoken "${1}" | setawstoken
  # TODO: migrate to docker
  aws sts assume-role --role-arn arn:aws:iam::TODO:role/TODO --role-session-name TODO | setawstoken
  # TODO: Set the AWS_PROFILE variable appropriately so it uses your .aws/config and so it shows up at the shell prompt
  export AWS_PROFILE="Organization -> Account"
}

## Other env vars
export DEFAULT_USER='jonzeolla'
export HISTCONTROL="ignorespace${HISTCONTROL:+:$HISTCONTROL}"
# Version pin to Java 12
export JAVA_HOME=$(/usr/libexec/java_home -v12)
