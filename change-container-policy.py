#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import swiftclient.client
from swiftclient.exceptions import ClientException
from swiftclient.service import SwiftService, SwiftCopyObject, SwiftError
import os
from sys import argv
import json
import random


auth_version = '3.0',
os_username = os.getenv('OS_USERNAME'),
os_password = os.getenv('OS_PASSWORD'),
os_project_name = os.getenv('OS_PROJECT_NAME'),
os_project_domain_name = os.getenv('OS_PROJECT_DOMAIN_NAME'),
os_auth_url = os.getenv('OS_AUTH_URL')


swiftconnect = swiftclient.Connection(
    user=os_username,
    key=os_password,
    authurl=os_auth_url
)


def list_policy():
    with SwiftService() as swift:
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
            print ("pouprout")

def check_policy_exist(policy):
    policy_list = list_policy()
    if policy not in policy_list:
        print ("The policy "+str(policy)+" does not exist.")
        exit()

def copy_container(container_source, container_destination):
    with SwiftService() as swift:
        nbobject = 0
        try:
            list_parts_gen = swift.list(container=container_source)
            for page in list_parts_gen:
                if page["success"]:
                    for item in page["listing"]:
                        i_size = int(item["bytes"])
                        i_name = item["name"]
                        nbobject+=1
                        copy_object(container_source, i_name, container_destination, nbobject)
                else:
                    raise page["error"]

        except SwiftError as e:
            print("prout")

def stat_container(container):
    with SwiftService() as swift:
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
            print(str(container)+" doesn't exist !")
            exit()

def create_container(container_name, vsource_stats):
    with SwiftService() as swift:
        hpolicy = "X-Storage-Policy: "+str(policy)
        try:
            swift.post(container_name, options={'header': [hpolicy],'read_acl': vsource_stats[2], 'write_acl': vsource_stats[3]})
            print ("Container "+str(container_name)+" created with policy : "+str(policy))
        except SwiftError as e:
            print("prout")

def copy_object(source, object, destination, nbobject):
    destination = "/"+str(destination)
    with SwiftService() as swift:
        try:
            obj = SwiftCopyObject(object, {"destination": destination})
            for i in swift.copy(source, [obj]):
                if i["success"]:
                    if i["action"] == "copy_object":
                        print("   Copy to "+str(destination)+" in progress (",nbobject,"/ "+str(vsource_stats[1])+" )")
                else:
                    print("prout1")

        except SwiftError as e:
            print("prout2")

def delete_source(source, destination):
    source_stats = stat_container(source)
    destination_stats = stat_container(destination)
    if source_stats[4] == destination_stats[4]:
        with SwiftService() as swift:
            del_iter = swift.delete(container=source)
            for del_res in del_iter:
                if del_res['success'] and not del_res['action'] == 'bulk_delete':
                    rd = del_res.get('response_dict')
                    if rd is not None:
                        t = dict(rd.get('headers', {}))
        print ("Container "+str(source)+" deleted.")

    else:
        print ("proutouuu")
        exit()


if len(argv) > 1:
    if argv[1] == "--help":
        print("prouthelp")
        exit()
    elif argv[1] == "--list":
        print(list_policy())
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
    print("prouthelp")
    exit()

vsource_stats = stat_container(container)
check_policy_exist(policy)
copy_container(container, container_temp)
delete_source(container, container_temp)
create_container(container, vsource_stats)
copy_container(container_temp, container)
delete_source(container_temp, container)
