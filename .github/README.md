# 🔄 GitHub Actions CI/CD - Configuration

## 📋 Vue d'ensemble

Ce workflow GitHub Actions automatise la validation, le scan de sécurité et le déploiement de l'infrastructure Terraform.

## 🎯 Déclencheurs

Le workflow se déclenche dans les cas suivants :

### 1. Push sur les branches principales
```yaml
push:
  branches:
    - main      # Déploiement automatique
    - develop   # Validation uniquement
  paths:
    - 'terraform/**'  # Uniquement si Terraform change
```

### 2. Pull Request vers main
```yaml
pull_request:
  branches:
    - main
  paths:
    - 'terraform/**'
```

### 3. Déclenchement manuel
Via l'interface GitHub Actions : `Actions` > `Terraform CI/CD` > `Run workflow`

---

## 🔧 Jobs de la Pipeline

### Job 1 : `terraform-validate` ✅
**Objectif** : Valider la syntaxe et le formatage Terraform

**Étapes** :
1. Checkout du code
2. Installation de Terraform 1.7.0
3. Vérification du formatage (`terraform fmt -check`)
4. Initialisation sans backend (`terraform init -backend=false`)
5. Validation de la configuration (`terraform validate`)

**Exécution** : Sur tous les événements

---

### Job 2 : `security-scan` 🔒
**Objectif** : Scanner le code Terraform pour détecter les vulnérabilités

**Outils utilisés** :
- **tfsec** : Analyse statique de sécurité Terraform
- **Checkov** : Scan de sécurité et conformité

**Exécution** : Sur tous les événements

**Note** : Les échecs sont en `soft_fail` (ne bloquent pas la pipeline)

---

### Job 3 : `terraform-plan` 📋
**Objectif** : Générer un plan Terraform et le commenter dans la PR

**Étapes** :
1. Configuration des credentials AWS
2. Initialisation Terraform avec backend
3. Génération du plan (`terraform plan`)
4. Upload du plan comme artifact
5. Commentaire automatique dans la PR avec le plan

**Exécution** : Uniquement sur les Pull Requests

**Permissions requises** :
- `contents: read`
- `pull-requests: write`

---

### Job 4 : `terraform-apply` 🚀
**Objectif** : Appliquer les changements Terraform en production

**Étapes** :
1. Configuration des credentials AWS
2. Initialisation Terraform
3. Génération du plan final
4. Application automatique (`terraform apply -auto-approve`)
5. Publication des outputs dans le résumé GitHub

**Exécution** : 
- Uniquement sur push vers `main`
- Nécessite approbation via l'environnement `production`

---

## 🔑 Secrets Requis

Pour que la CI fonctionne, vous devez configurer les secrets suivants dans GitHub :

### Configuration des Secrets

1. Aller sur votre repo GitHub
2. `Settings` > `Secrets and variables` > `Actions`
3. Cliquer sur `New repository secret`

### Secrets à créer :

| Secret Name | Description | Exemple |
|-------------|-------------|---------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key pour le déploiement | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Access Key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |

### Comment créer ces credentials AWS

```bash
# Option 1 : Créer un utilisateur IAM dédié pour la CI
aws iam create-user --user-name github-actions-terraform

# Option 2 : Utiliser vos credentials existants (déconseillé pour prod)
aws configure list
```

**⚠️ Permissions IAM requises** :
- EC2 (création VPC, instances, etc.)
- EKS (gestion cluster)
- IAM (création de rôles)
- CloudWatch (logs et métriques)
- S3 (pour le backend Terraform remote, si configuré)
- DynamoDB (pour le locking Terraform, si configuré)

---

## 🔒 Configuration de l'Environnement GitHub

Pour activer la protection sur le job `terraform-apply` :

1. `Settings` > `Environments` > `New environment`
2. Nom : `production`
3. Configurer les protections :
   - ✅ **Required reviewers** : Ajouter des reviewers obligatoires
   - ✅ **Wait timer** : Délai avant déploiement (ex: 5 minutes)
   - ✅ **Deployment branches** : Uniquement `main`

---

## 📊 Workflow Complet

### Scénario 1 : Pull Request

```
1. Developer crée une PR
   ↓
2. ✅ terraform-validate (validation du code)
   ↓
3. 🔒 security-scan (scan de sécurité)
   ↓
4. 📋 terraform-plan (génération du plan)
   ↓
5. 💬 Commentaire automatique dans la PR avec le plan
   ↓
6. Reviewers approuvent la PR
   ↓
7. Merge vers main
```

### Scénario 2 : Push sur main

```
1. Code mergé sur main
   ↓
2. ✅ terraform-validate
   ↓
3. 🔒 security-scan
   ↓
4. ⏸️ Approbation manuelle (environnement production)
   ↓
5. 🚀 terraform-apply (déploiement automatique)
   ↓
6. 📊 Outputs publiés dans le résumé
```

---

## 🎨 Personnalisation

### Changer la région AWS
Modifier dans le fichier `.github/workflows/terraform.yml` :
```yaml
env:
  AWS_REGION: eu-west-3  # Votre région
```

### Changer la version Terraform
```yaml
env:
  TF_VERSION: 1.8.0  # Nouvelle version
```

### Désactiver le terraform apply automatique
Ajouter `when: manual` dans le job `terraform-apply` ou supprimer le job.

### Ajouter d'autres branches
```yaml
on:
  push:
    branches:
      - main
      - develop
      - staging  # Ajouter ici
```

---

## 🐛 Troubleshooting

### ❌ Erreur : "No configuration files"
**Solution** : Vérifier que le dossier `terraform/` existe et contient des fichiers `.tf`

### ❌ Erreur : "Error: configuring Terraform AWS Provider: no valid credential sources"
**Solution** : Vérifier que les secrets `AWS_ACCESS_KEY_ID` et `AWS_SECRET_ACCESS_KEY` sont bien configurés

### ❌ Erreur : "Permission denied"
**Solution** : Vérifier les permissions IAM de l'utilisateur AWS utilisé

### ❌ Le plan Terraform est trop long pour le commentaire PR
**Solution** : Le plan est uploadé comme artifact, téléchargez-le depuis l'onglet Actions

### ⚠️ Warning : "terraform fmt check failed"
**Solution** : Formater le code localement :
```bash
cd terraform
terraform fmt -recursive
git add .
git commit -m "Format Terraform code"
```

---

## 📝 Best Practices

### ✅ À FAIRE
- [ ] Toujours créer une PR pour les changements Terraform
- [ ] Reviewer le plan Terraform avant merge
- [ ] Utiliser des credentials IAM dédiés pour la CI
- [ ] Activer les protections d'environnement pour production
- [ ] Monitorer les coûts AWS après chaque apply
- [ ] Conserver les artifacts de plan pendant 7 jours

### ❌ À ÉVITER
- ❌ Push directement sur main (bypass de la CI)
- ❌ Utiliser des credentials personnels pour la CI
- ❌ Ignorer les warnings de sécurité
- ❌ Appliquer sans reviewer le plan
- ❌ Désactiver les scans de sécurité

---

## 🚀 Premiers Pas

### 1. Configurer les secrets
```bash
# Dans GitHub : Settings > Secrets > Actions
# Ajouter AWS_ACCESS_KEY_ID
# Ajouter AWS_SECRET_ACCESS_KEY
```

### 2. Créer l'environnement production
```bash
# Dans GitHub : Settings > Environments > New environment
# Nom : production
# Activer : Required reviewers
```

### 3. Tester le workflow
```bash
# Créer une branche de test
git checkout -b test/ci-workflow

# Modifier un fichier Terraform
echo "# Test CI" >> terraform/main.tf

# Commit et push
git add .
git commit -m "test: CI workflow"
git push origin test/ci-workflow

# Créer une PR sur GitHub
# Vérifier que les jobs s'exécutent correctement
```

---

## 📚 Ressources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform GitHub Actions](https://github.com/hashicorp/setup-terraform)
- [AWS GitHub Actions](https://github.com/aws-actions/configure-aws-credentials)
- [tfsec](https://github.com/aquasecurity/tfsec)
- [Checkov](https://www.checkov.io/)

---

## 📞 Support

En cas de problème avec la CI :
1. Vérifier les logs dans l'onglet `Actions` de GitHub
2. Consulter ce README
3. Vérifier les permissions AWS
4. Contacter l'équipe DevOps

---

**Dernière mise à jour** : 31 Mars 2026

