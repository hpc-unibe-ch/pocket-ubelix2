# Pocket UBELIX 2

#### Table of Contents

1. [Overview](#overview)
1. [Description](#description)
1. [Features](#features)
1. [Requirements](#requirements)
1. [Usage](#usage)
    1. [Starting machines in general](#starting-machines-in-general)
    1. [The prefs.conf file](#the-prefs-conf-file)
    1. [Setting up the master host](#setting-up-the-master-host)
    1. [Setting up the puppetdb host](#setting-up-the-puppetdb-host)
    1. [Setting up other hosts](#setting-up-other-hosts)
    1. [Puppet Environments of Hosts](#puppet-environments-of-hosts)
1. [Copyright Notice](#copyright-notice)

## Overview

This repository brings all ingredients to setup an UBELIX development environment on a laptop.

## Description

By default the environment can setup a number of machines - at least for every role used in
UBELIX and where it makes sense additional ones. This mimics UBELIX' infrastructure. Additionally
it features bash scripts to setup a puppetmaster and to provision puppet on all other machines.
The puppetmaster then enables testing of puppet/hiera code before rolling out to UBELIX. Locally
the environment `development` is applied by default.

## Features

In principle it does so by:

* providing different machines in the Vagrantfiel according the roles/tribes in UBELIX
* providing scripts to install a puppetmaster and to bootstrap all other nodes with puppet-agent
* providing additional script to fiddle with the puppet code on the puppetmaster
* being a reminder of useful puppet commands. Look into the scripts
* finally being a source of documentation

## Requirements

The following requirements are only of importance  when setting up the development environment on your MacBook of choice.

* UBELIX Puppet environment repository (puppetenv)
* [Vagrant Hosts Plugin](https://github.com/adrienthebo/vagrant-hosts)
* Access to the admin network where the UBELIX mirrors are located (IDaccess)

To setup the above requirements run the following commands from within the toplevel directory of this project:

    $ git clone git@github.com:hpc-unibe-ch/ubelix-controlrepo.git
    $ vagrant plugin install vagrant-hosts

## Usage

### Starting machines in general

If requirements above are in place, it's time to fire up the environment:

    $ vagrant up [HOSTNAME]...

Now login to the puppet box:

    $ vagrant ssh HOSTNAME
    $ sudo su -

To see the list of available host run

    $ vagrant status

### Configuring the different scripts

Every script has some variables at the top to configure its behaviour. As of this
writing the defaults will install Puppet-6 and checkout the development branch
of the ubelix control repository. Keep in mind that environemnts correspond to
branches in the puppetenv repository. Normally you shoudl not have to change
anything.


### Recommended order of Puppet runs

First setup the puppetmaster using `setup_puppetmaster.sh` and follow the other setup tasks
requested at the end of the script, e.g. eyaml keys palcement, bitbucket key placement, g10k run.

Then run Puppet **agents** on the hosts. These should be run in the following order to have a proper UBELIX setup
locally:

1. service01      (takes some time due to ISO download on first run - runt twice due to ordering issues))
1. puppetdb       (installs puppetdb)
1. puppetmaster   (connects to puppetdb and finishes puppemaster)
1. gridamdin01    (install the jumphost to ssh into the other machines!)
1. Any host you wish but think about dependencies in UBELIX! Examples:
    - nfs01 before any of lrms01/submit/compute nodes as they mount an nfs share)
    - lrms01 before computed nodes or slurmd won't work out of the box

**CAVE: Do not log out of puppetmaster as long as no jumphost is provisioned. You won't be able to relogin. ;-)**

### Setting up the puppetmaster

First clone the pocket-ubelix2 repository and adjust the settings in the scripts. This first
step can be ommited in a development environment locally the repo is already mounted in the
virtual hosts at /vagrant.

    $ git clone git@github.com:hpc-unibe-ch/pocket-ubelix2.git
    $ cd pocket-ubelix2

The script 'setup_puppetmaster.sh' interactively installs and configures
a puppetserver and additional things like g10k and eyaml.

    $ /vagrant/setup_puppetmaster.sh (local|ubelix)

Follow the last manual steps outlined by the script after its termination, which
mainly covers setting up priv/pub keys for g10k and eyaml.

### Setting up other hosts

The `setup_puppet-agent.sh` script is called by the Vagrantfile in pocket-ubleix on host creation
using a shell provisioner. On kickstarted UBELIX hosts in the wild, this script gets provisioned
to /usr/loca/sbin by the kickstart files => it's in your path and ready to be called manually!

    # Omit this in pocket-ubelix
    $ setup_puppet-agent.sh $ROLE $TRIBE ubelix    

    $ puppet agent -t --waitforcert 20

    # On the puppetmaster:
    $ puppetserver ca sign --certname HOSTNAME.ubelix.unibe.ch

If you don't specify the role and tribe, which are needed to extend
the certificate, you have to set those to values in `/etc/puppetlbas/puppet/csr_attributes.yaml`
by hand **before** running `puppet agent -t`.

### Puppet Environment of Hosts

The environment the agents run in is set by `setup_puppetmaster.sh` and
`setup_puppet-agent`. All nodes have their environment set in section `[agent]`
of the puppet.conf. Only the puppet agent depends on environment on clients.
One important exception to this rule is the puppetmaster, which must have the
environemtn set in all sections, e.g. `[master], [agent], [user]`.
This is necessary for the puppet cli tool to be able to lookup hiera data from
the correct (same as the agent) environment. For a production puppetmaster (and
hosts) this setting be absent or set to production.

You easily change the environment later usina the following command:

    $ puppet config set --section agent environment development

On the Puppet master the environment must be set for all sections, e.g. main,
agent, Use section main on the puppetmaster.

## Limitations

All scripts are only tested on the following operating systems:

* CentOS-7

## Copyright Notice

All the provided characters come with no warranty! Use it at your own risk and fun.

© 2017-2020 IT Services Department, University of Bern, Switzerland, see LICENSE file for license details.


