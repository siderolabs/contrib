terraform {
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "0.10.0-beta.0"
    }
  }
}

provider "talos" {}
