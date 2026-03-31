# 🎯 Quick Start - Black Friday Survival

```
  ____  _            _      _____      _     _
 | __ )| | __ _  ___| | __ |  ___|_ __(_) __| | __ _ _   _
 |  _ \| |/ _` |/ __| |/ / | |_ | '__| |/ _` |/ _` | | | |
 | |_) | | (_| | (__|   <  |  _|| |  | | (_| | (_| | |_| |
 |____/|_|\__,_|\___|_|\_\ |_|  |_|  |_|\__,_|\__,_|\__, |
                                                     |___/
  ____                  _            _
 / ___| _   _ _ ____   _(_)_   ____ _| |
 \___ \| | | | '__\ \ / / \ \ / / _` | |
  ___) | |_| | |   \ V /| |\ V / (_| | |
 |____/ \__,_|_|    \_/ |_| \_/ \__,_|_|
```

## 🚀 Déploiement en 5 Minutes

### Étape 1 : Configuration AWS
```bash
aws configure set region eu-west-1
aws sts get-caller-identity
```

### Étape 2 : Déployer l'Infrastructure
```bash
cd terraform
terraform init && terraform apply -auto-approve
```
⏱️ **Durée** : 15-20 minutes

### Étape 3 : Déployer Online Boutique
```bash
cd ..
./deploy-online-boutique.sh
```
⏱️ **Durée** : 5-10 minutes

### Étape 4 : Exposer le Frontend
```bash
kubectl patch svc frontend-external -n online-boutique -p '{"spec":{"type":"LoadBalancer"}}'
kubectl get svc frontend-external -n online-boutique -w
```
⏱️ **Durée** : 2-3 minutes

### Étape 5 : Tester
```bash
./load-test.sh
```
⏱️ **Durée** : 30+ minutes (selon les tests)

---

## 📊 Infrastructure Déployée

```
┌─────────────────────────────────────────────────────────────┐
│                     AWS Cloud (eu-west-1)                   │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                 VPC (10.0.0.0/16)                     │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐│  │
│  │  │  Public AZ-A │  │  Public AZ-B │  │  Public AZ-C ││  │
│  │  │  10.0.1.0/24 │  │  10.0.2.0/24 │  │  10.0.3.0/24 ││  │
│  │  └──────┬───────┘  └──────────────┘  └──────────────┘│  │
│  │         │                                              │  │
│  │    ┌────▼─────┐         Internet Gateway              │  │
│  │    │NAT Gateway│◄──────────────────────────────────── │  │
│  │    └────┬─────┘                                        │  │
│  │  ┌──────▼───────┐  ┌──────────────┐  ┌──────────────┐│  │
│  │  │ Private AZ-A │  │ Private AZ-B │  │ Private AZ-C ││  │
│  │  │ 10.0.101/24  │  │ 10.0.102/24  │  │ 10.0.103/24  ││  │
│  │  │              │  │              │  │              ││  │
│  │  │  ┌────────┐  │  │  ┌────────┐  │  │  ┌────────┐ ││  │
│  │  │  │  Node  │  │  │  │  Node  │  │  │  │  Node  │ ││  │
│  │  │  │ Group  │  │  │  │ Group  │  │  │  │ Group  │ ││  │
│  │  │  │General │  │  │  │ Spot   │  │  │  │Hi-Mem  │ ││  │
│  │  │  └────────┘  │  │  └────────┘  │  │  └────────┘ ││  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘│  │
│  │                                                        │  │
│  │              EKS Cluster (eks-bfs-gp12)               │  │
│  │            Kubernetes 1.29 - 149 Resources            │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              Security & Monitoring                    │  │
│  │  • WAF (Rate Limiting: 2000 req/5min)                │  │
│  │  • KMS (Secret Encryption)                            │  │
│  │  • CloudWatch (Logs + Alarms)                         │  │
│  │  • Prometheus + Grafana                               │  │
│  │  • Jaeger (Distributed Tracing)                       │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 Ressources (149 Total)

| Catégorie | Quantité | Exemples |
|-----------|----------|----------|
| **Network** | 15+ | VPC, Subnets, NAT, IGW, Routes |
| **Compute** | 20+ | EKS Cluster, 3 Node Groups, Auto Scaling |
| **Security** | 30+ | KMS, Security Groups, IAM Roles, WAF |
| **Monitoring** | 25+ | CloudWatch, Prometheus, Grafana, Jaeger |
| **Storage** | 10+ | EBS Volumes, PVCs |
| **Load Balancing** | 5+ | ALB, NLB, Target Groups |
| **Controllers** | 10+ | ALB Controller, Cluster Autoscaler, Metrics Server |
| **Application** | 34+ | 11 microservices + HPA + Network Policies |

---

## 🛍️ Online Boutique (11 Microservices)

```
┌─────────────────────────────────────────────────────────────┐
│                        Frontend (Go)                        │
│                    http://LOAD_BALANCER                     │
└───┬─────────────────────────────────────────────────────┬───┘
    │                                                     │
    ├─► Cart Service (C#)          Recommendation ◄──────┤
    │                               Service (Python)      │
    ├─► Product Catalog (Go)                             │
    │                                                     │
    ├─► Currency Service (Node.js)                       │
    │                                                     │
    ├─► Checkout Service (Go) ────┐                      │
    │                              │                      │
    │                              ├─► Payment (Node.js)  │
    │                              │                      │
    │                              ├─► Shipping (Go)      │
    │                              │                      │
    │                              └─► Email (Python)     │
    │                                                     │
    └─► Ad Service (Java) ◄──────────────────────────────┘
         
    Redis Cart (Cache) ◄─── Cart Service
```

---

## 📊 Monitoring Stack

```
┌──────────────────────────────────────────────────────────┐
│                      Grafana UI                          │
│              http://localhost:3000                       │
│              User: admin / Pass: admin123                │
└────────────────┬─────────────────────────────────────────┘
                 │
     ┌───────────▼────────────┐
     │    Prometheus          │
     │  (Metrics Storage)     │
     │    Retention: 7d       │
     └───────────┬────────────┘
                 │
     ┌───────────▼────────────┐
     │   Metrics Server       │
     │   (CPU/Memory)         │
     └────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│                      Jaeger UI                           │
│              http://JAEGER_LOAD_BALANCER:16686          │
└────────────────┬─────────────────────────────────────────┘
                 │
     ┌───────────▼────────────┐
     │  Jaeger Collector      │
     │  (OTLP 4317/4318)      │
     └───────────┬────────────┘
                 │
     ┌───────────▼────────────┐
     │   Elasticsearch        │
     │  (Traces Storage)      │
     └────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│                   CloudWatch                             │
│        AWS Console > CloudWatch > Dashboards             │
│           Dashboard: eks-bfs-gp12-monitoring             │
└──────────────────────────────────────────────────────────┘
```

---

## 🧪 Tests de Charge

```bash
./load-test.sh
```

Le script demande interactivement :
```
Nombre d'utilisateurs pour le TEST 1 (faible charge, défaut: 5000): 
Nombre d'utilisateurs pour le TEST 2 (charge moyenne, défaut: 20000): 
Nombre d'utilisateurs pour le TEST 3 (Black Friday, défaut: 50000): 
```

### Scénarios de Test Automatiques
- 🏠 **10%** : Visite homepage
- 👁️ **5%** : Vue produit
- 🛒 **3%** : Ajout panier
- 📦 **1%** : Vue panier
- 💳 **1%** : Checkout

---

## 💰 Coûts Estimés

| Configuration | Coût/Mois | Usage |
|--------------|-----------|-------|
| **Production** | $260-592 | Full stack, HA, Monitoring |
| **Dev** | $120-180 | Minimal, 1 node, No monitoring |
| **Black Friday Peak** | +$100-200 | Scale temporaire |

**💡 Optimisation** : Voir [TERRAFORM-REFACTORING.md](./TERRAFORM-REFACTORING.md)

---

## 🔗 Liens Rapides

| Service | Commande | URL |
|---------|----------|-----|
| **Frontend** | `kubectl get svc -n online-boutique frontend-external` | `http://<LB_DNS>` |
| **Grafana** | `kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80` | `localhost:3000` |
| **Jaeger** | `kubectl port-forward -n observability svc/jaeger-query 16686:16686` | `localhost:16686` |
| **Prometheus** | `kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090` | `localhost:9090` |

---

## 📚 Documentation

| Fichier | Description | Lignes |
|---------|-------------|--------|
| [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md) | Guide complet de déploiement | 400+ |
| [RESOURCES-INSTALLED.md](./RESOURCES-INSTALLED.md) | Liste des 149 ressources | 350+ |
| [TERRAFORM-REFACTORING.md](./TERRAFORM-REFACTORING.md) | Propositions d'amélioration | 500+ |
| [SUMMARY-MODIFICATIONS.md](./SUMMARY-MODIFICATIONS.md) | Résumé des changements | 250+ |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | Architecture détaillée | Existant |
| [README.md](./README.md) | Vue d'ensemble | Existant |

---

## 🛠️ Scripts Utiles

### Déploiement
```bash
# Déployer tout
./deploy-all.sh

# Déployer Online Boutique uniquement
./deploy-online-boutique.sh

# Configuration personnalisée
CLUSTER_NAME="mon-cluster" AWS_REGION="eu-west-1" ./deploy-online-boutique.sh
```

### Tests
```bash
# Tests de charge interactifs
./load-test.sh

# Tests rapides (valeurs par défaut)
echo -e "\n\n\n" | ./load-test.sh
```

### Monitoring
```bash
# Surveiller les pods
watch kubectl get pods -n online-boutique

# Métriques
kubectl top nodes
kubectl top pods -n online-boutique

# Logs
kubectl logs -n online-boutique deployment/frontend -f
```

### Nettoyage
```bash
# Supprimer Online Boutique
kubectl delete namespace online-boutique

# Détruire l'infrastructure
cd terraform && terraform destroy -auto-approve
```

---

## 🔍 Troubleshooting Rapide

### Pods en ImagePullBackOff
```bash
kubectl describe pod <pod-name> -n online-boutique
# Vérifier l'image et les credentials ECR
```

### LoadBalancer ne se crée pas
```bash
kubectl logs -n kube-system deployment/aws-load-balancer-controller
kubectl describe svc frontend-external -n online-boutique
```

### Nodes ne scalent pas
```bash
kubectl logs -n kube-system deployment/cluster-autoscaler
kubectl get hpa -n online-boutique
```

### Terraform échoue
```bash
# Vérifier les permissions IAM
aws iam list-attached-user-policies --user-name $(aws sts get-caller-identity --query 'Arn' --output text | cut -d'/' -f2)

# Vérifier les ressources orphelines
aws eks list-clusters --region eu-west-1
```

---

## ✅ Checklist de Vérification

- [ ] AWS CLI configuré (région : eu-west-1)
- [ ] Terraform 149 ressources déployées
- [ ] Cluster EKS accessible (`kubectl get nodes`)
- [ ] Online Boutique déployé (11 pods Running)
- [ ] Frontend exposé (LoadBalancer)
- [ ] Grafana accessible (port-forward)
- [ ] Jaeger accessible (LoadBalancer ou port-forward)
- [ ] Tests de charge fonctionnels
- [ ] CloudWatch Alarms configurées
- [ ] HPA fonctionnels (`kubectl get hpa`)

---

## 🎓 Formation et Ressources

### Pour Apprendre
- [Guide de Déploiement](./DEPLOYMENT-GUIDE.md) - Suivre étape par étape
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)

### Pour Améliorer
- [Terraform Refactoring](./TERRAFORM-REFACTORING.md) - 12 propositions
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [CNCF Landscape](https://landscape.cncf.io/) - Outils Cloud Native

### Pour Débugger
- [Resources Installed](./RESOURCES-INSTALLED.md) - Vue d'ensemble complète
- [Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug/)

---

## 🚀 Go Live !

```bash
# Terminal 1 : Déployer
cd terraform && terraform apply -auto-approve
./deploy-online-boutique.sh

# Terminal 2 : Surveiller
watch kubectl get pods -n online-boutique

# Terminal 3 : Exposer
kubectl patch svc frontend-external -n online-boutique -p '{"spec":{"type":"LoadBalancer"}}'
kubectl get svc frontend-external -n online-boutique -w

# Terminal 4 : Tester (une fois le LB prêt)
./load-test.sh
```

---

**🎉 Félicitations ! Votre infrastructure Black Friday est prête ! 🛍️**

**📅 Dernière mise à jour** : 31 Mars 2026  
**⭐ Version** : 1.0.0

