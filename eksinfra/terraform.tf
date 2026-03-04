terraform {
  backend "s3" {
    bucket         = "online-boutique-terraform-state"
    key            = "eksinfra/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "online-boutique-terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.95.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.3"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }
  }
}

provider "aws" {
  region = local.region
}
