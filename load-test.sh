#!/bin/bash
set -e

echo "🧪 Tests de charge progressifs pour Black Friday Survival"
echo "=========================================================="
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

# Demander le nombre d'utilisateurs pour le test
echo "📊 Configuration du test de charge"
echo "===================================="
echo ""
read -p "Nombre d'utilisateurs pour le TEST 1 (faible charge, défaut: 5000): " USER_COUNT_1
USER_COUNT_1=${USER_COUNT_1:-5000}

read -p "Nombre d'utilisateurs pour le TEST 2 (charge moyenne, défaut: 20000): " USER_COUNT_2
USER_COUNT_2=${USER_COUNT_2:-20000}

read -p "Nombre d'utilisateurs pour le TEST 3 (Black Friday, défaut: 50000): " USER_COUNT_3
USER_COUNT_3=${USER_COUNT_3:-50000}

echo ""
echo "✅ Configuration:"
echo "   Test 1: $USER_COUNT_1 utilisateurs"
echo "   Test 2: $USER_COUNT_2 utilisateurs"
echo "   Test 3: $USER_COUNT_3 utilisateurs (Black Friday)"
echo ""

# Fonction pour vérifier les pods
check_pods() {
  echo "📊 État des pods:"
  kubectl get pods -n $NAMESPACE
  echo ""
}

# Fonction pour vérifier les métriques
check_metrics() {
  echo "📈 Métriques des pods:"
  kubectl top pods -n $NAMESPACE 2>/dev/null || echo "Metrics server pas encore prêt"
  echo ""
  echo "📈 Métriques des nodes:"
  kubectl top nodes 2>/dev/null || echo "Metrics server pas encore prêt"
  echo ""
}

# Fonction pour vérifier HPA
check_hpa() {
  echo "🔄 État des HPA:"
  kubectl get hpa -n $NAMESPACE
  echo ""
}

# Installation de Locust si nécessaire
if ! command -v locust &> /dev/null; then
  echo "📦 Installation de Locust pour les tests de charge..."
  pip3 install locust
fi

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

echo "🧪 TEST 1/3 - Charge FAIBLE ($USER_COUNT_1 utilisateurs)"
echo "================================================"
check_pods
check_metrics
check_hpa

echo "🚀 Démarrage du test avec ${USER_COUNT_1} utilisateurs virtuels..."
locust -f /tmp/locustfile.py \
  --host=http://$FRONTEND_URL \
  --users $USER_COUNT_1 \
  --spawn-rate $(($USER_COUNT_1 / 50)) \
  --run-time 5m \
  --headless \
  --only-summary

echo ""
echo "⏸️  Pause de 2 minutes pour stabilisation..."
sleep 120

check_pods
check_metrics
check_hpa

echo ""
echo "🧪 TEST 2/3 - Charge MOYENNE ($USER_COUNT_2 utilisateurs)"
echo "==================================================="

echo "🚀 Démarrage du test avec ${USER_COUNT_2} utilisateurs virtuels..."
locust -f /tmp/locustfile.py \
  --host=http://$FRONTEND_URL \
  --users $USER_COUNT_2 \
  --spawn-rate $(($USER_COUNT_2 / 100)) \
  --run-time 10m \
  --headless \
  --only-summary

echo ""
echo "⏸️  Pause de 3 minutes pour stabilisation..."
sleep 180

check_pods
check_metrics
check_hpa

echo ""
echo "🧪 TEST 3/3 - Charge ÉLEVÉE Black Friday ($USER_COUNT_3 utilisateurs)"
echo "==============================================================="

echo "🚀 Démarrage du test avec ${USER_COUNT_3} utilisateurs virtuels..."
locust -f /tmp/locustfile.py \
  --host=http://$FRONTEND_URL \
  --users $USER_COUNT_3 \
  --spawn-rate $(($USER_COUNT_3 / 100)) \
  --run-time 15m \
  --headless \
  --only-summary

echo ""
echo "⏸️  Pause de 5 minutes pour observation..."
sleep 300

check_pods
check_metrics
check_hpa

echo ""
echo "✅ Tests de charge terminés!"
echo ""
echo "📊 Résumé final:"
echo "==============="
kubectl get hpa -n $NAMESPACE
echo ""
kubectl get pods -n $NAMESPACE -o wide
echo ""
kubectl top nodes
echo ""
echo "🎯 Vérifier les dashboards:"
echo "  - Grafana: kubectl get svc -n monitoring kube-prometheus-stack-grafana"
echo "  - Jaeger: kubectl get svc -n observability jaeger-query"
echo "  - CloudWatch: Console AWS -> CloudWatch -> Dashboards -> eks-bfs-gp12-monitoring"

