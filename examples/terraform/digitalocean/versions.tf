# TF setup

terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.28.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.3.1"
    }
  }
}

# Configure providers

provider "digitalocean" {}

provider "talos" {}
