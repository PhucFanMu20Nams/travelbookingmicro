terraform {
  backend "s3" {
    bucket         = "online-boutique-terraform-state"
    key            = "oidc-setup/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "online-boutique-terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}
