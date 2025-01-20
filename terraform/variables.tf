variable "aws_region" {
  description = "AWS region to deploy resources"
  default     = "us-west-2"
}

variable "gcp_project" {
  description = "GCP project ID"
}

variable "gcp_region" {
  description = "GCP region to deploy resources"
  default     = "us-central1"
}

variable "azure_location" {
  description = "Azure location to deploy resources"
  default     = "East US"
}

