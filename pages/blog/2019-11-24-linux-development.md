---
title: "Linux Dev - Part 2: Elementary OS"
categories: [personal, linux]
tags: [linux]
---
I'm trying to install ElementaryOS, and it's pretty annoying. Probably easier than
other linux distros though. I'm running on an CHUWI LapBook Pro 14.1.

## Pain Point: `Could not get lock /var/lib/dpkg/lock-frontend - open`
Only one instance of the package manager can be running at a time, and this is the
message that you get when trying to update in parallel.

## Pain Point: Wifi
This feels like it has and always will be a pain point for Linux. I don't want to
have to know the style of connection I'm using in order to browse the web.

## Pain Point: Display Not Recognized
The display, for whatever reason, is recognized as 800 x 600, which makes
everything way larger than it needs to be.

## Pain Point: Keyboard Shortcuts
The keyboard shortcuts are annoying coming from Mac. `Meta-W` shows all windows,
instead of closing a window. `Meta-T` opens a window, instead of a tab.

## Awesome Feature: Keyboard Modifier Keys
You can just... edit your modifier keys. Like on Macbooks. It's that simple. I just
clicked. It's incredible.

## Pain Point: Pantheon Terminal
"Natural copy-paste" prevents visual block mode in Vim, and must be disabled with
a poorly documented setting
(`gsettings set io.elementary.terminal.settings natural-copy-paste false`).

## Awesome Feature: Alt + Tab
I know this isn't ElementaryOS exclusive, but it's still really nice. I haven't lost
any productivity in switching off of mac, because the keyboard shortcuts I used
to use are either exactly the same or only slightly different.

## Awesome Feature: Pantheon Terminal
After having used the terminal for a few weeks, it's actually not that bad. I haven't
had to make any changes to the terminal to use things like italics. That might be
because of my configs, but who cares. It works seamlessly, and that's what matters.

<!--

Topics:
xkb - For some reason doing the previous thing with caps-lock bound to control doesn't
work.
https://www.happyassassin.net/2014/01/25/uefi-boot-how-does-that-actually-work-then/
https://medium.com/@damko/a-simple-humble-but-comprehensive-guide-to-xkb-for-linux-6f1ad5e13450
https://askubuntu.com/questions/53038/how-do-i-remap-the-caps-lock-key
https://www.howtogeek.com/194705/how-to-disable-or-reassign-the-caps-lock-key-on-any-operating-system/

gnome - Gnome didn't help at all; I ended up using gcalcli and conky, which
work great actually

upgrading to galliumos 3.0 - I'm upgrading my distribution so I'll have another opportunity to test by setup script for my computer!
-->

