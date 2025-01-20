# main.tf - The conductor of our multi-cloud orchestra

terraform {
  required_version = ">= 0.14.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 3.0"
    }
  }
}

# AWS - Because who doesn't love a good rainforest?
provider "aws" {
  region = var.aws_region
}

# Azure - Microsoft's cloud, now with 100% more Linux!
provider "azurerm" {
  features {}
}

# Google Cloud - Where your data floats on a fluffy, white Google-shaped cloud
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Let the cloud games begin!
module "aws_infrastructure" {
  source = "./aws"
  # ... other variables
}

module "azure_infrastructure" {
  source = "./azure"
  # ... other variables
}

module "gcp_infrastructure" {
  source = "./gcp"
  # ... other variables
}

module "monitoring" {
  source = "./monitoring"
  # ... other variables
}

