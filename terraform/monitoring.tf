# monitoring.tf - Because what you can't measure, you can't improve (or blame on the other team)

resource "google_compute_instance" "monitoring" {
  name         = "multi-cloud-monitoring"
  machine_type = "n1-standard-1"
  zone         = "${var.gcp_region}-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    subnetwork = google_compute_subnetwork.subnet.name

    access_config {
      // Ephemeral IP
    }
  }

  metadata_startup_script = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y docker.io
              systemctl start docker
              systemctl enable docker

              # Pull and run Prometheus
              docker run -d --name prometheus -p 9090:9090 prom/prometheus

              # Pull and run Grafana
              docker run -d --name grafana -p 3000:3000 grafana/grafana
              EOF

  tags = ["monitoring"]

  labels = {
    environment = "multi-cloud-demo"
    component   = "monitoring"
  }
}

# Firewall rule to allow Prometheus and Grafana access
resource "google_compute_firewall" "allow_monitoring" {
  name    = "allow-monitoring"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["9090", "3000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["monitoring"]
}

