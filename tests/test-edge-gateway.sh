#!/usr/bin/env bash
set -euo pipefail

GATEWAY_URL="https://integration-suite-eu10.test02.apimanagement.eu10.hana.ondemand.com:443/open-finance/edge/v1/credit-scoring"

echo "=== Testing SAP APIM Edge Gateway ==="
echo "Target: $GATEWAY_URL"
echo ""

curl -i -X GET "$GATEWAY_URL" \
  -H "Accept: application/json"

echo ""
echo "=== Test Completed ==="
