#!/usr/bin/env bash

set -e

# Settings; change to your needs
ELMAJ_VER="7"
PUP_URL="https://yum.puppetlabs.com/puppet5/puppet5-release-el-${ELMAJ_VER}.noarch.rpm"
PUP_ENV="development"
PUP_ENV_URL="ssh://git@idos-code.unibe.ch:7999/ubelix/ubelix-controlrepo.git"
R10K_CONFDIR=/etc/puppetlabs/r10k
R10K_CACHEDIR=/opt/puppetlabs/r10k/cache

# General functions for output beautification
prompt_confirm() {
  while true; do
    printf "\r  [ \033[0;33m??\033[0m ] ${1:-Continue?} [y/n]: "
    read -r -n 1 REPLY
    case $REPLY in
      [yY]) echo ; return 0 ;;
      [nN]) echo ; return 1 ;;
      *) printf " \033[31m %s \n\033[0m" "invalid input"
    esac
  done
}

info () {
  printf "\r  [ \033[00;34m..\033[0m ] $1\n"
}

user () {
  printf "\r  [ \033[00;33m??\033[0m ] $1"
}

warning () {
  printf "\r  [ \033[00;33m!!\033[0m ] $1\n"
}

success () {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

fail () {
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] $1\n"
  echo ''
  exit
}

# Setup variables
workdir=$(dirname -- $(readlink -f $0))

if [ $# -eq 1 ]
then
  location="$1"
else
  warning "Usage: $0 (local|ubelix)"
  exit 1
fi

#
# Add Puppetlabs yum repository
#
if ! rpm -qa | grep puppet5-release >/dev/null 2>&1; then
  info "Installing puppet collection repo. This may take a while."
  yum -y install $PUP_URL >/dev/null
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
# Explicitly set the environment, see
# https://puppet.com/docs/puppet/latest/configuration.html#environment
#
# We set agent and user, as those are relevant and must be available
# locall.
#
# Until the first r10k run we fake the environment though.
#
puppet config set --section agent environment "${PUP_ENV}"
puppet config set --section user environment "${PUP_ENV}"
mkdir -p $envpath/$PUP_ENV

#
# Enable show_diff to have file diffs; defaults to false
#
puppet config set --section main show_diff true

#
# Custom mapping for UBELIX subrole
#
cat > $confdir/custom_trusted_oid_mapping.yaml << YAML
oid_mapping:
  1.3.6.1.4.1.34380.1.2.1:
    shortname: 'ux_role'
    longname:  'UBELIX Node Role Name'
  1.3.6.1.4.1.34380.1.2.2:
    shortname: 'ux_location'
    longname:  'UBELIX Node Location Name'
  1.3.6.1.4.1.34380.1.2.3:
    shortname: 'ux_tribe'
    longname:  'UBELIX Node Tribe Name'
YAML

#
# Additional csr attributes for the puppetmaster
#
csr_attr_file=$confdir/csr_attributes.yaml
cat > $csr_attr_file << YAML
extension_requests:
  1.3.6.1.4.1.34380.1.2.1: "puppetmaster"
  1.3.6.1.4.1.34380.1.2.2: "${location}"
  1.3.6.1.4.1.34380.1.2.3: "infraserver"
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
  :ubelix-controlrepo:
    remote: '$PUP_ENV_URL'
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
  systemctl enable puppetserver.service >/dev/null 2>&1
  systemctl start puppetserver.service
  success "Puppet server has been started."
else
  systemctl restart puppetserver.service
  success "Puppet server has been restarted."
fi

info "The follwoing actions are not automatically done. Do them now:"
echo ""
info "* Relogin or source the following file to have everything in \$PATH"
info "    source /etc/profile.d/puppet-agent.sh"
echo ""
info "* Place public and private key for eyaml encryption to:"
info "    ${eyaml_keydir}/private_key.pkcs7.pem"
info "    ${eyaml_keydir}/public_key.pkcs7.pem"
info "    chown puppet ${eyaml_keydir}/*.pem"
info "    chmod 440 ${eyaml_keydir}/*.pem"
echo ""
info "* Place public and private key for idos-code connectivity to:"
info "    /root/.ssh/ubelix_bitbucket_rsa"
info "    /root/.ssh/ubelix_bitbucket_rsa.pub"
info "    chmod 600 ~/.ssh/ubelix_bitbucket_rsa"
echo ""
info "* Deploy the environemnts by issuing"
info "    r10k deploy environment [development] -pv"
echo ""
info "* If you are working locally, setup devsymlinks to /vagrant:"
info "    /vagrant/create_devsymlinks.sh"
echo ""
info "* Test the setup by issuing"
info "    puppet lookup --node=puppet01.ubelix.unibe.ch ntp::servers"
echo ""
info "If everything is ok, then run puppet agent for the first time on puppetmaster before adding nodes."

exit 0
