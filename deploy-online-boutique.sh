#!/bin/bash
set -e

# Configuration
CLUSTER_NAME="${CLUSTER_NAME:-eks-bfs-gp12}"
AWS_REGION="${AWS_REGION:-eu-south-2}"
NAMESPACE="online-boutique"
TIMEOUT="600s"

# Couleurs pour l'affichage
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Fonction pour vérifier les prérequis
check_prerequisites() {
    log_info "Vérification des prérequis..."

    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl n'est pas installé"
        exit 1
    fi

    if ! command -v aws &> /dev/null; then
        log_error "aws-cli n'est pas installé"
        exit 1
    fi

    log_info "✅ Prérequis OK"
}

# Fonction pour configurer kubectl
configure_kubectl() {
    log_info "Configuration de kubectl pour le cluster $CLUSTER_NAME..."

    if ! aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME" 2>/dev/null; then
        log_error "Impossible de configurer kubectl. Vérifiez que le cluster existe."
        exit 1
    fi

    # Vérifier la connexion au cluster
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Impossible de se connecter au cluster"
        exit 1
    fi

    log_info "✅ Connexion au cluster établie"
}

# Fonction pour créer le namespace
create_namespace() {
    log_info "Création du namespace $NAMESPACE..."

    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        log_warn "Le namespace $NAMESPACE existe déjà"
    else
        kubectl create namespace "$NAMESPACE"
        log_info "✅ Namespace créé"
    fi
}

# Fonction pour déployer les ressources Kubernetes
deploy_resources() {
    log_info "Déploiement des ressources Kubernetes (StorageClass, Quotas, Limits)..."

    if [ -f "./k8s-resources.yaml" ]; then
        kubectl apply -f ./k8s-resources.yaml
        log_info "✅ Ressources appliquées"
    else
        log_warn "Fichier k8s-resources.yaml non trouvé, skip"
    fi
}

# Fonction pour déployer les microservices
deploy_microservices() {
    log_info "Déploiement des 11 microservices d'Online Boutique..."

    if [ ! -d "./kubernetes-manifests" ]; then
        log_error "Dossier kubernetes-manifests non trouvé"
        exit 1
    fi

    local deployed_count=0
    for file in ./kubernetes-manifests/*.yaml; do
        if [[ ! "$file" =~ "kustomization.yaml" ]]; then
            log_info "Déploiement de $(basename $file)..."
            kubectl apply -f "$file" -n "$NAMESPACE"
            ((deployed_count++))
        fi
    done

    log_info "✅ $deployed_count fichiers déployés"
}

# Fonction pour attendre que les pods soient prêts
wait_for_pods() {
    log_info "Attente que les pods soient prêts (timeout: $TIMEOUT)..."

    if kubectl wait --for=condition=Ready pods --all -n "$NAMESPACE" --timeout="$TIMEOUT" 2>/dev/null; then
        log_info "✅ Tous les pods sont prêts"
    else
        log_warn "Certains pods ne sont pas encore prêts. Vérifiez avec: kubectl get pods -n $NAMESPACE"
    fi
}

# Fonction pour déployer les HPA
deploy_hpa() {
    log_info "Déploiement des HPA (Horizontal Pod Autoscalers)..."

    if [ -f "./k8s-hpa.yaml" ]; then
        kubectl apply -f ./k8s-hpa.yaml
        log_info "✅ HPA déployés"
    else
        log_warn "Fichier k8s-hpa.yaml non trouvé, skip"
    fi
}

# Fonction pour déployer les Network Policies
deploy_network_policies() {
    log_info "Déploiement des Network Policies..."

    if [ -f "./k8s-network-policies.yaml" ]; then
        kubectl apply -f ./k8s-network-policies.yaml
        log_info "✅ Network Policies déployées"
    else
        log_warn "Fichier k8s-network-policies.yaml non trouvé, skip"
    fi
}

# Fonction pour afficher le statut final
show_status() {
    echo ""
    log_info "=========================================="
    log_info "📊 État final du déploiement"
    log_info "=========================================="
    echo ""

    log_info "Pods:"
    kubectl get pods -n "$NAMESPACE" -o wide

    echo ""
    log_info "Services:"
    kubectl get svc -n "$NAMESPACE"

    echo ""
    log_info "HPA:"
    kubectl get hpa -n "$NAMESPACE" 2>/dev/null || log_warn "HPA non disponibles"

    echo ""
    log_info "=========================================="
}

# Fonction pour afficher les instructions post-déploiement
show_instructions() {
    echo ""
    log_info "🎉 Online Boutique déployé avec succès!"
    echo ""
    echo "📝 Prochaines étapes:"
    echo ""
    echo "1️⃣  Exposer le frontend avec un Load Balancer AWS:"
    echo "   kubectl patch svc frontend-external -n $NAMESPACE -p '{\"spec\":{\"type\":\"LoadBalancer\"}}'"
    echo ""
    echo "2️⃣  Récupérer l'URL du frontend:"
    echo "   kubectl get svc frontend-external -n $NAMESPACE"
    echo ""
    echo "3️⃣  Surveiller les pods:"
    echo "   kubectl get pods -n $NAMESPACE -w"
    echo ""
    echo "4️⃣  Lancer les tests de charge:"
    echo "   ./load-test.sh"
    echo ""
}

# Main
main() {
    echo "🛍️  Déploiement d'Online Boutique sur EKS"
    echo "=========================================="
    echo ""

    check_prerequisites
    configure_kubectl
    create_namespace
    deploy_resources
    deploy_microservices
    wait_for_pods
    deploy_hpa
    deploy_network_policies
    show_status
    show_instructions
}

# Exécuter le script
main
