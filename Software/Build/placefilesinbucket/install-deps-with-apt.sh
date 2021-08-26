#!/bin/bash

# Install dependencies using apt

sudo apt-get update

# Remove requirement on cursor addressable terminal.
sudo echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections
sudo apt-get install -y -q

#Install unzip package
sudo apt-get --assume-yes install unzip curl wget && \

# Install libGLXT
echo "Starting libxst family of packages install"
sudo apt-get --assume-yes install libxtst6 && \
sudo apt-get --assume-yes install --reinstall libgl1-mesa-glx && \
sudo apt-get update
sudo apt-get --assume-yes install libxt6 && \

# Install MPS required libraries
echo "Beginning to install MPS required libraries for"
sudo apt-get --assume-yes install libnss3
sudo apt-get --assume-yes install libnspr4-dbg
sudo apt-get --assume-yes install locales-all
sudo apt-get --assume-yes install gfortran
sudo apt-get --assume-yes install csh
sudo apt-get --assume-yes install gstreamer1.0-tools
sudo apt-get --assume-yes install gstreamer1.0-libav
sudo apt-get --assume-yes install gstreamer1.0-plugins-good
sudo apt-get --assume-yes install gstreamer1.0-plugins-bad
sudo apt-get --assume-yes install gstreamer1.0-plugins-ugly
sudo apt-get --assume-yes install libc6-i386
sudo apt-get --assume-yes install libxtst6
sudo apt-get --assume-yes install --reinstall libgl1-mesa-glx

# Install gcsfuse for mounting GCS buckets
export GCSFUSE_REPO=gcsfuse-`lsb_release -c -s`
sudo echo "deb http://packages.cloud.google.com/apt $GCSFUSE_REPO main" | sudo tee /etc/apt/sources.list.d/gcsfuse.list && \
sudo curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - && \
sudo apt-get update
sudo apt-get -y install gcsfuse

# (c) 2021 MathWorks, Inc.
