# Validation and Testing Guide

Complete guide for validation and testing scripts for Infinite Drive.

## 📋 Table of Contents

- [Available Validation Scripts](#available-validation-scripts)
- [Node Health Check](#node-health-check)
- [Configuration Validation](#configuration-validation)
- [Code Validation](#code-validation)
- [Unit and Integration Tests](#unit-and-integration-tests)
- [Recommended Validation Workflows](#recommended-validation-workflows)

## 🔍 Available Validation Scripts

| Script | Purpose | Requires Node | Time |
|--------|---------|---------------|------|
| `infinite_health_check.sh` | Complete health check | ✅ Yes | <1 min |
| `validate_token_config.sh` | Validate token configuration | ✅ Yes | <1 min |
| `validate_customizations.sh` | Validate customizations in code | ❌ No | <1 min |
| `check_build_prerequisites.sh` | Verify build prerequisites | ❌ No | <1 min |

## 🏥 Node Health Check

### Script: `scripts/infinite_health_check.sh`

**Purpose**: Verify that the node is functioning correctly and all services are available.

**What it validates**:
- ✅ JSON-RPC connectivity (port 8545)
- ✅ REST API connectivity (port 1317)
- ✅ Tendermint connectivity (port 26657)
- ✅ Block production
- ✅ Chain synchronization
- ✅ System status
- ✅ Chain information (chain ID, height, etc.)

**Requirements**:
- Running node (started with Drive or direct installation)
- `jq` installed
- `curl` installed

**Usage**:
```bash
# From project root
./scripts/infinite_health_check.sh
```

**Expected output**:
```
🔍 Infinite Drive Node Health Check
==================================
Timestamp: 2025-11-16 13:48:41

✅ JSON-RPC endpoint responding (port 8545)
✅ REST API endpoint responding (port 1317)
✅ Tendermint endpoint responding (port 26657)
✅ Node is producing blocks
✅ Chain is synced
...
```

**When to use**:
- After starting a node
- To verify the node is still functioning
- Before important operations
- For debugging connectivity issues

**Result interpretation**:
- ✅ Green: Everything works correctly
- ❌ Red: There's a problem that needs attention
- ⚠️ Yellow: Warning (may be normal in some cases)

## 🪙 Token Configuration Validation

### Script: `scripts/validate_token_config.sh`

**Purpose**: Validate that the Improbability (42) token configuration is correct in the running node.

**What it validates**:
- ✅ Token metadata (name: "Improbability", symbol: "42")
- ✅ Base denom: "drop"
- ✅ Display denom: "Improbability"
- ✅ Chain ID: 421018
- ✅ Token URI: `https://assets.infinitedrive.xyz/tokens/42/icon.png`
- ✅ Configuration in genesis
- ✅ Configuration in running node (REST API)
- ✅ Correct denomination units

**Requirements**:
- Running node
- `jq` installed
- `curl` installed

**Usage**:
```bash
# From project root
./scripts/validate_token_config.sh
```

**Expected output**:
```
🔍 Token Configuration Validation
==================================
Timestamp: 2025-11-16 13:48:41

✅ Token metadata found in REST API
✅ Base denom correct: drop
✅ Display denom correct: Improbability
✅ Symbol correct: 42
✅ URI correct: https://assets.infinitedrive.xyz/tokens/42/icon.png
✅ Chain ID correct: 421018
...
```

**When to use**:
- After token configuration changes
- After updating genesis
- To verify changes were applied correctly
- Before making a release

**Expected values** (according to customizations):
- Base denom: `drop`
- Display denom: `Improbability`
- Symbol: `42`
- Chain ID: `421018` (EVM) / `infinite_421018-1` (Cosmos)
- URI: `https://assets.infinitedrive.xyz/tokens/42/icon.png`

## 🔧 Code Validation

### Script: `scripts/validate_customizations.sh`

**Purpose**: Validate that Infinite Drive customizations are correctly implemented in the code.

**What it validates**:
- ✅ Token configuration in code (`x/vm/types/params.go`)
- ✅ Correct constants (`testutil/constants/constants.go`)
- ✅ Bech32 prefixes (`infinited/config/bech32.go`)
- ✅ Custom genesis functions (`infinited/genesis.go`)
- ✅ Upstream compliance (go.mod, package paths)
- ✅ Correct branding

**Requirements**:
- Only needs code access (doesn't require node)
- Git (to verify upstream compliance)

**Usage**:
```bash
# From project root
./scripts/validate_customizations.sh
```

**Expected output**:
```
🔍 Validating Infinite Drive customizations...
==============================================

Token configuration...
✅ Token display denom
✅ Token base denom
✅ EVM Chain ID

Genesis state customization...
✅ Mint genesis state function
✅ Staking genesis state function
✅ Governance genesis state function
✅ Genesis functions use ExampleAttoDenom (drop)

✅ All customizations validated
✅ Upstream compliance verified
```

**When to use**:
- After making code changes
- Before committing
- During merges with upstream
- To verify customizations weren't lost

**What it specifically verifies**:
1. **Token config**: `DefaultEVMDenom = "drop"`, `DefaultEVMDisplayDenom = "Improbability"`
2. **Chain ID**: `DefaultEVMChainID = 421018`
3. **Bech32**: `Bech32Prefix = "infinite"`
4. **Genesis functions**: `NewStakingGenesisState()`, `NewGovGenesisState()`, `NewMintGenesisState()`
5. **Package paths**: Should not have `deep-thought-labs/infinite` (should be `github.com/cosmos/evm`)

## 🧪 Unit and Integration Tests

### Unit Tests

**Command**: `make test-unit`

**What it does**: Runs all unit tests in the project.

**Usage**:
```bash
make test-unit
```

**Estimated time**: 5-15 minutes

**When to use**: After making code changes, before commit

### Integration Tests

**Command**: `make test-infinited`

**What it does**: Runs integration tests specific to `infinited`.

**Usage**:
```bash
make test-infinited
```

**Estimated time**: 10-20 minutes

### Complete Tests

**Command**: `make test-all`

**What it does**: Runs all tests (unit + integration).

**Usage**:
```bash
make test-all
```

**Estimated time**: 15-30 minutes

### Tests with Coverage

**Command**: `make test-unit-cover`

**What it does**: Runs unit tests and generates coverage report.

**Usage**:
```bash
make test-unit-cover
```

**Result**: Generates `coverage.txt` with the report

## 🔄 Recommended Validation Workflows

### Workflow 1: Quick Validation After Changes

**When**: After making code changes

```bash
# 1. Validate code
./scripts/validate_customizations.sh

# 2. Compile to verify no errors
make install

# 3. Quick unit tests
make test-unit
```

**Total time**: ~10 minutes

### Workflow 2: Complete Validation Before Commit

**When**: Before committing important changes

```bash
# 1. Validate code
./scripts/validate_customizations.sh

# 2. Compile
make install

# 3. Complete tests
make test-all

# 4. If you have a running node, validate configuration
./scripts/validate_token_config.sh
```

**Total time**: ~30 minutes

### Workflow 3: Running Node Validation

**When**: After starting a node or after configuration changes

```bash
# 1. Complete health check
./scripts/infinite_health_check.sh

# 2. Validate token configuration
./scripts/validate_token_config.sh
```

**Total time**: ~2 minutes

### Workflow 4: Pre-Release Validation

**When**: Before creating a release

```bash
# 1. Validate code
./scripts/validate_customizations.sh

# 2. Compile
make install

# 3. Complete tests
make test-all

# 4. Release test (dry run)
make release-dry-run-linux

# 5. If you have a test node, validate
./scripts/infinite_health_check.sh
./scripts/validate_token_config.sh
```

**Total time**: ~45 minutes

## 📝 Other Useful Scripts

### Verify Build Prerequisites

**Script**: `scripts/check_build_prerequisites.sh`

**Purpose**: Verify you have all prerequisites installed to compile.

**Usage**:
```bash
./scripts/check_build_prerequisites.sh
```

### List All Customizations

**Script**: `scripts/list_all_customizations.sh`

**Purpose**: List all differences with upstream.

**Usage**:
```bash
# Compare with main
./scripts/list_all_customizations.sh main

# Compare with upstream
./scripts/list_all_customizations.sh upstream/main
```

## 🐛 Troubleshooting

### Script Can't Find Node

**Problem**: `infinite_health_check.sh` or `validate_token_config.sh` fail

**Solution**:
1. Verify node is running: `ps aux | grep infinited`
2. Verify ports: `netstat -an | grep -E '1317|8545|26657'`
3. Verify you're in the project root

### Code Validation Fails

**Problem**: `validate_customizations.sh` reports errors

**Solution**:
1. Verify changes are saved
2. Verify you're on the correct branch
3. Review the specific error message
4. See `CUSTOMIZATIONS.md` for reference

### Tests Fail

**Problem**: `make test-unit` or `make test-all` fail

**Solution**:
1. Verify no node processes are running that could interfere
2. Clean build: `rm -rf build/`
3. Recompile: `make install`
4. Run tests again

## 📚 More Information

- **[guides/QUICK_START.md](../QUICK_START.md)** - Quick start
- **[guides/development/BUILDING.md](../development/BUILDING.md)** - Compilation guide
- **[CUSTOMIZATIONS.md](../../CUSTOMIZATIONS.md)** - Customizations reference
