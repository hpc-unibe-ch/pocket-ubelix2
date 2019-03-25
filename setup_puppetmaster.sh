#!/usr/bin/env bash

set -e

# Settings; change to your needs
ELMAJ_VER="7"
PUP_VER="6"
PUP_URL="https://yum.puppetlabs.com/puppet${PUP_VER}/puppet${PUP_VER}-release-el-${ELMAJ_VER}.noarch.rpm"
PUP_ENV="development"
PUP_ENV_URL="ssh://git@idos-code.unibe.ch:7999/ubelix/ubelix-controlrepo.git"
G10K_VER="0.5.8"
G10K_BINDIR=/usr/local/sbin
G10K_WRAPPER=g10k-update-env
G10K_CONFDIR=/etc/puppetlabs/g10k
G10K_CACHEDIR=/opt/puppetlabs/g10k/cache

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
if ! rpm -qa | grep "puppet${PUP_VER}-release" >/dev/null 2>&1; then
  info "Installing Puppet repository. This may take a while."
  yum -y install $PUP_URL >/dev/null
  yum clean all >/dev/null
  yum makecache >/dev/null
  success "Puppet repository has been installed."
else
  success "Puppet repository is already available."
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
confdir=$(puppet config print confdir --section main)
envpath=$(puppet config print environmentpath --section main)

#
# Explicitly set the environment, see
# https://puppet.com/docs/puppet/latest/configuration.html#environment
#
# We set master, agent and user, as those are relevant and must be available
# in locally.
#
# Until the first g10k run we fake the environment directory though.
#
puppet config set environment "${PUP_ENV}" --section master
puppet config set environment "${PUP_ENV}" --section agent
puppet config set environment "${PUP_ENV}" --section user
mkdir -p $envpath/$PUP_ENV

#
# Enable show_diff to have file diffs; defaults to false
#
puppet config set show_diff true --section main

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
ssldir=$(puppet config --section main print ssldir)
if prompt_confirm "Destroy puppetmaster's CA and create new CA at ${ssldir}?"
then
  puppet resource service puppet ensure=stopped >/dev/null
  puppet resource service puppetserver ensure=stopped >/dev/null
  rm -rf "${ssldir}"
  puppetserver ca setup
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
  puppetserver gem install hiera-eyaml --no-ri --no-rdoc >/dev/null
fi

# Do not alter global hiera.yaml
# hiera.yaml is finally environemtn specific
success "eyaml is now setup and configured."

#
# g10k installation and configuration
#
# Git is needed for g10k to work.
if ! type git >/dev/null 2>&1
then
  yum -y install git >/dev/null 2>&1
fi

# Install g10k binary in appropriate location and generate necessary directories.
if ! type g10k >/dev/null 2>&1
then
  wget "https://github.com/xorpaul/g10k/releases/download/v${G10K_VER}/g10k-linux-amd64.zip" >/dev/null 2>&1
  unzip g10k-linux-amd64.zip >/dev/null 2>&1
  mv g10k $G10K_BINDIR/
  rm -f g10k-linux-amd64.zip
  mkdir -p $G10K_CONFDIR
  mkdir -p $G10K_CACHEDIR
fi

cat <<EOF > $G10K_BINDIR/$G10K_WRAPPER
#!/bin/bash

if [ \$# -ne 1 ]
then
  echo "Usage: \${0} (environemnt|all)"
  exit
elif [ \$1 == 'all' ]
then
  target_env="development testing production"
  echo "Updating all environments:"
else
  target_env=\$1
fi

for env in \$target_env
do
  echo ""
  echo "----------------------------"
  echo "Updating environment \${env}:"
  g10k -config $G10K_CONFDIR/g10k.yaml -maxextractworker 20 -maxworker 50 -branch \$env
  echo ""
  echo "Generating Puppet resource types for \${env}"
  puppet generate types --environment \$env
done
EOF
chmod 755 $G10K_BINDIR/$G10K_WRAPPER


# Configuration of g10k
cat << EOF > $G10K_CONFDIR/g10k.yaml
# The location to use for storing cached Git repos
:cachedir: '$G10K_CACHEDIR'

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

success "g10k is now setup and configured"

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
info "    g10k-update-env [\$environment|all]"
echo ""
info "* If you are working locally, setup devsymlinks to /vagrant:"
info "    /vagrant/create_devsymlinks.sh"
echo ""
info "* Test the setup by issuing"
info "    puppet lookup --node=puppet01.ubelix.unibe.ch ntp::servers"
echo ""
info "If everything is ok, then run puppet agent for the first time on puppetmaster before adding nodes."

exit 0
