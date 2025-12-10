# VPC Module - Creates AWS VPC with public and private subnets
# Uses the official terraform-aws-modules/vpc/aws module

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.environment_name}-vpc"
  cidr = var.vpc_cidr

  # Calculate availability zones based on az_count
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # Private subnets for EKS nodes
  private_subnets = [
    for i in range(var.az_count) :
    cidrsubnet(var.vpc_cidr, 4, i)
  ]

  # Public subnets for load balancers
  public_subnets = [
    for i in range(var.az_count) :
    cidrsubnet(var.vpc_cidr, 4, i + var.az_count)
  ]

  # NAT Gateway configuration (single NAT for cost savings)
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags required for AWS Load Balancer Controller discovery
  # These tags allow the controller to automatically discover subnets
  public_subnet_tags = {
    "kubernetes.io/role/elb"            = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "karpenter.sh/discovery"                    = var.cluster_name
  }

  tags = {
    Environment = var.environment_name
    ManagedBy   = "Terraform"
  }
}

# Data source to get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}
