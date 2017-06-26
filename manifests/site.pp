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
    #listen_address       => $puppetdb_cname,
    manage_firewall      => true,
    open_listen_port     => false,
    open_ssl_listen_port => true,
    java_args            => {
      '-Xmx' => '384m',
      '-Xms' => '128m'
    },
  }

  # Configure Apache on this server
  class { 'apache': }
  class { 'apache::mod::wsgi':
    wsgi_socket_prefix => "/var/run/wsgi",
  }
  # Configure Puppetboard
  class { 'puppetboard':
    manage_git        => true,
    manage_virtualenv => true,
    reports_count     => 40,
    listen            => 'public',
  }
  # Access Puppetboard through pboard.example.com, port 8888
  class { 'puppetboard::apache::vhost':
    vhost_name => 'puppetdb.ubelix.unibe.ch',
  }
  firewall { '5000 accept from gridadmin - puppetboard':
    src_range => '10.1.128.51-10.1.128.52',
    dport     => 5000,
    proto     => 'tcp',
    action    => 'accept',
  }
}

node default {
  class { '::puppet_agent':
    collection =>  'PC1',
    package_version =>  '1.10.4',
    #service_names => ['puppet'],
  }
}

