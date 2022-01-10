#!/bin/bash

set -e

SERVERS=$(ocicli -csv machine-list -a | q -H -d, "SELECT hostname FROM -  WHERE role LIKE 'swift%'")
if [ -z $1 ]; then
    echo "  Provide a Policy ID"
    exit
    else
        POLICY_ID=$1
fi
for SERVER in $SERVERS; do
        echo "===> Copying ring to: $SERVER"
    scp /var/lib/oci/clusters/swiftmini01/swift-ring/object-$POLICY_ID.ring.gz $SERVER:/etc/swift
    echo "-> Fixing unix rights"
    ssh $SERVER "chown swift:swift /etc/swift/object-$POLICY_ID.ring.gz"
done