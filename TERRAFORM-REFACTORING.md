# 🔧 Refactorisation Terraform - Propositions d'Amélioration

## 📋 État Actuel

Le code Terraform actuel est fonctionnel avec **149 ressources déployées**, mais peut être amélioré pour :
- Une meilleure maintenabilité
- Une réutilisabilité accrue
- Une organisation modulaire
- Une gestion simplifiée des environnements

---

## 🎯 Propositions de Refactorisation

### 1. Structure Modulaire

#### Structure Actuelle
```
terraform/
├── main.tf (233 lignes - VPC, EKS, IAM)
├── cloudwatch.tf (84 lignes)
├── observability.tf (286 lignes)
├── security.tf (217 lignes)
├── variables.tf (91 lignes)
├── outputs.tf (100 lignes)
└── providers.tf
```

#### Structure Proposée
```
terraform/
├── main.tf (orchestration)
├── variables.tf
├── outputs.tf
├── providers.tf
├── terraform.tfvars
└── modules/
    ├── networking/
    │   ├── main.tf (VPC, subnets, NAT)
    │   ├── variables.tf
    │   └── outputs.tf
    ├── eks-cluster/
    │   ├── main.tf (cluster + addons)
    │   ├── node-groups.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── iam/
    │   ├── main.tf (tous les rôles IRSA)
    │   ├── variables.tf
    │   └── outputs.tf
    ├── security/
    │   ├── main.tf (SG, KMS, WAF)
    │   ├── variables.tf
    │   └── outputs.tf
    ├── monitoring/
    │   ├── main.tf (CloudWatch, Prometheus)
    │   ├── variables.tf
    │   └── outputs.tf
    └── observability/
        ├── main.tf (Jaeger, Elasticsearch)
        ├── variables.tf
        └── outputs.tf
```

**Avantages:**
- Réutilisation des modules dans d'autres projets
- Tests unitaires par module
- Développement parallèle par équipe
- Versioning indépendant des modules

---

### 2. Gestion Multi-Environnements

#### Créer des Workspaces Terraform

```bash
# Structure proposée
terraform/
├── environments/
│   ├── dev/
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   ├── staging/
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   └── prod/
│       ├── terraform.tfvars
│       └── backend.tf
```

#### Fichier `environments/dev/terraform.tfvars`
```hcl
# Dev environment
environment       = "dev"
cluster_name      = "eks-bfs-dev"
cluster_version   = "1.29"
aws_region        = "eu-west-1"

# Economie pour dev
single_nat_gateway = true
enable_prometheus  = false
enable_jaeger      = false

# Node groups minimaux
node_groups = {
  general = {
    min_size     = 1
    max_size     = 3
    desired_size = 1
    instance_types = ["t3.small"]
  }
}
```

#### Fichier `environments/prod/terraform.tfvars`
```hcl
# Production environment
environment       = "prod"
cluster_name      = "eks-bfs-gp12"
cluster_version   = "1.29"
aws_region        = "eu-west-1"

# Haute disponibilité
single_nat_gateway = false  # 3 NAT gateways
enable_prometheus  = true
enable_jaeger      = true

# Node groups production
node_groups = {
  general = {
    min_size       = 2
    max_size       = 10
    desired_size   = 2
    instance_types = ["t3.medium"]
  }
  high_memory = {
    min_size       = 0
    max_size       = 5
    desired_size   = 0
    instance_types = ["t3.large"]
  }
  spot = {
    min_size       = 0
    max_size       = 5
    desired_size   = 0
    instance_types = ["t3.medium", "t3a.medium"]
    capacity_type  = "SPOT"
  }
}
```

---

### 3. Refactorisation des Node Groups

#### Code Actuel (main.tf)
```hcl
eks_managed_node_groups = {
  general = {
    min_size     = 2
    max_size     = 10
    desired_size = 2
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    labels = { workload = "general" }
  }
  high_memory = {
    min_size     = 0
    max_size     = 5
    desired_size = 0
    instance_types = ["t3.large"]
    capacity_type  = "ON_DEMAND"
    labels = { workload = "high-memory" }
    taints = [{ key = "high-memory", value = "true", effect = "NO_SCHEDULE" }]
  }
  # ...
}
```

#### Code Proposé (avec variable dynamique)
```hcl
# variables.tf
variable "node_groups" {
  description = "Configuration des node groups EKS"
  type = map(object({
    min_size       = number
    max_size       = number
    desired_size   = number
    instance_types = list(string)
    capacity_type  = optional(string, "ON_DEMAND")
    labels         = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
    tags = optional(map(string), {})
  }))
  default = {
    general = {
      min_size       = 2
      max_size       = 10
      desired_size   = 2
      instance_types = ["t3.medium"]
      labels         = { workload = "general" }
    }
  }
}

# main.tf
eks_managed_node_groups = {
  for name, config in var.node_groups : name => {
    min_size       = config.min_size
    max_size       = config.max_size
    desired_size   = config.desired_size
    instance_types = config.instance_types
    capacity_type  = config.capacity_type
    labels         = config.labels
    taints         = config.taints
    tags           = merge(local.tags, config.tags)
  }
}
```

**Avantages:**
- Configuration via fichier tfvars
- Ajout/suppression de node groups sans modifier le code
- Validation des types

---

### 4. Backend Terraform Remote (S3 + DynamoDB)

#### Code Actuel
État local (`terraform.tfstate` dans le dossier)

#### Code Proposé
```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "bfs-terraform-state-${var.aws_account_id}"
    key            = "${var.environment}/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "bfs-terraform-locks"
    
    # Tags
    tags = {
      Project     = "black-friday-survival"
      Environment = "${var.environment}"
      ManagedBy   = "Terraform"
    }
  }
}
```

**Avantages:**
- Collaboration en équipe (état partagé)
- Locking avec DynamoDB (évite les conflits)
- Versioning de l'état (S3)
- Backup automatique

**Script de création:**
```bash
# create-backend.sh
#!/bin/bash
BUCKET_NAME="bfs-terraform-state-622333992348"
REGION="eu-west-1"

# Créer le bucket S3
aws s3 mb "s3://${BUCKET_NAME}" --region "$REGION"

# Activer le versioning
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

# Créer la table DynamoDB pour le locking
aws dynamodb create-table \
  --table-name bfs-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION"
```

---

### 5. Optimisation des Coûts

#### Variables de Coût
```hcl
# variables.tf
variable "cost_optimization_enabled" {
  description = "Activer les optimisations de coût"
  type        = bool
  default     = true
}

variable "use_spot_instances" {
  description = "Utiliser des instances Spot"
  type        = bool
  default     = false
}

variable "enable_cluster_autoscaler_scale_to_zero" {
  description = "Permettre au cluster autoscaler de descendre à 0 node"
  type        = bool
  default     = false
}
```

#### Logic Conditionnelle
```hcl
# main.tf
single_nat_gateway = var.cost_optimization_enabled ? true : false

# Prometheus storage réduit en mode économie
storage_size = var.cost_optimization_enabled ? "10Gi" : "50Gi"

# Node group spot activé conditionnellement
eks_managed_node_groups = merge(
  local.default_node_groups,
  var.use_spot_instances ? local.spot_node_groups : {}
)
```

---

### 6. Validation et Conventions

#### Pre-commit Hooks
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.83.5
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_docs
      - id: terraform_tflint
      - id: terraform_tfsec
```

#### Naming Conventions
```hcl
# locals.tf
locals {
  # Convention de nommage centralisée
  name_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    CostCenter  = var.cost_center
    Owner       = var.owner_email
  }
  
  # Noms standardisés
  cluster_name = "${local.name_prefix}-eks"
  vpc_name     = "${local.name_prefix}-vpc"
  kms_alias    = "alias/${local.name_prefix}-eks"
}
```

---

### 7. Outputs Améliorés

#### Code Actuel
```hcl
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}
```

#### Code Proposé
```hcl
# outputs.tf
output "cluster_info" {
  description = "Informations complètes du cluster EKS"
  value = {
    name              = module.eks.cluster_name
    endpoint          = module.eks.cluster_endpoint
    version           = module.eks.cluster_version
    certificate       = module.eks.cluster_certificate_authority_data
    oidc_provider_arn = module.eks.oidc_provider_arn
  }
  sensitive = true
}

output "kubectl_config" {
  description = "Commande pour configurer kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "connection_commands" {
  description = "Commandes de connexion aux services"
  value = {
    grafana = "kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80"
    jaeger  = "kubectl port-forward -n observability svc/jaeger-query 16686:16686"
  }
}

# Générer un fichier de sortie JSON
resource "local_file" "cluster_info" {
  content = jsonencode({
    cluster_name   = module.eks.cluster_name
    cluster_region = var.aws_region
    vpc_id         = module.vpc.vpc_id
    endpoints = {
      grafana_command = "kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80"
      jaeger_command  = "kubectl port-forward -n observability svc/jaeger-query 16686:16686"
    }
  })
  filename = "${path.module}/cluster-info.json"
}
```

---

### 8. Data Sources pour Réutilisation

#### Cas d'Usage
Réutiliser un VPC existant ou un cluster EKS existant

```hcl
# data.tf
data "aws_eks_cluster" "existing" {
  count = var.use_existing_cluster ? 1 : 0
  name  = var.existing_cluster_name
}

data "aws_vpc" "existing" {
  count = var.use_existing_vpc ? 1 : 0
  id    = var.existing_vpc_id
}

# main.tf
locals {
  vpc_id = var.use_existing_vpc ? data.aws_vpc.existing[0].id : module.vpc.vpc_id
}
```

---

## 📊 Comparaison Avant/Après

| Aspect | Avant | Après |
|--------|-------|-------|
| **Fichiers** | 7 fichiers monolithiques | Structure modulaire (15+ fichiers) |
| **Réutilisabilité** | Faible | Modules réutilisables |
| **Multi-env** | Duplication de code | Workspaces + tfvars |
| **État** | Local (non partagé) | Remote S3 (partagé) |
| **Coûts** | Fixes | Optimisables par env |
| **Testing** | Manuel | Pre-commit hooks |
| **Documentation** | Commentaires | terraform-docs auto |
| **Maintenance** | Complexe | Simplifiée |

---

## 🚀 Plan de Migration

### Phase 1 : Backend Remote (1 jour)
```bash
1. Créer le bucket S3 et table DynamoDB
2. Configurer backend.tf
3. Migrer l'état : terraform init -migrate-state
4. Vérifier : terraform plan (doit être no changes)
```

### Phase 2 : Structure Modulaire (2-3 jours)
```bash
1. Créer le dossier modules/
2. Extraire networking dans modules/networking
3. Extraire eks-cluster dans modules/eks-cluster
4. Tester : terraform plan
5. Continuer avec les autres modules
```

### Phase 3 : Multi-Environnements (1 jour)
```bash
1. Créer environments/dev, staging, prod
2. Adapter les terraform.tfvars
3. Tester chaque environnement
```

### Phase 4 : Optimisations (1-2 jours)
```bash
1. Implémenter les variables de coût
2. Ajouter les data sources
3. Améliorer les outputs
4. Configurer pre-commit hooks
```

---

## 📝 Recommandations

### À Faire Immédiatement
- [ ] Migrer vers backend S3 (état partagé)
- [ ] Ajouter `.terraform/` et `*.tfstate` au `.gitignore`
- [ ] Créer un fichier `terraform.tfvars.example`
- [ ] Documenter les variables obligatoires

### À Faire à Moyen Terme
- [ ] Modulariser le code (networking, eks, security)
- [ ] Créer des environnements dev/staging/prod
- [ ] Mettre en place des pre-commit hooks
- [ ] Générer la documentation avec terraform-docs

### À Faire à Long Terme
- [ ] Créer un registry de modules privé
- [ ] Automatiser avec CI/CD (GitHub Actions / GitLab CI)
- [ ] Implémenter des tests (Terratest)
- [ ] Ajouter des policies OPA pour validation

---

## 🔗 Ressources

- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [AWS EKS Terraform Module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
- [Terragrunt](https://terragrunt.gruntwork.io/) - Pour gérer des configurations complexes
- [terraform-docs](https://terraform-docs.io/) - Génération automatique de documentation
- [tfsec](https://github.com/aquasecurity/tfsec) - Analyse de sécurité

---

**💡 Note**: Ces refactorisations sont des propositions. Elles peuvent être implémentées progressivement sans tout casser d'un coup. Commencez par le backend remote et la modularisation.

