# Install chocolately
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1))

# Install things
choco install git docker burp-suite-free-edition etcher nmap putty wireshark sublimetext3 winscp winpcap googlechrome
