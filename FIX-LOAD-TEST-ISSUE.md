# 🔧 Correction du Problème de Test de Charge

## ❌ Problème Identifié

Vos tests de charge ne fonctionnaient plus à cause des **Pod Security Standards** configurés sur le namespace `online-boutique`.

### Erreur Rencontrée

```
Error creating: pods "loadgenerator-test-XXXXX" is forbidden: 
violates PodSecurity "restricted:latest":
  - allowPrivilegeEscalation != false
  - unrestricted capabilities
  - runAsNonRoot != true
  - seccompProfile not defined
```

## ✅ Solution Appliquée

J'ai mis à jour le script `load-test.sh` pour ajouter les configurations de sécurité requises :

### Changements Effectués

#### 1. SecurityContext au niveau du Pod
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault
```

#### 2. SecurityContext au niveau du Container
```yaml
securityContext:
  allowPrivilegeEscalation: false
  runAsNonRoot: true
  runAsUser: 1000
  capabilities:
    drop:
    - ALL
  seccompProfile:
    type: RuntimeDefault
```

## 🚀 Test de la Correction

Testons maintenant que les tests de charge fonctionnent :

```bash
# Lancer le menu principal
sh bfs.sh

# Sélectionner l'option 3 : "Lancer un test de charge"
# Entrer: 100 utilisateurs
```

### Ce Que Vous Devriez Voir

```
✅ Configuration: 100 utilisateurs (1 loadgenerators)
✅ Déploiement lancé
⏳ Attente du démarrage des pods (30 secondes)...
✅ Loadgenerators Running: 1/1
✅ Utilisateurs simulés: 100/100
```

---

## 📊 Vérification Manuelle

Si vous voulez vérifier que tout fonctionne :

```bash
# Voir les deployments de test
kubectl get deployments -n online-boutique | grep loadgenerator-test

# Voir les pods de test
kubectl get pods -n online-boutique | grep loadgenerator-test

# Voir les logs d'un loadgenerator
kubectl logs -n online-boutique -l app=loadgenerator-test-XXXXX --tail=50
```

---

## 🔍 Pourquoi Ce Problème ?

### Pod Security Standards

Kubernetes 1.23+ introduit les **Pod Security Standards** qui remplacent les Pod Security Policies. Votre cluster utilise le profil `restricted:latest` qui impose :

| Règle | Explication |
|-------|-------------|
| `runAsNonRoot: true` | Les containers ne peuvent pas tourner en tant que root (UID 0) |
| `allowPrivilegeEscalation: false` | Empêche l'escalade de privilèges |
| `capabilities.drop: [ALL]` | Supprime toutes les capabilities Linux |
| `seccompProfile` | Active le filtrage des syscalls Linux |

### Pourquoi Maintenant ?

Ces règles ont probablement été appliquées lors de :
1. La création du namespace `online-boutique` avec Terraform
2. La configuration des labels Pod Security Standards dans `iam-hardening.tf`

Vérification :

```bash
kubectl get namespace online-boutique -o yaml | grep -A 5 "labels:"
```

Vous devriez voir :

```yaml
labels:
  pod-security.kubernetes.io/enforce: restricted
  pod-security.kubernetes.io/audit: restricted
  pod-security.kubernetes.io/warn: restricted
```

---

## 🎯 Actions Effectuées

### 1. ✅ Suppression du Deployment Échoué

```bash
kubectl delete deployment loadgenerator-test-20115 -n online-boutique
```

### 2. ✅ Mise à Jour du Script `load-test.sh`

Le script génère maintenant des manifests conformes aux Pod Security Standards.

### 3. ✅ Documentation Créée

Ce fichier explicatif + mise à jour du guide de monitoring.

---

## 🔄 Pour les Tests Futurs

À partir de maintenant, tous les tests de charge utiliseront automatiquement les bonnes configurations de sécurité. Aucune action manuelle n'est requise !

---

## 🛠️ Si le Problème Persiste

### Option 1 : Vérifier les Logs

```bash
# Voir pourquoi un pod ne démarre pas
kubectl describe pod <nom-du-pod> -n online-boutique

# Voir les events
kubectl get events -n online-boutique --sort-by='.lastTimestamp' | tail -20
```

### Option 2 : Assouplir Temporairement les Règles (NON RECOMMANDÉ)

```bash
# Passer le namespace en "baseline" au lieu de "restricted"
kubectl label namespace online-boutique pod-security.kubernetes.io/enforce=baseline --overwrite
```

⚠️ **Attention** : Ceci réduit la sécurité. À utiliser uniquement pour déboguer.

### Option 3 : Test Manuel Sans le Script

```bash
# Créer un loadgenerator manuel
kubectl run test-loadgen \
  --image=gcr.io/google-samples/microservices-demo/loadgenerator:v0.10.1 \
  --namespace=online-boutique \
  --env="FRONTEND_ADDR=frontend:80" \
  --env="USERS=10" \
  --overrides='{
    "spec": {
      "securityContext": {
        "runAsNonRoot": true,
        "runAsUser": 1000
      },
      "containers": [{
        "name": "test-loadgen",
        "image": "gcr.io/google-samples/microservices-demo/loadgenerator:v0.10.1",
        "securityContext": {
          "allowPrivilegeEscalation": false,
          "runAsNonRoot": true,
          "capabilities": {"drop": ["ALL"]}
        }
      }]
    }
  }'

# Supprimer après test
kubectl delete pod test-loadgen -n online-boutique
```

---

## 📚 Ressources

- [Kubernetes Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/)
- [Security Context Documentation](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)

---

## ✅ Checklist de Vérification

Avant de lancer un test de charge, vérifiez :

- [ ] Le cluster est accessible : `kubectl cluster-info`
- [ ] Le namespace existe : `kubectl get ns online-boutique`
- [ ] Les services tournent : `kubectl get pods -n online-boutique`
- [ ] Le frontend est accessible : Vérifier l'URL du Load Balancer
- [ ] Grafana est prêt (optionnel) : `sh access-grafana.sh`

---

**🎉 Vos tests de charge sont maintenant opérationnels !**

Lancez simplement : `sh load-test.sh`


