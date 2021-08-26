# allow http traffic
resource "google_compute_firewall" "allow-http-ssh" {
  name = "${var.tag}-fw-allow-http"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports    = var.enable_https ? [var.mps_port,"443","22"] : [var.mps_port,"22"]
  }
  target_tags = ["mps"]
  source_ranges = var.allowclientip
}

# Add firewall rule to whitelist Google Frontend IP Sources
resource "google_compute_firewall" "allow-healthcheck" {
  name = "${var.tag}-fw-allow-lb"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports    = [ var.mps_port ]
  }
  target_tags = ["loadbalancer"]
  source_ranges = [ "130.211.0.0/22", "35.191.0.0/16"]
}

# (c) 2021 MathWorks, Inc.
