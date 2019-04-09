#!/usr/bin/env bash

for host in `cat /etc/hosts | awk '/^10.10/{print $3}'`
do

  ssh $host <<-'ENDSSH'
    sed -i 's/^AllowUsers root/#AllowUsers root/' /etc/ssh/sshd_config
    systemctl restart sshd
    exit 0
ENDSSH

done

exit 0

