#!/usr/bin/env bash

for host in `cat /etc/hosts | awk '/^10.1/{print $3}'`
do

  ssh $host <<-'ENDSSH'
    sed -i 's/^AllowUsers root/#AllowUsers root/' /etc/ssh/sshd_config

    if type systemctl >/dev/null 2>&1; then
      systemctl restart sshd
    else
      service sshd restart
    fi

    exit 0
ENDSSH

done

exit 0

