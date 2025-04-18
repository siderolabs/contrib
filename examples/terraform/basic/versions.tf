terraform {
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "0.8.0-alpha.0"
    }
  }
}

provider "talos" {}
