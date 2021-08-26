#!/bin/bash

# This script checks if ISO is available at ISO_PATH

# Input arguments
ISO_GSUTIL_URI=$1
echo gsutil string for ISO is $ISO_GSUTIL_URI.
printf "\n\n"

# Extension
ext=${ISO_GSUTIL_URI: -4}

# Does object have an .iso extension
if [[ "${ext}" == ".iso" ]]; then
    echo -e "${GREEN}\e[1mObject extension is an iso.\e[0m"
else
    echo -e "${RED}\e[1mInvalid object file extension. Expected .iso format but received ${ext}\e[0m"
    exit 1
fi

# URL start substring
printf  "\n\n"

gsutil_uri_start="${ISO_GSUTIL_URI:0:5}"

# Does URI start with gs://
if [ "$gsutil_uri_start" == "gs://" ]; then
    echo -e "${GREEN}\e[1mgsutil URI starts with gs://.\e[0m"
else
    echo -e "${RED}\e[1mInvalid gsutil URI. Expected to begin with with gs://\e[0m"
    exit 1
fi

# Run gsutil stat to get metadata response for validation
gsutil stat ${ISO_GSUTIL_URI}
if [[ $? -eq 0 ]]; then
    exit 0
else
    exit 1
fi

# (c) 2021 MathWorks, Inc.
