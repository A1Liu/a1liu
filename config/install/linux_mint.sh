#!/bin/bash

sudo mv /etc/apt/preferences.d/nosnap.pref ~/Documents/nosnap.backup

sudo apt-get install ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
  https://download.docker.com/linux/ubuntu bionic stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] \
  https://packages.cloud.google.com/apt cloud-sdk main" \
  | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

curl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
  | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

sudo apt update
sudo apt upgrade

sudo apt-get install snapd

sudo apt-get install nvidia-driver-510
sudo apt-get remove xserver-xorg-video-nouveau

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

sudo apt-get install docker-ce docker-ce-cli containerd.io

sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker

