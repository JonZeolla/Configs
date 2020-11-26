#!/usr/bin/env bash

## Always update first
sudo softwareupdate -i -a

## Set some macOS settings
defaults write com.apple.finder AppleShowAllFiles YES
defaults write com.apple.menuextra.battery ShowPercent YES
defaults write -g KeyRepeat -int 1
sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 2
# I don't think this currently works, so I put something in the README to do it manually
defaults write ~/Library/Preferences/.GlobalPreferences com.apple.swipescrolldirection -bool false
sudo fdesetup enable
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.locate.plist
echo /usr/local/bin/zsh | sudo tee -a /etc/shells
echo /usr/local/bin/bash | sudo tee -a /etc/shells
xcode-select --install

## Install some basics

bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
brew tap sambadevi/powerlevel9k
brew update
brew install python3 go maven@3.3 maven git wget gnupg2 ant npm yarn nmap swig cmake openssl jq azure-cli hashcat shellcheck packer nvm dos2unix testssl ttygif tree vim imagemagick ruby autoconf automake libtool gnu-tar pandoc aircrack-ng bash libextractor fortune cowsay lolcat awscli terraform kubectl nuget php screen zsh heroku/brew/heroku bison zmap watch jupyter asciinema coreutils libnfc mfoc powerlevel9k logstash pipenv graphviz wakeonlan grep hadolint coreutils yara neovim neo4j kubectx git-lfs aquasecurity/trivy/trivy ncrack fzf dive yubico-yubikey-manager yubico-authenticator fujitsu-scansnap-manager-ix500 minikube google-chrome-canary nasm octant krew
npm install -g electron-packager
brew cask install vagrant virtualbox google-chrome sublime-text wireshark mysqlworkbench iterm2 slack steam firefox the-unarchiver gpg-suite docker burp-suite balenaEtcher atom powershell veracrypt beyond-compare drawio visual-studio-code little-snitch micro-snitch launchbar Keyboard-Maestro hazel bloodhound xquartz playonmac tunnelblick google-cloud-sdk surge keka microsoft-office evernote wire chef/chef/inspec thunderbird intellij-idea metasploit quicklook-json postman paragon-extfs pdftotext obs signal toggle-track gimp lens meld
# Twisted version is for sslstrip
pip3 install bcrypt ipaddress impacket pyyaml pylint pycrypto pyopenssl pefile netaddr termcolor flake8 defusedxml validators mypy black pytest-cov coverage virtualenv yamllint bandit scandir lxml grip pipenv
brew install numpy scipy ansible
go get -u golang.org/x/lint/golint
brew cleanup
sudo gem install jekyll bundler

## Set some application settings
defaults write com.aone.keka ZipUsingAES TRUE # https://github.com/aonez/Keka/wiki/ZipAES

## Configure
# bash
wget -O ~/.bash_profile https://raw.githubusercontent.com/jonzeolla/configs/master/apple/productivity/.bash_profile
wget -O ~/.bashrc https://raw.githubusercontent.com/jonzeolla/configs/master/apple/productivity/.bashrc
wget -O ~/.bash_prompt https://raw.githubusercontent.com/jonzeolla/configs/master/apple/productivity/.bash_prompt

# zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
chsh -s /usr/local/bin/zsh # Assumes zsh was installed and linked via brew
wget -O ~/.zshrc https://raw.githubusercontent.com/jonzeolla/configs/master/apple/productivity/.zshrc
ln -s /usr/local/opt/powerlevel9k "${HOME}/.oh-my-zsh/themes/powerlevel9k"
terraform -install-autocomplete

# go
mkdir "${HOME}/go"

# make
go get github.com/mrtazz/checkmake
pushd "${GOPATH}/src/github.com/mrtazz/checkmake" || { echo "Unable to cd to $GOPATH/src/github.com/mrtazz/checkmake"; exit 1; }
make
popd || { echo "Unable to popd"; exit 1; }

# other
wget -O ~/.screenrc https://raw.githubusercontent.com/jonzeolla/configs/master/apple/productivity/.screenrc
mkdir -p ~/bin ~/etc ~/src/testing ~/src/seiso
wget -O ~/bin/backtick.sh https://raw.githubusercontent.com/jonzeolla/configs/master/apple/productivity/bin/backtick.sh
sudo ln -s /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport /usr/local/bin/airport

# k8s
k krew install starboard

# Docker
docker pull asciinema/asciicast2gif
docker pull ubuntu:latest
docker pull centos:latest

## Start some things up
open /Applications/Docker.app
open /Applications/LaunchBar.app
open /Applications/Micro\ Snitch.app
open /Applications/Evernote.app
open /Applications/Microsoft\ Remote\ Desktop\ Beta.app
open /usr/local/Caskroom/little-snitch/*/LittleSnitch-*.dmg

## Setup git
wget -O ~/.gitconfig https://raw.githubusercontent.com/JonZeolla/Configs/master/apple/productivity/.gitconfig
wget -O ~/src/seiso/.gitconfig https://raw.githubusercontent.com/JonZeolla/Configs/master/apple/productivity/.seisogitconfig

## Clone some good repos
cd ~/src || { echo "Unable to cd"; exit 1; }
git clone https://github.com/jordansissel/fpm
git clone https://github.com/apache/metron
git clone https://github.com/apache/metron-bro-plugin-kafka
git clone https://github.com/zeek/zeek --recurse-submodules
git clone https://github.com/jonzeolla/configs ~/src/jonzeolla/configs/
git clone https://github.com/jonzeolla/development ~/src/jonzeolla/development/
git clone https://github.com/seisollc/probemon ~/src/seiso/probemon/ --recurse-submodules
git clone https://github.com/powerline/fonts
git clone https://github.com/trustedsec/social-engineer-toolkit
git clone https://github.com/ioquake/ioq3

## Install powerline fonts
cd ~/src/fonts || { echo "Unable to cd"; exit 1; }
./install.sh

## Setup quake3
cd ~/src/ioq3 || { echo "Unable to cd"; exit 1; }
./make-macosx.sh x86_64
cd build || { echo "Unable to cd"; exit 1; }
cp -pR release-darwin-x86_64/ /Applications/ioquake3
curl -L 'https://www.ioquake3.org/data/quake3-latest-pk3s.zip' -H 'Connection: keep-alive' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' -H 'Upgrade-Insecure-Requests: 1' -H 'DNT: 1' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.142 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3' -H 'Referer: https://ioquake3.org/extras/patch-data/' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-US,en;q=0.9' --compressed --output ./quake3-latest-pk3s.zip
open ./quake3-latest-pk3s.zip
cp -pR quake3-latest-pk3s/baseq3/* /Applications/ioquake3/baseq3/
cp -pR quake3-latest-pk3s/missionpack/* /Applications/ioquake3/missionpack/

## Setup msfconsole
cd /opt/metasploit-framework/embedded/framework || { echo "Unable to cd"; exit 1; }
# As of 2018-11-06 this is required to link pg to metasploit's postgres bundled libs, etc.
gem install pg -v '0.20.0' --source 'https://rubygems.org/' -- --with-pg-config=/opt/metasploit-framework/embedded/bin/pg_config
bundle install

## Setup SET
cd ~/src/social-engineer-toolkit || { echo "Unable to cd"; exit 1; }
latesttag=$(git describe --tags)
git checkout "${latesttag}"
python setup.py install
sudo sed -i '' 's#METASPLOIT_PATH.*#METASPLOIT_PATH=/opt/metasploit-framework/embedded/framework#' /etc/setoolkit/set.config

## Setup fpm
cd ~/src/fpm || { echo "Unable to cd"; exit 1; }
latesttag=$(git describe --tags)
git checkout "${latesttag}"
gem install --no-ri --no-rdoc fpm

## Setup GnuPG
mkdir ~/.gnupg
echo "use-standard-socket" >> ~/.gnupg/gpg-agent.conf

## Setup neovim
# These setup steps assume fzf and node are already installed via brew
mkdir -p ~/.local/share/nvim/site/pack/git-plugins/start
# Install my config
wget -O ~/.config/nvim/init.vim https://raw.githubusercontent.com/jonzeolla/configs/master/apple/productivity/init.vim
# ale
git clone --depth 1 https://github.com/dense-analysis/ale.git ~/.local/share/nvim/site/pack/git-plugins/start/ale
# NERDtree
git clone https://github.com/preservim/nerdtree.git ~/.local/share/nvim/site/pack/git-plugins/start/nerdtree
# gitgutter
git clone https://github.com/airblade/vim-gitgutter.git ~/.local/share/nvim/site/pack/git-plugins/start/vim-gitgutter
# airline
git clone https://github.com/vim-airline/vim-airline ~/.local/share/nvim/site/pack/git-plugins/start/vim-airline
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
wget -O ~/.vimrc https://raw.githubusercontent.com/jonzeolla/configs/master/apple/productivity/.vimrc
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
wget -O ~/Library/Preferences/com.googlecode.iterm2.plist https://raw.githubusercontent.com/jonzeolla/configs/master/apple/productivity/com.googlecode.iterm2.plist

## Update logstash
logstash-plugin update

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
