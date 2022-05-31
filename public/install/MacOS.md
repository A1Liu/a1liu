# De-Stupifying MacOS Guide

1. Fix the Keyboard (System Preferences -> Keyboard)
   1. Turn OFF: Shortcuts -> Mission Control -> ALL
   1. Turn OFF: Shortcuts -> Input Sources -> ALL
   1. Turn OFF: Shortcuts -> Services -> Searching -> ALL
   1. Turn OFF: Shortcuts -> Services -> Text -> ALL
   1. (if present) Set to "Do Nothing": Keyboard -> Press `GLOBE ICON` to
   1. (if present) Set to "Expanded Control Strip": Keyboard -> Touch bar shows
   1. Customize: Keyboard -> Customize Control Strip
2. Remove keyboard text
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
   1. Turn ON: Show Bluetooth in menu bar
   1. Set to "when last connected to this mac": `AIRPOD NAME` -> Options ->
      Connect to This Mac

### Bluetooth
Airpods should have the setting "when connecting to this macbook" set to "".
Otherwise they'll keep changing what they're connected to randomly.

### `/etc/hosts` Performance
MacOS is slow when using `/etc/hosts` on multiple lines, so just put all the aliases
for an IP address on a single line.

https://superuser.com/questions/1189379/chrome-slow-to-resolve-etc-hosts-on-macos-os-x
