# Cache brew shellenv (Ruby fork is ~1s; sourcing the cache is ~5ms)
_brew_env="${HOME}/.cache/brew-shellenv.zsh"
if [[ ! -s $_brew_env || /opt/homebrew/bin/brew -nt $_brew_env ]]; then
  [[ -d "${HOME}/.cache" ]] || mkdir -p "${HOME}/.cache"
  /opt/homebrew/bin/brew shellenv > $_brew_env
fi
source $_brew_env
unset _brew_env

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
export PATH="${HOME}/bin:/usr/local/bin:/usr/local/sbin:${HOME}/.rd/bin:/usr/local/opt/ruby/bin:${PATH}"

# Go
export GOPATH="${HOME}/go"
export GOROOT="/opt/homebrew/opt/go/libexec"
export PATH="${PATH}:${GOPATH}/bin:${GOROOT}/bin"

# Python
# uv sets up symlinks into .local/bin
export PATH="${HOME}/.local/bin:${PATH}"

# Rust
export PATH="${HOME}/.cargo/bin:${PATH}"

## AI stuff
export OLLAMA_API_BASE=http://127.0.0.1:11434
# This isn't ready yet, just lots of repeating myself and a messy UI
#export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1

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

ZSH_DISABLE_COMPFIX=true   # skip compaudit (~0.2s)
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

# Short for local zenable
alias lzenable='pushd $(git_root)/packages/zenable && task install && popd && zenable'
export monorepo="TODO_change_your_zshrc"
alias git_root='git rev-parse --show-toplevel 2> /dev/null || echo ""'
export scripts_dir="${monorepo}/scripts"
function sethost() {
  ln -sf "${monorepo}/../.envrc.host" "${monorepo}/../.envrc"
  direnv allow "${monorepo}/"
}
function setcontainer() {
  ln -sf "${monorepo}/../.envrc.container" "${monorepo}/../.envrc"
  direnv allow "${monorepo}/"
}
function setsandbox() {
  ln -sf "${monorepo}/../.envrc.sandbox" "${monorepo}/../.envrc"
  direnv allow "${monorepo}/"
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
# launchd jobs whose ProgramArguments live inside a Homebrew keg. `brew cleanup`
# deletes that keg out from under the running process; the process survives on
# open inodes but can no longer resolve any not-yet-imported module, so it stays
# up while silently failing every code path it hadn't already executed.
# These must be restarted between `brew upgrade` and `brew cleanup`.
typeset -ga BREW_BACKED_SERVICES=(
  ai.hermes.gateway
  ai.hermes.triprunner
)

# Move brew-backed services onto the newly installed kegs. Runs BEFORE
# `brew cleanup` so the old keg still exists if a restart needs to fall back.
function reconcilebrewservices() {
  local svc rc=0
  # hermes pins its keg version into the plist, so the plist must be
  # regenerated against the new version or launchd cannot respawn the gateway.
  if command -v hermes >/dev/null 2>&1; then
    hermes gateway install || rc=1
  fi
  for svc in $BREW_BACKED_SERVICES; do
    launchctl print "gui/${UID}/${svc}" &>/dev/null || continue
    print "  restarting ${svc}"
    launchctl kickstart -k "gui/${UID}/${svc}" || rc=1
  done
  return $rc
}

# A launchd job pointing at a path that no longer exists is a latent outage:
# KeepAlive cannot respawn it, so it dies permanently at the next restart or
# reboot while `launchctl list` still shows it healthy.
function auditlaunchagents() {
  local dir=${1:-~/Library/LaunchAgents} plist label p rc=0
  for plist in ${~dir}/*.plist(N); do
    label=${${plist:t}:r}
    for p in ${(f)"$(grep -oE '/opt/homebrew/(Cellar|opt)/[^<\"[:space:]:]+' $plist 2>/dev/null | sort -u)"}; do
      [[ -z $p || -e $p ]] && continue
      print -P "%F{red}BROKEN%f ${label}: ${p}"
      rc=1
    done
  done
  (( rc )) || print -P "%F{green}All LaunchAgent paths resolve.%f"
  return $rc
}

function brewupgrade() {
  bubo
  brew upgrade --cask --yes
  brew upgrade --yes
  reconcilebrewservices   # restart onto the new kegs while the old ones still exist
  brew cleanup            # only now is deleting the old kegs safe
}
function copy() {
  if [[ $# -gt 0 ]]; then
    pbcopy < <(cat "$@")
  else
    echo "Usage: copy <file glob>"
  fi
}
alias grepz="grep --exclude-dir=.venv --exclude-dir=.terraform --exclude-dir=.aws-sam --exclude-dir=.pytest_cache --exclude-dir=.web --exclude-dir=node_modules --exclude-dir=.mypy_cache --exclude-dir=htmlcov --exclude-dir=.next --exclude-dir=_next --exclude=requirements.txt --exclude=uv.lock --exclude=package-lock.json --exclude=tsconfig.tsbuildinfo --exclude='*.pyc'"
function grepyml() {
  grep -r --include \*.yml --include \*.yaml --exclude-dir=.venv --exclude-dir=.terraform -- "$1" *
}
function greptoml() {
  grep -r --include \*.toml --exclude-dir=.venv --exclude-dir=.terraform -- "$1" *
}
function greppy() {
  grep -r --include \*.py --exclude-dir=.venv --exclude-dir=.terraform --exclude-dir=.aws-sam -- "$1" *
}
function grepmd() {
  grep -r --include \*.md --exclude-dir=.venv --exclude-dir=.terraform -- "$1" *
}
function greptf() {
  grep -r --include \*.tf --exclude-dir=.venv --exclude-dir=.terraform -- "$1" *
}

# Python
alias upgradeuvtools='uv tool upgrade --all'

# Ad-hoc Python scripting lives in a uv-managed venv rather than brew's shared
# site-packages: brew owns the formula-managed packages there, and pip3 is
# PEP 668 externally-managed so it refuses to write to it anyway.
export SCRIPTING_VENV="${HOME}/.venvs/scripting"
export SCRIPTING_REQS="${HOME}/.venvs/scripting-requirements.txt"
alias scripting="source ${SCRIPTING_VENV}/bin/activate"
function upgradescriptingvenv() {
  [[ -d $SCRIPTING_VENV && -f $SCRIPTING_REQS ]] || return 0
  uv pip install --python "${SCRIPTING_VENV}/bin/python" --upgrade -r "$SCRIPTING_REQS"
}

# What is still installed in brew's shared site-packages, for migration to uv.
function pipglobalaudit() {
  print -P "%BPackages in brew's shared site-packages (migrate to 'uv tool install'):%b"
  pip3 list --outdated --format=json 2>/dev/null \
    | jq -r '.[] | "  \(.name) \(.version) -> \(.latest_version)"'
  print -P "\n%F{yellow}Do NOT bulk 'pip3 install -U' these -- brew owns some of them.%f"
}

# k8s
alias kctx="kubectx"
alias kns="kubens"
alias k="kubectl"
export PATH="${PATH}:${HOME}/.krew/bin"
alias kkrewupgrade="k krew update && k krew upgrade"

# git
function debug-chrome() {
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --remote-debugging-port=9222 --user-data-dir="$HOME/.config/google-chrome"
}
function claudedefault() {
  local prev_dir=$(pwd)
  cd "$(git_root)" || return
  trap 'cd "$prev_dir"' EXIT INT
  command /opt/homebrew/bin/claude "$@"
  trap - EXIT INT
}
function claude() {
  local prev_dir=$(pwd)
  cd "$(git_root)" || return
  trap 'cd "$prev_dir"' EXIT INT
  command /opt/homebrew/bin/claude --verbose --allowedTools 'Bash,Read,Write,Edit,MultiEdit,Glob,Grep,LS,Task,Monitor,WebSearch,WebFetch,mcp__chrome-devtools,mcp__zenable' "$@"
  trap - EXIT INT
}
function codex() {
  local prev_dir=$(pwd)
  cd "$(git_root)" || return
  trap 'cd "$prev_dir"' EXIT INT
  command /opt/homebrew/bin/codex --dangerously-bypass-approvals-and-sandbox "$@"
  trap - EXIT INT
}
function checkout() {
  if [[ $# -eq 1 ]]; then
    git checkout main
    git pull origin main --tags
    pr_branch=$(gh pr view "$1" --json headRefName -q .headRefName)
    git fetch origin "${pr_branch}"
    git checkout "${pr_branch}"
    git pull origin "${pr_branch}"
  else
    echo "Usage: checkout <pr-number>"
  fi
}
function worktree() {
  if [[ $# -ne 1 ]]; then
    echo "Usage: worktree <new-worktree-and-branch-name>"
    return 1
  fi
  branch="$1"
  dir="$(git_root)/../${branch}"
  if [[ -d "${dir}" ]] \
    || git show-ref --verify --quiet "refs/heads/${branch}" \
    || git show-ref --verify --quiet "refs/remotes/origin/${branch}"; then
    suffix="$(date +'%B-%d' | tr '[:upper:]' '[:lower:]')"
    branch="${branch}-${suffix}"
    dir="$(git_root)/../${branch}"
    echo "Branch or directory already exists, using: ${branch}"
  fi
  git worktree add "${dir}" main -b "${branch}"
  cd "${dir}"
  claude
}
function openworktree() {
  branch="$1"
  dir="$(git_root)/../${branch}"
  if [[ $# -eq 1 ]]; then
    # Check if worktree directory already exists
    if [[ -d "${dir}" ]]; then
      echo "Worktree directory already exists, navigating to: ${dir}"
      cd "${dir}"
      claude -c || claude
      return 0
    fi

    # Fetch all remotes to ensure we have the latest branch info
    git fetch --all

    # Check if branch exists locally
    if git show-ref --verify --quiet "refs/heads/${branch}"; then
      # Local branch exists
      git worktree add "${dir}" "${branch}"
    elif git show-ref --verify --quiet "refs/remotes/origin/${branch}"; then
      # Remote branch exists
      git worktree add "${dir}" -b "${branch}" "origin/${branch}"
    else
      echo "Error: Branch '${branch}' not found locally or on remote 'origin'"
      return 1
    fi
    cd "${dir}"
    claude -c || claude
  else
    echo "Usage: openworktree <existing-branch-name>"
  fi
}
function compare() {
  git diff --name-only $(git merge-base main HEAD)..HEAD
}
function split-branch() {
  ~/bin/git-split-branch.sh
}
alias breakup-branch="split-branch"
alias gpom="git push origin main"
alias gpomf="git push origin main --force"
alias gdc="git diff --cached"
# Git pull push
alias gpp="ggl; ggp"
# Git add all, commit, and push. Retry if pre-commit changes things
function gacp() {                   # git add + commit + pull/push
  [ $# -ge 1 ] || { echo "usage: gacp <msg>"; return 1; }
  git add -A
  git commit -m "$*" || { git add -A && git commit -m "$*"; } && gpp
}
export GITSIGN_CREDENTIAL_CACHE="${HOME}/Library/Caches/sigstore/gitsign/cache.sock"
alias gooffline="cp ~/.gitconfig.offline ~/.gitconfig"
alias goonline="cp ~/.gitconfig.online ~/.gitconfig"

# Docker
alias dps="docker ps"
alias docker-cleanup="docker system df; docker container prune ; docker builder prune -f; docker image prune -a --filter 'until=168h'; docker system df"
# Superset of docker-cleanup: drops the 168h age filter and clears the cache of
# every docker-container builder. Those keep their cache in a named volume that
# `docker builder prune` never reaches, so they need a per-builder pass; the
# docker-driver builders are skipped because they share the daemon cache already
# pruned above, and pruning one bound to another context just errors.
# The volume prune is deliberately not -a: anonymous volumes are cruft, but named
# ones are local database data (pgvector, postgres) and must survive.
docker-cleanup-more() {
  docker system df
  docker container prune -f
  docker image prune -a -f
  docker builder prune -af
  local builder
  for builder in $(docker buildx ls | tail -n +2 | grep -v '\\_' | awk '$2=="docker-container"{sub(/\*$/,"",$1); print $1}'); do
    docker buildx prune -af --builder "$builder"
  done
  docker volume prune -f
  docker system df
}

# tmux
alias tl="tmux ls"
alias ta='tmux attach -d -t'

# Powershell
alias pwsh="docker pull microsoft/powershell:latest && docker run -it -v $(pwd):/src microsoft/powershell:latest"

# goss/dgoss
export GOSS_PATH=~/bin/goss
# -f makes curl fail on HTTP errors instead of writing the error body to the
# output file; staging in a tmpdir keeps a failed run from destroying a working
# binary.
function upgradegoss() {
  local rel ver tmp rc
  rel=$(curl -fsSL https://api.github.com/repos/goss-org/goss/releases/latest | jq -r .tag_name) || return 1
  [[ -n $rel && $rel != null ]] || { print -u2 "upgradegoss: could not resolve latest release"; return 1 }
  ver=${rel#v}
  tmp=$(mktemp -d) || return 1
  curl -fsSL "https://github.com/goss-org/goss/releases/download/${rel}/goss_${ver}_darwin_$(uname -m).tar.gz" \
    | tar -xzf - -C "$tmp" goss || { rm -rf "$tmp"; return 1 }
  install -m 0755 "$tmp/goss" ~/bin/goss || { rm -rf "$tmp"; return 1 }
  curl -fsSL https://raw.githubusercontent.com/goss-org/goss/master/extras/dgoss/dgoss -o "$tmp/dgoss" \
    && install -m 0755 "$tmp/dgoss" ~/bin/dgoss
  rc=$?
  rm -rf "$tmp"
  return $rc
}

# Other
export COWPATH="/usr/local/Cellar/cowsay/*/share/cows"
alias happiness="while true; do fortune -n 1 | cowsay -f \`find $COWPATH -type f | sort -R | head -n1\` | lolcat -a -s 100; sleep 2; done"
alias asciicast2gif='docker run --rm -v "$PWD:/data" asciinema/asciicast2gif'
alias testssl="docker run -t --rm mvance/testssl"
# These are functions rather than aliases because upgradeallthethings invokes
# them via "$@", and alias expansion does not apply to expanded words.
function upgradespaceship() {
  pushd "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/spaceship-prompt" && git pull && popd
}
function upgradelazynvim()  { nvim --headless "+Lazy update" +qa }
function upgradenvimconfig() {
  upgradelazynvim && nvim --headless "+MasonUpdate" +qa
}
function upgradetmux()      { ~/.tmux/plugins/tpm/bin/update_plugins all }
function upgradekrew()      { kubectl krew update && kubectl krew upgrade }

# Run one upgrade step, recording success/failure instead of letting it scroll
# past unnoticed. Always returns 0 so a failed step does not abort the run.
function _uatt_run() {
  local name=$1; shift
  print -P "\n%F{blue}%B==> ${name}%b%f"
  "$@"; local rc=$?
  if (( rc )); then
    _UATT_FAIL+=("${name} (exit ${rc})")
    print -P "%F{red}%B!! ${name} failed (exit ${rc})%b%f"
  else
    _UATT_OK+=("${name}")
  fi
  return 0
}

# Each step reports pass/fail and the run ends with a summary, so a step that
# breaks is visible rather than scrolling past. The closing launchd audit catches
# a service left pointing at a deleted keg before the next reboot does.
function upgradeallthethings() {
  local -a _UATT_OK _UATT_FAIL
  _uatt_run "homebrew"      brewupgrade
  _uatt_run "oh-my-zsh"     omz update
  _uatt_run "krew"          upgradekrew
  _uatt_run "uv tools"      upgradeuvtools
  _uatt_run "scripting venv" upgradescriptingvenv
  _uatt_run "neovim"        upgradenvimconfig
  _uatt_run "tmux plugins"  upgradetmux
  _uatt_run "spaceship"     upgradespaceship
  _uatt_run "goss"          upgradegoss
  _uatt_run "launchd audit" auditlaunchagents

  print -P "\n%B── upgrade summary ──%b"
  (( $#_UATT_OK ))   && print -P "%F{green}ok:%f     ${(j:, :)_UATT_OK}"
  (( $#_UATT_FAIL )) && { print -P "%F{red}%Bfailed:%b%f ${(j:, :)_UATT_FAIL}"; return 1 }
  print -P "%F{green}All steps succeeded.%f"
}
alias mastertomain="git branch -m master main && git push -u origin main && git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main && echo Successfully migrated from master to main"
alias chromermfavicons='rm -rf "$HOME/Library/Application Support/Google/Chrome/Default/Favicons"'
# common task typo / shortener
alias t="task"
alias ask="task"
alias taks="task"
# Autocomplete
autoload -U compinit; compinit -C
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
