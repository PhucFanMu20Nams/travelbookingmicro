# VPC for Cluster
data "aws_availability_zones" "azs" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.2"

  name = "${local.name}-vpc"
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k + 3)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb"                  = 1
    "kubernetes.io/cluster/${local.name}-eks" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"         = 1
    "kubernetes.io/cluster/${local.name}-eks" = "shared"
  }

}

# EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.3"

  depends_on = [ module.vpc ]

  cluster_name                   = "${local.name}-eks"
  cluster_version                = local.k8s_version
  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  create_cluster_security_group = false
  create_node_security_group    = false

  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  eks_managed_node_groups = {
    eks-node = {
      instance_types = ["t3.medium"]
      min_size       = 2
      max_size       = 4
      desired_size   = 2
    }
  }

  tags = local.tags
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.21"

  depends_on = [module.eks]

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_aws_load_balancer_controller = true
  enable_kube_prometheus_stack        = true

  aws_load_balancer_controller = {
    chart         = "aws-load-balancer-controller"
    chart_version = "1.13.4"
    repository    = "https://aws.github.io/eks-charts"
    namespace     = "kube-system"
    wait          = true
    wait_for_jobs = true
    values = [
      yamlencode({
        clusterName = module.eks.cluster_name
        region      = local.region
        vpcId       = module.vpc.vpc_id
        replicaCount = 2
      })
    ]
  }

  kube_prometheus_stack = {
    chart         = "kube-prometheus-stack"
    chart_version = "77.0.0"
    repository    = "https://prometheus-community.github.io/helm-charts"
    namespace     = "monitoring"
    wait          = true
    wait_for_jobs = true
    values = [
      yamlencode({
        grafana = {
          adminPassword = "admin"
          ingress = {
            enabled          = true
            ingressClassName = "alb"
            annotations = {
              "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
              "alb.ingress.kubernetes.io/target-type"     = "ip"
              "alb.ingress.kubernetes.io/certificate-arn" = "arn:aws:acm:eu-west-2:663264486938:certificate/64e45cde-e6b2-4f02-97cd-25a06a580031"
              "alb.ingress.kubernetes.io/listen-ports"    = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
              "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
              "alb.ingress.kubernetes.io/group.name"      = "online-boutique"
              "alb.ingress.kubernetes.io/healthcheck-path" = "/api/health"
              "alb.ingress.kubernetes.io/healthcheck-interval-seconds" = "15"
              "alb.ingress.kubernetes.io/healthcheck-timeout-seconds" = "5"
              "alb.ingress.kubernetes.io/healthy-threshold-count" = "2"
              "alb.ingress.kubernetes.io/unhealthy-threshold-count" = "2"
            }
            hosts = ["grafana.teachdev.online"]
            path  = "/"
          }
        }
        prometheus = {
          prometheusSpec = {
            serviceMonitorSelectorNilUsesHelmValues = false
            serviceMonitorSelector = {
              matchLabels = {
                "release" = "kube-prometheus-stack"
              }
            }
          }
        }
      })
    ]
  }

  tags = {
    "kubernetes.io/cluster/${local.name}-eks" = "shared"
  }
}