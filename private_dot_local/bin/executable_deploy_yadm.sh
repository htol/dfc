#!/usr/bin/env bash

cd
git clone https://github.com/TheLocehiliosan/yadm.git ~/.local/yadm-project
mkdir -p ~/.local/bin
ln -s ~/.local/yadm-project/yadm ~/.local/bin/yadm
~/.local/bin/yadm clone --bootstrap https://github.com/htol/dotfiles.git
