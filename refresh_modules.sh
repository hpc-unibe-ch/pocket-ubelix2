#!/usr/bin/env bash

set -e

# General settings
PUP_ENV="development"

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

if [ ! -f $envdir/manifests/site.pp ]
then
  fail "No controlrepo found in ${envdir}. Have you installed and run g10k yet?"
  exit 1
fi
cd $envdir

# Preserve devsymlinks to local modules if available
declare -A local_modules
for link in $(find modules -maxdepth 1 -type l)
do
  target=$(readlink $link)
  local_modules+=([$link]=$target)
done

# Delete cache as the cache might cause problems
rm -rf /tmp/g10k
# Deploy fresh copies of all modules
g10k -puppetfile install -config /etc/puppetlabs/g10k/g10k.yaml

# Replay devymlinks of preserved modules
for key in ${!local_modules[@]}
do
  # First delete the fresh copy g10k has deployed
  rm -rf $key

  # and symlink our local version again
  ln -sf ${local_modules[$key]} $key
done


success "Refreshed modules in ${envdir}/modules. Don't forget to create symlinks if needed."

exit 0
