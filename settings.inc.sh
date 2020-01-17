#!/usr/bin/env bash

# General settings
TENANT="ID-SYS" # ID-SYS, ID-INF, ...
ELMAJ_VER="7"
PUP_VER="6"
PUP_URL="https://yum.puppetlabs.com/puppet${PUP_VER}/puppet${PUP_VER}-release-el-${ELMAJ_VER}.noarch.rpm"
PUP_ENV="development"
PUP_RUNINTERVAL="1800" # 30m
PUP_RUNTIMEOUT="0"  # unlimited

# Puppet master settings
PUP_ENV_URL="ssh://git@github.com/hpc-unibe-ch/ubelix-controlrepo.git"
G10K_VER="0.8.9"
G10K_URL="https://github.com/xorpaul/g10k/releases/download/v${G10K_VER}/g10k-linux-amd64.zip"
G10K_BINDIR=/usr/local/sbin
G10K_WRAPPER=g10k-update-env
G10K_CONFDIR=/etc/puppetlabs/g10k
G10K_CACHEDIR=/opt/puppetlabs/g10k/cache


# General functions used in shell scripts
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
