### Provisionnement d'un Cluster EKS avec Terraform

---

#### Qu'est-ce qu'EKS ?

AWS EKS est un service managé qui facilite le déploiement, la gestion et la mise à l'échelle des applications conteneurisées en utilisant Kubernetes. EKS gère automatiquement la disponibilité et la scalabilité des serveurs de plan de contrôle Kubernetes responsables de l'exécution des clusters.

---

#### Pourquoi utiliser Terraform ?

Terraform est un outil d'infrastructure en tant que code (IaC) qui permet de définir et de provisionner des infrastructures complètes via des fichiers de configuration. Voici les avantages clés :

- **Workflow unifié** : Utilisation d'un même workflow pour déployer à la fois l'infrastructure AWS et les clusters EKS.
- **Gestion complète du cycle de vie** : Création, mise à jour et suppression des ressources suivies de manière automatisée.
- **Graphique des relations** : Gestion des dépendances entre les ressources, assurant l'ordre correct de provisionnement.

---

#### Prérequis

Vous aurez besoin de :

- Terraform v1.3+ installé localement.([Installation Terraform](https://docs.aws.amazon.com/fr_fr/cli/latest/userguide/getting-started-install.html))
- Un compte AWS et les CLI AWS v2.7.0/v1.24.0 configurées.([Configuration de l'environnement AWS](https://docs.aws.amazon.com/fr_fr/cli/latest/userguide/getting-started-configure.html))
- Kubectl v1.24.0 ou plus récent.([Installation Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/))
- Un compte GitHub.([Création d'un compte GitHub](https://docs.github.com/en/get-started/onboarding/getting-started-with-your-github-account))
- Helm v3.7.0 ou plus récent.([Installation Helm](https://helm.sh/docs/intro/install/))

---

#### Étapes de Provisioning

1. **Définition des Variables** :
   J'ai défini plusieurs variables pour personnaliser le déploiement du cluster EKS. Ces variables comprennent la région AWS, le nom du projet, les blocs CIDR pour le VPC et les sous-réseaux, le type d'instance pour les nœuds, et les configurations de dimensionnement des groupes de nœuds.

   ```hcl
   variable "region" {
     description = "La région AWS où le cluster EKS sera déployé."
     type        = string
     default     = "eu-west-3"
   }
   
   variable "project_name" {
     description = "Préfixe utilisé pour nommer les ressources du cluster EKS."
     type        = string
     default     = "adolfo"
   }
   
   variable "vpc_cidr" {
     description = "Bloc CIDR pour le VPC."
     type        = string
     default     = "10.0.0.0/16"
   }
   
   variable "cidrs_public" {
     description = "Liste des blocs CIDR pour les sous-réseaux publics."
     type        = list(string)
     default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
   }
   
   variable "cidrs_private" {
     description = "Liste des blocs CIDR pour les sous-réseaux privés."
     type        = list(string)
     default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
   }
   
   variable "node_group_type" {
     description = "Type d'AMI pour les groupes de nœuds managés. Par exemple, 'AL2_x86_64'."
     type        = string
     default     = "AL2_x86_64"
   }
   
   variable "node_instance_type" {
     description = "Type d'instance EC2 à utiliser pour les nœuds du cluster EKS."
     type        = string
     default     = "t2.micro"
   }
   
   variable "scaling_config" {
     description = "Configuration du dimensionnement des groupes de nœuds, comprenant la taille désirée, maximale, et minimale."
     type        = map
     default     = {
       "desired_size" = 2
       "max_size" = 3
       "min_size" = 1
     }
   }
   ```
2. **Configuration de Terraform** :
   J'ai configuré Terraform pour utiliser les fournisseurs nécessaires, notamment AWS, random, tls et cloudinit.

   ```hcl
   terraform {
     required_providers {
       aws = {
         source  = "hashicorp/aws"
         version = "~> 5.47.0"
       }
       random = {
         source  = "hashicorp/random"
         version = "~> 3.6.1"
       }
       tls = {
         source  = "hashicorp/tls"
         version = "~> 4.0.5"
       }
       cloudinit = {
         source  = "hashicorp/cloudinit"
         version = "~> 2.3.4"
       }
     }
     required_version = "~> 1.3"
   }
   
   provider "aws" {
     region = var.region
   }
   ```
3. **Provisionnement des Ressources** :
   J'ai utilisé des modules pour provisionner le VPC et le cluster EKS, en intégrant des configurations spécifiques telles que les sous-réseaux publics et privés, et en définissant les groupes de nœuds managés.

   ```hcl
   module "vpc" {
     source  = "terraform-aws-modules/vpc/aws"
     version = "5.8.1"
     name = "${var.project_name}-vpc"
     cidr = var.vpc_cidr
     azs  = slice(data.aws_availability_zones.available.names, 0, 3)
     private_subnets = var.cidrs_private
     public_subnets  = var.cidrs_public
     enable_nat_gateway   = true
     single_nat_gateway   = true
     enable_dns_hostnames = true
     public_subnet_tags = {
       "kubernetes.io/role/elb" = 1
     }
     private_subnet_tags = {
       "kubernetes.io/role/internal-elb" = 1
     }
   }
   
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
   ```
4. **Initialisation de Terraform** :

   ```sh
   $ terraform init
   ```
5. **Application du Plan Terraform** :

   ```sh
   $ terraform apply
   ```

   Confirmez l'opération avec 'yes'.

---

#### Configuration de kubectl

Après avoir provisionné le cluster, nous pouvons recuperer les informations nécessaires pour configurer kubectl.

```sh
terraform output -raw kubeconnect
```

---

#### Vérification du Cluster

Utilisez les commandes kubectl pour vérifier la configuration de votre cluster.

```sh
$ kubectl cluster-info
$ kubectl get nodes
```

---

#### Nettoyage des ressources

Pour éviter des frais supplémentaires, il est crucial de détruire les ressources une fois la démonstration terminée.

```sh
$ terraform destroy
```

Confirmez l'opération avec 'yes'.

---
