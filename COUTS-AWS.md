# 💰 Coûts AWS - Black Friday Survival

**Région** : eu-west-1  
**Cluster** : eks-bfs-gp12  
**Capacité** : 5,000 utilisateurs concurrents MAX

---

## 💵 Coûts Actuels (Configuration Testée)

### 📊 Coût Mensuel Total : **$260-400/mois**

| Ressource | Quantité | Coût Unitaire | Coût Mensuel |
|-----------|----------|---------------|--------------|
| **EKS Cluster** | 1 | $73/mois | **$73** |
| **EC2 Instances (t3.medium)** | 2-7 nodes | ~$30/node/mois | **$60-210** |
| **NAT Gateway** | 1 | $32 + data | **$40-60** |
| **EBS Volumes (gp3)** | ~100Gi | $0.08/Gi/mois | **$8** |
| **Load Balancers** | 1-2 | ~$22/LB/mois | **$22-44** |
| **CloudWatch Logs** | ~50GB/mois | $0.50/GB | **$25** |
| **WAF** | 1 Web ACL | $5 + rules | **$10** |
| **Elasticsearch (Jaeger)** | Désactivé | - | **$0** |
| **Prometheus + Grafana** | Inclus dans nodes | - | **$0** |
| | | **TOTAL** | **$260-400** |

### 🎯 Coût pour Black Friday (3 jours)

**Scénario : 5,000 users, config actuelle**

| Période | Nodes Actifs | Coût/Jour | Coût Total |
|---------|--------------|-----------|------------|
| **Avant Black Friday** (25 jours) | 2 nodes | ~$10/jour | ~$250 |
| **Black Friday** (3 jours) | 7 nodes | ~$20/jour | ~$60 |
| **Après Black Friday** (2 jours) | 2 nodes | ~$10/jour | ~$20 |
| | | **TOTAL MOIS** | **~$330** |

**Surcoût Black Friday** : ~$30-50 pour 3 jours

---

## 📈 Coûts par Scénario (Si Vous Voulez Aller Plus Loin)

### Scénario 1 : Configuration Actuelle (5,000 Users) ✅

| Composant | Coût |
|-----------|------|
| **Mensuel** | $260-400 |
| **Black Friday (3 jours)** | +$30-50 |
| **Coût total du mois** | ~$330 |

**Capacité** : 5,000 users  
**Risque** : ✅ Zéro  
**Status** : **Configuration actuelle**

---

### Scénario 2 : Après Modifications HPA (6,000-8,000 Users) ⚠️

**Modifications** :
- HPA Cart Service : 50 replicas max (au lieu de 15)
- HPA Frontend : 40 replicas max (au lieu de 20)
- Terraform : 20 nodes max (au lieu de 10)

| Composant | Coût |
|-----------|------|
| **Mensuel** (au repos) | $280-450 |
| **Black Friday (3 jours)** | +$150-250 |
| **Coût total du mois** | ~$550-700 |

**Détail des coûts supplémentaires** :
- Nodes supplémentaires : 3-5 nodes × $30 = +$90-150/mois
- EBS volumes : +20Gi = +$2/mois
- Data transfer : +50GB = +$5-10/mois

**Capacité** : 6,000-8,000 users (NON TESTÉ)  
**Risque** : ⚠️ Moyen  
**Surcoût Black Friday** : +$220-370 par rapport au scénario 1

---

### Scénario 3 : Infrastructure Optimisée (15,000+ Users) 🔴

**Modifications** :
- Instances t3.large ou t3.xlarge
- Redis Cluster (ElastiCache)
- RDS PostgreSQL
- CDN CloudFront
- Plus de nodes

| Composant | Quantité | Coût Mensuel |
|-----------|----------|--------------|
| **EKS Cluster** | 1 | $73 |
| **EC2 (t3.large)** | 10-20 nodes | $600-1,200 |
| **ElastiCache Redis** | Multi-AZ | $100-200 |
| **RDS PostgreSQL** | db.t3.medium | $150-250 |
| **CloudFront CDN** | 1TB transfer | $85 |
| **Load Balancers** | 3-4 | $66-88 |
| **NAT Gateways** | 3 (1 par AZ) | $96-150 |
| **EBS Volumes** | 500Gi | $40 |
| **CloudWatch** | 200GB | $100 |
| **WAF** | 1 + règles | $15 |
| | **TOTAL** | **$1,500-2,200** |

**Capacité** : 15,000-20,000 users (théorique)  
**Risque** : 🔴 Nécessite refonte complète  
**Délai** : 1 semaine minimum  
**Surcoût annuel** : +$15,000-24,000

**Recommandation** : 🔴 Non recommandé pour 2026

---

## 💡 Calcul Simple

### Configuration Actuelle (Safe)

```
Coût de base : ~$10/jour
Black Friday (7 nodes) : ~$20/jour × 3 jours = $60
Total mois : ~$330

Capacité : 5,000 users
Risque : Zéro
```

### Après Modifications (Risqué)

```
Coût de base : ~$15/jour
Black Friday (12-15 nodes) : ~$40/jour × 3 jours = $120
Total mois : ~$600

Capacité : 7,000-8,000 users (peut-être)
Risque : Moyen
```

### Différence

```
Surcoût : +$270/mois
Capacité supplémentaire : +2,000-3,000 users (incertain)
Coût par user supplémentaire : ~$0.10/user

Question : Est-ce que 2,000 users de plus valent $270 de risque ?
```

---

## 🎯 Comparaison Coût/Bénéfice

### Option 1 : Rester à 5,000 Users

**Coût** : $330/mois  
**Capacité** : 5,000 users garantis  
**Coût par user** : $0.066/user  
**Risque** : 0%  
**Verdict** : ✅ **Meilleur rapport coût/risque**

---

### Option 2 : Viser 8,000 Users

**Coût** : $600/mois  
**Capacité** : 7,000-8,000 users (peut-être)  
**Coût par user** : $0.075-0.086/user  
**Risque** : 30-40%  
**Verdict** : ⚠️ **Risqué et plus cher par user**

---

## 📅 Coûts par Période

### Mois Normal (Hors Black Friday)

```
Nodes : 2 (minimum)
Coût/jour : ~$10
Coût/mois : ~$300
```

### Semaine Black Friday (Pic de Traffic)

```
Jours -2 à -1 : 2 nodes = $20
Jour 0 (Black Friday) : 7 nodes = $20
Jours +1 à +2 : 5 → 2 nodes = $30
Total semaine : ~$70
```

### Année Complète

```
11 mois normaux : 11 × $300 = $3,300
1 mois Black Friday : $330
Total annuel : ~$3,630

Moyenne mensuelle : ~$303
```

---

## 💸 Optimisations pour Réduire les Coûts

### Actuellement Appliqué ✅

- ✅ **1 seul NAT Gateway** (au lieu de 3) : Économie de $64/mois
- ✅ **Nodes spot** configurés (0 actifs actuellement) : Économie potentielle de 70%
- ✅ **Autoscaling** : Ne paye que ce qu'on utilise
- ✅ **Log retention 7 jours** : Au lieu de 30 jours
- ✅ **Pas d'ElasticSearch** pour Jaeger : Économie de $200/mois

### Optimisations Possibles (Si Budget Serré)

#### 1. Désactiver Prometheus/Grafana (Économie : ~$0)
Prometheus/Grafana tournent sur les nodes existants, donc coût = 0.  
**Pas recommandé** : Vous perdez la surveillance.

#### 2. Désactiver Jaeger (Économie : ~$0)
Déjà désactivé.

#### 3. Utiliser des Spot Instances (Économie : 50-70%)

```hcl
# terraform/main.tf
# Augmenter l'utilisation du node group spot :
spot_node_group {
  min_size = 2
  max_size = 10
  desired_size = 2
}
```

**Coût** : $15-20/node au lieu de $30  
**Économie** : ~$100-150/mois  
**Risque** : Instances peuvent être terminées par AWS (rare)

#### 4. Réduire les Log Retention (Économie : ~$10-15/mois)

```bash
# CloudWatch Logs : 3 jours au lieu de 7
# Économie : ~$15/mois
```

#### 5. Réduire le Node Group au Minimum

```hcl
# terraform/main.tf
general_node_group {
  min_size = 1  # Au lieu de 2
}
```

**Économie** : $30/mois  
**Risque** : ⚠️ Moins de redondance

---

## 📊 Estimation Coûts Optimisés

### Mode Économie Maximum

| Optimisation | Économie |
|--------------|----------|
| 1 NAT Gateway | $64/mois ✅ Déjà fait |
| Spot Instances | $100-150/mois |
| Log Retention 3j | $15/mois |
| Min nodes = 1 | $30/mois |
| **TOTAL ÉCONOMIES** | **~$200/mois** |

**Coût optimisé** : ~$160-200/mois (au lieu de $300-400)

**⚠️ Compromis** :
- Moins de redondance
- Moins d'historique de logs
- Risque de termination Spot instances

---

## 🎯 Recommandation Coûts

### Configuration Actuelle (RECOMMANDÉE)

**Coût** : $260-400/mois  
**Capacité** : 5,000 users  
**Optimisations** : Déjà appliquées (1 NAT GW)  
**Risque** : Faible

**Verdict** : ✅ Bon compromis coût/performance/risque

---

### Mode Économie (Si Budget Très Serré)

**Coût** : $160-200/mois  
**Capacité** : 3,000-4,000 users  
**Optimisations** : Spot instances, min nodes = 1  
**Risque** : Moyen

**Verdict** : ⚠️ Possible mais moins robuste

---

### Mode Performance (Si Budget Confortable)

**Coût** : $600-800/mois  
**Capacité** : 7,000-10,000 users  
**Optimisations** : Aucune (max resources)  
**Risque** : Faible (après tests)

**Verdict** : 💰 Cher pour un gain incertain

---

## 🧮 Calculateur Rapide

### Formule Simple

```
Coût de base (EKS + infra fixe) : $150/mois

Coût par node t3.medium :
  - On-Demand : $30/mois
  - Spot : $10-15/mois

Nombre de nodes selon users :
  - 0-2,000 users : 2 nodes
  - 2,000-5,000 users : 5-7 nodes
  - 5,000-8,000 users : 10-15 nodes
  - 8,000+ users : 20+ nodes

Calcul :
  Coût total = $150 + (nb_nodes × $30)

Exemples :
  2 nodes : $150 + $60 = $210/mois
  7 nodes : $150 + $210 = $360/mois
  15 nodes : $150 + $450 = $600/mois
```

---

## 📅 Coûts par Scénario Black Friday

### Scénario 1 : 5,000 Users (Safe)

**Configuration** : Actuelle (aucune modification)

```
Mois normal (25 jours) : 2 nodes × $10/jour = $250
Black Friday (3 jours) : 7 nodes × $20/jour = $60
Scale down (2 jours) : 4 nodes × $15/jour = $30
---
TOTAL MOIS : ~$340
```

**Surcoût Black Friday** : $60 (pour 3 jours)  
**Capacité** : 5,000 users garantis  
**Recommandation** : ✅ **Meilleure option**

---

### Scénario 2 : 8,000 Users (Risqué)

**Configuration** : HPA augmentés + Terraform 20 nodes max

```
Mois normal (25 jours) : 5 nodes × $15/jour = $375
Black Friday (3 jours) : 15 nodes × $40/jour = $120
Scale down (2 jours) : 8 nodes × $25/jour = $50
---
TOTAL MOIS : ~$545
```

**Surcoût Black Friday** : $120 (pour 3 jours)  
**Surcoût vs Scénario 1** : +$205/mois  
**Capacité** : 8,000 users (NON TESTÉ)  
**Recommandation** : ⚠️ Uniquement si vraiment nécessaire

---

### Scénario 3 : 15,000+ Users (Refonte)

**Configuration** : t3.large + Redis Cluster + RDS

```
Mois normal : $1,500/mois
Black Friday : $1,800-2,000/mois
---
Coût annuel : ~$18,000-20,000
```

**Recommandation** : 🔴 Non recommandé pour 2026

---

## 🎯 Où Trouver les Coûts dans les Docs

| Document | Section Coûts | Page |
|----------|---------------|------|
| **COUTS-AWS.md** | 👈 **CE DOCUMENT** | Tout |
| RESOURCES-INSTALLED.md | "Estimation des Coûts" | Ligne ~300 |
| CAPACITY-ANALYSIS.md | "Coûts par Scénario" | Ligne ~250 |
| BLACK-FRIDAY-REALITY.md | Tableaux de décision | Ligne ~180 |

**Recommandation** : 👉 **Utilisez CE document (COUTS-AWS.md)** comme référence unique.

---

## 💡 Décision Rapide

### Budget < $400/mois

→ **Garder la config actuelle**  
→ Capacité : 5,000 users  
→ Coût : $330/mois

---

### Budget $400-700/mois

→ **Modifier HPA + Terraform**  
→ Capacité : 7,000-8,000 users (peut-être)  
→ Coût : $550-700/mois  
→ ⚠️ Tester avant !

---

### Budget > $1,000/mois

→ **Refonte complète possible**  
→ Capacité : 15,000+ users  
→ Coût : $1,500-2,000/mois  
→ Délai : 1 semaine

---

## 🧮 Calculateur Interactif

### Combien Ça Coûte pour X Users ?

| Users Cibles | Nodes Requis | Coût Mensuel | Coût Black Friday |
|--------------|--------------|--------------|-------------------|
| **2,000** | 2-3 | $250-300 | +$20 |
| **5,000** | 5-7 | $300-400 | +$50 ✅ Config actuelle |
| **7,000** | 10-12 | $450-550 | +$100 |
| **8,000** | 12-15 | $500-650 | +$150 |
| **10,000** | 18-25 | $700-900 | +$250 |
| **15,000** | 30-40 (t3.large) | $1,500-2,000 | +$500 |

---

## 💸 Économiser de l'Argent

### Action 1 : Utiliser Spot Instances (Économie : 50-70%)

**Actuellement** : 0 spot instances utilisées  
**Potentiel** : 5-10 spot instances

```bash
cd terraform
# Éditer main.tf - Activer spot instances :
spot_node_group {
  min_size = 2
  max_size = 10
  desired_size = 2
}
```

**Économie** : $15-20/node = $100-150/mois  
**Risque** : Faible (AWS termine rarement les spots)

---

### Action 2 : Réduire Log Retention

```bash
# CloudWatch Logs : 3 jours au lieu de 7
# Via Terraform ou AWS Console
```

**Économie** : ~$15/mois  
**Impact** : Moins d'historique de logs

---

### Action 3 : Désactiver ce qui n'est pas utilisé

**Actuellement désactivé** :
- ✅ Jaeger (ElasticSearch) : $0 économisé
- ✅ Pas de Load Balancer externe inutile

**Déjà optimisé** ✅

---

## 📊 Synthèse Coûts

### Coûts Actuels Confirmés

```
💰 Configuration actuelle :
   - Base : $260-400/mois
   - Black Friday : +$30-50 pour 3 jours
   - Total mois avec BF : ~$330

✅ Capacité : 5,000 users
✅ Testé et validé
✅ Coûts maîtrisés
```

### Si Vous Voulez Plus de Capacité

```
💰 Configuration modifiée :
   - Base : $450-550/mois
   - Black Friday : +$150-250 pour 3 jours
   - Total mois avec BF : ~$600-700

⚠️ Capacité : 7,000-8,000 users (NON testé)
⚠️ Risque d'instabilité
⚠️ Surcoût : +$270-370/mois
```

---

## ✅ Recommandation Finale

### Pour Vous

**Restez à la configuration actuelle**

**Pourquoi** :
- Coût raisonnable : $330/mois
- Capacité suffisante : 5,000 users
- Risque zéro
- Pas de mauvaises surprises

**Si vous avez plus de 5,000 users attendus** :
- File d'attente virtuelle
- Ventes étalées sur plusieurs heures
- Codes promo par email pour ceux en attente

**Vous économisez $270/mois ET vous dormez tranquille.** 😴

---

## 🔍 Vérifier Vos Coûts Réels

### AWS Cost Explorer

```bash
# Voir vos coûts actuels
aws ce get-cost-and-usage \
  --time-period Start=2026-03-01,End=2026-04-01 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=SERVICE \
  --filter file://filter.json

# Ou via AWS Console :
# Billing > Cost Explorer > Filtrer par tag:Project=bfs-gp12
```

### Voir les Ressources Actives

```bash
# Nombre de nodes actuellement actifs
kubectl get nodes | wc -l

# Nombre de pods
kubectl get pods -A | wc -l

# EBS volumes
kubectl get pvc -A

# Load Balancers
kubectl get svc --all-namespaces | grep LoadBalancer
```

---

## 📞 Questions Fréquentes

### Q: Pourquoi les coûts varient ($260-400) ?

R: Ça dépend du nombre de nodes actifs :
- **2 nodes** (repos) : $260/mois
- **7 nodes** (charge) : $400/mois

---

### Q: Combien coûte un test de charge ?

R: Presque rien ! Les nodes scalent temporairement.
- Test de 1h avec 5,000 users : ~$5-10
- Test de 3h : ~$15-20

---

### Q: Est-ce que je paye même quand personne n'utilise le site ?

R: Oui, coûts fixes :
- EKS Cluster : $73/mois (toujours)
- 2 nodes minimum : $60/mois (toujours)
- NAT Gateway : $32/mois (toujours)
- **Total minimum** : ~$165/mois

---

### Q: Comment réduire les coûts hors Black Friday ?

R: **Détruire l'infrastructure** :

```bash
cd terraform
terraform destroy

# Coût : $0/mois
# Redéployer avant Black Friday : terraform apply (15-20 min)
```

**OU** : Réduire au minimum :

```bash
# Garder 1 seul node
kubectl scale deployment --all -n online-boutique --replicas=0
# Modifier Terraform : desired_size = 1

# Coût : ~$200/mois
```

---

## ✅ TL;DR (Résumé Ultra Court)

| Question | Réponse |
|----------|---------|
| **Coût actuel** | $260-400/mois |
| **Black Friday** | +$30-50 pour 3 jours |
| **Capacité** | 5,000 users MAX |
| **Pour aller à 8,000** | +$270/mois + risques |
| **Recommandation** | Rester à 5,000 users |
| **Où sont les coûts** | 👉 **CE DOCUMENT** |

---

**📍 Gardez ce document en bookmark - C'est votre référence unique pour les coûts.**

