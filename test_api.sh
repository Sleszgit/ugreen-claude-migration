#!/bin/bash

# Test UGREEN Proxmox API access
TOKEN=$(cat ~/.proxmox-api-token)
echo "Testing UGREEN API with token: ${TOKEN:0:10}..."

# Test simple API endpoint
echo "1. Testing /api2/json/version endpoint:"
curl -s -k -H "Authorization: PVEAPIToken=claude-reader@pam!claude-token=$TOKEN" \
  "https://192.168.40.60:8006/api2/json/version" | python3 -m json.tool 2>&1 | head -20

echo ""
echo "2. Testing /api2/json/nodes endpoint:"
curl -s -k -H "Authorization: PVEAPIToken=claude-reader@pam!claude-token=$TOKEN" \
  "https://192.168.40.60:8006/api2/json/nodes" | python3 -m json.tool 2>&1 | head -20
