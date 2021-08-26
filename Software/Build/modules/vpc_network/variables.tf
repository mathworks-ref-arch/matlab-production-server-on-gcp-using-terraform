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

# firewall target network tags for vm
variable "network_tags" {
  default = ["mps"]
  description = "Target Network tags"
}

# MPS port
variable "mps_port" {
  type=string
  description = "MPS backend service port on VM group"
}

# Client IPs
# change this to the range specific to your organization
variable "allowclientip" {
  type = list(string)
  description = "Add IP Ranges that would connect/submit job"
}

# (c) 2021 MathWorks, Inc.
