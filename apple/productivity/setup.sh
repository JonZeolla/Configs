#!/usr/bin/env bash

## Always update first
softwareupdate --all --install --force --install-rosetta

## Set some macOS settings
# Set finder to show all files
defaults write com.apple.finder AppleShowAllFiles YES
# Set the keyrepeat speed
defaults write -g KeyRepeat -int 1
# Ensure the firewall is enabled
sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 2
# Set the scroll direction; may no longer work or need a restart?
defaults write ~/Library/Preferences/.GlobalPreferences com.apple.swipescrolldirection -bool false
# Enable FDE
sudo fdesetup enable
# Enable the 'locate' command
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.locate.plist
# Allow brew-installed zsh and bash (ARM only)
echo '/opt/homebrew/bin/zsh' | sudo tee -a /etc/shells
echo '/opt/homebrew/bin/bash' | sudo tee -a /etc/shells
xcode-select --install

## Install some basics
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
# terraform is no longer updated via brew, so not installing it here
brew install go git git-lfs wget nmap swig cmake openssl jq neovim sha3sum opentofu lolcat fortune go-task yq ansible gnu-tar kubectl kubectx krew shellcheck grype syft age trivy bash zsh tree dos2unix goreleaser bison watch coreutils grep hadolint asciinema graphviz libtool libextractor libxml2 libxmlsec1 cosign crane act logitech-options direnv helm gitsign colordiff pkg-config sigstore/tap/gitsign-credential-cache quarto screenflow gh elgato-stream-deck obs ffmpeg rancher krisp ruff ripgrep tmux superhuman poetry ollama uv k3d rye cursor pipenv grip aws-sam-cli pv rsync golangci-lint beekeeper-studio rust dive ngrok zed
brew install --cask google-chrome slack firefox the-unarchiver keycastr visual-studio-code little-snitch micro-snitch raycast xquartz keka signal discord google-drive logitech-presentation rancher docker chromedriver spotify obsbot-webcam ghostty descript microsoft-powerpoint microsoft-word microsoft-excel sublime-text
# At the moment this is the only supported way to install task-master
npm install -g task-master-ai && task-master init
# At the moment this is the only supported way to install claude code
npm install -g @anthropic-ai/claude-code

# Packages useful to have on the host; project dependencies should be in a Pipfile.lock, requirements.txt, poetry.lock, etc.
pip3 install bcrypt pylint termcolor flake8 defusedxml validators mypy black pytest-cov coverage virtualenv yamllint bandit scandir lxml cookiecutter pre-commit gitpython pyyaml flynt refurb pyre gql aider-chat
brew install fd # for the linux-cultist/venv-selector.nvim plugin
uv tool install compliance-trestle
uv tool install tox
brew cleanup

## Set some application settings
# https://github.com/aonez/Keka/wiki/ZipAES
defaults write com.aone.keka ZipUsingAES TRUE

## Configure
# zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
chsh -s /opt/homebrew/bin/zsh
wget -O ~/.zshrc https://raw.githubusercontent.com/jonzeolla/configs/main/apple/productivity/.zshrc

# spaceship stuff
wget -O ~/.spaceshiprc.zsh https://raw.githubusercontent.com/jonzeolla/configs/main/apple/productivity/.spaceshiprc.zsh
git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1
ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
touch ~/.hushlogin # Don't show Last Login MOTD

# Ensure that /usr/local/share/zsh/site-functions/ is in your FPATH env var for the below to work
sudo mkdir -p /usr/local/share/zsh/site-functions/
sudo chown "$(whoami)": /usr/local/share/zsh/site-functions/
kubectl completion zsh | sed 's/kubectl/k/g' > /usr/local/share/zsh/site-functions/_k
kubectl completion zsh > /usr/local/share/zsh/site-functions/_kubectl

# go
mkdir "${HOME}/go"

## Zenable
mkdir -p ~/src/zenable
wget -O ~/src/zenable/.gitconfig https://raw.githubusercontent.com/JonZeolla/Configs/main/apple/productivity/.zenablegitconfig
# Configure spaceship
mkdir -p ~/.zsh/zenable-spaceship-section
wget -O ~/.zsh/zenable-spaceship-section/zenable.plugin.zsh https://raw.githubusercontent.com/JonZeolla/Configs/main/apple/productivity/zenable.plugin.zsh
wget -O ~/.zsh/zenable-spaceship-section/aws_custom.plugin.zsh https://raw.githubusercontent.com/JonZeolla/Configs/main/apple/productivity/aws_custom.plugin.zsh

# SANS
mkdir -p ~/src/sans ~/Documents/sans
wget -O ~/Documents/sans/Cloud\ Ace\ Final.png https://raw.githubusercontent.com/JonZeolla/Configs/main/apple/productivity/Cloud%20Ace%20Final.png
wget -O ~/src/sans/.gitconfig https://raw.githubusercontent.com/JonZeolla/Configs/main/apple/productivity/.sansgitconfig

# Seiso
mkdir -p ~/src/seiso ~/Documents/seiso
wget -O ~/Documents/seiso/seiso-enso.png https://raw.githubusercontent.com/JonZeolla/Configs/main/apple/productivity/seiso-enso.png
wget -O ~/src/seiso/.gitconfig https://raw.githubusercontent.com/JonZeolla/Configs/main/apple/productivity/.seisogitconfig

# other
mkdir -p ~/bin ~/etc ~/src/testing
wget -O ~/bin/new-desktop https://raw.githubusercontent.com/jonzeolla/configs/main/apple/productivity/bin/new-desktop

# k8s
k krew install starboard

## Start some things up
open /Applications/LaunchBar.app
open /Applications/Micro\ Snitch.app
open /usr/local/Caskroom/little-snitch/*/LittleSnitch-*.dmg

## Setup git
wget -O ~/.gitconfig https://raw.githubusercontent.com/JonZeolla/Configs/main/apple/productivity/.gitconfig
wget -O ~/.gitconfig.offline https://raw.githubusercontent.com/JonZeolla/Configs/main/apple/productivity/.gitconfig.offline
wget -O ~/.gitconfig.online https://raw.githubusercontent.com/JonZeolla/Configs/main/apple/productivity/.gitconfig.online

## Setup tmux
mkdir -p ~/.config/tmux/ ~/.tmux/plugins
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
wget -O ~/.config/tmux/tmux.conf https://raw.githubusercontent.com/jonzeolla/configs/main/apple/productivity/tmux.conf
wget -O ~/bin/tmux_status.sh https://raw.githubusercontent.com/jonzeolla/configs/main/apple/productivity/bin/tmux_status.sh

## Setup neovim
# Install NvChad
git clone https://github.com/NvChad/NvChad ~/.config/nvim
# Apply my config
git clone https://github.com/jonzeolla/neovim.git ~/.config/nvim/lua/custom
# Configure neovim supporting tools
mkdir -p ~/.config/yamllint
wget -O ~/.config/yamllint/config https://raw.githubusercontent.com/jonzeolla/configs/main/apple/productivity/yamllint.config
wget -O ~/.pylintrc https://raw.githubusercontent.com/jonzeolla/configs/main/apple/productivity/.pylintrc
# GitHub copilot requires node and an interactive setup
brew install node
echo "Interactively login to copilot"
nvim "+Copilot auth" +qa
nvim --headless "+MasonInstallAll" +qa
nvim --headless "+Lazy sync" +qa

## Setup goss/dgoss
# Pending https://github.com/goss-org/goss/issues/1030
curl -L https://raw.githubusercontent.com/goss-org/goss/master/extras/dgoss/dgoss -o ~/bin/dgoss
chmod 0755 ~/bin/dgoss
latest_release=$(curl https://api.github.com/repos/goss-org/goss/releases/latest | jq -r '.tag_name' | sed 's_^v__')
# Assumes arm64
curl -L "https://github.com/goss-org/goss/releases/download/v${latest_release}/goss-linux-arm64" -o ~/bin/goss
chmod 0755 ~/bin/goss

## Setup grant
# This is the only install path, pending https://github.com/anchore/grant/issues/222
curl -sSfL https://raw.githubusercontent.com/anchore/grant/main/install.sh | sh -s -- -b "${HOME}/bin"
