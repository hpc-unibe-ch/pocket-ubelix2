#!/usr/bin/env bash

set -e

# Source preferences and common functions
workdir=$(dirname -- $(readlink -f $0))
source $workdir/shellfunctions.sh
source $workdir/prefs.conf
prodenv=$(puppet config print environmentpath)/$ENVIRONMENT
puppetenv_local=$workdir/puppetenv

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
