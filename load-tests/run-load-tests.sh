set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${GREEN}${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║              LOAD TESTS - BLACK FRIDAY SURVIVAL          ║${NC}"
echo -e "${GREEN}${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

if ! command -v artillery &> /dev/null; then
    echo -e "${RED}Artillery is not installed. Installing...${NC}"
    npm install
fi

TARGET_URL="http://localhost:9000"
if ! curl -s --max-time 5 "$TARGET_URL/health" > /dev/null; then
    echo -e "${YELLOW}Target application not responding at $TARGET_URL${NC}"
    echo "Make sure the application is running with: npm run dev"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo -e "${BLUE}Select test type:${NC}"
echo "1) Quick test (2 minutes)"
echo "2) Standard test (5 minutes)"
echo "3) Stress test (10 minutes)"
echo "4) Custom configuration"
echo ""

read -p "Choice [1-4]: " choice

case $choice in
    1)
        echo -e "${GREEN}Running quick load test...${NC}"
        artillery run --output quick-report.json load-test.yml
        artillery report quick-report.json
        ;;
    2)
        echo -e "${GREEN}Running standard load test...${NC}"
        artillery run --output standard-report.json load-test.yml
        artillery report standard-report.json
        ;;
    3)
        echo -e "${GREEN}Running stress load test...${NC}"
        sed 's/arrivalRate: 50/arrivalRate: 100/g' load-test.yml > stress-test.yml
        artillery run --output stress-report.json stress-test.yml
        artillery report stress-report.json
        rm stress-test.yml
        ;;
    4)
        echo -e "${YELLOW}Custom configuration:${NC}"
        read -p "Test duration (seconds): " duration
        read -p "Arrival rate (requests/second): " rate
        read -p "Output file name: " output_file

        cat > custom-test.yml << EOF
config:
  target: '$TARGET_URL'
  phases:
    - duration: $duration
      arrivalRate: $rate
      name: Custom load test
scenarios:
  - name: 'Browse products'
    weight: 40
    flow:
      - get:
          url: '/store/products'
  - name: 'View product details'
    weight: 30
    flow:
      - get:
          url: '/store/products'
      - get:
          url: '/store/products/1'
  - name: 'Add to cart'
    weight: 20
    flow:
      - post:
          url: '/store/carts'
          json:
            region_id: 'reg_01HXXXXXXXXXXXXXXXXXXXXX'
      - post:
          url: '/store/carts/cart_01HXXXXXXXXXXXXXXXXXXXXX/line-items'
          json:
            variant_id: 'variant_01HXXXXXXXXXXXXXXXXXXXXX'
            quantity: 1
  - name: 'Checkout'
    weight: 10
    flow:
      - post:
          url: '/store/carts/cart_01HXXXXXXXXXXXXXXXXXXXXX/complete'
          json:
            billing_address:
              first_name: 'Test'
              last_name: 'User'
              address_1: '123 Test St'
              city: 'Test City'
              country_code: 'US'
              postal_code: '12345'
            email: 'test@example.com'
EOF

        artillery run --output "${output_file}.json" custom-test.yml
        artillery report "${output_file}.json"
        rm custom-test.yml
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}Load test completed!${NC}"
echo "Reports saved in load-tests/ directory"