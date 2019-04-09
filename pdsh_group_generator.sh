#!/usr/bin/env bash

groupfile=$HOME/.dsh/group/hosts

mkdir -p `dirname $groupfile`
rm -f $groupfile
for host in `cat /etc/hosts | awk '/^10.10/{print $3}'`
do
  echo $host >> $groupfile
done

exit 0
