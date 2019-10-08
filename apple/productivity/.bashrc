## Load the bash prompt
if [ -r ~/.bash_prompt ]; then
  source ~/.bash_prompt
fi

## Functions
:

## Env Vars
export COWPATH="/usr/local/Cellar/cowsay/*/share/cows"
export PATH="${PATH}:/usr/local/Cellar/*/*/bin:${HOME}/bin"

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
# Other
alias dps="docker ps"
alias happiness="while true; do fortune | cowsay -f \`find \${COWPATH} -type f | sort -R | head -n1\` | lolcat -a -s 75; sleep 2; done"
alias asciicast2gif='docker run --rm -v $PWD:/data asciinema/asciicast2gif'
alias s="screen -S"
alias sl="screen -ls"
alias sr="screen -r"

