#!/bin/bash

set -e

# Settings; change to your needs
ELMAJ_VER="7"
PUP_URL="https://yum.puppetlabs.com/puppet5/puppet5-release-el-${ELMAJ_VER}.noarch.rpm"
PUP_ENV="development"

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

workdir=$(dirname -- $(readlink -f $0))

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

if ! rpm -qa | grep puppet5-release >/dev/null 2>&1; then
  info "Installing puppet collection repo. This may take a while."
  yum -y install $PUP_URL >/dev/null
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
puppet config set --section agent environment "${PUP_ENV}"

confdir=$(puppet config print confdir)
csr_attr_file=$confdir/csr_attributes.yaml
cat > $csr_attr_file << YAML
extension_requests:
  1.3.6.1.4.1.34380.1.2.1: "${role}"
  1.3.6.1.4.1.34380.1.2.2: "${location}"
  1.3.6.1.4.1.34380.1.2.3: "${tribe}"
YAML

info "If necessary, add dns_alt_naes to section main of ${confdir}/puppet.conf, i.e.:"
info "$ puppet config set --section main dns_alt_names puppetdb01.ubelix.unibe.ch,puppetdb01,puppetdb"
echo ""
info "Finally run puppet agent if ready."

exit 0
