# static public IP for all compute instances behind the load balancer
output "head_node_public_ip" {
  value = google_compute_instance.vm_instance_mpsnode[*].network_interface.0.access_config.0.nat_ip
}

# Selflink for all MPS compute instances
output "Selflink" {
  value = google_compute_instance.vm_instance_mpsnode[*].self_link
}

# Resource ID for all MPS compute instances
output "id" {
   value = google_compute_instance.vm_instance_mpsnode[*].id
}

# Resource Name for all MPS compute instances
output "name" {
   value = google_compute_instance.vm_instance_mpsnode[*].name
}

# (c) 2021 MathWorks, Inc.
