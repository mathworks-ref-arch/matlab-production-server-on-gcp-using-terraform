#!/bin/bash

# This is an example script for setting up MATLAB Production Server on Google cloud platform.

    # Sample Requirements:
        # OS: Ubuntu20
        # Compute: Low, i.e. n2-standard-4 machine
        # Number of nodes : 2
        # Existing Network License Manager on GCP : True
        # Existing GCP VPC & Subnet : True
        # MATLAB Production Server Version : R2021a
        # Enable HTTPS : True

## Automate Build and Deploy

## Variables for Build Stage

# Path to service account credentials
credentials_file_path="/home/user/gcp/credentials.json"

# MATLAB Production Server Version
Version="R2021a"
Agree_To_License="no"

#Enable HTTPS
enable_https=true

# File Installation Key for the licensed product
FIK="1234-5678-90123-4567"

# VM Operating system
BootDiskOS="ubuntu20"

# Existing License Manager and Network Details
LicenseManagerHost="10.128.0.2"
VPC_Network_Name="mlm-test-ubuntu20-licensemanager-network"
Subnet_Name="mlm-test-ubuntu20-licensemanager-subnetwork"

# Set to true if you wish to create a new subnet within the License Manager VPC
build_subnet_create=true
# If new subnet, then provide subnet_cidr_range
build_subnet_ip_cidr_range="10.130.0.0/20"

# Do you have an existing bucket with ISO
ISO_Bucket_exists=true

# Provide gsutil string for ISO object
ISO_Object_URI="gs://projectID_iso_bucket/R2021a.iso"

# Unique tag for naming resources
TS=$(date +%s) && \
MPS_BUILD_TAG="mps-${Version:(-3)}-build-${BootDiskOS}-${TS}"

## Navigate to Build directory
cd Build/ && \

# Initialize and Validate
terraform init 
terraform validate

# Apply Terraform configuration for building MATLAB Production Server disk image
# See Build/variables.tf to configure other variables
terraform apply -auto-approve -var "credentials_file_path=${credentials_file_path}" \
-var "bootDiskOS=${BootDiskOS}" \
-var "LicenseManagerHost=${LicenseManagerHost}" \
-var "vpc_network_name=${VPC_Network_Name}" \
-var "subnet_name=${Subnet_Name}" \
-var "subnet_create=${build_subnet_create}" \
-var "subnet_ip_cidr_range=${build_subnet_ip_cidr_range}" \
-var "tag=${MPS_BUILD_TAG}" \
-var "Version=${Version}" \
-var "Agree_To_License=${Agree_To_License}" \
-var "FIK=${FIK}" \
-var "ISO_Bucket_exists=${ISO_Bucket_exists}" \
-var "ISO_Object_URI=${ISO_Object_URI}"

# Verify build exit status
build_status=$?
printf "\n\n"

# Proceed only if terraform apply has passed for Build stage with exit code 0.
if [[ $build_status -eq 0 ]]; then
    printf "Build stage is complete\n"

    # Extract build output returned by Terraform
    imageName=$(terraform output -json | jq '."mps-disk-image"."value"' | tr -d \") && \
    imageSize=$(terraform output -json | jq '."mps-disk-image-size"."value"' | tr -d \") && \
    imageOS=$(terraform output -json | jq '."boot-disk-os"."value"' | tr -d \") && \
    imageID=$(terraform output -json | jq '."mps-disk-image-id"."value"' | tr -d \") && \

    echo "Extracting output values from Build stage" && \
    echo MATLAB Production Server disk image: ${imageName} is built successfully. && \
    echo The disk image size is ${imageSize}. This is the minimum size for creating an attached disk in Deploy stage. && \
    echo The OS for the image is ${imageOS}. && \
    echo The imageID for the disk image is : ${imageID}. The imageID is used to save and import the disk image for the deploy stage.

    # Preserve Disk Image for deploy stage and destroy other temporary resources to avoid costs
    terraform state rm google_compute_image.mps && \
    terraform destroy -auto-approve && \
    terraform import google_compute_image.mps ${imageID} && \

    echo All temporary resources in the build stage have been destroyed.
    echo MPS disk image: ${imageID} has been restored to the Terraform state.

    # Entering Deploy stage
    echo "Starting Deploy Stage"
    cd Deploy

    # Terraform intialize and Validate
    terraform initialize
    terraform validate

    # Initialize variables for Deploy stage
    Deploy_LicenseManagerHost=${LicenseManagerHost}
    # Existing VPC of the License Manager
    Deploy_Existing_VPC_Network=${VPC_Network_Name}
    # Existing Subnet within License Manager VPC
    Deploy_Existing_Subnet=${Subnet_Name}
    # Set to true if you wish to create a new subnet within the License Manager VPC
    deploy_subnet_create=true
    # If new subnet, then provide subnet_cidr_range
    deploy_subnet_ip_cidr_range="10.129.0.0/20"


   # See more details within Software/Deploy/variables.tf
    # Configure variables `machine_types` to customize your options.
    Machine_Type="n2-standard-4"

    # Configure a unique tag for resources
    TS=$(date +%s) && \
    MPS_DEPLOY_TAG="mps-${Version:(-3)}-deploy-${BootDiskOS}-${TS}"


    # Building resources to Deploy Production Server
    # See Deploy/variables.tf to configure other variables
    terraform apply -auto-approve \
    -var "machine_types"=${Machine_Type} \
    -var "sourcediskimage=${imageName}" \
    -var "sourcedisksize=${imageSize}" \
    -var "bootDiskOS=${imageOS}" \
    -var "LicenseManagerHost=${Deploy_LicenseManagerHost}" \
    -var "vpc_network_name=${Deploy_Existing_VPC_Network}" \
    -var "subnet_create=${deploy_subnet_create}" \
    -var "subnet_name=${Deploy_Existing_Subnet}" \
    -var "tag=${MPS_DEPLOY_TAG}" \
    -var "Version=${Version}" \
    -var "enable_https=${enable_https}" \
    -var "subnet_ip_cidr_range=${deploy_subnet_ip_cidr_range}"


    deploy_status=$?

    if [[ $deploy_status -eq 0 ]]; then

        # Destroy temporary Google cloud storage resources
        echo "Deleting temporary buckets to avoid costs " && \
        temporary_bucket_name=$(terraform output -json | jq '."mps-script-bucket"."value"' | tr -d \") && \
        gsutil rm -r gs://${temporary_bucket_name} && \
        printf "\n\n" && \
        echo -e "\e[1mDeploy stage complete.\e[0m"
    else
        printf "\n\n" && \
        echo -e  "\e[1mDeploy stage Failed with status code ${deploy_status}.\e[1m" && \
        printf "\n" && \
        echo -e "\e[1mRun 'terraform destroy' to roll back any changes.\e[0m"
    fi
else
    echo -e "\e[1m Build stage Failed with status code $build_status. Run 'terraform destroy' to roll back any changes.\e[0m"
fi

# (c) 2021 MathWorks, Inc.
