# For the following shorts to work, adjust puppet.conf BEFORE generating puppet certificate
# when issuing puppet agent -t for the first time!
$foreman_uri  = 'https://foreman'
$puppetdb_cname = 'puppetdb'

node 'foreman02.ubelix.unibe.ch' {
  #class { 'foreman':
  #  admin_username   => 'admin',
  #  admin_password   => '123456',
  #  admin_first_name => 'System',
  #  admin_last_name  => 'Administrator',
  #  admin_email      => 'michael.rolli@id.unibe.ch',
  #}
}

node 'puppetserver01.ubelix.unibe.ch' {
  class { 'puppet':
    server                      => true,
    server_foreman              => true,
    server_foreman_url          => $foreman_uri,
    server_environments         => [],
    server_implementation       => 'puppetserver',
    server_jvm_min_heap_size    => '1g',
    server_jvm_max_heap_size    => '1g',
    #server_puppetserver_version => '2.5.x',
    server_reports              => 'puppetdb,foreman',
    server_storeconfigs_backend => 'puppetdb',
    show_diff                   => true,

  }

  class { 'puppetdb::master::config':
    puppetdb_server => $puppetdb_cname,
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
}

