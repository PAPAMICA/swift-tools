#!/bin/bash

CONTAINER="$1"
FOLDER="$2"

FILESLIST=$(find $FOLDER -type f )
for FILE in $FILESLIST 
    do
    openstack object create $CONTAINER $FILE > /dev/null
        if test $? -eq 0; then
            echo "[$(date +%Y-%m-%d_%H:%M:%S)]   SendFolder   ✅   $FILE has been successfully sent to $CONTAINER."
        else
            echo "[$(date +%Y-%m-%d_%H:%M:%S)]   SendFolder   ❌   ERROR : A problem was encountered during the upload of $FILE"
        fi
done

