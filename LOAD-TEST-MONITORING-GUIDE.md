# 🧪 Guide de Test de Charge - Monitoring Grafana

## 🎯 Objectif

Ce guide vous accompagne dans le monitoring d'un test de charge avec les dashboards Grafana.

---

## 📋 Informations Générales sur les Tests de Charge

### 🔧 Outil Utilisé : Locust (via LoadGenerator)

**Solution actuelle** : **Locust** packagé dans le LoadGenerator de Google
- **Image Docker** : `gcr.io/google-samples/microservices-demo/loadgenerator:v0.10.1`
- **Technologie** : **Locust** (outil de test de charge Python)
- **Packaging** : Conteneur Docker pré-configuré par Google pour Online Boutique
- **Déploiement** : Pods Kubernetes temporaires via script `bfs.sh`
- **Configuration** : Via variables d'environnement (FRONTEND_ADDR, USERS)
- **Avantage** : Pas besoin d'installer/configurer Locust manuellement ✅

**En résumé** : C'est bien **Locust**, mais emballé dans un conteneur prêt à l'emploi !

### 👥 Capacité Utilisateurs Supportés

| Configuration | Utilisateurs Concurrents | Status |
|--------------|-------------------------|---------|
| **Minimal** (7 nodes, 56 pods) | ~**5,000 users** | ✅ Testé et stable |
| **Autoscaling** (10 nodes, ~80 pods) | ~**8,000-15,000 users** | ⚡ Avec HPA actif |
| **Black Friday** (30 nodes optimisés) | ~**20,000 users** | 🎯 Configuration recommandée |

**Référence** : Voir `CAPACITY-ANALYSIS.md` pour les détails de calcul.

### 💰 Coûts AWS Estimés

| Période | Configuration | Coût Estimé |
|---------|--------------|-------------|
| **Normal** (mensuel) | 7 nodes t3.medium | ~$469/mois (~€438) |
| **Black Friday** (3 jours) | 15-20 nodes t3.large + Spot | ~$442 (~€413) |
| **Annuel** | Temps normal + pics | ~$6,670 (~€6,229) |
| **Optimisé** | Avec Spot + Reserved Instances | ~$4,000/an (~€3,740) |

**Détails coûts** : Voir `CAPACITY-ANALYSIS.md` ligne 250.

---

## 📊 Configuration Multi-Dashboard

### Setup Recommandé

Ouvrez **4 onglets** dans votre navigateur :

| Onglet | Dashboard | URL |
|--------|-----------|-----|
| 1 | **Vue d'Ensemble** | http://localhost:3000/d/black-friday-overview |
| 2 | **Infrastructure** | http://localhost:3000/d/black-friday-infrastructure |
| 3 | **Performance & SLOs** | http://localhost:3000/d/black-friday-performance |
| 4 | **Microservices** | http://localhost:3000/d/black-friday-microservices |

> 💡 **Astuce** : Utilisez un écran large ou plusieurs écrans pour tout afficher simultanément.

---

## 🔄 Workflow Étape par Étape

### **Avant le Test** (T-5 min)

#### 1. Lancer Grafana
```bash
sh access-grafana.sh
```

#### 2. Ouvrir les 4 dashboards (4 onglets)

#### 3. Baseline - Noter les métriques au repos
- **Dashboard Vue d'Ensemble** :
  - [ ] CPU Cluster : _____%
  - [ ] Memory Cluster : _____%
  - [ ] Pods Running : _____
  
- **Dashboard Infrastructure** :
  - [ ] HPA Replicas par service : _____
  - [ ] Nodes actifs : _____

- **Dashboard Performance** :
  - [ ] Latency p95 baseline : _____ ms
  - [ ] Throughput baseline : _____ req/s

---

### **Pendant le Test** (T0 → Tn)

#### 📍 Étape 1 : Lancer le Test de Charge
```bash
# Dans un nouveau terminal
sh load-test.sh

# Ou avec paramètres custom
USERS=100 DURATION=300 sh load-test.sh
```

#### 📍 Étape 2 : Surveillance Continue (ordre de priorité)

##### **Tab 1 : Vue d'Ensemble** (Vérification toutes les 30s)

**🟢 Indicateurs Sains :**
- CPU Cluster < 70% (🟡) ou < 85% (🔴)
- Memory Cluster < 70% (🟡) ou < 85% (🔴)
- Tous les pods "Running"
- Aucun restart

**🔴 Alertes :**
```
SI CPU > 85% → Risque de throttling
SI Memory > 85% → Risque d'OOMKill
SI Pods Pending > 0 → Manque de ressources
SI Restarts > 0 → Service instable
```

##### **Tab 2 : Infrastructure** (Vérification toutes les 1-2 min)

**🟢 Indicateurs Sains :**
- HPA Current Replicas augmente progressivement
- HPA Current = Desired (pas de lag)
- CPU/Memory Nodes < 80%

**🔴 Alertes :**
```
SI HPA Current < Desired pendant >2min → HPA lent ou pas de place
SI Nodes CPU > 85% → Besoin de plus de nodes
SI Allocation % > 85% → Cluster proche de la saturation
```

**📊 Ce qu'on veut voir :**
```
Début du test (T+1min) :
├─ HPA détecte la charge
├─ Desired replicas augmente (ex: 1 → 3)
├─ Current replicas suit (ex: 1 → 2 → 3)
└─ CPU nodes reste < 80%

Milieu du test (T+5min) :
├─ HPA stabilisé (current = desired)
├─ CPU distribué entre les replicas
└─ Pas de nouvelle création de pods

Fin du test (T+10min après arrêt) :
├─ HPA commence le scale down
├─ Desired replicas diminue
└─ Pods se terminent proprement
```

##### **Tab 3 : Performance & SLOs** (Vérification continue)

**🎯 SLOs à Respecter :**

| SLO | Target | Warning | Critical |
|-----|--------|---------|----------|
| **Uptime** | > 99.9% | < 99.5% | < 99% |
| **Latency p95** | < 500ms | > 300ms | > 500ms |
| **Error Rate** | < 1% | > 0.5% | > 1% |

**🔴 Alertes :**
```
SI Latency p95 > 500ms → Service trop lent
SI Error Rate > 1% → Problème applicatif
SI Uptime < 99.9% → Service instable
SI Throttling > 1% → CPU limité
```

**📊 Graphiques à Observer :**
- **Latency par Service** : Identifier quel service ralentit
- **Throughput** : Vérifier que ça monte avec la charge
- **Error Rate** : Doit rester proche de 0%

##### **Tab 4 : Microservices** (Consultation si problème détecté)

**🔍 Utiliser SI :**
- Un service a une latency élevée → Regarder son CPU/Memory
- Des erreurs apparaissent → Identifier quel service
- Redis semble lent → Vérifier cache saturation

**📊 Détails par Service :**
```
Frontend :
├─ CPU doit être < 80%
├─ Memory croissance linéaire (pas de fuite)
└─ Network I/O élevé (normal, c'est le point d'entrée)

Backend Services :
├─ CPU proportionnel au nombre de requêtes
├─ Memory stable
└─ Network I/O modéré

Redis :
├─ CPU < 50% (Redis est mono-thread)
├─ Memory croissante (normal, c'est un cache)
└─ Network I/O élevé (normal, beaucoup de read/write)
```

---

### **Après le Test** (T+15 min)

#### 📍 Analyse des Résultats

##### 1. Vérifier le Scale Down (Dashboard Infrastructure)
```
✓ HPA a commencé à réduire les replicas ?
✓ Retour à la baseline (1 replica par service) ?
✓ Temps de scale down : _____ minutes
```

##### 2. Vérifier les SLOs (Dashboard Performance)
```
✓ Uptime moyen pendant le test : _____%
✓ Latency p95 max : _____ ms
✓ Error Rate max : _____%
✓ Throughput max atteint : _____ req/s
```

##### 3. Identifier les Bottlenecks (Dashboard Microservices)
```
Service le plus chargé (CPU) : __________
Service le plus lent (Latency) : __________
Service avec le plus d'erreurs : __________
```

##### 4. Analyser les Nodes (Dashboard Infrastructure)
```
Nodes max utilisés : _____
CPU max d'un node : _____%
Memory max d'un node : _____%
Besoin d'ajouter des nodes ? OUI / NON
```

---

## 📈 Métriques Clés par Phase de Test

### Phase 1 : Montée en Charge (0 → 2 min)

| Métrique | Attendu | Dashboard |
|----------|---------|-----------|
| HPA Desired | Augmente | Infrastructure |
| Latency p95 | +50-100ms | Performance |
| CPU Nodes | +30-50% | Infrastructure |
| Throughput | Linéaire | Performance |

### Phase 2 : Plateau (2 → 8 min)

| Métrique | Attendu | Dashboard |
|----------|---------|-----------|
| HPA Replicas | Stable | Infrastructure |
| Latency p95 | Stable | Performance |
| CPU Nodes | Stable | Infrastructure |
| Error Rate | < 1% | Performance |

### Phase 3 : Descente (8 → 15 min)

| Métrique | Attendu | Dashboard |
|----------|---------|-----------|
| HPA Desired | Diminue | Infrastructure |
| Latency p95 | Retour baseline | Performance |
| CPU Nodes | Diminue | Infrastructure |
| Throughput | Diminue | Performance |

---

## 🚨 Alertes et Actions

### Alerte Critique : CPU > 85%

**Dashboard** : Vue d'Ensemble + Infrastructure

**Actions** :
1. Vérifier HPA : Scale en cours ?
2. Si HPA bloqué → Manque de nodes → Augmenter `max_size` du node group
3. Si nodes saturés → Cluster trop petit

```bash
# Vérifier HPA
kubectl get hpa -n online-boutique

# Forcer un scale si besoin
kubectl scale deployment frontend -n online-boutique --replicas=5
```

---

### Alerte Critique : Latency > 500ms

**Dashboard** : Performance & SLOs

**Actions** :
1. Dashboard Microservices → Identifier le service lent
2. Vérifier si le service a scalé (HPA)
3. Vérifier CPU/Memory du service

```bash
# Vérifier les ressources d'un service
kubectl top pods -n online-boutique | grep frontend
```

---

### Alerte Critique : Error Rate > 1%

**Dashboard** : Performance & SLOs

**Actions** :
1. Dashboard Microservices → Identifier le service en erreur
2. Consulter les logs

```bash
# Voir les logs d'erreur
kubectl logs -n online-boutique -l app=frontend --tail=50 | grep -i error
```

---

### Alerte Warning : Pods Pending

**Dashboard** : Vue d'Ensemble

**Actions** :
1. Dashboard Infrastructure → Vérifier Allocation %
2. Si > 90% → Cluster plein → Besoin de scale les nodes

```bash
# Vérifier les pods en attente
kubectl get pods -n online-boutique -o wide | grep Pending

# Voir la raison
kubectl describe pod <pod-name> -n online-boutique
```

---

## 📊 Template de Rapport de Test

```markdown
# Rapport de Test de Charge - [Date]

## Configuration du Test
- **Utilisateurs simulés** : _____
- **Durée** : _____ minutes
- **Montée en charge** : _____ sec
- **Endpoint testé** : _____

## Résultats SLOs

| SLO | Target | Résultat | Status |
|-----|--------|----------|--------|
| Uptime | > 99.9% | _____ % | ✅ / ❌ |
| Latency p95 | < 500ms | _____ ms | ✅ / ❌ |
| Error Rate | < 1% | _____ % | ✅ / ❌ |

## Autoscaling

| Service | Replicas Initiales | Replicas Max | Scale Time |
|---------|-------------------|--------------|------------|
| frontend | 1 | _____ | _____ sec |
| cartservice | 1 | _____ | _____ sec |
| productcatalog | 1 | _____ | _____ sec |

## Ressources Cluster

| Métrique | Baseline | Peak | Notes |
|----------|----------|------|-------|
| CPU Cluster | _____ % | _____ % | |
| Memory Cluster | _____ % | _____ % | |
| Nodes Actifs | _____ | _____ | |
| Pods Total | _____ | _____ | |

## Bottlenecks Identifiés

1. __________
2. __________
3. __________

## Recommandations

- [ ] Augmenter les limites HPA ?
- [ ] Optimiser le service _____ (CPU élevé)
- [ ] Ajouter des nodes au cluster ?
- [ ] Tuning de Redis ?
```

---

## 🎯 Checklist Complète

### Avant le Test
- [ ] Grafana accessible (http://localhost:3000)
- [ ] 4 dashboards ouverts en onglets
- [ ] Baseline notée
- [ ] Cluster stable (pas de pods Pending/CrashLoop)
- [ ] HPA configurés (`kubectl get hpa -n online-boutique`)

### Pendant le Test
- [ ] Vue d'Ensemble : CPU/Memory < 85%
- [ ] Infrastructure : HPA scale correctement
- [ ] Performance : SLOs respectés
- [ ] Microservices : Aucun service saturé

### Après le Test
- [ ] Scale down complété
- [ ] Rapport de test rempli
- [ ] Bottlenecks identifiés
- [ ] Actions d'amélioration définies

---

## 💡 Astuces Pro

### 1. Time Range Synchronisé
Dans Grafana, synchronisez le time range de tous les dashboards :
- Cliquez sur l'horloge en haut à droite
- Sélectionnez la durée du test (ex: Last 15 minutes)

### 2. Rafraîchissement Automatique
Les dashboards rafraîchissent toutes les 30s automatiquement.

### 3. Zoomer sur un Pic
Cliquez-glissez sur un graphique pour zoomer sur une période spécifique.

### 4. Exporter un Dashboard
**Share** → **Export** → **Save to file** pour conserver un snapshot.

### 5. Alertes Temps Réel
Configurez des alertes Grafana pour recevoir des notifications automatiques.

---

## 🔗 Liens Rapides

- **Accès Grafana** : `sh access-grafana.sh`
- **Menu principal** : `sh bfs.sh`
- **Voir les pods** : `kubectl get pods -n online-boutique`
- **Voir les HPA** : `kubectl get hpa -n online-boutique`

---

## 🎪 Scénarios de Tests Recommandés

### Test 1 : Baseline (5,000 utilisateurs)
```bash
./bfs.sh
# Option 3: Lancer test de charge
# Entrer: 5000
```

**Objectif** : Vérifier la stabilité actuelle
- Durée : 30 minutes
- Résultat attendu : CPU ~70-80%, Latency p95 < 300ms, Error Rate < 0.5%

### Test 2 : Peak Load (10,000 utilisateurs)
```bash
./bfs.sh
# Option 3: Lancer test de charge
# Entrer: 10000
```

**Objectif** : Tester l'autoscaling
- Durée : 60 minutes
- Résultat attendu : HPA actif, CPU pics à ~85%, Latency p95 < 500ms

### Test 3 : Black Friday Stress (20,000 utilisateurs)
```bash
./bfs.sh
# Option 3: Lancer test de charge
# Entrer: 20000
```

**Objectif** : Identifier les limites réelles
- Durée : 30 minutes
- Configuration requise : Augmenter maxReplicas des HPAs avant le test
- Résultat attendu : Configuration maximale, tous les HPAs actifs

---

## 📚 Documentation Complémentaire

- **CAPACITY-ANALYSIS.md** : Analyse détaillée de la capacité et calculs
- **FIX-LOAD-TEST-ISSUE.md** : Résolution problèmes Pod Security Standards
- **DEPLOYMENT-GUIDE.md** : Infrastructure et coûts détaillés
- **GRAFANA-GUIDE.md** : Configuration Grafana et dashboards

---

**🎉 Vous êtes prêt pour votre test de charge !**

Bon monitoring ! 📊🚀

