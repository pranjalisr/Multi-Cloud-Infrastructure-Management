output "aws_instance_ip" {
  value = aws_instance.web.public_ip
}

output "azure_vm_ip" {
  value = azurerm_public_ip.main.ip_address
}

output "gcp_instance_ip" {
  value = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}

output "monitoring_ip" {
  value = google_compute_instance.monitoring.network_interface[0].access_config[0].nat_ip
}

output "grafana_url" {
  value = "http://${google_compute_instance.monitoring.network_interface[0].access_config[0].nat_ip}:3000"
}

output "prometheus_url" {
  value = "http://${google_compute_instance.monitoring.network_interface[0].access_config[0].nat_ip}:9090"
}

