terraform {
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "0.1.0"
    }
  }
}

provider "talos" {}
