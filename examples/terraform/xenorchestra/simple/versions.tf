terraform {
  required_providers {
    xenorchestra = {
      source = "vatesfr/xenorchestra"
    }
  }
}

# Configure the Xen Orchestra Provider
provider "xenorchestra" {
  token = var.xoa_token
  url   = "ws://${var.xoa_url}"
}
