output "cluster_name" {
  description = "Le nom du cluster EKS créé."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "L'URL de l'endpoint du cluster EKS."
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "L'ID du groupe de sécurité du cluster EKS."
  value       = module.eks.cluster_security_group_id
}

output "cluster_iam_role_name" {
  description = "Le nom du rôle IAM du cluster EKS."
  value       = module.eks.cluster_iam_role_name
}

output "cluster_certificate_authority_data" {
  description = "Les données de l'autorité de certification du cluster EKS."
  value       = module.eks.cluster_certificate_authority_data
}

output "vpc_id" {
  description = "L'ID du VPC dans lequel le cluster EKS est déployé."
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "Les ID des sous-réseaux publics du VPC."
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "Les ID des sous-réseaux privés du VPC."
  value       = module.vpc.private_subnets
}

output "kubeconnect" {
  description = "Commande pour se connecter au cluster EKS."
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}
