## Load the bash prompt
if [ -r ~/.bash_prompt ]; then
  source ~/.bash_prompt
fi

# Env Vars
export COWPATH=/usr/local/Cellar/cowsay/*/share/cows

## Configure some aliases
# OS
alias ll="ls -al"
alias cls=clear # C-l
alias calc="bc -l"
alias sha1="openssl sha1"
#alias md5="openssl md5" # Native on macOS
alias thetime="date +\"%T\""
alias thedate="date +\"%d-%m-%Y\""
alias vi=vim
alias headers="curl -I"
# Docker
alias dps="docker ps"
alias happiness="while true; do fortune | cowsay -f \`find $COWPATH -type f | sort -R | head -n1\` | lolcat -a -s 75; sleep 2; done"

