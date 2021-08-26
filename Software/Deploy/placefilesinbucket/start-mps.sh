#!/bin/bash

# Script for installing MATLAB Production server

# VARIABLES
PROD_SERVER_ROOT="/usr/local/MATLAB/MATLABProductionServer"
MPS_INSTANCE_FOLDER="/opt/mps-instance"
MPS_INSTANCE_NAME="prod_server_1"
MPS_INSTANCE_FOLDER_ESCAPED="\/opt\/mps-instance"
MPS_LOG_FILE="$MPS_INSTANCE_FOLDER_ESCAPED\/$MPS_INSTANCE_NAME\/log\/main.log"

## Input
VERSION=$1
INTERNET=$2
PORT=$3
AUTODEPLOY_BUCKET=$4
CONFIG_BUCKET=$5
SCRIPT_BUCKET=$6
NUM_WORKER_PER_NODE=$7

# Create Mount Point for MPS and Runtime install image
sudo mkdir -p /usr/local/MATLAB && \
sudo chmod -R 775 /usr/local/MATLAB && \

# Mount persistent disk at MATLAB Root /usr/local/MATLAB
sudo lsblk && \
sudo mount -o discard,defaults /dev/sdb /usr/local/MATLAB && \
sudo chmod a+w /usr/local/MATLAB && \

## Configure and create a new MATLAB PRODUCTION SERVER instance

# Skipping mps-setup which selects only one runtime [This step is optional]
# ---------------------------------------------------
# sudo echo 'y' | sudo ${PROD_SERVER_ROOT}/${VERSION}/script/mps-setup && \
# sudo echo '\n' && \
# 
# Uncomment the above 2 lines if only one default Runtime has been installed
# Comment the additional MATLAB mcr-root lines below added to main_config

sudo mkdir ${MPS_INSTANCE_FOLDER} && \
sudo chmod -R 777 ${MPS_INSTANCE_FOLDER} && \
sudo ${PROD_SERVER_ROOT}/${VERSION}/script/mps-new ${MPS_INSTANCE_FOLDER}/${MPS_INSTANCE_NAME} -v && \

# Provide permissions for all mount points
sudo chmod -R 777 ${MPS_INSTANCE_FOLDER}/${MPS_INSTANCE_NAME} && \
sudo chmod -R 777 ${MPS_INSTANCE_FOLDER}/${MPS_INSTANCE_NAME}/log && \
sudo chmod -R 777 ${MPS_INSTANCE_FOLDER}/${MPS_INSTANCE_NAME}/auto_deploy && \
sudo chmod -R 777 ${MPS_INSTANCE_FOLDER}/${MPS_INSTANCE_NAME}/config && \

# Connect MPS log with google cloud logging agent
sudo gsutil cp gs://${SCRIPT_BUCKET}/mps-fluentd-log.conf . && \
sudo sed -i 's/path <LOGFILE>/path '"$MPS_LOG_FILE"'/' mps-fluentd-log.conf && \
sudo cp mps-fluentd-log.conf /etc/google-fluentd/config.d/mps-fluentd-log.conf && \
sudo service google-fluentd restart && \

## Move config and change Config
sudo cp ${MPS_INSTANCE_FOLDER}/${MPS_INSTANCE_NAME}/config/main_config . && \

# Main config entry
sudo sed -i 's/# --enable-discovery/--enable-discovery/g' main_config && \
sudo sed -i 's/#--cors-allowed-origins */--cors-allowed-origins /' main_config && \
sudo sed -i '0,/#   --license 27000@hostA/s/#   --license 27000@hostA/--license '"${PORT}@${INTERNET}"'/' main_config && \
sudo sed -i 's/--num-workers 1/--num-workers '"${NUM_WORKER_PER_NODE}"'/' main_config && \

## Removing reference to single mcr-root
sudo sed -i 's/--mcr-root/#--mcr-root/g' main_config && \

## Adding all possible runtimes to config using mcr-root
sudo echo "#" >> main_config && \
sudo echo "#" >> main_config && \
sudo echo "## Adding additonal MATLAB runtime entries " >> main_config && \
for entry in "/usr/local/MATLAB/MATLAB_Runtime"/*
do
    sudo echo "--mcr-root $entry" >> main_config
done

# Copy fully configured main_config to server instance folder
sudo cp main_config ${MPS_INSTANCE_FOLDER}/${MPS_INSTANCE_NAME}/config && \

# Mount server instance - auto_deploy folder. The folder is now ready for ctf uploads through GCD bucket
echo "Mounting " ${AUTODEPLOY_BUCKET} && \
gcsfuse ${AUTODEPLOY_BUCKET} ${MPS_INSTANCE_FOLDER}/${MPS_INSTANCE_NAME}/auto_deploy && \

## Start MPS and Log
sudo ${PROD_SERVER_ROOT}/${VERSION}/script/mps-start -C ${MPS_INSTANCE_FOLDER}/${MPS_INSTANCE_NAME}


# (c) 2021 MathWorks, Inc.
