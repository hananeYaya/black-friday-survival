#!/bin/bash

# Script pour arrêter proprement un test de charge

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ -z "$1" ]; then
    echo -e "${RED}Usage: $0 <deployment-name>${NC}"
    echo ""
    echo "Exemple:"
    echo "  $0 loadgenerator-test-5000"
    echo "  $0 loadgenerator-5000.yaml  (détecte automatiquement)"
    echo ""
    echo -e "${CYAN}Deployments loadgenerator disponibles:${NC}"
    kubectl get deployments | grep loadgenerator || echo "Aucun test en cours"
    exit 1
fi

INPUT=$1

# Si l'utilisateur passe un fichier .yaml, extraire le nom du deployment
if [[ "$INPUT" == *.yaml ]]; then
    # Extraire le nom du fichier sans extension
    FILENAME=$(basename "$INPUT" .yaml)

    # Chercher un deployment correspondant
    # Patterns possibles: loadgenerator-1000.yaml -> loadgenerator-test-1000 ou loadgenerator-1000
    if kubectl get deployment "loadgenerator-test-${FILENAME#loadgenerator-}" &>/dev/null; then
        DEPLOYMENT_NAME="loadgenerator-test-${FILENAME#loadgenerator-}"
        echo -e "${YELLOW}ℹ️  Fichier YAML détecté. Utilisation du deployment: $DEPLOYMENT_NAME${NC}"
        echo ""
    elif kubectl get deployment "$FILENAME" &>/dev/null; then
        DEPLOYMENT_NAME="$FILENAME"
        echo -e "${YELLOW}ℹ️  Fichier YAML détecté. Utilisation du deployment: $DEPLOYMENT_NAME${NC}"
        echo ""
    else
        echo -e "${RED}❌ Aucun deployment trouvé pour le fichier $INPUT${NC}"
        echo ""
        echo "Deployments disponibles:"
        kubectl get deployments | grep loadgenerator
        exit 1
    fi
else
    DEPLOYMENT_NAME=$INPUT
fi

echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║         ARRÊT DU TEST DE CHARGE                           ║${NC}"
echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Vérifier que le deployment existe
if ! kubectl get deployment $DEPLOYMENT_NAME &>/dev/null; then
    echo -e "${RED}❌ Le deployment $DEPLOYMENT_NAME n'existe pas${NC}"
    exit 1
fi

# Obtenir le nombre actuel de replicas
CURRENT_REPLICAS=$(kubectl get deployment $DEPLOYMENT_NAME -o jsonpath='{.spec.replicas}')
echo "Replicas actuelles: $CURRENT_REPLICAS"
echo ""

echo "Choisissez une option:"
echo "  1) Arrêt progressif (recommandé)"
echo "  2) Arrêt immédiat"
echo "  3) Suppression complète du deployment"
echo "  4) Annuler"
echo ""
read -p "Votre choix [1-4]: " choice

case $choice in
    1)
        echo ""
        echo -e "${YELLOW}Arrêt progressif...${NC}"

        if [ $CURRENT_REPLICAS -gt 50 ]; then
            echo "Réduction à 50 replicas..."
            kubectl scale deployment $DEPLOYMENT_NAME --replicas=50
            sleep 30
        fi

        if [ $CURRENT_REPLICAS -gt 20 ]; then
            echo "Réduction à 20 replicas..."
            kubectl scale deployment $DEPLOYMENT_NAME --replicas=20
            sleep 30
        fi

        if [ $CURRENT_REPLICAS -gt 10 ]; then
            echo "Réduction à 10 replicas..."
            kubectl scale deployment $DEPLOYMENT_NAME --replicas=10
            sleep 30
        fi

        echo "Arrêt total..."
        kubectl scale deployment $DEPLOYMENT_NAME --replicas=0

        echo ""
        echo -e "${GREEN}✅ Test arrêté progressivement${NC}"
        ;;

    2)
        echo ""
        echo -e "${YELLOW}Arrêt immédiat...${NC}"
        kubectl scale deployment $DEPLOYMENT_NAME --replicas=0
        echo ""
        echo -e "${GREEN}✅ Test arrêté${NC}"
        ;;

    3)
        echo ""
        echo -e "${RED}⚠️  Suppression du deployment...${NC}"
        kubectl delete deployment $DEPLOYMENT_NAME
        echo ""
        echo -e "${GREEN}✅ Deployment supprimé${NC}"
        ;;

    4)
        echo ""
        echo "Annulé."
        exit 0
        ;;

    *)
        echo ""
        echo -e "${RED}Choix invalide${NC}"
        exit 1
        ;;
esac

echo ""
echo "État actuel:"
kubectl get pods -l app=$DEPLOYMENT_NAME 2>/dev/null || echo "Aucun pod"
echo ""
echo "Nodes:"
kubectl get nodes
echo ""
echo -e "${CYAN}Le Cluster Autoscaler va automatiquement réduire le nombre de nodes${NC}"
echo -e "${CYAN}dans les 10-15 prochaines minutes.${NC}"

