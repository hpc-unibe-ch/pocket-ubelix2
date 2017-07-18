# Pocket UBELIX

#### Table of Contents

1. [Overview](#overview)
1. [Description](#description)
1. [Features](#features)
1. [Requirements](#requirements)
1. [Usage](#usage)
1. [Copyright Notice](#copyright-notice)

## Overview

This repository delivers measures to setup a puppet development environment locally on a laptop.

## Description

By default the environment can setup a number of maschines - at least for every subrole used in
UBELIX and where it makes sense additional ones. This mimic UBELIX' infrastructure. Additionally
it features bash scripts to setup a puppetmaster and to provision puppet on all other machines.
The puppetmaster then enables testing of puppet/hiera code before rolling out to UBELIX.

## Features

In principle it does so by:

* providing differen maschines in the Vagrantfiel according the roles/subrole in UBELIX
* providing scripts to install a puppetmaster and to bootstrap all other nodes with puppet-agent
* providing additional script to fiddle with the puppet code on the puppetmaster
* being a reminder of useful puppet commands. Look into the scripts
* finally being a source of documentation

## Requirements

The following requirements are only when setting up the development environment on your MacBook of choice.

* UBELIX Puppet environment repository (puppetenv)
* [Vagrant Hosts Plugin](https://github.com/adrienthebo/vagrant-hosts)

To setup the above requirements run the following commands from within the toplevel directory of this project:

    $ git clone https://idos-code.unibe.ch/scm/ubelix/puppetenv.git
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

### The prefs.conf

Every script is using preferences set in prefs.conf. The most important setting is
the environemtn setting. This makes every script work on the same environemnt.

Keep in mind that environemnts correspond to branches in the puppetenv repository.

All nodes have their environment set in section `[agent]` of the puppet.conf. Only
the puppet agent depends on environment on clients. One important exception to this
rule is the puppetmaster, which must have the environemtn set in section `[main]`.
This is necessary for the puppet cli tool to be able to lookup hiera data from
the correct (same as the agent) environment. For a production puppetmaster (and
hosts) this setting be absent or set to production. In developemnt set it to an
environemnt desired, i.e.:

    $ puppet config set --section agent environment ubelixng

Use section main on the puppetmaster.


### Setting up the puppetmaster

First clone the pocket-ubelix2 repository and adjust settings in `prefs.conf`:

    $ git clone https://idos-code.unibe.ch/scm/ubelix/pocket-ubelix2.git
    $ cd pocket-ubelix2
    $ vi prefs.conf

The script 'setup_puppetmaster.sh' interactively installs and configures
a puppetserver and additional

Follow the last manual steps oulined by the script after its termination, which
mainly covers setting up priv/pub keys for r10k and eyaml.

Then run `puppet agent -t` for the first time on puppetmaster (before installing any other host!)

### Setting up other puppet clients

First clone the pocket-ubelix2 repository and adjust settings in `prefs.conf`:

    $ git clone https://idos-code.unibe.ch/scm/ubelix/pocket-ubelix2.git
    $ cd ppocket-ubelix2
    $ vi prefs.conf


The procedure to provision any other node than the puppetmaster is as follows:

    $ /vagrant/setup_puppet-agent.sh [ROLE SUBROLE]
    $ puppet agent -t --waitforcert 20

    # On the puppetmaster:
    $ puppet cert sign HOSTNAME.ubelix.unibe.ch

If you don't specify the role and subrole, which are needed to extend
the certificate, you have to set those to values in `/etc/puppetlbas/puppet/csr_attributes.yaml`
by hand **before** running `puppet agent -t`.

**Notice:** For the **puppetdb server** there's one additional step
before running `puppet agent -t` the first time. The certificate has
to accept the general CNAME 'puppetdb', therefore the setup_puppet-agent.sh
script will thell you, which command to run to add this DNS alternative name.

and follow the [puppetenv readme](https://idos-code.unibe.ch/projects/UBELIX/repos/puppetenv/browse) for further instructions.

## Limitations

All scripts are only tested on the following operating systems:

* CentOS-7.3

## Copyright Notice

All the provided characters come with no warranty! Use it at your own risk and fun.

© 2017 IT Services Department, University of Bern, Switzerland, see LICENSE file for license details.


