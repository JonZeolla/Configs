# Productivity configurations for macOS
1.  If your network allows you to prioritize/QoS systems, consider bumping up the priority of your device for a couple of hours, since there will be a lot of downloads.
1.  Prepare to run the setup script.
    1.  Install Xcode via the macOS App Store.
    1.  Accept the Xcode license, and then clone this repo:
    ```
    sudo xcodebuild -license
    xcode-select --install
    mkdir -p ~/src/jonzeolla
    git clone https://github.com/jonzeolla/configs/ ~/src/jonzeolla/configs/
    ```
1.  Run `~/src/jonzeolla/apple/productivity/setup.sh`
    1.  Ensure that iTerm 2 has been properly configured (has a "Presenter Mode" profile, is using Solarized Dark theme, etc.).  If it is not, follow the following steps:
        1.  After completion, open iTerm 2, open Preferences, click on the "Profiles" icon in the preferences toolbar, then select the "colors" tab. Click on the "load presets" and select "import...". Select the Solarized Dark theme file from ~/.iterm2/ (To display hidden files, press command, shift, and period).\*
        1.  To apply the Solarized color presets into iTerm 2, select an existing profile from the profile list window on the left, or create a new profile. Then select the Solarized Dark preset from the "Load Presets" drop down.\*
1.  Open the App Store and install purchased/desirable apps under "Purchased" (Magnet, NFC Tools, ...)
1.  Set appropriate Security & Privacy settings under System Preferences > Security & Privacy > Privacy.
1.  Configure [scrolling](https://support.apple.com/kb/ph25291?locale=en_US) to have a "non-natural" scroll direction.
1.  Configure [the trackpad](https://support.apple.com/en-us/HT202319) to be 4 ticks from the right.
1.  Open the following apps and ensure they open at login:
    1.  Micro Snitch
    1.  Magnet
    1.  Little Snitch
1.  Clean up the dock, leaving just Finder, Activity Monitor, and iTerm 2 pinned.
1.  Setup any standard folder structures, like `~/Documents/ISOs`, `~/Documents/Reference`, etc.
1.  Open finder, then:
    1.  Hit Shift+Cmd+A, and uninstall unwanted Applications
    1.  Update the Favorites list on the left
    1.  Customize the toolbar to add Path, View, Group, Action, and then Search (right click > Customize Toolbar...)
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
        1.  Install the `ms-python.python`, `ms-vscode.go`, `ms-vscode.powershell`, `vscodevim.vim`, `ms-vscode.cpptools`, and `wayou.vscode-todo-highlight` extensions (Hit `F1` then type "Extension")
    1.  Microsoft Outlook
        1.  Setup an email signature.
    1.  Microsoft OneDrive
        1.  Setup appropriate syncs (SharePoint, etc.).
    1.  JetBrains IntelliJ IDEA
        1.  Install the [free open source license](https://www.jetbrains.com/buy/opensource/) (requires an @apache.org email address).
1.  Configure the following system settings:
    1.  Show volume in menu bar ([details](http://apple.stackexchange.com/a/151589))
    1.  Add seconds display to the clock
    1.  Require password immediately after sleep or screen saver begins ([details](https://support.apple.com/kb/PH18669?locale=en_US))
    1.  Uncheck "Displays have separate spaces" ([details](http://www.imore.com/how-span-window-between-two-displays-mavericks))
    1.  Configure the keyboard to "Use F1, F2, etc. keys as standard function key" ([details](https://support.apple.com/en-us/HT204436))
    1.  Configure the keyboard to remove the Mission Conrol "Show Desktop" shortcut of F11 to fix VS Code "step into" shortcut. ([details](https://github.com/Microsoft/vscode/issues/5102))
1.  Install the latest version of `eapol_test`:
    1. Check `http://w1.fi/releases/` for the latest version of the `wpa_supplicant-x.y.tar.gz` and update the below commands if there is a new release (This is why it's not automated in `setup.sh`).
    1. Run the following.
    ```
    mkdir ~/src ~/bin ~/etc
    cd ~/src
    wget http://w1.fi/releases/wpa_supplicant-2.6.tar.gz
    tar -xvf wpa_supplicant-2.6.tar.gz
    cd wpa_supplicant-*/wpa_supplicant/
    cp defconfig .config
    cat >> .config << EOF
    CFLAGS += -I/usr/local/opt/openssl/include
    LIBS += -L/usr/local/opt/openssl/lib
    CONFIG_EAPOL_TEST=y
    CONFIG_L2_PACKET=freebsd
    CONFIG_OSX=y
    EOF
    cp .config ~/etc/eapol_test_config 
    make eapol_test
    cp eapol_test ~/bin/
    ```

\* Modified comments from [here](https://github.com/altercation/solarized/tree/master/iterm2-colors-solarized).

