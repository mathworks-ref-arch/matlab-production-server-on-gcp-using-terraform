## Input variables for the module loadbalancer

# Tag for naming resources uniquely
variable "tag" {
  type = string
  description = "A prefix to make resource names unique"
  default = ""
}

# Port at which mps running
variable "mps_port" {
  type = string
  description = "MPS port on backend service for request forwarding"
  default = "9910"
}

# Cloud zone for resourcs
variable "zone"{
  type = string
  description = "Zone"
  default = "us-central1-c"
}

# MPS worker nodes (compute instances) to be include in the manage instance group
variable "listOfmpsWorkernodesSelflink"{
  description = "list of self links to vms prepared for MPS worker nodes"
}
 
# Path to private key
variable "privatekey_path"{
  type = string
  description = "Path to private key e.g. Software/Deploy/certificate/private.key"
}

# Path to certificate
variable "certificate_path"{
  type = string
  description = "Path to signed certificate e.g. Software/Deploy/certificate/cert.pem"
}

# Enable HTTPS
variable "enable_https"{
  type = bool
  default = false
}

# (c) 2021 MathWorks, Inc.
