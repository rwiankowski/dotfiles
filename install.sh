#!/usr/bin/env bash

#Install Fonts

#A set of Noto fonts
sudo pacman -S noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra

# Additional TTF fonts

sudo pacman -S ttf-liberation ttf-dejavu ttf-roboto

# Monospace and Hack fonts
sudo pacman -S ttf-jetbrains-mono ttf-fira-code ttf-hack ttf-hack-nerd

# Configure Fonts

sudo cp Config/Fonts/local.conf /etc/fonts/
