#!/bin/bash

set -e

ELMAJ_VER="7"
PUPCOL_VER="pc1"
PUPCOL_URL="http://yum.puppetlabs.com/puppetlabs-release-${PUPCOL_VER}-el-${ELMAJ_VER}.noarch.rpm"
ENVIRONMENT="ubelixng"

workdir=$(dirname -- $(readlink -f $0))

# General functions used in shell scripts
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

# Argument validation
params=0
role=""
subrole=""
if [ $# -gt 0 ]
then
  if [ $# -eq 3 ]
  then
    params=1
    role="$1"
    subrole="$2"
    location="$3"
  else
    warning "Usage: $0 [role subrole [(local|ubelix)]"
    exit 1
  fi
fi

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
puppet config set --section agent environment "${ENVIRONMENT}"

csr_attr_file=$(puppet config print confdir)/csr_attributes.yaml
cat > $csr_attr_file << YAML
extension_requests:
  1.3.6.1.4.1.34380.1.1.13: "${role}"
  1.3.6.1.4.1.34380.1.2.13: "${subrole}"
  1.3.6.1.4.1.34380.1.2.16: "${location}"
YAML

if [ $params -eq 0 ]
then
  warning "You have to fill in role and subrole in ${csr_attr_file} or puppet will fail."
fi

info "If necessary, add dns_alt_naes to section main of ${confdir}/puppet.conf, i.e.:"
info "$ puppet config set --section main dns_alt_names puppetdb01.ubelix.unibe.ch,puppetdb01,puppetdb"
echo ""
info "Finally run puppet agent if ready."

exit 0
