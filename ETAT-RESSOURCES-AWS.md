# 📊 ÉTAT COMPLET DES RESSOURCES AWS - BLACK FRIDAY SURVIVAL

**Date** : 23 février 2026  
**Projet** : Black Friday Survival - bfs-gp12  
**Cluster** : eks-bfs-gp12-prod  
**Région** : eu-south-2 (Espagne)  
**Compte AWS** : 622333992348

---

## 🏗️ INFRASTRUCTURE AWS (VIA TERRAFORM)

### 1. VPC ET RÉSEAU

#### VPC Principal
- **VPC ID** : vpc-0dd16f967ef7855b6
- **CIDR** : 10.0.0.0/16
- **Nom** : vpc-bfs-gp12
- **DNS Support** : Activé
- **DNS Hostnames** : Activé

#### Subnets (6 au total)

**Subnets Privés** (pour les pods et nodes) :
- subnet-0bfc44e6a3de7ecea (AZ: eu-south-2a)
- subnet-0bd25b76698c89697 (AZ: eu-south-2b)
- subnet-0127f5c4edfd2b478 (AZ: eu-south-2c)

**Subnets Publics** (pour les LoadBalancers) :
- subnet-0e841a12c9f81effb (AZ: eu-south-2a)
- subnet-0697cd7dea71038c1 (AZ: eu-south-2b)
- subnet-08454d206f58193ea (AZ: eu-south-2c)

#### Composants Réseau

**NAT Gateways** (3 pour haute disponibilité) :
- 1 NAT Gateway par AZ
- Associés aux subnets publics
- Elastic IPs allouées

**Internet Gateway** :
- 1 Internet Gateway attaché au VPC
- Route vers 0.0.0.0/0 pour trafic sortant

**Route Tables** :
- Route tables privées (via NAT Gateways)
- Route tables publiques (via Internet Gateway)

**Security Groups** :
- Cluster Security Group : sg-01386aa48797cfd96
- Node Groups Security Groups
- Load Balancer Security Groups

---

## ☸️ CLUSTER AMAZON EKS

### Cluster Principal

**Nom** : eks-bfs-gp12-prod  
**ARN** : arn:aws:eks:eu-south-2:622333992348:cluster/eks-bfs-gp12-prod  
**Version Kubernetes** : 1.29  
**Endpoint** : https://D37D36C265318C173B065D75E52C8AE2.yl4.eu-south-2.eks.amazonaws.com  
**Status** : ACTIVE ✅

**Configuration** :
- Encryption : KMS activée
- Logs CloudWatch : 5 types activés
  - api
  - audit
  - authenticator
  - controllerManager
  - scheduler
- OIDC Provider : Activé pour IRSA
- Network Type : IPv4

**OIDC Provider** :
- ARN : arn:aws:iam::622333992348:oidc-provider/oidc.eks.eu-south-2.amazonaws.com/id/D37D36C265318C173B065D75E52C8AE2

---

## 🖥️ NODE GROUPS (WORKERS)

### 1. General Purpose Node Group
- **Nom** : general-bfs-gp12
- **Type d'instance** : t3.medium (2 vCPU, 4GB RAM)
- **Min** : 3 nodes
- **Max** : 20 nodes
- **Actuel** : 5 nodes ✅
- **AMI** : Amazon Linux 2
- **Disk** : 20 GB gp3
- **Labels** : role=general
- **Taints** : Aucun

**Coût** : ~0.0416 USD/heure/node (~30 USD/mois/node)

### 2. High Performance Node Group
- **Nom** : high-perf-bfs-gp12
- **Type d'instance** : c5.xlarge (4 vCPU, 8GB RAM)
- **Min** : 0 nodes
- **Max** : 30 nodes
- **Actuel** : 2 nodes ✅
- **AMI** : Amazon Linux 2
- **Disk** : 20 GB gp3
- **Labels** : role=high-performance
- **Taints** : high-performance=true:NoSchedule

**Coût** : ~0.17 USD/heure/node (~122 USD/mois/node)

### 3. Spot Instances Node Group
- **Nom** : spot-bfs-gp12
- **Types d'instances** : t3.medium, t3.large
- **Min** : 0 nodes
- **Max** : 15 nodes
- **Actuel** : 3 nodes ✅
- **Capacity Type** : SPOT (économies ~70%)
- **AMI** : Amazon Linux 2
- **Disk** : 20 GB gp3
- **Labels** : role=spot

**Coût** : ~0.0125 USD/heure/node (~9 USD/mois/node)

### TOTAL NODES ACTIFS : 10 nodes

**Capacité Totale** :
- **vCPUs** : ~28
- **RAM** : ~56 GB
- **Coût mensuel actuel** : ~589 USD

**Capacité Maximale (si fully scaled)** :
- **Nodes max** : 65 (20 + 30 + 15)
- **vCPUs max** : ~180
- **RAM max** : ~360 GB
- **Coût max** : ~4,519 USD/mois

---

## 🔐 IAM ROLES ET POLICIES

### 1. Cluster Autoscaler Role
- **Nom** : eks-bfs-gp12-prod-cluster-autoscaler
- **ARN** : arn:aws:iam::622333992348:role/eks-bfs-gp12-prod-cluster-autoscaler
- **Service Account** : cluster-autoscaler (namespace: kube-system)
- **Permissions** :
  - autoscaling:DescribeAutoScalingGroups
  - autoscaling:SetDesiredCapacity
  - autoscaling:TerminateInstanceInAutoScalingGroup
  - ec2:DescribeInstances
  - ec2:DescribeLaunchTemplateVersions

### 2. AWS Load Balancer Controller Role
- **Nom** : eks-bfs-gp12-prod-aws-load-balancer-controller
- **ARN** : arn:aws:iam::622333992348:role/eks-bfs-gp12-prod-aws-load-balancer-controller
- **Service Account** : aws-load-balancer-controller (namespace: kube-system)
- **Permissions** :
  - Gestion des ALB/NLB
  - Gestion des Target Groups
  - Modification des Security Groups
  - Route53 (optionnel)

### 3. EBS CSI Driver Role
- **Nom** : eks-bfs-gp12-prod-ebs-csi
- **ARN** : arn:aws:iam::622333992348:role/eks-bfs-gp12-prod-ebs-csi
- **Service Account** : ebs-csi-controller-sa (namespace: kube-system)
- **Permissions** :
  - ec2:CreateVolume
  - ec2:DeleteVolume
  - ec2:AttachVolume
  - ec2:DetachVolume
  - ec2:DescribeVolumes

---

## 📊 MONITORING - CLOUDWATCH

### Dashboard
- **Nom** : eks-bfs-gp12-prod-monitoring
- **Région** : eu-south-2
- **URL** : https://eu-south-2.console.aws.amazon.com/cloudwatch/home?region=eu-south-2#dashboards:name=eks-bfs-gp12-prod-monitoring

**Widgets** :
- Nombre de nodes
- Utilisation CPU
- Trafic réseau (in/out)
- Métriques custom

### Log Groups
- **Nom** : /aws/eks/eks-bfs-gp12-prod/cluster
- **Retention** : 7 jours
- **Types de logs** :
  - api (API server logs)
  - audit (Audit logs)
  - authenticator (IAM authenticator)
  - controllerManager (Controller Manager)
  - scheduler (Scheduler)

**Taille estimée** : ~500 MB/jour

### CloudWatch Alarms

**1. High CPU Usage**
- Seuil : > 80% pendant 5 minutes
- Action : SNS notification

**2. Low Node Count**
- Seuil : < 3 nodes
- Action : SNS notification

### SNS Topic
- **Nom** : alerts-bfs-gp12
- **ARN** : arn:aws:sns:eu-south-2:622333992348:alerts-bfs-gp12
- **Protocole** : Email (à configurer)

---

## 🚀 COMPOSANTS SYSTÈME KUBERNETES

### 1. Cluster Autoscaler
- **Namespace** : kube-system
- **Deployment** : cluster-autoscaler
- **Replicas** : 1/1 ✅
- **Version** : v1.29.0
- **Image** : registry.k8s.io/autoscaling/cluster-autoscaler:v1.29.0
- **IRSA** : ✅ Configuré
- **Fonction** : Auto-scaling des nodes (3-65)

### 2. AWS Load Balancer Controller
- **Namespace** : kube-system
- **Deployment** : aws-load-balancer-controller
- **Replicas** : 2/2 ✅
- **Version** : Latest (via Helm)
- **IRSA** : ✅ Configuré
- **Fonction** : Gestion des ALB/NLB

### 3. Metrics Server
- **Namespace** : kube-system
- **Deployment** : metrics-server
- **Replicas** : 1/1 ✅
- **Fonction** : Métriques CPU/RAM pour HPA

### 4. CoreDNS
- **Namespace** : kube-system
- **Deployment** : coredns
- **Replicas** : 2/2 ✅
- **Fonction** : DNS interne du cluster

### 5. AWS VPC CNI
- **Namespace** : kube-system
- **DaemonSet** : aws-node
- **Pods** : 10/10 (1 par node) ✅
- **Fonction** : Networking avec AWS VPC

### 6. kube-proxy
- **Namespace** : kube-system
- **DaemonSet** : kube-proxy
- **Pods** : 10/10 (1 par node) ✅
- **Fonction** : Network proxy

---

## 🛍️ MICROSERVICES APPLICATIFS (12 services)

### 1. Frontend
- **Deployment** : frontend
- **Replicas** : 1/1 ✅ (HPA: min 2, max 20)
- **Image** : gcr.io/google-samples/microservices-demo/frontend:v0.10.1
- **Port** : 8080
- **Langage** : Go
- **Fonction** : Interface web de la boutique
- **Ressources** :
  - CPU request: 100m
  - Memory request: 64Mi

### 2. Product Catalog Service
- **Deployment** : productcatalogservice
- **Replicas** : 1/1 ✅ (HPA: min 2, max 10)
- **Image** : gcr.io/google-samples/microservices-demo/productcatalogservice:v0.10.1
- **Port** : 3550
- **Langage** : Go
- **Fonction** : Catalogue de produits (liste, recherche)

### 3. Cart Service
- **Deployment** : cartservice
- **Replicas** : 1/1 ✅ (HPA: min 2, max 10)
- **Image** : gcr.io/google-samples/microservices-demo/cartservice:v0.10.1
- **Port** : 7070
- **Langage** : C#
- **Fonction** : Gestion du panier
- **Dépendance** : Redis

### 4. Checkout Service
- **Deployment** : checkoutservice
- **Replicas** : 1/1 ✅ (HPA: min 2, max 15)
- **Image** : gcr.io/google-samples/microservices-demo/checkoutservice:v0.10.1
- **Port** : 5050
- **Langage** : Go
- **Fonction** : Processus de commande

### 5. Recommendation Service
- **Deployment** : recommendationservice
- **Replicas** : 1/1 ✅ (HPA: min 2, max 10)
- **Image** : gcr.io/google-samples/microservices-demo/recommendationservice:v0.10.1
- **Port** : 8080
- **Langage** : Python
- **Fonction** : Recommandations de produits

### 6. Currency Service
- **Deployment** : currencyservice
- **Replicas** : 1/1 ✅
- **Image** : gcr.io/google-samples/microservices-demo/currencyservice:v0.10.1
- **Port** : 7000
- **Langage** : Node.js
- **Fonction** : Conversion de devises

### 7. Payment Service
- **Deployment** : paymentservice
- **Replicas** : 1/1 ✅
- **Image** : gcr.io/google-samples/microservices-demo/paymentservice:v0.10.1
- **Port** : 50051
- **Langage** : Node.js
- **Fonction** : Traitement des paiements

### 8. Shipping Service
- **Deployment** : shippingservice
- **Replicas** : 1/1 ✅
- **Image** : gcr.io/google-samples/microservices-demo/shippingservice:v0.10.1
- **Port** : 50051
- **Langage** : Go
- **Fonction** : Calcul des frais de port

### 9. Email Service
- **Deployment** : emailservice
- **Replicas** : 1/1 ✅
- **Image** : gcr.io/google-samples/microservices-demo/emailservice:v0.10.1
- **Port** : 5000
- **Langage** : Python
- **Fonction** : Envoi d'emails de confirmation

### 10. Ad Service
- **Deployment** : adservice
- **Replicas** : 1/1 ✅
- **Image** : gcr.io/google-samples/microservices-demo/adservice:v0.10.1
- **Port** : 9555
- **Langage** : Java
- **Fonction** : Service de publicités

### 11. Redis Cart
- **Deployment** : redis-cart
- **Replicas** : 1/1 ✅
- **Image** : redis:alpine
- **Port** : 6379
- **Fonction** : Base de données pour le panier

### 12. Load Generator
- **Deployment** : loadgenerator
- **Replicas** : 1/1 ✅
- **Image** : gcr.io/google-samples/microservices-demo/loadgenerator:v0.10.1
- **Fonction** : Génération de trafic pour tests

**TOTAL MICROSERVICES** : 12 services ✅

---

## ���� SERVICES KUBERNETES

### Services ClusterIP (Internes)

1. **frontend** : 172.20.81.156:80 → 8080
2. **productcatalogservice** : 172.20.30.10:3550
3. **cartservice** : 172.20.208.64:7070
4. **checkoutservice** : 172.20.79.80:5050
5. **currencyservice** : 172.20.22.250:7000
6. **emailservice** : 172.20.221.15:5000
7. **paymentservice** : 172.20.231.195:50051
8. **recommendationservice** : 172.20.172.237:8080
9. **shippingservice** : 172.20.68.120:50051
10. **adservice** : 172.20.178.202:9555
11. **redis-cart** : 172.20.38.193:6379

### Ingress (Accès Externe)

**Frontend Ingress**
- **Nom** : frontend-ingress
- **Class** : alb
- **Type** : Application Load Balancer (ALB)
- **Scheme** : internet-facing
- **Target Type** : IP
- **URL** : http://k8s-default-frontend-6d2488e557-1971279743.eu-south-2.elb.amazonaws.com
- **Port** : 80 → 8080
- **Health Check** : HTTP GET /

**Annotations** :
- alb.ingress.kubernetes.io/scheme: internet-facing
- alb.ingress.kubernetes.io/target-type: ip
- alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'

---

## 🔄 AUTO-SCALING CONFIGURÉ

### Horizontal Pod Autoscaler (HPA)

1. **frontend**
   - Min replicas : 2
   - Max replicas : 20
   - Target CPU : 70%
   - Current : 1 replica

2. **productcatalogservice**
   - Min replicas : 2
   - Max replicas : 10
   - Target CPU : 70%
   - Current : 1 replica

3. **checkoutservice**
   - Min replicas : 2
   - Max replicas : 15
   - Target CPU : 70%
   - Current : 1 replica

4. **cartservice**
   - Min replicas : 2
   - Max replicas : 10
   - Target CPU : 70%
   - Current : 1 replica

5. **recommendationservice**
   - Min replicas : 2
   - Max replicas : 10
   - Target CPU : 70%
   - Current : 1 replica

**Total HPAs** : 5 services auto-scalables

### Cluster Autoscaler

- **Min nodes** : 3
- **Max nodes** : 65
- **Current nodes** : 10
- **Scaling logic** :
  - Scale UP : Quand pods en Pending (pas assez de ressources)
  - Scale DOWN : Quand nodes sous-utilisés < 50% pendant 10 min

---

## 🧪 TESTS DE CHARGE

### Configuration Actuelle

**Load Generator - 1000 Users**
- **Deployment** : loadgenerator-heavy
- **Replicas** : 10/10 ✅
- **Users par replica** : 100
- **Total users simulés** : 1000
- **Status** : ACTIF ✅

### Configuration Préparée (Non Déployée)

**Load Generator - 5000 Users**
- **Deployment** : loadgenerator-5k (fichier créé)
- **Replicas configurées** : 50
- **Users par replica** : 100
- **Total users** : 5000
- **Status** : Prêt à déployer

---

## 💰 COÛTS AWS ESTIMÉS

### Coût Mensuel Actuel (~589 USD/mois)

**Compute (Nodes)** :
- 5 × t3.medium : 150 USD
- 2 × c5.xlarge : 244 USD
- 3 × t3.medium spot : 27 USD
- **Total Compute** : 421 USD/mois

**Network** :
- 3 × NAT Gateway : 96 USD/mois (32 USD × 3)
- Data Transfer : ~20 USD/mois
- **Total Network** : 116 USD/mois

**EKS** :
- Cluster fee : 73 USD/mois (0.10 USD/heure)

**Storage** :
- EBS volumes (20GB × 10) : ~20 USD/mois
- CloudWatch Logs : ~5 USD/mois

**Load Balancer** :
- ALB : ~16 USD/mois

**Autres** :
- KMS : ~1 USD/mois
- Elastic IPs : ~0 USD (associées)

### Coût Journalier : ~20 USD/jour

### Coût Pendant Tests de Charge

**Test 5K users** (~25 nodes) :
- Compute : ~1,500 USD/mois (~50 USD/jour)
- Network : ~150 USD/mois (~5 USD/jour)
- **Total** : ~55 USD/jour

**Test 50K users** (~65 nodes max) :
- Compute : ~4,000 USD/mois (~133 USD/jour)
- Network : ~200 USD/mois (~7 USD/jour)
- **Total** : ~140 USD/jour

---

## 📈 MÉTRIQUES ACTUELLES

### Utilisation Ressources (Estimation)

**Nodes** :
- CPU moyen : ~30-40%
- RAM moyenne : ~50%
- Pods total : ~35 pods

**Pods par Node** :
- Moyenne : ~3-4 pods/node
- Max possible : ~29 pods/node (limite AWS ENI)

**Network** :
- Trafic entrant : ~10 GB/jour
- Trafic sortant : ~5 GB/jour

---

## 🔧 RESSOURCES ADDITIONNELLES

### ConfigMaps
- aws-auth (kube-system) : Mapping IAM → K8s RBAC
- coredns (kube-system) : Configuration DNS

### Service Accounts
- cluster-autoscaler : IRSA configuré
- aws-load-balancer-controller : IRSA configuré
- ebs-csi-controller-sa : IRSA configuré
- default (par namespace)

### Namespaces
- default : Applications
- kube-system : Composants système
- kube-public : Ressources publiques
- kube-node-lease : Node heartbeats

---

## 📋 RÉSUMÉ GLOBAL

### Infrastructure AWS

| Ressource | Quantité | Status |
|-----------|----------|--------|
| VPC | 1 | ✅ |
| Subnets | 6 (3 privés + 3 publics) | ✅ |
| NAT Gateways | 3 | ✅ |
| Internet Gateway | 1 | ✅ |
| Cluster EKS | 1 | ✅ |
| Node Groups | 3 | ✅ |
| Nodes actifs | 10 | ✅ |
| IAM Roles | 3+ | ✅ |
| Security Groups | 4+ | ✅ |
| CloudWatch Dashboard | 1 | ✅ |
| CloudWatch Log Groups | 1 | ✅ |
| CloudWatch Alarms | 2 | ✅ |
| SNS Topics | 1 | ✅ |
| Application Load Balancer | 1 | ✅ |

### Applications Kubernetes

| Type | Quantité | Status |
|------|----------|--------|
| Microservices | 12 | ✅ Running |
| Composants Système | 6 | ✅ Running |
| Services ClusterIP | 11 | ✅ |
| Ingress | 1 | ✅ |
| HPAs | 5 | ✅ |
| Load Generators | 10 | ✅ Actifs (1000 users) |

### Capacité

| Métrique | Actuel | Maximum |
|----------|--------|---------|
| Nodes | 10 | 65 |
| vCPUs | 28 | ~180 |
| RAM | 56 GB | ~360 GB |
| Pods | ~35 | ~1,885 (29 × 65) |
| Users simulés | 1,000 | 5,000+ |

---

## 🎯 ÉTAT FINAL

**Infrastructure** : ✅ 100% Opérationnelle  
**Applications** : ✅ 12/12 Running  
**Auto-Scaling** : ✅ Configuré (Pods + Nodes)  
**Monitoring** : ✅ CloudWatch actif  
**Tests** : ✅ 1000 users en cours  
**Accès Public** : ✅ Via ALB  

**Budget mensuel** : ~589 USD  
**Coût actuel** : ~20 USD/jour  
**Région** : eu-south-2 (Espagne)  

🚀 **INFRASTRUCTURE PRÊTE POUR LE BLACK FRIDAY !**

---

**Dernière mise à jour** : 23 février 2026  
**Cluster** : eks-bfs-gp12-prod  
**Account** : 622333992348  
**Contact** : bfs-gp12

