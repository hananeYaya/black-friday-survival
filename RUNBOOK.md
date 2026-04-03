# Runbook Opérationnel — Black Friday Survival
**Cluster**: `eks-bfs-gp12` | **Région**: `eu-west-1` | **Namespace app**: `online-boutique`

---

## Table des matières

1. [Vérification de santé du cluster](#1-vérification-de-santé-du-cluster)
2. [Déploiement de l'application](#2-déploiement-de-lapplication)
3. [Lancer un test de charge](#3-lancer-un-test-de-charge)
4. [Surveillance en temps réel](#4-surveillance-en-temps-réel)
5. [Incidents courants](#5-incidents-courants)
   - [5.1 Pod en CrashLoopBackOff / Error](#51-pod-en-crashloopbackoff--error)
   - [5.2 Pod bloqué en Pending](#52-pod-bloqué-en-pending)
   - [5.3 HPA ne scale pas](#53-hpa-ne-scale-pas)
   - [5.4 Cluster Autoscaler ne crée pas de nodes](#54-cluster-autoscaler-ne-crée-pas-de-nodes)
   - [5.5 LoadBalancer sans IP / hostname](#55-loadbalancer-sans-ip--hostname)
   - [5.6 Frontend inaccessible (5xx)](#56-frontend-inaccessible-5xx)
   - [5.7 cartservice indisponible (Redis)](#57-cartservice-indisponible-redis)
   - [5.8 WAF bloque le trafic légitime](#58-waf-bloque-le-trafic-légitime)
6. [Scaling manuel d'urgence](#6-scaling-manuel-durgence)
7. [Arrêter les tests de charge](#7-arrêter-les-tests-de-charge)
8. [Accès aux outils de monitoring](#8-accès-aux-outils-de-monitoring)
9. [Nettoyage et destruction](#9-nettoyage-et-destruction)
10. [Escalade](#10-escalade)

---

## 1. Vérification de santé du cluster

Effectuer ces vérifications avant tout test de charge ou démonstration.

```bash
# Connexion au cluster
aws eks update-kubeconfig --region eu-west-1 --name eks-bfs-gp12

# Vérifier les nodes (attendu : 3+ nodes Ready)
kubectl get nodes

# Vérifier tous les pods de l'application (tous doivent être Running)
kubectl get pods -n online-boutique

# Vérifier les HPAs (TARGETS ne doit pas rester à <unknown> longtemps)
kubectl get hpa -n online-boutique

# Vérifier les services (frontend-external doit avoir un EXTERNAL-IP)
kubectl get svc -n online-boutique

# Vérifier les métriques (doit retourner des valeurs CPU/Memory)
kubectl top nodes
kubectl top pods -n online-boutique
```

**Checklist rapide :**
- [ ] Tous les nodes en `Ready`
- [ ] 11 pods `Running` dans `online-boutique`
- [ ] `frontend-external` a un hostname LoadBalancer
- [ ] `kubectl top nodes` retourne des métriques (pas d'erreur)

---

## 2. Déploiement de l'application

### Déploiement complet (première fois)

```bash
# 1. Déployer l'infrastructure Terraform (~15-20 min)
cd terraform
terraform init
terraform apply -auto-approve
cd ..

# 2. Configurer kubectl
aws eks update-kubeconfig --region eu-west-1 --name eks-bfs-gp12

# 3. Déployer Online Boutique + HPA + Network Policies
./deploy-online-boutique.sh

# 4. Exposer le frontend
kubectl patch svc frontend-external -n online-boutique -p '{"spec":{"type":"LoadBalancer"}}'

# 5. Attendre le LoadBalancer (2-3 min) et récupérer l'URL
kubectl get svc frontend-external -n online-boutique -w
export FRONTEND_URL=$(kubectl get svc frontend-external -n online-boutique \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Frontend: http://$FRONTEND_URL"
```

### Via le menu interactif

```bash
./bfs.sh
# Option 1 : Déployer l'application
# Option 2 : Exposer le frontend
```

### Vérifier que le déploiement est prêt

```bash
# Attendre que tous les pods soient Ready (timeout 10 min)
kubectl wait --for=condition=Ready pods --all -n online-boutique --timeout=600s
```

---

## 3. Lancer un test de charge

### Paliers recommandés (Black Friday simulation)

| Palier | Utilisateurs | Durée | RPS estimé |
|--------|-------------|-------|------------|
| Warm-up | 5 000 | 5 min | ~500 |
| Montée | 20 000 | 10 min | ~2 000 |
| Peak | 50 000 | 15 min | ~5 000 |

### Via le menu interactif (recommandé)

```bash
./bfs.sh
# Option 3 : Lancer un test de charge
# Saisir le nombre d'utilisateurs
```

### Manuellement

```bash
# Exemple : 5000 utilisateurs = 50 pods loadgenerator (100 users/pod)
USERS=5000
REPLICAS=$((USERS / 100))

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: loadgenerator-manual
  namespace: online-boutique
spec:
  replicas: $REPLICAS
  selector:
    matchLabels:
      app: loadgenerator-manual
  template:
    metadata:
      labels:
        app: loadgenerator-manual
    spec:
      containers:
      - name: main
        image: gcr.io/google-samples/microservices-demo/loadgenerator:v0.10.1
        env:
        - name: FRONTEND_ADDR
          value: "frontend:80"
        - name: USERS
          value: "100"
        resources:
          requests:
            cpu: 300m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
EOF
```

---

## 4. Surveillance en temps réel

Ouvrir 4 terminaux en parallèle :

```bash
# Terminal 1 : état des pods
watch kubectl get pods -n online-boutique

# Terminal 2 : HPAs (scaling automatique)
watch kubectl get hpa -n online-boutique

# Terminal 3 : consommation CPU/Memory des nodes
watch kubectl top nodes

# Terminal 4 : top 10 pods par CPU
watch "kubectl top pods -n online-boutique | sort -k2 -hr | head -10"
```

Ou utiliser le menu interactif :
```bash
./bfs.sh
# Option 6 : État du cluster
# Option 7 : Surveiller les HPAs
# Option 8 : Voir les métriques
```

---

## 5. Incidents courants

### 5.1 Pod en CrashLoopBackOff / Error

**Symptôme** : `kubectl get pods` affiche `CrashLoopBackOff` ou `Error`

```bash
# Identifier le pod
kubectl get pods -n online-boutique | grep -v Running

# Lire les logs du pod
kubectl logs -n online-boutique <pod-name> --previous

# Inspecter les événements
kubectl describe pod -n online-boutique <pod-name>
```

**Causes fréquentes et résolutions :**

| Cause | Solution |
|-------|----------|
| OOMKilled (mémoire insuffisante) | Augmenter les limites dans le manifest, ou vérifier que HPA scale |
| Liveness probe fail | Vérifier les logs applicatifs, redémarrer le pod |
| Dépendance indisponible (ex: Redis) | Vérifier `cartservice` et `redis-cart` |

```bash
# Forcer le redémarrage d'un pod
kubectl rollout restart deployment/<service-name> -n online-boutique
```

---

### 5.2 Pod bloqué en Pending

**Symptôme** : Pod reste en `Pending` sans démarrer

```bash
# Voir pourquoi le pod est en attente
kubectl describe pod -n online-boutique <pod-name>
# Chercher la section "Events" en bas
```

**Causes fréquentes :**

| Cause | Commande de diagnostic | Solution |
|-------|----------------------|----------|
| Pas de node disponible | `kubectl get nodes` | Attendre Cluster Autoscaler (~2 min) ou scaler manuellement |
| Ressources insuffisantes | `kubectl top nodes` | Vérifier les quotas, node group plein |
| Taint non tolérée | `kubectl describe node <node>` | Vérifier les tolerations du pod |

```bash
# Vérifier les logs du Cluster Autoscaler
kubectl logs -n kube-system deployment/cluster-autoscaler --tail=50
```

---

### 5.3 HPA ne scale pas

**Symptôme** : CPU dépasse le seuil mais les replicas n'augmentent pas

```bash
# Vérifier l'état détaillé du HPA
kubectl describe hpa -n online-boutique <hpa-name>

# Vérifier que le Metrics Server fonctionne
kubectl top pods -n online-boutique

# Vérifier les événements de scaling
kubectl get events -n online-boutique --sort-by='.lastTimestamp' | tail -20
```

**Causes fréquentes :**

| Cause | Solution |
|-------|----------|
| Metrics Server indisponible | `kubectl rollout restart deployment/metrics-server -n kube-system` |
| TARGETS affiche `<unknown>` | Attendre 2-3 min, le scraping peut être en retard |
| maxReplicas atteint | Scaler manuellement (voir [section 6](#6-scaling-manuel-durgence)) |
| Stabilization window active | Attendre (scaleUp: 60s, scaleDown: 300s) |

---

### 5.4 Cluster Autoscaler ne crée pas de nodes

**Symptôme** : Pods en Pending mais pas de nouveau node

```bash
# Logs du Cluster Autoscaler
kubectl logs -n kube-system deployment/cluster-autoscaler --tail=100 | grep -E "scale|error|ERROR"

# Vérifier les limites des node groups
aws eks describe-nodegroup --cluster-name eks-bfs-gp12 --nodegroup-name general \
  --query 'nodegroup.scalingConfig'

# Vérifier si le max est atteint
kubectl get nodes | wc -l
# Limite : general=10, high-memory=5, spot=5 → max 20 nodes
```

**Si le max est atteint et qu'il faut plus de capacité :**
```bash
# Augmenter temporairement le max du node group (via AWS CLI)
aws eks update-nodegroup-config \
  --cluster-name eks-bfs-gp12 \
  --nodegroup-name general \
  --scaling-config minSize=2,maxSize=15,desiredSize=10
```

---

### 5.5 LoadBalancer sans IP / hostname

**Symptôme** : `kubectl get svc frontend-external` affiche `<pending>` sous EXTERNAL-IP

```bash
# Logs du AWS Load Balancer Controller
kubectl logs -n kube-system deployment/aws-load-balancer-controller --tail=50

# Vérifier les événements du service
kubectl describe svc frontend-external -n online-boutique

# Vérifier les permissions IAM (IRSA)
kubectl get sa -n kube-system aws-load-balancer-controller -o yaml
```

**Vérifications AWS :**
```bash
# Vérifier les LoadBalancers existants
aws elbv2 describe-load-balancers --region eu-west-1 \
  --query 'LoadBalancers[*].[LoadBalancerName,State.Code]'

# Quota EIP (si NLB) - max 5 par région par défaut
aws service-quotas get-service-quota \
  --service-code ec2 --quota-code L-0263D0A3 --region eu-west-1
```

---

### 5.6 Frontend inaccessible (5xx)

**Symptôme** : L'URL du frontend retourne des erreurs HTTP 5xx

```bash
# Vérifier l'état des pods frontend
kubectl get pods -n online-boutique -l app=frontend

# Logs du frontend
kubectl logs -n online-boutique deployment/frontend --tail=50

# Vérifier que les services dépendants sont UP
kubectl get pods -n online-boutique | grep -E "product|cart|currency|checkout"

# Tester la connectivité interne
kubectl exec -it -n online-boutique deployment/frontend -- wget -q -O- http://productcatalogservice:3550 2>&1 | head -5
```

**Action rapide :**
```bash
# Redémarrer le frontend
kubectl rollout restart deployment/frontend -n online-boutique
kubectl rollout status deployment/frontend -n online-boutique
```

---

### 5.7 cartservice indisponible (Redis)

**Symptôme** : Erreurs sur l'ajout au panier, `cartservice` en crash

```bash
# Vérifier Redis
kubectl get pods -n online-boutique -l app=redis-cart
kubectl logs -n online-boutique deployment/redis-cart --tail=30

# Vérifier cartservice
kubectl logs -n online-boutique deployment/cartservice --tail=30
kubectl describe pod -n online-boutique -l app=cartservice
```

**Résolution :**
```bash
# Redémarrer redis-cart (ATTENTION : perte du contenu des paniers)
kubectl rollout restart deployment/redis-cart -n online-boutique

# Puis redémarrer cartservice
kubectl rollout restart deployment/cartservice -n online-boutique
```

---

### 5.8 WAF bloque le trafic légitime

**Symptôme** : Requêtes bloquées avec 403, trafic légitime refusé

**Limite configurée** : 2000 req/IP/5min

```bash
# Consulter les logs WAF dans CloudWatch
aws logs filter-log-events \
  --log-group-name /aws/waf/eks-bfs-gp12 \
  --filter-pattern '{ $.action = "BLOCK" }' \
  --region eu-west-1 \
  --start-time $(date -d '1 hour ago' +%s000) \
  | jq '.events[].message' | head -20
```

**Pour un test de charge** : si le loadgenerator génère >2000 req depuis une IP, les pods tournent dans le cluster (réseau interne) et ne passent pas par le WAF. Ce problème ne survient qu'avec des clients externes.

---

## 6. Scaling manuel d'urgence

Utiliser en cas de pic inattendu ou si le HPA ne réagit pas assez vite.

```bash
# Scaler le frontend immédiatement (max HPA = 20)
kubectl scale deployment frontend -n online-boutique --replicas=15

# Scaler les services critiques
kubectl scale deployment checkoutservice -n online-boutique --replicas=10
kubectl scale deployment cartservice -n online-boutique --replicas=10
kubectl scale deployment productcatalogservice -n online-boutique --replicas=10

# Vérifier que les pods démarrent
kubectl get pods -n online-boutique -w
```

**Limites max par service (configurées dans les HPA) :**

| Service | Min | Max |
|---------|-----|-----|
| frontend | 2 | 20 |
| checkout / cart / product / recommendation | 2 | 15 |
| currency / payment / shipping / email / ad | 2 | 10 |

---

## 7. Arrêter les tests de charge

### Via le menu interactif

```bash
./bfs.sh
# Option 4 : Arrêter un test de charge
# Option 5 : Nettoyer tous les tests temporaires
```

### Manuellement

```bash
# Lister les tests en cours
kubectl get deployments -n online-boutique | grep loadgenerator-test

# Arrêter un test spécifique (scale à 0)
kubectl scale deployment <loadgenerator-test-xxx> -n online-boutique --replicas=0

# Supprimer le deployment
kubectl delete deployment <loadgenerator-test-xxx> -n online-boutique

# Supprimer TOUS les tests d'un coup
kubectl get deployments -n online-boutique --no-headers | grep loadgenerator-test | \
  awk '{print $1}' | xargs kubectl delete deployment -n online-boutique
```

---

## 8. Accès aux outils de monitoring

### Grafana (dashboards Kubernetes + HPA)

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
# URL : http://localhost:3000
# User : admin | Password : BlackFriday2024!
```

### Prometheus (métriques brutes)

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# URL : http://localhost:9090
```

### Jaeger (distributed tracing)

```bash
kubectl port-forward -n observability svc/jaeger-query 16686:16686
# URL : http://localhost:16686
```

### CloudWatch Dashboard

```bash
# URL directe
terraform -chdir=terraform output cloudwatch_dashboard_url

# Ou AWS Console : CloudWatch > Dashboards > eks-bfs-gp12-monitoring
```

### Alarmes CloudWatch configurées

| Alarme | Seuil | Action |
|--------|-------|--------|
| High CPU | >80% | SNS notification |
| High Memory | >80% | SNS notification |

---

## 9. Nettoyage et destruction

### Arrêter les tests et libérer les ressources applicatives

```bash
# Supprimer tous les loadgenerators
kubectl get deployments -n online-boutique --no-headers | grep loadgenerator-test | \
  awk '{print $1}' | xargs kubectl delete deployment -n online-boutique

# Supprimer l'application complète
kubectl delete namespace online-boutique
```

### Détruire l'infrastructure AWS (IRRÉVERSIBLE)

```bash
# ATTENTION : supprime TOUTES les ressources AWS (~$9/jour économisés)
cd terraform
terraform destroy -auto-approve
```

**Si `terraform destroy` échoue**, supprimer manuellement dans cet ordre via la console AWS (filtrer par tag `Project = bfs-gp12`) :
1. LoadBalancers (EC2 > Load Balancers)
2. Node Groups EKS
3. Cluster EKS
4. NAT Gateway
5. VPC et sous-réseaux
6. CloudWatch Log Groups
7. KMS Keys

---

## 10. Escalade

### Informations du cluster

| Ressource | Valeur |
|-----------|--------|
| Cluster | `eks-bfs-gp12` |
| Région | `eu-west-1` |
| Namespace app | `online-boutique` |
| Namespace monitoring | `monitoring` |
| Namespace tracing | `observability` |
| Node group général | `general` (t3.medium, max 10) |
| Node group spot | `spot` (t3.medium, max 5) |
| Node group high-memory | `high-memory` (t3.large, max 5) |

### Commandes de collecte d'informations pour l'escalade

```bash
# Dump complet de l'état du cluster
kubectl get all -n online-boutique > cluster-state-$(date +%Y%m%d-%H%M).txt
kubectl get events -n online-boutique --sort-by='.lastTimestamp' >> cluster-state-$(date +%Y%m%d-%H%M).txt
kubectl top nodes >> cluster-state-$(date +%Y%m%d-%H%M).txt

# Logs des composants système
kubectl logs -n kube-system deployment/cluster-autoscaler --tail=100
kubectl logs -n kube-system deployment/aws-load-balancer-controller --tail=100
kubectl logs -n kube-system deployment/metrics-server --tail=50

# État AWS
aws eks describe-cluster --name eks-bfs-gp12 --region eu-west-1
```

---

*Dernière mise à jour : 2026-04-03*
