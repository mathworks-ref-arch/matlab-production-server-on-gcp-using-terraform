#!/bin/bash

# Input arguments
ISO_DIR=$1

# Deleting iso images for emptying local disk space
if [[ -d "$ISO_DIR" ]]; then
   echo Deleting ISOs located within $ISO_DIR.
   rm -rf $ISO_DIR/*.iso
else
   echo $ISO_DIR directory does not exist.
fi

# (c) 2021 MathWorks, Inc.

