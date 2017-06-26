# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  #config.ssh.username = 'root'
  #config.ssh.password = 'vagrant'
  #config.ssh.private_key_path = '/Users/mrolli/.ssh/blupp'
  #config.ssh.insert_key = 'false'
  config.vm.box = "centos-7-x86_64-nocm"

  #config.vm.define "foreman" do |foreman|
  #  foreman.vm.host_name = "foreman02.ubelix.unibe.ch"
  #  foreman.vm.network "private_network", ip: "10.1.128.26", netmask: "255.255.0.0"
  #  foreman.vm.network "forwarded_port", guest: 443, host: 7843
  #  foreman.vm.network "forwarded_port", guest: 80, host: 7880
  #  foreman.vm.provider "virtualbox" do |vb|
  #    vb.name = "foreman02.ubelix.unibe.ch"
  #    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  #    vb.customize ["modifyvm", :id, "--name", "foreman02"]
  #    vb.customize ["modifyvm", :id, "--memory", "2048"]
  #    vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root", "1"]
  #  end
  #  foreman.vm.provision :hosts
  #  #foreman.vm.provision "shell", path: "puppetenv/bin/bootstrap_server.sh"
  #  #foreman.vm.provision "shell", path: "puppetenv/bin/install_foreman.sh", args: "/vagrant/puppetenv/bin/foreman-installer-answers-ubelix.yaml 1"
  #end

  config.vm.define "puppet" do |puppet|
    puppet.vm.host_name = "puppet01.ubelix.unibe.ch"
    puppet.vm.network "private_network", ip: "10.1.128.31", netmask: "255.255.0.0"
    #puppet.vm.network "forwarded_port", guest: 443, host: 7843
    #puppet.vm.network "forwarded_port", guest: 80, host: 7880
    puppet.vm.provider "virtualbox" do |vb|
      vb.name = "puppet01.ubelix.unibe.ch"
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--name", "puppetserver01"]
      vb.customize ["modifyvm", :id, "--memory", "2048"]
      vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root", "1"]
    end
    puppet.vm.provision :hosts
  end

  config.vm.define "puppetdb" do |puppetdb|
    puppetdb.vm.host_name = "puppetdb01.ubelix.unibe.ch"
    puppetdb.vm.network "private_network", ip: "10.1.128.33", netmask: "255.255.0.0"
    puppetdb.vm.network "forwarded_port", guest: 5000, host: 8088
    puppetdb.vm.provider "virtualbox" do |vb|
      vb.name = "puppetdb01.ubelix.unibe.ch"
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--name", "puppetdb01"]
      vb.customize ["modifyvm", :id, "--memory", "512"]
      vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root", "1"]
    end
    puppetdb.vm.provision :hosts
    #foreman.vm.provision "shell", path: "puppetenv/bin/bootstrap_server.sh"
  end

  (1..2).each do |index|
    config.vm.define "service0#{index}" do |service|
      service.vm.host_name = "service0#{index}.ubelix.unibe.ch"
      service.vm.network "private_network", ip: "10.1.128.2#{index}", netmask: "255.255.0.0"
      service.vm.provider "virtualbox" do |vb|
        vb.name = "service0#{index}.ubelix.unibe.ch"
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--name", "service0#{index}"]
        vb.customize ["modifyvm", :id, "--memory", "512"]
        vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root", "1"]
      end
      service.vm.provision :hosts
      service.vm.provision "shell", path: "puppetenv/bin/bootstrap_server.sh"
    end
  end

  (1..2).each do |index|
    config.vm.define "submit0#{index}" do |submit|
      submit.vm.host_name = "submit0#{index}.ubelix.unibe.ch"
      submit.vm.network "private_network", ip: "10.1.129.2#{index}", netmask: "255.255.0.0"
      submit.vm.provider "virtualbox" do |vb|
        vb.name = "submit0#{index}.ubelix.unibe.ch"
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--name", "submit0#{index}"]
        vb.customize ["modifyvm", :id, "--memory", "512"]
        vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root", "1"]
      end
      submit.vm.provision :hosts
      #submit.vm.provision "shell", path: "puppetenv/bin/bootstrap_server.sh"
    end
  end

end

