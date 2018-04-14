#!/usr/bin/env bash

groupfile=/etc/dsh/group/hosts

mkdir -p `dirname $groupfile`
rm -f $groupfile
for host in `cat /etc/hosts | awk '/^10.1/{print $3}'`
do
  echo $host >> $groupfile
done

exit 0
