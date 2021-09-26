# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |global|
  global.vm.box = "hpc-unibe-ch/centos7"
  global.vm.box_check_update = false

  #
  # Gridadmins - Jump hosts to rule them all.
  #
  (1..2).each do |index|
    primary   = index == 1 ? true : false
    autostart = index == 1 ? true : false
    global.vm.define "gridadmin0#{index}", primary: primary,  autostart: autostart do |config|
      config.vm.hostname = "gridadmin0#{index}.ubelix.unibe.ch"
      config.vm.network "private_network", ip: "10.10.128.5#{index}", netmask: "255.255.0.0"
      config.vm.network "forwarded_port", guest: 80, host: 8087 + index
      config.vm.provider "virtualbox" do |vb|
        vb.name = "gridadmin0#{index}"
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--memory", "384"]
        vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root", "1"]
        vb.linked_clone = true
      end
      config.vm.provision :hosts, :sync_hosts => true
      config.vm.provision "shell", inline: "/vagrant/setup_puppet-agent.sh gridadmin infraserver local"
    end
  end

  #
  # Puppet infrastructure
  #
  # The global name puppet has no numbers by intention.
  #
  # This makes this an alias in /etc/hosts, which means that
  # there is no need to set the servername in puppet.conf!!
  #
  global.vm.define "puppet" do |config|
    config.vm.hostname = "puppet01.ubelix.unibe.ch"
    config.vm.network "private_network", ip: "10.10.128.31", netmask: "255.255.0.0"
    config.vm.provider "virtualbox" do |vb|
      vb.name = "puppet01"
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--memory", "2048"]
      vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root", "1"]
      vb.linked_clone = true
    end
    config.vm.provision :hosts, :sync_hosts => true
  end

  global.vm.define "puppetdb01" do |config|
    config.vm.hostname = "puppetdb01.ubelix.unibe.ch"
    config.vm.network "private_network", ip: "10.10.128.33", netmask: "255.255.0.0"
    # Puppet dashboard port forwarding
    config.vm.network "forwarded_port", guest: 5000, host: 5000
    config.vm.provider "virtualbox" do |vb|
      vb.name = "puppetdb01"
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--memory", "512"]
      vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root", "1"]
      vb.linked_clone = true
    end
    config.vm.provision :hosts, :sync_hosts => true
    config.vm.provision "shell", inline: "/vagrant/setup_puppet-agent.sh puppetdb infraserver local"
  end

  #
  # Service hosts - DNS, DHCP, TFTP, Mrepo - you know, services!
  #
  (1..2).each do |index|
    autostart = index == 1 ? true : false
    global.vm.define "service0#{index}", autostart: autostart do |config|
      config.vm.hostname = "service0#{index}.ubelix.unibe.ch"
      config.vm.network "private_network", ip: "10.10.128.2#{index}", netmask: "255.255.0.0"
      # Webserver port forwarding
      config.vm.network "forwarded_port", guest: 80, host: 8080+index
      config.vm.provider "virtualbox" do |vb|
        vb.name = "service0#{index}"
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--memory", "384"]
        vb.customize ["modifyvm", :id, "--nic3", "intnet"]
        vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root", "1"]
        vb.linked_clone = true
      end
      config.vm.provision :hosts, :sync_hosts => true
      config.vm.provision "shell", inline: "/vagrant/setup_puppet-agent.sh service infraserver local"
    end
  end

  #
  # lrms - for the Slurm times of life
  #
  # Make lrms01 a slurmmaster
  global.vm.define "lrms01", autostart: false do |config|
    config.vm.hostname = "lrms01.ubelix.unibe.ch"
    config.vm.network "private_network", ip: "10.10.128.24", netmask: "255.255.0.0"
    config.vm.provider "virtualbox" do |vb|
      vb.name = "lrms01"
      vb.customize ["modifyvm", :id, "--memory", "384"]
      vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root", "1"]
      vb.linked_clone = true
    end
    config.vm.provision :hosts, :sync_hosts => true
    config.vm.provision "shell", inline: "/vagrant/setup_puppet-agent.sh slurmmaster infraserver local"
  end

  # Make lrms02 mange a slurmmaster_test
  global.vm.define "lrms02", autostart: false do |config|
    config.vm.hostname = "lrms02.ubelix.unibe.ch"
    config.vm.network "private_network", ip: "10.10.128.25", netmask: "255.255.0.0"
    config.vm.provider "virtualbox" do |vb|
      vb.name = "lrms02"
      vb.customize ["modifyvm", :id, "--memory", "384"]
      vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root", "1"]
      vb.linked_clone = true
    end
    config.vm.provision :hosts, :sync_hosts => true
    config.vm.provision "shell", inline: "/vagrant/setup_puppet-agent.sh slurmmaster_test infraserver local"
    config.vm.provision "shell", inline: "/vagrant/create_local_users.sh"
  end

  #
  # nfs servers - for file sharing business
  #
  global.vm.define "nfs01", autostart: false do |config|
    config.vm.box = "hpc-unibe-ch/centos7"
    config.vm.hostname = "nfs01.ubelix.unibe.ch"
    config.vm.network "private_network", ip: "10.10.128.27", netmask: "255.255.0.0"
    config.vm.provider "virtualbox" do |vb|
      vb.name = "nfs01"
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--memory", "384"]
      vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root", "1"]
      vb.linked_clone = true
    end
    config.vm.provision :hosts, :sync_hosts => true
    config.vm.provision "shell", inline: "/vagrant/setup_puppet-agent.sh fileserver infraserver local"
  end

  #
  # logger - Logging, monitoring, CIA, ...
  #
  global.vm.define "logger", autostart: false do |config|
    config.vm.hostname = "service03.ubelix.unibe.ch"
    config.vm.network "private_network", ip: "10.10.128.23", netmask: "255.255.0.0"
    config.vm.provider "virtualbox" do |vb|
      vb.name = "logger01.ubelix.unibe.ch"
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--name", "service03"]
      vb.customize ["modifyvm", :id, "--memory", "1024"]
      vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root", "1"]
      vb.linked_clone = true
    end
    config.vm.provision :hosts, :sync_hosts => true
  end

  #
  # Frontend servers
  #
  global.vm.define "submit-lb", autostart: false do |config|
    config.vm.box = "centos-7-x86_64-nocm"
    config.vm.hostname = "submit-config.ubelix.unibe.ch"
    config.vm.network "private_network", ip: "10.10.129.10", netmask: "255.255.0.0"
    config.vm.provider "virtualbox" do |vb|
      vb.name = "submit-lb"
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--memory", "384"]
      vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root", "1"]
      vb.linked_clone = true
    end
    config.vm.provision :hosts, :sync_hosts => true
  end

  (1..2).each do |index|
    global.vm.define "submit0#{index}", autostart: false do |config|
      config.vm.hostname = "submit0#{index}.ubelix.unibe.ch"
      config.vm.network "private_network", ip: "10.10.129.2#{index}", netmask: "255.255.0.0"
      config.vm.provider "virtualbox" do |vb|
        vb.name = "submit0#{index}"
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--memory", "384"]
        vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root", "1"]
        vb.linked_clone = true
      end
      config.vm.provision :hosts, :sync_hosts => true
      config.vm.provision "shell", inline: "mkdir -p /scratch"
      config.vm.provision "shell", inline: "/vagrant/setup_puppet-agent.sh submit frontendserver local"
      config.vm.provision "shell", inline: "/vagrant/create_local_users.sh"
    end
  end

  global.vm.define "grid01", autostart: false do |config|
    config.vm.hostname = "grid01.ubelix.unibe.ch"
    config.vm.network "private_network", ip: "10.10.129.31", netmask: "255.255.0.0"
    config.vm.provider "virtualbox" do |vb|
      vb.name = "grid01"
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--memory", "384"]
      vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root", "1"]
      vb.linked_clone = true
    end
    config.vm.provision :hosts, :sync_hosts => true
  end

  #
  # Compute nodes
  #
  (1..2).each do |index|
    global.vm.define "anode00#{index}", autostart: false do |config|
      config.vm.hostname = "anode00#{index}.ubelix.unibe.ch"
      config.vm.network "private_network", ip: "10.10.2.#{index}", netmask: "255.255.0.0"
      config.vm.provider "virtualbox" do |vb|
        vb.name = "anode00#{index}"
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--memory", "384"]
        vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root", "1"]
        vb.linked_clone = true
      end
      config.vm.provision :hosts, :sync_hosts => true
      config.vm.provision "shell", inline: "mkdir -p /scratch"
      config.vm.provision "shell", inline: "/vagrant/setup_puppet-agent.sh anode computenode local"
      config.vm.provision "shell", inline: "/vagrant/create_local_users.sh"
    end
  end

  (1..2).each do |index|
    global.vm.define "knode0#{index}", autostart: false do |config|
      config.vm.hostname = "knode0#{index}.ubelix.unibe.ch"
      config.vm.network "private_network", ip: "10.10.11.#{index}", netmask: "255.255.0.0"
      config.vm.provider "virtualbox" do |vb|
        vb.name = "knode0#{index}"
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--memory", "384"]
        vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root", "1"]
        vb.linked_clone = true
      end
      config.vm.provision :hosts, :sync_hosts => true
      config.vm.provision "shell", inline: "mkdir -p /scratch"
      config.vm.provision "shell", inline: "/vagrant/setup_puppet-agent.sh knode computenode local"
      config.vm.provision "shell", inline: "/vagrant/create_local_users.sh"
    end
  end

  (1..2).each do |index|
    global.vm.define "ces0#{index}", autostart: false do |config|
      config.vm.hostname = "ces0#{index}.ubelix.unibe.ch"
      config.vm.network "private_network", ip: "10.10.130.#{index}", netmask: "255.255.0.0"
      config.vm.provider "virtualbox" do |vb|
        vb.name = "ces0#{index}"
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--memory", "384"]
        vb.customize ["modifyvm", :id, "--nic3", "intnet"]
        vb.customize ["modifyvm", :id, "--nic4", "intnet"]
        vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root", "1"]
        vb.linked_clone = true
      end
      config.vm.provision :hosts, :sync_hosts => true
      config.vm.provision "shell", inline: "/vagrant/setup_puppet-agent.sh cesnode storageserver local"
    end
  end

end
