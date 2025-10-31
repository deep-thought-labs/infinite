#!/bin/bash
#
# Copyright (c) 2025 Deep Thought Labs
# All rights reserved.
#
# This file is part of the internal tooling for node health monitoring and
# validation processes.
#
# Purpose: Comprehensive health check script for Infinite Drive blockchain nodes.
#          Verifies node connectivity, block production, chain configuration,
#          and system status across JSON-RPC, REST API, and Tendermint endpoints.
#

set -e

echo "🔍 Infinite Drive Node Health Check"
echo "=================================="
echo "Timestamp: $(date)"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Test 1: JSON-RPC connectivity
echo "1. Testing JSON-RPC connectivity..."
if curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
  http://localhost:8545 > /dev/null; then
    print_status 0 "JSON-RPC server responding"
else
    print_status 1 "JSON-RPC server not responding"
fi

# Test 2: Cosmos SDK REST API
echo "2. Testing Cosmos SDK REST API..."
if curl -s http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info > /dev/null; then
    print_status 0 "Cosmos SDK REST API responding"
else
    print_status 1 "Cosmos SDK REST API not responding"
fi

# Test 3: Tendermint RPC
echo "3. Testing Tendermint RPC..."
if curl -s http://localhost:26657/status > /dev/null; then
    print_status 0 "Tendermint RPC responding"
else
    print_status 1 "Tendermint RPC not responding"
fi

# Test 4: Chain ID verification
echo "4. Verifying Chain IDs..."

# Known Chain IDs
MAINNET_EVM_HEX="0x66c9a"
MAINNET_EVM_DECIMAL="421018"
MAINNET_COSMOS_NUMERIC="421018"

TESTNET_EVM_HEX="0x19183991"
TESTNET_EVM_DECIMAL="421018001"
TESTNET_COSMOS_NUMERIC="421018001"

# Get Chain IDs from node
EVM_CHAIN_ID_HEX=$(curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
  http://localhost:8545 | jq -r '.result' 2>/dev/null || echo "error")

COSMOS_CHAIN_ID_FULL=$(curl -s http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info | jq -r '.default_node_info.network' 2>/dev/null || echo "error")

# Extract numeric part from Cosmos Chain ID (e.g., "infinite_421018-1" -> "421018")
if [ "$COSMOS_CHAIN_ID_FULL" != "error" ] && [ -n "$COSMOS_CHAIN_ID_FULL" ]; then
    # Extract number between underscore and dash (or end of string)
    # Pattern: prefix_number[-suffix] -> extract number
    COSMOS_CHAIN_ID_NUMERIC=$(echo "$COSMOS_CHAIN_ID_FULL" | sed -E 's/.*_([0-9]+)(-.*)?$/\1/' 2>/dev/null || echo "error")
else
    COSMOS_CHAIN_ID_NUMERIC="error"
fi

# Convert EVM Chain ID from hex to decimal for comparison
if [ "$EVM_CHAIN_ID_HEX" != "error" ] && [ -n "$EVM_CHAIN_ID_HEX" ]; then
    # Remove 0x prefix if present and convert hex to decimal
    HEX_WITHOUT_PREFIX=$(echo "$EVM_CHAIN_ID_HEX" | sed 's/^0x//' 2>/dev/null || echo "")
    if [ -n "$HEX_WITHOUT_PREFIX" ]; then
        # Convert to uppercase for bc compatibility (if needed)
        HEX_UPPER=$(echo "$HEX_WITHOUT_PREFIX" | tr '[:lower:]' '[:upper:]' 2>/dev/null || echo "$HEX_WITHOUT_PREFIX")
        # Use bc for conversion (more portable for large numbers)
        if command -v bc >/dev/null 2>&1; then
            EVM_CHAIN_ID_DECIMAL=$(echo "ibase=16; $HEX_UPPER" | bc 2>/dev/null || echo "error")
        else
            # Fallback to arithmetic expansion (works for numbers that fit in bash's int range)
            EVM_CHAIN_ID_DECIMAL=$((0x${HEX_WITHOUT_PREFIX})) 2>/dev/null || echo "error"
        fi
    else
        EVM_CHAIN_ID_DECIMAL="error"
    fi
else
    EVM_CHAIN_ID_DECIMAL="error"
fi

# Verify Chain IDs against known networks
NETWORK_DETECTED=""
CHAIN_ID_MATCH=false

if [ "$EVM_CHAIN_ID_HEX" = "$MAINNET_EVM_HEX" ] && [ "$EVM_CHAIN_ID_DECIMAL" = "$MAINNET_EVM_DECIMAL" ] && \
   [ "$COSMOS_CHAIN_ID_NUMERIC" = "$MAINNET_COSMOS_NUMERIC" ]; then
    NETWORK_DETECTED="MAINNET"
    CHAIN_ID_MATCH=true
elif [ "$EVM_CHAIN_ID_HEX" = "$TESTNET_EVM_HEX" ] && [ "$EVM_CHAIN_ID_DECIMAL" = "$TESTNET_EVM_DECIMAL" ] && \
     [ "$COSMOS_CHAIN_ID_NUMERIC" = "$TESTNET_COSMOS_NUMERIC" ]; then
    NETWORK_DETECTED="TESTNET"
    CHAIN_ID_MATCH=true
fi

if [ "$CHAIN_ID_MATCH" = true ] && [ -n "$NETWORK_DETECTED" ]; then
    print_status 0 "Chain IDs correct - Network: $NETWORK_DETECTED (EVM: $EVM_CHAIN_ID_HEX / $EVM_CHAIN_ID_DECIMAL, Cosmos: $COSMOS_CHAIN_ID_FULL -> $COSMOS_CHAIN_ID_NUMERIC)"
else
    print_status 1 "Chain ID mismatch (EVM: $EVM_CHAIN_ID_HEX / $EVM_CHAIN_ID_DECIMAL, Cosmos: $COSMOS_CHAIN_ID_FULL -> $COSMOS_CHAIN_ID_NUMERIC)"
    echo -e "   Expected: Mainnet (EVM: $MAINNET_EVM_HEX / $MAINNET_EVM_DECIMAL, Cosmos: ..._${MAINNET_COSMOS_NUMERIC}_...) or"
    echo -e "             Testnet (EVM: $TESTNET_EVM_HEX / $TESTNET_EVM_DECIMAL, Cosmos: ..._${TESTNET_COSMOS_NUMERIC}_...)"
fi

# Test 5: Block production
echo "5. Checking block production..."
CURRENT_HEIGHT=$(curl -s http://localhost:1317/cosmos/base/tendermint/v1beta1/blocks/latest | jq -r '.block.header.height' 2>/dev/null || echo "0")
sleep 3
NEW_HEIGHT=$(curl -s http://localhost:1317/cosmos/base/tendermint/v1beta1/blocks/latest | jq -r '.block.header.height' 2>/dev/null || echo "0")

if [ "$NEW_HEIGHT" -gt "$CURRENT_HEIGHT" ]; then
    print_status 0 "Blocks being produced (height: $NEW_HEIGHT)"
else
    print_warning "Block production may be stalled (height: $NEW_HEIGHT)"
fi

# Test 6: Token metadata
echo "6. Verifying token metadata..."
METADATA=$(curl -s http://localhost:1317/cosmos/bank/v1beta1/denoms_metadata | jq '.metadatas[] | select(.base == "drop")' 2>/dev/null)

if [ -n "$METADATA" ]; then
    NAME=$(echo "$METADATA" | jq -r '.name')
    SYMBOL=$(echo "$METADATA" | jq -r '.symbol')
    if [ "$NAME" = "Improbability" ] && [ "$SYMBOL" = "TEA" ]; then
        print_status 0 "Token metadata correct (Improbability/TEA)"
    else
        print_status 1 "Token metadata incorrect ($NAME/$SYMBOL)"
    fi
else
    print_status 1 "Token metadata not found"
fi

# Test 7: Process status
echo "7. Checking process status..."
PID=$(pgrep infinited 2>/dev/null || echo "")
if [ -n "$PID" ]; then
    print_status 0 "Infinited process running (PID: $PID)"
else
    print_status 1 "Infinited process not running"
fi

# Test 8: Data directory
echo "8. Checking data directory..."
DATA_DIR="$HOME/.infinited"
if [ -d "$DATA_DIR" ]; then
    DISK_USAGE=$(du -sh "$DATA_DIR" 2>/dev/null | awk '{print $1}' || echo "unknown")
    print_status 0 "Data directory exists (size: $DISK_USAGE)"
else
    print_status 1 "Data directory not found"
fi

echo ""
echo "🏁 Health check complete!"
echo "========================="
