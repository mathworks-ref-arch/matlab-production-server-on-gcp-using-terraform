## Deploy Stage

### Resources created during Deploy stage include:

| Resource Type | Number | Lifecycle |
|---------------|--------|-----------|
|Google Compute Instances | As configured | Permanent|
|Google Cloud Managed instance group| 1 | Permanent|
|Google Cloud Load Balancer| 1 | Permanent|
|VPC network (Optional)| 1 | Permanent|
|Google Cloud Storage buckets| 2| Permanent|


In **Deploy Stage** stage the Terraform scripts are used to leverage the Terraform outputs `sourcediskimage` and `sourcedisksize` returned by the `Build` stage to set up a fully functional `MATLAB Production Server` on Google Cloud Platform.

**Pre-requisites** :
* Existing [Network License Manager  setup on Google Cloud Platform](https://insidelabs-git.mathworks.com/EI-DTST/Staging/setting-up-license-manager-for-matlab-on-google-cloud-using-terraform). It is recommended that the instance hosting the license manager is available in the same VPC network as the MATLAB Production Server instances.
* `Google Compute disk image` from Build stage

**See details for Deploy stage**:
* Terraform `variables`
* Terraform `modules`
* Terraform `output`

**Variables**:

|Variable Name|Default Value| Type | Description |Required|
|-------------|-------------|------|--------------|-------|
|app_project | "projectID" | `string`| [Google Cloud project ID](https://cloud.google.com/resource-manager/docs/creating-managing-projects) | `yes` |
|username| "user" | `string`| [User authorized to access the Cloud Platform with Google user credentials](https://cloud.google.com/sdk/gcloud/reference/auth/login)|`yes`|
|gce_ssh_key_file_path|"/home/user/.ssh/google_compute_engine.pub"|`string`|Path to public ssh keys for gcloud users. [Locating keys](https://cloud.google.com/compute/docs/instances/adding-removing-ssh-keys#locatesshkeys)|`yes`|
|credentials_file_path|"/home/user/gcp/credentials.json"|`string`|Provide path to the Google Cloud Service account credentials. See template `Software/credentials.json.template`|`yes`|
|region|"us-central1"|`string`|Enter cloud region for resource creation|`yes`|
|zone|"us-central1-c"|`string`|Enter cloud zone for resource creation|`yes`|
|machine_types| "n2-standard-2"|`string`|[Google compute machine types](https://cloud.google.com/compute/docs/machine-types#n2_machine_types). See Google cloud [pricing](https://cloud.google.com/compute/vm-instance-pricing) to select a machine_type.|`yes`|
|bootDiskOS|"ubuntu20"|`string`|"Supported OS include: rhel7, rhel8, ubuntu16, ubuntu18, ubuntu20". `bootDiskOS` is by default mapped to existing public images on GCP with the help of two variables `imageProject` and `imageFamily` mentioned below.|`yes`|
|imageProject| <ul><li>`rhel7 = "rhel-cloud"`</li></ul> <ul><li>`rhel8 = "rhel-cloud"`</li></ul> <ul><li>`ubuntu16 = "ubuntu-os-cloud"`</li></ul><ul><li>`ubuntu18 = "ubuntu-os-cloud"`</li></ul><ul><li>`ubuntu20 = "ubuntu-os-cloud"`</li></ul>| `map`|Boot disk images available on GCP are referenced using Image Project and Family.This variable maps the input `bootDiskOS` to default public images using the global ProjectID for the image.|`yes`|
|imageFamily| <ul><li>`rhel7 = "rhel-7"`</li></ul> <ul><li>`rhel8 = "rhel-8"`</li></ul> <ul><li>`ubuntu16 = "ubuntu-1604-lts"`</li></ul> <ul><li>`ubuntu18 = "ubuntu-1804-lts"`</li></ul> <ul><li>`ubuntu20 = "ubuntu-2004-lts"`</li></ul> |`map`| Boot disk images available on GCP are referenced using Image Project and Family.This variable maps the input `bootDiskOS` to default public images using the global image family.|`yes`|
|create_new_vpc|`false`|`bool`|Set this to `true` if new vpc network needs to be created and `false` if an existing one will be used. If this variable is set to `false`, the value for the variable `vpc_network_name` needs to be set to an existing network name this project has access to. |`yes`|
|vpc_network_name|"tf-test-network"|`string`|Set the value to an existing VPC network name if `create_new_vpc` is set to `false`.|`yes`|
|network_tags|["mps"]|`list`|Provide network firewall tags for applying the rules on target MPS VMs created by the scripts. These network_tags are passed as an input to the module `mpsworkernode`|`yes`|
|subnet_create|`false`|`bool`|"User Input stating whether a new subnet needs to be created or an existing subnet needs to be used"|`yes`|
|subnet_ip_cidr_range|"10.129.0.0/20"|`string`|Assign CIDR if creating new subnet. Make sure any other existing subnet within the considered VPC and network region does not have the same CIDR.|`yes`|
|subnet_name|"test-tf-subnet"|`string`|Set to existing subnet name if subnet_create set to `false`. Make sure the existing subnet exists within the existing VPC network stated in `vpc_network_name`|`yes`|
|mps_port|"9910"|`string`|"MPS port for backend service created for managed instance group. the frontend load balancer will be relaying requests on this port"|`yes`|
|allowclientip|"172.24.0.0/0"|`string`|Add comma seperated IP Ranges that should be allowed through the firewall|`yes`|
|Version|"R2021a"|`string`|Version of MATLAB Production Server |`yes`|
|LicenseManagerHost|"instance-name/ip"|`string`|Hostname/IP for the GCP instance where network license manager has been set up|`yes`|
|LicenseManagerPort|"27000"|`string`|Default port for FlexLM service. This port will be open on the firewall to allow traffic requesting for license checkout.|`yes`|
|tag|"`username`-`deploy`-server-`date`"|`string`|A prefix to create cloud resources with unique names|`yes`|
|numworkernodes|2|`number`|Number of MATLAB Production Server worker VMs you would like to create based on expected incoming load|`yes`|
|numworker|4|`number`|Number of concurrent requests handled by a VM (should be set to vCPUs). `numworkernodes`*`numworker` should be less than or equal to the number of licensed workers|`yes`|
|sourcediskimage|"output-image-name-from-build-stage"|`string`|Name of source disk image created in the build stage. The image created contains MATLAB runtime and MATLAB Production Server installation and configuration.|`yes`|
|sourcedisksize|50|`number`|Size of existing source disk image created during the build stage.|`yes`|
|enable_https|false|`bool`|Switch this to `true` if you have SSL certificates available to enable https for the load balancer.|`yes`|
|privatekey_path|"home/user/certificate/psgcp.key"|`string`|Path to private key e.g. Software/Deploy/certificate/private.key|`yes`|
|certificate_path|"/home/user/certificate/mpsgcp.pem"|`string`|Path to signed certificate e.g. Software/Deploy/certificate/cert.pem|`yes`|

**Modules**:

|Module Name|Module Description|
|----|-------------------|
|`loadbalancer`|<ul><li>Creates instance group for all Production Server instances.</li></ul> <ul><li>Assigns named port for Production server port e.g. 9910.</li></ul> <ul><li>Creates backend service for the loadbalancer with target instance group</li></ul> <ul><li>Creates health check using default health api provided by MATLAB Production Server at `api/health`</li></ul> <ul><li>Creates a URL map</li></ul> <ul><li>Creates global forwarding rule for Load Balancer</li></ul>|
|`mpsworkernode`|<ul><li>Creates GCP instance.</li></ul><ul><li>Assigns `vpc`, `subnet` and firewall `network_tags`.</li></ul><ul><li>Installs MATLAB Runtime and MATLAB Production Server.</li></ul>|
|`subnet`| Used only if `create_subnet` is set to `true`|
|`vpc_network`|Used only if `create_new_vpc` is set to `true`|

**Outputs**:

|Name|Terraform Resource | Description|
|----|-------------------|------------|
|mps-endpoint|`module.load_balancer.mps-endpoint`|base Url for REST endpoint exposing MATLAB functions|
|mps-worker-nodes|`module.mps_worker_node.name`|IPs for MPS worker nodes|
|mps-autodeploy-bucket|`google_storage_bucket.autodeploy.name`|Cloud storage bucket for user to upload ctfs|
|mps-config-bucket|`google_storage_bucket.config.name`|Cloud storage bucket for users to access Production Server Config|

[//]: #  (Copyright 2021 The MathWorks, Inc.)

