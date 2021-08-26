#!/bin/bash
# This script is used by Terraform as a part of the standard startup script for a Google Compute Engine VM.
# The script takes care of dependency resolution and enabling the Google logging agent.
# The installation of the product is already completed in the Build stage.
# This startup script utilizes the build image to deploy a multi-node MATLAB Production Server backend to a Google Cloud Load Balancer.
# This script is triggered by `main.tf` within the module `mpsworkernode`.
# This script does not run locally on the user's system.
# This script is accessed from a Google cloud storage bucket by the VM

## Receive Input Arguments

# MATLAB Production Server Release
MPS_VERSION=$1

# FLEX LM Address and Port for license checkout
INTERNET=$2
PORT=$3

# Google Cloud Storage bucket containing all scripts from folder Software/placefilesinbucket
SCRIPT_BUCKET=$4

# Google Cloud Storage Bucket Names for mounting `autodeploy` and `config`
AUTODEPLOY_BUCKET=$5
CONFIG_BUCKET=$6

# Number of MATLAB Production Server per instance
NUM_WORKER_PER_NODE=$7

## Installing dependencies based on Linux distribution (VM)

# Download from Google Cloud Storage bucket and run  script getLinuxDistro
sudo gsutil cp gs://${SCRIPT_BUCKET}/getLinuxDistro.sh . && \
sudo chmod 777 getLinuxDistro.sh && \
sudo ./getLinuxDistro.sh ${SCRIPT_BUCKET} && \
echo "Completed dependency installation stage" && \

# Download required scripts for installing logging agent and install fluentd from GCS bucket
sudo gsutil cp gs://${SCRIPT_BUCKET}/install_logging_agent.sh . && \
sudo chmod 777 install_logging_agent.sh && \
./install_logging_agent.sh && \
echo "Finished installing logging agent." && \

# Download required scripts for updated config
sudo gsutil cp gs://${SCRIPT_BUCKET}/monitor_config_restart_mps.sh /opt && \
sudo chmod 777 /opt/monitor_config_restart_mps.sh && \
sudo gsutil cp gs://${SCRIPT_BUCKET}/loopcron.sh /opt && \
sudo chmod 777 /opt/loopcron.sh && \

# Download required startup scripts from GCS bucket for creating MATLAB Production Server instance
# The scripts also configure and start the server instance. 
sudo gsutil cp gs://${SCRIPT_BUCKET}/start-mps.sh . && \
sudo chmod 777 start-mps.sh && \

# Start MATLAB Production Server
./start-mps.sh ${MPS_VERSION} ${INTERNET} ${PORT} ${AUTODEPLOY_BUCKET} ${CONFIG_BUCKET} ${SCRIPT_BUCKET} ${NUM_WORKER_PER_NODE}

# Clean up local scripts
sudo rm -rf start-mps.sh && \
sudo rm -rf install_logging_agent.sh && \
sudo rm -rf getLinuxDistro.sh && \
sudo rm -rf install-deps-with-apt.sh && \
sudo rm -rf install-deps-with-yum.sh

# Apply monitoring on config mount location
VERSION=$MPS_VERSION
CONFIG_LOCATION="/opt/update_config"
CONFIG_FILE=${CONFIG_LOCATION}/main_config
MPS_ROOT="/usr/local/MATLAB/MATLABProductionServer"
MPS_INSTANCE_FOLDER="/opt/mps-instance"
MPS_INSTANCE_NAME="prod_server_1"
DEST_LOC=$MPS_INSTANCE_FOLDER/$MPS_INSTANCE_NAME/config

## Mount config location and start monitoring for updates for new config
sudo mkdir -p ${CONFIG_LOCATION} && \
sudo chmod -R 777 ${CONFIG_LOCATION} && \
sudo gcsfuse ${CONFIG_BUCKET} ${CONFIG_LOCATION} && \
echo Mounting ${CONFIG_BUCKET} containing template config at ${CONFIG_LOCATION} && \

## Now run monitoring script to monitor mount bucket changes 
## Changes should trigger config update and server restart
/opt/loopcron.sh ${CONFIG_FILE} ${DEST_LOC} ${MPS_ROOT} ${VERSION} ${MPS_INSTANCE_FOLDER} ${MPS_INSTANCE_NAME}


# (c) 2021 MathWorks, Inc.
