# Provider and credentials
provider "google" {
  credentials = file(var.credentials_file_path)
  project = var.app_project
  region = var.region
  zone = var.zone
}

# Create a temporary GCS bucket for placing startup and helper scripts
resource "google_storage_bucket" "script" {
  name = "${var.tag}-tempscript-bucket"
  force_destroy = true
  provisioner "local-exec" {
   command = "gsutil -m cp -r ./placefilesinbucket/* gs://${google_storage_bucket.script.name}/"
 }
}

# Create GCS bucket for uploading and modifying compiled artifacts within server auto_deploy
resource "google_storage_bucket" "autodeploy" {
  name = "${var.tag}-autodeploy-bucket"
  force_destroy = true
}

# Create GCS bucket for accessing and updating server configuration
resource "google_storage_bucket" "config" {
  name = "${var.tag}-mps-config-bucket"
  force_destroy = true
  provisioner "local-exec" {
   command = "gsutil -m cp ./config/main_config gs://${google_storage_bucket.config.name}/"
 }
}

# Create a new VPC
module "mps_vpc_network" {
  count = var.create_new_vpc ? 1:0
  source  = "./modules/vpc_network"
  tag     = var.tag
  project = var.app_project
  network_tags = var.network_tags
  mps_port = var.mps_port
  allowclientip = var.allowclientip
  enable_https = var.enable_https
}

# Use existing VPC
data "google_compute_network" "input_vpc_network" {
  count = var.create_new_vpc ? 0 : 1
  name = var.vpc_network_name
}

# Add firewall rules if using and existing VPC to allow connections to MATLAB Production Server workers
resource "google_compute_firewall" "allow-mps-port" {
  depends_on = [data.google_compute_network.input_vpc_network]
  count = var.create_new_vpc ? 0 : 1
  name = "${var.tag}-fw-allow-http"
  network = var.vpc_network_name
  allow {
    protocol = "tcp"
    ports    = var.enable_https ? [var.mps_port,"443","22"] : [var.mps_port,"22"]
  }
  target_tags = ["mps"]
  source_ranges = var.allowclientip
}

# Add firewall rule to whitelist Google Frontend IP Sources
resource "google_compute_firewall" "allow-healthcheck" {
  depends_on = [data.google_compute_network.input_vpc_network]
  count = var.create_new_vpc ? 0 : 1
  name = "${var.tag}-fw-allow-lb"
  network = var.vpc_network_name
  allow {
    protocol = "tcp"
    ports    = [ var.mps_port ]
  }
  target_tags = [ "loadbalancer" ]
  source_ranges = [ "130.211.0.0/22", "35.191.0.0/16"]
}

# Create a new Subnet
module "mps_subnet" {
  count = var.subnet_create ? 1:0
  source  = "./modules/subnet"
  tag          = var.tag
  ip_cidr_range = var.subnet_ip_cidr_range
  region        = var.region
  network_id    = var.create_new_vpc ? module.mps_vpc_network[0].id : data.google_compute_network.input_vpc_network[0].id
}

# Uses existing subnet
data "google_compute_subnetwork" "input-subnetwork" {
  count = var.subnet_create ? 0 : 1
  name = var.subnet_name
  region = var.region
}

# Creating Google Compute instances for MATLAB Production Server worker nodes
module "mps_worker_node" {

  depends_on = [ google_storage_bucket.autodeploy, google_compute_disk.default, google_storage_bucket.script, google_storage_bucket.config ]

  # module location
  source  = "./modules/mpsworkernode"

  # gcloud user access
  username = var.username
  gce_ssh_key_file_path = var.gce_ssh_key_file_path

  # Tag for naming purposes
  tag = var.tag

  # Network resources
  network = var.create_new_vpc ? module.mps_vpc_network[0].name : data.google_compute_network.input_vpc_network[0].name
  subnetwork = var.subnet_create ? module.mps_subnet[0].name : data.google_compute_subnetwork.input-subnetwork[0].name
  network_tags = var.network_tags

  # Compute instance type
  machine_type = var.machine_types

  # Number of MPS instances
  numworkernodes = var.numworkernodes

  # Number of concurrent threads on every MPS instance
  numworker= var.numworker

  # GCS bucket names
  scriptBucketName = google_storage_bucket.script.name
  autodeployBucketName = google_storage_bucket.autodeploy.name
  configBucketName = google_storage_bucket.config.name

  # Product version
  Version = var.Version

  # Base OS - Linux distro and version
  imageProject = var.imageProject[var.bootDiskOS]
  imageFamily  = var.imageFamily[var.bootDiskOS]

  # Existing MATLAB License Manager Host and Service port details
  LicenseManagerIP = var.LicenseManagerHost
  LicenseManagerPort = var.LicenseManagerPort

} #vm_instance

# Create disk with built image containing MPS and MATLAB Runtime installation
resource "google_compute_disk" "default" {
  count = var.numworkernodes
  name  = "${var.tag}-image-disk-${count.index}"
  image = var.sourcediskimage
  type  = "pd-ssd"
  size  = var.sourcedisksize
}

# Attach disk with MPS and Runtime image to the compute instance created by module `mps_worker_node`
resource "google_compute_attached_disk" "default" {
  count = var.numworkernodes
  disk     = google_compute_disk.default[count.index].id
  instance = module.mps_worker_node.id[count.index]
}

# Create loadbalancer for MPS worker nodes
module "load_balancer" {
   depends_on = [module.mps_worker_node]
   source = "./modules/loadbalancer"
   tag = var.tag
   zone = var.zone
   listOfmpsWorkernodesSelflink = tolist(module.mps_worker_node.Selflink)
   mps_port = var.mps_port
   enable_https = var.enable_https
   certificate_path = var.certificate_path
   privatekey_path = var.privatekey_path
}

# Test http health check for MATLAB Production Server. 
# See if MPS is ready to receive http requests
resource "null_resource" "check_http_instance"{
  depends_on = [ module.load_balancer ]
  provisioner "local-exec" {
    command = "./local_scripts/test_mps_http_health.sh ${module.load_balancer.http-mps-endpoint} 2>/dev/null"
  }
}

# (c) 2021 MathWorks, Inc.
