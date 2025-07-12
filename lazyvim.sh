#!/bin/bash
docker run -it --rm \
  -w /root \
  -v "$(pwd):/project" \
  alpine:edge \
  sh -uelic '
        apk add git neovim fzf curl ripgrep lazygit alpine-sdk --update
        git clone https://github.com/LazyVim/starter ~/.config/nvim
        cd /project
        sh
    '
