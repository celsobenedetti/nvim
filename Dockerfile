FROM alpine:edge

WORKDIR /root

RUN apk add git lazygit neovim ripgrep alpine-sdk fzf fd --update

RUN git clone https://github.com/LazyVim/starter /root/.config/nvim

RUN git config --global --add safe.directory /app

CMD [ "bash" ]
