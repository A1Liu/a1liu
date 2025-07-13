# De-Stupifying MacOS Guide

### Set up for development

1. Install XCode tools using `xcode-select --install`
2. Clone repository with `git clone https://github.com/A1Liu/config.git`
3. Install [nix-darwin](https://github.com/LnL7/nix-darwin) and run

   ```sh
   darwin-rebuild switch --flake ./nix/darwin#aliu
   ```

### Fixing the settings
1. Fix the Keyboard (System Preferences -> Keyboard)
   1. Turn OFF: Shortcuts -> Mission Control -> ALL
   1. Turn OFF: Shortcuts -> Input Sources -> ALL
   1. Turn OFF: Shortcuts -> Services -> Searching -> ALL
   1. Turn OFF: Shortcuts -> Services -> Text -> ALL
   1. (if present) Set to "Do Nothing": Keyboard -> Press `GLOBE ICON` to
   1. (if present) Set to "Expanded Control Strip": Keyboard -> Touch bar shows
   1. Customize: Keyboard -> Customize Control Strip
<!-- 2. Remove keyboard text -->
2. Remove annoying Terminal stuff (Terminal -> Preferences)
   1. Set to "Close the Window": Profiles -> Shell -> When Shell Exits
   1. Set to OFF: Profiles -> Advanced -> Bell -> Audible bell
3. Remove trackpad stuff (System Preferences -> Trackpad)
   1. Turn OFF: Point & Click -> Force click and haptic feedback
   1. Turn OFF: More Gestures -> Lauchpad
   1. Turn OFF: More Gestures -> Show Desktop
   1. Turn OFF: More Gestures -> App Expose
4. Turn OFF: System Preferences -> Siri -> Enable Ask Siri
5. Bluetooth (System Preferences -> Bluetooth)
   1. Set to "when last connected to this mac": `AIRPOD NAME` -> Options ->
      Connect to This Mac

      (This prevents airpods from switching back and forth between devices)

### `/etc/hosts` Performance
MacOS is slow when using `/etc/hosts` on multiple lines, so just put all the aliases
for an IP address on a single line.

https://superuser.com/questions/1189379/chrome-slow-to-resolve-etc-hosts-on-macos-os-x

### iTerm Fix for Cmd+R
IDK what this key sequence does, but it messes up the iTerm screen. You can disable
it by setting a keybinding for Cmd+R to ignore (this is already done in the iTerm
config in the `programs` folder).
