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
    1.  This script is not tested, and is almost guaranteed fail. Use it at your own risk. Consider reviewing and running the contents manually line-by-line. You may not need all of the packages that I install.
        1. Configure hotkey preferences like the [LastPass quick search](https://support.logmeininc.com/lastpass/help/how-do-i-use-lastpass-hotkeys-on-my-mac).
    1.  Ensure that iTerm 2 has been properly configured (has a "Presenter Mode" profile, is using Solarized Dark theme, is using the Source Code Pro for Powerline font, etc.).  If it is not, follow the following steps:
        1.  After completion, open iTerm 2, open Preferences > Profiles > Colors. Click on the "load presets" and select "import...". Select the Solarized Dark theme file from ~/.iterm2/ (To display hidden files, press command, shift, and period).\*
        1.  To apply the Solarized color presets into iTerm 2, select an existing profile from the profile list window on the left, or create a new profile. Then select the Solarized Dark preset from the "Load Presets" drop down.\*
        1.  Set the font under Preferences > Profiles > Text to Source Code Pro for Powerline.
1.  Open the App Store and install purchased/desirable apps under "Purchased" (Magnet, NFC Tools, ...)
1.  Install non-brew, non-App Store software, like [GoPro webcam](https://community.gopro.com/t5/en/How-to-Use-Your-GoPro-as-a-Webcam/ta-p/665493).
1.  Set appropriate Security & Privacy settings under System Preferences > Security & Privacy > Privacy.
1.  Configure the OS manually.
    1.  Configure [the trackpad](https://support.apple.com/en-us/HT202319) to be 4 ticks from the right.
    1.  Disable "Automatically rearrange Spaces based on most recent use" in Mission Control.
    1.  Enable "Automatically hide and show the Dock" in Dock & Menu Bar.
    1.  Set "Show Sound in menu bar" to "always" under Sound.
    1.  Enable "Display the time with seconds" under Dock & Menu Bar.
    1.  Ensure the Mission control "Show Desktop" is not set to F11 F11 to fix VS Code "step into" shortcut. ([details](https://github.com/Microsoft/vscode/issues/5102))
    1.  Require password immediately after sleep or screen saver begins under Security & Privacy > General.
1.  Open the following apps and ensure they open at login:
    1.  Micro Snitch
    1.  Magnet
    1.  Little Snitch
1.  Clean up the dock, leaving just Finder, Activity Monitor, and iTerm 2 pinned.
1.  Setup any standard folder structures, like `~/Documents/Reference`, etc. and migrate information from prior systems.
1.  Open finder, then:
    1.  Hit Shift+Cmd+A, and uninstall unwanted Applications
    1.  Update the Favorites list on the left
    1.  Customize the toolbar to add Path, View, Group, Action, and then Search (right click > Customize Toolbar...)
1.  Restore the following from backup (if applicable):
    1.  ~/.ssh/
        - Add any configs to mapping usernames and keys to hostnames.
        - Add any git-related configs, such as:
        ```
        Host github.com
          Hostname github.com
          User git
          IdentityFile ~/.ssh/changeme
        ```
    1.  Printers (Relevant post [here](https://discussions.apple.com/thread/2775350?tstart=0))
        - Restart cups after with `sudo launchctl stop org.cups.cupsd;sudo launchctl start org.cups.cupsd`
        - Set locked/private jobs appropriately
1.  Configure the following application settings:
    1.  `visual studio code`
        1.  Install the `ms-python.python`, `ms-vscode.go`, `ms-vscode.powershell`, `vscodevim.vim`, `ms-vscode.cpptools`, `Terraform`, and `wayou.vscode-todo-highlight` extensions (Hit `F1` then type "Extension")
    1.  Microsoft Outlook
        1.  Setup an email signature.
    1.  Microsoft OneDrive
        1.  Setup appropriate syncs (SharePoint, etc.).
1.  Migrate any unsynced bookmarks (i.e. from custom Chrome profiles)

\* Modified comments from [here](https://github.com/altercation/solarized/tree/master/iterm2-colors-solarized).
