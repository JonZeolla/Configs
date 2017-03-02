#!/usr/bin/env bash

## Always update first
sudo softwareupdate -i -a

## Set some macOS settings
defaults write com.apple.finder AppleShowAllFiles YES
sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 2
sudo fdesetup enable

## Configure the environment
if ! grep -q "source ~/.bash_prompt" "/Users/${USER}/.bash_profile"; then
  echo -e "if [ -r ~/.bash_prompt ]; then\n  source ~/.bash_prompt\nfi\n" >> ~/.bash_profile
fi
wget -O ~/.bash_prompt https://raw.githubusercontent.com/jonzeolla/configs/master/apple/productivity/.bash_prompt
source ~/.bash_prompt
mkdir ~/bin ~/dev

## Install some basic tools
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew update
brew install python python3 go maven git wget
brew cask install vagrant virtualbox java google-chrome sublime-text vmware-fusion rescuetime wireshark mysqlworkbench iterm2
brew install weechat --with-aspell --with-curl --with-python --with-perl --with-ruby --with-lua --with-guile
pip install --upgrade distribute pip
brew install homebrew/python/numpy homebrew/python/scipy ansible docker-machine
brew tap samueljohn/python homebrew/science
brew cleanup

## Start some things up
open /Applications/RescueTime.app
brew services start docker-machine

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

