terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.28.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.10.0-beta.0"
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
