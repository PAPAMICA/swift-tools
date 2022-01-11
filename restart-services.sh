#!/bin/bash
set -e

SERVERS=$(ocicli -csv machine-list -a | q -H -d, "SELECT hostname FROM -  WHERE role LIKE 'swift%'")
for SERVER in $SERVERS; do
        ssh $SERVER 'for i in /etc/init.d/swift-* ; do $i restart; done'
        if [ $? -eq 0 ]; then
                echo "  All swift services restarted on $SERVER"
        else
                echo "  ERROR : $SERVER"
        fi
done