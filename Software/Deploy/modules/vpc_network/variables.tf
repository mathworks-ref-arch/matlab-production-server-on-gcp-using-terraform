# GCP project name
variable "project" {
  description = "ProjectID"
  default = ""
}

# Tag to uniquely name resources
variable "tag" {
  description = "A prefix to make resource names unique"
  default=""
}

# Target tags to apply firewall rules
variable "network_tags" {
  description = " List of target tags for vms to apply firewall rules"
  default = ["mps"]
}

# MPS Port
variable "mps_port" {
  type=string
  default="9910"
  description = "MPS backend service port on VM group"
}

# Client IPs
# change this to the range specific to your organization
variable "allowclientip" {
  default = ["172.24.0.0/16"]
  description = "Add IP Ranges that would connect/submit job"
}

# Enable HTTPS
variable "enable_https"{
  type = bool
  default = false
}

# (c) 2021 MathWorks, Inc.
