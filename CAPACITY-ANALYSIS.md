# 📊 Capacité Actuelle du Système - Black Friday Survival

**Date d'analyse**: 3 avril 2026  
**Région**: eu-west-1  
**Cluster**: eks-bfs-gp12

## 🎯 Résumé Exécutif

### Capacité Estimée : **~5,000 - 8,000 utilisateurs concurrent**

> **Note**: Cette estimation est basée sur les ressources actuelles et peut augmenter automatiquement grâce aux HPAs (jusqu'à 15,000+ utilisateurs avec autoscaling complet)

---

## 📈 État Actuel du Cluster

### Noeuds Kubernetes
- **Total de noeuds**: 7 nodes (t3.medium)
- **CPU total**: 14 vCPUs (2 par node)
- **Mémoire totale**: ~27 GB (~3.8 GB par node)
- **Utilisation CPU moyenne**: 20-34% par node
- **Utilisation mémoire moyenne**: 21-59% par node

### Pods Déployés
- **Total de pods Running**: 56 pods
- **Frontend pods**: 7 pods (HPA: 2-20 replicas)
- **Cart service**: 15 pods (HPA: 2-15 replicas)
- **Autres services**: 34 pods répartis

---

## 🔧 Configuration des Services Critiques

### Frontend (Point d'entrée utilisateurs)
```
Replicas actuels: 7/20 (35% de la capacité max)
Min replicas: 2
Max replicas: 20
CPU par pod: 100m requests, 200m limits
Memory par pod: 64Mi requests, 128Mi limits
Autoscaling triggers: CPU > 70% OU Memory > 80%
```

**Capacité Frontend**:
- Avec 7 replicas: ~700-1,200 requêtes/sec
- Avec 20 replicas (max): ~2,000-3,500 requêtes/sec

### Cart Service (Service le plus sollicité)
```
Replicas actuels: 15/15 (100% de la capacité max)
Min replicas: 2
Max replicas: 15
Autoscaling triggers: CPU > 70% ET Memory > 80%
Utilisation actuelle: CPU 6%, Memory 96%
```

**⚠️ ATTENTION**: Cart service est au MAX de ses replicas !  
**Recommandation**: Augmenter `maxReplicas` à 30-50 pour Black Friday

### Currency Service
```
Replicas actuels: 5/10 (50% de la capacité max)
Utilisation CPU: 68% (proche du seuil de 70%)
```

### Product Catalog Service
```
Replicas actuels: 3/15 (20% de la capacité max)
Utilisation CPU: 70% (au seuil!)
```

---

## 📊 Calcul de Capacité par Scénario

### Scénario 1: Configuration Actuelle (CONSERVATIVE)
**Ressources**: 7 nodes, 56 pods  
**Frontend**: 7 replicas  
**Capacité estimée**: **~5,000 utilisateurs concurrents**

**Hypothèses**:
- 1 utilisateur = ~10 requêtes/min
- 1 pod frontend = ~100-150 requêtes/sec max
- 7 pods × 100 req/sec = 700 req/sec
- 700 req/sec ÷ 10 req/min/user = ~4,200 users
- Avec buffer: **~5,000 users concurrents**

### Scénario 2: Autoscaling Partiel (RÉALISTE)
**Ressources**: 10 nodes (autoscaling), ~80 pods  
**Frontend**: 12 replicas  
**Capacité estimée**: **~8,000 utilisateurs concurrents**

**Avec autoscaling**:
- Frontend scale à 12 replicas
- Cart service augmenté à 30 replicas (si modifié)
- Cluster autoscaler ajoute 3 nodes
- **~8,000 users concurrents**

### Scénario 3: Configuration Maximale (OPTIMISTE)
**Ressources**: 15-20 nodes, ~150 pods  
**Frontend**: 20 replicas (max actuel)  
**Capacité estimée**: **~15,000+ utilisateurs concurrents**

**Avec configuration optimale**:
- Frontend à 20 replicas
- Cart service à 50 replicas (après modification HPA)
- Tous les services scalés
- **~15,000-20,000 users concurrents**

---

## 🚨 Goulots d'Étranglement Identifiés

### 1. Cart Service ⚠️ CRITIQUE
- **Status**: SATURÉ (15/15 replicas)
- **Impact**: Limite majeure sur la capacité
- **Solution**: Augmenter `maxReplicas` de 15 à 50

### 2. Currency Service ⚠️ ATTENTION
- **Status**: CPU à 68% (proche du seuil)
- **Impact**: Va scaler bientôt
- **Solution**: Surveiller et éventuellement augmenter les resources

### 3. Product Catalog ⚠️ ATTENTION  
- **Status**: CPU à 70% (au seuil)
- **Impact**: Scaling imminent
- **Solution**: OK, HPA va gérer

### 4. Nodes Capacity
- **Status**: 97% CPU allocated sur certains nodes
- **Impact**: Pods ne peuvent plus être schedulés
- **Solution**: Cluster Autoscaler va ajouter des nodes automatiquement

---

## 💡 Recommandations pour Augmenter la Capacité

### Action Immédiate (5 min)
```bash
# 1. Augmenter les replicas max du Cart Service
kubectl patch hpa cartservice-hpa -n online-boutique -p '{"spec":{"maxReplicas":50}}'

# 2. Augmenter les replicas max des services critiques
kubectl patch hpa currencyservice-hpa -n online-boutique -p '{"spec":{"maxReplicas":20}}'
kubectl patch hpa productcatalogservice-hpa -n online-boutique -p '{"spec":{"maxReplicas":25}}'
kubectl patch hpa checkoutservice-hpa -n online-boutique -p '{"spec":{"maxReplicas":30}}'
```

**Impact**: Capacité passe de ~5,000 à ~12,000 users

### Action Court Terme (30 min)
```bash
# 3. Augmenter le max nodes du cluster via Terraform
# Dans terraform/main.tf, modifier:
# max_size = 20 (au lieu de 10)

cd terraform
terraform apply -target=module.eks

# 4. Augmenter les resources du frontend
kubectl set resources deployment/frontend -n online-boutique \
  --requests=cpu=150m,memory=96Mi \
  --limits=cpu=300m,memory=192Mi
```

**Impact**: Capacité passe à ~15,000-20,000 users

### Action Moyen Terme (1-2h)
1. **Optimiser les images Docker**
   - Réduire la taille des images
   - Optimiser le startup time

2. **Ajouter du caching**
   - Redis pour les données fréquemment accédées
   - CDN pour les assets statiques

3. **Utiliser des instances plus puissantes**
   - Remplacer t3.medium par t3.large/t3.xlarge
   - Capacité × 2-4

**Impact**: Capacité passe à ~30,000-50,000 users

---

## 📏 Métriques Actuelles de Performance

### Latence Moyenne
- **Frontend**: ~50-100ms
- **Cart Service**: ~20-40ms
- **Product Catalog**: ~30-60ms

### Throughput Actuel
- **Requêtes/sec**: ~200-400 req/sec
- **Utilisateurs actifs**: ~1,500-2,500 users
- **Marge disponible**: ~3,000-5,000 users supplémentaires

### Taux d'Erreur
- **5xx Errors**: < 0.1%
- **Timeouts**: < 0.5%
- **Status**: ✅ Système stable

---

## 🎯 Configuration Recommandée pour Black Friday

### Objectif: Support de 20,000 utilisateurs concurrents

```yaml
# Nouvelle configuration HPA recommandée
Frontend:
  minReplicas: 5
  maxReplicas: 50
  targetCPU: 60%

CartService:
  minReplicas: 5
  maxReplicas: 100
  targetCPU: 60%

CurrencyService:
  minReplicas: 3
  maxReplicas: 30
  targetCPU: 60%

ProductCatalog:
  minReplicas: 3
  maxReplicas: 40
  targetCPU: 60%

CheckoutService:
  minReplicas: 3
  maxReplicas: 50
  targetCPU: 60%
```

### Node Groups
```hcl
general_node_group:
  min_size: 5
  max_size: 30
  desired_size: 10
  instance_type: t3.large  # Upgrade depuis t3.medium

spot_node_group:
  min_size: 0
  max_size: 20
  desired_size: 5
```

**Coût estimé**: ~$300-500/mois en temps normal, ~$800-1200 pendant Black Friday (3 jours)

---

## 🧪 Tests de Charge Recommandés

### Test 1: Baseline (Actuel)
```bash
./bfs.sh
# Option 3: Lancer test de charge
# Users: 5000
# Duration: 30 min
```

**Résultat attendu**: Système stable, CPU ~70-80%

### Test 2: Peak Load
```bash
# Users: 10000
# Duration: 60 min
```

**Résultat attendu**: Autoscaling actif, quelques latences

### Test 3: Stress Test
```bash
# Users: 15000+
# Duration: 30 min
```

**Résultat attendu**: Identifier les limites réelles

---

## 📞 Monitoring et Alertes

### Métriques à Surveiller
1. **CPU Utilization** > 80% sur les pods
2. **Memory Utilization** > 85% sur les pods
3. **Request Latency** > 500ms (p95)
4. **Error Rate** > 1%
5. **Pod Pending** (nodes insuffisants)

### Dashboards
```bash
# Grafana (monitoring)
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# CloudWatch
# AWS Console > CloudWatch > Dashboards > eks-bfs-gp12
```

---

## ✅ Checklist Pre-Black Friday

- [ ] Augmenter maxReplicas de cart-service à 50+
- [ ] Augmenter maxReplicas de frontend à 30+
- [ ] Augmenter max_size du node group à 20+
- [ ] Tester avec 10,000 utilisateurs simulés
- [ ] Vérifier que les alertes CloudWatch fonctionnent
- [ ] Configurer un runbook d'incident
- [ ] Prévoir une astreinte technique
- [ ] Tester le rollback rapide
- [ ] Backup de la base de données
- [ ] Augmenter les quotas AWS si nécessaire

---

**Résumé**: Actuellement ~**5,000 users**, facilement extensible à **15,000-20,000 users** avec quelques ajustements HPA. Pour supporter 50,000+ users, migration vers instances plus grandes recommandée.

