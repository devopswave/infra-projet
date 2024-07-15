# Définition de la région AWS à utiliser pour le déploiement
variable "region" {
  description = "La région AWS où le cluster EKS sera déployé."
  type        = string
  default     = "eu-west-3"
}

# Préfixe pour nommer les ressources liées au projet
variable "project_name" {
  description = "Préfixe utilisé pour nommer les ressources du cluster EKS."
  type        = string
  default     = "adolfo"
}

# Bloc CIDR pour le VPC
variable "vpc_cidr" {
  description = "Bloc CIDR pour le VPC."
  type        = string
  default     = "10.0.0.0/16"
}

# Blocs CIDR pour les sous-réseaux publics
variable "cidrs_public" {
  description = "Liste des blocs CIDR pour les sous-réseaux publics."
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

# Blocs CIDR pour les sous-réseaux privés
variable "cidrs_private" {
  description = "Liste des blocs CIDR pour les sous-réseaux privés."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

# Type d'AMI pour les groupes de nœuds managés
variable "node_group_type" {
  description = "Type d'AMI pour les groupes de nœuds managés. Par exemple, 'AL2_x86_64'."
  type        = string
  default     = "AL2_x86_64"
}

# Type d'instance EC2 pour les nœuds
variable "node_instance_type" {
  description = "Type d'instance EC2 à utiliser pour les nœuds du cluster EKS."
  type        = string
  default     = "t2.micro"
}

# Configuration pour le dimensionnement des groupes de nœuds
variable "scaling_config" {
  description = "Configuration du dimensionnement des groupes de nœuds, comprenant la taille désirée, maximale, et minimale."
  type        = map(any)
  default = {
    "desired_size" = 2
    "max_size"     = 3
    "min_size"     = 1
  }
}