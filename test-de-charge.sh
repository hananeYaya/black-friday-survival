#!/bin/bash

# Script de test de charge interactif
# Permet de simuler N utilisateurs avec surveillance en temps réel

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

clear

echo -e "${GREEN}${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║      SCRIPT DE TEST DE CHARGE - BLACK FRIDAY SURVIVAL    ║${NC}"
echo -e "${GREEN}${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Fonction pour afficher une barre de progression
progress_bar() {
    local duration=$1
    local steps=50
    local sleep_time=$(echo "scale=2; $duration / $steps" | bc)

    echo -ne "["
    for ((i=0; i<steps; i++)); do
        echo -ne "="
        sleep $sleep_time
    done
    echo -e "] Done!"
}

# Fonction pour surveiller en temps réel
monitor_test() {
    local deployment_name=$1
    local target_users=$2

    clear
    echo -e "${CYAN}${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║           SURVEILLANCE EN TEMPS RÉEL                      ║${NC}"
    echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    while true; do
        # Effacer l'écran pour la mise à jour
        tput cup 4 0

        # Date et heure
        echo -e "${YELLOW}📅 $(date '+%Y-%m-%d %H:%M:%S')${NC}"
        echo ""

        # Loadgenerators
        echo -e "${BLUE}━━━ LOADGENERATORS (Charge simulée) ━━━${NC}"
        LOADGEN_RUNNING=$(kubectl get pods -l app=$deployment_name --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l | tr -d ' ')
        LOADGEN_TOTAL=$(kubectl get pods -l app=$deployment_name --no-headers 2>/dev/null | wc -l | tr -d ' ')
        USERS=$((LOADGEN_RUNNING * 100))

        if [ "$LOADGEN_RUNNING" -eq "$LOADGEN_TOTAL" ]; then
            echo -e "${GREEN}✅ Loadgenerators: $LOADGEN_RUNNING/$LOADGEN_TOTAL Running${NC}"
            echo -e "${GREEN}✅ Utilisateurs simulés: $USERS/$target_users${NC}"
        else
            echo -e "${YELLOW}⏳ Loadgenerators: $LOADGEN_RUNNING/$LOADGEN_TOTAL Running${NC}"
            echo -e "${YELLOW}⏳ Utilisateurs simulés: $USERS/$target_users (démarrage...)${NC}"
        fi
        echo ""

        # HPAs
        echo -e "${BLUE}━━━ AUTO-SCALING (HPAs) ━━━${NC}"
        kubectl get hpa 2>/dev/null | head -6 || echo "Pas de HPA configuré"
        echo ""

        # Pods count
        echo -e "${BLUE}━━━ NOMBRE DE PODS PAR SERVICE ━━━${NC}"
        printf "%-25s : %s\n" "Frontend" "$(kubectl get pods -l app=frontend --no-headers 2>/dev/null | wc -l | tr -d ' ')"
        printf "%-25s : %s\n" "Product Catalog" "$(kubectl get pods -l app=productcatalogservice --no-headers 2>/dev/null | wc -l | tr -d ' ')"
        printf "%-25s : %s\n" "Checkout" "$(kubectl get pods -l app=checkoutservice --no-headers 2>/dev/null | wc -l | tr -d ' ')"
        printf "%-25s : %s\n" "Cart" "$(kubectl get pods -l app=cartservice --no-headers 2>/dev/null | wc -l | tr -d ' ')"
        printf "%-25s : %s\n" "Recommendation" "$(kubectl get pods -l app=recommendationservice --no-headers 2>/dev/null | wc -l | tr -d ' ')"
        echo ""

        # Nodes
        echo -e "${BLUE}━━━ NODES (Cluster Autoscaler) ━━━${NC}"
        NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')
        echo "Nombre de nodes actifs: $NODE_COUNT"
        echo ""

        # Top Pods CPU
        echo -e "${BLUE}━━━ TOP 5 PODS (CPU) ━━━${NC}"
        kubectl top pods --no-headers 2>/dev/null | sort -k2 -hr | head -5 || echo "Metrics Server non disponible"
        echo ""

        # Instructions
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}Appuyez sur Ctrl+C pour arrêter la surveillance${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

        # Pause avant le prochain refresh
        sleep 5
    done
}

# Changement de répertoire vers le dossier du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ═══════════════════════════════════════════════════════════
# ÉTAPE 1 : CONFIGURATION
# ═══════════════════════════════════════════════════════════

echo -e "${YELLOW}${BOLD}[ÉTAPE 1/5] Configuration du test${NC}"
echo ""

# Demander le nombre d'utilisateurs
while true; do
    echo -e "${CYAN}Combien d'utilisateurs voulez-vous simuler ?${NC}"
    echo "  1) 1000 utilisateurs   (10 loadgenerators)"
    echo "  2) 2000 utilisateurs   (20 loadgenerators)"
    echo "  3) 5000 utilisateurs   (50 loadgenerators) ${RED}[ATTENTION: Charge élevée]${NC}"
    echo "  4) 10000 utilisateurs  (100 loadgenerators) ${RED}[DANGER: Très haute charge]${NC}"
    echo "  5) Nombre personnalisé"
    echo ""
    read -p "Votre choix [1-5]: " choice

    case $choice in
        1)
            USERS=1000
            REPLICAS=10
            break
            ;;
        2)
            USERS=2000
            REPLICAS=20
            break
            ;;
        3)
            USERS=5000
            REPLICAS=50
            break
            ;;
        4)
            USERS=10000
            REPLICAS=100
            break
            ;;
        5)
            read -p "Nombre d'utilisateurs à simuler: " USERS
            REPLICAS=$((USERS / 100))
            if [ $REPLICAS -lt 1 ]; then
                REPLICAS=1
            fi
            break
            ;;
        *)
            echo -e "${RED}Choix invalide. Veuillez choisir entre 1 et 5.${NC}"
            echo ""
            ;;
    esac
done

echo ""
echo -e "${GREEN}✅ Configuration: $USERS utilisateurs ($REPLICAS loadgenerators)${NC}"
echo ""

# Nom du déploiement
DEPLOYMENT_NAME="loadgenerator-test-${USERS}"
YAML_FILE="loadgenerator-${USERS}.yaml"

# Confirmation
echo -e "${YELLOW}⚠️  ATTENTION${NC}"
echo "Ce test va créer $REPLICAS pods qui vont générer $USERS requêtes simultanées."
echo "Le Cluster Autoscaler va probablement ajouter des nodes supplémentaires."
echo ""
read -p "Voulez-vous continuer ? (o/n): " confirm

if [[ ! $confirm =~ ^[Oo]$ ]]; then
    echo -e "${RED}Test annulé.${NC}"
    exit 0
fi

echo ""

# ═══════════════════════════════════════════════════════════
# ÉTAPE 2 : CRÉATION DU YAML
# ═══════════════════════════════════════════════════════════

echo -e "${YELLOW}${BOLD}[ÉTAPE 2/5] Préparation du fichier de configuration${NC}"
echo ""

if [ -f "$YAML_FILE" ]; then
    echo -e "${GREEN}✅ Le fichier $YAML_FILE existe déjà${NC}"
else
    echo -e "${CYAN}Création du fichier $YAML_FILE...${NC}"

    cat > "$YAML_FILE" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $DEPLOYMENT_NAME
  labels:
    app: $DEPLOYMENT_NAME
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
      serviceAccountName: default
      terminationGracePeriodSeconds: 5
      restartPolicy: Always
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

    echo -e "${GREEN}✅ Fichier $YAML_FILE créé${NC}"
fi

echo ""

# ═══════════════════════════════════════════════════════════
# ÉTAPE 3 : VÉRIFICATION DE L'INFRASTRUCTURE
# ═══════════════════════════════════════════════════════════

echo -e "${YELLOW}${BOLD}[ÉTAPE 3/5] Vérification de l'infrastructure${NC}"
echo ""

echo "État actuel:"
CURRENT_NODES=$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')
CURRENT_PODS=$(kubectl get pods --no-headers 2>/dev/null | wc -l | tr -d ' ')
echo "  - Nodes: $CURRENT_NODES"
echo "  - Pods: $CURRENT_PODS"
echo ""

# Vérifier les HPAs
HPA_COUNT=$(kubectl get hpa --no-headers 2>/dev/null | wc -l | tr -d ' ')
if [ "$HPA_COUNT" -lt 5 ]; then
    echo -e "${YELLOW}⚠️  Nombre de HPAs configurés: $HPA_COUNT/5${NC}"
    read -p "Voulez-vous configurer les HPAs maintenant ? (o/n): " setup_hpa

    if [[ $setup_hpa =~ ^[Oo]$ ]]; then
        echo "Configuration des HPAs..."
        kubectl autoscale deployment frontend --cpu-percent=70 --min=2 --max=20 2>/dev/null || echo "  HPA frontend déjà configuré"
        kubectl autoscale deployment productcatalogservice --cpu-percent=70 --min=2 --max=10 2>/dev/null || echo "  HPA productcatalog déjà configuré"
        kubectl autoscale deployment checkoutservice --cpu-percent=70 --min=2 --max=15 2>/dev/null || echo "  HPA checkout déjà configuré"
        kubectl autoscale deployment cartservice --cpu-percent=70 --min=2 --max=10 2>/dev/null || echo "  HPA cart déjà configuré"
        kubectl autoscale deployment recommendationservice --cpu-percent=70 --min=2 --max=10 2>/dev/null || echo "  HPA recommendation déjà configuré"
        echo -e "${GREEN}✅ HPAs configurés${NC}"
    fi
else
    echo -e "${GREEN}✅ HPAs configurés: $HPA_COUNT${NC}"
fi

echo ""

# ═══════════════════════════════════════════════════════════
# ÉTAPE 4 : DÉPLOIEMENT DES LOADGENERATORS
# ═══════════════════════════════════════════════════════════

echo -e "${YELLOW}${BOLD}[ÉTAPE 4/5] Déploiement des loadgenerators${NC}"
echo ""

echo "Déploiement de $REPLICAS loadgenerators..."
kubectl apply -f "$YAML_FILE"

echo ""
echo -e "${GREEN}✅ Déploiement lancé${NC}"
echo ""

echo "Attente du démarrage des pods (60 secondes)..."
progress_bar 60

echo ""

# Vérifier l'état du déploiement
LOADGEN_RUNNING=$(kubectl get pods -l app=$DEPLOYMENT_NAME --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l | tr -d ' ')
LOADGEN_TOTAL=$(kubectl get pods -l app=$DEPLOYMENT_NAME --no-headers 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo -e "${CYAN}État du déploiement:${NC}"
echo "  - Loadgenerators Running: $LOADGEN_RUNNING/$LOADGEN_TOTAL"
echo "  - Utilisateurs simulés: $((LOADGEN_RUNNING * 100))/$USERS"
echo ""

if [ "$LOADGEN_RUNNING" -lt "$LOADGEN_TOTAL" ]; then
    echo -e "${YELLOW}⏳ Tous les pods ne sont pas encore démarrés.${NC}"
    echo "   Ils vont continuer à démarrer en arrière-plan."
    echo ""
fi

# ═══════════════════════════════════════════════════════════
# ÉTAPE 5 : SURVEILLANCE EN TEMPS RÉEL
# ═══════════════════════════════════════════════════════════

echo -e "${YELLOW}${BOLD}[ÉTAPE 5/5] Surveillance en temps réel${NC}"
echo ""

echo -e "${CYAN}Le mode surveillance va s'afficher dans 3 secondes...${NC}"
echo ""
echo "Appuyez sur Ctrl+C pour arrêter la surveillance (les tests continueront en arrière-plan)"
sleep 3

# Trap Ctrl+C pour sortir proprement de la surveillance
trap ctrl_c INT
function ctrl_c() {
    echo ""
    echo ""
    echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║         Surveillance arrêtée                              ║${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    show_stop_commands
    exit 0
}

# Fonction pour afficher les commandes d'arrêt
show_stop_commands() {
    echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}  TEST DE CHARGE EN COURS - $USERS UTILISATEURS${NC}"
    echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${CYAN}📊 INFORMATIONS DU TEST${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Deployment      : $DEPLOYMENT_NAME"
    echo "Replicas        : $REPLICAS loadgenerators"
    echo "Utilisateurs    : $USERS"
    echo "Fichier YAML    : $YAML_FILE"
    echo ""

    echo -e "${YELLOW}📈 COMMANDES DE SURVEILLANCE${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Surveiller les HPAs (auto-scaling):"
    echo "  ${GREEN}watch kubectl get hpa${NC}"
    echo ""
    echo "Surveiller les nodes:"
    echo "  ${GREEN}watch kubectl get nodes${NC}"
    echo ""
    echo "Voir les loadgenerators:"
    echo "  ${GREEN}kubectl get pods -l app=$DEPLOYMENT_NAME${NC}"
    echo ""
    echo "Métriques CPU/RAM:"
    echo "  ${GREEN}kubectl top pods${NC}"
    echo "  ${GREEN}kubectl top nodes${NC}"
    echo ""

    echo -e "${RED}🛑 COMMANDES POUR ARRÊTER LE TEST${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Option 1 : Arrêt progressif (RECOMMANDÉ)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [ $REPLICAS -ge 50 ]; then
        echo "  # Réduire à 50%"
        echo "  ${RED}kubectl scale deployment $DEPLOYMENT_NAME --replicas=$((REPLICAS / 2))${NC}"
        echo ""
    fi

    if [ $REPLICAS -ge 20 ]; then
        echo "  # Réduire à 1000 utilisateurs"
        echo "  ${RED}kubectl scale deployment $DEPLOYMENT_NAME --replicas=10${NC}"
        echo ""
    fi

    echo "  # Arrêt total"
    echo "  ${RED}kubectl scale deployment $DEPLOYMENT_NAME --replicas=0${NC}"
    echo ""

    echo "Option 2 : Suppression complète"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ${RED}kubectl delete deployment $DEPLOYMENT_NAME${NC}"
    echo ""

    echo "Option 3 : Utiliser le script d'arrêt"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ${RED}./stop-test.sh $DEPLOYMENT_NAME${NC}"
    echo ""

    echo -e "${CYAN}💡 CONSEIL${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Laissez le test tourner 15-30 minutes pour observer le comportement"
    echo "du cluster sous charge et l'auto-scaling en action."
    echo ""
}

# Lancer la surveillance
monitor_test "$DEPLOYMENT_NAME" "$USERS"

