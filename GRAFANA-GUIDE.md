# 📊 Guide d'Accès et Vérification Grafana

## 🎯 Informations de Connexion

| Paramètre | Valeur |
|-----------|--------|
| **URL** | `http://localhost:3000` (après port-forward) |
| **Username** | `admin` |
| **Password** | `BlackFriday2024!` (récupéré automatiquement via script) |
| **Namespace** | `monitoring` |
| **Service** | `kube-prometheus-stack-grafana` |

---

## ✅ Étape 1 : Accès Rapide avec le Script

```bash
# Utiliser le script automatisé
sh access-grafana.sh

# Le script va :
# ✓ Vérifier que Grafana est déployé
# ✓ Récupérer automatiquement le mot de passe
# ✓ Afficher les credentials
# ✓ Lancer le port-forward
```

---

## 🔌 Étape 2 : Accès Manuel (optionnel)

Si vous préférez l'accès manuel :

```bash
# Vérifier le service Grafana
kubectl get svc -n monitoring kube-prometheus-stack-grafana

# Vérifier les pods Grafana
kubectl get pods -n monitoring | grep grafana

# Récupérer le mot de passe
kubectl get secret -n monitoring kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
echo

# Créer le port-forward
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
```

---

## 📊 Étape 3 : Dashboards Pré-installés

### Dashboards Disponibles

Une fois connecté, cliquez sur :
1. **Menu hamburger** (☰) en haut à gauche
2. **Dashboards** → **Browse**
3. **Dossier "Black Friday Survival"**

Vous verrez **4 dashboards professionnels** :

| Dashboard | Description | Métriques Clés |
|-----------|-------------|----------------|
| **🎯 Black Friday - Vue d'Ensemble** | Vision globale du système | CPU/Memory cluster, Pods status, Replicas |
| **🔧 Black Friday - Microservices** | Détails par service | Frontend, Backend, Redis, Network I/O |
| **🏗️ Black Friday - Infrastructure** | Nodes & Autoscaling | Nodes resources, HPA, Capacity planning |
| **⚡ Black Friday - Performance & SLOs** | SLOs & Performance | Availability, Latency, Throughput, Errors |

---

## 📈 Dashboard 1 : Vue d'Ensemble

**Objectif** : Vision rapide de la santé globale du système

### Panneaux Principaux

| Panneau | Métrique | Seuils |
|---------|----------|--------|
| **CPU Cluster Global** | Utilisation CPU moyenne | 🟢 <70% / 🟡 70-85% / 🔴 >85% |
| **Mémoire Cluster Global** | Utilisation mémoire moyenne | 🟢 <70% / 🟡 70-85% / 🔴 >85% |
| **État des Pods** | Running / Pending / Failed | Running = vert |
| **CPU par Pod** | Détail par pod online-boutique | Identifier les pics |
| **Mémoire par Pod** | Détail par pod online-boutique | Détecter les fuites mémoire |
| **Pods Running** | Nombre total Running | Vert si > 0 |
| **Pods avec Restarts** | Nombre de pods redémarrés | 🟢 0 / 🟡 1-5 / 🔴 >5 |
| **Nodes Total** | Nombre de nodes actifs | Info |
| **Replicas par Deployment** | Replicas par service | Info |

### Utilisation

✅ **Morning Check** : Vérifier que tous les gauges sont verts  
✅ **Incident** : Identifier rapidement le service problématique  
✅ **Load Test** : Suivre l'évolution des pods

---

## 🔧 Dashboard 2 : Microservices

**Objectif** : Monitoring détaillé de chaque microservice

### Sections

#### 1️⃣ Frontend & Load Generator
- CPU Usage Frontend
- Memory Usage Frontend

#### 2️⃣ Backend Services
- CPU Usage tous les services backend
- Memory Usage tous les services backend
- Filtrage automatique : `adservice`, `cartservice`, `checkoutservice`, `currencyservice`, `emailservice`, `paymentservice`, `productcatalogservice`, `recommendationservice`, `shippingservice`

#### 3️⃣ Database & Cache (Redis)
- Redis CPU Usage
- Redis Memory Usage

#### 4️⃣ Network Activity
- Network I/O par pod (transmit / receive)

### Utilisation

✅ **Identifier les bottlenecks** : Quel service consomme le plus ?  
✅ **Vérifier Redis** : Cache surchargé ?  
✅ **Network saturation** : Quel service génère le plus de trafic ?

---

## 🏗️ Dashboard 3 : Infrastructure

**Objectif** : Monitoring des nodes et autoscaling

### Sections

#### 1️⃣ Nodes Overview
- **CPU Usage par node** : 🟢 <70% / 🟡 70-85% / 🔴 >85%
- **Memory Usage par node** : 🟢 <70% / 🟡 70-85% / 🔴 >85%
- **Disk Usage** : Espace disque restant
- **Network I/O** : Transfert réseau par node

#### 2️⃣ Horizontal Pod Autoscaler (HPA)
- **Replicas (Current vs Desired vs Min/Max)** : Graphique montrant l'évolution de l'autoscaling
- **CPU Target Utilization** : % CPU actuel vs target HPA

#### 3️⃣ Cluster Capacity
- **Total CPU Allocatable** : CPU total disponible
- **Total Memory Allocatable** : Mémoire totale disponible
- **CPU Requested (online-boutique)** : CPU demandé par l'app
- **Memory Requested (online-boutique)** : Mémoire demandée par l'app
- **CPU Allocation %** : 🟢 <70% / 🟡 70-85% / 🔴 >85%
- **Memory Allocation %** : 🟢 <70% / 🟡 70-85% / 🔴 >85%

### Utilisation

✅ **Vérifier HPA** : L'autoscaling fonctionne ?  
✅ **Capacity Planning** : Besoin d'ajouter des nodes ?  
✅ **Node Health** : Tous les nodes sont-ils sains ?

---

## ⚡ Dashboard 4 : Performance & SLOs

**Objectif** : SLOs (Service Level Objectives) et métriques de performance

### Indicateurs SLO

| SLO | Target | Panneau |
|-----|--------|---------|
| **Uptime** | 99.9% (3 nines) | 🟢 >99.9% / 🟡 99.5-99.9% / 🔴 <99.5% |
| **Latency p95** | < 500ms | 🟢 <300ms / 🟡 300-500ms / 🔴 >500ms |
| **Error Rate** | < 1% | 🟢 <0.5% / 🟡 0.5-1% / 🔴 >1% |

### Métriques de Santé

- **Availability (5min)** : Disponibilité sur 5 minutes
- **CPU Throttling Rate** : Taux de throttling CPU
- **Restarts (dernière heure)** : Nombre de redémarrages
- **Pods Waiting** : Pods en attente

### Performance Metrics

- **Latency par Service (p50, p95, p99)** : Latence par percentile
- **Throughput par Service (req/s)** : Requêtes par seconde
- **Error Rate par Service (4xx & 5xx)** : Taux d'erreurs client/serveur

### Utilisation

✅ **Vérifier SLOs** : On respecte nos objectifs ?  
✅ **Performance Baseline** : Quelle est la latence normale ?  
✅ **Error Tracking** : Quel service génère des erreurs ?

---

## 🔍 Requêtes PromQL Utiles

### Explorer Prometheus directement

1. Cliquez sur **Explore** (icône boussole)
2. Sélectionnez **Prometheus** comme data source
3. Testez ces requêtes :

```promql
# CPU Usage par Pod
sum(rate(container_cpu_usage_seconds_total{namespace="online-boutique"}[5m])) by (pod)

# Memory Usage par Pod
sum(container_memory_working_set_bytes{namespace="online-boutique"}) by (pod)

# HPA Current Replicas
kube_horizontalpodautoscaler_status_current_replicas{namespace="online-boutique"}

# Pods en erreur
count(kube_pod_status_phase{namespace="online-boutique", phase!="Running"})

# Network Throughput
sum(rate(container_network_transmit_bytes_total{namespace="online-boutique"}[5m])) by (pod)
```

---

## 🛠️ Dépannage

### Problème : Port-forward se déconnecte

```bash
# Créer un script auto-reconnect
while true; do
  kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
  echo "Port-forward déconnecté, reconnexion dans 5s..."
  sleep 5
done
```

### Problème : "Cannot connect to Grafana"

```bash
# Vérifier que le pod est Running
kubectl get pods -n monitoring | grep grafana

# Si le pod est en CrashLoopBackOff
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana --tail=100

# Redémarrer le pod
kubectl rollout restart deployment -n monitoring kube-prometheus-stack-grafana
```

### Problème : Dashboards vides ou pas de données

```bash
# Vérifier que Prometheus collecte des métriques
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090

# Ouvrir http://localhost:9090 et tester une requête :
# up{namespace="online-boutique"}
```

### Problème : Mot de passe oublié

```bash
# Récupérer le secret Grafana
kubectl get secret -n monitoring kube-prometheus-stack-grafana -o jsonpath='{.data.admin-password}' | base64 -d
echo

# Ou réinitialiser via le pod
kubectl exec -n monitoring -it $(kubectl get pod -n monitoring -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}') -- grafana-cli admin reset-admin-password admin123
```

---

## 🚀 Workflow de Vérification Quotidien

### 1. Morning Check (5 min)
```bash
# Port-forward Grafana
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80 &

# Ouvrir le navigateur
open http://localhost:3000

# Vérifier :
# - Dashboard "Kubernetes Cluster" : CPU/Memory globaux < 60%
# - Dashboard "Kubernetes Pods" : Namespace "online-boutique" tous verts
# - Aucun pod en CrashLoopBackOff
```

### 2. Pendant un Load Test
```bash
# Dashboard à surveiller : "Kubernetes Pods"
# Filtrer par : namespace="online-boutique"

# Métriques clés :
# - CPU par pod (ne doit pas dépasser 80%)
# - Memory par pod (ne doit pas dépasser 85%)
# - Nombre de replicas HPA (doit augmenter si charge)
```

### 3. Post-Incident Analysis
```bash
# Utiliser la plage de temps personnalisée
# Chercher les pics de CPU/Memory
# Identifier les pods problématiques
# Vérifier les restarts
```

---

## 📞 Liens Utiles

| Service | Commande | URL |
|---------|----------|-----|
| **Grafana** | `kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80` | http://localhost:3000 |
| **Prometheus** | `kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090` | http://localhost:9090 |
| **Jaeger** | `kubectl port-forward -n observability svc/jaeger-query 16686:16686` | http://localhost:16686 |
| **CloudWatch** | - | AWS Console > CloudWatch > Dashboards > eks-bfs-gp12-monitoring |

---

## 🎓 Ressources Complémentaires

- 📖 [Documentation Grafana](https://grafana.com/docs/grafana/latest/)
- 📖 [PromQL Cheat Sheet](https://promlabs.com/promql-cheat-sheet/)
- 📖 [Kubernetes Monitoring avec Prometheus](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)
- 📊 [Grafana Dashboard Library](https://grafana.com/grafana/dashboards/)

---

**✅ Checklist de Vérification :**
- [ ] Grafana accessible sur http://localhost:3000
- [ ] Login avec admin/admin123 fonctionne
- [ ] Dashboard "Kubernetes Cluster" affiche des données
- [ ] Dashboard "Kubernetes Pods" affiche les pods de "online-boutique"
- [ ] Prometheus data source connecté
- [ ] Aucune alerte rouge active

---

**💡 Astuce Pro :**
Ajoutez Grafana à vos favoris avec ce bookmark :
```
javascript:(function(){window.open('http://localhost:3000','_blank');})()
```

**🔥 Raccourcis Grafana :**
- `Ctrl/Cmd + K` : Recherche rapide
- `Shift + ?` : Voir tous les raccourcis
- `d + k` : Aller au dashboard
- `e` : Toggle time range

