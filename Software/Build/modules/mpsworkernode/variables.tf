## Input variables for mpsworkernode module

# gcloud user with access to the projecta nd credentials
variable "username" {
  type = string
  default = ""
  description = "local user who is authenticated to ssh and run startup scripts"
}

# gcloud ssh credentials
variable "gce_ssh_key_file_path" {
  type = string
  description = "/home/local-gce-user/.ssh/google_compute_engine.pub"
  default = ""
}

## VM resource specific variables

# tag for naming resources
variable "tag" {
  description = "A prefix to make resource names unique"
  default=""
}

# instance hardware
variable "machine_type" {
  default = ""
  description = "n2-standard-2 , n2-standard-4 , n2-standard-8"
}

# boot disk OS - global image project
variable "imageProject" {
  type = string
  description = "Global image project"
}

# boot disk OS - global image family
variable "imageFamily" {
  type = string
  description = "Global image family"
}

# number of gcp instances
variable "numworkernodes" {
  type = number
  description = "Number of nodes in the cluster.cal cores per node"
}

# vpc for mps instance
variable "network" {
  default = ""
  description = "VPC network name"
}

# firewall target network tags for vm
variable "network_tags" {
  default = []
  description = "Target Network tags"
}

# subnet for resources
variable "subnetwork" {
  default = ""
  description = "subnet name"
}


## Temporary storage buckets

# GCS bucket containing MATLAB ISO for installation
variable "isoBucketName" {
  type = string
  description = "Name for creating a temporary cloud storage bucket to carry the ISO"
  default=""
}

# GCS bucket containing shell scripts for installation
variable "scriptBucketName" {
  type = string
  description = "Name for creating a temporary cloud storage bucket to carry the scripts"
  default=""
}

# GCS bucket containing MATLAB runtime for installation
variable "runtimeBucketName" {
  type = string
  description = "Name for creating a persistent cloud storage bucket for accessing runtime"
  default=""
}

## Product specific variables

# MPS Version
variable "Version" {
  type = string
  default = ""
  description = "Example 'R2020a' , 'R2020b' etc"
}

## License Information

# Do you agree to the License
variable "Agree_To_License"{
  type = string
  description = "Switch to 'yes' .User needs to agree to the license terms for installaion."
  default = "no"
}

# License File Installation Key
variable "FIK"{
  type = string
  description = "FIK"
  default = ""
}

# MATLAB License Manager host
variable "LicenseManagerHost"{
  default = ""
}

# MATLAB License Manager service port
variable "LicenseManagerPort"{
  default = ""
}

# (c) 2021 MathWorks, Inc.
