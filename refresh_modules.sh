#!/usr/bin/env bash

set -e

# Source preferences and common functions
workdir=$(dirname -- $(readlink -f $0))
source $workdir/shellfunctions.sh
source $workdir/prefs.conf
prodenv=$(puppet config print environmentpath --section main)/$ENVIRONMENT

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

if [ ! -d $prodenv/site ]
then
  fail "No controlrepo found in ${prodenv}. Have you installed and run r10k yet?"
  exit 1
fi

r10k puppetfile install \
  --verbose \
  --puppetfile $prodenv/Puppetfile \
  --moduledir $prodenv/modules

success "Refreshed modules in ${prodenv}/modules."

exit 0
