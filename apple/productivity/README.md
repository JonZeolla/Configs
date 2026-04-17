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
    1.  This script is not tested, and is almost guaranteed fail. Use it at your own risk. Consider reviewing and running the contents manually line-by-line.
    1.  Install Sauce Code Pro from [Nerd fonts](https://www.nerdfonts.com/) (The Source Code Pro equivalent) and setup Warp to use it
    1.  Update "${HOME}/.oh-my-zsh/plugins/git/" to add `--tags --force` to `ggpull`
    1.  Run `uv` and finish the setup.
1.  Setup the `zenable` and `task-master` MCP servers in Cursor.
1.  Configure hotkey preferences like the LaunchBar's emoji keyboard shortcut (⌘+e) and Actions.
1.  Setup the aws cli and gitsign.
1.  Setup the github CLI via `gh auth login && gh extension install actions/gh-actions-cache`.
1.  Open the App Store and install purchased/desirable apps under "Purchased" (Countdown Timer Plus, ...)
1.  Set appropriate Security & Privacy settings under System Settings > Privacy & Security > Privacy.
1.  Grant permissions for the MINI_KEYBOARD remapper (`~/Applications/BikingKeyboardRemap.app`):
    1.  System Settings > Privacy & Security > **Accessibility** > "+" > navigate to `~/Applications/BikingKeyboardRemap.app`
    1.  Restart the agent: `launchctl stop local.biking-keyboard-remap`
    1.  Type a few keys on main keyboard first to register it, then MINI_KEYBOARD A/B map to Space/Enter
1.  Open the following apps and ensure they open at login:
    1.  Micro Snitch
    1.  Little Snitch
    1.  Fathom video
1.  Clean up the dock, leaving it as minimal as possible.
1.  Open finder, then:
    1.  Hit Shift+Cmd+A, and uninstall unwanted Applications like GarageBand.
    1.  Update the Favorites list on the left
    1.  Customize the toolbar to add Path, View, Group, Action, and then Search (right click > Customize Toolbar...)
1.  Configure the OS manually.
    1.  In Dock & Menu Bar, Disable "Automatically rearrange Spaces based on most recent use" and "Automatically hide and show the Dock"
    1.  Speed up desktop switching via Display --> Refresh Rate --> Change from ProMotion to 60 Hertz.
    1.  In Control Center enable "Display the time with seconds" and set "Show volume in the menu bar" to "Always show..."
    1.  Disable F11 to show desktop under Keyboard Shortcuts > Mission control to fix VS Code "step into" shortcut. ([details](https://github.com/Microsoft/vscode/issues/5102))
    1.  Under Lock Screen, ensure password is required immediately after sleep or screen saver.
1.  Setup any standard folder structures, like `~/Documents/Reference`, etc. and migrate information from prior systems.
1.  Migrate any unsynced bookmarks (i.e. from custom Chrome profiles)
1.  Restore the following from backup (if applicable):
    1.  ~/.ssh/
        - Add any configs to mapping usernames and keys to hostnames.
        - Add any git-related configs, such as the following. Note this works in combination with configs in .gitconfig:
        ```
        Host github.com
          Hostname github.com
          User git
          IdentityFile ~/.ssh/changeme-github
          IdentitiesOnly yes
        Host gitlab-zenable-demo
          Hostname gitlab.com
          User git
          IdentityFile ~/.ssh/changeme-gitlab-demo
          IdentitiesOnly yes
        Host gitlab.com
          Hostname gitlab.com
          User git
          IdentityFile ~/.ssh/changeme-gitlab
          IdentitiesOnly yes
        ```
