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
# Set the scroll direction
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
brew tap filippo.io/age https://filippo.io/age
brew tap anchore/syft
brew tap anchore/grype
brew tap cantino/mcfly
brew update
brew install go git wget gnupg2 npm yarn nmap swig cmake openssl jq azure-cli hashcat shellcheck packer dos2unix testssl ttygif tree vim imagemagick ruby autoconf automake libtool gnu-tar pandoc aircrack-ng bash libextractor fortune cowsay lolcat awscli terraform kubectl nuget screen zsh bison zmap watch jupyter asciinema coreutils graphviz wakeonlan grep hadolint coreutils yara neovim neo4j kubectx git-lfs aquasecurity/trivy/trivy ncrack fzf dive ykman minikube octant krew sha3sum tor tor-browser libxml2 libxmlsec1 pkg-config age syft grype beekeeper-studio pyenv ansible cosign crane act just colordiff rust logitech-options kind cantino/mcfly/mcfly direnv
npm install -g electron-packager
brew install --cask vagrant google-chrome sublime-text wireshark iterm2 slack steam firefox the-unarchiver gpg-suite owasp-zap keycastr balenaEtcher drawio visual-studio-code little-snitch micro-snitch launchbar hazel bloodhound xquartz surge keka microsoft-office evernote wire chef/chef/inspec postman paragon-extfs pdftotext obs signal toggle-track gimp lens meld quik microsoft-teams lastpass yt-music discord google-drive intune-company-portal logitech-presentation parallels rancher docker

###################################################################################
# Hack to get the latest version of 3, excluding any alphas, betas, or dev releases
latest_version_of_python="$(pyenv install -l | sed 's/^ *//g' | grep '^3\.' | grep -v '[a-zA-Z]' | tail -1)"
pyenv install -f "${latest_version_of_python}"
pyenv global "${latest_version_of_python}"
eval "$(pyenv init -)"
###################################################################################

# Packages useful to have on the host; project dependencies should be in a Pipfile.lock, requirements.txt, poetry.lock, etc.
pip3 install bcrypt impacket pylint termcolor flake8 defusedxml validators mypy black pytest-cov coverage virtualenv yamllint bandit scandir lxml grip cookiecutter pipx c7n
python3 -m pipx ensurepath
pipx install pipenv
pipx install pls
brew cleanup

## Set some application settings
defaults write com.aone.keka ZipUsingAES TRUE # https://github.com/aonez/Keka/wiki/ZipAES

## Configure
# bash
wget -O ~/.bash_profile https://raw.githubusercontent.com/jonzeolla/configs/main/apple/productivity/.bash_profile
wget -O ~/.bashrc https://raw.githubusercontent.com/jonzeolla/configs/main/apple/productivity/.bashrc
wget -O ~/.bash_prompt https://raw.githubusercontent.com/jonzeolla/configs/main/apple/productivity/.bash_prompt
touch ~/.hushlogin # Don't show Last Login MOTD

# zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
chsh -s /opt/homebrew/bin/zsh
wget -O ~/.zshrc https://raw.githubusercontent.com/jonzeolla/configs/main/apple/productivity/.zshrc
wget -O ~/.zprofile https://raw.githubusercontent.com/jonzeolla/configs/main/apple/productivity/.zprofile
wget -O ~/.p10k.zsh https://raw.githubusercontent.com/jonzeolla/configs/main/apple/productivity/.p10k.zsh
p10k configure # This will download the fonts and do other p10k setup tasks
touch ~/.hushlogin # Don't show Last Login MOTD

# Ensure that /usr/local/share/zsh/site-functions/ is in your FPATH env var for the below to work
sudo mkdir -p /usr/local/share/zsh/site-functions/
sudo chown jonzeolla: /usr/local/share/zsh/site-functions/
nerdctl completion zsh > /usr/local/share/zsh/site-functions/_nerdctl
rdctl completion zsh > /usr/local/share/zsh/site-functions/_rdctl
kubectl completion zsh | sed 's/kubectl/k/g' > /usr/local/share/zsh/site-functions/_k
kubectl completion zsh > /usr/local/share/zsh/site-functions/_kubectl
kind completion zsh > /usr/local/share/zsh/site-functions/_kind
terraform -install-autocomplete

# go
mkdir "${HOME}/go"
go get -u golang.org/x/lint/golint

# SANS
mkdir -p ~/src/sans
# This is used in iTerm2 configs for the SANS profile(s)
wget -O ~/Documents/SANS/Cloud\ Ace\ Final.png https://raw.githubusercontent.com/JonZeolla/Configs/main/apple/productivity/Cloud%20Ace%20Final.png
wget -O ~/src/sans/.envrc https://raw.githubusercontent.com/jonzeolla/configs/main/apple/productivity/.sansenvrc
direnv allow ~/src/sans/

# other
wget -O ~/.screenrc https://raw.githubusercontent.com/jonzeolla/configs/main/apple/productivity/.screenrc
mkdir -p ~/bin ~/etc ~/src/testing ~/src/seiso
wget -O ~/bin/backtick.sh https://raw.githubusercontent.com/jonzeolla/configs/main/apple/productivity/bin/backtick.sh
sudo ln -s /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport /opt/homebrew/bin/airport

# k8s
k krew install starboard

## Start some things up
open /Applications/Rancher\ Desktop.app
open /Applications/LaunchBar.app
open /Applications/Micro\ Snitch.app
open /Applications/Evernote.app
open /Applications/Lastpass.app
open /Applications/Toggl\ Track.app
open /Applications/Company\ Portal.app/
open /Applications/Parallels\ Desktop.app
open /usr/local/Caskroom/little-snitch/*/LittleSnitch-*.dmg

## Setup git
wget -O ~/.gitconfig https://raw.githubusercontent.com/JonZeolla/Configs/main/apple/productivity/.gitconfig
wget -O ~/src/seiso/.gitconfig https://raw.githubusercontent.com/JonZeolla/Configs/main/apple/productivity/.seisogitconfig
wget -O ~/src/sans/.gitconfig https://raw.githubusercontent.com/JonZeolla/Configs/main/apple/productivity/.sansgitconfig

## Clone some good repos
cd ~/src || { echo "Unable to cd"; exit 1; }
git clone https://github.com/jonzeolla/configs ~/src/jonzeolla/configs/
git clone https://github.com/ioquake/ioq3

## Setup quake3
cd ~/src/ioq3 || { echo "Unable to cd"; exit 1; }
./make-macosx.sh x86_64
cd build || { echo "Unable to cd"; exit 1; }
cp -pR release-darwin-x86_64/ /Applications/ioquake3
curl -L 'https://www.ioquake3.org/data/quake3-latest-pk3s.zip' -H 'Connection: keep-alive' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' -H 'Upgrade-Insecure-Requests: 1' -H 'DNT: 1' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.142 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3' -H 'Referer: https://ioquake3.org/extras/patch-data/' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-US,en;q=0.9' --compressed --output ./quake3-latest-pk3s.zip
open ./quake3-latest-pk3s.zip
cp -pR quake3-latest-pk3s/baseq3/* /Applications/ioquake3/baseq3/
cp -pR quake3-latest-pk3s/missionpack/* /Applications/ioquake3/missionpack/

## Setup GnuPG
mkdir ~/.gnupg
echo "use-standard-socket" >> ~/.gnupg/gpg-agent.conf

## Setup neovim
# These setup steps assume fzf and node are already installed via brew
mkdir -p ~/.local/share/nvim/site/pack/git-plugins/start ~/.config/nvim
# Install my config
wget -O ~/.config/nvim/init.vim https://raw.githubusercontent.com/jonzeolla/configs/main/apple/productivity/init.vim
# ale
git clone --depth 1 https://github.com/dense-analysis/ale.git ~/.local/share/nvim/site/pack/git-plugins/start/ale
# NERDtree
git clone https://github.com/preservim/nerdtree.git ~/.local/share/nvim/site/pack/git-plugins/start/nerdtree
# gitgutter
git clone https://github.com/airblade/vim-gitgutter.git ~/.local/share/nvim/site/pack/git-plugins/start/vim-gitgutter
# airline
git clone https://github.com/vim-airline/vim-airline ~/.local/share/nvim/site/pack/git-plugins/start/vim-airline
# vim-just
git clone https://github.com/NoahTheDuke/vim-just ~/.local/share/nvim/site/pack/git-plugins/start/vim-just
# semshi
mkdir -p ~/.local/share/nvim/site/pack/semshi/start
git clone https://github.com/numirias/semshi ~/.local/share/nvim/site/pack/semshi/start/semshi
nvim -c 'UpdateRemotePlugins|q'
# COC
mkdir -p ~/.local/share/nvim/site/pack/coc/start
cd ~/.local/share/nvim/site/pack/coc/start
curl --fail -L https://github.com/neoclide/coc.nvim/archive/release.tar.gz | tar xzfv -
python3 -m pip install --upgrade pynvim jedi mypy
nvim -c 'CocInstall -sync coc-python coc-json coc-powershell coc-yaml|q|q'
npm install -g neovim

## Setup vim
# TODO:  Migrate to vim 8 packages
mkdir -p ~/.vim/autoload ~/.vim/bundle && curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim
wget -O ~/.vimrc https://raw.githubusercontent.com/jonzeolla/configs/main/apple/productivity/.vimrc
git clone https://github.com/tpope/vim-sensible.git ~/.vim/bundle/vim-sensible/
git clone https://github.com/altercation/vim-colors-solarized.git ~/.vim/bundle/vim-colors-solarized/
git clone --recursive https://github.com/davidhalter/jedi-vim.git ~/.vim/bundle/jedi-vim/
git clone https://github.com/fatih/vim-go.git ~/.vim/pack/plugins/start/vim-go
git clone https://github.com/vim-airline/vim-airline ~/.vim/pack/dist/start/vim-airline/
git clone --depth=1 https://github.com/vim-syntastic/syntastic.git ~/.vim/bundle/syntastic/
git clone https://github.com/tpope/vim-fugitive.git ~/.vim/bundle/vim-fugitive/
git clone https://github.com/PProvost/vim-ps1.git ~/.vim/bundle/vim-ps1/
git clone https://github.com/scrooloose/nerdtree.git ~/.vim/bundle/nerdtree/

## Setup iTerm2
mkdir -p ~/.iterm2/
wget -O ~/.iterm2/solarized_dark.itermcolors https://raw.githubusercontent.com/altercation/solarized/master/iterm2-colors-solarized/Solarized%20Dark.itermcolors
defaults write com.googlecode.iterm2 AboutToPasteTabsWithCancel 0
wget -O ~/Library/Preferences/com.googlecode.iterm2.plist https://raw.githubusercontent.com/jonzeolla/configs/main/apple/productivity/com.googlecode.iterm2.plist

## Setup TLS tooling
go get -u github.com/cloudflare/cfssl/cmd/...
go get github.com/google/trillian
pushd ~/go/src/github.com/google/trillian || { echo "Unable to cd to ~/go/src/github.com/google/trillian"; exit 1; }
go get -t -u -v ./...
popd || { echo "Unable to popd"; exit 1; }
pushd ~/src || { echo "Unable to cd to ~/src"; exit 1; }
git clone https://github.com/google/certificate-transparency-go.git
go build certificate-transparency-go/client/ctclient/ctclient.go
chmod a+x ctclient
sudo cp ctclient /usr/local/bin/ctclient
popd || { echo "Unable to popd"; exit 1; }

## Setup vagrant
# Install the hostmanager
vagrant plugin install vagrant-hostmanager
