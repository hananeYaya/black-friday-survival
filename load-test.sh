#!/bin/bash
set -e

echo "🧪 Test de charge pour Black Friday Survival"
echo "============================================="
echo ""

# Variables
NAMESPACE="online-boutique"
FRONTEND_URL=$(kubectl get svc frontend-external -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

if [ -z "$FRONTEND_URL" ]; then
  echo "❌ Erreur: Le service frontend-external n'a pas de Load Balancer"
  echo "💡 Conseil: Exécutez d'abord:"
  echo "   kubectl patch svc frontend-external -n $NAMESPACE -p '{\"spec\":{\"type\":\"LoadBalancer\"}}'"
  exit 1
fi

echo "🌐 URL Frontend: http://$FRONTEND_URL"
echo ""

# Demander le nombre d'utilisateurs (obligatoire)
echo "📊 Configuration du test de charge"
echo "===================================="
echo ""

USER_COUNT=""
while [ -z "$USER_COUNT" ]; do
  read -p "Nombre d'utilisateurs à tester: " USER_COUNT
  if [ -z "$USER_COUNT" ]; then
    echo "⚠️  Le nombre d'utilisateurs est obligatoire !"
  elif ! [[ "$USER_COUNT" =~ ^[0-9]+$ ]]; then
    echo "⚠️  Veuillez entrer un nombre valide !"
    USER_COUNT=""
  fi
done

# Calculer le spawn-rate (environ 1% du nombre d'utilisateurs)
SPAWN_RATE=$((USER_COUNT / 100))
if [ $SPAWN_RATE -lt 10 ]; then
  SPAWN_RATE=10
fi

# Demander la durée du test
read -p "Durée du test en minutes (défaut: 10): " DURATION
DURATION=${DURATION:-10}

echo ""
echo "✅ Configuration du test:"
echo "   • Utilisateurs: $USER_COUNT"
echo "   • Spawn rate: $SPAWN_RATE utilisateurs/seconde"
echo "   • Durée: $DURATION minutes"
echo "   • URL: http://$FRONTEND_URL"
echo ""

# Vérifier que Docker est disponible
if ! command -v docker &> /dev/null; then
  echo "❌ Erreur: Docker n'est pas installé ou n'est pas démarré"
  echo "💡 Installez Docker Desktop: https://www.docker.com/products/docker-desktop"
  exit 1
fi

echo "⏳ Préparation du test..."
echo "📦 Utilisation de Locust via Docker..."
echo ""

# Afficher l'état initial
echo "📊 État AVANT le test:"
echo "======================"
echo ""

echo "🖥️  Nodes:"
kubectl get nodes
echo ""

echo "📦 Pods dans $NAMESPACE:"
kubectl get pods -n $NAMESPACE
echo ""

echo "🔄 HPA (Horizontal Pod Autoscalers):"
kubectl get hpa -n $NAMESPACE 2>/dev/null || echo "Aucun HPA configuré"
echo ""

echo "📊 Métriques actuelles:"
kubectl top nodes 2>/dev/null || echo "⚠️  Metrics server pas encore prêt"
echo ""

read -p "Appuyez sur ENTRÉE pour démarrer le test de charge..."
echo ""

# Créer le fichier Locust
cat > /tmp/locustfile.py << 'EOF'
from locust import HttpUser, task, between
import random

class OnlineBoutiqueUser(HttpUser):
    wait_time = between(1, 3)

    @task(10)
    def view_homepage(self):
        self.client.get("/")

    @task(5)
    def view_product(self):
        product_ids = [
            "0PUK6V6EV0", "1YMWWN1N4O", "2ZYFJ3GM2N", "66VCHSJNUP",
            "6E92ZMYYFZ", "9SIQT8TOJO", "L9ECAV7KIM", "LS4PSXUNUM", "OLJCESPC7Z"
        ]
        product_id = random.choice(product_ids)
        self.client.get(f"/product/{product_id}")

    @task(3)
    def add_to_cart(self):
        product_ids = [
            "0PUK6V6EV0", "1YMWWN1N4O", "2ZYFJ3GM2N", "66VCHSJNUP",
            "6E92ZMYYFZ", "9SIQT8TOJO", "L9ECAV7KIM", "LS4PSXUNUM", "OLJCESPC7Z"
        ]
        product_id = random.choice(product_ids)
        quantity = random.randint(1, 5)
        self.client.post("/cart", {
            "product_id": product_id,
            "quantity": quantity
        })

    @task(1)
    def view_cart(self):
        self.client.get("/cart")

    @task(1)
    def checkout(self):
        self.client.post("/cart/checkout", {
            "email": "test@example.com",
            "street_address": "1600 Amphitheatre Parkway",
            "zip_code": "94043",
            "city": "Mountain View",
            "state": "CA",
            "country": "United States",
            "credit_card_number": "4432-8015-6152-0454",
            "credit_card_expiration_month": "12",
            "credit_card_expiration_year": "2030",
            "credit_card_cvv": "123"
        })
EOF

echo "🚀 DÉMARRAGE DU TEST DE CHARGE"
echo "==============================="
echo ""
echo "⏳ Le test va durer $DURATION minutes avec $USER_COUNT utilisateurs virtuels..."
echo ""

# Lancer Locust via Docker en arrière-plan et capturer le PID
docker run -d \
  --name locust-load-test-$$ \
  -v /tmp/locustfile.py:/mnt/locust/locustfile.py \
  locustio/locust \
  -f /mnt/locust/locustfile.py \
  --host=http://$FRONTEND_URL \
  --users $USER_COUNT \
  --spawn-rate $SPAWN_RATE \
  --run-time ${DURATION}m \
  --headless \
  --only-summary > /tmp/locust_container_id.txt

CONTAINER_ID=$(cat /tmp/locust_container_id.txt)

echo "📊 Test en cours (Container ID: ${CONTAINER_ID:0:12})..."
echo "⚠️  Pour arrêter le test à tout moment, exécutez:"
echo "   docker stop ${CONTAINER_ID:0:12}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Fonction pour surveiller l'état pendant le test
monitor_during_test() {
  while docker ps --filter id=$CONTAINER_ID --format '{{.ID}}' | grep -q .; do
    clear
    echo "🔴 TEST DE CHARGE EN COURS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "⚙️  Configuration: $USER_COUNT users | Durée: ${DURATION}m | Container: ${CONTAINER_ID:0:12}"
    echo ""
    echo "⚠️  Pour arrêter: docker stop ${CONTAINER_ID:0:12}"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    echo "🖥️  NODES:"
    kubectl get nodes --no-headers | awk '{printf "   %-30s %s\n", $1, $2}'
    echo ""

    echo "📦 PODS ($NAMESPACE):"
    kubectl get pods -n $NAMESPACE --no-headers | wc -l | xargs echo "   Total:"
    kubectl get pods -n $NAMESPACE --no-headers | grep "Running" | wc -l | xargs echo "   Running:"
    kubectl get pods -n $NAMESPACE --no-headers | grep -v "Running" | wc -l | xargs echo "   Problèmes:"
    echo ""

    echo "🔄 HPA (Horizontal Pod Autoscalers):"
    kubectl get hpa -n $NAMESPACE --no-headers 2>/dev/null | awk '{printf "   %-30s %s/%s\n", $1, $2, $3}' || echo "   Aucun HPA"
    echo ""

    echo "📊 MÉTRIQUES NODES:"
    kubectl top nodes --no-headers 2>/dev/null | awk '{printf "   %-30s CPU: %-10s RAM: %s\n", $1, $2, $3}' || echo "   Metrics server pas prêt"
    echo ""

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   Rafraîchissement dans 10 secondes..."

    sleep 10
  done
}

# Lancer le monitoring en arrière-plan
monitor_during_test &
MONITOR_PID=$!

# Attendre la fin du conteneur Docker
docker wait $CONTAINER_ID > /dev/null
LOCUST_EXIT_CODE=$?

# Récupérer les logs finaux de Locust
echo ""
echo "📊 Résultats du test Locust:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker logs $CONTAINER_ID 2>&1 | tail -20
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Nettoyer le conteneur
docker rm $CONTAINER_ID > /dev/null 2>&1

# Arrêter le monitoring
kill $MONITOR_PID 2>/dev/null

clear
echo ""
echo "✅ TEST TERMINÉ"
echo "==============="
echo ""

# Afficher les résultats finaux
echo "📊 État APRÈS le test:"
echo "======================"
echo ""

echo "🖥️  Nodes:"
kubectl get nodes
echo ""

echo "📦 Pods dans $NAMESPACE:"
kubectl get pods -n $NAMESPACE
echo ""

echo "🔄 HPA (Horizontal Pod Autoscalers):"
kubectl get hpa -n $NAMESPACE 2>/dev/null || echo "Aucun HPA configuré"
echo ""

echo "📊 Métriques finales:"
kubectl top nodes 2>/dev/null || echo "⚠️  Metrics server pas disponible"
echo ""

echo "📈 Métriques des pods:"
kubectl top pods -n $NAMESPACE 2>/dev/null || echo "⚠️  Metrics server pas disponible"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎯 RÉSUMÉ DU TEST:"
echo "   • Utilisateurs: $USER_COUNT"
echo "   • Durée: $DURATION minutes"
echo "   • URL testée: http://$FRONTEND_URL"
echo "   • Code de sortie: $LOCUST_EXIT_CODE"
echo ""
echo "💡 Commandes utiles:"
echo "   • Voir les logs d'un pod:"
echo "     kubectl logs -n $NAMESPACE <pod-name>"
echo ""
echo "   • Voir les événements:"
echo "     kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp'"
echo ""
echo "   • Voir les HPA en temps réel:"
echo "     watch kubectl get hpa -n $NAMESPACE"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Script terminé."


