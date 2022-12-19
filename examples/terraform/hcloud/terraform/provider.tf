
terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "1.35.2"
    }
    talos = {
      source = "siderolabs/talos"
      # 0.1.0-beta.0 = Talos sdk: v1.3.0
      version = "0.1.0-beta.0"
    }
  }
}
