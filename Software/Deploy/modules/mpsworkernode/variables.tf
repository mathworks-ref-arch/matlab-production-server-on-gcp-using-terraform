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
  default = "debian-cloud"
}

# boot disk OS - global image family
variable "imageFamily" {
  type = string
  description = "Global image family"
  default = "debian-10"
}

# number of gcp instances
variable "numworkernodes" {
  type = number
  description = "Number of MPS instances"
  default = 1
}

# number of concurrent requests er mps instance
variable "numworker"{
    type = number
    description = "Based on licensed workers - (2-8) workers/threads per node in the cluster."
    default = 1
}

## Network detais

# VPC network for the compute instances
variable "network"{
  default = ""
  description = "VPC network name"
}

# firewall target network tags for vm
variable "network_tags" {
  default = []
  description = "Target Network tags"
}

# subnet
variable "subnetwork"{
  default = ""
  description = "subnet name"
}

## Bucket resources

# Temporary GCS bucket for holding install scripts
variable "scriptBucketName" {
  type = string
  description = "Name for creating a temporary cloud storage bucket to carry the scripts"
  default=""
}

# GCS buckets for accessing MPS instance config
variable "configBucketName" {
  type = string
  description = "Name for creating a persistent cloud storage bucket for accessing and editing config"
  default=""
}

# GCS buckets for accessing autodeploy in order to upload MATLAB ctfs
variable "autodeployBucketName" {
  type = string
  description = "Name for creating a persistent cloud storage bucket for accessing autodeploy"
  default=""
}

## Product specific variables

# MPS Version
variable "Version" {
  type = string
  default = ""
  description = "Example 'R2020a' , 'R2020b' etc"
}

# IP for existing MATLAB License Manager
variable "LicenseManagerIP"{
  default = ""
}

# Port at which License manager is running
variable "LicenseManagerPort"{
  default = ""
}

# (c) 2021 MathWorks, Inc.
