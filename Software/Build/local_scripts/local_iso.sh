#!/bin/bash

# This script checks if ISO is available at ISO_PATH

# Input arguments
VERSION=$1
ISO_PATH=$2
FILE=${ISO_PATH}/${VERSION}.iso

if [ ! -f "$FILE" ]; then
    echo "Cannot find ${VERSION}.iso at ${ISO_PATH}. Either correct the ISOPath in variables.tf or download the relevant ISO and rename it as ${VERSION}.iso and place it at ${ISO_PATH}"
    exit 1
fi

# (c) 2021 MathWorks, Inc.
