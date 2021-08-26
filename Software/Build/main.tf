# Provider and credentials
provider "google" {
  credentials = file(var.credentials_file_path)
  project = var.app_project
  region = var.region
  zone = var.zone
}

# check if user has agreed to license for installing Runtime and MATLAB Production Server
resource "null_resource" "checklicenseagreement"{
  count= var.Agree_To_License == "no" ? 1 : 0
  provisioner "local-exec" {
    command = "echo You need to agree to license before installing MATLAB Runtime and MATLAB Production Server.Change the default value for the variable Agree_To_License from 'no' to 'yes'. && exit 1"
  }
}

# check if user has agreed to license for installing Runtime and MATLAB Production Server
resource "null_resource" "checkISObucketExists"{
  count= var.ISO_Bucket_exists ? 1 : 0
  provisioner "local-exec" {
    command = "echo Checking if URI, ${var.ISO_Object_URI} provided for variable 'ISO_Object_URI' is a valid URL. && ./local_scripts/check_iso_object_uri.sh ${var.ISO_Object_URI}"
  }
}

# Create a GCS bucket to host MPS installer
resource "google_storage_bucket" "iso" {
  depends_on = [ null_resource.checklicenseagreement , null_resource.checkISObucketExists ]
  # Do not create a bucket if the below variable is true. Since ISO already exists in a GCS bucket.
  count = var.ISO_Bucket_exists ? 0 : 1
  name = "${var.tag}-build-iso-bucket"
  force_destroy = true
   provisioner "local-exec" {
    command = "./local_scripts/local_iso.sh ${var.Version} ${var.ISO_Location} && gsutil -o GSUtil:parallel_composite_upload_threshold=150M cp -r ${var.ISO_Location}/${var.Version}.iso gs://${google_storage_bucket.iso[0].name}/"
  }
}



# Create a GCS bucket to host installation scripts
resource "google_storage_bucket" "script" {
  depends_on = [ null_resource.checklicenseagreement , null_resource.checkISObucketExists ]
  name = "${var.tag}-build-tempscript-bucket"
  force_destroy = true
  provisioner "local-exec" {
   command = " gsutil -m cp -r ./placefilesinbucket/* gs://${google_storage_bucket.script.name}/"
 }
}

# Create a GCS bucket to host runtime installers
resource "google_storage_bucket" "runtime" {
  depends_on = [ null_resource.checklicenseagreement , null_resource.checkISObucketExists ]
  name = "${var.tag}-build-runtime-bucket"
  force_destroy = true
}

# Create a resource to upload runtimes to GCS bucket
resource "null_resource" "runtime_download" {
  depends_on = [ null_resource.checklicenseagreement , google_storage_bucket.runtime , null_resource.checkISObucketExists  ]

  for_each = var.MCR_url
   provisioner "local-exec" {
    command = "./local_scripts/local_runtime.sh ${each.key} ${var.MCR_url[each.key]} ${google_storage_bucket.runtime.name}"
  }
}

# Create vpc
module "mps_vpc_network" {
  depends_on = [ null_resource.checklicenseagreement , null_resource.checkISObucketExists ]
  count = var.create_new_vpc ? 1:0
  source  = "./modules/vpc_network"
  tag     = var.tag
  project = var.app_project
  network_tags = var.network_tags
  mps_port = var.mps_port
  allowclientip = var.allowclientip
}

# Use existing VPC
data "google_compute_network" "input_vpc_network" {
  count = var.create_new_vpc ? 0 : 1
  name = var.vpc_network_name
}

# Add firewall rules to allow mps connections for existing network
resource "google_compute_firewall" "allow-mps" {
  depends_on = [ null_resource.checklicenseagreement , null_resource.checkISObucketExists ]
  count = var.create_new_vpc ? 0 : 1
  name = "${var.tag}-fw-allow-http"
  network = var.vpc_network_name
  allow {
    protocol = "tcp"
    ports    = [var.mps_port,"22"]
  }
  target_tags = ["mps"]
  source_ranges = var.allowclientip
}

# Create subnet
module "mps_subnet" {
  depends_on = [ null_resource.checklicenseagreement , null_resource.checkISObucketExists ]
  count = var.subnet_create ? 1:0
  source  = "./modules/subnet"
  tag          = var.tag
  ip_cidr_range = var.subnet_ip_cidr_range
  region        = var.region
  network_id    = var.create_new_vpc ? module.mps_vpc_network[0].id : data.google_compute_network.input_vpc_network[0].id
}

# Use existing subnet
data "google_compute_subnetwork" "input-subnetwork" {
  count = var.subnet_create ? 0 : 1
  name = var.subnet_name
  region = var.region
}

# Creating VM for MATLAB Production Server
module "mps_worker_node" {

  depends_on = [google_storage_bucket.iso, google_storage_bucket.script, google_storage_bucket.runtime, null_resource.runtime_download , null_resource.checklicenseagreement, null_resource.checkISObucketExists ]

  source  = "./modules/mpsworkernode"
  # access
  username = var.username
  gce_ssh_key_file_path = var.gce_ssh_key_file_path

  # resources
  tag = var.tag

  # Network resources
  network = var.create_new_vpc ? module.mps_vpc_network[0].name : data.google_compute_network.input_vpc_network[0].name
  subnetwork = var.subnet_create ? module.mps_subnet[0].name : data.google_compute_subnetwork.input-subnetwork[0].name
  network_tags = var.create_new_vpc ? module.mps_vpc_network[0].firewall.target_tags : var.network_tags

  # Compute instance type
  machine_type = var.machine_types

  # Number of MPS instances. Require only 1 for  build phase
  numworkernodes = 1

  # storage
  isoBucketName = var.ISO_Bucket_exists ? var.ISO_Object_URI : google_storage_bucket.iso[0].name
  scriptBucketName = google_storage_bucket.script.name
  runtimeBucketName = google_storage_bucket.runtime.name

  # product versioning
  Version = var.Version

  # Base OS - Linux dist and version
  imageProject = var.imageProject[var.bootDiskOS]
  imageFamily  = var.imageFamily[var.bootDiskOS]

  # license
  Agree_To_License = var.Agree_To_License
  FIK = var.FIK
  LicenseManagerHost = var.LicenseManagerHost
  LicenseManagerPort = var.LicenseManagerPort
}

# Create disks to be mounted
resource "google_compute_disk" "default" {
  depends_on = [google_storage_bucket.iso, google_storage_bucket.script, google_storage_bucket.runtime, null_resource.runtime_download , null_resource.checklicenseagreement , null_resource.checkISObucketExists ]
  name = "${var.tag}-image-disk"
  type  = "pd-ssd"
  size  = 50
}

# Attach disk to the VM `mps_worker_node`
resource "google_compute_attached_disk" "default" {
  depends_on = [google_storage_bucket.iso, google_storage_bucket.script, google_storage_bucket.runtime, null_resource.runtime_download , null_resource.checklicenseagreement , null_resource.checkISObucketExists  ]
  disk     = google_compute_disk.default.id
  instance = module.mps_worker_node.id[0]
}

# check if mps is ready to accept requests
resource "null_resource" "checkinstance"{
  depends_on = [google_storage_bucket.iso, google_storage_bucket.script, google_storage_bucket.runtime, null_resource.runtime_download , null_resource.checklicenseagreement , null_resource.checkISObucketExists  ]
  provisioner "local-exec" {
    command = "./local_scripts/test_mps_worker_health.sh ${module.mps_worker_node.head_node_public_ip[0]} && gcloud compute instances stop ${module.mps_worker_node.id[0]} && sleep 15"
  }
}

# create disk image with mps and runtime installation from attached disk
resource "google_compute_image" "mps" {
  depends_on = [ null_resource.checkinstance ]
  name = "${var.tag}-build-image"
  source_disk = google_compute_disk.default.id
}

# (c) 2021 MathWorks, Inc.
