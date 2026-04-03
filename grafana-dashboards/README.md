# 📊 Dashboards Grafana Black Friday Survival

## 📁 Dashboards Disponibles

Ce dossier contient **4 dashboards professionnels** créés sur mesure pour le monitoring Black Friday.

| Fichier | Dashboard | UID | Tags |
|---------|-----------|-----|------|
| `01-overview.json` | Black Friday - Vue d'Ensemble | `black-friday-overview` | `black-friday`, `overview` |
| `02-microservices.json` | Black Friday - Microservices | `black-friday-microservices` | `black-friday`, `microservices` |
| `03-infrastructure.json` | Black Friday - Infrastructure | `black-friday-infrastructure` | `black-friday`, `infrastructure` |
| `04-performance.json` | Black Friday - Performance & SLOs | `black-friday-performance` | `black-friday`, `performance`, `slo` |

---

## 🎯 Dashboard 1 : Vue d'Ensemble

**Fichier** : `01-overview.json`  
**UID** : `black-friday-overview`

### Objectif
Vision rapide de la santé globale du système en un coup d'œil.

### Panneaux
- ✅ **Gauges** : CPU/Memory cluster global avec seuils colorés
- ✅ **État des Pods** : Running / Pending / Failed en temps réel
- ✅ **CPU par Pod** : Graphique de consommation CPU par pod
- ✅ **Mémoire par Pod** : Graphique de consommation mémoire par pod
- ✅ **Stats** : Pods Running, Pods avec Restarts, Nodes Total
- ✅ **Bar Gauge** : Replicas par Deployment

### Cas d'Usage
- Morning Check quotidien
- Incident Response (identifier rapidement le problème)
- Monitoring pendant Load Test

---

## 🔧 Dashboard 2 : Microservices

**Fichier** : `02-microservices.json`  
**UID** : `black-friday-microservices`

### Objectif
Monitoring détaillé de chaque microservice de l'application Online Boutique.

### Sections

#### Frontend & Load Generator
- CPU Usage Frontend
- Memory Usage Frontend

#### Backend Services
- CPU Usage tous services backend (adservice, cartservice, checkout, etc.)
- Memory Usage tous services backend

#### Database & Cache (Redis)
- CPU Usage Redis
- Memory Usage Redis

#### Network Activity
- Network I/O par pod (transmit/receive en graph miroir)

### Cas d'Usage
- Identifier les bottlenecks applicatifs
- Vérifier la santé de Redis (cache)
- Détecter les saturations réseau

---

## 🏗️ Dashboard 3 : Infrastructure

**Fichier** : `03-infrastructure.json`  
**UID** : `black-friday-infrastructure`

### Objectif
Monitoring des nodes Kubernetes et de l'autoscaling horizontal (HPA).

### Sections

#### Nodes Overview
- CPU Usage par node (seuils 70% / 85%)
- Memory Usage par node (seuils 70% / 85%)
- Disk Usage (bar gauge)
- Network I/O par node

#### Horizontal Pod Autoscaler (HPA)
- Replicas : Current vs Desired vs Min/Max (4 métriques)
- CPU Target Utilization (bar gauge avec seuils)

#### Cluster Capacity
- Total CPU Allocatable
- Total Memory Allocatable
- CPU Requested (online-boutique)
- Memory Requested (online-boutique)
- CPU Allocation % (avec seuils colorés)
- Memory Allocation % (avec seuils colorés)

### Cas d'Usage
- Vérifier que HPA scale correctement
- Capacity Planning (besoin d'ajouter des nodes ?)
- Health Check des nodes EC2

---

## ⚡ Dashboard 4 : Performance & SLOs

**Fichier** : `04-performance.json`  
**UID** : `black-friday-performance`

### Objectif
SLOs (Service Level Objectives) et métriques de performance applicative.

### Indicateurs SLO (Gauges)

| SLO | Target | Seuils |
|-----|--------|--------|
| **Uptime** | 99.9% | 🟢 >99.9% / 🟡 99.5-99.9% / 🔴 <99.5% |
| **Latency p95** | < 500ms | 🟢 <300ms / 🟡 300-500ms / 🔴 >500ms |
| **Error Rate** | < 1% | 🟢 <0.5% / 🟡 0.5-1% / 🔴 >1% |

### Métriques de Santé (Stats)
- Availability (5min)
- CPU Throttling Rate
- Restarts (dernière heure)
- Pods Waiting

### Performance Metrics
- **Latency par Service** : p50, p95, p99 en 3 courbes
- **Throughput par Service** : Requests/sec (stacked area)
- **Error Rate par Service** : 4xx et 5xx séparément

### Cas d'Usage
- Vérifier le respect des SLOs contractuels
- Établir une baseline de performance
- Identifier les services lents ou en erreur

---

## 🔄 Déploiement

### Automatique via Terraform

Les dashboards sont automatiquement déployés lors du `terraform apply` :

```bash
cd terraform
terraform apply
```

Terraform va :
1. Lire les fichiers JSON dans `grafana-dashboards/`
2. Les injecter dans Grafana via Helm values
3. Les placer dans le folder "Black Friday Survival"

### Manuel via API Grafana

Si besoin de déployer manuellement :

```bash
# Port-forward Grafana
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80 &

# Importer un dashboard
curl -X POST http://admin:BlackFriday2024!@localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d @01-overview.json
```

---

## 📝 Personnalisation

### Modifier un Dashboard

1. Ouvrir Grafana : http://localhost:3000
2. Se connecter avec `admin` / `BlackFriday2024!`
3. Naviguer vers le dashboard à modifier
4. Cliquer sur **Settings** (engrenage) → **JSON Model**
5. Copier le JSON modifié
6. Remplacer dans le fichier correspondant (ex: `01-overview.json`)
7. `terraform apply` pour redéployer

### Ajouter un Panneau

Les dashboards sont entièrement éditables dans Grafana. Pour persister les changements :

1. Éditer dans l'UI Grafana
2. Exporter le JSON (**Share** → **Export** → **Save to file**)
3. Remplacer le fichier JSON correspondant
4. `terraform apply`

---

## 🎨 Thèmes et Variables

### Refresh Rate
Tous les dashboards ont un refresh automatique de **30 secondes**.

### Timezone
Utilise la timezone du navigateur.

### Time Range par Défaut
`now-1h` à `now` (dernière heure).

### Templating
Actuellement aucune variable template. Peut être ajouté si besoin :
- `$namespace` pour filtrer par namespace
- `$pod` pour filtrer par pod
- `$node` pour filtrer par node

---

## 📊 Métriques Prometheus Utilisées

### Métriques CPU
- `node_cpu_seconds_total{mode="idle"}` : CPU idle des nodes
- `container_cpu_usage_seconds_total` : CPU des containers
- `container_cpu_cfs_throttled_seconds_total` : CPU throttling

### Métriques Memory
- `node_memory_MemAvailable_bytes` : Mémoire disponible
- `node_memory_MemTotal_bytes` : Mémoire totale
- `container_memory_working_set_bytes` : Mémoire utilisée par container

### Métriques Kubernetes
- `kube_pod_status_phase` : État des pods
- `kube_pod_container_status_restarts_total` : Redémarrages
- `kube_horizontalpodautoscaler_*` : Métriques HPA
- `kube_node_status_allocatable` : Capacité allocatable
- `kube_pod_container_resource_requests` : Ressources demandées

### Métriques Network
- `container_network_transmit_bytes_total` : Bytes envoyés
- `container_network_receive_bytes_total` : Bytes reçus
- `node_network_transmit_bytes_total` : Network node transmit
- `node_network_receive_bytes_total` : Network node receive

### Métriques Application (si disponibles)
- `http_server_duration_milliseconds_bucket` : Latence HTTP
- `http_server_requests_total` : Requêtes HTTP totales
- `up` : Health check service

**Note** : Certaines métriques HTTP nécessitent l'instrumentation des applications.

---

## 🚀 Best Practices

### Seuils Recommandés

| Métrique | Warning | Critical |
|----------|---------|----------|
| CPU | 70% | 85% |
| Memory | 70% | 85% |
| Disk | 70% | 85% |
| Latency p95 | 300ms | 500ms |
| Error Rate | 0.5% | 1% |
| Uptime | 99.5% | 99.9% |

### Ordre de Consultation

1. **Vue d'Ensemble** : Check rapide santé globale
2. **Performance & SLOs** : Vérifier SLOs
3. **Infrastructure** : Si problème de scale → HPA/Nodes
4. **Microservices** : Si problème applicatif → Quel service ?

### Alerting

Pour configurer des alertes basées sur ces dashboards :

1. Aller dans **Alerting** → **Alert Rules**
2. Créer une règle basée sur une query PromQL
3. Exemples :
   - `CPU > 85%` pendant 5min → Alerte critique
   - `Error Rate > 1%` → Alerte warning
   - `Pods Pending > 0` pendant 2min → Alerte info

---

## 📞 Support

En cas de problème avec les dashboards :

1. Vérifier que Prometheus collecte les métriques : http://localhost:9090
2. Tester les queries PromQL dans **Explore**
3. Vérifier les logs Grafana :
   ```bash
   kubectl logs -n monitoring -l app.kubernetes.io/name=grafana --tail=100
   ```

4. Redéployer les dashboards :
   ```bash
   cd terraform
   terraform apply -replace=helm_release.kube_prometheus_stack[0]
   ```

---

**Version** : 1.0  
**Créé le** : 2026-04-03  
**Compatibilité** : Grafana 10.0+, Prometheus, Kubernetes 1.27+

