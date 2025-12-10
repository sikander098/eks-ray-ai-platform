# EKS Module - Creates AWS EKS Cluster with managed node groups
# Uses the official terraform-aws-modules/eks/aws module

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # Network configuration
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Cluster endpoint access
  cluster_endpoint_public_access = true

  # CRITICAL: Enable OIDC Provider for IRSA (IAM Roles for Service Accounts)
  # This is required for Karpenter and other AWS integrations
  enable_irsa = true

  access_entries = var.access_entries

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    general = {
      name = "${var.cluster_name}-general"

      instance_types = var.instance_types
      capacity_type  = var.capacity_type

      min_size     = var.min_size
      max_size     = var.max_size
      desired_size = var.desired_size

      # Use the latest EKS optimized AMI
      ami_type = "AL2_x86_64"

      # Disk configuration
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 50
            volume_type           = "gp3"
            encrypted             = true
            delete_on_termination = true
          }
        }
      }

      # Labels for node selection
      labels = {
        Environment = var.cluster_name
        NodeGroup   = "general"
      }

      tags = {
        NodeGroup = "general"
      }
    }
  }

  # Cluster access entry
  # Allow the current caller identity to administer the cluster
  enable_cluster_creator_admin_permissions = true
  
  # Node security group tags for Karpenter discovery
  node_security_group_tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }

  tags = {
    Environment = var.cluster_name
    ManagedBy   = "Terraform"
  }
}

# Data source to get current caller identity
data "aws_caller_identity" "current" {}
