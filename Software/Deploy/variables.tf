# Use the variables.tf to provide default inputs

# Google Cloud ProjectID you have access to and will be using for resource creation
variable "app_project" {
  type = string
  default = "pftappdeploy"
  description = "Enter ProjectID"
}

# gcloud authenticated user with ssh keys
variable "username" {
  type = string
  default = "username"
  description = "local user who is authenticated to ssh and run startup scripts"
}

# Path to local ssh keys for the gcloud user
variable "gce_ssh_key_file_path" {
  type = string
  default = "/home/user/.ssh/google_compute_engine.pub"
  description = "/home/local-gce-user/.ssh/google_compute_engine.pub"
}

# Path to service account credentials 
variable "credentials_file_path"{
  type = string
  default = "credentials.json"
  description = "Provide full path to the credentials file for your service account"
}

# Google Cloud region for resources
variable "region" {
  type = string
  default = "us-central1"
  description = "Enter cloud regions"
}

# Google Cloud zone for resources
variable "zone" {
  type = string
  default = "us-central1-c"
  description = "Add zone for cluster vms"
}

# Compute requirements of an instance
# See instance type on GCP for reference
# https://cloud.google.com/compute/vm-instance-pricing
# https://cloud.google.com/compute/docs/machine-types#n2_machine_types


variable "machine_types" {
  type    = string
  default = "n2-standard-4"
  description = "Select VM hardware such as 'n2-standard-2' , 'n2-standard-4', 'n2-standard-8'"
}

# Boot Disk OS details

# Provide OS and version for VM
variable "bootDiskOS" {
  type = string
  default = "ubuntu20"
  description = "Supported OS include: rhel7, rhel8,ubuntu16, ubuntu18, ubuntu20"
}

# Map bootDiskImage to Global image project on GCP

variable "imageProject" {
  type = map
  default = {
    rhel7 = "rhel-cloud"
    rhel8 = "rhel-cloud"
    ubuntu16 = "ubuntu-os-cloud"
    ubuntu18 = "ubuntu-os-cloud"
    ubuntu20 = "ubuntu-os-cloud"
  }
  description = "Global image project for the requested image."
}

# Map bootDiskImage to image family on GCP
variable "imageFamily" {
  type = map
  default = {
    rhel7 = "rhel-7"
    rhel8 = "rhel-8"
    ubuntu16 = "ubuntu-1604-lts"
    ubuntu18 = "ubuntu-1804-lts"
    ubuntu20 = "ubuntu-2004-lts"
  }
    description = "Global image family for the requested image."
}

# Set this to `true` if new vpc config needs to be created and
# `false` if en existing one will be used
variable "create_new_vpc" {
 type = bool
 default = false
 description = "Set this to false, if using an existing VPC. Very commonly used to include MATLAB based VMs within the License Manager VPC."
}

# VPC Name as Input. Set the default to an existing vpc if `create_new_vpc` is `false`
# or to a new vpc name if `create_new_vpc` is set to `true`
variable "vpc_network_name" {
 type = string
 default = "tf-test-network"
 description = "Name of the existing VPC you would like to deploy into."
}

# Provide firewall tags for target VMs
variable "network_tags" {
  type = list
  default = ["mps"]
  description = "Provide a network tag to allow firewall connections for port value provided for 'mps_port'"
}

# Frontend Loadbalancer will route incoming external http/https requests through firewall to this port
variable "mps_port" {
  type = string
  default = "9910"
  description = "MPS backend service port on VM group. Frontend Loadbalancer will route incoming external http/https requests through firewall to this port."
}

# Set to `true` if new subnet needs to be created
variable "subnet_create" {
  type = bool
  default = false
  description = "Set to true or false depending on whether a new subnet needs to be created or an existing subnet within an existing networkwill be used for deployment."
}

variable "subnet_ip_cidr_range" {
 type = string
 default = "10.129.0.0/20"
 description = "CIDR for new subnet.Make sure any other existing subnet within the considered VPC and network region does not have the same CIDR."
}

# Subnet Name as Input. Set the default to an existing subnet if `subnet_create` is `false` or to a new subnet name if `subnet_create` is set to `true`
variable "subnet_name" {
  type = string
  default = "test-tf-subnet"
  description = "If subnet_create is false, provide existing Subnet mame within the VPC."
}

# Allowed Client IPs
# Change this to the range specific to your organization
variable "allowclientip" {
  default = ["76.24.0.0/16", "144.212.0.0/16"]
  type = list(string)
  description = "Add IP Ranges that would connect/submit job e.g. 172.24.0.0/0"
}

## Product specific variables

# MPS Version
variable "Version" {
  type = string
  default = "R2021a"
  description = "Example 'R2020a' , 'R2020b' etc"
}

# Provide IP/HostID for the Google instance where MATLAB License Manager has been setup
# It is recommended to have this instance within the same VPC as the MPS worker node instances for network security reasons
variable "LicenseManagerHost"{
  type = string
  default = "1xx.98.xx.xx1"
  description = "Identifiable IP or hostname of the existing License Manager hosting MATLAB Production Server license"
}

# Provide port for communication with License manager service and MPS worker nodes (within same VPC is recommended)
variable "LicenseManagerPort"{
  type = string
  default = "27000"
  description = "TCP port used by License Manager to listen for license checkout requests. This port should be open on the License Manager firewall for expected client IPS."
}

# Provide a tag for supporting globally unique naming convention of resources on GCS
variable "tag" {
  type = string
  default = "username-deployed-prodserver"
  description = "A prefix to make resource names unique"
}

# Number of MPS worker nodes based on load expected
variable "numworkernodes" {
  type = number
  default = 2
  description = "Number of nodes in the cluster."
}

# Number of parallel/concurrent requests on every MPS nodes
# Consider memory and vCPU for making the decision
variable "numworker" {
  type = number
  default = 4
  description = "Based on licensed workers - (2-8) workers/threads per node in the cluster."
}

# Name of existing disk image containing MPS and MATLAB Runtime installations
variable "sourcediskimage"{
  type = string
  default = ""
  description = "Name of existing source disk image with MPS and Runtime installations"
}

# Size of existing disk from which 'sourcediskimage' was built
variable "sourcedisksize"{
  type = number
  default = 50
  description = "Size of existing source disk image with MPS and Runtime installations. Example 1g"
}

# Enable HTTPS
variable "enable_https"{
  type = bool
  default = false
}

# Path to private key
variable "privatekey_path"{
  type = string
  default = "/home/user/gcp/certificate/mpsgcp.key"
  description = "Path to private key e.g. Software/Deploy/certificate/private.key"
}

# Path to certificate
variable "certificate_path"{
  type = string
  default = "/home/user/gcp/certificate/mpsgcp.pem"
  description = "Path to signed certificate e.g. Software/Deploy/certificate/cert.pem"
}

# (c) 2021 MathWorks, Inc.
