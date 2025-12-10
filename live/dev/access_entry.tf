
# Standalone Access Entry for Karpenter Nodes to break dependency cycle
resource "aws_eks_access_entry" "karpenter_node" {
  cluster_name  = module.eks.cluster_name
  principal_arn = module.karpenter.node_role_arn
  type          = "EC2_LINUX"
  
  depends_on = [module.eks, module.karpenter]
}
