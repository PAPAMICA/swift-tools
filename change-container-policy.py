#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import swiftclient.client
from swiftclient.exceptions import ClientException
from swiftclient.service import SwiftService, SwiftCopyObject, SwiftError
import os
from sys import argv
import json
import random
import logging

logging.basicConfig(level=logging.ERROR)
logging.getLogger("requests").setLevel(logging.CRITICAL)
logging.getLogger("swiftclient").setLevel(logging.CRITICAL)
logger = logging.getLogger(__name__)

# Recovering login information from environment variables
auth_version = '3.0',
os_username = os.getenv('OS_USERNAME'),
os_password = os.getenv('OS_PASSWORD'),
os_project_name = os.getenv('OS_PROJECT_NAME'),
os_project_domain_name = os.getenv('OS_PROJECT_DOMAIN_NAME'),
os_auth_url = os.getenv('OS_AUTH_URL')

# Connection to Swift API
swiftconnect = swiftclient.Connection(
    user=os_username,
    key=os_password,
    authurl=os_auth_url
)

# List all available policies 
def list_policy(swift):
    try:
        capabilities_result = swift.capabilities()
        policy_list = list()
        policy_name_list = ""
        for ipolicy in capabilities_result['capabilities']['swift']['policies']:
            policy_list.append(ipolicy['name'])
        for name in policy_list:
            policy_name_list = policy_name_list +" "+ name
        return (policy_name_list)
    except ClientException as e:
        logger.error(e.value)

# Checks if the given policy exists
def check_policy_exist(swift, policy):
    policy_list = list_policy(swift)
    if policy not in policy_list:
        logger.error(f"The policy {policy} does not exist.")
        exit()

# Copy all objects from one container to another
def copy_container(swift, container_source, container_destination):
        nbobject = 0
        try:
            list_parts_gen = swift.list(container=container_source)
            for page in list_parts_gen:
                if page["success"]:
                    for item in page["listing"]:
                        i_name = item["name"]
                        nbobject+=1
                        copy_object(swift, container_source, i_name, container_destination, nbobject)
                else:
                    raise page["error"]

        except SwiftError as e:
            logger.error(e.value)

# Retrieves information from the container
def stat_container(swift, container):
        try:
            list_stat=swift.stat(container=container)
            json_str = json.dumps(list_stat)
            resp = json.loads(json_str)
            nbobjects = resp['items'][2][1]
            policy = resp['headers']['x-storage-policy']
            rACL = resp['items'][4][1]
            wACL = resp['items'][5][1]
            size = resp['items'][3][1]
            return policy, nbobjects, rACL, wACL, size
        except SwiftError as e:
            print(f"{container} doesn't exist !")
            logger.error(e.value)

# Create a container with the requested policy and the sent parameters
def create_container(swift, container_name, vsource_stats):
        hpolicy = "X-Storage-Policy: "+str(policy)
        try:
            swift.post(container_name, options={'header': [hpolicy],'read_acl': vsource_stats[2], 'write_acl': vsource_stats[3]})
            print (f"Container {container_name} created with policy : {policy}")
        except SwiftError as e:
            logger.error(e.value)

# Copy an object from the source container to the destination
def copy_object(swift, source, object, destination, nbobject):
    destination = "/"+str(destination)
    try:
        obj = SwiftCopyObject(object, {"destination": destination})
        for i in swift.copy(source, [obj]):
            if i["success"]:
                if i["action"] == "copy_object":
                    print(f"   Copy to {destination} in progress ({nbobject}/{vsource_stats[1]})")
            else:
                exit()

    except SwiftError as e:
        logger.error(e.value)

# Checks that the source and destination are the same size and deletes the source
def delete_source(swift, source, destination):
    source_stats = stat_container(swift, source)
    destination_stats = stat_container(swift, destination)
    if source_stats[4] == destination_stats[4]:
        del_iter = swift.delete(container=source)
        for del_res in del_iter:
            if del_res['success'] and not del_res['action'] == 'bulk_delete':
                rd = del_res.get('response_dict')
                if rd is not None:
                    t = dict(rd.get('headers', {}))
        print (f"Container {source} deleted.")

    else:
        print (f"There was an error while deleting {source}.")
        exit()

# Main application
if __name__ == '__main__':
    if len(argv) > 1:
        if argv[1] == "--help":
            print("This script allows to change the policy of a container.")
            print("You have to provide the name of the container and the desired policy :")
            print("   'python3 change-container-policy.py <container> <policy>'")
            print("You can list the available policies with :")
            print("   'python3 change-container-policy.py --list'")
            exit()
        elif argv[1] == "--list":
            with SwiftService() as swift:
                print(list_policy(swift))
            exit()
        else:
            container = argv[1]
            if len(argv) > 2:
                policy = argv[2]
            else:
                print ("Provide policy please. You can list policies with '--list'")
                exit()
            nrandom = random.randint(1000,22000)
            container_temp = str(container)+"-temp-"+str(nrandom)
    else:
        print("This script allows to change the policy of a container.")
        print("You have to provide the name of the container and the desired policy :")
        print("   'python3 change-container-policy.py <container> <policy>'")
        print("You can list the available policies with :")
        print("   'python3 change-container-policy.py --list'")
        exit()

    with SwiftService() as swift:
        vsource_stats = stat_container(swift, container)
        check_policy_exist(swift, policy)
        copy_container(swift, container, container_temp)
        delete_source(swift, container, container_temp)
        create_container(swift, container, vsource_stats)
        copy_container(swift, container_temp, container)
        delete_source(swift, container_temp, container)
