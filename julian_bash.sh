#!/bin/bash

# git stuff
git config --global user.email "julianbrendl@gmail.com"
git config --global user.name "Julian Brendl"
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
git config --global alias.sm submodule

export PATH="$HOME/bin:$PATH"

alias proj='cd ~/projects'
alias log='cd ~/log'
alias ll="eza -lah -snew"

# use highlight inplace of cat
alias cat="highlight $1 --out-format xterm256 --line-numbers --quiet --force --style solarized-light"
