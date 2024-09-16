# TF setup

terraform {
  required_providers {
    equinix = {
      source  = "equinix/equinix"
      version = "1.33.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.6.0-beta.0"
    }
  }
}

# Configure providers

provider "equinix" {
  auth_token = var.em_api_token
}

provider "talos" {}
