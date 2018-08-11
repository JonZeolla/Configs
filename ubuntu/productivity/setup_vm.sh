#!/usr/bin/env bash

## Always update first
sudo apt update
sudo apt -y upgrade

## Install some packages
sudo apt -y install python python-pip python-dev python-setuptools python3 python3-pip python3-dev python3-setuptools build-essential open-vm-tools

## Install some basic tools
pip install virtualenv boto service_identity pyasn1-modules cryptography pyyaml
pip3 install boto3 paramiko selenium jupyter pyasn1-modules cryptography bcrypt asn1crypto ipaddress jedi docopt impacket pyyaml

# The following was selectively pulled from https://raw.githubusercontent.com/JonZeolla/Configs/master/apple/productivity/setup.sh on 2018-08-10

## Configure the environment
wget -O ~/.bash_profile https://raw.githubusercontent.com/jonzeolla/configs/master/apple/productivity/.bash_profile
wget -O ~/.bashrc https://raw.githubusercontent.com/jonzeolla/configs/master/apple/productivity/.bashrc
wget -O ~/.bash_prompt https://raw.githubusercontent.com/jonzeolla/configs/master/apple/productivity/.bash_prompt
source ~/.bash_profile
wget -O ~/.screenrc https://raw.githubusercontent.com/jonzeolla/configs/master/apple/productivity/.screenrc
mkdir -p ~/bin ~/etc ~/src/testing ~/src/seiso

## Clone some repos
cd ~/src
git clone https://github.com/apache/metron
git clone https://github.com/apache/metron-bro-plugin-kafka
git clone https://github.com/bro/bro --recurse-submodules
git clone https://github.com/jonzeolla/configs ~/src/jonzeolla/configs/
git clone https://github.com/jonzeolla/development ~/src/jonzeolla/development/
git clone https://github.com/seisollc/probemon ~/src/seiso/probemon/ --recurse-submodules

## Setup git
wget -O ~/.gitconfig https://raw.githubusercontent.com/JonZeolla/Configs/master/apple/productivity/.gitconfig
wget -O ~/src/seiso/.gitconfig https://raw.githubusercontent.com/JonZeolla/Configs/master/apple/productivity/.seisogitconfig

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
# Set up jedi-vim
cd ~/.vim/bundle && git clone --recursive https://github.com/davidhalter/jedi-vim.git

