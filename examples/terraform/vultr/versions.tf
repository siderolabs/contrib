# TF setup

terraform {
  required_providers {
    vultr = {
      source  = "vultr/vultr"
      version = "2.12.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.6.0-beta.0"
    }
  }
}

# Configure providers

provider "vultr" {}

provider "talos" {}
