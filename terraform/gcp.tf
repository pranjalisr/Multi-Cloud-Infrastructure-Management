# gcp.tf - Google's cloud, where your data floats on a fluffy, white Google-shaped cloud

resource "google_compute_network" "vpc_network" {
  name                    = "multi-cloud-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "multi-cloud-subnet"
  ip_cidr_range = "10.0.3.0/24"
  region        = var.gcp_region
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]
}

resource "google_compute_instance" "vm_instance" {
  name         = "multi-cloud-instance"
  machine_type = "f1-micro"
  zone         = "${var.gcp_region}-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.name
    subnetwork = google_compute_subnetwork.subnet.name

    access_config {
      // Ephemeral IP
    }
  }

  metadata_startup_script = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y apache2
              echo "Hello from GCP!" > /var/www/html/index.html
              systemctl start apache2
              EOF

  tags = ["web"]

  labels = {
    environment = "multi-cloud-demo"
    cloud       = "gcp"
  }
}

# GCP Load Balancer - Because every cloud needs a silver lining
resource "google_compute_global_forwarding_rule" "default" {
  name       = "multi-cloud-lb"
  target     = google_compute_target_http_proxy.default.id
  port_range = "80"
}

resource "google_compute_target_http_proxy" "default" {
  name        = "multi-cloud-proxy"
  url_map     = google_compute_url_map.default.id
}

resource "google_compute_url_map" "default" {
  name            = "multi-cloud-url-map"
  default_service = google_compute_backend_service.default.id
}

resource "google_compute_backend_service" "default" {
  name        = "multi-cloud-backend"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  health_checks = [google_compute_health_check.default.id]
}

resource "google_compute_health_check" "default" {
  name               = "multi-cloud-health-check"
  check_interval_sec = 1
  timeout_sec        = 1

  tcp_health_check {
    port = "80"
  }
}

# GCP Autoscaler - Scaling up (and down) like a boss
resource "google_compute_autoscaler" "default" {
  name   = "multi-cloud-autoscaler"
  zone   = "${var.gcp_region}-a"
  target = google_compute_instance_group_manager.default.id

  autoscaling_policy {
    max_replicas    = 5
    min_replicas    = 1
    cooldown_period = 60

    cpu_utilization {
      target = 0.5
    }
  }
}

resource "google_compute_instance_template" "default" {
  name         = "multi-cloud-template"
  machine_type = "f1-micro"

  disk {
    source_image = "debian-cloud/debian-9"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network    = google_compute_network.vpc_network.name
    subnetwork = google_compute_subnetwork.subnet.name

    access_config {
      // Ephemeral IP
    }
  }

  metadata_startup_script = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y apache2
              echo "Hello from GCP Autoscaled Instance!" > /var/www/html/index.html
              systemctl start apache2
              EOF

  tags = ["web"]

  labels = {
    environment = "multi-cloud-demo"
    cloud       = "gcp"
  }
}

resource "google_compute_instance_group_manager" "default" {
  name = "multi-cloud-igm"
  zone = "${var.gcp_region}-a"

  version {
    instance_template = google_compute_instance_template.default.id
    name              = "primary"
  }

  target_pools       = [google_compute_target_pool.default.id]
  base_instance_name = "multi-cloud"
}

resource "google_compute_target_pool" "default" {
  name = "multi-cloud-target-pool"

  health_checks = [
    google_compute_http_health_check.default.name,
  ]
}

resource "google_compute_http_health_check" "default" {
  name               = "multi-cloud-health-check"
  request_path       = "/"
  check_interval_sec = 1
  timeout_sec        = 1
}

