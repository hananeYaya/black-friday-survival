# 🚀 Black Friday Survival - Guide Rapide

## ✨ UN SEUL SCRIPT À RETENIR

```bash
./bfs.sh
```

C'est tout ! Ce script fait TOUT :
- ✅ Déployer l'application
- ✅ Lancer des tests de charge
- ✅ Surveiller le cluster
- ✅ Nettoyer les tests

---

## 📋 Menu Principal

```
╔═══════════════════════════════════════════════════════════╗
║           BLACK FRIDAY SURVIVAL - MENU PRINCIPAL          ║
╚═══════════════════════════════════════════════════════════╝

DÉPLOIEMENT
  1) Déployer l'application Online Boutique
  2) Exposer le frontend (LoadBalancer)

TESTS DE CHARGE
  3) Lancer un test de charge
  4) Arrêter un test de charge
  5) Nettoyer tous les tests temporaires

SURVEILLANCE
  6) Voir l'état du cluster
  7) Surveiller les HPAs
  8) Voir les métriques

AUTRE
  9) Aide / Documentation
  0) Quitter
```

---

## 🎯 Scénario Typique

### 1. Premier déploiement
```bash
./bfs.sh
# Choisir: 1 (Déployer l'application)
# Choisir: 2 (Exposer le frontend)
```

### 2. Lancer un test
```bash
./bfs.sh
# Choisir: 3 (Lancer un test)
# Entrer: 1000 (nombre d'utilisateurs)
```

### 3. Surveiller
```bash
./bfs.sh
# Choisir: 7 (Surveiller HPAs)
# ou
# Choisir: 6 (État du cluster)
```

### 4. Arrêter un test
```bash
./bfs.sh
# Choisir: 4 (Arrêter un test)
# Sélectionner le numéro du test
```

---

## 📁 Scripts Disponibles

### Script Principal
- ✅ **`bfs.sh`** - Menu interactif (UTILISEZ CELUI-CI)

### Scripts Avancés (Optionnels)
- 🔧 `load-test.sh` - Test avec monitoring temps réel détaillé
- 🔧 `deploy-online-boutique.sh` - Déploiement direct (utilisé par bfs.sh)

💡 **Recommandation** : Utilisez `bfs.sh` pour 99% des cas. Les autres scripts sont pour les utilisateurs avancés.

---

## 📚 Documentation Complète

- **DEPLOYMENT-GUIDE.md** - Guide complet de déploiement
- **LOAD-TEST-GUIDE.md** - Guide détaillé des tests de charge
- **RESOURCES-INSTALLED.md** - Liste des 149 ressources Terraform
- **TERRAFORM-REFACTORING.md** - Propositions d'amélioration

---

## ⚡ Commandes Rapides

### État général
```bash
./bfs.sh  # Option 6
```

### Lancer 5000 utilisateurs
```bash
./bfs.sh  # Option 3 → Entrer 5000
```

### Voir les HPAs en temps réel
```bash
./bfs.sh  # Option 7
```

---

## 🎓 Que Faire en Cas de Problème ?

```bash
./bfs.sh  # Option 9 (Aide)
```

Ou consultez les logs :
```bash
kubectl get pods -n online-boutique
kubectl logs -n online-boutique <pod-name>
```

---

## 🎉 C'est Tout !

**Un seul script. Un menu simple. Tout est dedans.**

```bash
./bfs.sh
```

---

**Dernière mise à jour** : 31 Mars 2026

