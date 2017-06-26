#!/usr/bin/env bash

set -e

# Source settings and common functions
workdir=$(dirname -- $(readlink -f $0))
source $workdir/shellfunctions.sh
source $workdir/settings.conf

if ! which puppet >/dev/null 2>&1
then
  fail "You must first install puppet agent by running setup_puppet-agent.sh"
  exit 1
fi

if ! rpm -qa | grep puppetdb >/dev/null 2>&1
then
  # We want several hostnames in the certificate for puppetdb.
  # Rolling out static puppet agent config from installer.
  cp $workdir/resources/puppet.conf.puppetdb $(puppet config print config)

  info "About to run puppet agent for the first time."
  info "Certificate signing on the puppet master is needed."
  prompt_confirm "Ready to sign the certificate?"

  puppet agent -t --waitforcert 10
  #if devenv
  #sed -i 's/Xms2g/Xms1g/' /etc/sysconfig/puppetserver
  #sed -i 's/Xmx2g/Xmx1g/' /etc/sysconfig/puppetserver
  success "PuppetDB has been installed."
else
  info "PuppetDB is already installed."
fi

if ! systemctl status puppetdb.service >/dev/null 2>&1; then
  systemctl start puppetserver.service
  echo "PuppetDB has been started."
else
  success "PuppetDB is already running."
fi

exit 0

