# Définir des variables locales du cluster EKS
locals {
  cluster_name = "${var.project_name}-eks-${random_string.suffix.result}"
}

# Générer une chaîne aléatoire pour le suffixe du nom de cluster
resource "random_string" "suffix" {
  length  = 8
  special = false
}

# Module EKS
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_name    = local.cluster_name
  cluster_version = "1.30"

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    aws-ebs-csi-driver = {
      service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_group_defaults = {
    ami_type = var.node_group_type
  }

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = [var.node_instance_type]

      min_size     = var.scaling_config.min_size
      max_size     = var.scaling_config.max_size
      desired_size = var.scaling_config.desired_size
    }

    two = {
      name = "node-group-2"

      instance_types = [var.node_instance_type]

      min_size     = var.scaling_config.min_size
      max_size     = var.scaling_config.max_size
      desired_size = var.scaling_config.desired_size
    }
  }
}
