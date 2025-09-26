data "aws_availability_zones" "available" {}

locals {
  name        = "online-boutique"
  region      = "eu-west-2"
  k8s_version = "1.33"

  vpc_cidr = "172.17.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    online-boutique = local.name
    GithubRepo      = "online-boutique-tf-eks-rep"
    GithubOrg       = "terraform-aws-modules"
  }
}