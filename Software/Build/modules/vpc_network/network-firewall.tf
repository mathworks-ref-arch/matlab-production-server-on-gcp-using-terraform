# allow http traffic
resource "google_compute_firewall" "allow-mps" {
  name = "${var.tag}-fw-allow-http"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports    = [var.mps_port,"22"]
  }
  target_tags = ["mps"]
  source_ranges = var.allowclientip
}


# (c) 2021 MathWorks, Inc.
