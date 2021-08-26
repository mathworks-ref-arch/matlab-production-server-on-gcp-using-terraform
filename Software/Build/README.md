## Build Stage:

### Resources created during Build stage:

| Resource Type | Number | Lifecycle |
|---------------|--------|-----------|
|Google Compute Instances | 1 | Temporary|
|Google Cloud Managed instance group| 1 | Temporary|
|Google Cloud Load Balancer| 1 | Temporary|
|VPC network (Optional)| 1 | Temporary|
|Google Cloud Storage buckets| 4 | Temporary|
|Google Compute Attached Disk | 1 | Temporary|
|Google Compute Disk Image| 1 | Will be available for use|

 In **Build Stage** stage the Terraform scripts are used to temporarily create a single worker MATLAB Production Server instance so that a disk image for the installed product can be created and saved within Google Cloud Project for on demand deployment of larger clusters. 

**Pre-requisites** :
* Existing [Network License Manager  setup on Google Cloud Platform](https://insidelabs-git.mathworks.com/EI-DTST/Staging/setting-up-license-manager-for-matlab-on-google-cloud-using-terraform). It is recommended that the instance hosting the license manager is available in the same VPC network as the MATLAB Production Server instances.
* Download a local copy of :
  * [MATLAB ISO](https://www.mathworks.com/downloads/) for the required version of MATLAB Production Server
  * All [MATLAB runtime installers](https://www.mathworks.com/products/compiler/matlab-runtime.html) (Linux only), you would like to support.

**See details for the Build stage**:
* Terraform `variables`
* Terraform `modules`
* Terraform `output`

**Variables**:

|Variable Name|Default Value| Type | Description |Required|
|-------------|-------------|------|-------------------------------------|------|
|app_project | "projectID" | `string`| [Google Cloud project ID](https://cloud.google.com/resource-manager/docs/creating-managing-projects) | `yes` |
|username| "user" | `string`| [User authorized to access the Cloud Platform with Google user credentials](https://cloud.google.com/sdk/gcloud/reference/auth/login)|`yes`|
|gce_ssh_key_file_path|"/home/user/.ssh/google_compute_engine.pub"|`string`|Path to public ssh keys for gcloud users. [Locating keys](https://cloud.google.com/compute/docs/instances/adding-removing-ssh-keys#locatesshkeys)|`yes`|
|credentials_file_path|"/home/user/gcp/credentials.json"|`string`|Provide path to the Google Cloud Service account credentials. See template `Software/credentials.json.template`|`yes`|
|region|"us-central1"|`string`|Enter cloud region for resource creation|`yes`|
|zone|"us-central1-c"|`string`|Enter cloud zone for resource creation|`yes`|
|machine_types| `"n2-standard-2"`|`string`|[Google compute machine types](https://cloud.google.com/compute/docs/machine-types#n2_machine_types). See Google cloud [pricing](https://cloud.google.com/compute/vm-instance-pricing) to select a machine_type.|`yes`|
|bootDiskOS|"ubuntu20"|`string`|Supported OS include: rhel7, rhel8, ubuntu16, ubuntu18, ubuntu20. `bootDiskOS` is by default mapped to existing public images on GCP with the help of two variables `imageProject` and `imageFamily` mentioned below.|`yes`|
|imageProject| <ul><li>`rhel7 = "rhel-cloud"`</li></ul> <ul><li>`rhel8 = "rhel-cloud"`</li></ul> <ul><li>`ubuntu16 = "ubuntu-os-cloud"`</li></ul><ul><li>`ubuntu18 = "ubuntu-os-cloud"`</li></ul><ul><li>`ubuntu20 = "ubuntu-os-cloud"`</li></ul>| `map`|Boot disk images available on GCP are referenced using Image Project and Family.This variable maps the input `bootDiskOS` to default public images using the global ProjectID for the image.|`yes`|
|imageFamily|<ul><li>`rhel7 = "rhel-7"`</li></ul> <ul><li>`rhel8 = "rhel-8"`</li></ul> <ul><li>`ubuntu16 = "ubuntu-1604-lts"`</li></ul> <ul><li>`ubuntu18 = "ubuntu-1804-lts"`</li></ul> <ul><li>`ubuntu20 = "ubuntu-2004-lts"`</li></ul> |`map`| Boot disk images available on GCP are referenced using Image Project and Family.This variable maps the input `bootDiskOS` to default public images using the global image family.|`yes`|
|create_new_vpc|`false`|`bool`|Set this to `true` if new vpc network needs to be created and `false` if an existing one will be used. If this variable is set to `false`, the value for the variable `vpc_network_name` needs to be set to an existing network name this project has access to. |`yes`|
|vpc_network_name|"tf-test-network"|`string`|Set the value to an existing VPC network name if `create_new_vpc` is set to `false`.|`yes`|
|network_tags|["mps"]|`list`|Provide network firewall tags for applying the rules on target MPS VMs created by the scripts. These network_tags are passed as an input to the module `mpsworkernode`|`yes`|
|subnet_create|`false`|`bool`|"User Input stating whether a new subnet needs to be created or an existing subnet needs to be used"|`yes`|
|subnet_ip_cidr_range|"10.129.0.0/20"|`string`|Assign CIDR if creating new subnet. Make sure any other existing subnet within the considered VPC and network region does not have the same CIDR.|`yes`|
|subnet_name|"test-tf-subnet"|`string`|Set to existing subnet name if subnet_create set to `false`. Make sure the existing subnet exists within the existing VPC network stated in `vpc_network_name`|`yes`|
|mps_port|"9910"|`string`|"MPS port for backend service created for managed instance group. the frontend load balancer will be relaying requests on this port"|`yes`|
|allowclientip|["172.24.0.0/0"]|`list(string)`|Add comma seperated IP Ranges that should be allowed through the firewall|`yes`|
|Version|"R2021a"|`string`|Version of MATLAB Production Server |`yes`|
|MCR_url| <ul><li>v98  = "https://ssd.mathworks.com/supportfiles/downloads/R2020a/Release/6/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2020a_Update_6_glnxa64.zip"</li></ul><ul><li>v97  = https://ssd.mathworks.com/supportfiles/downloads/R2019b/Release/7/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2019b_Update_7_glnxa64.zip"</li></ul><ul><li> v99  = "https://ssd.mathworks.com/supportfiles/downloads/R2020b/Release/3/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2020b_Update_3_glnxa64.zip"</li></ul><ul><li>v910 = "https://ssd.mathworks.com/supportfiles/downloads/R2021a/Release/0/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2021a_glnxa64.zip"</li></ul>|`map`|Configure MATLAB runtime versions you would like to enable. Comment or remove versions that you don't intend to use. Note: The download urls for every version needs to be up to date with urls available at https://www.mathworks.com/products/compiler/matlab-runtime.html for every version and Linux.|`yes`|
|Agree_To_License|`no`|`string`| User should configure this variable to `yes`. By default it is set to `no`. By switching it to `yes` you are agreeing to MathWorks license agreement for using MATLAB Runtime and MATLAB Production Server. The package will not work without `Agree_To_License`=`yes` setting. |
|FIK|"0000-00000-0000-0000"|`string`|File Installation Key available for the licensed product.The File Installation Key can be downloaded from the License Center on the MathWorks website (if you are using a trial license, go to https://www.mathworks.com/licensecenter/trials). If you are using your organization's license, contact your administrator.|`yes`|
|LicenseManagerHost|"instance-name/ip"|`string`|Hostname/IP for the GCP instance where network license manager has been set up|`yes`|
|LicenseManagerPort|"27000"|`string`|Default port for FlexLM service. This port will be open on the firewall to allow traffic requesting for license checkout.|`yes`|
|ISO_Bucket_exists|false|`bool`|If you want to skip uploading ISO and have an existing GCS bucket with ISO, switch the default value to true and provide the Object address to the below variable.|`no`|
|ISO_Object_URI|"gs://valid-bucket-name/R2021.iso"|`string`|Provide a valid gsutil string for existing ISO object located in a  bucket you have permissions to read from.|`no`|
|ISO_Location|"/opt/Downloads/iso"|`string`|Folder path where MATLAB ISO is located. ISO file should be renamed as VERSION.iso e.g. R2019b.iso or R2020.iso"|`yes`|
|tag|"`username`-`build`-server-`date`"|`string`|A prefix to create cloud resources with unique names|`yes`|

**Modules**:

|Module Name|Module Description|
|-----------|------------------|
|`mpsworkernode`| Used to create single or multi-node worker VMs.<ul><li>Creates a Google compute instance to host MATLAB Production.</li></ul><ul><li>Assigns a `vpc`,`subnet` and firewall `network_tags`.</li></ul><ul><li>Installs MATLAB runtime and MATLAB Production Server.</li></ul>|
|`subnet`| Used only if `create_subnet` is set to `true`|
|`vpc_network`|Used only if `create_new_vpc` is set to `true`|



**Outputs**:

|Name|Terraform Resource | Description|
|----|-------------------|------------|
|mps-disk-image|`google_compute_image.mps.name`|Name of the disk image created during the Build stage. This image is used as an input for the deploy stage.|
|mps-disk-image-size|`google_compute_disk.default.size`|This is the disk size for the Build image. It is also the minimum disk size for creating a new disk with this image. This is used as an input in the Deploy stage.|
|mps-disk-image-id|`google_compute_image.mps.id`|Unique resource ID of the disk image created during the build stage. This is required as a reference when creating new disks with this pre-built image.|
|boot-disk-os|`var.bootDiskOS`|Boot disk OS used while creating the image.|


[//]: #  (Copyright 2021 The MathWorks, Inc.)
