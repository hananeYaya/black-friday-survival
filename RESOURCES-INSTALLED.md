# 📦 Ressources Installées - Black Friday Survival

> ✅ **Statut**: Système opérationnel | Dernière mise à jour: 3 avril 2026  
> 🌍 **Région**: eu-west-1  
> 🔗 **URL**: http://a1d60cd154e58498aa759b79dcd0b6d3-1630945732.eu-west-1.elb.amazonaws.com

## 🎯 Vue d'ensemble

**Total: 149 ressources Terraform déployées**

- **Région AWS**: `eu-west-1`
- **Cluster EKS**: `eks-bfs-gp12`
- **VPC CIDR**: `10.0.0.0/16`
- **Kubernetes Version**: `1.29`

---

## 🌐 Réseau (VPC)

### VPC et Subnets
- **VPC** : `eks-bfs-gp12-vpc` (10.0.0.0/16)
- **Subnets Publics** : 3 (1 par AZ)
  - `10.0.1.0/24` (eu-west-1a)
  - `10.0.2.0/24` (eu-west-1b)
  - `10.0.3.0/24` (eu-west-1c)
- **Subnets Privés** : 3 (1 par AZ)
  - `10.0.101.0/24` (eu-west-1a)
  - `10.0.102.0/24` (eu-west-1b)
  - `10.0.103.0/24` (eu-west-1c)

### Passerelles
- **Internet Gateway** : 1 instance
- **NAT Gateway** : 1 instance (mode économie, partagé entre les AZ)
- **Route Tables** : 
  - 1 table publique
  - 1 table privée

### Elastic IPs
- **EIP NAT Gateway** : 1 adresse IP élastique

---

## ☸️ Cluster EKS

### Cluster Principal
- **Nom** : `eks-bfs-gp12`
- **Version Kubernetes** : `1.29`
- **Endpoint** : HTTPS (public + private)
- **Log Types Activés** :
  - `api`
  - `audit`
  - `authenticator`
  - `controllerManager`
  - `scheduler`

### Addons EKS
| Addon | Version | Description |
|-------|---------|-------------|
| `coredns` | Latest | DNS interne du cluster |
| `kube-proxy` | Latest | Gestion réseau des pods |
| `vpc-cni` | Latest | Network plugin AWS |
| `aws-ebs-csi-driver` | Latest | Storage persistant (EBS) |

### Node Groups

#### 1. Node Group `general` (Production)
- **Instances** : `t3.medium`
- **Capacité** : 
  - Min: 2 nodes
  - Max: 10 nodes
  - Desired: 2 nodes
- **Type** : ON_DEMAND
- **Labels** : `workload=general`
- **Usage** : Workloads standards (frontend, cartservice, etc.)

#### 2. Node Group `high_memory` (Spécialisé)
- **Instances** : `t3.large`
- **Capacité** : 
  - Min: 0 nodes
  - Max: 5 nodes
  - Desired: 0 nodes
- **Type** : ON_DEMAND
- **Labels** : `workload=high-memory`
- **Taints** : `high-memory=true:NoSchedule`
- **Usage** : Workloads gourmands en mémoire (Redis, cache)

#### 3. Node Group `spot` (Économie)
- **Instances** : `t3.medium`, `t3a.medium`
- **Capacité** : 
  - Min: 0 nodes
  - Max: 5 nodes
  - Desired: 0 nodes
- **Type** : SPOT (jusqu'à 70% d'économie)
- **Labels** : `workload=spot`
- **Usage** : Charges de travail tolérantes aux interruptions

---

## 🔐 Sécurité

### KMS (Chiffrement)
- **KMS Key** : `eks-bfs-gp12-kms`
- **Alias** : `alias/eks-bfs-gp12`
- **Usage** : Chiffrement des secrets Kubernetes

### Security Groups

#### 1. Security Group EKS Principal
- **Nom** : `eks-bfs-gp12-cluster`
- **Description** : Security group pour le control plane EKS
- **Règles** : Gérées automatiquement par le module EKS

#### 2. Security Group EKS Additionnel
- **Nom** : `eks-bfs-gp12-additional`
- **Ingress** :
  - Port 443 (HTTPS) depuis CIDR autorisés
  - Port 80 (HTTP) depuis CIDR autorisés
- **Egress** : Tout le trafic sortant autorisé

#### 3. Security Group ALB
- **Nom** : `eks-bfs-gp12-alb`
- **Ingress** :
  - Port 80 (HTTP) depuis Internet (0.0.0.0/0)
  - Port 443 (HTTPS) depuis Internet (0.0.0.0/0)
- **Egress** : Tout le trafic sortant autorisé

### WAF (Web Application Firewall)
- **Web ACL** : `eks-bfs-gp12-waf`
- **Règles** :
  - **Rate Limiting** : 2000 requêtes / 5 minutes / IP
  - **Action** : Block si dépassement
- **Scope** : REGIONAL (attaché à l'ALB)

---

## 👤 IAM (Identity and Access Management)

### Rôles IRSA (IAM Roles for Service Accounts)

#### 1. AWS Load Balancer Controller
- **Role** : `eks-bfs-gp12-aws-load-balancer-controller`
- **Policy** : Gestion des ALB/NLB
- **Permissions** :
  - Création/suppression de Load Balancers
  - Gestion des Target Groups
  - Modification des Security Groups

#### 2. Cluster Autoscaler
- **Role** : `eks-bfs-gp12-cluster-autoscaler`
- **Policy** : Scaling automatique des nodes
- **Permissions** :
  - Describe/Update Auto Scaling Groups
  - Describe/Terminate instances EC2

#### 3. EBS CSI Driver
- **Role** : `eks-bfs-gp12-ebs-csi`
- **Policy** : Gestion des volumes EBS
- **Permissions** :
  - Création/suppression de volumes EBS
  - Attachment/Detachment de volumes
  - Gestion des snapshots

#### 4. Pod Security Policy
- **Policy** : `eks-bfs-gp12-restricted-pod-policy`
- **Description** : Restreint les privilèges des pods

---

## 📊 Monitoring et Observabilité

### CloudWatch

#### Log Groups
- **Cluster Logs** : `/aws/eks/eks-bfs-gp12/cluster`
  - Retention : 7 jours
  - Taille : Variable
- **WAF Logs** : `/aws/wafv2/eks-bfs-gp12`
  - Retention : 7 jours

#### Dashboard
- **Nom** : `eks-bfs-gp12-monitoring`
- **Métriques** :
  - Failed Nodes Count
  - CPU Utilization
  - Memory Utilization
  - Recent Logs

#### Alarmes CloudWatch

| Alarme | Métrique | Seuil | Action |
|--------|----------|-------|--------|
| `eks-bfs-gp12-high-cpu` | node_cpu_utilization | > 80% | SNS Topic |
| `eks-bfs-gp12-high-memory` | node_memory_utilization | > 80% | SNS Topic |

#### SNS Topic
- **Nom** : `eks-bfs-gp12-alerts`
- **Endpoint** : Email (si configuré dans `alert_email`)

### Prometheus + Grafana

#### Deployment
- **Namespace** : `monitoring`
- **Chart** : `kube-prometheus-stack` (v56.0+)
- **Service Account** : Avec IRSA

#### Prometheus
- **Retention** : 7 jours
- **Storage** : 20Gi (PVC avec StorageClass gp3)
- **Ressources** :
  - CPU Request: 500m, Limit: 1 core
  - Memory Request: 2Gi, Limit: 4Gi

#### Grafana
- **Service Type** : ClusterIP (accès via port-forward)
- **Admin Username** : `admin`
- **Admin Password** : `BlackFriday2024!` (récupéré via script ou secret K8s)
- **Storage** : 10Gi (PVC avec StorageClass gp3)
- **Accès** : `sh access-grafana.sh` ou `http://localhost:3000` (après port-forward)
- **Dashboards Personnalisés** (4 dashboards) :
  - **Black Friday - Vue d'Ensemble** : Vision globale instantanée (CPU, Memory, Pods)
  - **Black Friday - Microservices** : Monitoring par service (Frontend, Backend, Redis)
  - **Black Friday - Infrastructure** : Nodes, HPA, Capacity planning
  - **Black Friday - Performance & SLOs** : SLOs, Latency, Throughput, Error rates
- **Folder** : Black Friday Survival

#### Alertmanager
- **Activé** : Oui
- **Integration** : SNS pour les alertes critiques

### Jaeger (Distributed Tracing)

#### Deployment
- **Namespace** : `observability`
- **Chart** : `jaeger` (v3.0+)

#### Components

##### Jaeger Collector
- **Service Type** : ClusterIP
- **Ports** :
  - OTLP gRPC: 4317
  - OTLP HTTP: 4318
- **Ressources** :
  - CPU: 200m-500m
  - Memory: 512Mi-1Gi

##### Jaeger Query (UI)
- **Service Type** : LoadBalancer (NLB)
- **Port** : 16686
- **Ressources** :
  - CPU: 100m-500m
  - Memory: 256Mi-1Gi

##### Jaeger Agent
- **Deployment** : DaemonSet sur chaque node
- **Fonction** : Collecte des traces depuis les pods

#### Elasticsearch (Backend Jaeger)
- **Namespace** : `observability`
- **Chart** : `elasticsearch` (v8.5+)
- **Replicas** : 1 (mode économie)
- **Storage** : 30Gi (PVC avec StorageClass gp3)
- **Ressources** :
  - CPU: 500m-1 core
  - Memory: 2Gi-4Gi

---

## 🚀 Controllers Kubernetes

### 1. AWS Load Balancer Controller
- **Namespace** : `kube-system`
- **Version** : Latest
- **Function** : 
  - Crée automatiquement des ALB pour les Ingress
  - Crée des NLB pour les Services de type LoadBalancer
  - Gère les Target Groups

### 2. Cluster Autoscaler
- **Namespace** : `kube-system`
- **Version** : Compatible avec K8s 1.29
- **Function** : 
  - Scale automatiquement les node groups selon la demande
  - Descale les nodes inutilisés
- **Configuration** :
  - Scale Down Delay : 10 minutes
  - Scale Up Threshold : Pod en Pending > 30 secondes

### 3. Metrics Server
- **Namespace** : `kube-system`
- **Version** : Latest
- **Function** :
  - Collecte les métriques CPU/Memory des pods et nodes
  - Requis pour HPA (Horizontal Pod Autoscaler)
  - Requis pour `kubectl top`

---

## 🛍️ Application (Online Boutique)

### Namespace
- **Nom** : `online-boutique`

### Microservices (11 au total)

| Service | Langage | Port | Fonction |
|---------|---------|------|----------|
| `frontend` | Go | 8080 | Interface utilisateur |
| `cartservice` | C# | 7070 | Panier d'achat |
| `productcatalogservice` | Go | 3550 | Catalogue produits |
| `currencyservice` | Node.js | 7000 | Conversion devise |
| `paymentservice` | Node.js | 50051 | Paiement |
| `shippingservice` | Go | 50051 | Livraison |
| `emailservice` | Python | 8080 | Emails |
| `checkoutservice` | Go | 5050 | Commande |
| `recommendationservice` | Python | 8080 | Recommandations |
| `adservice` | Java | 9555 | Publicités |
| `redis-cart` | Redis | 6379 | Cache panier |

### Services Kubernetes

#### Frontend (Point d'entrée)
- **Service** : `frontend-external`
- **Type** : ClusterIP → LoadBalancer (après patch)
- **Port** : 80 → 8080
- **Annotations ALB** :
  - Load Balancer Type: ALB
  - Scheme: internet-facing
  - WAF integration

### HPA (Horizontal Pod Autoscalers)

| Service | Min Pods | Max Pods | CPU Target | Memory Target |
|---------|----------|----------|------------|---------------|
| `frontend` | 1 | 10 | 70% | - |
| `cartservice` | 1 | 5 | 70% | - |
| `productcatalogservice` | 1 | 5 | 70% | - |
| `currencyservice` | 1 | 3 | 70% | - |
| `paymentservice` | 1 | 5 | 70% | - |
| `shippingservice` | 1 | 3 | 70% | - |
| `emailservice` | 1 | 3 | 70% | - |
| `checkoutservice` | 1 | 5 | 70% | - |
| `recommendationservice` | 1 | 3 | 70% | - |
| `adservice` | 1 | 3 | 70% | - |

### Network Policies
- **Isolation** : Par défaut, deny all
- **Règles** : Allow uniquement entre services nécessaires
- **Egress DNS** : Autorisé pour tous les pods

### Resource Quotas (Namespace)
- **Pods** : Max 50
- **Services** : Max 20
- **CPU Requests** : Max 20 cores
- **Memory Requests** : Max 40Gi

---

## 💰 Estimation des Coûts

### Coûts Mensuels (Région eu-west-1)

| Ressource | Quantité | Coût Unitaire | Coût Mensuel |
|-----------|----------|---------------|--------------|
| **EKS Cluster** | 1 | $73/mois | **$73** |
| **EC2 Instances (t3.medium)** | 2-10 nodes | ~$30/node/mois | **$60-300** |
| **NAT Gateway** | 1 | $32/mois + data | **$40-80** |
| **EBS Volumes (gp3)** | ~100Gi | $0.08/Gi/mois | **$8** |
| **Load Balancers (ALB+NLB)** | 2-3 | ~$22/mois/LB | **$44-66** |
| **CloudWatch Logs** | ~50GB/mois | $0.50/GB | **$25** |
| **Elasticsearch** | 1 instance | Inclus dans nodes | **$0** |
| **WAF** | 1 Web ACL | $5 + rules | **$10** |
| | | **TOTAL** | **$260-592/mois** |

### Mode Économie (Dev)
- Node groups minimaux (1 t3.small)
- Pas de Prometheus/Jaeger
- 1 NAT Gateway partagé
- **Coût estimé** : **$120-180/mois**

---

## 🔍 Commandes de Vérification

### Lister toutes les ressources Terraform
```bash
cd terraform
terraform state list | wc -l  # Devrait afficher 149
```

### Vérifier le cluster EKS
```bash
aws eks describe-cluster --name eks-bfs-gp12 --region eu-west-1
```

### Vérifier les nodes
```bash
kubectl get nodes -o wide
```

### Vérifier tous les pods
```bash
kubectl get pods -A
```

### Vérifier les ressources par namespace
```bash
# Online Boutique
kubectl get all -n online-boutique

# Monitoring
kubectl get all -n monitoring

# Observability
kubectl get all -n observability
```

### Vérifier les HPA
```bash
kubectl get hpa -n online-boutique
```

### Vérifier les métriques
```bash
kubectl top nodes
kubectl top pods -n online-boutique
```

---

## 📚 Documentation Complémentaire

- **[DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md)** : Guide complet de déploiement
- **[TERRAFORM-REFACTORING.md](./TERRAFORM-REFACTORING.md)** : Propositions d'amélioration
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** : Architecture détaillée
- **[README.md](./README.md)** : Vue d'ensemble du projet

---

**Dernière mise à jour** : 31 Mars 2026

