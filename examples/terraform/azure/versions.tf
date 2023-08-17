terraform {
  required_version = "~> 1.3"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.3.0"
    }
  }
}

provider "azurerm" {
  features {}
}
