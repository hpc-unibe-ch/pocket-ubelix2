#!/bin/bash

set -e

workdir=$(dirname -- $(readlink -f $0))
source $workdir/shellfunctions.sh
source $workdir/prefs.conf

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
  success "Puppet agent has been installed."
else
  success "Puppet agent is already installed."
fi


if ! which puppet >/dev/null 2>&1
then
  info "To use puppet source the profile file or relogin:"
  info "$ source /etc/profile.d/puppet-agent.sh\n"
fi

info "Now add dns_alt_names if necessary,"
info "place a csr_attributes.yaml to \$confdir,"
info "and run puppet agent."

exit 0

