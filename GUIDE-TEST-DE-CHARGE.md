# 🧪 GUIDE D'UTILISATION - TEST DE CHARGE

## 📋 PRÉ-REQUIS

Avant d'utiliser le script de test de charge, assurez-vous d'avoir :

1. ✅ **kubectl** configuré et connecté à votre cluster EKS
   ```bash
   kubectl get nodes
   ```

2. ✅ **Application déployée** (les 12 microservices doivent être Running)
   ```bash
   kubectl get pods
   ```

3. ✅ **HPAs configurés** (optionnel mais recommandé)
   ```bash
   kubectl get hpa
   ```

---

## 🚀 UTILISATION DU SCRIPT

### Lancer un Test de Charge

```bash
./test-de-charge.sh
```

Le script est **100% interactif** et vous guide à travers 5 étapes :

#### 1️⃣ **Configuration**
Choisissez le nombre d'utilisateurs :
- 1000 utilisateurs (10 loadgenerators)
- 2000 utilisateurs (20 loadgenerators)
- 5000 utilisateurs (50 loadgenerators) ⚠️ Charge élevée
- 10000 utilisateurs (100 loadgenerators) 🔥 Très haute charge
- Nombre personnalisé

#### 2️⃣ **Création du YAML**
Le script crée automatiquement le fichier `loadgenerator-XXXX.yaml` si nécessaire.

#### 3️⃣ **Vérification Infrastructure**
- Affiche l'état actuel (nodes, pods)
- Propose de configurer les HPAs si manquants

#### 4️⃣ **Déploiement**
- Applique le YAML
- Attend le démarrage des pods (barre de progression)

#### 5️⃣ **Surveillance en Temps Réel** 🔥
Affiche toutes les 5 secondes :
- Nombre de loadgenerators actifs
- Utilisateurs simulés
- État des HPAs (auto-scaling)
- Nombre de pods par service
- Nombre de nodes
- Top 5 pods par CPU

**Appuyez sur `Ctrl+C` pour quitter la surveillance** (le test continue en arrière-plan)

---

## 🛑 ARRÊTER UN TEST

### Option 1 : Script d'Arrêt (RECOMMANDÉ)

```bash
./stop-test.sh loadgenerator-test-5000
```

Vous aurez le choix :
1. Arrêt progressif (recommandé)
2. Arrêt immédiat
3. Suppression complète
4. Annuler

### Option 2 : Commandes Manuelles

**Arrêt progressif** :
```bash
# Réduire à 50%
kubectl scale deployment loadgenerator-test-5000 --replicas=25

# Réduire à 1000 users
kubectl scale deployment loadgenerator-test-5000 --replicas=10

# Arrêt total
kubectl scale deployment loadgenerator-test-5000 --replicas=0
```

**Arrêt immédiat** :
```bash
kubectl scale deployment loadgenerator-test-5000 --replicas=0
```

**Suppression complète** :
```bash
kubectl delete deployment loadgenerator-test-5000
```

---

## 📊 SURVEILLANCE MANUELLE

### Surveiller les HPAs (Auto-Scaling)

```bash
watch kubectl get hpa
```

### Surveiller les Nodes

```bash
watch kubectl get nodes
```

### Voir tous les Pods

```bash
watch kubectl get pods
```

### Métriques CPU/RAM

```bash
# Pods
kubectl top pods

# Nodes
kubectl top nodes

# Top 10 pods par CPU
kubectl top pods --sort-by=cpu | head -10
```

### Voir les Loadgenerators Actifs

```bash
kubectl get pods -l app=loadgenerator-test-5000
```

### Logs des Loadgenerators

```bash
kubectl logs -l app=loadgenerator-test-5000 --tail=50
```

---

## 🎯 SCÉNARIOS D'UTILISATION

### Scénario 1 : Test Rapide (1000 users)

```bash
./test-de-charge.sh
# Choix : 1
# Confirmer : o
# Attendre 5 minutes
# Ctrl+C pour arrêter la surveillance
# ./stop-test.sh loadgenerator-test-1000
```

**Résultat attendu** :
- Nodes : 3-5
- Pods frontend : 2-5
- Durée recommandée : 10-15 minutes
- Coût : ~2 USD

### Scénario 2 : Test Moyen (5000 users)

```bash
./test-de-charge.sh
# Choix : 3
# Confirmer : o
# Attendre 10-15 minutes
# Observer le scaling
# Ctrl+C pour arrêter la surveillance
# ./stop-test.sh loadgenerator-test-5000
```

**Résultat attendu** :
- Nodes : 15-25
- Pods frontend : 10-20
- Pods catalog : 5-10
- Durée recommandée : 30-60 minutes
- Coût : ~6-10 USD

### Scénario 3 : Stress Test (10000 users)

```bash
./test-de-charge.sh
# Choix : 4
# Confirmer : o
# Attendre 20-30 minutes
# Observer les limites du cluster
# Ctrl+C pour arrêter la surveillance
# ./stop-test.sh loadgenerator-test-10000
```

**Résultat attendu** :
- Nodes : 30-50
- Pods frontend : 15-20 (max)
- Pods catalog : 8-10 (max)
- Durée recommandée : 1-2 heures
- Coût : ~15-25 USD
- ⚠️ Peut atteindre les limites du cluster (65 nodes max)

---

## ⚠️ NOTES IMPORTANTES

### Coûts AWS

Les tests de charge **coûtent de l'argent** :
- **1000 users** : ~2 USD pour 1h de test
- **5000 users** : ~6-10 USD pour 1h de test
- **10000 users** : ~15-25 USD pour 1h de test

**N'oubliez pas d'arrêter les tests après utilisation !**

### Cluster Autoscaler

Le Cluster Autoscaler va :
- **Scale UP** : Ajouter des nodes quand les pods sont en `Pending`
- **Scale DOWN** : Retirer des nodes sous-utilisés après ~10 minutes

**Le scale down est automatique mais peut prendre 10-15 minutes.**

### Limites du Cluster

Configuration actuelle :
- **Min nodes** : 3
- **Max nodes** : 65
- **Max pods par node** : ~29 (limite AWS ENI)

Si vous atteignez 65 nodes, les nouveaux pods resteront en `Pending`.

---

## 🔧 DÉPANNAGE

### Problème : "kubectl: command not found"

```bash
# Installer kubectl
brew install kubectl

# Ou télécharger depuis
# https://kubernetes.io/docs/tasks/tools/
```

### Problème : "error: You must be logged in to the server"

```bash
# Reconfigurer kubectl
aws eks update-kubeconfig --region eu-south-2 --name eks-bfs-gp12-prod
```

### Problème : Pods en "ImagePullBackOff"

Les images sont dans le Google Container Registry et sont publiques. Si erreur :
```bash
# Vérifier les images
kubectl describe pod <nom-du-pod>

# Les images doivent être :
# gcr.io/google-samples/microservices-demo/loadgenerator:v0.10.1
```

### Problème : Pods en "Pending" longtemps

```bash
# Vérifier les événements
kubectl get events --sort-by='.lastTimestamp' | tail -20

# Vérifier le Cluster Autoscaler
kubectl logs -n kube-system -l app=cluster-autoscaler --tail=50

# Peut prendre 3-5 minutes pour ajouter des nodes
```

### Problème : "bc: command not found"

Le script utilise `bc` pour la barre de progression. Installer :
```bash
# macOS
brew install bc

# Ubuntu/Debian
sudo apt-get install bc
```

---

## 📁 FICHIERS GÉNÉRÉS

Lors de l'exécution, le script crée :
- `loadgenerator-1000.yaml` (si choix 1)
- `loadgenerator-2000.yaml` (si choix 2)
- `loadgenerator-5000.yaml` (si choix 3)
- `loadgenerator-10000.yaml` (si choix 4)
- `loadgenerator-XXXX.yaml` (si personnalisé)

Ces fichiers peuvent être :
- ✅ **Committés** dans Git (templates)
- ✅ **Réutilisés** pour relancer le même test
- ✅ **Modifiés** pour ajuster la configuration

---

## 📈 MÉTRIQUES À OBSERVER

### Indicateurs de Santé ✅

- **Pods** : Tous en `Running`, pas de `CrashLoopBackOff`
- **HPAs** : Scaling progressif et fluide
- **Nodes** : Ajout progressif selon les besoins
- **CPU** : 60-80% moyen (optimal)
- **RAM** : 70-80% moyen (optimal)

### Signaux d'Alerte ⚠️

- **Pods Pending** > 5 minutes : Cluster Autoscaler lent ou limite atteinte
- **CPU > 90%** : Risque de throttling, besoin de plus de resources
- **Pods CrashLoopBackOff** : Problème applicatif, saturation mémoire
- **Nodes non ajoutés** : Vérifier les logs du Cluster Autoscaler

---

## 🎯 CHECKLIST AVANT TEST

- [ ] kubectl configuré et connecté
- [ ] Application déployée (12 microservices Running)
- [ ] HPAs configurés (5 services)
- [ ] Cluster Autoscaler opérationnel
- [ ] Metrics Server fonctionnel
- [ ] Budget AWS validé pour le test

---

## 📞 SUPPORT

### Vérifier l'État du Cluster

```bash
# Nodes
kubectl get nodes

# Pods
kubectl get pods

# Services
kubectl get services

# HPAs
kubectl get hpa

# Cluster Autoscaler
kubectl logs -n kube-system -l app=cluster-autoscaler --tail=50
```

### Logs CloudWatch

```bash
# Via AWS CLI
aws logs tail /aws/eks/eks-bfs-gp12-prod/cluster --follow

# Via Console
# https://eu-south-2.console.aws.amazon.com/cloudwatch/
```

---

## 📚 DOCUMENTATION ADDITIONNELLE

- `TESTS-CHARGE-5K-PROGRESSIF.md` - Guide détaillé tests 5K
- `TESTS-CHARGE-1000-USERS.md` - Guide tests 1K
- `ETAT-RESSOURCES-AWS.md` - État complet de l'infrastructure
- `RAPPORT-PROGRESSION.md` - Progression du projet

---

**Script créé par** : Black Friday Survival Team  
**Version** : 1.0  
**Date** : Février 2026  
**Cluster** : eks-bfs-gp12-prod  
**Région** : eu-south-2 (Espagne)

🚀 **Bon test de charge !**

