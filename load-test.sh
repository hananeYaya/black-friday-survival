#!/bin/bash
set -e

# Script de test de charge pour Black Friday Survival
# Utilise des loadgenerators Kubernetes pour simuler N utilisateurs

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

clear

echo -e "${GREEN}${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║      TEST DE CHARGE - BLACK FRIDAY SURVIVAL               ║${NC}"
echo -e "${GREEN}${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

NAMESPACE="online-boutique"

# Vérifier que le namespace existe
if ! kubectl get namespace $NAMESPACE &>/dev/null; then
  echo -e "${RED}❌ Le namespace $NAMESPACE n'existe pas${NC}"
  echo "💡 Déployez d'abord l'application avec: ./deploy-online-boutique.sh"
  exit 1
fi

# ═══════════════════════════════════════════════════════════
# ÉTAPE 1 : CONFIGURATION
# ═══════════════════════════════════════════════════════════

echo -e "${YELLOW}${BOLD}[ÉTAPE 1/4] Configuration du test${NC}"
echo ""

# Demander le nombre d'utilisateurs (obligatoire)
USER_COUNT=""
while [ -z "$USER_COUNT" ]; do
  read -p "Nombre d'utilisateurs à tester: " USER_COUNT
  if [ -z "$USER_COUNT" ]; then
    echo -e "${RED}⚠️  Le nombre d'utilisateurs est obligatoire !${NC}"
  elif ! [[ "$USER_COUNT" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}⚠️  Veuillez entrer un nombre valide !${NC}"
    USER_COUNT=""
  fi
done

# Calculer le nombre de loadgenerators (1 loadgenerator = 100 users)
REPLICAS=$((USER_COUNT / 100))
if [ $REPLICAS -lt 1 ]; then
  REPLICAS=1
fi

echo ""
echo -e "${GREEN}✅ Configuration: $USER_COUNT utilisateurs ($REPLICAS loadgenerators)${NC}"
echo ""

# Nom du déploiement
DEPLOYMENT_NAME="loadgenerator-test-$$"
YAML_FILE="/tmp/loadgenerator-test-$$.yaml"

# Confirmation
echo -e "${YELLOW}⚠️  ATTENTION${NC}"
echo "Ce test va créer $REPLICAS pods qui vont générer $USER_COUNT requêtes simultanées."
echo "Le Cluster Autoscaler et les HPAs vont automatiquement adapter les ressources."
echo ""
read -p "Voulez-vous continuer ? (o/n): " confirm

if [[ ! $confirm =~ ^[Oo]$ ]]; then
  echo -e "${RED}Test annulé.${NC}"
  exit 0
fi

echo ""

# ═══════════════════════════════════════════════════════════
# ÉTAPE 2 : ÉTAT INITIAL
# ═══════════════════════════════════════════════════════════

echo -e "${YELLOW}${BOLD}[ÉTAPE 2/4] État initial du cluster${NC}"
echo ""

echo -e "${CYAN}État actuel:${NC}"
CURRENT_NODES=$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')
CURRENT_PODS=$(kubectl get pods -n $NAMESPACE --no-headers 2>/dev/null | wc -l | tr -d ' ')
echo "  - Nodes: $CURRENT_NODES"
echo "  - Pods dans $NAMESPACE: $CURRENT_PODS"
echo ""

# Afficher les HPAs
echo -e "${CYAN}HPAs (Horizontal Pod Autoscalers):${NC}"
kubectl get hpa -n $NAMESPACE 2>/dev/null || echo "  Aucun HPA configuré"
echo ""

# Afficher les métriques
echo -e "${CYAN}Métriques actuelles:${NC}"
kubectl top nodes 2>/dev/null || echo "  ⚠️  Metrics server pas encore prêt"
echo ""

read -p "Appuyez sur ENTRÉE pour démarrer le test..."
echo ""

# ═══════════════════════════════════════════════════════════
# ÉTAPE 3 : CRÉATION DU DÉPLOIEMENT
# ═══════════════════════════════════════════════════════════

echo -e "${YELLOW}${BOLD}[ÉTAPE 3/4] Déploiement des loadgenerators${NC}"
echo ""

echo -e "${CYAN}Création du fichier de configuration...${NC}"

cat > "$YAML_FILE" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $DEPLOYMENT_NAME
  namespace: $NAMESPACE
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

echo -e "${GREEN}✅ Fichier créé${NC}"
echo ""

echo -e "${CYAN}Déploiement de $REPLICAS loadgenerators...${NC}"
kubectl apply -f "$YAML_FILE"

echo ""
echo -e "${GREEN}✅ Déploiement lancé${NC}"
echo ""

echo "⏳ Attente du démarrage des pods (30 secondes)..."
sleep 30

# Vérifier l'état
LOADGEN_RUNNING=$(kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT_NAME --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l | tr -d ' ')
LOADGEN_TOTAL=$(kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT_NAME --no-headers 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo -e "${CYAN}État du déploiement:${NC}"
echo "  - Loadgenerators Running: $LOADGEN_RUNNING/$LOADGEN_TOTAL"
echo "  - Utilisateurs simulés: $((LOADGEN_RUNNING * 100))/$USER_COUNT"
echo ""

if [ "$LOADGEN_RUNNING" -lt "$LOADGEN_TOTAL" ]; then
  echo -e "${YELLOW}⏳ Tous les pods ne sont pas encore démarrés.${NC}"
  echo "   Ils vont continuer à démarrer en arrière-plan."
  echo ""
fi

# ═══════════════════════════════════════════════════════════
# ÉTAPE 4 : SURVEILLANCE EN TEMPS RÉEL
# ═══════════════════════════════════════════════════════════

echo -e "${YELLOW}${BOLD}[ÉTAPE 4/4] Surveillance en temps réel${NC}"
echo ""

echo -e "${CYAN}Le mode surveillance va s'afficher dans 3 secondes...${NC}"
echo "Appuyez sur Ctrl+C pour arrêter la surveillance (le test continuera en arrière-plan)"
sleep 3

# Trap Ctrl+C pour sortir proprement
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
    echo -e "${GREEN}${BOLD}  TEST DE CHARGE EN COURS - $USER_COUNT UTILISATEURS${NC}"
    echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${CYAN}📊 INFORMATIONS DU TEST${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Deployment      : $DEPLOYMENT_NAME"
    echo "Namespace       : $NAMESPACE"
    echo "Replicas        : $REPLICAS loadgenerators"
    echo "Utilisateurs    : $USER_COUNT"
    echo ""

    echo -e "${YELLOW}📈 COMMANDES DE SURVEILLANCE${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Surveiller les HPAs (auto-scaling):"
    echo -e "  ${GREEN}watch kubectl get hpa -n $NAMESPACE${NC}"
    echo ""
    echo "Surveiller les nodes:"
    echo -e "  ${GREEN}watch kubectl get nodes${NC}"
    echo ""
    echo "Voir les loadgenerators:"
    echo -e "  ${GREEN}kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT_NAME${NC}"
    echo ""
    echo "Métriques CPU/RAM:"
    echo -e "  ${GREEN}kubectl top pods -n $NAMESPACE${NC}"
    echo -e "  ${GREEN}kubectl top nodes${NC}"
    echo ""

    echo -e "${RED}🛑 COMMANDES POUR ARRÊTER LE TEST${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Option 1 : Arrêt progressif (RECOMMANDÉ)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [ $REPLICAS -ge 50 ]; then
        echo "  # Réduire à 50%"
        echo -e "  ${RED}kubectl scale deployment $DEPLOYMENT_NAME -n $NAMESPACE --replicas=$((REPLICAS / 2))${NC}"
        echo ""
    fi

    if [ $REPLICAS -ge 20 ]; then
        echo "  # Réduire à 1000 utilisateurs"
        echo -e "  ${RED}kubectl scale deployment $DEPLOYMENT_NAME -n $NAMESPACE --replicas=10${NC}"
        echo ""
    fi

    echo "  # Arrêt total"
    echo -e "  ${RED}kubectl scale deployment $DEPLOYMENT_NAME -n $NAMESPACE --replicas=0${NC}"
    echo ""

    echo "Option 2 : Suppression complète"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  ${RED}kubectl delete deployment $DEPLOYMENT_NAME -n $NAMESPACE${NC}"
    echo ""

    echo -e "${CYAN}💡 CONSEIL${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Laissez le test tourner 15-30 minutes pour observer le comportement"
    echo "du cluster sous charge et l'auto-scaling en action."
    echo ""
}

# Fonction de monitoring en temps réel
monitor_test() {
    while true; do
        clear
        echo -e "${CYAN}${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}${BOLD}║           SURVEILLANCE EN TEMPS RÉEL                      ║${NC}"
        echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"
        echo ""

        # Date et heure
        echo -e "${YELLOW}📅 $(date '+%Y-%m-%d %H:%M:%S')${NC}"
        echo ""

        # Loadgenerators
        echo -e "${BLUE}━━━ LOADGENERATORS (Charge simulée) ━━━${NC}"
        LOADGEN_RUNNING=$(kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT_NAME --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l | tr -d ' ')
        LOADGEN_TOTAL=$(kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT_NAME --no-headers 2>/dev/null | wc -l | tr -d ' ')
        USERS_SIMULATED=$((LOADGEN_RUNNING * 100))

        if [ "$LOADGEN_RUNNING" -eq "$LOADGEN_TOTAL" ]; then
            echo -e "${GREEN}✅ Loadgenerators: $LOADGEN_RUNNING/$LOADGEN_TOTAL Running${NC}"
            echo -e "${GREEN}✅ Utilisateurs simulés: $USERS_SIMULATED/$USER_COUNT${NC}"
        else
            echo -e "${YELLOW}⏳ Loadgenerators: $LOADGEN_RUNNING/$LOADGEN_TOTAL Running${NC}"
            echo -e "${YELLOW}⏳ Utilisateurs simulés: $USERS_SIMULATED/$USER_COUNT (démarrage...)${NC}"
        fi
        echo ""

        # HPAs
        echo -e "${BLUE}━━━ AUTO-SCALING (HPAs) ━━━${NC}"
        kubectl get hpa -n $NAMESPACE 2>/dev/null | head -6 || echo "  Pas de HPA configuré"
        echo ""

        # Pods count
        echo -e "${BLUE}━━━ NOMBRE DE PODS PAR SERVICE ━━━${NC}"
        printf "  %-25s : %s\n" "Frontend" "$(kubectl get pods -n $NAMESPACE -l app=frontend --no-headers 2>/dev/null | wc -l | tr -d ' ')"
        printf "  %-25s : %s\n" "Product Catalog" "$(kubectl get pods -n $NAMESPACE -l app=productcatalogservice --no-headers 2>/dev/null | wc -l | tr -d ' ')"
        printf "  %-25s : %s\n" "Checkout" "$(kubectl get pods -n $NAMESPACE -l app=checkoutservice --no-headers 2>/dev/null | wc -l | tr -d ' ')"
        printf "  %-25s : %s\n" "Cart" "$(kubectl get pods -n $NAMESPACE -l app=cartservice --no-headers 2>/dev/null | wc -l | tr -d ' ')"
        printf "  %-25s : %s\n" "Recommendation" "$(kubectl get pods -n $NAMESPACE -l app=recommendationservice --no-headers 2>/dev/null | wc -l | tr -d ' ')"
        echo ""

        # Nodes
        echo -e "${BLUE}━━━ NODES (Cluster Autoscaler) ━━━${NC}"
        NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')
        echo "  Nombre de nodes actifs: $NODE_COUNT"
        echo ""

        # Top Pods CPU
        echo -e "${BLUE}━━━ TOP 5 PODS (CPU) ━━━${NC}"
        kubectl top pods -n $NAMESPACE --no-headers 2>/dev/null | sort -k2 -hr | head -5 | awk '{printf "  %-45s %s\n", $1, $2}' || echo "  Metrics Server non disponible"
        echo ""

        # Instructions
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}Appuyez sur Ctrl+C pour arrêter la surveillance${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

        # Pause avant le prochain refresh
        sleep 5
    done
}

# Lancer la surveillance
monitor_test


