#!/usr/bin/env bash

set -e

# Settings; change to your needs
PUP_ENV=development

# General functions for output beautification
prompt_confirm() {
  while true; do
    printf "\r  [ \033[0;33m??\033[0m ] ${1:-Continue?} [y/n]: "
    read -r -n 1 REPLY
    case $REPLY in
      [yY]) echo ; return 0 ;;
      [nN]) echo ; return 1 ;;
      *) printf " \033[31m %s \n\033[0m" "invalid input"
    esac
  done
}

info () {
  printf "\r  [ \033[00;34m..\033[0m ] $1\n"
}

user () {
  printf "\r  [ \033[00;33m??\033[0m ] $1"
}

warning () {
  printf "\r  [ \033[00;33m!!\033[0m ] $1\n"
}

success () {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

fail () {
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] $1\n"
  echo ''
  exit
}

# Checking environment
if ! type puppet >/dev/null 2>&1
then
  fail "Puppet binary not found."
  exit 1
fi

if [ ! -d /vagrant ]
then
  fail "Not in a virtualbox machine. Refusing to work."
  exit 1
fi

# Setup variables
workdir=$(dirname -- $(readlink -f $0))
prodenv=$(puppet config print environmentpath --section main)/$PUP_ENV
controlrepo_local=$workdir/controlrepo

if [ ! -d $prodenv/site ]
then
  fail "No controlrepo found in ${prodenv}. Have you installed and run g10k yet?"
  exit 1
fi

rm -rf $prodenv/data && ln -sf $controlrepo_local/data $prodenv/data
rm -rf $prodenv/manifests && ln -sf $controlrepo_local/manifests $prodenv/manifests
rm -rf $prodenv/scripts && ln -sf $controlrepo_local/scripts $prodenv/scripts
rm -rf $prodenv/site && ln -sf $controlrepo_local/site $prodenv/site
rm -rf $prodenv/environment.conf && ln -sf $controlrepo_local/environment.conf $prodenv/environment.conf
rm -rf $prodenv/hiera.yaml && ln -sf $controlrepo_local/hiera.yaml $prodenv/hiera.yaml
rm -rf $prodenv/Puppetfile && ln -sf $controlrepo_local/Puppetfile $prodenv/Puppetfile

success "Replaced relevant data with content from shared folder."
echo ""
info "If you want to locally work on a module, just add a symlink the same way in modules/."

exit 0
