# Creates  MPS worker nodes and assigns network, disk and address

# Static public - ip for  MPS nodes
resource "google_compute_address" "mpsnode-static-ip-address" {
  count = var.numworkernodes
  name = "${var.tag}-static-ip-address-${count.index}"
}

# Creating instance for MATLAB Production Server
#   Number of instances                 - count
#   Instance Type                       - machine_type
#   Firewall rules applicable           - tags
#   Boot Disk image                     - image
#   Boot Disk Size                      - size
#   Access & Permissions                - scopes
#   Startup script                      - metadata_startup_script
#   VPC and Subnet                      - network_interface
#   Disk with MPS and Runtime image     - attached_disk

resource "google_compute_instance" "vm_instance_mpsnode" {
  count = var.numworkernodes
  name = "${var.tag}-mps-node-${count.index}"
  machine_type = var.machine_type
  tags = concat(var.network_tags,["mps","loadbalancer"])
  allow_stopping_for_update = true

  boot_disk {
      initialize_params {
        image = "${var.imageProject}/${var.imageFamily}"
        size = 70
      }
    }

metadata = {
    ssh-keys = "${var.username}:${file(var.gce_ssh_key_file_path)}"
}

service_account {
  scopes = ["compute-rw", "storage-full", "cloud-platform", "logging-write", "monitoring-write", "userinfo-email" , "service-management", "service-control"]
}

metadata_startup_script = "gsutil cp gs://${var.scriptBucketName}/startup.sh . && sudo chmod 777 startup.sh && ./startup.sh ${var.Version} ${var.LicenseManagerIP} ${var.LicenseManagerPort} ${var.scriptBucketName} ${var.autodeployBucketName} ${var.configBucketName} ${var.numworker}"


# Input Argument Reference
# ##############################################################################
# VERSION=$1 IP=$2 PORT=$3
# SCRIPT_BUCKET=$4 AUTODEPLOY_BUCKET=$5  CONFIG_BUCKET=$6
# NUM_WORKER=$7
###############################################################################

network_interface {
  subnetwork = var.subnetwork
  access_config {
    nat_ip = google_compute_address.mpsnode-static-ip-address[count.index].address
  }
}

lifecycle {
  ignore_changes = [attached_disk]
  }
}

# (c) 2021 MathWorks, Inc.
