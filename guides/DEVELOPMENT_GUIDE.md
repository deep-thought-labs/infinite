# Development Guide

**⚠️ IMPORTANT**: The instructions in this guide are **FOR DEVELOPMENT AND LEARNING PURPOSES ONLY**. They create test accounts and use development configurations. **DO NOT use these instructions for production deployment.**

This guide covers testing, manual compilation, and development-specific configurations for Infinite Drive.

## Table of Contents

1. [Testing Your Running Node](#testing-your-running-node)
2. [Manual Compilation & Configuration](#manual-compilation--configuration)
3. [Understanding PATH Issues](#understanding-path-issues)
4. [Development vs Production](#development-vs-production)

## Testing Your Running Node

**What we're doing**: Verifying that your blockchain node is working correctly and learning how to interact with it.

### 1. Automated Health Check (Easiest)

**What this does**: Runs a comprehensive test of all node services automatically.

```bash
# Run the automated health check
./infinite_health_check.sh
```

**Expected output**:
```
🔍 Infinite Drive Node Health Check
==================================
✅ JSON-RPC server responding
✅ Cosmos SDK REST API responding  
✅ Tendermint RPC responding
✅ Chain IDs correct (EVM: 0x66c9a, Cosmos: 421018)
✅ Blocks being produced (height: XXX)
✅ Token metadata correct (Improbability/TEA)
✅ Infinited process running
✅ Data directory exists
```

### 2. Manual API Testing (Learn How It Works)

#### Test JSON-RPC (EVM Compatibility)
**What this tests**: Ethereum-compatible API for dApps and wallets.

```bash
# Get chain ID
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
  http://localhost:8545

# Expected response: {"jsonrpc":"2.0","id":1,"result":"0x66c9a"}

# Get available accounts
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_accounts","params":[],"id":1}' \
  http://localhost:8545

# Get account balance (replace with actual address from above)
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_getBalance","params":["0x...","latest"],"id":1}' \
  http://localhost:8545
```

#### Test Cosmos SDK REST API
**What this tests**: Cosmos blockchain query interface.

```bash
# Get node information
curl -s http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info | jq '.'

# Get latest block height
curl -s http://localhost:1317/cosmos/base/tendermint/v1beta1/blocks/latest | jq '.block.header.height'

# Get TEA token metadata
curl -s http://localhost:1317/cosmos/bank/v1beta1/denoms_metadata | jq '.metadatas[] | select(.base == "drop")'
```

#### Test Tendermint RPC
**What this tests**: Low-level blockchain interface.

```bash
# Get node status
curl -s http://localhost:26657/status | jq '.result.node_info.network'

# Expected response: "421018"
```

### 3. Token Verification

**What this verifies**: That the TEA token is properly configured.

```bash
# Check token metadata
curl -s http://localhost:1317/cosmos/bank/v1beta1/denoms_metadata | jq '.metadatas[] | select(.base == "drop")'

# Expected response:
# {
#   "name": "Improbability",
#   "symbol": "TEA", 
#   "base": "drop",
#   "display": "TEA",
#   "denom_units": [
#     {"denom": "drop", "exponent": 0},
#     {"denom": "TEA", "exponent": 18}
#   ]
# }
```

**Understanding the token**:
- **Base unit**: `drop` (smallest unit, like wei in Ethereum)
- **Display unit**: `TEA` (what users see, like ETH)
- **Conversion**: 1 TEA = 10^18 drop (18 decimals)

## Manual Compilation & Configuration

**What this section covers**: How to manually compile and configure the blockchain without using the automated script.

**When to use this**: When you want to understand the build process, customize configuration, or learn how the blockchain works internally.

### 1. Manual Compilation

**What this does**: Compiles the blockchain binary step by step, giving you full control over the process.

#### Understanding the Build Process
The Infinite Drive project uses a Makefile-based build system that:
1. **Compiles the main binary**: `infinited` (the blockchain node)
2. **Sets build flags**: Including version information and optimization flags
3. **Installs dependencies**: Downloads and compiles all Go modules
4. **Creates executables**: Places binaries in `$HOME/go/bin/`

#### Build Commands

```bash
# Full compilation and installation
make install

# Compile without installing
make build

# Clean build artifacts
make clean

# Run tests
make test

# Check for linting issues
make lint
```

#### Build Output

After successful compilation, you should see:
```
🚚  Installing infinited to '/Users/yourusername/go'/bin ...
BUILD_FLAGS: -tags netgo -ldflags '-X github.com/cosmos/cosmos-sdk/version.Name=infinite ...'
```

The binary will be installed to: `$HOME/go/bin/infinited`

### 2. Manual Node Configuration (DEVELOPMENT ONLY)

**What this does**: Sets up the blockchain node manually, giving you full control over configuration.

**⚠️ DEVELOPMENT WARNING**: This creates test accounts and development configurations. For production, you need proper genesis files and secure key management.

#### Initialize the Node

```bash
# Initialize the node (creates ~/.infinited/ directory)
infinited init mynode --chain-id infinite_421018-1
```

#### Create Test Accounts

```bash
# Add a validator account (TEST ONLY - not for production)
infinited keys add validator --keyring-backend test

# Add a user account (TEST ONLY - not for production)
infinited keys add user --keyring-backend test

# List accounts
infinited keys list --keyring-backend test
```

#### Configure Genesis (DEVELOPMENT CONFIGURATION)

```bash
# Add test accounts to genesis (DEVELOPMENT ONLY)
infinited genesis add-genesis-account validator 1000000000000000000000drop --keyring-backend test
infinited genesis add-genesis-account user 1000000000000000000000drop --keyring-backend test

# Create genesis transaction (DEVELOPMENT ONLY)
infinited genesis gentx validator 1000000000000000000000drop --gas-prices 0drop --keyring-backend test --chain-id infinite_421018-1

# Collect genesis transactions
infinited genesis collect-gentxs
```

#### Start the Node (DEVELOPMENT MODE)

```bash
# Start the node with all APIs enabled (DEVELOPMENT CONFIGURATION)
infinited start --json-rpc.api eth,txpool,personal,net,debug,web3 --minimum-gas-prices=0drop
```

**Note**: This creates a development blockchain with test accounts. For production, you would use proper genesis files and secure key management.

## Understanding PATH Issues

**What this explains**: Why you might get "command not found" errors and how to fix them.

**Note**: If you followed the Prerequisites section correctly, your PATH should already be configured. This section explains the issue for troubleshooting purposes.

### The PATH Problem

**What happens**: The most common issue users encounter is the `infinited: command not found` error. This happens because the binary is installed to `$HOME/go/bin/` but this directory is not in your system's PATH.

### Solution: Export PATH

```bash
# Add Go bin directory to PATH
export PATH=$HOME/go/bin:$PATH

# Verify infinited is now accessible
which infinited
infinited version
```

### Permanent PATH Fix

To avoid this issue in the future, add the following to your shell configuration file:

```bash
# Add to ~/.bashrc, ~/.zshrc, or ~/.profile
echo 'export PATH=$HOME/go/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

### Binary Location Consistency

**Important**: Always use `make install` for consistency. If you manually compile binaries to other locations later, you might have conflicts where the system doesn't know which binary to use.

**Best practice**: Keep all Go binaries in `$GOPATH/bin` and ensure this directory is in your PATH.

## Development vs Production

### Development Configuration
- **Data Directory**: `~/.infinited/` (user home directory)
- **Accounts**: Test accounts with `--keyring-backend test`
- **Genesis**: Created manually with test data
- **Security**: Minimal security for easy testing
- **Purpose**: Learning, testing, development

### Production Configuration
- **Data Directory**: `/opt/infinited/` (system directory)
- **Accounts**: Secure key management with proper keyring
- **Genesis**: Official genesis file from network
- **Security**: Full security with proper permissions
- **Purpose**: Real blockchain network participation

**Important**: Never use development configurations in production. Always follow the [Production Deployment](PRODUCTION_DEPLOYMENT.md) guide for actual deployment.

## Testing Commands

**What this section covers**: Comprehensive testing commands available in the Infinite Drive project.

**When to use**: When you want to run tests, check coverage, or benchmark performance.

### Available Test Commands

All test scripts are found in the `Makefile` in the root of the repository:

#### Unit Testing
```bash
# Run unit tests
make test-unit
```

#### Coverage Testing
```bash
# Generate code coverage report
make test-unit-cover
```
**What this does**: Generates a code coverage file `filtered_coverage.txt` and prints the covered code percentage for working files.

#### Fuzz Testing
```bash
# Run fuzz tests
make test-fuzz
```

#### Solidity Testing
```bash
# Run Solidity contract tests
make test-solidity
```

#### Benchmark Testing
```bash
# Run performance benchmarks
make benchmark
```

### Running Tests in Development

**For development workflow**:
1. **Quick tests**: `make test-unit` (fastest)
2. **Contract tests**: `make test-solidity` (when working with smart contracts)
3. **Full coverage**: `make test-unit-cover` (before committing)
4. **Performance**: `make benchmark` (when optimizing)

## Next Steps

- **[Production Deployment](PRODUCTION_DEPLOYMENT.md)** - Learn how to deploy to production
- **[Troubleshooting](TROUBLESHOOTING.md)** - Common issues and solutions
- **[Node Health Scripts](NODE_HEALTH_SCRIPTS.md)** - Comprehensive health monitoring and verification tools
- **Explore APIs**: Try different API endpoints and methods
- **Deploy Smart Contracts**: Use development tools like Hardhat or Foundry
