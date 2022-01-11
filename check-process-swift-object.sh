#!/bin/bash
set -e
SLACK_WEBHOOK="<REPLACE_WEBHOOK>"

function Check-Process(){
  NBDISKS=$(grep -P '^(?!#).*sd' /etc/fstab | wc -l)
  NBSERVERSPERPORT=$(grep -oP '(?<=servers_per_port = )[0-9]+' /etc/swift/object-server.conf)
  NBTOTALWORKERS=$(($NBDISKS*$NBSERVERSPERPORT))
  NBPROCESS=$(echo "$(($(ps aux | grep "swift-object-server" | wc -l)-1))")
  if [ "$NBTOTALWORKERS" -ge "$NBPROCESS" ];
    then
      echo "1"
    else
      echo "0"
  fi
}

if [ "$1" = "-h" ]; 
  then 
    echo "This script is used to restart the swift-object service if the number of processes does not match the number of workers (number of disks x number of server ports)."
fi

if [ $(Check-Process) -eq "1" ];
  then
    logger "[PROCESS-SWIFT-OBJECT] There are not enough processes, restart the swift-object.service. "
    systemctl restart swift-object
    sleep 10
    if [ $(Check-Process) -eq "1" ];
      then
        logger "[PROCESS-SWIFT-OBJECT] ERROR -  Even after a service restart, there is not enough process."
        curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"[ $(uname -n) -  PROCESS-SWIFT-OBJECT] ERROR -  Even after a service restart, there is not enough process.\"}" $SLACK_WEBHOOK
    fi
fi