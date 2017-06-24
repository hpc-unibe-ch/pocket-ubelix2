# For the following shorts to work, adjust puppet.conf BEFORE generating puppet certificate
# when issuing puppet agent -t for the first time!
$puppetdb_cname = 'puppetdb'

node 'puppet01.ubelix.unibe.ch' {
  class { 'puppetdb::master::config':
    puppetdb_server => $puppetdb_cname,
    manage_report_processor => true,
    enable_reports => true,
  }

  include firewall

  firewall { '8140 accept - puppetserver':
    dport  => 8140,
    proto  => 'tcp',
    action => 'accept',
  }
}

node 'puppetdb01.ubelix.unibe.ch' {
  class { 'puppetdb':
    listen_address       => $puppetdb_cname,
    manage_firewall      => true,
    open_listen_port     => true,
    open_ssl_listen_port => true,
    java_args            => {
      '-Xmx' => '384m',
      '-Xms' => '128m'
    },
  }
}

node default {
  class { '::puppet_agent':
    collection =>  'PC1',
    package_version =>  '1.10.4',
    #service_names => ['puppet'],
  }
}

