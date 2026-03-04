# 📊 ÉTAT DES RESSOURCES AWS - bfs-gp12

**Date** : 2 mars 2026  
**Cluster** : eks-bfs-gp12-prod  
**Région** : eu-south-2 (Espagne)  
**Compte** : 622333992348

---

## 🏗️ INFRASTRUCTURE

### Cluster EKS
- **Nom** : eks-bfs-gp12-prod
- **Version** : Kubernetes 1.29
- **Endpoint** : https://D37D36C265318C173B065D75E52C8AE2.yl4.eu-south-2.eks.amazonaws.com
- **Status** : ✅ ACTIVE

### VPC & Réseau
- **VPC** : vpc-0dd16f967ef7855b6 (10.0.0.0/16)
- **Subnets** : 6 (3 privés + 3 publics) sur 3 AZ
- **NAT Gateways** : 3 (1 par AZ)
- **Internet Gateway** : 1
- **Security Groups** : sg-01386aa48797cfd96

### Nodes
- **Node Group** : general-bfs-gp12
- **Type** : t3.medium (2 vCPU, 4GB RAM)
- **Actuel** : 3 nodes
- **Auto-scaling** : 3 min → 20 max

---

## 🛍️ MICROSERVICES (12 services)

| Service | Status | HPA | Port |
|---------|--------|-----|------|
| frontend | ✅ 1/1 | 2-20 | 8080 |
| productcatalogservice | ✅ 1/1 | 2-10 | 3550 |
| cartservice | ✅ 1/1 | 2-10 | 7070 |
| checkoutservice | ✅ 1/1 | 2-15 | 5050 |
| recommendationservice | ✅ 1/1 | 2-10 | 8080 |
| currencyservice | ✅ 1/1 | - | 7000 |
| paymentservice | ✅ 1/1 | - | 50051 |
| shippingservice | ✅ 1/1 | - | 50051 |
| emailservice | ✅ 1/1 | - | 5000 |
| adservice | ✅ 1/1 | - | 9555 |
| redis-cart | ✅ 1/1 | - | 6379 |
| loadgenerator | ✅ 1/1 | - | - |

---

## 🌐 ACCÈS PUBLIC

**URL Frontend** : http://k8s-default-frontend-6d2488e557-1971279743.eu-south-2.elb.amazonaws.com

**Load Balancer** :
- Type : Application Load Balancer (ALB)
- Scheme : internet-facing
- Status : ✅ Opérationnel

---

## 🔄 AUTO-SCALING

### Pods (HPA)
- **5 services** avec auto-scaling
- **Trigger** : CPU > 70%
- **Min replicas** : 2 par service
- **Max replicas** : 10-20 selon le service

### Nodes (Cluster Autoscaler)
- **Min** : 3 nodes
- **Max** : 20 nodes
- **Status** : ✅ Actif

---

## 📊 MONITORING (CloudWatch)

### Dashboard
- **Nom** : eks-bfs-gp12-prod-monitoring
- **Métriques** : CPU, RAM, Network, Node count

### Logs
- **Log Group** : /aws/eks/eks-bfs-gp12-prod/cluster
- **Retention** : 7 jours
- **Types** : api, audit, authenticator, controllerManager, scheduler

### Alertes
- **CPU > 80%** → SNS (alerts-bfs-gp12)
- **Nodes < 3** → SNS (alerts-bfs-gp12)

---

## 🔐 IAM ROLES (IRSA)

| Role | ARN |
|------|-----|
| cluster-autoscaler | arn:aws:iam::622333992348:role/eks-bfs-gp12-prod-cluster-autoscaler |
| aws-load-balancer-controller | arn:aws:iam::622333992348:role/eks-bfs-gp12-prod-aws-load-balancer-controller |
| ebs-csi-driver | arn:aws:iam::622333992348:role/eks-bfs-gp12-prod-ebs-csi |

---

## 🧪 TESTS DE CHARGE

### Scripts
- **test-de-charge.sh** : Lancer un test (demande nb users)
- **stop-test.sh** : Arrêter un test en cours

### Capacités
- **100 users** : 1 replica (défaut)
- **1000 users** : 10 replicas
- **5000 users** : 50 replicas
- **Personnalisable** : Tout nombre via script

---

## 💰 COÛTS

### Actuel (~200 USD/mois - ~7 USD/jour)
- **Compute** : 90 USD (3 × t3.medium)
- **Network** : 106 USD (3 NAT GW + data transfer)
- **EKS** : 73 USD (cluster fee)
- **Storage + Logs** : 9 USD
- **ALB** : 16 USD
- **Autres** : 6 USD

### Pendant Tests de Charge
- **5K users** : ~19 USD/jour (10-15 nodes)
- **20K users** : ~25 USD/jour (20 nodes max)

---

## 🎯 RÉSUMÉ

| Composant | État |
|-----------|------|
| Infrastructure | ✅ Opérationnelle |
| Microservices | ✅ 12/12 Running |
| Auto-Scaling | ✅ Pods + Nodes |
| Monitoring | ✅ CloudWatch |
| Load Balancer | ✅ Public |
| Tests | ✅ Scripts prêts |

---

## 📝 COMMANDES UTILES

```bash
# Configuration kubectl
aws eks update-kubeconfig --region eu-south-2 --name eks-bfs-gp12-prod

# Voir les pods
kubectl get pods

# Voir les nodes
kubectl get nodes

# Lancer un test de charge
./test-de-charge.sh

# Arrêter un test
./stop-test.sh <deployment-name>

# Dashboard CloudWatch
# https://eu-south-2.console.aws.amazon.com/cloudwatch/home?region=eu-south-2#dashboards:name=eks-bfs-gp12-prod-monitoring
```

---

**Dernière mise à jour** : 2 mars 2026

