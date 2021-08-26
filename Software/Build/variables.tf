# Google Cloud Project ID
variable "app_project" {
  type = string
  default = "projectID"
  description = "Enter ProjectID"
}

# gcloud authenticated user
variable "username" {
  type = string
  default = "matlabuser"
  description = "Local username who is authenticated to ssh and run startup scripts"
}

# Path to ssh key for gcloud login and authorization
variable "gce_ssh_key_file_path" {
  type = string
  description = "/home/local-gce-user/.ssh/google_compute_engine.pub"
  default = "/home/matlabuser/.ssh/google_compute_engine.pub"
}

# Path to service account credentials 
variable "credentials_file_path"{
  type = string
  default = "credentials.json"
  description = "Provide full path to the credentials file for your service account"
}

# Cloud region for resource creation
variable "region" {
  type = string
  default = "us-central1"
  description = "Enter cloud region for instances"
}

# Zone for resource creation
variable "zone" {
  type = string
  default = "us-central1-c"
  description = "Add zone for instances"
}

# Compute requirements of an instance
# See instance type on GCP for reference
# https://cloud.google.com/compute/vm-instance-pricing
# https://cloud.google.com/compute/docs/machine-types#n2_machine_types


variable "machine_types" {
  type    = string
  description = "Select VM hardware such as 'n2-standard-2' , 'n2-standard-4', 'n2-standard-8'"
  default = "n2-standard-4"
}

## Boot Disk OS details

# Provide OS and version for VM
variable "bootDiskOS" {
  type = string
  description = "Supported OS include: rhel7, rhel8, ubuntu16, ubuntu18, ubuntu20"
  default = "ubuntu20"
}

# Map bootDiskOS to Global image project on GCP

variable "imageProject" {
  type = map
  description = "Global image project"
  default = {
    rhel7 = "rhel-cloud"
    rhel8 = "rhel-cloud"
    ubuntu16 = "ubuntu-os-cloud"
    ubuntu18 = "ubuntu-os-cloud"
    ubuntu20 = "ubuntu-os-cloud"
  }
}

# Map bootDiskImage to image family on GCP

variable "imageFamily" {
  type = map
  description = "Global image family"
  default = {
    rhel7 = "rhel-7"
    rhel8 = "rhel-8"
    ubuntu16 = "ubuntu-1604-lts"
    ubuntu18 = "ubuntu-1804-lts"
    ubuntu20 = "ubuntu-2004-lts"
  }
}

## Network
# Set this to `true` if new vpc config needs to be created and `false` if en existing one will be used
variable "create_new_vpc" {
 type = bool
 default = false
}

# Set this to existing or new VPC network name depending on `create_new_vpc` is set to `false` or `true`
variable "vpc_network_name" {
 type = string
 default = "tf-test-network"
}

# Provide network firewall tags for Target VMs
variable "network_tags" {
  type = list
  default = ["mps"]
}

# Set to True if new subnet needs to be created
variable "subnet_create" {
  description = "User Input stating whether new subnet needs to be created or an existing subnet needs to be used"
  default = false
}

# Provide valid CIDR if creating a new Subnet
variable "subnet_ip_cidr_range" {
 type = string
 default = "10.129.0.0/20"
 description = "Assign CIDR if creating new subnet. Make sure any other existing subnet within the considered VPC and network region does not have the same CIDR."
}

# Subnet Name as Input.
# Set to existing subnet name if subnet_create set to `false`.
# Set to new subnet name if subnet_create set to `true`
variable "subnet_name" {
  description = "Existing Subnet Name within Parent VPC Module"
  default = "test-tf-subnet"
}

# Port for MPS access
variable "mps_port" {
  type=string
  default="9910"
  description = "MPS backend service port on VM group"
}

# Set client IP
# Change this to the range specific to your organization
variable "allowclientip" {
  default = ["76.24.0.0/16", "144.212.0.0/16"]
  type = list(string)
  description = "Add IP Ranges that would connect/submit job"
}

## Product specific variables

# MATLAB Production Server Version
variable "Version" {
  type = string
  default = "R2021a"
  description = "Example 'R2021a' , 'R2020b' , 'R2020a' etc"
}

# MATLAB Runtime Version. Uncomment/Add versions that need to be supported
# Comment out the versions that will not be used
# Most updated urls are available at https://www.mathworks.com/products/compiler/matlab-runtime.html
variable "MCR_url" {
  type    = map
  default = {
  v97  = "https://ssd.mathworks.com/supportfiles/downloads/R2019b/Release/8/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2019b_Update_7_glnxa64.zip"
  v98  = "https://ssd.mathworks.com/supportfiles/downloads/R2020a/Release/6/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2020a_Update_6_glnxa64.zip"
  v99  = "https://ssd.mathworks.com/supportfiles/downloads/R2020b/Release/5/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2020b_Update_3_glnxa64.zip"
  v910 = "https://ssd.mathworks.com/supportfiles/downloads/R2021a/Release/4/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2021a_Update_4_glnxa64.zip"
  }
}

## Licensing

# Do you agree to the License
variable "Agree_To_License"{
  type = string
  description = "Switch to 'yes' .User needs to agree to the license terms for installaion."
  default = "no"
}

# Provide File Installation Key for the License
variable "FIK"{
  type = string
  description = "FIK 5XXX9-0XXX0-1XXX6-4XXX4"
  default = ""
}

# Hostname/IP for the GCP instance where license manager is set up
# Recommended to have this instance within the same VPC as Production Server instances/worker nodes
variable "LicenseManagerHost"{
  default = "10.XX.XX.XXX"
}

# License Manager Port
# Communication within VPC should be allowed for license checkout
variable "LicenseManagerPort"{
  default = "27000"
}

# Is there an existing bucket with MATLAB ISO uploaded
variable "ISO_Bucket_exists"{
  type = bool
  default = false
  description = "If you want to skip uploading ISO and have an existing GCS bucket with ISO, switch the default value to true an dprovide the Object address to the below variable."
}

# If ISO_Bucket_exists is set to true, provide the gsutil string to iso object here
variable "ISO_Object_URI"{
  type = string
  default = "gs://valid-bucket-name/R2021.iso"
  description = "Provide a valid gsutil string for existing ISO object located in a  bucket you have permissions to read from."
}

# Local Directory where MATLAB ISO is or should be located
variable "ISO_Location" {
    type = string
    default = "/opt/Downloads"
    description = "Folder path where MATLAB ISO is located. ISO file should be renamed as VERSION.iso e.g. R2019b.iso or R2020.iso"
}

# Custom tag for unique naming of GCP resources
variable "tag" {
  default="username-image-prodserver-date"
  description = "A prefix to make resource names unique"
}

# (c) 2021 MathWorks, Inc.
