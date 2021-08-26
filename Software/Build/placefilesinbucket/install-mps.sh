#!/bin/bash

# This script carries out the installation for MATLAB Production Server

## Setting up required environment variables
PROD_SERVER_ROOT="/usr/local/MATLAB/MATLABProductionServer"
RUNTIME_ROOT="/usr/local/MATLAB/MATLAB_Runtime"
MPS_INSTANCE_FOLDER="/opt/mps-instance"
MPS_INSTANCE_NAME="prod_server_1"

## Input Variables

# MATLAB Production Server Release to be deployed
VERSION=$1

# License Manager Address and Port hosting license for MATLAB Production Server
# Most of the time this is within the same VPC
INTERNET=$2
PORT=$3


# Install MATLAB Production Server with inputs
sudo /opt/iso1/install -inputFile /opt/mps-install/mps_installer_input.txt && \

# Create a new server instance and select available runtimes
sudo echo 'y' | sudo ${PROD_SERVER_ROOT}/${VERSION}/script/mps-setup && \
sudo echo '\n' && \
sudo mkdir ${MPS_INSTANCE_FOLDER} && \
sudo ${PROD_SERVER_ROOT}/${VERSION}/script/mps-new ${MPS_INSTANCE_FOLDER}/${MPS_INSTANCE_NAME} -v && \

# Set a default configuration for server instance
sudo sed -i 's/# --enable-discovery/--enable-discovery/g' ${MPS_INSTANCE_FOLDER}/${MPS_INSTANCE_NAME}/config/main_config && \
sudo sed -i 's/#--cors-allowed-origins */--cors-allowed-origins */g' ${MPS_INSTANCE_FOLDER}/${MPS_INSTANCE_NAME}/config/main_config && \
sudo sed -i '0,/#   --license 27000@hostA/s/#   --license 27000@hostA/--license '"${PORT}@${INTERNET}"'/' ${MPS_INSTANCE_FOLDER}/${MPS_INSTANCE_NAME}/config/main_config && \

# Clean up temporary folders and unmount GCS bucket containing MATLAB Runtime installers

sudo rm -rf /opt/mps-install && \
sudo fusermount -u /opt/iso1 && \
sudo rm -rf /opt/iso1 && \
sudo umount -v /mnt/iso1 && \
sudo rm -rf /mnt/iso1 && \

## Start the instance
sudo ${PROD_SERVER_ROOT}/${VERSION}/script/mps-start -C ${MPS_INSTANCE_FOLDER}/${MPS_INSTANCE_NAME}

# (c) 2021 MathWorks, Inc.
