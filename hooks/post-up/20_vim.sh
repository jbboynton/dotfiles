#!/bin/bash

vim_plug_path="$HOME/.vim/autoload/plug.vim"
vim_plug_url="https://raw.githubusercontent.com/junegunn/vim-plug"
vim_plug_url+="/master/plug.vim"

ensure_vim_plug_is_installed() {
  [ -e "$vim_plug_path" ] || install_vim_plug
}

install_vim_plug() {
	curl -fLsSo "$vim_plug_path" --create-dirs "$vim_plug_url"
}

install_vim_plugins() {
  vim -E -s +PlugUpgrade +qa
}

ensure_vim_plug_is_installed && install_vim_plugins
