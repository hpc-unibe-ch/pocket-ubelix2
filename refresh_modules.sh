#!/usr/bin/env bash

set -e

# Setup variables
workdir=$(dirname -- $(readlink -f $0))
source $workdir/settings.inc.sh

# Checking environment
if ! type puppet >/dev/null 2>&1
then
  fail "Puppet binary not found."
  exit 1
fi

if [ ! -f /etc/vagrant_box_build_time ]
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

g10k -puppetfile install -config /etc/puppetlabs

success "Refreshed modules in ${envdir}/modules. Don't forget to create symlinks if needed."

exit 0
