#!/bin/bash

# 📊 Script d'Accès Rapide à Grafana

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 Accès à Grafana - Black Friday Survival${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Vérifier que kubectl est configuré
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Erreur : kubectl n'est pas configuré${NC}"
    echo -e "${YELLOW}💡 Exécutez : aws eks update-kubeconfig --region eu-west-1 --name eks-bfs-gp12${NC}"
    exit 1
fi

# Vérifier que Grafana est déployé
echo -e "${YELLOW}🔍 Vérification du déploiement Grafana...${NC}"
if ! kubectl get svc -n monitoring kube-prometheus-stack-grafana &> /dev/null; then
    echo -e "${RED}❌ Erreur : Grafana n'est pas déployé${NC}"
    echo -e "${YELLOW}💡 Vérifiez que Terraform a bien provisionné l'infrastructure${NC}"
    exit 1
fi

# Vérifier que le pod Grafana est Running
POD_STATUS=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
if [ "$POD_STATUS" != "Running" ]; then
    echo -e "${RED}❌ Erreur : Le pod Grafana n'est pas en état Running (statut: $POD_STATUS)${NC}"
    kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana
    exit 1
fi

echo -e "${GREEN}✅ Grafana est déployé et opérationnel${NC}"
echo ""

# Récupérer le mot de passe Grafana
echo -e "${YELLOW}🔍 Récupération du mot de passe Grafana...${NC}"
GRAFANA_PASSWORD=$(kubectl get secret -n monitoring kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" 2>/dev/null | base64 --decode)

if [ -z "$GRAFANA_PASSWORD" ]; then
    echo -e "${RED}❌ Erreur : Impossible de récupérer le mot de passe Grafana${NC}"
    exit 1
fi

# Afficher les informations de connexion
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🔑 Informations de Connexion${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${YELLOW}URL       :${NC} http://localhost:3000"
echo -e "  ${YELLOW}Username  :${NC} admin"
echo -e "  ${YELLOW}Password  :${NC} ${GRAFANA_PASSWORD}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Vérifier si le port 3000 est déjà utilisé
if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo -e "${YELLOW}⚠️  Le port 3000 est déjà utilisé${NC}"
    echo ""
    echo -e "${YELLOW}Options :${NC}"
    echo -e "  1) Tuer le processus existant et redémarrer"
    echo -e "  2) Ouvrir http://localhost:3000 dans le navigateur"
    echo -e "  3) Quitter"
    echo ""
    read -p "Votre choix [1-3] : " choice

    case $choice in
        1)
            echo -e "${YELLOW}🔄 Arrêt du processus sur le port 3000...${NC}"
            PID=$(lsof -ti:3000)
            kill -9 $PID 2>/dev/null
            sleep 2
            ;;
        2)
            echo -e "${GREEN}🌐 Ouverture de Grafana dans le navigateur...${NC}"
            open http://localhost:3000 2>/dev/null || xdg-open http://localhost:3000 2>/dev/null
            exit 0
            ;;
        3)
            echo -e "${BLUE}👋 Au revoir !${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Choix invalide${NC}"
            exit 1
            ;;
    esac
fi

# Démarrer le port-forward
echo -e "${GREEN}🚀 Démarrage du port-forward...${NC}"
echo -e "${YELLOW}💡 Appuyez sur Ctrl+C pour arrêter${NC}"
echo ""

# Fonction pour cleanup
cleanup() {
    echo ""
    echo -e "${YELLOW}🛑 Arrêt du port-forward...${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Lancer le port-forward avec auto-reconnect
while true; do
    kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
    EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ]; then
        break
    fi

    echo -e "${YELLOW}⚠️  Port-forward interrompu, reconnexion dans 3 secondes...${NC}"
    sleep 3
done

