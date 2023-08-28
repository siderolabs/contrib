# TF setup

terraform {
  required_providers {
    vultr = {
      source  = "vultr/vultr"
      version = "2.12.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.3.2"
    }
  }
}

# Configure providers

provider "vultr" {}

provider "talos" {}
