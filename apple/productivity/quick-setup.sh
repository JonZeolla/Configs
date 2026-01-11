#!/usr/bin/env bash

# Set finder to show all files
defaults write com.apple.finder AppleShowAllFiles YES
# Set the keyrepeat speed
defaults write -g KeyRepeat -int 1
# Allow brew-installed zsh (ARM only)
echo '/opt/homebrew/bin/zsh' | sudo tee -a /etc/shells

# basics
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install --cask ghostty
brew install zsh git uv jq neovim tmux gh ruff direnv

# zsh
chsh -s /opt/homebrew/bin/zsh
mv ~/.zshrc ~/.zshrc.bkp
wget -O ~/.zshrc https://raw.githubusercontent.com/jonzeolla/configs/main/apple/productivity/.zshrc

# neovim
git clone https://github.com/jonzeolla/neovim.git ~/.config/nvim
rm -rf ~/.config/nvim/.git
nvim --headless "+Lazy sync" +qa

# More
brew install git-lfs wget nmap sha3sum go-task gnu-tar shellcheck bash tree watch coreutils grep hadolint crane ripgrep ollama grip beekeeper-studio dive ngrok bats eslint
brew install fd # for the linux-cultist/venv-selector.nvim plugin
brew cleanup
