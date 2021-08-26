## Sample Build and Deploy using Reference Architecture

The [example script](../Software/exampleBuildDeployScript.sh) is a sample scenario for building and deploying a MATLAB Production Server instance on Google Cloud Platform.

The example has the following pre-requisites:
* User has access to an existing License Manager on Google Cloud Platform. If not, one can use (Reference architecture for setting up License manager on Google Cloud)[] to set one up and get access to:
  * `License Manager hostname` or instance hostname.
  * `License Manager IP` (private should be sufficient if the plan is to use the same VPC.)
  * `VPC name` or ID for the License Manager.
  * `Subnet name` and  `CIDR range` for the License Manager.
    * You can either `use the same subnet` for MATLAB Production Server, or
    * You can `use the information to select a different valid CIDR range` for deploying MATLAB production Server within the same VPC.
  * `License Manager port` open on the VPC firewall for accepting license checkout requests.
* Select a MATLAB Production Server version for deployment. Supported versions include R2020a, R2020b and R2021a.
* Select MATLAB Runtime versions you would like to support. A MATLAB Production Server version can support up to six releases back. [See more details here for version support](https://www.mathworks.com/help/mps/qs/download-and-install-the-matlab-compiler-runtime-mcr.html). 
* Add the MATLAB Runtime versions you would like to support within [Build/variables.tf](../Software/Build/variables.tf) as follows:
  
  ```
  variable "MCR_url" {
  type    = map
  default = {
  v97  = "https://ssd.mathworks.com/supportfiles/downloads/R2019b/Release/8/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2019b_Update_7_glnxa64.zip"
  v98  = "https://ssd.mathworks.com/supportfiles/downloads/R2020a/Release/6/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2020a_Update_6_glnxa64.zip"
  v99  = "https://ssd.mathworks.com/supportfiles/downloads/R2020b/Release/5/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2020b_Update_3_glnxa64.zip"
  v910 = "https://ssd.mathworks.com/supportfiles/downloads/R2021a/Release/4/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2021a_Update_4_glnxa64.zip"
    } 
  }
   ```

* User has access to all `Prerequisites` and has followed the `Getting Started` steps listed within [README.md](../README.md).


The sample scenario in this example is as follows:

* OS: `Ubuntu20`
* Compute: `n2-standard-4`
* Number of instances: `2`
* Existing Network License Manager on GCP : `true`
* Use existing VPC & Subnet : `true`
* MATLAB Production Server Version : `R2021a`


### Variables for Build Stage:

```
# Path to service account credentials
credentials_file_path="/home/matlabuser/gcp/credentials.json"

# MATLAB Production Server Version
Version="R2021a"
Agree_To_License="yes"

# Enable HTTPS
enable_https=false

# File Installation Key for the licensed product
FIK="3xxx6-3xxx1-5xxx6-6xxx4"

# VM Operating system
BootDiskOS="ubuntu20"

# Existing License Manager and Network Details

LicenseManagerHost="10.128.0.2"
VPC_Network_Name="mlm-21a-ubuntu20-1627426546-licensemanager-network"

Subnet_Name="mlm-21a-ubuntu20-1627426546-licensemanager-subnetwork"

# Unique tag for naming resources
TS=$(date +%s) && \
MPS_BUILD_TAG="mps-${Version:(-3)}-build-${BootDiskOS}-${TS}"
```

### Applying Terraform plan for Build stage:

The above variables are just a subset of a much longer list that needs to be configured within `Software/Build/variables.tf`. The above values will override the defaults set within variables.tf .

The next section applies the terraform plan for the Build Stage. If you encounter an error related to `unrecognized modules or plan`, initialize the Terraform modules by running the following command:
```
>> cd Software/Build
>> terraform init
>> terraform validate
```

At the completion of the Build stage a `google compute disk image` containing configured versions of `MATLAB Production Server` and `MATLAB runtime` will be created. This resource will be preserved for use in the Deploy stage. Rest of the resources such as `compute`, `subnets`, `firewall rules` and `storage buckets` will be destroyed using `terraform destroy` to avoid incurring any costs.

```
# Navigate to Build directory
cd ../Build/ && \

# Apply Terraform configuration for building a google compute disk image containing MATLAB Production Server & MATLAB Runtime image.

terraform apply -auto-approve -var "credentials_file_path=${credentials_file_path}" \
-var "bootDiskOS=${BootDiskOS}" \
-var "LicenseManagerHost=${LicenseManagerHost}" \
-var "vpc_network_name=${VPC_Network_Name}" \
-var "subnet_name=${Subnet_Name}" \
-var "tag=${MPS_BUILD_TAG}" \
-var "Version=${Version}" \
-var "Agree_To_License=${Agree_To_License}" \
-var "FIK=${FIK}" \
-var "ISO_Bucket_exists=${ISO_Bucket_exists}" \
-var "ISO_Object_URI=${ISO_Object_URI}"
```

### Verify build status before proceeding to Deploy stage:

```
build_status=$?
printf "\n\n"
```
Proceed only if terraform apply has passed for Build stage with exit code 0. If the Build is successful the script extracts the `terraform output` values required to initialize input variables for `Deploy` stage. The script uses `jq` to parse terraform output in `json` format as follows.

```
if [[ $build_status -eq 0 ]]; then
    
    printf "Build stage is complete\n"

    # Extract build output returned by Terraform
    imageName=$(terraform output -json | jq '."mps-disk-image"."value"' | tr -d \") && \
    imageSize=$(terraform output -json | jq '."mps-disk-image-size"."value"' | tr -d \") && \
    imageOS=$(terraform output -json | jq '."boot-disk-os"."value"' | tr -d \") && \
    imageID=$(terraform output -json | jq '."mps-disk-image-id"."value"' | tr -d \") 

else

    echo -e "Build stage Failed with status code $build_status. Run 'terraform destroy' to roll back any changes."
fi
```

### Preserving disk image and destroying all other resources:

Terraform provides useful commands to manage the terraform state and manage resources created by Terraform config. The script uses some of the following commands:

* `terraform state rm [Options]`
* `terraform import [Options]`
* `terraform destroy`


```
# Remove Disk Image from terraform state temporarily

terraform state rm google_compute_image.mps && \

# Destroy all resources in the terraform state

terraform destroy -auto-approve && \

# Add/Import the disk image back to the terraform state using Resource ID obtained from the Build stage output

terraform import google_compute_image.mps ${imageID} && \

echo All temporary resources in the build stage have been destroyed.

echo MPS disk image: ${imageID} has been restored to the Terraform state.
```
### Build Stage Output:

Here is an example of Terraform output of the Build Stage:

```
Output:

boot-disk-os = "ubuntu20"

mps-disk-image = "mps-21a-build-ubuntu20-1628793575-build-image"

mps-disk-image-size = 50

mps-disk-image-id = "projects/projectID/global/images/mps-21a-build-ubuntu20-1628793575-build-image"
"

Removing mps-disk-image from Terraform state

Destroy complete: 11 Resources destroyed.

google_compute_image.mps: Importing from ID "projects/pftappdeploy/global/images/mps-21a-build-ubuntu20-1628793575-build-image"...

google_compute_image.mps: Import prepared!

Prepared google_compute_image for import
google_compute_image.mps: Refreshing state... [id=projects/pftappdeploy/global/images/mps-21a-build-ubuntu20-1628793575-build-image]

Import successful!    

The resources that were imported are shown above. These resources are now in your Terraform state and will henceforth be managed by Terraform.                                                                            

All temporary resources in the build stage have been destroyed.

MPS disk image: projects/pftappdeploy/global/images/mps-21a-build-ubuntu20-1628793575-build-image has been restored to the Terraform state.
```
### Applying Terraform Plan for Deploy Stage :

This section applies the terraform plan for the `Deploy` Stage. If you encounter an error related to `unrecognized modules or plan`, initialize the Terraform modules by running the following command:
```
>> cd Software/Deploy
>> terraform init
>> terraform validate
```
At the completion of the Deploy stage a fully functional `MATLAB Production Server` should be ready for use. The Terraform output should provide the following:
* Frontend IP (representing Cloud Load Balancer frontend) for receiving MATLAB Production Server client requests.
* HTTP(S) endpoints for MATLAB production Server backend health check.
* Private IPs and hostnames for the MATLAB Production Server worker VMs constituting the Google Load Balancer backend service.
* Name of the Cloud Storage bucket assigned for `autodeploy`. A MATLAB user should be able to upload compiled MATLAB functions to this bucket for auto deploying the MATLAB code as a REST endpoint. This will not require a server restart.
* Name of the Cloud Storage bucket assigned to receive updated `MATLAB Production Server config`. Any new config uploaded to this bucket by the server admin will trigger config update on all MATLAB Production Server VMs and restart the MATLAB Production Server service to make the new config effective.

### Initialize variables for Deploy Stage:

```
# Assign the License manager host/ip for the Deploy stage
Deploy_LicenseManagerHost=${LicenseManagerHost}

# Existing VPC of the License Manager

Deploy_Existing_VPC_Network=${VPC_Network_Name}

# Existing Subnet within License Manager VPC if using the same
Deploy_Existing_Subnet=${Subnet_Name}
    
# Set to true if you wish to create a new subnet within the License Manager VPC
subnet_create=true

# If new subnet, then provide subnet_cidr_range
subnet_ip_cidr_range="10.129.0.0/20"
    
# Configure  `machine_types` based on compute/load requirements
Machine_Type="n2-standard-4"

# Configure a unique tag for resources
TS=$(date +%s) && \
MPS_DEPLOY_TAG="mps-${Version:(-3)}-deploy-${BootDiskOS}-${TS}"
```

The above variables are just a subset of a much longer list that needs to be configured within `Software/Deploy/variables.tf`. The above values will override the defaults set within variables.tf .

```
# Entering Deploy stage

echo "Starting Deploy Stage"
cd ../Deploy/

# Building resources to Deploy Production Server

terraform apply -auto-approve \
    -var "machine_types"=${Machine_Type} \
    -var "sourcediskimage=${imageName}" \
    -var "sourcedisksize=${imageSize}" \
    -var "bootDiskOS=${imageOS}" \
    -var "LicenseManagerHost=${Deploy_LicenseManagerHost}" \
    -var "vpc_network_name=${Deploy_Existing_VPC_Network}" \
    -var "subnet_create=${subnet_create}" \
    -var "subnet_name=${Deploy_Existing_Subnet}" \
    -var "tag=${MPS_DEPLOY_TAG}" \
    -var "Version=${Version}" \
    -var "enable_https=${enable_https}" \
    -var "subnet_ip_cidr_range=${subnet_ip_cidr_range}"
```
### Verify deploy status and extract Terraform output:

Proceed only if terraform apply has passed for Deploy stage with exit code 0. 

```
deploy_status=$?
```

If the Deploy is successful the script extracts the `terraform output` values and removes any temporary resources such as cloud storage buckets created for provisioning. The script uses `jq` to parse terraform output in `json` format as follows.

```
if [[ $deploy_status -eq 0 ]]; then

    # Destroy temporary Google cloud storage resources

    temporary_bucket_name=$(terraform output -json | jq '."mps-script-bucket"."value"' | tr -d \")

    gsutil rm -r gs://${temporary_bucket_name}

    echo -e "Deploy stage complete."

else

    echo -e  "Deploy stage Failed with status code ${deploy_status}."

    echo -e "Run 'terraform destroy' to roll back any changes."
fi
```

Here is an example of the Terraform output received at the completion of the deployment stage:

```
Outputs:

mps-autodeploy-bucket = "mps-21a-deploy-ubuntu20-1628794679-autodeploy-bucket"

mps-config-bucket = "mps-21a-deploy-ubuntu20-1628794679-mps-config-bucket"

mps-http-endpoint = "http://34.107.196.133/api/health"

mps-script-bucket = "mps-21a-deploy-ubuntu20-1628794679-tempscript-bucket"

mps-worker-nodes = [
  "mps-21a-deploy-ubuntu20-1628794679-mps-node-0",
  "mps-21a-deploy-ubuntu20-1628794679-mps-node-1",
]

Deleting temporary buckets to avoid costs 

Removing gs://mps-21a-deploy-ubuntu20-1628794679-tempscript-bucket/configure_yum.sh#1628794684997045...

Removing gs://mps-21a-deploy-ubuntu20-1628794679-tempscript-bucket/getLinuxDistro.sh#1628794684981293...

Removing gs://mps-21a-deploy-ubuntu20-1628794679-tempscript-bucket/install-deps-with-apt.sh#1628794684996564...

Removing gs://
mps-21a-deploy-ubuntu20-1628794679-tempscript-bucket/install-deps-with-yum.sh#1628794685028823...

/ [4 objects]                                                                   
Removing gs://mps-21a-deploy-ubuntu20-1628794679-tempscript-bucket/install_logging_agent.sh#1628794685000140...

Removing gs://mps-21a-deploy-ubuntu20-1628794679-tempscript-bucket/mps-fluentd-log.conf#1628794684977769...

Removing gs://mps-21a-deploy-ubuntu20-1628794679-tempscript-bucket/start-mps.sh#1628794684979041...

Removing gs://mps-21a-deploy-ubuntu20-1628794679-tempscript-bucket/startup.sh#1628794684979208...

/ [8 objects]                                                                   
Operation completed over 8 objects.                                              
Removing gs://mps-21a-deploy-ubuntu20-1628794679-tempscript-bucket/...

```



[//]: #  (Copyright 2021 The MathWorks, Inc.)