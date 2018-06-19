# Productivity configurations for macOS
1.  Install `git` (via developer tools if you have plenty of disk space, otherwise use brew) and clone this repo.
  1.  If you attempt to run a `git` command without having the developer tools installed, it should prompt you to install them appropriately.
1.  Run `setup.sh`
  1.  After completion, open iTerm 2, open Preferences, click on the "Profiles" icon in the preferences toolbar, then select the "colors" tab. Click on the "load presets" and select "import...". Select the Solarized Dark theme file from ~/.iterm2/ (To display hidden files, press command, shift, and period).\*
  1.  To apply the Solarized color presets into iTerm 2, select an existing profile from the profile list window on the left, or create a new profile. Then select the Solarized Dark preset from the "Load Presets" drop down.\*
1.  Manually install the following applications:
    1.  [Evernote](https://itunes.apple.com/us/app/evernote-stay-organized/id406056744)
    1.  [Wire](https://itunes.apple.com/us/app/wire-private-messenger/id931134707)
    1.  Microsoft Office
    1.  [Magnet](https://itunes.apple.com/us/app/magnet/id441258766?mt=12)
        - Don't forget to set start at login
1.  Open the App Store and install purchased/desirable apps under "Purchased"
1.  Open finder, hit Shift+Cmd+A, and uninstall unwanted Applications
1.  Restore the following from backup (if applicable):
    1.  ~/.ssh/
    1.  Printers (Relevant post [here](https://discussions.apple.com/thread/2775350?tstart=0))
        - Restart cups after with `sudo launchctl stop org.cups.cupsd;sudo launchctl start org.cups.cupsd`
        - Set locked/private jobs appropriately
1.  Configure the following application settings:
    1.  `weechat`
        1.  `/secure passphrase <Insert your passphrase here>`
        1.  `/secure set freenode <Insert your freenode password here>`
    1.  `visual studio code`
        1.  Install the `powershell` and `vscodevim` extensions (Hit `F1` then type "Extension")
1.  Configure the following system settings:
    1.  Show volume in menu bar ([details](http://apple.stackexchange.com/a/151589))
    1.  Add seconds display to the clock
    1.  Require password immediately after sleep or screen saver begins ([details](https://support.apple.com/kb/PH18669?locale=en_US))
    1.  Uncheck "Displays have separate spaces" ([details](http://www.imore.com/how-span-window-between-two-displays-mavericks))
1.  Install `eapol_test`:
    1. `mkdir ~/src/`
    1. `cd ~/src/`
    1. `wget http://w1.fi/releases/wpa_supplicant-2.6.tar.gz`
    1. `tar -xvf wpa_supplicant-2.6.tar.gz`
    1. `cd wpa_supplicant-*/wpa_supplicant/`
    1. `cp defconfig .config`
    1. Do the following:
    ```
    cat >> .config << EOF
    CFLAGS += -I/usr/local/opt/openssl/include
    LIBS += -L/usr/local/opt/openssl/lib
    CONFIG_EAPOL_TEST=y
    CONFIG_L2_PACKET=freebsd
    CONFIG_OSX=y
    EOF
    ```
    1. `make eapol_test`
    1. `cp eapol_test ~/bin/`

\* Modified comments from [here](https://github.com/altercation/solarized/tree/master/iterm2-colors-solarized).

