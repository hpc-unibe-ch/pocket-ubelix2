# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |global|
  global.vm.box = "centos-7-x86_64-nocm"

  #
  # Puppet infrastructure
  #
  # The global names puppet/puppetdb have no numbers by intention
  # This makes these aliases available in /etc/hosts!
  #
  global.vm.define "puppet" do |config|
    config.vm.host_name = "puppet01.ubelix.unibe.ch"
    config.vm.network "private_network", ip: "10.1.128.31", netmask: "255.255.0.0"
    config.vm.provider "virtualbox" do |vb|
      vb.name = "puppet01.ubelix.unibe.ch"
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--name", "puppet01"]
      vb.customize ["modifyvm", :id, "--memory", "2048"]
      vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root", "1"]
    end
    config.vm.provision :hosts, :sync_hosts => true
  end

  global.vm.define "puppetdb" do |config|
    config.vm.host_name = "puppetdb01.ubelix.unibe.ch"
    config.vm.network "private_network", ip: "10.1.128.33", netmask: "255.255.0.0"
    config.vm.provider "virtualbox" do |vb|
      vb.name = "puppetdb01.ubelix.unibe.ch"
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--name", "puppetdb01"]
      vb.customize ["modifyvm", :id, "--memory", "512"]
      vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root", "1"]
    end
    config.vm.provision :hosts, :sync_hosts => true
  end

  (1..2).each do |index|
    global.vm.define "service0#{index}" do |config|
      config.vm.host_name = "service0#{index}.ubelix.unibe.ch"
      config.vm.network "private_network", ip: "10.1.128.2#{index}", netmask: "255.255.0.0"
      config.vm.provider "virtualbox" do |vb|
        vb.name = "service0#{index}.ubelix.unibe.ch"
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--name", "service0#{index}"]
        vb.customize ["modifyvm", :id, "--memory", "512"]
        vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root", "1"]
      end
      config.vm.provision :hosts, :sync_hosts => true
    end
  end

  (1..2).each do |index|
    global.vm.define "gridadmin0#{index}" do |config|
      config.vm.host_name = "gridadmin0#{index}.ubelix.unibe.ch"
      config.vm.network "private_network", ip: "10.1.128.5#{index}", netmask: "255.255.0.0"
      config.vm.network "forwarded_port", guest: 443, host: 8088
      config.vm.provider "virtualbox" do |vb|
        vb.name = "gridadmin0#{index}.ubelix.unibe.ch"
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--name", "gridadmin0#{index}"]
        vb.customize ["modifyvm", :id, "--memory", "512"]
        vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root", "1"]
      end
      config.vm.provision :hosts, :sync_hosts => true
    end
  end

  (1..2).each do |index|
    global.vm.define "lrms0#{index}" do |config|
      config.vm.host_name = "lrms0#{index}.ubelix.unibe.ch"
      config.vm.network "private_network", ip: "10.1.128.#{index+23}", netmask: "255.255.0.0"
      config.vm.provider "virtualbox" do |vb|
        vb.name = "lrms0#{index}"
        vb.customize ["modifyvm", :id, "--name", "lrms0#{index}"]
        vb.customize ["modifyvm", :id, "--memory", "512"]
        vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root", "1"]
      end
      config.vm.provision :hosts, :sync_hosts => true
    end
  end

  global.vm.define "nfs01" do |config|
    config.vm.box = "centos-7-x86_64-nocm"
    config.vm.host_name = "nfs01.ubelix.unibe.ch"
    config.vm.network "private_network", ip: "10.1.128.27", netmask: "255.255.0.0"
    config.vm.provider "virtualbox" do |vb|
      vb.name = "nfs01.ubelix.unibe.ch"
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--name", "nfs01"]
      vb.customize ["modifyvm", :id, "--memory", "512"]
      vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root", "1"]
    end
    config.vm.provision :hosts, :sync_hosts => true
  end

  global.vm.define "logger" do |config|
    config.vm.host_name = "service03.ubelix.unibe.ch"
    config.vm.network "private_network", ip: "10.1.128.23", netmask: "255.255.0.0"
    # Uchiwa Dashboard
    config.vm.network "forwarded_port", guest: 3000, host: 8300
    # RabbitMQ Management
    config.vm.network "forwarded_port", guest: 15671, host: 8301
    config.vm.network "forwarded_port", guest: 15672, host: 8302
    # Elastic Search
    config.vm.network "forwarded_port", guest: 9200, host: 9200
    # Kibana
    config.vm.network "forwarded_port", guest: 5601, host: 8303
    config.vm.provider "virtualbox" do |vb|
      vb.name = "logger01.ubelix.unibe.ch"
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--name", "service03"]
      vb.customize ["modifyvm", :id, "--memory", "1024"]
      vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root", "1"]
    end
    config.vm.provision :hosts, :sync_hosts => true
  end

  #
  # Frontend servers
  #
  global.vm.define "submit-lb" do |config|
    config.vm.box = "centos-7-x86_64-nocm"
    config.vm.host_name = "submit-config.ubelix.unibe.ch"
    config.vm.network "private_network", ip: "10.1.129.10", netmask: "255.255.0.0"
    config.vm.provider "virtualbox" do |vb|
      vb.name = "submit-config.ubelix.unibe.ch"
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--name", "submit-lb"]
      vb.customize ["modifyvm", :id, "--memory", "512"]
      vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root", "1"]
    end
    config.vm.provision :hosts, :sync_hosts => true
  end

  (1..2).each do |index|
    global.vm.define "submit0#{index}" do |config|
      config.vm.host_name = "submit0#{index}.ubelix.unibe.ch"
      config.vm.network "private_network", ip: "10.1.129.2#{index}", netmask: "255.255.0.0"
      config.vm.provider "virtualbox" do |vb|
        vb.name = "submit0#{index}.ubelix.unibe.ch"
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--name", "submit0#{index}"]
        vb.customize ["modifyvm", :id, "--memory", "512"]
        vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root", "1"]
      end
      config.vm.provision :hosts, :sync_hosts => true
    end
  end

  global.vm.define "grid01" do |config|
    config.vm.host_name = "grid01.ubelix.unibe.ch"
    config.vm.network "private_network", ip: "10.1.129.31", netmask: "255.255.0.0"
    config.vm.provider "virtualbox" do |vb|
      vb.name = "grid01.ubelix.unibe.ch"
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--name", "grid01"]
      vb.customize ["modifyvm", :id, "--memory", "512"]
      vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root", "1"]
    end
    config.vm.provision :hosts, :sync_hosts => true
  end

  #
  # Compute nodes
  #
  (1..2).each do |index|
    global.vm.define "anode00#{index}" do |config|
      config.vm.host_name = "anode00#{index}.ubelix.unibe.ch"
      config.vm.network "private_network", ip: "10.1.11.#{index}", netmask: "255.255.0.0"
      config.vm.provider "virtualbox" do |vb|
        vb.name = "anode00#{index}"
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--name", "anode00#{index}"]
        vb.customize ["modifyvm", :id, "--memory", "512"]
        vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root", "1"]
      end
      config.vm.provision :hosts, :sync_hosts => true
    end
  end

  (1..2).each do |index|
    global.vm.define "knode0#{index}" do |config|
      config.vm.host_name = "knode0#{index}.ubelix.unibe.ch"
      config.vm.network "private_network", ip: "10.1.11.#{index}", netmask: "255.255.0.0"
      config.vm.provider "virtualbox" do |vb|
        vb.name = "knode0#{index}"
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--name", "knode0#{index}"]
        vb.customize ["modifyvm", :id, "--memory", "512"]
        vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root", "1"]
      end
      config.vm.provision :hosts, :sync_hosts => true
    end
  end

end
