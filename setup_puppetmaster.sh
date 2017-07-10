#!/usr/bin/env bash

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

if ! rpm -qa | grep puppetserver >/dev/null 2>&1; then
  info "Installing puppetserver."

  # Install puppetserver and adjust $PATH
  yum -y install puppetserver >/dev/null

  # Lower memory settings in vagrant boxes
  if [ -d /vagrant ]
  then
    info "Adjusting heap size for puppetserver."
    sed -i 's/Xms2g/Xms1g/' /etc/sysconfig/puppetserver
    sed -i 's/Xmx2g/Xmx1g/' /etc/sysconfig/puppetserver
  fi

  success "Puppet server has been installed"
else
  success "Puppet server is already installed."
fi

# Make puppet available if needed
if ! type puppet >/dev/null 2>&1
then
  source /etc/profile.d/puppet-agent.sh
fi

confdir=$(puppet config print confdir)

# Custom mapping for UBELIX subrole
cat > $confdir/custom_trusted_oid_mapping.yaml << YAML
oid_mapping:
  1.3.6.1.4.1.34380.1.2.13:
    shortname: 'ux_subrole'
    longname:  'UBELIX subrole'
YAML

# Additional csr attributes for the puppetmaster
csr_attr_file=$confdir/csr_attributes.yaml
cat > $csr_attr_file << YAML
custom_attributes:
  1.2.840.113549.1.9.7: "$SHARED_SECRET"
extension_requests:
  1.3.6.1.4.1.34380.1.1.13: "infraserver"
  1.3.6.1.4.1.34380.1.2.13: "puppetmaster"
YAML
chown puppet:puppet $csr_attr_file
chmod 640 $csr_attr_file

# autosigning script
autosign_script=$confdir/check_csr.sh
cat > $autosign_script <<'EOF'
#!/usr/bin/env bash

shared_secret="hackmenot"

csr=$(openssl req -noout -text </dev/stdin)
certname=$1

# Find value of OID $1 in csr
function extension {
  echo "$csr" | fgrep -A1 "$1" | tail -n 1 | sed -e 's/^ *//;s/ *$//;s/\.\.//'
}

psk=$(echo "$csr" | awk '/challengePassword/{print $2}' | cut -c 2-)
role=$(extension '1.3.6.1.4.1.34380.1.1.13')
subrole=$(extension '1.3.6.1.4.1.34380.1.2.13')

if [ "$psk" == "$shared_secret" ]
then
  echo "Autosign succeeded for ${certname} with role ${role} and subrole ${subrole}."
  exit 0
else
  echo "Autosign failed for ${certname} with role ${role} and subrole ${subrole}."
  exit 1
fi
EOF
chown puppet:puppet $autosign_script
chmod 750 $autosign_script
# Activate autosigining in puppetmaster
puppet config set --section master autosign $autosign_script


# Start the puppetserver but do not yet start puppet-agent
if ! systemctl status puppetserver.service >/dev/null 2>&1; then
  systemctl enable puppetserver.service
  systemctl start puppetserver.service
  success "Puppet server has been started."
else
  systemctl restart puppetserver.service
  success "Puppet server has been restarted."
fi

warning "No manfiests/modules have been installed yet."
warning "For an UBELIX setup, run:"
warning "- snippet_inst_eyaml"
warning "- snippet_inst_r10k"

exit 0

