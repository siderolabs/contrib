terraform {
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "0.3.2"
    }
  }
}

provider "talos" {}
