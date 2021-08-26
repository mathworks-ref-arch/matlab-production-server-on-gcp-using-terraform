# HTTP MPS endpoint
output "http-mps-endpoint" {
  value = google_compute_global_forwarding_rule.http.ip_address
}

# HTTPS MPS endpoint
output "https-mps-endpoint" {
  value =  var.enable_https ? google_compute_global_forwarding_rule.https[0].ip_address : null
}

# (c) 2021 MathWorks, Inc.
