# Install chocolately
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install things
choco install git docker burp-suite-free-edition etcher nmap putty wireshark sublimetext3 winscp winpcap googlechrome packer virtualbox vagrant 7zip vscode node chromedriver choco-cleaner office365business
# Should upgrade this soon to 14
choco install vmwareworkstation --version 12.5.9
