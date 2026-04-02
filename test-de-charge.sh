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

monitor_test() {
    local deployment_name=$1
    local target_users=$2
    local duration=$3

    local log_file="load-test-report-${deployment_name}.log"
    echo "Timestamp,Loadgen_Running,Loadgen_Total,Users_Simulated,Nodes,Pods_Frontend,Pods_Product,Pods_Checkout,Pods_Cart,Pods_Rec,Top_CPU" > "$log_file"

    local start_time=$(date +%s)

    clear
    echo -e "${CYAN}${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║           SURVEILLANCE EN TEMPS RÉEL                      ║${NC}"
    echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    while true; do
        local current_time=$(date +%s)
        if [ $((current_time - start_time)) -ge $duration ]; then
            break
        fi

        tput cup 4 0

        echo -e "${YELLOW}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
        echo ""

        echo -e "${BLUE}━━━ LOADGENERATORS (Charge simulée) ━━━${NC}"
        LOADGEN_RUNNING=$(kubectl get pods -l app=$deployment_name --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l | tr -d ' ')
        LOADGEN_TOTAL=$(kubectl get pods -l app=$deployment_name --no-headers 2>/dev/null | wc -l | tr -d ' ')
        USERS=$((LOADGEN_RUNNING * 100))

        if [ "$LOADGEN_RUNNING" -eq "$LOADGEN_TOTAL" ]; then
            echo -e "${GREEN} Loadgenerators: $LOADGEN_RUNNING/$LOADGEN_TOTAL Running${NC}"
            echo -e "${GREEN} Utilisateurs simulés: $USERS/$target_users${NC}"
        else
            echo -e "${YELLOW} Loadgenerators: $LOADGEN_RUNNING/$LOADGEN_TOTAL Running${NC}"
            echo -e "${YELLOW} Utilisateurs simulés: $USERS/$target_users (démarrage...)${NC}"
        fi
        echo ""

        echo -e "${BLUE}━━━ AUTO-SCALING (HPAs) ━━━${NC}"
        kubectl get hpa 2>/dev/null | head -6 || echo "Pas de HPA configuré"
        echo ""

        echo -e "${BLUE}━━━ NOMBRE DE PODS PAR SERVICE ━━━${NC}"
        printf "%-25s : %s\n" "Frontend" "$(kubectl get pods -l app=frontend --no-headers 2>/dev/null | wc -l | tr -d ' ')"
        printf "%-25s : %s\n" "Product Catalog" "$(kubectl get pods -l app=productcatalogservice --no-headers 2>/dev/null | wc -l | tr -d ' ')"
        printf "%-25s : %s\n" "Checkout" "$(kubectl get pods -l app=checkoutservice --no-headers 2>/dev/null | wc -l | tr -d ' ')"
        printf "%-25s : %s\n" "Cart" "$(kubectl get pods -l app=cartservice --no-headers 2>/dev/null | wc -l | tr -d ' ')"
        printf "%-25s : %s\n" "Recommendation" "$(kubectl get pods -l app=recommendationservice --no-headers 2>/dev/null | wc -l | tr -d ' ')"
        echo ""

        echo -e "${BLUE}━━━ NODES (Cluster Autoscaler) ━━━${NC}"
        NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')
        echo "Nombre de nodes actifs: $NODE_COUNT"
        echo ""

        echo -e "${BLUE}━━━ TOP 5 PODS (CPU) ━━━${NC}"
        kubectl top pods --no-headers 2>/dev/null | sort -k2 -hr | head -5 || echo "Metrics Server non disponible"
        echo ""

        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        local pods_frontend=$(kubectl get pods -l app=frontend --no-headers 2>/dev/null | wc -l | tr -d ' ')
        local pods_product=$(kubectl get pods -l app=productcatalogservice --no-headers 2>/dev/null | wc -l | tr -d ' ')
        local pods_checkout=$(kubectl get pods -l app=checkoutservice --no-headers 2>/dev/null | wc -l | tr -d ' ')
        local pods_cart=$(kubectl get pods -l app=cartservice --no-headers 2>/dev/null | wc -l | tr -d ' ')
        local pods_rec=$(kubectl get pods -l app=recommendationservice --no-headers 2>/dev/null | wc -l | tr -d ' ')
        local top_cpu=$(kubectl top pods --no-headers 2>/dev/null | sort -k2 -hr | head -1 | awk '{print $2}' | tr -d 'm')
        echo "$timestamp,$LOADGEN_RUNNING,$LOADGEN_TOTAL,$USERS,$NODE_COUNT,$pods_frontend,$pods_product,$pods_checkout,$pods_cart,$pods_rec,$top_cpu" >> "$log_file"

        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}Test en cours... Fin dans $((duration - (current_time - start_time))) secondes${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

        sleep 5
    done

    generate_report "$log_file" "$deployment_name" "$target_users" "$duration"
}

generate_report() {
    local log_file=$1
    local deployment_name=$2
    local target_users=$3
    local duration=$4

    echo ""
    echo -e "${YELLOW}${BOLD}GÉNÉRATION DU RAPPORT${NC}"
    echo ""

    local total_entries=$(($(wc -l < "$log_file") - 1))  
    if [ $total_entries -gt 0 ]; then
        local avg_nodes=$(awk -F',' 'NR>1 {sum+=$5} END {if(NR>1) print sum/(NR-1); else print 0}' "$log_file")
        local max_nodes=$(awk -F',' 'NR>1 {if($5 > max) max=$5} END {print max}' "$log_file")
        local avg_cpu=$(awk -F',' 'NR>1 && $11 != "" {sum+=$11; count++} END {if(count>0) print sum/count; else print 0}' "$log_file")
        local max_pods_frontend=$(awk -F',' 'NR>1 {if($6 > max) max=$6} END {print max}' "$log_file")
        local max_pods_product=$(awk -F',' 'NR>1 {if($7 > max) max=$7} END {print max}' "$log_file")
        local max_pods_checkout=$(awk -F',' 'NR>1 {if($8 > max) max=$8} END {print max}' "$log_file")
        local max_pods_cart=$(awk -F',' 'NR>1 {if($9 > max) max=$9} END {print max}' "$log_file")
        local max_pods_rec=$(awk -F',' 'NR>1 {if($10 > max) max=$10} END {print max}' "$log_file")

        echo -e "${GREEN}Rapport de test de charge${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Test: $deployment_name"
        echo "Utilisateurs simulés: $target_users"
        echo "Durée: $((duration / 60)) minutes"
        echo "Points de données: $total_entries"
        echo ""
        echo "Statistiques:"
        echo "  - Nombre moyen de nodes: ${avg_nodes%.*}"
        echo "  - Nombre max de nodes: $max_nodes"
        echo "  - CPU moyen (top pod): ${avg_cpu%.*}m"
        echo ""
        echo "Pods max par service:"
        echo "  - Frontend: $max_pods_frontend"
        echo "  - Product Catalog: $max_pods_product"
        echo "  - Checkout: $max_pods_checkout"
        echo "  - Cart: $max_pods_cart"
        echo "  - Recommendation: $max_pods_rec"
        echo ""
        echo "Fichier de log complet: $log_file"
    else
        echo -e "${RED}Aucune donnée collectée pour le rapport${NC}"
    fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${YELLOW}${BOLD}[ÉTAPE 1/5] Configuration du test${NC}"
echo ""

while true; do
    echo -e "${CYAN}Combien d'utilisateurs voulez-vous simuler ?${NC}"
    echo "  1) 1000 utilisateurs   (10 loadgenerators)"
    echo "  2) 2000 utilisateurs   (20 loadgenerators)"
    echo "  3) 5000 utilisateurs   (50 loadgenerators) ${RED}[ATTENTION: Charge élevée]${NC}"
    echo "  4) 10000 utilisateurs  (100 loadgenerators) ${RED}[DANGER: Très haute charge]${NC}"
    echo "  5) Nombre personnalisé"
    echo "  6) 15000 utilisateurs  (150 loadgenerators) ${RED}[BLACK FRIDAY MODE]${NC}"
    echo "  7) 20000 utilisateurs  (200 loadgenerators) ${RED}[EXTREME LOAD]${NC}"
    echo ""
    read -p "Votre choix [1-7]: " choice

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
        6)
            USERS=15000
            REPLICAS=150
            break
            ;;
        7)
            USERS=20000
            REPLICAS=200
            break
            ;;
        *)
            echo -e "${RED}Choix invalide. Veuillez choisir entre 1 et 7.${NC}"
            echo ""
            ;;
    esac
done

echo ""
echo -e "${GREEN}Configuration: $USERS utilisateurs ($REPLICAS loadgenerators)${NC}"
echo ""

echo -e "${CYAN}Quelle est la durée du test ?${NC}"
echo "  1) 5 minutes"
echo "  2) 10 minutes"
echo "  3) 15 minutes"
echo "  4) 30 minutes"
echo "  5) Durée personnalisée"
echo ""
read -p "Votre choix [1-5]: " duration_choice

case $duration_choice in
    1)
        DURATION=300
        ;;
    2)
        DURATION=600
        ;;
    3)
        DURATION=900
        ;;
    4)
        DURATION=1800
        ;;
    5)
        read -p "Durée en minutes: " minutes
        DURATION=$((minutes * 60))
        ;;
    *)
        DURATION=600  
        ;;
esac

echo ""
echo -e "${GREEN} Durée: $((DURATION / 60)) minutes${NC}"
echo ""

DEPLOYMENT_NAME="loadgenerator-test-${USERS}"
YAML_FILE="loadgenerator-${USERS}.yaml"

echo -e "${YELLOW}  ATTENTION${NC}"
echo "Ce test va créer $REPLICAS pods qui vont générer $USERS requêtes simultanées."
echo "Le Cluster Autoscaler va probablement ajouter des nodes supplémentaires."
echo ""
read -p "Voulez-vous continuer ? (o/n): " confirm

if [[ ! $confirm =~ ^[Oo]$ ]]; then
    echo -e "${RED}Test annulé.${NC}"
    exit 0
fi

echo ""

echo -e "${YELLOW}${BOLD}[ÉTAPE 2/5] Préparation du fichier de configuration${NC}"
echo ""

if [ -f "$YAML_FILE" ]; then
    echo -e "${GREEN}Le fichier $YAML_FILE existe déjà${NC}"
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

    echo -e "${GREEN}Fichier $YAML_FILE créé${NC}"
fi

echo ""

echo -e "${YELLOW}${BOLD}[ÉTAPE 3/5] Vérification de l'infrastructure${NC}"
echo ""

echo "État actuel:"
CURRENT_NODES=$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')
CURRENT_PODS=$(kubectl get pods --no-headers 2>/dev/null | wc -l | tr -d ' ')
echo "  - Nodes: $CURRENT_NODES"
echo "  - Pods: $CURRENT_PODS"
echo ""

HPA_COUNT=$(kubectl get hpa --no-headers 2>/dev/null | wc -l | tr -d ' ')
if [ "$HPA_COUNT" -lt 5 ]; then
    echo -e "${YELLOW}  Nombre de HPAs configurés: $HPA_COUNT/5${NC}"
    read -p "Voulez-vous configurer les HPAs maintenant ? (o/n): " setup_hpa

    if [[ $setup_hpa =~ ^[Oo]$ ]]; then
        echo "Configuration des HPAs..."
        kubectl autoscale deployment frontend --cpu-percent=70 --min=2 --max=20 2>/dev/null || echo "  HPA frontend déjà configuré"
        kubectl autoscale deployment productcatalogservice --cpu-percent=70 --min=2 --max=10 2>/dev/null || echo "  HPA productcatalog déjà configuré"
        kubectl autoscale deployment checkoutservice --cpu-percent=70 --min=2 --max=15 2>/dev/null || echo "  HPA checkout déjà configuré"
        kubectl autoscale deployment cartservice --cpu-percent=70 --min=2 --max=10 2>/dev/null || echo "  HPA cart déjà configuré"
        kubectl autoscale deployment recommendationservice --cpu-percent=70 --min=2 --max=10 2>/dev/null || echo "  HPA recommendation déjà configuré"
        echo -e "${GREEN} HPAs configurés${NC}"
    fi
else
    echo -e "${GREEN} HPAs configurés: $HPA_COUNT${NC}"
fi

echo ""

echo -e "${YELLOW}${BOLD}[ÉTAPE 4/5] Déploiement des loadgenerators${NC}"
echo ""

echo "Déploiement de $REPLICAS loadgenerators..."
kubectl apply -f "$YAML_FILE"

echo ""
echo -e "${GREEN} Déploiement lancé${NC}"
echo ""

echo "Attente du démarrage des pods (60 secondes)..."
progress_bar 60

echo ""

LOADGEN_RUNNING=$(kubectl get pods -l app=$DEPLOYMENT_NAME --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l | tr -d ' ')
LOADGEN_TOTAL=$(kubectl get pods -l app=$DEPLOYMENT_NAME --no-headers 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo -e "${CYAN}État du déploiement:${NC}"
echo "  - Loadgenerators Running: $LOADGEN_RUNNING/$LOADGEN_TOTAL"
echo "  - Utilisateurs simulés: $((LOADGEN_RUNNING * 100))/$USERS"
echo ""

if [ "$LOADGEN_RUNNING" -lt "$LOADGEN_TOTAL" ]; then
    echo -e "${YELLOW} Tous les pods ne sont pas encore démarrés.${NC}"
    echo "   Ils vont continuer à démarrer en arrière-plan."
    echo ""
fi


echo -e "${YELLOW}${BOLD}[ÉTAPE 5/5] Surveillance en temps réel${NC}"
echo ""

echo -e "${CYAN}Le mode surveillance va s'afficher dans 3 secondes...${NC}"
echo ""
echo "Appuyez sur Ctrl+C pour arrêter la surveillance (les tests continueront en arrière-plan)"
sleep 3

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

show_stop_commands() {
    echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}  TEST DE CHARGE EN COURS - $USERS UTILISATEURS${NC}"
    echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${CYAN} INFORMATIONS DU TEST${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Deployment      : $DEPLOYMENT_NAME"
    echo "Replicas        : $REPLICAS loadgenerators"
    echo "Utilisateurs    : $USERS"
    echo "Fichier YAML    : $YAML_FILE"
    echo ""

    echo -e "${YELLOW} COMMANDES DE SURVEILLANCE${NC}"
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

    echo -e "${RED} COMMANDES POUR ARRÊTER LE TEST${NC}"
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

    echo -e "${CYAN} CONSEIL${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Laissez le test tourner 15-30 minutes pour observer le comportement"
    echo "du cluster sous charge et l'auto-scaling en action."
    echo ""
}

monitor_test "$DEPLOYMENT_NAME" "$USERS" "$DURATION"

