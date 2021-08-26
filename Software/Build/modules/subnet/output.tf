# Name of the subnet created or existing subnet to be used
output "name" {
  description = "SubNetwork name"
  value = google_compute_subnetwork.network-with-private-secondary-ip-ranges.name
}
# (c) 2021 MathWorks, Inc.
