terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.38.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.11.0-beta.1"
    }
  }
}

provider "aws" {
  default_tags {
    tags = {
      Project     = "Talos Kubernetes Cluster"
      Provisioner = "Terraform"
      Environment = "Testing"
    }
  }
}
