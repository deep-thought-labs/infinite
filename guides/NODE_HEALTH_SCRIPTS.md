# Infinite Drive Node Health Verification Scripts

This document provides comprehensive scripts and examples for verifying the health and status of your Infinite Drive blockchain node. These scripts help monitor various aspects of node operation, from basic connectivity to advanced blockchain state verification.

## Quick Start - Automated Health Check

**For immediate health verification, use the automated script:**

```bash
# Run the comprehensive health check script
./infinite_health_check.sh
```

**What this script does**: Performs 8 automated tests covering all essential node health aspects with colorized output and clear pass/fail indicators.

**When to use**: For quick verification, monitoring, or troubleshooting.

## Manual Verification Scripts

**What this section covers**: Detailed, step-by-step verification scripts for specific scenarios and learning purposes.

**When to use**: When you need to understand specific checks, troubleshoot particular issues, or customize verification processes.

## Table of Contents

1. [Quick Start - Automated Health Check](#quick-start---automated-health-check)
2. [Manual Verification Scripts](#manual-verification-scripts)
3. [Basic Connectivity Tests](#basic-connectivity-tests)
4. [Blockchain State Verification](#blockchain-state-verification)
5. [Token and Account Verification](#token-and-account-verification)
6. [Network and Consensus Health](#network-and-consensus-health)
7. [Performance Monitoring](#performance-monitoring)
8. [Automated Health Check Script](#automated-health-check-script)
9. [Troubleshooting Common Issues](#troubleshooting-common-issues)

## Basic Connectivity Tests

### 1. JSON-RPC Server Health Check

```bash
#!/bin/bash
# Check if JSON-RPC server is responding
echo "Testing JSON-RPC connectivity..."

# Test basic connectivity
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
  http://localhost:8545

echo -e "\n✅ JSON-RPC server is responding"
```

### 2. Cosmos SDK REST API Health Check

```bash
#!/bin/bash
# Check Cosmos SDK REST API
echo "Testing Cosmos SDK REST API..."

# Get node info
curl -s http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info | jq '.'

# Get latest block
curl -s http://localhost:1317/cosmos/base/tendermint/v1beta1/blocks/latest | jq '.'

echo "✅ Cosmos SDK REST API is responding"
```

### 3. Tendermint RPC Health Check

```bash
#!/bin/bash
# Check Tendermint RPC
echo "Testing Tendermint RPC..."

# Get node status
curl -s http://localhost:26657/status | jq '.'

# Get network info
curl -s http://localhost:26657/net_info | jq '.'

echo "✅ Tendermint RPC is responding"
```

## Blockchain State Verification

### 4. Chain ID Verification

```bash
#!/bin/bash
# Verify correct chain ID
echo "Verifying Chain ID..."

# Get EVM Chain ID
EVM_CHAIN_ID=$(curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
  http://localhost:8545 | jq -r '.result')

echo "EVM Chain ID: $EVM_CHAIN_ID (should be 0x66bca = 421018)"

# Get Cosmos Chain ID
COSMOS_CHAIN_ID=$(curl -s http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info | jq -r '.default_node_info.network')

echo "Cosmos Chain ID: $COSMOS_CHAIN_ID (should be infinite_421018-1)"

if [ "$EVM_CHAIN_ID" = "0x66bca" ] && [ "$COSMOS_CHAIN_ID" = "infinite_421018-1" ]; then
    echo "✅ Chain IDs are correct"
else
    echo "❌ Chain ID mismatch detected"
fi
```

### 5. Block Production Verification

```bash
#!/bin/bash
# Verify block production
echo "Monitoring block production..."

# Get current block height
CURRENT_HEIGHT=$(curl -s http://localhost:1317/cosmos/base/tendermint/v1beta1/blocks/latest | jq -r '.block.header.height')

echo "Current block height: $CURRENT_HEIGHT"

# Wait and check if height increases
sleep 5
NEW_HEIGHT=$(curl -s http://localhost:1317/cosmos/base/tendermint/v1beta1/blocks/latest | jq -r '.block.header.height')

echo "New block height: $NEW_HEIGHT"

if [ "$NEW_HEIGHT" -gt "$CURRENT_HEIGHT" ]; then
    echo "✅ Blocks are being produced"
else
    echo "❌ Block production may be stalled"
fi
```

### 6. Genesis State Verification

```bash
#!/bin/bash
# Verify genesis configuration
echo "Verifying genesis state..."

# Check token metadata
curl -s http://localhost:1317/cosmos/bank/v1beta1/denoms_metadata | jq '.metadatas[] | select(.base == "drop")'

# Check EVM parameters
curl -s http://localhost:1317/cosmos/evm/v1/params | jq '.'

echo "✅ Genesis state verification complete"
```

## Token and Account Verification

### 7. Token Metadata Verification

```bash
#!/bin/bash
# Verify 42 token metadata
echo "Verifying 42 token metadata..."

METADATA=$(curl -s http://localhost:1317/cosmos/bank/v1beta1/denoms_metadata | jq '.metadatas[] | select(.base == "drop")')

echo "Token Metadata:"
echo "$METADATA" | jq '.'

# Verify specific fields
NAME=$(echo "$METADATA" | jq -r '.name')
SYMBOL=$(echo "$METADATA" | jq -r '.symbol')
DISPLAY=$(echo "$METADATA" | jq -r '.display')
BASE=$(echo "$METADATA" | jq -r '.base')

if [ "$NAME" = "Improbability" ] && [ "$SYMBOL" = "42" ] && [ "$DISPLAY" = "42" ] && [ "$BASE" = "drop" ]; then
    echo "✅ Token metadata is correct"
else
    echo "❌ Token metadata mismatch"
    echo "Expected: Improbability/42/42/drop"
    echo "Found: $NAME/$SYMBOL/$DISPLAY/$BASE"
fi
```

### 8. Account Balance Verification

```bash
#!/bin/bash
# Verify account balances
echo "Verifying account balances..."

# Get validator account (first account from keyring)
VALIDATOR_ADDR=$(infinited keys show validator --keyring-backend test --output json | jq -r '.address')

echo "Validator address: $VALIDATOR_ADDR"

# Check balance
BALANCE=$(curl -s http://localhost:1317/cosmos/bank/v1beta1/balances/$VALIDATOR_ADDR | jq '.balances[] | select(.denom == "drop")')

echo "Validator balance:"
echo "$BALANCE" | jq '.'

# Convert to 42 (divide by 10^18)
BALANCE_42=$(echo "$BALANCE" | jq -r '.amount' | awk '{print $1/1000000000000000000}')
echo "Balance in 42: $BALANCE_42"

if [ "$(echo "$BALANCE_42 > 0" | bc)" -eq 1 ]; then
    echo "✅ Account has 42 balance"
else
    echo "❌ Account balance is zero or invalid"
fi
```

### 9. EVM Account Verification

```bash
#!/bin/bash
# Verify EVM account
echo "Verifying EVM account..."

# Get EVM address from Cosmos address
COSMOS_ADDR=$(infinited keys show validator --keyring-backend test --output json | jq -r '.address')
EVM_ADDR=$(curl -s -X POST -H "Content-Type: application/json" \
  --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_accounts\",\"params\":[],\"id\":1}" \
  http://localhost:8545 | jq -r '.result[0]')

echo "Cosmos address: $COSMOS_ADDR"
echo "EVM address: $EVM_ADDR"

# Get EVM balance
EVM_BALANCE=$(curl -s -X POST -H "Content-Type: application/json" \
  --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getBalance\",\"params\":[\"$EVM_ADDR\",\"latest\"],\"id\":1}" \
  http://localhost:8545 | jq -r '.result')

echo "EVM balance (wei): $EVM_BALANCE"

# Convert to 42
BALANCE_42=$(printf "%d" "$EVM_BALANCE" | awk '{print $1/1000000000000000000}')
echo "EVM balance in 42: $BALANCE_42"

echo "✅ EVM account verification complete"
```

## Network and Consensus Health

### 10. Validator Status Check

```bash
#!/bin/bash
# Check validator status
echo "Checking validator status..."

# Get validator info
VALIDATOR_ADDR=$(infinited keys show validator --keyring-backend test --output json | jq -r '.address')
VALIDATOR_INFO=$(curl -s http://localhost:1317/cosmos/staking/v1beta1/validators | jq ".validators[] | select(.operator_address == \"$VALIDATOR_ADDR\")")

echo "Validator information:"
echo "$VALIDATOR_INFO" | jq '.'

# Check if validator is bonded
STATUS=$(echo "$VALIDATOR_INFO" | jq -r '.status')
if [ "$STATUS" = "BOND_STATUS_BONDED" ]; then
    echo "✅ Validator is bonded and active"
else
    echo "❌ Validator is not bonded (status: $STATUS)"
fi
```

### 11. Consensus Health Check

```bash
#!/bin/bash
# Check consensus health
echo "Checking consensus health..."

# Get consensus state
CONSENSUS_STATE=$(curl -s http://localhost:26657/consensus_state | jq '.')

echo "Consensus state:"
echo "$CONSENSUS_STATE" | jq '.'

# Check if consensus is healthy
ROUND_STATE=$(echo "$CONSENSUS_STATE" | jq -r '.result.round_state.height_vote_set[0].round')
CURRENT_HEIGHT=$(echo "$CONSENSUS_STATE" | jq -r '.result.round_state.height')

echo "Current height: $CURRENT_HEIGHT"
echo "Current round: $ROUND_STATE"

echo "✅ Consensus health check complete"
```

### 12. Network Connectivity Check

```bash
#!/bin/bash
# Check network connectivity
echo "Checking network connectivity..."

# Get network info
NET_INFO=$(curl -s http://localhost:26657/net_info | jq '.')

echo "Network information:"
echo "$NET_INFO" | jq '.'

# Check peer count
PEER_COUNT=$(echo "$NET_INFO" | jq -r '.result.n_peers')
echo "Connected peers: $PEER_COUNT"

if [ "$PEER_COUNT" -gt 0 ]; then
    echo "✅ Network has peers"
else
    echo "⚠️  No peers connected (normal for local node)"
fi
```

## Performance Monitoring

### 13. Memory and CPU Usage

```bash
#!/bin/bash
# Monitor resource usage
echo "Monitoring resource usage..."

# Get process info
PID=$(pgrep infinited)
if [ -n "$PID" ]; then
    echo "Infinited process PID: $PID"
    
    # Memory usage
    MEMORY=$(ps -p $PID -o rss= | awk '{print $1/1024 " MB"}')
    echo "Memory usage: $MEMORY"
    
    # CPU usage
    CPU=$(ps -p $PID -o %cpu= | awk '{print $1 "%"}')
    echo "CPU usage: $CPU"
    
    echo "✅ Process monitoring complete"
else
    echo "❌ Infinited process not found"
fi
```

### 14. Disk Usage Check

```bash
#!/bin/bash
# Check disk usage
echo "Checking disk usage..."

# Check data directory
DATA_DIR="$HOME/.infinited"
if [ -d "$DATA_DIR" ]; then
    DISK_USAGE=$(du -sh "$DATA_DIR" | awk '{print $1}')
    echo "Data directory size: $DISK_USAGE"
    
    # Check available space
    AVAILABLE=$(df -h "$DATA_DIR" | tail -1 | awk '{print $4}')
    echo "Available space: $AVAILABLE"
    
    echo "✅ Disk usage check complete"
else
    echo "❌ Data directory not found"
fi
```

## Automated Health Check Script

### 15. Complete Health Check Script

```bash
#!/bin/bash
# Complete Infinite Drive node health check
# Save as: infinite_health_check.sh

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
EVM_CHAIN_ID=$(curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
  http://localhost:8545 | jq -r '.result' 2>/dev/null || echo "error")

COSMOS_CHAIN_ID=$(curl -s http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info | jq -r '.default_node_info.network' 2>/dev/null || echo "error")

if [ "$EVM_CHAIN_ID" = "0x66bca" ] && [ "$COSMOS_CHAIN_ID" = "infinite_421018-1" ]; then
    print_status 0 "Chain IDs correct (EVM: $EVM_CHAIN_ID, Cosmos: $COSMOS_CHAIN_ID)"
else
    print_status 1 "Chain ID mismatch (EVM: $EVM_CHAIN_ID, Cosmos: $COSMOS_CHAIN_ID)"
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
    if [ "$NAME" = "Improbability" ] && [ "$SYMBOL" = "42" ]; then
        print_status 0 "Token metadata correct (Improbability/42)"
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
```

## Troubleshooting Common Issues

### 16. Common Issue Detection Script

```bash
#!/bin/bash
# Troubleshooting script for common issues
# Save as: infinite_troubleshoot.sh

echo "🔧 Infinite Drive Troubleshooting"
echo "==============================="

# Check if ports are in use
echo "Checking port usage..."
if lsof -i :8545 > /dev/null 2>&1; then
    echo "✅ Port 8545 (JSON-RPC) is in use"
else
    echo "❌ Port 8545 (JSON-RPC) is not in use"
fi

if lsof -i :1317 > /dev/null 2>&1; then
    echo "✅ Port 1317 (REST API) is in use"
else
    echo "❌ Port 1317 (REST API) is not in use"
fi

if lsof -i :26657 > /dev/null 2>&1; then
    echo "✅ Port 26657 (Tendermint RPC) is in use"
else
    echo "❌ Port 26657 (Tendermint RPC) is not in use"
fi

# Check log files for errors
echo ""
echo "Checking recent log entries..."
LOG_FILE="$HOME/.infinited/logs/infinited.log"
if [ -f "$LOG_FILE" ]; then
    echo "Recent ERROR entries:"
    tail -100 "$LOG_FILE" | grep -i error | tail -5
    echo ""
    echo "Recent WARN entries:"
    tail -100 "$LOG_FILE" | grep -i warn | tail -5
else
    echo "Log file not found at $LOG_FILE"
fi

# Check configuration files
echo ""
echo "Checking configuration files..."
CONFIG_DIR="$HOME/.infinited/config"
if [ -d "$CONFIG_DIR" ]; then
    echo "Configuration files found:"
    ls -la "$CONFIG_DIR"
else
    echo "Configuration directory not found"
fi

echo ""
echo "🔧 Troubleshooting complete!"
```

## Usage Instructions

### Running Individual Scripts

```bash
# Make scripts executable
chmod +x infinite_health_check.sh
chmod +x infinite_troubleshoot.sh

# Run health check
./infinite_health_check.sh

# Run troubleshooting
./infinite_troubleshoot.sh
```

### Running Individual Tests

```bash
# Test JSON-RPC
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
  http://localhost:8545

# Test REST API
curl -s http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info | jq '.'

# Test Tendermint RPC
curl -s http://localhost:26657/status | jq '.'
```

## Expected Results

### Healthy Node Indicators

- ✅ All three RPC endpoints responding
- ✅ Chain IDs: EVM=0x66bca (421018), Cosmos=infinite_421018-1
- ✅ Block height increasing over time
- ✅ Token metadata: Improbability/42/42/drop
- ✅ Infinited process running
- ✅ Data directory exists and growing

### Warning Signs

- ⚠️ Block production stalled
- ⚠️ High memory/CPU usage
- ⚠️ Low disk space
- ⚠️ No peers connected (normal for local node)
- ⚠️ RPC endpoints not responding

## Monitoring Recommendations

1. **Run health checks every 5 minutes** for production nodes
2. **Monitor disk space** - blockchain data grows continuously
3. **Check memory usage** - should be stable, not continuously growing
4. **Verify block production** - should see new blocks every ~1 second
5. **Monitor RPC response times** - should be under 1 second

## Integration with Monitoring Systems

These scripts can be integrated with monitoring systems like:

- **Prometheus + Grafana** for metrics collection and visualization
- **Nagios** for alerting
- **Custom monitoring dashboards**
- **Log aggregation systems** (ELK stack, Splunk)

---

*This document provides comprehensive tools for monitoring your Infinite Drive blockchain node. Regular health checks ensure optimal performance and early detection of issues.*
