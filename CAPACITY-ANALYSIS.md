# 📊 Capacité Actuelle du Système - Black Friday Survival

**Date d'analyse**: 3 avril 2026  
**Région**: eu-west-1  
**Cluster**: eks-bfs-gp12

## 🎯 Résumé Exécutif

### Capacité Réelle Testée : **~5,000 utilisateurs concurrents**

> **⚠️ IMPORTANT**: Cette capacité a été **testée et validée**. Au-delà de 5,000 utilisateurs, le système devient instable.
> 
> Pour augmenter la capacité au-delà de 5,000 users, des modifications majeures de l'infrastructure sont nécessaires (voir section Recommandations).

### 🔴 Limite Critique Identifiée

**Ne PAS dépasser 5,000 utilisateurs concurrents** sans modifications de l'infrastructure.

---

## 📈 État Actuel du Cluster

### Noeuds Kubernetes
- **Total de noeuds**: 7 nodes (t3.medium)
- **CPU total**: 14 vCPUs (2 par node)
- **Mémoire totale**: ~27 GB (~3.8 GB par node)
- **Utilisation CPU moyenne**: 20-34% par node (au repos)
- **Utilisation mémoire moyenne**: 21-59% par node (au repos)

**⚠️ Sous charge (5000 users)** :
- CPU : 70-90% par node
- Memory : 75-95% par node
- Pods Pending : Commence à apparaître
- Latence : Augmente significativement (> 500ms)

### Pods Déployés
- **Total de pods Running**: 56 pods (au repos)
- **Frontend pods**: 7 pods (HPA: 2-20 replicas)
- **Cart service**: 15 pods (⚠️ MAX atteint, goulot d'étranglement)
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

**Capacité Frontend Réelle** :
- Avec 7 replicas : ~3,500-5,000 users ✅ Testé
- Avec 20 replicas (max) : ~7,000-10,000 users ❓ Non testé (probablement limité par Cart Service)

### Cart Service ⚠️ GOULOT D'ÉTRANGLEMENT PRINCIPAL
```
Replicas actuels: 15/15 (100% de la capacité max - SATURÉ)
Min replicas: 2
Max replicas: 15
Autoscaling triggers: CPU > 70% ET Memory > 80%
Utilisation actuelle: CPU 6% (repos), Memory 96%
```

**🔴 PROBLÈME CRITIQUE** :
- Cart service atteint son maximum (15/15 replicas) à ~5,000 users
- C'est le **goulot d'étranglement principal**
- Explique pourquoi le système casse au-delà de 5,000 users

**Solution REQUISE** :
```bash
# AVANT tout test > 5000 users :
kubectl patch hpa cartservice-hpa -n online-boutique -p '{"spec":{"maxReplicas":50}}'
```

### Currency Service
```
Replicas actuels: 5/10 (50% de la capacité max)
Utilisation CPU: 68% (proche du seuil de 70%)
```

**Status** : OK jusqu'à 8,000-10,000 users

### Product Catalog Service
```
Replicas actuels: 3/15 (20% de la capacité max)
Utilisation CPU: 70% (au seuil!)
```

**Status** : OK, scale automatiquement si besoin

---

## 📊 Capacité par Scénario (RÉVISÉ basé sur tests réels)

### Scénario 1: Configuration Actuelle (TESTÉ ET VALIDÉ ✅)
**Ressources**: 7 nodes, 56 pods  
**Frontend**: 7 replicas  
**Cart Service**: 15/15 replicas ← **GOULOT**  
**Capacité RÉELLE**: **5,000 utilisateurs concurrents**

**Symptômes à 5,000 users** :
- ✅ Frontend : Stable (7/20 replicas)
- 🔴 Cart Service : SATURÉ (15/15 replicas)
- 🟡 Currency : Proche du seuil (68% CPU)
- 🟡 Nodes : 70-90% CPU

**Verdict** : **5,000 users = Limite actuelle confirmée**

---

### Scénario 2: Après Augmentation HPA Cart (NON TESTÉ ⚠️)
**Ressources**: 10-15 nodes (avec autoscaling)  
**Frontend**: 12-15 replicas  
**Cart Service**: 30-40 replicas (après modification)  
**Capacité ESTIMÉE**: **8,000-10,000 utilisateurs concurrents**

**Pré-requis OBLIGATOIRES** :
```bash
# 1. Augmenter Cart Service HPA
kubectl patch hpa cartservice-hpa -n online-boutique -p '{"spec":{"maxReplicas":50}}'

# 2. Augmenter Checkout Service HPA (2ème goulot probable)
kubectl patch hpa checkoutservice-hpa -n online-boutique -p '{"spec":{"maxReplicas":30}}'

# 3. Augmenter max nodes du cluster (Terraform)
# Modifier terraform/main.tf : max_size = 20

# 4. Vérifier les quotas AWS
# - EIP : 5 max par région
# - EC2 Instances : Vérifier les limites
```

**Risques** :
- ⚠️ Coût AWS augmenté (~$500-800/mois)
- ⚠️ Temps de scaling plus long
- ⚠️ Possibles autres goulots non identifiés

---

### Scénario 3: Infrastructure Optimisée (NÉCESSITE REFONTE)
**Ressources**: 20-30 nodes t3.large  
**Frontend**: 30-50 replicas  
**Cart Service**: 80-100 replicas  
**Capacité ESTIMÉE**: **15,000-20,000 utilisateurs concurrents**

**Pré-requis** :
1. Migration vers instances t3.large ou t3.xlarge
2. Redis Cluster (au lieu de single instance)
3. Base de données externe (RDS, DynamoDB)
4. CDN pour assets statiques
5. API Gateway / Cache HTTP

**Coût estimé** : ~$1,200-2,000/mois

**Délai de mise en œuvre** : 2-5 jours

---

## 🚨 Goulots d'Étranglement Confirmés

### 1. 🔴 Cart Service - CRITIQUE
**Limite** : 15 replicas max (configuration actuelle)  
**Impact** : **BLOQUE à 5,000 users**  
**CPU/Memory** : Saturé à 5,000 users  
**Solution IMMÉDIATE** :
```bash
kubectl patch hpa cartservice-hpa -n online-boutique -p '{"spec":{"maxReplicas":50}}'
```

### 2. 🟡 Nodes Capacity - SECONDAIRE
**Limite** : 10 nodes max (configuration Terraform)  
**Impact** : Pods restent en Pending si HPA veut scaler  
**Solution** :
```hcl
# terraform/main.tf
max_size = 20  # Au lieu de 10
```

### 3. 🟡 Frontend Resources - MINEUR
**Limite** : Ressources CPU/Memory trop conservatrices  
**Impact** : Latence élevée sous forte charge  
**Solution** :
```bash
kubectl set resources deployment/frontend -n online-boutique \
  --requests=cpu=150m,memory=96Mi \
  --limits=cpu=300m,memory=192Mi
```

---

## 💡 Plan d'Action pour Dépasser 5,000 Users

### Phase 1 : Modifications Rapides (15 min)

```bash
# 1. Augmenter HPA Cart Service
kubectl patch hpa cartservice-hpa -n online-boutique -p '{"spec":{"maxReplicas":50}}'

# 2. Augmenter HPA Checkout Service  
kubectl patch hpa checkoutservice-hpa -n online-boutique -p '{"spec":{"maxReplicas":30}}'

# 3. Augmenter HPA Frontend
kubectl patch hpa frontend-hpa -n online-boutique -p '{"spec":{"maxReplicas":40}}'

# 4. Augmenter HPA Currency Service
kubectl patch hpa currencyservice-hpa -n online-boutique -p '{"spec":{"maxReplicas":20}}'
```

**Capacité après modifications** : ~8,000-10,000 users (estimé)

---

### Phase 2 : Modifications Terraform (30 min)

```hcl
# terraform/main.tf - Node Group General
max_size = 20  # Au lieu de 10
desired_size = 5  # Au lieu de 2

# terraform/main.tf - Node Group Spot (économie)
max_size = 15  # Au lieu de 5
```

```bash
cd terraform
terraform apply
```

**Capacité après modifications** : ~12,000-15,000 users (estimé)

---

### Phase 3 : Optimisations (1-2 jours)

1. **Migration vers t3.large**
   - Plus de CPU/Memory par node
   - Capacité × 2

2. **Redis Cluster**
   - Actuellement : Single instance (goulot potentiel)
   - Solution : Redis Cluster ou ElastiCache

3. **Base de Données Externe**
   - Actuellement : Données en mémoire
   - Solution : RDS PostgreSQL ou DynamoDB

**Capacité après optimisations** : ~20,000-30,000 users

---

## 🧪 Tests de Charge Sécurisés

### ⚠️ RÉALITÉ TERRAIN : Limite Confirmée à 5,000 Users

**Tests effectués** :
- ✅ 2,000 users : Système stable
- ✅ 5,000 users : Limite atteinte, système à saturation
- 🔴 > 5,000 users : **ÇA CASSE** (système instable)

**Symptômes au-delà de 5,000 users** :
- 🔴 Cart Service saturé (15/15 replicas, ne peut plus scaler)
- 🔴 Pods en Pending (manque de ressources sur nodes)
- 🔴 Latency > 1000ms (SLO violé)
- 🔴 Error Rate > 5% (système défaillant)
- 🔴 Nodes CPU > 90% (throttling)

### Progression Recommandée (Après Modifications)

**⚠️ NE PAS tester au-delà de 5,000 users SANS avoir d'abord appliqué la Phase 1**

```
✅ Test 1 : 2,000 users   → Baseline validée
✅ Test 2 : 5,000 users   → Limite actuelle confirmée

------- NE PAS FRANCHIR CETTE LIGNE SANS MODIFICATIONS -------

⚠️ Test 3 : 5,500 users   → Après Phase 1, tester prudemment (+10%)
⚠️ Test 4 : 6,000 users   → Après Phase 1, observer attentivement (+20%)
⚠️ Test 5 : 7,000 users   → Après Phase 1, sous surveillance stricte (+40%)
⚠️ Test 6 : 8,000 users   → Après Phase 1 + 2, load test complet (+60%)

🔴 Test 7 : 10,000 users  → Après Phase 2 + 3, stress test (+100%)
🔴 Test 8 : 15,000 users  → Après Phase 3 complète, validation finale
```

### ⚠️ Règles de Sécurité pour Tests au-delà de 5,000 Users

**OBLIGATOIRE avant chaque test** :

1. **Grafana ouvert et surveillé** (les 4 dashboards)
2. **Quelqu'un devant l'écran** en permanence
3. **Commande d'arrêt prête** dans un terminal
4. **Backup du cluster** effectué
5. **Tests en heures creuses** (pas en production)

**Arrêter IMMÉDIATEMENT le test si** :
- Cart Service CPU > 90%
- Pods Pending > 10
- Latency p95 > 1000ms
- Error Rate > 5%
- Nodes CPU > 90%

### Surveillance Obligatoire Pendant les Tests

**Grafana Dashboards à surveiller** :

1. **Vue d'Ensemble** : CPU/Memory cluster global
2. **Infrastructure** : HPA replicas, nodes actifs
3. **Microservices** : Identifier quel service sature
4. **Performance** : Latency, Error Rate, Uptime

**Seuils d'Alerte** :

| Métrique | Warning | Critical | Action |
|----------|---------|----------|--------|
| CPU Cluster | > 70% | > 85% | Arrêter le test |
| Memory Cluster | > 70% | > 85% | Arrêter le test |
| Cart Service CPU | > 80% | > 90% | Arrêter le test |
| Latency p95 | > 500ms | > 1000ms | Arrêter le test |
| Error Rate | > 1% | > 5% | Arrêter le test |
| Pods Pending | > 5 | > 10 | Arrêter le test |

---

## 📞 Commandes d'Urgence

### Si le Système Devient Instable Pendant un Test

```bash
# 1. ARRÊTER IMMÉDIATEMENT LE TEST
sh bfs.sh
# Option 4 ou 5 : Arrêter/Nettoyer les tests

# Ou manuellement :
kubectl scale deployment loadgenerator-test-XXXXX -n online-boutique --replicas=0

# 2. Vérifier l'état des pods
kubectl get pods -n online-boutique | grep -v Running

# 3. Redémarrer les pods en erreur
kubectl rollout restart deployment -n online-boutique

# 4. Vérifier que tout revient à la normale
kubectl get hpa -n online-boutique
kubectl top nodes
```

---

## 💰 Coûts par Scénario

### Configuration Actuelle (5,000 users max)
**Coût mensuel** : ~$260-400/mois  
**Coût Black Friday (3 jours)** : ~$30-50

### Après Phase 1 (8,000-10,000 users estimés)
**Coût mensuel** : ~$350-550/mois  
**Coût Black Friday (3 jours)** : ~$50-80

### Après Phase 2 (12,000-15,000 users estimés)
**Coût mensuel** : ~$500-800/mois  
**Coût Black Friday (3 jours)** : ~$80-120

### Infrastructure Optimisée (20,000+ users)
**Coût mensuel** : ~$1,200-2,000/mois  
**Coût Black Friday (3 jours)** : ~$200-350

---

## 🎯 Recommandations pour Black Friday

### Option 1 : Rester à 5,000 Users (SÛRE)

**Avantages** :
- ✅ Configuration actuelle stable et testée
- ✅ Coût maîtrisé
- ✅ Pas de risque d'instabilité

**Inconvénients** :
- ❌ Capacité limitée
- ❌ Pas de marge de sécurité

**Actions** :
- Aucune modification nécessaire
- Mettre en place une file d'attente si > 5,000 users
- Prévoir un message "Site en forte affluence"

---

### Option 2 : Viser 8,000 Users (RISQUÉ mais POSSIBLE)

**Pré-requis OBLIGATOIRES** :
```bash
# 1. Augmenter Cart Service (goulot principal)
kubectl patch hpa cartservice-hpa -n online-boutique -p '{"spec":{"maxReplicas":50}}'

# 2. Augmenter Checkout Service
kubectl patch hpa checkoutservice-hpa -n online-boutique -p '{"spec":{"maxReplicas":30}}'

# 3. Augmenter Frontend
kubectl patch hpa frontend-hpa -n online-boutique -p '{"spec":{"maxReplicas":40}}'

# 4. Modifier Terraform pour plus de nodes
cd terraform
# Éditer main.tf : max_size = 20
terraform apply
```

**Test de Validation REQUIS** :
```bash
# Test progressif OBLIGATOIRE avant Black Friday :
sh bfs.sh
# Tester : 5500 users → OK ?
# Tester : 6000 users → OK ?
# Tester : 7000 users → OK ?
# Tester : 8000 users → OK ?
```

**Risques** :
- ⚠️ Système non testé au-delà de 5,000
- ⚠️ Autres goulots peuvent apparaître
- ⚠️ Coût AWS augmenté
- ⚠️ Temps de scaling plus long

**Recommandation** : ⚠️ **Faire des tests progressifs AVANT le vrai Black Friday**

---

### Option 3 : Infrastructure Robuste pour 15,000+ Users (NÉCESSITE REFONTE)

**Délai** : 3-7 jours de travail  
**Coût** : ~$1,200-2,000/mois

**Modifications requises** :
1. Migration vers instances t3.large ou c5.xlarge
2. Redis Cluster (ElastiCache multi-AZ)
3. Base de données RDS (au lieu de in-memory)
4. CDN CloudFront pour assets statiques
5. Application Load Balancer avec auto-scaling
6. Quotas AWS augmentés

**Recommandation** : ⚠️ **Uniquement si le Black Friday justifie l'investissement**

---

## 📊 Calcul de Capacité Révisé (Basé sur Tests Réels)

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

### Configuration Actuelle (5,000 Users MAX)

- [ ] ✅ Infrastructure stable et testée à 5,000 users
- [ ] ⚠️ Aucun test au-delà de 5,000 users effectué
- [ ] 🔴 Cart Service est le goulot principal (15/15 replicas)
- [ ] 📊 Dashboards Grafana configurés et testés
- [ ] 🚨 Alertes CloudWatch configurées
- [ ] 📋 Runbook d'incident préparé
- [ ] 👥 Équipe technique en alerte
- [ ] 🔄 Plan de rollback préparé
- [ ] 💾 Backup de configuration effectué

---

### Si Vous Voulez Tenter au-delà de 5,000 Users (RISQUÉ)

**⚠️ AVERTISSEMENT : Modifications NON testées en production**

#### Étape 1 : Préparation (OBLIGATOIRE)

```bash
# 1. Augmenter Cart Service HPA (goulot principal)
kubectl patch hpa cartservice-hpa -n online-boutique -p '{"spec":{"maxReplicas":50,"minReplicas":5}}'

# 2. Augmenter Checkout Service HPA
kubectl patch hpa checkoutservice-hpa -n online-boutique -p '{"spec":{"maxReplicas":30}}'

# 3. Augmenter Frontend HPA
kubectl patch hpa frontend-hpa -n online-boutique -p '{"spec":{"maxReplicas":40}}'

# 4. Augmenter Currency Service HPA
kubectl patch hpa currencyservice-hpa -n online-boutique -p '{"spec":{"maxReplicas":20}}'
```

#### Étape 2 : Modification Terraform (SI NÉCESSAIRE)

```bash
cd terraform
# Éditer main.tf :
#   max_size = 20 (au lieu de 10)
#   desired_size = 5 (au lieu de 2)
terraform apply
```

#### Étape 3 : Tests Progressifs (CRITIQUE)

```bash
# NE PAS sauter d'étape !

# Test A : +10% (5,500 users)
sh bfs.sh → Option 3 → 5500 users
# Surveiller Grafana pendant 20 min
# SI stable → continuer
# SI instable → ARRÊTER et rester à 5,000

# Test B : +20% (6,000 users)
sh bfs.sh → Option 3 → 6000 users
# Surveiller Grafana pendant 20 min
# SI stable → continuer
# SI instable → ARRÊTER

# Test C : +40% (7,000 users)
sh bfs.sh → Option 3 → 7000 users
# Surveiller Grafana pendant 30 min
# SI stable → continuer
# SI instable → ARRÊTER

# Test D : +60% (8,000 users)
sh bfs.sh → Option 3 → 8000 users
# Surveillance stricte
```

#### Checklist de Test

- [ ] Grafana ouvert (4 dashboards)
- [ ] Quelqu'un surveille en temps réel
- [ ] Terminal prêt avec commande d'arrêt
- [ ] Backup du cluster fait
- [ ] Test en heures creuses
- [ ] Quotas AWS vérifiés
- [ ] Plan B si ça casse

---

## 🔴 AVERTISSEMENTS IMPORTANTS

### 1. Limite Confirmée : 5,000 Users

**Le système actuel ne supporte PAS plus de 5,000 utilisateurs concurrents.**

Tests effectués et confirmés :
- ✅ 5,000 users : Fonctionne (à la limite)
- 🔴 > 5,000 users : Ça casse

### 2. Modifications Non Testées

**Toutes les suggestions pour aller au-delà de 5,000 users sont des ESTIMATIONS.**

Aucun test réel n'a été effectué avec :
- HPA Cart Service > 15 replicas
- Cluster > 7 nodes
- Charge > 5,000 users

### 3. Recommandation Officielle

**Pour Black Friday, 3 options** :

#### Option A : Sécuritaire (RECOMMANDÉ)
- Rester à **4,500 users maximum** (marge de 10%)
- File d'attente virtuelle au-delà
- Système stable garanti

#### Option B : Ambitieux (RISQUÉ)
- Appliquer Phase 1 (modifications HPA)
- Tester progressivement jusqu'à 7,000-8,000
- Risque d'instabilité
- Surveillance 24/7 requise

#### Option C : Agressif (DANGEREUX)
- Refonte complète infrastructure
- Délai : 1 semaine minimum
- Coût : ~$1,500-2,000/mois
- Tests exhaustifs requis

---

## 📊 Réalité vs Estimations

| Scénario | Estimation Initiale | Réalité Testée | Écart |
|----------|-------------------|----------------|-------|
| Config Actuelle | 5,000-8,000 | **5,000 MAX** | -37% |
| Après Phase 1 | 12,000-15,000 | **Inconnu** (non testé) | ??? |
| Après Phase 2 | 20,000-30,000 | **Inconnu** (non testé) | ??? |

**Leçon** : Les estimations théoriques sont trop optimistes. Seuls les tests réels comptent.

---

**Résumé**: 

🔴 **Capacité actuelle CONFIRMÉE : 5,000 utilisateurs concurrents**

⚠️ **Ne PAS dépasser sans modifications et tests progressifs**

✅ **Pour Black Friday : Rester à 4,500 users (marge de sécurité de 10%)**

