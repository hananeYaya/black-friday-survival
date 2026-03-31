# Black Friday Survival - Online Boutique sur EKS

## 🎯 Projet

Déploiement d'Online Boutique (11 microservices de Google) sur AWS EKS pour simuler un environnement Black Friday.

## 📦 Architecture

### Microservices (11 services)
1. **frontend** - Interface utilisateur web
2. **cartservice** - Gestion du panier
3. **productcatalogservice** - Catalogue des produits
4. **currencyservice** - Conversion de devises
5. **paymentservice** - Traitement des paiements
6. **shippingservice** - Calcul des frais d'expédition
7. **emailservice** - Envoi d'emails
8. **checkoutservice** - Processus de checkout
9. **recommendationservice** - Recommandations produits
10. **adservice** - Publicités
11. **loadgenerator** - Générateur de charge

### Infrastructure AWS
- **EKS Cluster** (Kubernetes 1.29)
- **VPC** avec subnets publics et privés sur 3 AZ
- **3 Node Groups** :
  - General (t3.medium, 2-10 nodes) - ON_DEMAND
  - High Memory (t3.large, 0-5 nodes) - ON_DEMAND pour pics de charge
  - Spot (t3.medium/t3a.medium, 0-5 nodes) - SPOT pour économies
- **Single NAT Gateway** (1 EIP seulement)
- **CloudWatch** monitoring + alertes
- **Cluster Autoscaler** - Scaling automatique
- **AWS Load Balancer Controller** - Ingress/ALB
- **Metrics Server** - Métriques Kubernetes

## 🚀 Déploiement

### Étape 1 : Déployer l'infrastructure EKS

```bash
cd terraform

# Initialiser Terraform
terraform init

# Voir le plan
terraform plan

# Déployer l'infrastructure (15-20 minutes)
terraform apply -auto-approve
```

### Étape 2 : Installer les addons Kubernetes

```bash
# Depuis le dossier terraform
./deploy-addons.sh
```

### Étape 3 : Déployer Online Boutique

```bash
# Revenir au dossier racine
cd ..

# Déployer les 11 microservices
./deploy-online-boutique.sh
```

### Étape 4 : Exposer le frontend

```bash
# Créer un Load Balancer AWS pour le frontend
kubectl patch svc frontend-external -n online-boutique -p '{"spec":{"type":"LoadBalancer"}}'

# Attendre que le Load Balancer soit créé
kubectl get svc frontend-external -n online-boutique -w
```

## 🔍 Vérification

```bash
# Voir tous les pods Online Boutique
kubectl get pods -n online-boutique

# Voir les services
kubectl get svc -n online-boutique

# Voir les logs d'un service
kubectl logs -f deployment/frontend -n online-boutique

# Obtenir l'URL du frontend
kubectl get svc frontend-external -n online-boutique -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## 📊 Monitoring

```bash
# Voir les métriques des nodes
kubectl top nodes

# Voir les métriques des pods
kubectl top pods -n online-boutique

# Voir les logs du cluster autoscaler
kubectl logs -f deployment/cluster-autoscaler -n kube-system

# Dashboard CloudWatch
# Ouvrir la console AWS CloudWatch -> Dashboards -> eks-bfs-gp12-monitoring
```

## 🧪 Test de charge

```bash
# Le loadgenerator envoie automatiquement du trafic
# Pour augmenter la charge :
kubectl scale deployment loadgenerator -n online-boutique --replicas=5
```

## 🗑️ Nettoyage

```bash
# Supprimer Online Boutique
kubectl delete namespace online-boutique

# Attendre que les Load Balancers soient supprimés
sleep 60

# Supprimer les addons (si nécessaire)
helm uninstall aws-load-balancer-controller -n kube-system

# Détruire l'infrastructure
cd terraform
terraform destroy -auto-approve
```

## 🏷️ Tags

Toutes les ressources AWS sont taggées avec :
- **Project** = bfs-gp12
- **Environment** = prod
- **ManagedBy** = Terraform
- **Name** = eks-bfs-gp12-*

## 📝 Notes

- Le cluster utilise **1 seul NAT Gateway** pour éviter les limites EIP (5 max par région)
- Les node groups utilisent **t3.medium** et **t3.large** (éligibles au free tier)
- Le **Spot node group** peut économiser jusqu'à 70% de coûts
- **Cluster Autoscaler** scale automatiquement selon la charge
- **CloudWatch** monitore le CPU et la mémoire avec alertes SNS

