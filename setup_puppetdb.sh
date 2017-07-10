#!/usr/bin/env bash

set -e

workdir=$(dirname -- $(readlink -f $0))
source $workdir/shellfunctions.sh
source $workdir/prefs.conf

if ! which puppet >/dev/null 2>&1
then
  fail "You must first install puppet agent by running setup_puppet-agent.sh"
  exit 1
fi

if ! rpm -qa | grep puppetdb >/dev/null 2>&1
then
  puppet config set --section main server "${MASTER_HOST}"
  puppet config set --section main environment "${ENVIRONMENT}"

  csr_attr_file=$confdir/csr_attributes.yaml
  cat > $csr_attr_file << YAML
custom_attributes:
  1.2.840.113549.1.9.7: "$SHARED_SECRET"
extension_requests:
  pp_role: "infraserver"
  ux_subrole: "puppetdb"
YAML
  chown puppet:puppet $csr_attr_file
  chmod 640 $csr_attr_file

  #info "About to run puppet agent for the first time."
  #info "Certificate signing on the puppet master is needed."
  #prompt_confirm "Ready to sign the certificate?"

  puppet agent -t --waitforcert 3

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

