#!/bin/bash

set -e

# Source settings and common functions
source $(dirname $0)/shellfunctions.sh
source $(dirname $0)/settings.conf

if ! rpm -qa | grep puppetlabs-release-$PUPCOL_VER >/dev/null 2>&1; then
  info "Installing puppet collection repo. This may take a while."
  yum -y install $PUPCOL_URL >/dev/null
  yum clean all >/dev/null
  yum makecache >/dev/null
  success "Puppet collection repo has been installed."
else
  success "Puppet collection repo is already available."
fi

if [ ! -f /etc/profile.d/puppet-agent.sh ]; then
  info "Installing puppet agent."
  yum -y install puppet-agent >/dev/null
  source /etc/profile.d/puppet-agent.sh
  success "Puppet agent has been installed."
else
  success "Puppet agent is already installed."
fi

info "Now add dns_alt_names if necessary (puppetdb/foreman)"
info "and run puppet agent."
#puppet agent -t --waitforcert 30

exit 0

