#!/usr/bin/env bash

set -e

# Setup variables
workdir=$(dirname -- $(readlink -f $0))
source $workdir/settings.inc.sh

if [ ! -f /etc/vagrant_box_build_time ]
then
  fail "Not in a virtualbox machine. Refusing to work."
  exit 1
fi

# Checking environment
if ! type puppet >/dev/null 2>&1
then
  fail "Puppet binary not found."
  exit 1
fi

# Setup variables
workdir=$(dirname -- $(readlink -f $0))
envdir=$(puppet config print environmentpath --section main)/$PUP_ENV
controlrepo_local=$workdir/controlrepo

if [ ! -f $envdir/manifests/site.pp ]
then
  fail "No controlrepo found in ${envdir}. Have you installed and run g10k yet?"
  exit 1
fi

rm -rf $envdir/data && ln -sf $controlrepo_local/data $envdir/data
rm -rf $envdir/manifests && ln -sf $controlrepo_local/manifests $envdir/manifests
rm -rf $envdir/scripts && ln -sf $controlrepo_local/scripts $envdir/scripts
rm -rf $envdir/site && ln -sf $controlrepo_local/site $envdir/site
rm -rf $envdir/environment.conf && ln -sf $controlrepo_local/environment.conf $envdir/environment.conf
rm -rf $envdir/hiera.yaml && ln -sf $controlrepo_local/hiera.yaml $envdir/hiera.yaml
rm -rf $envdir/Puppetfile && ln -sf $controlrepo_local/Puppetfile $envdir/Puppetfile

success "Replaced relevant data with content from shared folder."
echo ""
info "If you want to locally work on a module, just add a symlink the same way in ${envdir}/modules/."

exit 0
