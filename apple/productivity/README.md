# Productivity configurations for macOS
1.  Run `setup.sh`
  1.  After completion, open iTerm 2, open Preferences, click on the "Profiles" icon in the preferences toolbar, then select the "colors" tab. Click on the "load presets" and select "import...". Select the Solarized Dark theme file from ~/.iterm2/ (To display hidden files, press command, shift, and period).\*
  1.  To apply the Solarized color presets into iTerm 2, select an existing profile from the profile list window on the left, or create a new profile. Then select the Solarized Dark preset from the "Load Presets" drop down.\*
1.  Manually install the following applications:
  1.  [Evernote](https://itunes.apple.com/us/app/evernote-stay-organized/id406056744)
  1.  [Wire](https://itunes.apple.com/us/app/wire-private-messenger/id931134707)
  1.  Microsoft Office
  1.  [Magnet](https://itunes.apple.com/us/app/magnet/id441258766?mt=12)
1.  Restore the following from backup (if applicable):
  1.  ~/.ssh/
  1.  Printers (Relevant post [here](https://discussions.apple.com/thread/2775350?tstart=0))
    - Restart cups after with `sudo launchctl stop org.cups.cupsd;sudo launchctl start org.cups.cupsd`
    - Set locked/private jobs appropriately
1.  Configure the following application settings:
  1.  `weechat`
    1.  `/secure passphrase <Insert your passphrase here>`
    1.  `/secure set freenode <Insert your freenode password here>`
    1.  `/set irc.server.freenode.sasl_password "${sec.data.freenode}"`
1.  Configure the following system settings:
  1.  Show volume in menu bar ([details](http://apple.stackexchange.com/a/151589))
  1.  Add seconds display to the clock
  1.  Require password immediately after sleep or screen saver begins ([details](https://support.apple.com/kb/PH18669?locale=en_US))
  1.  Uncheck "Displays have separate spaces" ([details](http://www.imore.com/how-span-window-between-two-displays-mavericks))

\* Modified comments from [here](https://github.com/altercation/solarized/tree/master/iterm2-colors-solarized).

