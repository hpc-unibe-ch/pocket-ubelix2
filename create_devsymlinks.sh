#!/usr/bin/env bash

set -e

# Settings; change to your needs
PUP_ENV=ubelixng

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
prodenv=$(puppet config print environmentpath)/$PUP_ENV
puppetenv_local=$workdir/puppetenv

if [ ! -d $prodenv/modules/site ]
then
  fail "No puppetenv found in ${prodenv}. Have you installed and run r10k yet?"
  exit 1
fi

rm -rf $prodenv/hiera.yaml && ln -sf $puppetenv_local/hiera.yaml $prodenv/hiera.yaml
rm -rf $prodenv/data && ln -sf $puppetenv_local/data $prodenv/data
rm -rf $prodenv/environment.conf && ln -sf $puppetenv_local/environment.conf $prodenv/environment.conf
rm -rf $prodenv/Puppetfile && ln -sf $puppetenv_local/Puppetfile $prodenv/Puppetfile
rm -rf $prodenv/manifests && ln -sf $puppetenv_local/manifests $prodenv/manifests
rm -rf $prodenv/modules/site && ln -sf $puppetenv_local/modules/site $prodenv/modules/site
rm -rf $prodenv/modules/repo_ubelix && ln -sf $puppetenv_local/modules/repo_ubelix $prodenv/modules/repo_ubelix

success "Replaced relevant data with content from shared folder."

exit 0
