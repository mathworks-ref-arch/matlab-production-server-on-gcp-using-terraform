# public ip for mps instances created
output "head_node_public_ip" {
  value = google_compute_instance.vm_instance_mpsnode[*].network_interface.0.access_config.0.nat_ip
}
# reource self link for every mps instance
output "Selflink" {
  value = google_compute_instance.vm_instance_mpsnode[*].self_link
}

# resource id for every mps instance
output "id" {
   value = google_compute_instance.vm_instance_mpsnode[*].id
}

# (c) 2021 MathWorks, Inc.
