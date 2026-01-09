terraform {
  required_providers {
    xenorchestra = {
      source = "vatesfr/xenorchestra"
    }

    talos = {
      source  = "siderolabs/talos"
      version = "0.9.0"
    }
  }
}

# Configure the Xen Orchestra Provider
provider "xenorchestra" {
  token = var.xoa_token
  url   = "ws://${var.xoa_url}"
}

provider "talos" {}