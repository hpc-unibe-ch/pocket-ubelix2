#!/usr/bin/env bash

# The slurm and munge user and group are in LDAP
# in production envrionment while we do not have
# a working LDAP in Pocket-UBELIX (yet?).
#
# Therefore we create them explicitly at VM
# creation time with this script
export MUNGEUSER=469
export SLURMUSER=468

if ! getent group munge &>/dev/null
then
  groupadd -g $MUNGEUSER munge
fi

if ! getent passwd munge &>/dev/null
then
  useradd  -m -c "Runs Uid 'N' Gid Emporium" -d /var/lib/munge -u $MUNGEUSER -g munge  -s /sbin/nologin munge
fi

if ! getent group slurm &>/dev/null
then
  groupadd -g $SLURMUSER slurm
fi

if ! getent passwd slurm &>/dev/null
then
  useradd  -m -c "SLURM User" -d /var/lib/slurm -u $SLURMUSER -g slurm  -s /sbin/nologin slurm
fi
