# Endpoint for http REST endpoint
output "mps-http-endpoint" {
 value = "http://${module.load_balancer.http-mps-endpoint}/api/health" 
}

# Endpoint for http REST endpoint
output "mps-https-endpoint" {
 value =  var.enable_https ? "https://${module.load_balancer.https-mps-endpoint}/api/health" : null
}

# MPS Worker nodes
output "mps-worker-nodes" {
  value = module.mps_worker_node.name
}

# GCS bucket for user to upload ctfs (compiled MATLAB artifacts)
output "mps-autodeploy-bucket"{
 value = google_storage_bucket.autodeploy.name
}

# GCS bucket for user to access MPS config
output "mps-config-bucket" {
 value = google_storage_bucket.config.name
}

# Script Bucket to be deleted
output "mps-script-bucket" {
  value = google_storage_bucket.script.name
}

# (c) 2021 MathWorks, Inc.
