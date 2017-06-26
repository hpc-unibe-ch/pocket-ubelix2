#!/usr/bin/env bash

set -e

# Source settings and common functions
workdir=$(dirname -- $(readlink -f $0))
source $workdir/shellfunctions.sh
source $workdir/settings.conf

if ! rpm -qa | grep puppetlabs-release-$PUPCOL_VER >/dev/null 2>&1; then
  info "Installing puppet collection repo. This may take a while."
  yum -y install $PUPCOL_URL >/dev/null
  yum clean all >/dev/null
  yum makecache >/dev/null
  success "Puppet collection repo has been installed."
else
  success "Puppet collection repo is already available."
fi

if ! rpm -qa | grep puppetserver >/dev/null 2>&1; then
  info "Installing puppetserver."

  # Install puppetserver and adjust $PATH
  yum -y install puppetserver >/dev/null
  source /etc/profile.d/puppet-agent.sh
  # Install some module used while bootstrapping
  # the puppet infrascture
  puppet module install puppetlabs-puppet_agent --version 1.4.0
  puppet module install puppetlabs-puppetdb     --version 5.1.2
  puppet module install puppetlabs-apache       --version 1.11.0
  puppet module install puppet-puppetboard      --version 2.9.0

  # Do this only on vagrant boxes
  if [ -d /vagrant ]
  then
    # Lesser memeory on vagrant machine
    info "Adjusting heap size for puppetserver."
    sed -i 's/Xms2g/Xms1g/' /etc/sysconfig/puppetserver
    sed -i 's/Xmx2g/Xmx1g/' /etc/sysconfig/puppetserver

    # Perhaps, the following could be useful in production too
    # Two stage deployment of puppetmaster, puppetdb and then
    # in second stage configure puppetmaster to use puppetdb.
    prodenv=$(puppet config print environmentpath)/production
    rm -rf $prodenv/hieradata && ln -s $workdir/hieradata $prodenv/hieradata
    rm -rf $prodenv/manifests && ln -s $workdir/manifests $prodenv/manifests
    rm -rf $prodenv/modules && ln -s $workdir/modules $prodenv/modules
  fi
  success "Puppet server has been installed"
else
  success "Puppet server is already installed."
fi

# Start the puppetserver but do not yet start puppet-agent
if ! systemctl status puppetserver.service >/dev/null 2>&1; then
  systemctl enable puppetserver.service >/dev/null 2>&1
  systemctl start puppetserver.service
  success "Puppet server has been started."
else
  success "Puppet server is already running."
fi

info "Running puppet agent now. Warnings"
info "and errors are expected on first run"
if ! type puppet >/dev/null 2>&1
then
  source /etc/profile.d/puppet-agent.sh
fi
puppet agent -t

exit 0

