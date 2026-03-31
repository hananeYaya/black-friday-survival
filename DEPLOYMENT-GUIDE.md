# 🚀 Guide de Déploiement - Black Friday Survival

## 📋 Prérequis

- AWS CLI configuré avec les bonnes permissions
- kubectl installé
- Terraform >= 1.0
- Helm >= 3.0
- Python 3 et pip (pour les tests de charge)

## 🏗️ Ressources Terraform Déployées

### Infrastructure de base (149 ressources)

#### VPC et Réseau
- **VPC** : `10.0.0.0/16` sur 3 zones de disponibilité
- **Subnets** : 3 publics + 3 privés
- **NAT Gateway** : 1 instance (économie de coûts)
- **Internet Gateway** : 1 instance

#### EKS Cluster
- **Cluster EKS** : `eks-bfs-gp12` (Kubernetes 1.29)
- **Node Groups** :
  - `general` : 2-10 nodes (t3.medium, ON_DEMAND)
  - `high_memory` : 0-5 nodes (t3.large, ON_DEMAND, avec taint)
  - `spot` : 0-5 nodes (t3.medium/t3a.medium, SPOT)

#### Addons EKS
- CoreDNS (dernière version)
- kube-proxy (dernière version)
- VPC CNI (dernière version)
- AWS EBS CSI Driver (avec IAM role)

#### Sécurité
- **KMS Key** : Chiffrement des secrets Kubernetes
- **Security Groups** : EKS, ALB
- **WAF Web ACL** : Protection contre les attaques (rate limiting: 2000 req/5min/IP)
- **IAM Roles** : 
  - AWS Load Balancer Controller
  - Cluster Autoscaler
  - EBS CSI Driver
  - Pod Security Policy

#### Monitoring & Observabilité
- **CloudWatch** :
  - Dashboard EKS
  - Log Groups (cluster, WAF)
  - Alarms (CPU > 80%, Memory > 80%)
  - SNS Topic pour alertes
- **Prometheus + Grafana** :
  - Namespace `monitoring`
  - Storage 20Gi pour Prometheus
  - Storage 10Gi pour Grafana
  - Dashboards pré-configurés
- **Jaeger** (Distributed Tracing) :
  - Namespace `observability`
  - Elasticsearch pour stockage
  - UI accessible via LoadBalancer

---

## 📝 Étapes de Déploiement

### 1️⃣ Configuration AWS

```bash
# Vérifier l'identité AWS
aws sts get-caller-identity

# Configurer la région (adapter selon votre besoin)
aws configure set region eu-west-1

# Vérifier la configuration
aws configure list
```

### 2️⃣ Déploiement de l'Infrastructure Terraform

```bash
# Se placer dans le dossier terraform
cd terraform

# Initialiser Terraform (télécharge les providers et modules)
terraform init

# Valider la configuration
terraform validate

# Visualiser le plan de déploiement (optionnel)
terraform plan

# Appliquer l'infrastructure (102 ressources)
# ⚠️ Durée estimée : 15-20 minutes
terraform apply -auto-approve

# Sauvegarder les outputs
terraform output > ../outputs.txt
```

### 3️⃣ Configuration de kubectl

```bash
# Retour au dossier racine
cd ..

# Configurer kubectl pour accéder au cluster
aws eks update-kubeconfig --region eu-west-1 --name eks-bfs-gp12

# Vérifier l'accès au cluster
kubectl get nodes
kubectl get namespaces
```

### 4️⃣ Déploiement d'Online Boutique

```bash
# Exécuter le script de déploiement
./deploy-online-boutique.sh

# Le script va :
# - Créer le namespace online-boutique
# - Déployer les 11 microservices
# - Configurer les HPA (Horizontal Pod Autoscalers)
# - Appliquer les Network Policies
```

### 5️⃣ Vérification du Déploiement

```bash
# Vérifier les pods (peut prendre 5-10 minutes)
kubectl get pods -n online-boutique

# Attendre que tous les pods soient Ready
kubectl wait --for=condition=Ready pods --all -n online-boutique --timeout=600s

# Vérifier les services
kubectl get svc -n online-boutique

# Vérifier les HPA
kubectl get hpa -n online-boutique
```

### 6️⃣ Exposition du Frontend

```bash
# Option 1 : Via LoadBalancer AWS (recommandé pour la production)
kubectl patch svc frontend-external -n online-boutique -p '{"spec":{"type":"LoadBalancer"}}'

# Attendre que le LoadBalancer soit provisionné (2-3 minutes)
kubectl get svc frontend-external -n online-boutique -w

# Récupérer l'URL du frontend
export FRONTEND_URL=$(kubectl get svc frontend-external -n online-boutique -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "🌐 Frontend URL: http://$FRONTEND_URL"

# Option 2 : Via Port-Forward (développement local)
kubectl port-forward -n online-boutique svc/frontend-external 8080:80
# Accès : http://localhost:8080
```

### 7️⃣ Accès aux Outils de Monitoring

#### Grafana (Prometheus Stack)

```bash
# Récupérer le service Grafana
kubectl get svc -n monitoring kube-prometheus-stack-grafana

# Port-forward pour accéder à Grafana
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# Accès : http://localhost:3000
# Username : admin
# Password : admin123 (défini dans terraform.tfvars)
```

#### Jaeger (Distributed Tracing)

```bash
# Récupérer l'URL du LoadBalancer Jaeger
kubectl get svc -n observability jaeger-query

# Ou via port-forward
kubectl port-forward -n observability svc/jaeger-query 16686:16686

# Accès : http://localhost:16686
```

#### CloudWatch Dashboard

```bash
# Récupérer l'URL du dashboard
terraform output cloudwatch_dashboard_url

# Ou accès direct via AWS Console :
# CloudWatch > Dashboards > eks-bfs-gp12-monitoring
```

---

## 🧪 Tests de Charge

### Lancement des Tests Automatiques

```bash
# Le script lance 3 vagues de tests progressifs
./load-test.sh

# Tests effectués :
# 1. 5,000 utilisateurs (5 minutes)
# 2. 20,000 utilisateurs (10 minutes)
# 3. 50,000 utilisateurs - Black Friday (15 minutes)
```

### Monitoring Pendant les Tests

```bash
# Terminal 1 : Surveiller les pods
watch kubectl get pods -n online-boutique

# Terminal 2 : Surveiller les HPA
watch kubectl get hpa -n online-boutique

# Terminal 3 : Métriques des nodes
watch kubectl top nodes

# Terminal 4 : Métriques des pods
watch kubectl top pods -n online-boutique
```

---

## 📊 Vérifications Post-Déploiement

### Cluster Health

```bash
# Vérifier les nodes
kubectl get nodes -o wide

# Vérifier les addons
kubectl get daemonset -n kube-system
kubectl get deployment -n kube-system

# Vérifier les logs du cluster (CloudWatch)
aws logs tail /aws/eks/eks-bfs-gp12/cluster --follow
```

### Application Health

```bash
# Vérifier tous les pods
kubectl get pods -A

# Logs d'un service spécifique
kubectl logs -n online-boutique deployment/frontend -f

# Décrire un pod en erreur
kubectl describe pod -n online-boutique <pod-name>
```

### Autoscaling

```bash
# Vérifier le Cluster Autoscaler
kubectl logs -n kube-system deployment/cluster-autoscaler -f

# Vérifier les événements de scaling
kubectl get events -n online-boutique --sort-by='.lastTimestamp'
```

---

## 🔗 Liens Utiles

| Service | Commande | URL |
|---------|----------|-----|
| **Frontend** | `kubectl get svc -n online-boutique frontend-external` | `http://<LOAD_BALANCER_DNS>` |
| **Grafana** | `kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80` | `http://localhost:3000` |
| **Jaeger** | `kubectl port-forward -n observability svc/jaeger-query 16686:16686` | `http://localhost:16686` |
| **CloudWatch** | Terraform output | AWS Console |
| **Prometheus** | `kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090` | `http://localhost:9090` |

---

## 🧹 Nettoyage

### Supprimer l'Application

```bash
# Supprimer Online Boutique
kubectl delete namespace online-boutique
```

### Supprimer l'Infrastructure

```bash
# ATTENTION : Supprime toutes les ressources AWS
cd terraform
terraform destroy -auto-approve
```

### Nettoyage Manuel (si nécessaire)

Si `terraform destroy` échoue, supprimer manuellement via la console AWS :
1. LoadBalancers (EC2 > Load Balancers)
2. EKS Cluster
3. Node Groups
4. VPC et ressources réseau
5. CloudWatch Log Groups
6. KMS Keys

Filtrer par tag : `Project = bfs-gp12` ou rechercher `*eks-bfs-gp12*`

---

## ❓ Troubleshooting

### Pods en ImagePullBackOff

```bash
# Vérifier les événements
kubectl describe pod <pod-name> -n online-boutique

# Vérifier l'accès ECR (si images privées)
aws ecr get-login-password --region eu-west-1 | kubectl create secret docker-registry ecr-secret \
  --docker-server=<account-id>.dkr.ecr.eu-west-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region eu-west-1) \
  -n online-boutique
```

### LoadBalancer ne se crée pas

```bash
# Vérifier les logs du AWS Load Balancer Controller
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Vérifier les événements du service
kubectl describe svc frontend-external -n online-boutique
```

### Cluster Autoscaler ne scale pas

```bash
# Vérifier les logs
kubectl logs -n kube-system deployment/cluster-autoscaler

# Vérifier les limites des node groups
aws eks describe-nodegroup --cluster-name eks-bfs-gp12 --nodegroup-name <nodegroup-name>
```

### Terraform apply échoue

```bash
# Permissions IAM insuffisantes - vérifier les policies
aws iam list-attached-user-policies --user-name <your-username>

# Limite EIP atteinte - libérer les EIP non utilisées
aws ec2 describe-addresses --region eu-west-1
aws ec2 release-address --allocation-id <eip-id> --region eu-west-1

# Ressources orphelines - importer ou supprimer manuellement
terraform import <resource_type>.<resource_name> <resource_id>
```

---

## 📞 Support

Pour toute question ou problème :
- Consulter les logs : `kubectl logs <pod> -n <namespace>`
- Vérifier CloudWatch : AWS Console > CloudWatch > Log Groups
- Consulter la documentation officielle : [AWS EKS](https://docs.aws.amazon.com/eks/)

---

**✨ Bon déploiement ! 🚀**

