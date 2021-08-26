# Module definition for Loadbalancer


## Creating instance group for compute (MPS) instances - type unmanaged
resource "google_compute_instance_group" "prod_server_group" {
  name      = "${var.tag}-prod-server-instance-group"
  zone      = "${var.zone}"
  instances = var.listOfmpsWorkernodesSelflink
  named_port {
    name = "mps"
    port = "${var.mps_port}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

## Health check on port mps is listening on e.g. 9910
resource "google_compute_http_health_check" "prod_instance_health" {
  name         = "${var.tag}-mpsprod-instance-health"
  request_path = "/api/health"
  port = "${var.mps_port}"
  timeout_sec = 15
  healthy_threshold = 2
  unhealthy_threshold = 4
  check_interval_sec = 15
}

## Create Backend service for Load Balancer - target backend is the pool of compute instances
resource "google_compute_backend_service" "mps_service" {
  depends_on = [google_compute_http_health_check.prod_instance_health]
  name      = "${var.tag}-mps-service"
  port_name = "mps"
  protocol  = "HTTP"
  session_affinity = "GENERATED_COOKIE"
  backend {
    group = google_compute_instance_group.prod_server_group.id
  }

  health_checks = [
    google_compute_http_health_check.prod_instance_health.id,
  ]
}

## Frontend forwarding rule for requests received at port 80 for http
resource "google_compute_global_forwarding_rule" "http" {
  name       = "${var.tag}-http-global-rule"
  target     = google_compute_target_http_proxy.default.id
  port_range = "80"
}

# http proxy for requests received at port 80
resource "google_compute_target_http_proxy" "default" {
  name        = "${var.tag}-http-target-proxy"
  description = "http proxy for backend servce"
  url_map     = google_compute_url_map.default.id
}

## Frontend forwarding rule for requests received at port 443 for https
resource "google_compute_global_forwarding_rule" "https" {
  depends_on=[ null_resource.check_ssl_certificates , google_compute_ssl_certificate.default ]
  count = var.enable_https ? 1 : 0
  name       = "${var.tag}-https-global-rule"
  target     = google_compute_target_https_proxy.default[0].id
  port_range = "443"
}

# Test if certificates exist within Software/certificate
resource "null_resource" "check_ssl_certificates"{
  count = var.enable_https ? 1 : 0
  provisioner "local-exec" {
    command = "./local_scripts/check_ssl_certificates.sh ${var.privatekey_path} ${var.certificate_path} 2>/dev/null"
  }
}

# Check if private key and cert provided for ssl certificate is valid and available
resource "google_compute_ssl_certificate" "default" {
  depends_on=[ null_resource.check_ssl_certificates ]
  count = var.enable_https ? 1 : 0
  name        = "${var.tag}-ssl-certificates"
  private_key = file(var.privatekey_path)
  certificate = file(var.certificate_path)
}

# https proxy for requests received at port 443 
resource "google_compute_target_https_proxy" "default" {
  depends_on=[ null_resource.check_ssl_certificates , google_compute_ssl_certificate.default ]
  count = var.enable_https ? 1 : 0
  name        = "${var.tag}-https-target-proxy"
  description = "https proxy for backend servce"
  url_map     = google_compute_url_map.default.id
  ssl_certificates = [google_compute_ssl_certificate.default[0].id]
}

# URL map for reverse proxy for backend service
resource "google_compute_url_map" "default" {
  name            = "${var.tag}-url-map-target-proxy"
  description     = "url map"
  default_service = google_compute_backend_service.mps_service.id
}

# (c) 2021 MathWorks, Inc.
