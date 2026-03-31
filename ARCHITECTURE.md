# Architecture Complète - Black Friday Survival

## 🏗️ Infrastructure AWS

### Multi-AZ (3 Zones de Disponibilité)
- **Région**: eu-west-1
- **AZ1**: eu-west-1a
- **AZ2**: eu-west-1b  
- **AZ3**: eu-west-1c

### VPC (10.0.0.0/16)
- **Public Subnets** (3 AZ): 10.0.48.0/24, 10.0.49.0/24, 10.0.50.0/24
- **Private Subnets** (3 AZ): 10.0.0.0/20, 10.0.16.0/20, 10.0.32.0/20
- **NAT Gateway**: 1 seul (économie EIP)
- **Internet Gateway**: 1

### EKS Cluster (1.29)
- **Nom**: eks-bfs-gp12
- **Endpoint**: Public
- **Chiffrement**: KMS pour secrets
- **Logs**: CloudWatch (api, audit, authenticator, controllerManager, scheduler)

### Node Groups
1. **General** (ON_DEMAND)
   - Type: t3.medium
   - Min: 2, Max: 10, Desired: 3
   - Label: workload=general

2. **High Memory** (ON_DEMAND)
   - Type: t3.large
   - Min: 0, Max: 5, Desired: 0
   - Label: workload=high-memory
   - Taint: high-memory=true:NoSchedule

3. **Spot** (SPOT - 70% économie)
   - Type: t3.medium, t3a.medium
   - Min: 0, Max: 5, Desired: 2
   - Label: workload=spot

## 🔒 Security Hardening

### WAF (Web Application Firewall)
- **Rate Limiting**: 2000 req/IP/5min
- **AWS Managed Rules**:
  - Core Rule Set (protection générale)
  - Known Bad Inputs (injection)
  - SQL Injection Protection
- **Logging**: CloudWatch Logs

### Security Groups
1. **EKS Cluster SG**
   - HTTPS (443) - Sources autorisées seulement
   - HTTP (80) - Sources autorisées seulement

2. **ALB Security Group**
   - HTTP (80) - Internet
   - HTTPS (443) - Internet
   - Egress: All

### IAM Security
- **IRSA** (IAM Roles for Service Accounts)
  - AWS Load Balancer Controller
  - Cluster Autoscaler
  - EBS CSI Driver
  - CloudWatch Agent
  - Online Boutique Pods
- **KMS Encryption** pour secrets EKS
- **Politique restrictive** pour les pods
- **Pod Security Standards**: Restricted

### Network Policies
- **Default Deny All** (principe du moindre privilège)
- **Allow DNS** (kube-dns)
- **Frontend** → Services internes seulement
- **Services internes** → Communication inter-services
- **LoadGenerator** → Frontend seulement

### Kubernetes Security
- **ResourceQuota**: Limites par namespace
- **LimitRange**: Limites par container/pod
- **PriorityClass**: 3 niveaux (high/medium/low)
- **StorageClass**: GP3 avec chiffrement obligatoire

## 📊 Observabilité Complète

### Prometheus + Grafana
- **Namespace**: monitoring
- **Prometheus**:
  - Rétention: 7 jours
  - Storage: 50Gi GP3
  - Scraping: Tous les pods Kubernetes
- **Grafana**:
  - Dashboards: Kubernetes Cluster, Pods, HPA
  - Load Balancer: NLB public
  - Persistence: 10Gi
  - Password: BlackFriday2024!

### Jaeger (Distributed Tracing)
- **Namespace**: observability
- **Collector**: OTLP (gRPC 4317, HTTP 4318)
- **Query UI**: Load Balancer public
- **Storage**: Elasticsearch (30Gi)
- **Traces**: Tous les microservices

### CloudWatch
- **Container Insights**: Activé
- **Logs**:
  - /aws/eks/eks-bfs-gp12/cluster (EKS control plane)
  - /aws/waf/eks-bfs-gp12 (WAF logs)
- **Dashboard**: eks-bfs-gp12-monitoring
- **Alarmes**:
  - High CPU (>80%)
  - High Memory (>80%)
- **SNS**: Alertes email

## 🔄 Auto-Scaling

### Cluster Autoscaler
- **Auto-discovery**: Tags ASG
- **Stratégie**: least-waste
- **Balance**: Similar node groups
- **Version**: 1.29.0

### Horizontal Pod Autoscaler (HPA)
Services avec HPA :
1. **frontend**: 2-20 replicas (CPU 70%, Memory 80%)
2. **recommendationservice**: 2-15 replicas
3. **productcatalogservice**: 2-15 replicas
4. **checkoutservice**: 2-15 replicas
5. **cartservice**: 2-15 replicas
6. **currencyservice**: 2-10 replicas
7. **paymentservice**: 2-10 replicas
8. **shippingservice**: 2-10 replicas
9. **emailservice**: 2-10 replicas
10. **adservice**: 2-10 replicas

**Comportement**:
- Scale Up: +50% ou +2 pods/min (max)
- Scale Down: -10%/min après 5min stabilisation

### Metrics Server
- Métriques CPU/Memory en temps réel
- Support HPA

## 🛍️ Online Boutique (11 Microservices)

1. **frontend** - Go - Interface web
2. **cartservice** - C# - Redis cache
3. **productcatalogservice** - Go - Catalogue
4. **currencyservice** - Node.js - Conversion
5. **paymentservice** - Node.js - Paiements
6. **shippingservice** - Go - Expédition
7. **emailservice** - Python - Emails
8. **checkoutservice** - Go - Checkout
9. **recommendationservice** - Python - ML recommendations
10. **adservice** - Java - Publicités
11. **loadgenerator** - Python/Locust - Tests

## 🧪 Tests de Charge

### Configuration Locust
- **Test 1**: 5,000 utilisateurs (5 minutes)
- **Test 2**: 20,000 utilisateurs (10 minutes)
- **Test 3**: 50,000 utilisateurs (15 minutes)

### Scénarios
1. View Homepage (50%)
2. View Product (25%)
3. Add to Cart (15%)
4. View Cart (5%)
5. Checkout (5%)

### Métriques surveillées
- Response time (p50, p95, p99)
- Requests per second
- Error rate
- CPU/Memory utilization
- Number of pods scaled
- Number of nodes scaled

## 📈 Capacité Maximale

### Pods
- **Frontend**: Jusqu'à 20 replicas
- **Services critiques**: Jusqu'à 15 replicas
- **Services légers**: Jusqu'à 10 replicas
- **Total estimé**: ~150 pods maximum

### Nodes
- **General**: 10 nodes t3.medium = 20 vCPU, 40GB RAM
- **High Memory**: 5 nodes t3.large = 10 vCPU, 40GB RAM
- **Spot**: 5 nodes t3.medium = 10 vCPU, 20GB RAM
- **Total max**: 20 nodes = 40 vCPU, 100GB RAM

### Trafic estimé
- **5K users**: ~500 RPS
- **20K users**: ~2000 RPS
- **50K users**: ~5000 RPS (Black Friday peak)

## 💰 Coûts Estimés

### Infrastructure (par heure)
- EKS Control Plane: $0.10/h
- NAT Gateway: $0.045/h
- Nodes General (3x t3.medium): $0.125/h
- Nodes Spot (2x t3.medium): ~$0.025/h
- Load Balancers (3x): ~$0.075/h
- EBS Storage (150Gi): ~$0.002/h

**Total**: ~$0.37/heure (~$9/jour)

### Pendant pics (autoscaling)
- +10 nodes: +$0.40/h
**Total peak**: ~$0.77/heure

## 🏷️ Tags Obligatoires

Toutes les ressources:
```hcl
{
  Project     = "bfs-gp12"
  Environment = "prod"
  ManagedBy   = "Terraform"
  Name        = "eks-bfs-gp12-*"
}
```

## 🔐 Checklist Sécurité

- [x] WAF avec rate limiting
- [x] Security Groups restrictifs
- [x] IAM Roles avec moindre privilège (IRSA)
- [x] KMS encryption pour secrets
- [x] Network Policies (isolation réseau)
- [x] Pod Security Standards (restricted)
- [x] ResourceQuota et LimitRange
- [x] CloudWatch logging activé
- [x] Audit logs activés
- [x] TLS/SSL pour communications (à configurer)

## 📝 Notes Importantes

1. **Single NAT Gateway**: Économie mais point de défaillance unique
2. **Spot Instances**: Peuvent être terminées (prévoir tolérance)
3. **GP3 Storage**: 20% moins cher que GP2, meilleures performances
4. **Container Insights**: Coût additionnel CloudWatch
5. **Grafana Password**: Changer en production !

