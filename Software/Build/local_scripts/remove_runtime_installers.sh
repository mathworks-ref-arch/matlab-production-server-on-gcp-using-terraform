#!/bin/bash

# Deleting runtime installers within Software/Build/runtimes for emptying local disk space
cd ../runtimes &&
echo Removing any MATLAB Runtime Installers located within directory Software/Build/runtimes &&
rm -rf MATLAB_Runtime_*

# (c) 2021 MathWorks, Inc.
