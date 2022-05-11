---
title: Linux Development
categories: [personal, linux]
tags: [linux]
---
I've started developing on Linux! Here's a recounting of some of the things I've learned,
in part because sharing information is important, and in part because I might forget
what I did.

### Initial Plan
I've been meaning to try using Linux for a while now. My plan was to buy a Chromebook,
and install [GalliumOS][gallium-os] on it. From there, I'd start downloading apps
and figure out a plan of attack for customizing it for maximum performance.

[gallium-os]: https://galliumos.org/

### First Steps
I researched a few models of Acer, Dell, and HP computers using [the guide on the
GalliumOS wiki][hardware-guide], and was just about to buy an Acer,
when my friend Alex basically said I could have his! He had an old Acer C720, and
basically just gave it to me, so that's what I'll be working with.

[hardware-guide]: https://wiki.galliumos.org/Hardware_Compatibility

So I started by installing GalliumOS; [the instructions on the wiki][install-guide]
is pretty great, but here's a few things I learned that weren't mentioned there.

[install-guide]: https://wiki.galliumos.org/Installing

*  **You can only edit the firmware if you're running ChromeOS** - The initial firmware
   that the laptop comes with can only be edited with the write screw unscrewed,
   but doing that prevents the hardware from booting up in legacy mode (which is
   what GalliumOS boots up in if you don't install fresh firmware beforehand). If
   you want to upgrade the firmware, you have to do it with ChromeOS installed.
*  **You should edit the firmware** - The initial firmware just makes booting your
   computer annoying; just install the firmware from [MrChromeBox.tech][mr-chromebox-tech].
   For the Acer C720, I used [this video][acer-c720-disassembly].
*  **You probably don't need to back up your computer** - ChromeOS is available
   online for free; you can reset your device at any time. Unless you stored important
   files on the chromebook, you don't need to back it up.

[mr-chromebox-tech]: https://mrchromebox.tech/#fwscript
[acer-c720-disassembly]: https://www.youtube.com/watch?v=BG4ZWbimONQ

### Packages and Shell Scripting
Customizing was fun! I started by updating and upgrading the installed software:

```bash
sudo apt dist-upgrade
sudo apt update
sudo apt upgrade
```

Then I installed some stuff I use frequently:

```bash
sudo apt install software-properties-common
sudo apt install git snapd
sudo apt install python3.6 python2.7

# Neovim
add-apt-repository ppa:neovim-ppa/stable
apt install neovim

# Z shell
apt install zsh
chsh -s /bin/zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
```

I additionally tried to set up GNOME software, but
kinda failed in that regard; more on that later.

### Keyboard Stuff
The keyboard is set kinda weirdly; I wanted to change it to make the keys a little
more useful for using Vim. This took a while, but eventually I found [this article][keyboard-rebinding]
that explains exactly what to do for the simple stuff.

*  I changed the caps-lock to escape, because ViM.
<!-- *  I changed the power key to delete, because I keep accidentally pressing it at
   annoying times; [exact instructions here][remap-power-key] -->

[keyboard-rebinding]: http://www.fascinatingcaptain.com/projects/remap-keyboard-keys-for-ubuntu/
[remap-power-key]: https://www.reddit.com/r/GalliumOS/comments/8e956k/remap_power_key_to_delete/

### Integrating with GNOME
I searched the internet for a few hours before figuring this one out, and it all started
because I wanted to be able to use the same calendar on all my devices. That shouldn't
be too hard; there's a list of calendar apps for Linux online, and I picked the
best looking one, GNOME Calendar. Here's the problems that I had after that, and
how I solved each one:

*  **GNOME Calendar was unresponsive** - I installed it with `sudo apt-get install gnome-calendar`,
   but I couldn't *do* anything with it; I'd open it, and then nothing would happen
   when I'd try to open any of the menus.  
   *Solution:* GNOME Calendar needs to be installed with a few other things to get
   its full functionality. I installed `gnome-control-center`
*  **GNOME Control Center was empty** - I ran `gnome-control-center`, but when
   I tried to use it, I'd see a window with maybe 2 or 3 settings icons, none of
   which were "online accounts".  
   *Solution:* GNOME Control Center by default kinda disables itself if you're not
   in the GNOME desktop. To fix, you can do one of two things, as described
   in [this article][integrating-gnome]:

   *  `env XDG_CURRENT_DESKTOP=GNOME gnome-control-center` - If you launch from
      the command line, you need to prepend the command with an environment to
      trick the app into thinking you're using GNOME desktop.
   *  Editing `/usr/share/applications/gnome-control-center.desktop` - For a desktop
      launcher, first copy the file at `/usr/share/applications/gnome-control-center.desktop`
      into the folder `~/.local/share/applications/` with

      ```bash
      cp "/usr/share/applications/gnome-control-center.desktop" "~/.local/share/applications"
      ```

      This step isn't technically necessary, but if you're using a machine with multiple
      user you won't mess up their version of the launcher this way. Also I think
      that you don't need to use `sudo` if you do it this way (not sure though, forgot <!-- TODO check this -->
      to test that). Next, you want to edit that file. It'll look something like this:

      ```bash
      Type=Application
      Name=Settings
      Exec=gnome-control-center --overview
      Icon=Software
      OnlyShowIn=GNOME;Unity;
      ... # Rest ommitted for brevity
      ```

      You want to change `Exec=gnome-control-center --overview` to
      `Exec=env XDG_CURRENT_DESKTOP=GNOME gnome-control-center --overview` so that
      the application is usable, and delete the line `OnlyShowIn=GNOME;Unity;` to
      show the icon in the GUI. The end result looks something like this:

      ```bash
      Type=Application
      Name=Settings
      Exec=env XDG_CURRENT_DESKTOP=GNOME gnome-control-center --overview
      Icon=Software
      ... # Rest ommitted for brevity
      ```
*  **Online Accounts Not Really Loading** - This was pretty confusing;
   there was a blue bar near the top of the screen that seemed like it
   was getting larger, kinda like a loading bar, but I wasn't sure. I
   spent quite a bit of time trying to figure out why there was essentially
   no UI or anything, and eventually stumbled upon
   [this AskUbuntu question][ask-ubuntu-wifi] that worked for me.

[integrating-gnome]: http://www.webupd8.org/2016/03/use-gnome-318-google-drive-integration.html
[ask-ubuntu-wifi]: https://askubuntu.com/questions/1111749/online-accounts-are-very-slow

