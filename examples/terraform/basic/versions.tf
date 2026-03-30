terraform {
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "0.11.0-beta.1"
    }
  }
}

provider "talos" {}
