# TF setup

terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.28.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.8.0-alpha.0"
    }
  }
}

# Configure providers

provider "digitalocean" {}

provider "talos" {}
