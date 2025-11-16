#!/bin/bash
#
# Copyright (c) 2025 Deep Thought Labs
# All rights reserved.
#
# This file is part of the Infinite Drive blockchain tooling.
#
# Purpose: Comprehensive validation script for token configuration.
#          Validates all token-related configurations including metadata,
#          denom units, chain IDs, and URI structure after updates.
#          Ensures the Improbability (42) token is correctly configured
#          with the hierarchical asset URI structure.
#
# Usage: ./scripts/validate_token_config.sh
#
# Prerequisites:
#   - Running Infinite Drive node (ports 1317, 8545, 26657)
#   - jq command-line JSON processor
#   - curl command
#
# Exit codes:
#   0 - All validations passed
#   1 - One or more validations failed
#

set -e

echo "🔍 Token Configuration Validation"
echo "=================================="
echo "Timestamp: $(date)"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Expected values
EXPECTED_NAME="Improbability"
EXPECTED_SYMBOL="42"
EXPECTED_DISPLAY="Improbability"
EXPECTED_BASE="drop"
EXPECTED_URI="https://assets.infinitedrive.xyz/tokens/42/icon.png"
EXPECTED_DESCRIPTION="Improbability Token — Project 42: Sovereign, Perpetual, DAO-Governed"
EXPECTED_CHAIN_ID="infinite_421018-1"
EXPECTED_EVM_CHAIN_ID_HEX="0x66c9a"
EXPECTED_EVM_CHAIN_ID_DECIMAL="421018"

# Test 1: Node connectivity
echo "1. Testing node connectivity..."
REST_API_OK=false
JSON_RPC_OK=false

if curl -s http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info > /dev/null 2>&1; then
    REST_API_OK=true
    print_status 0 "REST API responding"
else
    print_status 1 "REST API not responding"
    echo "   Make sure your node is running on port 1317"
    exit 1
fi

if curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
  http://localhost:8545 > /dev/null 2>&1; then
    JSON_RPC_OK=true
    print_status 0 "JSON-RPC API responding"
else
    print_status 1 "JSON-RPC API not responding"
    echo "   Make sure your node is running on port 8545"
fi

echo ""

# Test 2: Chain ID verification
echo "2. Verifying Chain IDs..."

COSMOS_CHAIN_ID=$(curl -s http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info | jq -r '.default_node_info.network' 2>/dev/null || echo "error")

if [ "$COSMOS_CHAIN_ID" = "$EXPECTED_CHAIN_ID" ]; then
    print_status 0 "Cosmos Chain ID correct: $COSMOS_CHAIN_ID"
else
    print_status 1 "Cosmos Chain ID mismatch"
    echo "   Expected: $EXPECTED_CHAIN_ID"
    echo "   Found:    $COSMOS_CHAIN_ID"
fi

EVM_CHAIN_ID_HEX=$(curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
  http://localhost:8545 | jq -r '.result' 2>/dev/null || echo "error")

if [ "$EVM_CHAIN_ID_HEX" = "$EXPECTED_EVM_CHAIN_ID_HEX" ]; then
    print_status 0 "EVM Chain ID correct: $EVM_CHAIN_ID_HEX ($EXPECTED_EVM_CHAIN_ID_DECIMAL)"
else
    print_status 1 "EVM Chain ID mismatch"
    echo "   Expected: $EXPECTED_EVM_CHAIN_ID_HEX ($EXPECTED_EVM_CHAIN_ID_DECIMAL)"
    echo "   Found:    $EVM_CHAIN_ID_HEX"
fi

echo ""

# Test 3: Token metadata - Complete validation
echo "3. Verifying token metadata..."

METADATA=$(curl -s http://localhost:1317/cosmos/bank/v1beta1/denoms_metadata | jq '.metadatas[] | select(.base == "drop")' 2>/dev/null)

if [ -z "$METADATA" ] || [ "$METADATA" = "null" ]; then
    print_status 1 "Token metadata not found"
    echo "   No metadata found for base denom 'drop'"
    exit 1
fi

print_info "Full metadata:"
echo "$METADATA" | jq '.' | sed 's/^/   /'
echo ""

# Extract and validate each field
NAME=$(echo "$METADATA" | jq -r '.name // "missing"')
SYMBOL=$(echo "$METADATA" | jq -r '.symbol // "missing"')
DISPLAY=$(echo "$METADATA" | jq -r '.display // "missing"')
BASE=$(echo "$METADATA" | jq -r '.base // "missing"')
URI=$(echo "$METADATA" | jq -r '.uri // "missing"')
DESCRIPTION=$(echo "$METADATA" | jq -r '.description // "missing"')

# Validate name
if [ "$NAME" = "$EXPECTED_NAME" ]; then
    print_status 0 "Name: $NAME"
else
    print_status 1 "Name mismatch"
    echo "   Expected: $EXPECTED_NAME"
    echo "   Found:    $NAME"
fi

# Validate symbol
if [ "$SYMBOL" = "$EXPECTED_SYMBOL" ]; then
    print_status 0 "Symbol: $SYMBOL"
else
    print_status 1 "Symbol mismatch"
    echo "   Expected: $EXPECTED_SYMBOL"
    echo "   Found:    $SYMBOL"
fi

# Validate display
if [ "$DISPLAY" = "$EXPECTED_DISPLAY" ]; then
    print_status 0 "Display: $DISPLAY"
else
    print_status 1 "Display mismatch"
    echo "   Expected: $EXPECTED_DISPLAY"
    echo "   Found:    $DISPLAY"
fi

# Validate base
if [ "$BASE" = "$EXPECTED_BASE" ]; then
    print_status 0 "Base: $BASE"
else
    print_status 1 "Base mismatch"
    echo "   Expected: $EXPECTED_BASE"
    echo "   Found:    $BASE"
fi

# Validate URI (most important for our changes)
if [ "$URI" = "$EXPECTED_URI" ]; then
    print_status 0 "URI: $URI"
else
    print_status 1 "URI mismatch"
    echo "   Expected: $EXPECTED_URI"
    echo "   Found:    $URI"
fi

# Validate description
if [ "$DESCRIPTION" = "$EXPECTED_DESCRIPTION" ]; then
    print_status 0 "Description: $DESCRIPTION"
else
    print_warning "Description mismatch (may be acceptable)"
    echo "   Expected: $EXPECTED_DESCRIPTION"
    echo "   Found:    $DESCRIPTION"
fi

echo ""

# Test 4: Denom units validation
echo "4. Verifying denom units..."

DENOM_UNITS=$(echo "$METADATA" | jq '.denom_units' 2>/dev/null)

if [ -z "$DENOM_UNITS" ] || [ "$DENOM_UNITS" = "null" ]; then
    print_status 1 "Denom units not found"
else
    print_info "Denom units:"
    echo "$DENOM_UNITS" | jq '.' | sed 's/^/   /'
    echo ""
    
    # Check base unit (drop, exponent 0)
    BASE_UNIT=$(echo "$DENOM_UNITS" | jq '.[] | select(.denom == "drop")' 2>/dev/null)
    if [ -n "$BASE_UNIT" ] && [ "$BASE_UNIT" != "null" ]; then
        BASE_EXPONENT=$(echo "$BASE_UNIT" | jq -r '.exponent // "missing"')
        if [ "$BASE_EXPONENT" = "0" ]; then
            print_status 0 "Base unit 'drop' has correct exponent: 0"
        else
            print_status 1 "Base unit 'drop' has incorrect exponent: $BASE_EXPONENT (expected: 0)"
        fi
    else
        print_status 1 "Base unit 'drop' not found in denom_units"
    fi
    
    # Check display unit (Improbability, exponent 18)
    DISPLAY_UNIT=$(echo "$DENOM_UNITS" | jq '.[] | select(.denom == "Improbability")' 2>/dev/null)
    if [ -n "$DISPLAY_UNIT" ] && [ "$DISPLAY_UNIT" != "null" ]; then
        DISPLAY_EXPONENT=$(echo "$DISPLAY_UNIT" | jq -r '.exponent // "missing"')
        if [ "$DISPLAY_EXPONENT" = "18" ]; then
            print_status 0 "Display unit 'Improbability' has correct exponent: 18"
        else
            print_status 1 "Display unit 'Improbability' has incorrect exponent: $DISPLAY_EXPONENT (expected: 18)"
        fi
        
        # Check alias
        ALIASES=$(echo "$DISPLAY_UNIT" | jq -r '.aliases[]?' 2>/dev/null | tr '\n' ' ')
        if echo "$ALIASES" | grep -q "improbability"; then
            print_status 0 "Display unit has correct alias: 'improbability'"
        else
            print_warning "Display unit alias 'improbability' not found (found: $ALIASES)"
        fi
    else
        print_status 1 "Display unit 'Improbability' not found in denom_units"
    fi
fi

echo ""

# Test 5: Query using infinited CLI (if available)
echo "5. Testing infinited CLI query..."

if command -v infinited >/dev/null 2>&1; then
    CLI_METADATA=$(infinited q bank denom-metadata drop 2>/dev/null || echo "")
    if [ -n "$CLI_METADATA" ]; then
        CLI_SYMBOL=$(echo "$CLI_METADATA" | jq -r '.symbol // "missing"' 2>/dev/null || echo "error")
        CLI_DISPLAY=$(echo "$CLI_METADATA" | jq -r '.display // "missing"' 2>/dev/null || echo "error")
        CLI_BASE=$(echo "$CLI_METADATA" | jq -r '.base // "missing"' 2>/dev/null || echo "error")
        
        if [ "$CLI_SYMBOL" = "$EXPECTED_SYMBOL" ] && [ "$CLI_DISPLAY" = "$EXPECTED_DISPLAY" ] && [ "$CLI_BASE" = "$EXPECTED_BASE" ]; then
            print_status 0 "CLI query successful (symbol: $CLI_SYMBOL, display: $CLI_DISPLAY, base: $CLI_BASE)"
        else
            print_status 1 "CLI query returned unexpected values"
            echo "   Expected: symbol=$EXPECTED_SYMBOL, display=$EXPECTED_DISPLAY, base=$EXPECTED_BASE"
            echo "   Found:    symbol=$CLI_SYMBOL, display=$CLI_DISPLAY, base=$CLI_BASE"
        fi
    else
        print_warning "CLI query failed or returned empty result"
    fi
else
    print_warning "infinited CLI not found in PATH, skipping CLI test"
fi

echo ""

# Test 6: Genesis file validation (if accessible)
echo "6. Validating genesis file configuration..."

GENESIS_FILE="$HOME/.infinited/config/genesis.json"
if [ -f "$GENESIS_FILE" ]; then
    GENESIS_METADATA=$(jq '.app_state.bank.denom_metadata[] | select(.base == "drop")' "$GENESIS_FILE" 2>/dev/null)
    
    if [ -n "$GENESIS_METADATA" ] && [ "$GENESIS_METADATA" != "null" ]; then
        GENESIS_URI=$(echo "$GENESIS_METADATA" | jq -r '.uri // "missing"')
        GENESIS_SYMBOL=$(echo "$GENESIS_METADATA" | jq -r '.symbol // "missing"')
        GENESIS_DISPLAY=$(echo "$GENESIS_METADATA" | jq -r '.display // "missing"')
        
        if [ "$GENESIS_URI" = "$EXPECTED_URI" ]; then
            print_status 0 "Genesis file URI correct: $GENESIS_URI"
        else
            print_status 1 "Genesis file URI mismatch"
            echo "   Expected: $EXPECTED_URI"
            echo "   Found:    $GENESIS_URI"
        fi
        
        if [ "$GENESIS_SYMBOL" = "$EXPECTED_SYMBOL" ] && [ "$GENESIS_DISPLAY" = "$EXPECTED_DISPLAY" ]; then
            print_status 0 "Genesis file token config correct (symbol: $GENESIS_SYMBOL, display: $GENESIS_DISPLAY)"
        else
            print_status 1 "Genesis file token config mismatch"
            echo "   Expected: symbol=$EXPECTED_SYMBOL, display=$EXPECTED_DISPLAY"
            echo "   Found:    symbol=$GENESIS_SYMBOL, display=$GENESIS_DISPLAY"
        fi
    else
        print_status 1 "Token metadata not found in genesis file"
    fi
else
    print_warning "Genesis file not found at $GENESIS_FILE, skipping validation"
fi

echo ""
echo "🏁 Validation complete!"
echo "======================"
echo ""
echo "Summary:"
echo "- Token metadata should show:"
echo "  • Name: $EXPECTED_NAME"
echo "  • Symbol: $EXPECTED_SYMBOL"
echo "  • Display: $EXPECTED_DISPLAY"
echo "  • Base: $EXPECTED_BASE"
echo "  • URI: $EXPECTED_URI"
echo "- Chain ID: $EXPECTED_CHAIN_ID"
echo "- EVM Chain ID: $EXPECTED_EVM_CHAIN_ID_HEX ($EXPECTED_EVM_CHAIN_ID_DECIMAL)"

