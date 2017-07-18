#!/usr/bin/env bash

set -e

workdir=$(dirname -- $(readlink -f $0))
source $workdir/shellfunctions.sh
source $workdir/prefs.conf

#
# Add Puppetlabs yum repository
#
if ! rpm -qa | grep puppetlabs-release-$PUPCOL_VER >/dev/null 2>&1; then
  info "Installing puppet collection repo. This may take a while."
  yum -y install $PUPCOL_URL >/dev/null
  yum clean all >/dev/null
  yum makecache >/dev/null
  success "Puppet collection repo has been installed."
else
  success "Puppet collection repo is already available."
fi

#
# Install puppetserver package
#
if ! rpm -qa | grep puppetserver >/dev/null 2>&1; then
  info "Installing puppetserver."

  # Install puppetserver and adjust $PATH
  yum -y install puppetserver >/dev/null 2>&1

  success "Puppet server has been installed"
else
  success "Puppet server is already installed."
fi

# Make puppet available if needed
if ! type puppet >/dev/null 2>&1
then
  source /etc/profile.d/puppet-agent.sh
fi

# Setup config paths used later
confdir=$(puppet config print confdir)
envpath=$(puppet config print environmentpath)

#
# Delete global hiera.yaml, use only environment specific data
# and clear out current environments
#
rm -f  $confdir/hiera.yaml
rm -rf $envpath/*

#
# Explicitly set the environment for the puppetmaster
#
# All envs will be availble, so we can set it in main, which makes
# puppet lookup as expected!
#
# Until the first r10k run we fake the environment though.
#
puppet config set --section main environment "${ENVIRONMENT}"
mkdir -p $envpath/$ENVIRONMENT

#
# Custom mapping for UBELIX subrole
#
cat > $confdir/custom_trusted_oid_mapping.yaml << YAML
oid_mapping:
  1.3.6.1.4.1.34380.1.2.13:
    shortname: 'ux_subrole'
    longname:  'UBELIX subrole'
YAML

#
# Additional csr attributes for the puppetmaster
#
csr_attr_file=$confdir/csr_attributes.yaml
cat > $csr_attr_file << YAML
extension_requests:
  1.3.6.1.4.1.34380.1.1.13: "infraserver"
  1.3.6.1.4.1.34380.1.2.13: "puppetmaster"
YAML
chown puppet:puppet $csr_attr_file

#
# Lower memory settings in vagrant boxes
#
if [ -d /vagrant ]
then
  info "Adjusting heap size for puppetserver."
  sed -i 's/Xms2g/Xms1g/' /etc/sysconfig/puppetserver
  sed -i 's/Xmx2g/Xmx1g/' /etc/sysconfig/puppetserver
fi

#
# Regenerate all certificates to pickup extensions
# for the puppet master.
#
if prompt_confirm "Regenerate puppetmaster's CA at $(puppet config print ssldir)?"
then
  rm -rf $(puppet config print ssldir)
  puppet cert list -a >/dev/null
  puppet master
  kill -9 $(ps aux  | grep "[p]uppet master" | awk '{print $2}')
  success "Successfully created new Puppet CA."
fi

#
# Install and configure eyaml
#
# Configdir for standalone configuration
eyaml_confdir=/etc/eyaml
# Directory for encyrption keys
eyaml_keydir=$confdir/eyaml
mkdir -p $eyaml_keydir
chown -R puppet:puppet $eyaml_keydir
chmod -R 0500 $eyaml_keydir

# Config for standalone usage on cli
mkdir -p $eyaml_confdir
cat << EOF > $eyaml_confdir/config.yaml
pkcs7_private_key: '${eyaml_keydir}/private_key.pkcs7.pem'
pkcs7_public_key: '${eyaml_keydir}/public_key.pkcs7.pem'
EOF

# Eyaml installation
if ! type eyaml >/dev/null 2>&1; then
  # Install hiera-eyaml gem in appropriate locations;
  # once for cli usage
  /opt/puppetlabs/puppet/bin/gem install hiera-eyaml --no-ri --no-rdoc >/dev/null
  ln -s /opt/puppetlabs/puppet/bin/eyaml /opt/puppetlabs/bin/eyaml
  # once to be used by puppetserver
  /opt/puppetlabs/bin/puppetserver gem install hiera-eyaml --no-ri --no-rdoc >/dev/null
fi

# Do not alter global hiera.yaml
# hiera.yaml is finally environemtn specific
success "eyaml is now setup and configured."

#
# r10k installation and configuration
#
# Git is needed for r10k to work.
if ! type git >/dev/null 2>&1
then
  yum -y install git >/dev/null 2>&1
fi

# Install r10k gem in appropriate location and generate necessary directories.
if ! type r10k >/dev/null 2>&1
then
  /opt/puppetlabs/puppet/bin/gem install r10k --no-ri --no-rdoc >/dev/null
  ln -s /opt/puppetlabs/puppet/bin/r10k /opt/puppetlabs/bin/r10k
  mkdir -p $R10K_CONFDIR
  mkdir -p $R10K_CACHEDIR
fi

# Configuration of r10k
cat << EOF > $R10K_CONFDIR/r10k.yaml
# The location to use for storing cached Git repos
:cachedir: '$R10K_CACHEDIR'

# A list of git repositories to create
:sources:
  # This will clone the git repository and instantiate an environment per
  # branch in /etc/puppetlabs/code/environments
  :ubelix-puppetenv:
    remote: '$PUPPETENV_URL'
    basedir: '$envpath'
    prefix: false
EOF

# Add public read only key for UBELIX to do bitbucket clones
if [ ! -d ~/.ssh/ ]; then
  mkdir -p ~/.ssh/
  chmod 700 ~/.ssh/
fi

if ! grep "idos-code" ~/.ssh/config >/dev/null 2>&1; then
  cat << 'EOF' >> ~/.ssh/config

Host idos-code.unibe.ch
    User git
    Hostname idos-code.unibe.ch
    PreferredAuthentications publickey
    IdentityFile ~/.ssh/ubelix_bitbucket_rsa

EOF
fi

if [ ! -f ~/.ssh/known_hosts ] || ! cat ~/.ssh/known_hosts 2>/devnull | grep "idos-code" >/dev/null; then
  cat << 'EOF' >> ~/.ssh/known_hosts
[idos-code.unibe.ch]:7999,[130.92.253.206]:7999 ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCrC7tqEA/QDGCito53+9nO/n8ndXYqrNvqWfoOZS87heChNsYykbWIOqMdYisV+ELgniDQb0BFXAieHq+Rs3Y1PduoYbRXIjoqpVf8hxbrKdcbYNh+xizWuaeZ3UAK1rFaESnPOWn+cVK4HIFPc9oREj4rhSAFDVAF7DLA0S3tPLhhUuVcTkXYENyGY1AvFfEp5aCyA2d0WuRci1Mt5w8PuH40mP5sCXH8IZ6dIydypNMtQHdNbKMcit4dKrgAWlqHvg+eW4AMiidyEDz9z25mivcQPBNbnK2/IfW1IeavafhLHF2mTQkzvzm7leJ7v8J9aJtt2aGqM+JYokucW+XL
EOF
fi

success "R10K is now setup and configured"

#
# Start/restart the puppetserver but do not yet start puppet-agent
#
if ! systemctl status puppetserver.service >/dev/null 2>&1; then
  systemctl enable puppetserver.service
  systemctl start puppetserver.service
  success "Puppet server has been started."
else
  systemctl restart puppetserver.service
  success "Puppet server has been restarted."
fi

info "The follwoing actions are not automatically done. Do them now:"
echo ""
info "* Place public and private key for eyaml encryption to:"
info "    ${eyaml_keydir}/private_key.pkcs7.pem"
info "    ${eyaml_keydir}/public_key.pkcs7.pem"
info "* Place public and private key for idos-code connectivity to:"
info "    /root/.ssh/ubelix_bitbucket_rsa"
info "    /root/.ssh/ubelix_bitbucket_rsa.pub"
info "    chmod 600 ~/.ssh/ubelix_bitbucket_rsa"
info "* Deploy the environemnts by issuing"
info "    r10k deploy environment -pv"
info "* Test the setup by issuing"
info "    puppet lookup --node=puppet01.ubelix.unibe.ch ntp::servers"
echo ""
info "If everything is ok, then run puppet agent for the first time on puppetmaster before adding nodes."

exit 0
