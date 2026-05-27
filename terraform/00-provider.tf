terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = local.region
}

locals {
  rm     = "566277"
  region = "us-east-1"
  name   = "fiap-eks-rm${local.rm}"
}
