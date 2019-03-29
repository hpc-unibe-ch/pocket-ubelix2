#!/usr/bin/env bash

set -e

workdir=$(dirname -- $(readlink -f $0))
source $workdir/settings.inc.sh

# Settings file validation
if [[ -z $TENANT || -z $PUP_ENV ]]
then
  warning "Verify the variables in settings.inc.sh first!"
  exit 1
fi

# Argument validation
role=""
tribe=""
if [ $# -eq 3 ]
then
  role="$1"
  tribe="$2"
  location="$3"
else
  warning "Usage: $0 \$role \$tribe (local|ubelix)"
  exit 1
fi

# Install puppet repo
if ! rpm -qa | grep puppet${PUP_VER}-release >/dev/null 2>&1
then
  info "Installing Puppet repository. This may take a while."
  yum -y install $PUP_URL >/dev/null
  yum clean all >/dev/null
  rm -rf /var/cache/yum
  yum makecache fast >/dev/null
  success "Puppet collection repo has been installed."
else
  success "Puppet collection repo is already available."
fi

# Install puppet-agent package
if [ ! -f /etc/profile.d/puppet-agent.sh ]
then
  info "Installing puppet agent. This may take a while."
  yum -y install puppet-agent >/dev/null 2>&1

  success "Puppet agent has been installed."
else
  success "Puppet agent is already installed."
fi

if ! which puppet >/dev/null 2>&1
then
  echo ""
  info "To use puppet source the profile file or relogin:"
  info "$ source /etc/profile.d/puppet-agent.sh\n"
fi

source /etc/profile.d/puppet-agent.sh

# Configure puppet agent
puppet config set environment "${PUP_ENV}"         --section agent
puppet config set runinterval "${PUP_RUNINTERVAL}" --section agent
puppet config set runtimeout  "${PUP_RUNTIMEOUT}"  --section agent

confdir=$(puppet config print confdir --section main)
csr_attr_file=$confdir/csr_attributes.yaml
cat > $csr_attr_file << YAML
extension_requests:
  1.3.6.1.4.1.34380.1.2.1: "${role}"
  1.3.6.1.4.1.34380.1.2.2: "${location}"
  1.3.6.1.4.1.34380.1.2.3: "${tribe}"
YAML

echo ""
info "Finally run puppet agent if ready and sign the certificate on the puppetmaster."

exit 0
