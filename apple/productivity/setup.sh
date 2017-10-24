#!/usr/bin/env bash

# TODO:  Configure NVM

## Always update first
sudo softwareupdate -i -a

## Set some macOS settings
defaults write com.apple.finder AppleShowAllFiles YES
sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 2
sudo fdesetup enable
defaults write -g KeyRepeat -int 1

## Install some basic tools
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew update
brew cask install java
brew install python python3 go maven git wget gnupg2 ant npm yarn nmap bro swig cmake openssl jq azure-cli nvm
brew cask install vagrant virtualbox google-chrome sublime-text vmware-fusion rescuetime wireshark mysqlworkbench iterm2 slack steam firefox the-unarchiver gpgtools skype docker burp-suite etcher playonmac microsoft-teams atom powershell
brew install weechat --with-aspell --with-curl --with-python --with-perl --with-ruby --with-lua --with-guile
sudo easy_install pip
sudo pip install virtualenv boto
pip3 install boto3 paramiko
sudo pip install --upgrade --user awscli
pip3 install jupyter
brew install numpy scipy ansible
brew tap samueljohn/python
brew cleanup
sudo gem install bundler
sudo gem install jekyll

## Configure the environment
wget -O ~/.bash_profile https://raw.githubusercontent.com/jonzeolla/configs/master/apple/productivity/.bash_profile
source ~/.bash_profile
wget -O ~/.bash_prompt https://raw.githubusercontent.com/jonzeolla/configs/master/apple/productivity/.bash_prompt
source ~/.bash_prompt
mkdir -p ~/bin ~/dev/testing

## Start some things up
open /Applications/RescueTime.app
open /Applications/Docker.app

## Setup vagrant
# Install the hostmanager
vagrant plugin install vagrant-hostmanager

# Install VMWare Fusion plugin license
while [ -z "${prompt}" ]; do
  read -p "Is your license for vagrant-vmware-fusion in ~/license.lic? [Y/n]" prompt
  case "${prompt}" in
    ""|[yY]|[yY][eE][sS])
      echo -e "Installing the VMWare Fusion plugin for vagrant"
      vagrant plugin install vagrant-vmware-fusion
      vagrant plugin license vagrant-vmware-fusion ~/license.lic
      ;;
    [nN]|[nN][oO])
      read -p "Where is your license.lic file?  " location
      if [ -z "${location}" ]; then
        echo -e "No license file specified, not installing the VMWare Fusion plugin for vagrant"
      else
        vagrant plugin install vagrant-vmware-fusion
        vagrant plugin license vagrant-vmware-fusion "${location}"
      fi
      ;;
    *)
      echo -e "Unknown response, not configuring the VMWare Fusion plugin for vagrant" ;;
  esac
done

## Setup git
wget -O ~/.gitconfig https://raw.githubusercontent.com/jonzeolla/configs/master/apple/productivity/.gitconfig

## Setup GnuPG
mkdir ~/.gnupg
echo "use-standard-socket" >> ~/.gnupg/gpg-agent.conf

## Setup vim
# Setup pathogen
mkdir -p ~/.vim/autoload ~/.vim/bundle && curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim
# Pull down my .vimrc
wget -O ~/.vimrc https://raw.githubusercontent.com/jonzeolla/configs/master/apple/productivity/.vimrc
# Set up vim-sensible
cd ~/.vim/bundle && git clone https://github.com/tpope/vim-sensible.git
# Set up vim-colors-solarized
cd ~/.vim/bundle && git clone git://github.com/altercation/vim-colors-solarized.git

## Setup iTerm2
mkdir -p ~/.iterm2/
wget -O ~/.iterm2/solarized_dark.itermcolors https://raw.githubusercontent.com/altercation/solarized/master/iterm2-colors-solarized/Solarized%20Dark.itermcolors
defaults write com.googlecode.iterm2 AboutToPasteTabsWithCancel 0
wget -O ~/Library/Preferences/com.googlecode.iterm2.plist https://raw.githubusercontent.com/jonzeolla/configs/master/apple/productivity/com.googlecode.iterm2.plist

## Setup weechat
mkdir -p ~/.weechat/certs/
# Update the ca-bundle
curl https://curl.haxx.se/ca/cacert.pem > ~/.weechat/certs/ca-bundle.crt

# Setup weechat
while [ -z "${prompt}" ]; do
  read -p "Open and then close weechat before moving forward.  Enter Yes to this prompt when you are done."
  case "${prompt}" in
    ""|[yY]|[yY][eE][sS])
      echo -e "Continuing..."
      ;;
    [nN]|[nN][oO])
      echo -e "Negative response, exiting..."
      exit
      ;;
    *)
      echo -e "Unknown response, exiting..."
      exit
      ;;
  esac
done

sed -i '' 's#gnutls_ca_file.*#gnutls_ca_file = "~/.weechat/certs/ca-bundle.crt"#' ~/.weechat/weechat.conf
# Setup irc.conf
# Freenode
sed -i '' 's%freenode.addresses.*%freenode.addresses = "chat.freenode.net/7000"%' ~/.weechat/irc.conf
sed -i '' 's%freenode.sasl_username.*%freenode.sasl_username = "jzeolla"%' ~/.weechat/irc.conf
sed -i '' 's%freenode.autoconnect.*%freenode.autoconnect = on%' ~/.weechat/irc.conf
sed -i '' 's%freenode.nicks.*%freenode.nicks = "jzeolla,jzeolla_"%' ~/.weechat/irc.conf
sed -i '' 's%freenode.username.*%freenode.username = "jzeolla"%' ~/.weechat/irc.conf
sed -i '' 's%freenode.realname.*%freenode.realname = "jzeolla"%' ~/.weechat/irc.conf
sed -i '' 's%freenode.autojoin.*%freenode.autojoin = "#apache-metron,#bro,#pwning,#ansible,##machinelearning"%' ~/.weechat/irc.conf
sed -i '' 's%freenode.ssl.*%freenode.ssl = on%' ~/.weechat/irc.conf
# OFTC
sed -i '' 's%oftc.addresses.*%oftc.addresses = "irc.oftc.net/6697"%' ~/.weechat/irc.conf
sed -i '' 's%oftc.sasl_username.*%oftc.sasl_username = "jzeolla"%' ~/.weechat/irc.conf
sed -i '' 's%oftc.autoconnect.*%oftc.autoconnect = on%' ~/.weechat/irc.conf
sed -i '' 's%oftc.nicks.*%oftc.nicks = "jzeolla,jzeolla_"%' ~/.weechat/irc.conf
sed -i '' 's%oftc.username.*%oftc.username = "jzeolla"%' ~/.weechat/irc.conf
sed -i '' 's%oftc.realname.*%oftc.realname = "jzeolla"%' ~/.weechat/irc.conf
sed -i '' 's%oftc.autojoin.*%oftc.autojoin = "#ocmdev"%' ~/.weechat/irc.conf
sed -i '' 's%oftc.ssl.*%oftc.ssl = on%' ~/.weechat/irc.conf

