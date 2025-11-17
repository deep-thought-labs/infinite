# Useful Scripts Guide - Infinite Drive

Complete guide of all scripts developed by Deep Thought Labs for Infinite Drive, when to use them, and what they do.

## 📋 Table of Contents

- [Identifying Deep Thought Labs Scripts](#identifying-deep-thought-labs-scripts)
- [Validation and Verification Scripts](#validation-and-verification-scripts)
- [Development Scripts](#development-scripts)
- [Testing Scripts](#testing-scripts)
- [When to Use Each Script](#when-to-use-each-script)

## 🔍 Identifying Deep Thought Labs Scripts

**All scripts developed by Deep Thought Labs** have this header:

```bash
#!/bin/bash
#
# Copyright (c) 2025 Deep Thought Labs
# All rights reserved.
#
# This file is part of the Infinite Drive blockchain tooling.
```

**To identify Deep Thought Labs scripts**:
```bash
# Find all Deep Thought Labs scripts
grep -l "Deep Thought Labs" scripts/*.sh
```

---

## ✅ Validation and Verification Scripts

### 1. `check_build_prerequisites.sh`

**Purpose**: Verify that you have all prerequisites installed to compile Infinite Drive.

**What it verifies**:
- ✅ Docker installed and running
- ✅ Go installed (correct version according to go.mod)
- ✅ Make installed
- ✅ Git installed
- ✅ Available disk space
- ✅ Docker permissions (Linux)

**When to use**:
- **Before compiling for the first time**
- When you have compilation errors
- To verify your environment is ready

**Usage**:
```bash
./scripts/check_build_prerequisites.sh
```

**Expected output**:
```
🔍 Checking prerequisites for Infinite Drive builds...

Docker installation: ✅ Installed (version 24.x.x)
Docker running: ✅ Running
Go installation: ✅ Installed (version go1.25.0)
Go version matches go.mod (1.25.0): ✅ Correct version
Make installation: ✅ Installed (version 4.x)
Git installation: ✅ Installed (version 2.x)

✅ All critical prerequisites are met!
```

**More information**: See [guides/development/BUILDING.md](BUILDING.md)

---

### 2. `validate_customizations.sh`

**Purpose**: Validate that Infinite Drive customizations are correctly implemented in the code.

**What it validates**:
- ✅ Token configuration (denoms, chain ID)
- ✅ Custom genesis functions
- ✅ Bech32 prefixes
- ✅ Upstream compliance (go.mod, package paths)

**When to use**:
- **After making code changes**
- **Before committing**
- **During merges with upstream**
- To verify customizations weren't lost

**Usage**:
```bash
./scripts/validate_customizations.sh
```

**Requirements**: Only needs code access (doesn't require running node)

**More information**: See [guides/testing/VALIDATION.md](../testing/VALIDATION.md)

---

### 3. `validate_token_config.sh`

**Purpose**: Validate that the Improbability (42) token configuration is correct in the running node.

**What it validates**:
- ✅ Token metadata (name, symbol, URI)
- ✅ Denominations (base: "drop", display: "Improbability")
- ✅ Correct Chain ID (421018)
- ✅ Configuration in genesis
- ✅ Configuration in running node (REST API)

**When to use**:
- **After starting a node**
- **After token configuration changes**
- **After updating genesis**
- To verify changes were applied correctly

**Usage**:
```bash
# Node must be running
./scripts/validate_token_config.sh
```

**Requirements**: Running node, `jq` installed, `curl` installed

**More information**: See [guides/testing/VALIDATION.md](../testing/VALIDATION.md)

---

### 4. `infinite_health_check.sh`

**Purpose**: Verify that the node is functioning correctly and all services are available.

**What it validates**:
- ✅ JSON-RPC connectivity (port 8545)
- ✅ REST API connectivity (port 1317)
- ✅ Tendermint connectivity (port 26657)
- ✅ Block production
- ✅ Chain synchronization
- ✅ System status

**When to use**:
- **After starting a node**
- **To verify the node is still functioning**
- **Before important operations**
- For debugging connectivity issues

**Usage**:
```bash
# Node must be running
./scripts/infinite_health_check.sh
```

**Requirements**: Running node, `jq` installed, `curl` installed

**More information**: See [guides/testing/VALIDATION.md](../testing/VALIDATION.md)

---

## 🔧 Development Scripts

### 5. `list_all_customizations.sh`

**Purpose**: List all differences between your repository and the upstream repository.

**What it does**:
- Compares added files (A)
- Compares modified files (M)
- Compares deleted files (D)
- Shows change statistics

**When to use**:
- **During merges with upstream**
- **To document customizations**
- **To verify what has been modified**
- To generate change reports

**Usage**:
```bash
# Compare with upstream/main (default)
./scripts/list_all_customizations.sh

# Compare with another branch
./scripts/list_all_customizations.sh upstream/main

# Compare with local branch
./scripts/list_all_customizations.sh main
```

**Requirements**: Git configured, upstream remote configured

**Output**: List of added, modified, and deleted files

---

### 6. `audit_command_name.sh`

**Purpose**: Search for all references to the command name that need to be changed (for rebranding).

**What it searches for**:
- References to `evmd` in Cobra commands
- Examples with the command name
- Build messages in Makefile
- Home directory that uses the command name

**When to use**:
- **During rebranding process**
- **For command name change audit**
- To identify all references that need changing

**Usage**:
```bash
./scripts/audit_command_name.sh
```

**Output**: Creates `audit_report_YYYYMMDD_HHMMSS.txt` with all findings

---

### 7. `verify_command_name.sh`

**Purpose**: Verify that command name changes work correctly.

**What it verifies**:
- ✅ `infinited --help` shows `infinited` as command
- ✅ `evmd` does NOT appear as executable command
- ✅ `infinited version` works
- ✅ Examples use `infinited`

**When to use**:
- **AFTER making command name changes**
- To verify rebranding was successful

**Usage**:
```bash
# First compile
make install

# Then verify
./scripts/verify_command_name.sh
```

**Requirements**: Compiled and installed binary

---

### 8. `test_outputs_before.sh`

**Purpose**: Capture current outputs BEFORE making changes to compare later.

**What it captures**:
- `--help` of current command
- `version`
- `--help` of subcommands (keys, query, tx, testnet)

**When to use**:
- **BEFORE making any code changes**
- To have a reference point for comparison

**Usage**:
```bash
./scripts/test_outputs_before.sh
```

**Output**: Creates directory `outputs_before_YYYYMMDD_HHMMSS/` with all outputs

---

### 9. `compare_outputs.sh`

**Purpose**: Compare outputs before and after changes.

**What it compares**:
- Help before and after
- Version before and after
- Searches if any `evmd` remains in new outputs
- Verifies that `infinited` appears in new outputs

**When to use**:
- **AFTER making changes and compiling**
- To verify changes work correctly

**Usage**:
```bash
# Requirement: You must have run test_outputs_before.sh first
./scripts/compare_outputs.sh
```

**Requirements**: Must exist `outputs_before_*` directory (created by `test_outputs_before.sh`)

---

## Genesis Customization Script

### `scripts/customize_genesis.sh`

**Purpose**: Apply all Infinite Drive personalizations to a generated `genesis.json` file for mainnet, testnet, or creative networks.

**What it does**:
- Sets all module denominations to network-specific denom (drop/tdrop/cdrop)
- Adds complete token metadata for network-specific token (Improbability/TestImprobability/CreativeImprobability)
- Enables all EVM static precompiles
- Configures ERC20 native token pair
- Configures complete Staking Module (unbonding_time, max_validators, historical_entries, etc.)
- Configures complete Mint Module (inflation rates, goal_bonded, blocks_per_year)
- Configures complete Governance Module (voting periods, thresholds, min_deposits)
- Configures complete Slashing Module (penalties, windows, jail duration)
- Configures complete Fee Market Module (base_fee, no_base_fee, multipliers)
- Configures complete Distribution Module (community_tax, proposer rewards)
- Configures consensus parameters (max_gas, evidence windows)
- Creates automatic backup before modifications

**When to use**:
- **Network genesis creation**: When preparing a genesis file for mainnet, testnet, or creative (one-time setup process)
- As part of the network deployment pipeline
- When you need to ensure all Infinite Drive customizations are applied to a genesis file

**When NOT to use**:
- **Regular local development**: Use `local_node.sh` instead, which handles genesis customization automatically
- For quick local testing: `local_node.sh` is the recommended approach

**Usage**:
```bash
./scripts/customize_genesis.sh <genesis_file_path> --network <mainnet|testnet|creative>
```

**Example**:
```bash
# After initializing a node
infinited init my-moniker --chain-id infinite_421018-1

# Customize the generated genesis for mainnet
./scripts/customize_genesis.sh ~/.infinited/config/genesis.json --network mainnet

# Or for testnet
./scripts/customize_genesis.sh ~/.infinited/config/genesis.json --network testnet

# Or for creative network
./scripts/customize_genesis.sh ~/.infinited/config/genesis.json --network creative

# Validate the customized genesis
infinited genesis validate-genesis
```

**Expected output** (mainnet example):
```
ℹ Customizing Genesis file: ~/.infinited/config/genesis.json
ℹ Network: mainnet
ℹ Configuring for network: mainnet
ℹ Base denom: drop
ℹ Display denom: Improbability
ℹ Symbol: 42
ℹ EVM Chain ID: 421018
ℹ Backup created: ~/.infinited/config/genesis.json.backup.20251116_170222
ℹ Customizing module denominations to 'drop'...
ℹ Staking bond_denom → drop
ℹ Mint mint_denom → drop
ℹ Governance min_deposit → drop
ℹ Governance expedited_min_deposit → drop
ℹ EVM evm_denom → drop
ℹ Adding token metadata for Improbability (42) token...
ℹ Token metadata added
ℹ Configuring EVM static precompiles...
ℹ EVM static precompiles enabled
ℹ Configuring ERC20 native token pair...
ℹ ERC20 native precompiles configured
ℹ ERC20 native token pair configured
ℹ Configuring Staking Module parameters...
ℹ Configuring Mint Module parameters (inflation)...
ℹ Configuring Governance Module parameters...
ℹ Configuring Slashing Module parameters...
ℹ Configuring Fee Market Module parameters...
ℹ Configuring Distribution Module parameters (fee distribution)...
ℹ Configuring consensus parameters...
ℹ Genesis file customized successfully for mainnet!
```

**Configuration Files**:
The script reads all network-specific values from JSON configuration files located in `scripts/genesis-configs/`:
- `mainnet.json` - Production network configuration
- `testnet.json` - Testing network configuration (similar to mainnet)
- `creative.json` - Experimental playground network configuration (minimal fees, no inflation)

These files contain all parameters for each network, making it easy to modify values without editing the script code. The structure is consistent across all three files, with different values for each network.

**Prerequisites**:
- `jq` must be installed
- Valid `genesis.json` file must exist
- Configuration file for the specified network must exist in `scripts/genesis-configs/`

**Notes**:
- The script creates a timestamped backup automatically
- All modifications are applied safely with error handling
- The script validates the genesis file before making changes
- This script extracts the genesis customization logic from `local_node.sh` into a standalone tool

---

## 🧪 Testing Scripts

### 10. Compatibility Scripts

These scripts test compatibility with different EVM tools:

- `tests_compatibility_foundry.sh` - Tests with Foundry
- `tests_compatibility_hardhat.sh` - Tests with Hardhat
- `tests_compatibility_web3js.sh` - Tests with web3.js
- `tests_compatibility_viem.sh` - Tests with Viem
- `tests_compatibility_foundry_uniswap_v3.sh` - Specific Uniswap V3 tests

**When to use**: To verify EVM compatibility with different tools

**Usage**: See specific documentation for each script

---

## 📊 When to Use Each Script

### Workflow: First Time / Verify Environment

```bash
# 1. Verify prerequisites
./scripts/check_build_prerequisites.sh

# 2. If everything is OK, compile
make install
```

### Workflow: Active Development

```bash
# 1. Make code changes

# 2. Validate customizations
./scripts/validate_customizations.sh

# 3. Compile
make install

# 4. If you have a running node, validate
./scripts/infinite_health_check.sh
./scripts/validate_token_config.sh
```

### Workflow: Before Commit

```bash
# 1. Validate code
./scripts/validate_customizations.sh

# 2. Compile
make install

# 3. Tests
make test-unit
```

### Workflow: During Merge with Upstream

```bash
# 1. See what changed
./scripts/list_all_customizations.sh upstream/main

# 2. Validate that customizations were maintained
./scripts/validate_customizations.sh

# 3. Compile and test
make install
make test-all
```

### Workflow: Verify Running Node

```bash
# 1. Complete health check
./scripts/infinite_health_check.sh

# 2. Validate token configuration
./scripts/validate_token_config.sh
```

---

## 📚 Quick Reference of Scripts

| Script | Purpose | Requires Node | Time |
|--------|---------|---------------|------|
| `check_build_prerequisites.sh` | Verify prerequisites | ❌ No | <1 min |
| `validate_customizations.sh` | Validate code | ❌ No | <1 min |
| `validate_token_config.sh` | Validate token | ✅ Yes | <1 min |
| `infinite_health_check.sh` | Node health check | ✅ Yes | <1 min |
| `list_all_customizations.sh` | List changes | ❌ No | <1 min |
| `audit_command_name.sh` | Rebranding audit | ❌ No | <1 min |
| `verify_command_name.sh` | Verify rebranding | ❌ No | <1 min |
| `test_outputs_before.sh` | Capture state | ❌ No | <1 min |
| `compare_outputs.sh` | Compare changes | ❌ No | <1 min |

---

## 🔍 Identify Deep Thought Labs Scripts

**Command to list all Deep Thought Labs scripts**:

```bash
# Find scripts with Deep Thought Labs copyright
grep -l "Deep Thought Labs" scripts/*.sh

# Or see header of each script
head -10 scripts/*.sh | grep -B 5 "Deep Thought Labs"
```

**Identified Deep Thought Labs scripts**:
- `check_build_prerequisites.sh`
- `validate_customizations.sh`
- `validate_token_config.sh`
- `infinite_health_check.sh`
- `list_all_customizations.sh`
- `audit_command_name.sh`
- `verify_command_name.sh`
- `test_outputs_before.sh`
- `compare_outputs.sh`

---

## 📚 More Information

- **[guides/testing/VALIDATION.md](../testing/VALIDATION.md)** - Complete validation guide
- **[guides/development/BUILDING.md](BUILDING.md)** - Compilation guide
- **[CUSTOMIZATIONS.md](../../CUSTOMIZATIONS.md)** - Customizations reference

---

## 🔗 Quick Links

| Need | Script | When |
|------|--------|------|
| Verify prerequisites | `check_build_prerequisites.sh` | Before compiling |
| Validate code | `validate_customizations.sh` | After changes |
| Validate node | `infinite_health_check.sh` | Node running |
| See changes | `list_all_customizations.sh` | During merges |
