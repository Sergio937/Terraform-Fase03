module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.24.0"

  cluster_name    = "${var.project_name}-${var.environment}"
  cluster_version = var.eks_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa = var.enable_irsa

  eks_managed_node_groups = {
    default = {
      name           = "${var.project_name}-${var.environment}-ng"
      instance_types = var.eks_node_instance_types
      desired_size   = var.eks_node_desired_size
      min_size       = var.eks_node_min_size
      max_size       = var.eks_node_max_size
    }
  }

  tags = local.common_tags
}
