#!/bin/bash
set -e

echo "🚀 BLACK FRIDAY SURVIVAL - DÉPLOIEMENT COMPLET"
echo "=============================================="
echo ""
echo "📋 Ce script va déployer:"
echo "  1. Infrastructure EKS (VPC, Cluster, Node Groups)"
echo "  2. Addons Kubernetes (ALB Controller, Cluster Autoscaler, Metrics Server)"
echo "  3. Stack Observabilité (Prometheus, Grafana, Jaeger)"
echo "  4. Online Boutique (11 microservices)"
echo "  5. HPA (Horizontal Pod Autoscalers)"
echo ""
echo "⏱️  Durée estimée: 25-30 minutes"
echo ""

read -p "Continuer? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Étape 1: Infrastructure EKS
echo ""
echo "======================================"
echo "📦 ÉTAPE 1/5: Infrastructure EKS"
echo "======================================"
cd terraform

echo "⚙️  Initialisation de Terraform..."
terraform init

echo "📝 Validation de la configuration..."
terraform validate

echo "🏗️  Déploiement de l'infrastructure (15-20 minutes)..."
terraform apply -auto-approve

# Récupérer les outputs
CLUSTER_NAME=$(terraform output -raw cluster_name)
AWS_REGION=$(terraform output -raw region)

echo "✅ Infrastructure EKS déployée!"
echo "  - Cluster: $CLUSTER_NAME"
echo "  - Region: $AWS_REGION"

# Étape 2: Configuration kubectl
echo ""
echo "======================================"
echo "⚙️  Configuration de kubectl"
echo "======================================"
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

echo "⏳ Attente que les nodes soient prêts..."
kubectl wait --for=condition=Ready nodes --all --timeout=600s

echo "✅ Cluster prêt!"
kubectl get nodes

# Étape 3: Addons Kubernetes
echo ""
echo "======================================"
echo "📦 ÉTAPE 2/5: Addons Kubernetes"
echo "======================================"
./deploy-addons.sh

# Étape 4: Online Boutique
echo ""
echo "======================================"
echo "🛍️  ÉTAPE 3/5: Online Boutique"
echo "======================================"
cd ..
./deploy-online-boutique.sh

# Étape 5: HPA
echo ""
echo "======================================"
echo "🔄 ÉTAPE 4/5: Horizontal Pod Autoscalers"
echo "======================================"
echo "📦 Déploiement des HPA..."
kubectl apply -f k8s-hpa.yaml

echo "⏳ Attente que tous les pods soient prêts..."
sleep 30
kubectl get hpa -n online-boutique

# Étape 6: Exposition du frontend
echo ""
echo "======================================"
echo "🌐 ÉTAPE 5/5: Exposition du Frontend"
echo "======================================"
echo "📦 Création du Load Balancer AWS..."
kubectl patch svc frontend-external -n online-boutique -p '{"spec":{"type":"LoadBalancer"}}'

echo "⏳ Attente de la création du Load Balancer (2-3 minutes)..."
kubectl wait --for=jsonpath='{.status.loadBalancer.ingress}' svc/frontend-external -n online-boutique --timeout=300s || true

FRONTEND_URL=$(kubectl get svc frontend-external -n online-boutique -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo ""
echo "✅ ✅ ✅ DÉPLOIEMENT TERMINÉ! ✅ ✅ ✅"
echo "====================================="
echo ""
echo "🌐 Frontend URL: http://$FRONTEND_URL"
echo ""
echo "📊 Dashboards:"
GRAFANA_URL=$(kubectl get svc -n monitoring kube-prometheus-stack-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "En cours...")
JAEGER_URL=$(kubectl get svc -n observability jaeger-query -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "En cours...")
echo "  - Grafana: http://$GRAFANA_URL (admin/admin123)"
echo "  - Jaeger: http://$JAEGER_URL:16686"
echo "  - CloudWatch: https://console.aws.amazon.com/cloudwatch/home?region=$AWS_REGION#dashboards:name=eks-bfs-gp12-monitoring"
echo ""
echo "🧪 Pour lancer les tests de charge:"
echo "   ./load-test.sh"
echo ""
echo "🔍 Pour surveiller:"
echo "   kubectl get pods -n online-boutique -w"
echo "   kubectl get hpa -n online-boutique -w"
echo "   kubectl top nodes"
echo ""
echo "🗑️  Pour nettoyer:"
echo "   kubectl delete namespace online-boutique"
echo "   cd terraform && terraform destroy -auto-approve"

