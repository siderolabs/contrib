terraform {
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "0.5.0"
    }
  }
}

provider "talos" {}
