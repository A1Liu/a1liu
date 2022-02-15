#!/bin/bash

sudo mv /etc/apt/preferences.d/nosnap.pref ~/Documents/nosnap.backup
sudo apt update
sudo apt upgrade

sudo apt-get install nvidia-driver-510
sudo apt-get remove xserver-xorg-video-nouveau

sudo apt-get install snapd

sudo snap install 1password
sudo snap install spotify
sudo snap install slack --classic

sudo apt-get remove vim-tiny
sudo apt-get install git
sudo apt-get install vim-gtk
sudo apt-get install tmux
sudo apt-get install ripgrep

sudo snap install webstorm --classic

ssh-keygen -t ed25519 -C 'albertymliu@gmail.com' -N '' -q -f ~/.ssh/id_ed25519
