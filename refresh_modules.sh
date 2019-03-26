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
envdir=$(puppet config --section main print environmentpath)/$PUP_ENV

if [ ! -d $envdir/site ]
then
  fail "No controlrepo found in ${envdir}. Have you installed and run g10k yet?"
  exit 1
fi

g10k -puppetfile install \
  -config /etc/puppetlabs

success "Refreshed modules in ${envdir}/modules. Don't forget to create symlinks if needed."

exit 0
