#!/bin/bash

set -e

SERVERS=$(ocicli -csv machine-list -a | q -H -d, "SELECT hostname FROM -  WHERE role LIKE 'swift%'")

if [ -z $1 ] || [ -z $2 ]; then
    echo "  Provide a Policy ID and number of fragments "
    exit
    else
                POLICY_ID=$1
                FRAGMENTS=$2
fi

swift-ring-builder object-$POLICY_ID.builder create 10 $FRAGMENTS 1
swift-ring-builder object-$POLICY_ID.builder add --region 4 --zone 4 --ip <REPLACE_IP> --port 6201 --replication-ip <REPLACE_IP> --replication-port 6201 --device sdb --weight 16764.00
swift-ring-builder object-$POLICY_ID.builder add --region 4 --zone 4 --ip <REPLACE_IP> --port 6202 --replication-ip <REPLACE_IP> --replication-port 6202 --device sdc --weight 16764.00
swift-ring-builder object-$POLICY_ID.builder add --region 4 --zone 4 --ip <REPLACE_IP> --port 6203 --replication-ip <REPLACE_IP> --replication-port 6203 --device sdd --weight 16764.00
swift-ring-builder object-$POLICY_ID.builder add --region 4 --zone 4 --ip <REPLACE_IP> --port 6204 --replication-ip <REPLACE_IP> --replication-port 6204 --device sde --weight 16764.00
swift-ring-builder object-$POLICY_ID.builder add --region 4 --zone 4 --ip <REPLACE_IP> --port 6205 --replication-ip <REPLACE_IP> --replication-port 6205 --device sdf --weight 16764.00
swift-ring-builder object-$POLICY_ID.builder add --region 4 --zone 4 --ip <REPLACE_IP> --port 6200 --replication-ip <REPLACE_IP> --replication-port 6200 --device sda --weight 16764.00
swift-ring-builder object-$POLICY_ID.builder add --region 2 --zone 2 --ip <REPLACE_IP> --port 6200 --replication-ip <REPLACE_IP> --replication-port 6200 --device sda --weight 16764.00
swift-ring-builder object-$POLICY_ID.builder add --region 2 --zone 2 --ip <REPLACE_IP> --port 6201 --replication-ip <REPLACE_IP> --replication-port 6201 --device sdb --weight 16764.00
swift-ring-builder object-$POLICY_ID.builder add --region 2 --zone 2 --ip <REPLACE_IP> --port 6202 --replication-ip <REPLACE_IP> --replication-port 6202 --device sdc --weight 16764.00
swift-ring-builder object-$POLICY_ID.builder add --region 2 --zone 2 --ip <REPLACE_IP> --port 6203 --replication-ip <REPLACE_IP> --replication-port 6203 --device sdd --weight 16764.00
swift-ring-builder object-$POLICY_ID.builder add --region 2 --zone 2 --ip <REPLACE_IP> --port 6204 --replication-ip <REPLACE_IP> --replication-port 6204 --device sde --weight 16764.00
swift-ring-builder object-$POLICY_ID.builder add --region 2 --zone 2 --ip <REPLACE_IP> --port 6205 --replication-ip <REPLACE_IP> --replication-port 6205 --device sdf --weight 16764.00
swift-ring-builder object-$POLICY_ID.builder add --region 3 --zone 3 --ip <REPLACE_IP> --port 6200 --replication-ip <REPLACE_IP> --replication-port 6200 --device sda --weight 16764.00
swift-ring-builder object-$POLICY_ID.builder add --region 3 --zone 3 --ip <REPLACE_IP> --port 6201 --replication-ip <REPLACE_IP> --replication-port 6201 --device sdb --weight 16764.00
swift-ring-builder object-$POLICY_ID.builder add --region 3 --zone 3 --ip <REPLACE_IP> --port 6202 --replication-ip <REPLACE_IP> --replication-port 6202 --device sdc --weight 16764.00
swift-ring-builder object-$POLICY_ID.builder add --region 3 --zone 3 --ip <REPLACE_IP> --port 6203 --replication-ip <REPLACE_IP> --replication-port 6203 --device sdd --weight 16764.00
swift-ring-builder object-$POLICY_ID.builder add --region 3 --zone 3 --ip <REPLACE_IP> --port 6204 --replication-ip <REPLACE_IP> --replication-port 6204 --device sde --weight 16764.00
swift-ring-builder object-$POLICY_ID.builder add --region 3 --zone 3 --ip <REPLACE_IP> --port 6205 --replication-ip <REPLACE_IP> --replication-port 6205 --device sdf --weight 16764.00

swift-ring-builder object-$POLICY_ID.builder

read -r -p "  Everything looks good? (y/N) " response
case "$response" in
    [yY][eE][sS]|[yY])
        swift-ring-builder object-$POLICY_ID.builder rebalance
                for SERVER in $SERVERS; do
                        echo "===> Copying ring to: $SERVER"
                        scp object-$POLICY_ID.ring.gz $SERVER:/etc/swift
                        echo "-> Fixing unix rights"
                        ssh $SERVER "chown swift:swift /etc/swift/object-$POLICY_ID.ring.gz"
                done
        ;;
    *)
        echo "Check your Policy ID"
        exit
        ;;
esac