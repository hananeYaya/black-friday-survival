# 🎯 Prochaines étapes - Black Friday Survival

## ✅ **État actuel du déploiement**

- ✅ Cluster EKS opérationnel (eks-bfs-gp12)
- ✅ 2 nœuds actifs (t3.medium)
- ✅ Addons Kubernetes installés
- ✅ 11 microservices Online Boutique déployés et Running
- ✅ Load Balancer AWS créé

**URL de l'application** : http://k8s-onlinebo-frontend-d3518e0e74-8916b0a1c6b0cd94.elb.eu-west-1.amazonaws.com

---

## 🚀 **Prochaines actions recommandées**

### 1. **Tester l'application** 🧪
```bash
# Ouvrir l'application dans le navigateur
open http://k8s-onlinebo-frontend-d3518e0e74-8916b0a1c6b0cd94.elb.eu-west-1.amazonaws.com

# Ou récupérer l'URL dynamiquement
kubectl get svc frontend-external -n online-boutique -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### 2. **Monitoring et métriques** 📊
```bash
# Voir les métriques des nœuds
kubectl top nodes

# Voir les métriques des pods
kubectl top pods -n online-boutique

# Voir les HPA (autoscalers)
kubectl get hpa -n online-boutique

# Dashboard CloudWatch
echo "https://console.aws.amazon.com/cloudwatch/home?region=eu-west-1#dashboards:name=eks-bfs-gp12-monitoring"

# Logs d'un service
kubectl logs -f deployment/frontend -n online-boutique
```

### 3. **Test de charge Black Friday** 🔥
```bash
# Augmenter la charge du loadgenerator pour simuler un Black Friday
kubectl scale deployment loadgenerator -n online-boutique --replicas=5

# Observer le scaling automatique
watch kubectl get pods -n online-boutique
watch kubectl get hpa -n online-boutique
watch kubectl top pods -n online-boutique

# Observer le Cluster Autoscaler
kubectl logs -f deployment/cluster-autoscaler -n kube-system

# Les nœuds devraient automatiquement s'ajouter si nécessaire
watch kubectl get nodes
```

### 4. **Optimisations possibles** ⚡
```bash
# Activer les instances Spot pour économiser jusqu'à 70%
# (Les node groups spot sont déjà configurés mais à 0 replicas)
# Kubernetes peut les utiliser automatiquement quand il en a besoin

# Vérifier les node groups
kubectl get nodes --show-labels

# Voir les Auto Scaling Groups AWS
aws autoscaling describe-auto-scaling-groups --region eu-west-1 | grep -A 5 "eks-bfs-gp12"
```

### 5. **Sécurité** 🔒
```bash
# Vérifier les Network Policies
kubectl get networkpolicies -n online-boutique

# Vérifier le WAF
echo "WAF ARN: $(cd terraform && terraform output -raw waf_web_acl_arn)"

# Logs de sécurité dans CloudWatch
echo "Check: /aws/eks/eks-bfs-gp12/cluster"
```

### 6. **Nettoyage des anciens pods** 🧹
```bash
# Les anciens pods devraient être terminés automatiquement
kubectl get pods -n online-boutique | grep Terminating

# Si nécessaire, forcer la suppression
kubectl delete pods -n online-boutique --field-selector=status.phase=Failed
```

---

## 🧪 **Scénario de test Black Friday**

### Test progressif de montée en charge :

```bash
# Phase 1: Trafic normal (1 replica)
kubectl scale deployment loadgenerator -n online-boutique --replicas=1
sleep 60
kubectl top pods -n online-boutique
kubectl get hpa -n online-boutique

# Phase 2: Augmentation du trafic (3 replicas)
kubectl scale deployment loadgenerator -n online-boutique --replicas=3
sleep 120
kubectl top pods -n online-boutique
kubectl get hpa -n online-boutique

# Phase 3: Black Friday ! (5 replicas)
kubectl scale deployment loadgenerator -n online-boutique --replicas=5
watch kubectl get hpa -n online-boutique
# Observer les pods se multiplier automatiquement

# Phase 4: Observer le Cluster Autoscaler ajouter des nœuds
kubectl get nodes
kubectl describe nodes | grep -A 10 "Allocated resources"
```

---

## 📊 **Commandes utiles de monitoring**

```bash
# Vue d'ensemble complète
kubectl get all -n online-boutique

# Événements récents
kubectl get events -n online-boutique --sort-by='.lastTimestamp' | tail -20

# Utilisation des ressources
kubectl top nodes
kubectl top pods -n online-boutique --sort-by=memory
kubectl top pods -n online-boutique --sort-by=cpu

# Logs en temps réel de tous les services
kubectl logs -f -l app=frontend -n online-boutique

# Statut du cluster autoscaler
kubectl logs -f deployment/cluster-autoscaler -n kube-system | grep -i "scale"
```

---

## 🔧 **Résolution de problèmes**

### Si un pod ne démarre pas :
```bash
# Voir les détails
kubectl describe pod <POD_NAME> -n online-boutique

# Voir les logs
kubectl logs <POD_NAME> -n online-boutique

# Redémarrer un déploiement
kubectl rollout restart deployment/<SERVICE_NAME> -n online-boutique
```

### Si le Load Balancer ne fonctionne pas :
```bash
# Vérifier les logs du AWS Load Balancer Controller
kubectl logs -f deployment/aws-load-balancer-controller -n kube-system

# Vérifier le service
kubectl describe svc frontend-external -n online-boutique

# Recréer le Load Balancer
kubectl delete svc frontend-external -n online-boutique
kubectl expose deployment frontend --port=80 --target-port=8080 --name=frontend-external --type=LoadBalancer -n online-boutique
```

---

## 💰 **Gestion des coûts**

### Coûts actuels estimés (par heure) :
- **EKS Cluster** : $0.10/h
- **2 x t3.medium** : ~$0.08/h ($0.0416/h × 2)
- **NAT Gateway** : $0.045/h
- **EBS volumes** : ~$0.10/GB/mois
- **Load Balancer** : ~$0.023/h

**Total estimé : ~$0.25/h soit ~$6/jour**

### Pour économiser :
```bash
# Réduire à 1 nœud minimum (hors heures de test)
# Modifier dans terraform/main.tf puis:
cd terraform
terraform apply -auto-approve

# Ou via kubectl (temporaire)
kubectl scale deployment --all --replicas=1 -n online-boutique
```

---

## 🗑️ **Nettoyage complet**

Quand vous avez terminé vos tests :

```bash
# 1. Supprimer l'application
kubectl delete namespace online-boutique

# 2. Attendre que le Load Balancer soit supprimé
sleep 120

# 3. Détruire l'infrastructure
cd terraform
terraform destroy -auto-approve
```

**⚠️ Important** : Le Load Balancer doit être supprimé AVANT de détruire l'infrastructure Terraform, sinon vous aurez des erreurs.

---

## 📚 **Documentation**

- Architecture : `/ARCHITECTURE.md`
- Déploiement : `/DEPLOYMENT.md`
- Budget : `/BUDGET-VERDICT.md`
- Dashboard CloudWatch : https://console.aws.amazon.com/cloudwatch/home?region=eu-west-1#dashboards:name=eks-bfs-gp12-monitoring

---

## 🎊 **Félicitations !**

Votre environnement **Black Friday Survival** est maintenant **100% opérationnel** ! 

Vous avez :
- ✅ Un cluster EKS production-ready
- ✅ 11 microservices en haute disponibilité
- ✅ Autoscaling horizontal (HPA) et vertical (Cluster Autoscaler)
- ✅ Monitoring CloudWatch
- ✅ Sécurité avec Network Policies et WAF
- ✅ Load Balancer AWS public

**Bonne simulation Black Friday ! 🛍️🔥**

