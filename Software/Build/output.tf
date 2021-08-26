# Get disk image name for deployment of multi-node MPS
output "mps-disk-image" {
 value = google_compute_image.mps.name
}

# Get disk size for deployment of multi-node MPS
output "mps-disk-image-size" {
 value = google_compute_disk.default.size
}

# Get Resource ID for MPS disk image
output "mps-disk-image-id" {
  value = google_compute_image.mps.id
}

# Get boot disk OS
output "boot-disk-os" {
  value = var.bootDiskOS
}
# (c) 2021 MathWorks, Inc.
