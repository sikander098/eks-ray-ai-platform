# Dev Environment - Terraform Configuration
# Deploys VPC and EKS cluster for the development environment

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # S3 backend for remote state storage
  backend "s3" {
    bucket = "sikander-astronomy-tf-state"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
    # Uncomment these for production use:
    # encrypt        = true
    # dynamodb_table = "terraform-state-lock"
  }
}

# AWS Provider Configuration
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = "dev"
      Project     = "astronomy"
      ManagedBy   = "Terraform"
    }
  }
}

# Helm Provider Configuration
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.cluster_name
      ]
    }
  }
}

# Kubernetes Provider Configuration
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name
    ]
  }
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr         = "10.0.0.0/16"
  environment_name = "dev"
  cluster_name     = "astronomy-dev"
  az_count         = 2
}

# EKS Module
module "eks" {
  source = "../../modules/eks"

  cluster_name    = "astronomy-dev"
  cluster_version = "1.28"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  instance_types = ["t3.medium", "t3a.medium"]
  capacity_type  = "ON_DEMAND"  # Using ON_DEMAND for stability

  min_size     = 2
  max_size     = 3
  desired_size = 2
}

# Crossplane Module
module "crossplane" {
  source = "../../modules/crossplane"

  cluster_name              = module.eks.cluster_name
  cluster_oidc_provider_arn = module.eks.oidc_provider_arn
  cluster_oidc_provider_url = module.eks.cluster_oidc_issuer_url
  namespace                 = "crossplane-system"

  depends_on = [module.eks]
}

output "crossplane_role_arn" {
  description = "ARN of the IAM role for Crossplane AWS provider"
  value       = module.crossplane.crossplane_role_arn
}

output "crossplane_role_name" {
  description = "Name of the IAM role for Crossplane AWS provider"
  value       = module.crossplane.crossplane_role_name
}

# Velero Module
module "velero" {
  source = "../../modules/velero"

  cluster_name              = module.eks.cluster_name
  cluster_oidc_provider_arn = module.eks.oidc_provider_arn
  
  tags = {
    Environment = "dev"
    Project     = "astronomy"
    ManagedBy   = "Terraform"
  }
}

output "velero_s3_bucket_name" {
  description = "Name of the S3 bucket for Velero backups"
  value       = module.velero.s3_bucket_name
}

output "velero_iam_role_arn" {
  description = "ARN of the IAM role for Velero"
  value       = module.velero.iam_role_arn
}

# Karpenter Module
module "karpenter" {
  source = "../../modules/karpenter"
  
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.cluster_oidc_issuer_url
  cluster_endpoint  = module.eks.cluster_endpoint
  
  tags = {
    Environment = "dev"
    Project     = "astronomy"
    ManagedBy   = "Terraform"
  }
  
  depends_on = [module.eks]
}

# Karpenter Outputs
output "karpenter_controller_role_arn" {
  description = "ARN of the Karpenter controller IAM role"
  value       = module.karpenter.controller_role_arn
}

output "karpenter_node_instance_profile" {
  description = "Name of the Karpenter node instance profile"
  value       = module.karpenter.node_instance_profile_name
}

output "karpenter_node_role_name" {
  description = "Name of the Karpenter node IAM role"
  value       = module.karpenter.node_role_name
}

# Observability Stack (LGTM: Loki, Grafana, Tempo, Mimir/Prometheus)
module "observability" {
  source = "../../modules/observability"
  
  cluster_name                 = module.eks.cluster_name
  enable_grafana_loadbalancer  = true
  prometheus_retention         = "15d"
  prometheus_storage_size      = "50Gi"
  loki_storage_size            = "30Gi"
  oidc_provider_arn            = module.eks.oidc_provider_arn
  
  tags = {
    Environment = "dev"
    Project     = "astronomy"
    ManagedBy   = "Terraform"
  }
}

# Observability Outputs
output "grafana_admin_password" {
  description = "Grafana admin password (sensitive)"
  value       = module.observability.grafana_admin_password
  sensitive   = true
}

output "grafana_url_command" {
  description = "Command to get Grafana URL"
  value       = module.observability.grafana_url_command
}

output "prometheus_endpoint" {
  description = "Prometheus endpoint"
  value       = module.observability.prometheus_endpoint
}

output "loki_endpoint" {
  description = "Loki endpoint"
  value       = module.observability.loki_endpoint
}

output "tempo_otlp_grpc_endpoint" {
  description = "Tempo OTLP gRPC endpoint for traces"
  value       = module.observability.tempo_otlp_grpc_endpoint
}

output "tempo_otlp_http_endpoint" {
  description = "Tempo OTLP HTTP endpoint for traces"
  value       = module.observability.tempo_otlp_http_endpoint
}

