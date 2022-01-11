#!/bin/bash

ERRORS=0

if [ "$1" = "--help" ]; then
    echo "  This script can change policy of a container."
    echo "  Usage :"
    echo "    ./change-container-policy.sh <container> <policy>"
    echo ""
    echo "  You can list container with : 'swift list'"
    echo "  You can list policy with : './change-container-policy.sh --list'"
    exit
elif [ "$1" = "--list" ]; then
    swift info --json | jq -r '.swift.policies[].name'
    exit
elif [ -z $1 ] || [ -z $2 ]; then
    echo "   Provide container and policy please ! (--help)"
    exit
else
    CONTAINER="$1"
    POLICY="$2"
fi


swift stat $CONTAINER
if test $? -ne 0; then
    echo "[$(date +%Y-%m-%d_%H:%M:%S)]   ChangeContainerPolicy   ❌   ERROR : Container $CONTAINER does not exist !"
    exit
fi

READACL=$(swift stat $CONTAINER | grep 'Read ACL' | awk '{print $3}')
if [ -n $READACL ]; then
    ARGS=$(echo $ARGS --header "X-Container-Read: $READACL")
fi

WRITEACL=$(swift stat $CONTAINER | grep 'Write ACL' | awk '{print $3}')
if [ -n $WRITEACL ]; then
    ARGS=$(echo $ARGS --header "X-Container-Read: $WRITEACL")
fi

CONTAINERTEMP="$CONTAINER-temp-$RANDOM"
swift post $CONTAINERTEMP

NBTOTALOBJECTS=$(swift stat $CONTAINER | grep Objects | awk '{print $2}') > /dev/null 2>&1
NBOBJECT=0
OBJECTSLIST=$(swift list $CONTAINER)
for OBJECT in $OBJECTSLIST; do
    NBOBJECT=$((NBOBJECT+1))
    echo "    Copy (1/2) in progress ($NBOBJECT/$NBTOTALOBJECTS)"
    swift copy --destination /$CONTAINERTEMP $CONTAINER $OBJECT > /dev/null 2>&1
        if test $? -ne 0; then
            echo "[$(date +%Y-%m-%d_%H:%M:%S)]   ChangeContainerPolicy   ❌   ERROR : A problem was encountered during the copy of $OBJECT"``
            ERRORS=$((ERRORS+1))
        fi
done

if [ "$ERRORS" -eq "0" ]; then
    swift delete $CONTAINER > /dev/null 2>&1
    if test $? -eq 0; then
        echo "[$(date +%Y-%m-%d_%H:%M:%S)]   ChangeContainerPolicy   ✅   Original container $CONTAINER successfully deleted."
    else
        echo "[$(date +%Y-%m-%d_%H:%M:%S)]   ChangeContainerPolicy   ❌   ERROR : A problem was encountered during the delete of original container $CONTAINER."
    fi
else
    echo "[$(date +%Y-%m-%d_%H:%M:%S)]   ChangeContainerPolicy   ❌   ERROR : One or more errors during copy. Please check $CONTAINER and $CONTAINERTEMP."
    exit
fi

swift post $CONTAINER -H "X-Storage-Policy: $POLICY" $ARGS > /dev/null 2>&1
if test $? -eq 0; then
    echo "[$(date +%Y-%m-%d_%H:%M:%S)]   ChangeContainerPolicy   ✅   New container $CONTAINER with policy $POLICY successfully created."
else
    echo "[$(date +%Y-%m-%d_%H:%M:%S)]   ChangeContainerPolicy   ❌   ERROR : A problem was encountered during the create of container $CONTAINER with policy $POLICY."
fi

OBJECTSLISTTEMP=$(swift list $CONTAINERTEMP)
NBOBJECT=0
for OBJECT in $OBJECTSLISTTEMP; do
    NBOBJECT=$((NBOBJECT+1))
    echo "    Copy (2/2) in progress ($NBOBJECT/$NBTOTALOBJECTS)"
    swift copy --destination /$CONTAINER $CONTAINERTEMP $OBJECT > /dev/null 2>&1
        if test $? -ne 0; then
            echo "[$(date +%Y-%m-%d_%H:%M:%S)]   ChangeContainerPolicy   ❌   ERROR : A problem was encountered during the copy of $OBJECT"
        fi
done

if [ "$ERRORS" -eq "0" ]; then
    swift delete $CONTAINERTEMP > /dev/null 2>&1
    if test $? -eq 0; then
        echo "[$(date +%Y-%m-%d_%H:%M:%S)]   ChangeContainerPolicy   ✅   Temp container $CONTAINERTEMP successfully deleted."
        echo "[$(date +%Y-%m-%d_%H:%M:%S)]   ChangeContainerPolicy   ✅   $CONTAINER policy successfully changed to $POLICY !"
    else
        echo "[$(date +%Y-%m-%d_%H:%M:%S)]   ChangeContainerPolicy   ❌   ERROR : A problem was encountered during the delete of temp container $CONTAINERTEMP."
    fi
else
    echo "[$(date +%Y-%m-%d_%H:%M:%S)]   ChangeContainerPolicy   ❌   ERROR : One or more errors during copy. Please check $CONTAINER and $CONTAINERTEMP."
    exit
fi

swift stat $CONTAINER
