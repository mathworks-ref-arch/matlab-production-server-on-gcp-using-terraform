#!/bin/bash
# 
#  Usage:
#
# ./monitor_config_restart_mps.sh CONFIG_FILE DEST_LOC MPS_ROOT VERSION MPS_INSTANCE_FOLDER MPS_INSTANCE_NAME
#
#  This script is meant to monitor changes in MPS Config and restart the MPS instance to apply the updated config.

CONFIG_FILE=$1
DEST_LOC=$2
MPS_ROOT=$3
VERSION=$4
MPS_INSTANCE_FOLDER=$5
MPS_INSTANCE_NAME=$6
MPS_INSTANCE=${MPS_INSTANCE_FOLDER}/${MPS_INSTANCE_NAME}

# Get metadata
while true; do
        current=$(sudo find ${CONFIG_FILE} -type f -ctime -1 -exec ls -ls {} \;)
        sleep 15
        new=$(sudo find ${CONFIG_FILE} -type f -ctime -1 -exec ls -ls {} \;)
        if [[ $current != $new ]];then
                sudo cp ${CONFIG_FILE} ${DEST_LOC} && \
                sudo ${MPS_ROOT}/${VERSION}/script/mps-restart -C ${MPS_INSTANCE} -f
        fi
done

# (c) 2021 MathWorks, Inc.
