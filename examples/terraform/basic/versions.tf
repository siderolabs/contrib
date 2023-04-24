terraform {
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "0.2.0"
    }
  }
}

provider "talos" {}
