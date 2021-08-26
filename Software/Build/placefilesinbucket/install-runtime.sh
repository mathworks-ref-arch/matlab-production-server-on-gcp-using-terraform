#!/bin/bash

# This script carries out the installation for MATLAB Runtime versions selected by the user to support one or many MATLAB versions

## Script Inputs

# Name of existing Google Cloud Storage bucket containing installation scripts
SCRIPT_BUCKET_NAME=$1

# Name of existing Google Cloud Storage bucket containing MATLAB runtime installers
RUNTIME_BUCKET_NAME=$2

# Does User agree to License before installing MATLAB runtime. by Default this is "no"
AGREE_TO_LICENSE=$3

## Installing MATLAB Runtime

# Create temporary folder to extract MATLAB Runtime Installers
sudo mkdir -p /opt/mcr-install && \
sudo chmod -R 777 /opt/mcr-install && \

# Mount Google Cloud Storage bucket containing MATLAB Runtime installers at /opt/mcr-install
sudo gcsfuse ${RUNTIME_BUCKET_NAME} /opt/mcr-install && \

# Download the installer input file for Installing MATLAB Runtime
sudo gsutil cp gs://${SCRIPT_BUCKET_NAME}/runtime_installer_input.txt /opt/runtime_installer_input.txt && \

# Assign user input for license agreement
sudo sed -i 's/agreeToLicense=no/agreeToLicense='"${AGREE_TO_LICENSE}"'/g' /opt/runtime_installer_input.txt && \

# Create temporary folder to unzip runtime content
sudo mkdir /opt/mcrcontents && \
sudo chmod -R 777 /opt/mcrcontents && \

# Look for available MATLAB Runtime installers and install them one by one
for f in /opt/mcr-install/*.zip
do
	echo "Unzipping $f" && \
  sudo unzip $f -d /opt/mcrcontents && \
	sudo chmod 777 /opt/mcrcontents/install && \
  echo "Finished unzipping $f" && \

  echo "Installing MATLAB Runtime from $f"
  sudo /opt/mcrcontents/install -inputFile /opt/runtime_installer_input.txt && \
  echo "Completed installation of MATLAB Runtime version $f"

  sudo rm -rf /opt/mcrcontents/*
done


# Clean up all temporary folders and unmount buckets
sudo rm -rf /opt/mcrcontents && \
sudo fusermount -u /opt/mcr-install
sudo umount /opt/mcr-install
sudo rm -rf /opt/mcr-install
sudo rm -rf /opt/runtime_installer_input.txt

# (c) 2021 MathWorks, Inc.
