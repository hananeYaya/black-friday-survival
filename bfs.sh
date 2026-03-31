#!/bin/bash

# Script principal pour Black Friday Survival
# Gère le déploiement et les tests de charge

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

NAMESPACE="online-boutique"

# Fonction pour afficher le menu principal
show_menu() {
    clear
    echo -e "${GREEN}${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║           BLACK FRIDAY SURVIVAL - MENU PRINCIPAL          ║${NC}"
    echo -e "${GREEN}${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}DÉPLOIEMENT${NC}"
    echo "  1) Déployer l'application Online Boutique"
    echo "  2) Exposer le frontend (LoadBalancer)"
    echo ""
    echo -e "${CYAN}TESTS DE CHARGE${NC}"
    echo "  3) Lancer un test de charge"
    echo "  4) Arrêter un test de charge"
    echo "  5) Nettoyer tous les tests temporaires"
    echo ""
    echo -e "${CYAN}SURVEILLANCE${NC}"
    echo "  6) Voir l'état du cluster"
    echo "  7) Surveiller les HPAs"
    echo "  8) Voir les métriques"
    echo ""
    echo -e "${CYAN}AUTRE${NC}"
    echo "  9) Aide / Documentation"
    echo "  0) Quitter"
    echo ""
}

# Fonction 1 : Déployer l'application
deploy_app() {
    echo -e "${YELLOW}${BOLD}[DÉPLOIEMENT DE L'APPLICATION]${NC}"
    echo ""

    if [ -f "./deploy-online-boutique.sh" ]; then
        ./deploy-online-boutique.sh
    else
        echo -e "${RED}❌ Script deploy-online-boutique.sh introuvable${NC}"
    fi

    echo ""
    read -p "Appuyez sur ENTRÉE pour continuer..."
}

# Fonction 2 : Exposer le frontend
expose_frontend() {
    echo -e "${YELLOW}${BOLD}[EXPOSITION DU FRONTEND]${NC}"
    echo ""

    echo "Vérification du service frontend..."
    kubectl get svc frontend-external -n $NAMESPACE 2>/dev/null || {
        echo -e "${RED}❌ Service frontend-external introuvable${NC}"
        echo "Déployez d'abord l'application (option 1)"
        read -p "Appuyez sur ENTRÉE pour continuer..."
        return
    }

    TYPE=$(kubectl get svc frontend-external -n $NAMESPACE -o jsonpath='{.spec.type}')

    if [ "$TYPE" = "LoadBalancer" ]; then
        echo -e "${GREEN}✅ Le frontend est déjà exposé${NC}"
        echo ""
        URL=$(kubectl get svc frontend-external -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
        if [ -n "$URL" ]; then
            echo -e "${CYAN}URL: http://$URL${NC}"
        else
            echo -e "${YELLOW}⏳ LoadBalancer en cours de provisionnement...${NC}"
        fi
    else
        echo "Exposition du frontend..."
        kubectl patch svc frontend-external -n $NAMESPACE -p '{"spec":{"type":"LoadBalancer"}}'
        echo ""
        echo -e "${GREEN}✅ Frontend exposé${NC}"
        echo ""
        echo "Attente du LoadBalancer (30 secondes)..."
        sleep 30
        URL=$(kubectl get svc frontend-external -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
        if [ -n "$URL" ]; then
            echo -e "${CYAN}URL: http://$URL${NC}"
        fi
    fi

    echo ""
    read -p "Appuyez sur ENTRÉE pour continuer..."
}

# Fonction 3 : Lancer un test de charge
start_load_test() {
    echo -e "${YELLOW}${BOLD}[TEST DE CHARGE]${NC}"
    echo ""

    # Demander le nombre d'utilisateurs
    USER_COUNT=""
    while [ -z "$USER_COUNT" ]; do
        read -p "Nombre d'utilisateurs à tester: " USER_COUNT
        if [ -z "$USER_COUNT" ]; then
            echo -e "${RED}⚠️  Nombre obligatoire !${NC}"
        elif ! [[ "$USER_COUNT" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}⚠️  Nombre invalide !${NC}"
            USER_COUNT=""
        fi
    done

    REPLICAS=$((USER_COUNT / 100))
    if [ $REPLICAS -lt 1 ]; then
        REPLICAS=1
    fi

    echo ""
    echo -e "${GREEN}Configuration: $USER_COUNT users ($REPLICAS pods)${NC}"
    echo ""
    read -p "Continuer ? (o/n): " confirm

    if [[ ! $confirm =~ ^[Oo]$ ]]; then
        return
    fi

    # Créer le deployment
    DEPLOYMENT_NAME="loadgenerator-test-$$"
    YAML_FILE="/tmp/loadgenerator-$$.yaml"

    cat > "$YAML_FILE" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $DEPLOYMENT_NAME
  namespace: $NAMESPACE
spec:
  replicas: $REPLICAS
  selector:
    matchLabels:
      app: $DEPLOYMENT_NAME
  template:
    metadata:
      labels:
        app: $DEPLOYMENT_NAME
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

    echo "Déploiement en cours..."
    kubectl apply -f "$YAML_FILE"

    echo ""
    echo -e "${GREEN}✅ Test lancé: $DEPLOYMENT_NAME${NC}"
    echo ""
    echo -e "${CYAN}Commandes utiles:${NC}"
    echo "  Surveiller: watch kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT_NAME"
    echo "  Arrêter: kubectl scale deployment $DEPLOYMENT_NAME -n $NAMESPACE --replicas=0"
    echo ""
    read -p "Appuyez sur ENTRÉE pour continuer..."
}

# Fonction 4 : Arrêter un test
stop_load_test() {
    echo -e "${YELLOW}${BOLD}[ARRÊT D'UN TEST]${NC}"
    echo ""

    DEPLOYMENTS=$(kubectl get deployments -n $NAMESPACE --no-headers 2>/dev/null | grep "loadgenerator-test-" | awk '{print $1}')

    if [ -z "$DEPLOYMENTS" ]; then
        echo -e "${GREEN}✅ Aucun test en cours${NC}"
        read -p "Appuyez sur ENTRÉE pour continuer..."
        return
    fi

    echo "Tests en cours:"
    echo "$DEPLOYMENTS" | nl
    echo ""
    read -p "Numéro du test à arrêter (ou 0 pour annuler): " choice

    if [ "$choice" = "0" ]; then
        return
    fi

    DEPLOYMENT=$(echo "$DEPLOYMENTS" | sed -n "${choice}p")

    if [ -z "$DEPLOYMENT" ]; then
        echo -e "${RED}Choix invalide${NC}"
        read -p "Appuyez sur ENTRÉE pour continuer..."
        return
    fi

    echo ""
    echo "Arrêt de $DEPLOYMENT..."
    kubectl scale deployment $DEPLOYMENT -n $NAMESPACE --replicas=0

    echo ""
    echo -e "${GREEN}✅ Test arrêté${NC}"
    echo ""
    read -p "Supprimer le deployment ? (o/n): " delete_confirm

    if [[ $delete_confirm =~ ^[Oo]$ ]]; then
        kubectl delete deployment $DEPLOYMENT -n $NAMESPACE
        echo -e "${GREEN}✅ Deployment supprimé${NC}"
    fi

    echo ""
    read -p "Appuyez sur ENTRÉE pour continuer..."
}

# Fonction 5 : Nettoyer tous les tests
cleanup_all_tests() {
    echo -e "${YELLOW}${BOLD}[NETTOYAGE DES TESTS]${NC}"
    echo ""

    DEPLOYMENTS=$(kubectl get deployments -n $NAMESPACE --no-headers 2>/dev/null | grep "loadgenerator-test-" | awk '{print $1}')

    if [ -z "$DEPLOYMENTS" ]; then
        echo -e "${GREEN}✅ Aucun test à nettoyer${NC}"
        read -p "Appuyez sur ENTRÉE pour continuer..."
        return
    fi

    echo "Tests trouvés:"
    echo "$DEPLOYMENTS" | nl
    echo ""
    read -p "Supprimer TOUS ces tests ? (o/n): " confirm

    if [[ ! $confirm =~ ^[Oo]$ ]]; then
        return
    fi

    echo ""
    for deployment in $DEPLOYMENTS; do
        echo "Suppression de $deployment..."
        kubectl delete deployment $deployment -n $NAMESPACE
    done

    echo ""
    echo -e "${GREEN}✅ Nettoyage terminé${NC}"
    echo ""
    read -p "Appuyez sur ENTRÉE pour continuer..."
}

# Fonction 6 : État du cluster
show_cluster_status() {
    echo -e "${YELLOW}${BOLD}[ÉTAT DU CLUSTER]${NC}"
    echo ""

    echo -e "${CYAN}Nodes:${NC}"
    kubectl get nodes

    echo ""
    echo -e "${CYAN}Pods dans $NAMESPACE:${NC}"
    kubectl get pods -n $NAMESPACE

    echo ""
    echo -e "${CYAN}Services:${NC}"
    kubectl get svc -n $NAMESPACE

    echo ""
    read -p "Appuyez sur ENTRÉE pour continuer..."
}

# Fonction 7 : Surveiller HPAs
monitor_hpa() {
    echo -e "${YELLOW}${BOLD}[SURVEILLANCE HPAs]${NC}"
    echo ""
    echo "Appuyez sur Ctrl+C pour arrêter"
    echo ""
    sleep 2
    watch kubectl get hpa -n $NAMESPACE
}

# Fonction 8 : Voir les métriques
show_metrics() {
    echo -e "${YELLOW}${BOLD}[MÉTRIQUES]${NC}"
    echo ""

    echo -e "${CYAN}Nodes:${NC}"
    kubectl top nodes 2>/dev/null || echo "Metrics Server non disponible"

    echo ""
    echo -e "${CYAN}Pods (Top 10):${NC}"
    kubectl top pods -n $NAMESPACE 2>/dev/null | head -11 || echo "Metrics Server non disponible"

    echo ""
    read -p "Appuyez sur ENTRÉE pour continuer..."
}

# Fonction 9 : Aide
show_help() {
    echo -e "${YELLOW}${BOLD}[AIDE]${NC}"
    echo ""
    echo "Documentation disponible:"
    echo "  • DEPLOYMENT-GUIDE.md - Guide complet de déploiement"
    echo "  • LOAD-TEST-GUIDE.md - Guide des tests de charge"
    echo "  • RESOURCES-INSTALLED.md - Liste des ressources"
    echo ""
    echo "Commandes kubectl utiles:"
    echo "  kubectl get pods -n $NAMESPACE"
    echo "  kubectl get hpa -n $NAMESPACE"
    echo "  kubectl top nodes"
    echo "  kubectl logs -n $NAMESPACE <pod-name>"
    echo ""
    read -p "Appuyez sur ENTRÉE pour continuer..."
}

# Boucle principale
while true; do
    show_menu
    read -p "Votre choix: " choice

    case $choice in
        1) deploy_app ;;
        2) expose_frontend ;;
        3) start_load_test ;;
        4) stop_load_test ;;
        5) cleanup_all_tests ;;
        6) show_cluster_status ;;
        7) monitor_hpa ;;
        8) show_metrics ;;
        9) show_help ;;
        0)
            echo ""
            echo "Au revoir !"
            exit 0
            ;;
        *)
            echo -e "${RED}Choix invalide${NC}"
            sleep 1
            ;;
    esac
done

