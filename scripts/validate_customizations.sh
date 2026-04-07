#!/bin/bash
#
# Copyright (c) 2025 Deep Thought Labs
# All rights reserved.
#
# This file is part of the Infinite Drive blockchain tooling.
#
# Purpose: Safety-net validation for Infinite Drive: chain identity, operational
#          scripts, and documented fork product code (Infinite Bank x/bank,
#          Hyperlane core+warp wiring). Also warns on go.mod/go.sum drift vs
#          upstream where git remote exists.
#          Use during merges and before merge PRs to catch accidental removal
#          of fork-specific implementations.
#
# Usage: ./scripts/validate_customizations.sh
#
# Exit codes:
#   0 - All validations passed
#   1 - One or more validations failed
#

set -e

FAILED=0

check() {
    local file="$1"
    local pattern="$2"
    local description="$3"
    
    if ! grep -q "$pattern" "$file" 2>/dev/null; then
        echo "❌ $description: $file"
        FAILED=1
        return 1
    fi
    return 0
}

check_absent() {
    local file="$1"
    local pattern="$2"
    local description="$3"
    
    if grep -q "$pattern" "$file" 2>/dev/null; then
        echo "❌ $description: $file (should NOT contain: $pattern)"
        FAILED=1
        return 1
    fi
    return 0
}

echo "🔍 Validating Infinite Drive customizations..."
echo "=============================================="
echo ""
echo "⚠️  Scope: chain identity + genesis/tooling + fork product modules (see docs/feature/)."
echo "   Upstream drift (go.mod/go.sum) is warned when upstream/main is available."
echo ""

# Token configuration
echo "Token configuration..."
check "x/vm/types/params.go" 'DefaultEVMDisplayDenom = "Improbability"' "Token display denom"
check "x/vm/types/params.go" 'DefaultEVMDenom = "drop"' "Token base denom"
check "x/vm/types/params.go" "DefaultEVMChainID uint64 = 421018" "EVM Chain ID"

# Genesis state customization (ensures all modules use "drop" instead of default "stake")
echo "Genesis state customization..."
check "infinited/genesis.go" "NewMintGenesisState" "Mint genesis state function"
check "infinited/genesis.go" "NewStakingGenesisState" "Staking genesis state function"
check "infinited/genesis.go" "NewGovGenesisState" "Governance genesis state function"
check "infinited/genesis.go" 'testconstants.ExampleAttoDenom' "Genesis functions use ExampleAttoDenom (drop)"
check "infinited/app.go" "NewStakingGenesisState" "DefaultGenesis applies staking customization"
check "infinited/app.go" "NewGovGenesisState" "DefaultGenesis applies governance customization"

# Constants
echo "Constants..."
check "testutil/constants/constants.go" 'ExampleDisplayDenom = "Improbability"' "Display denom constant"
check "testutil/constants/constants.go" 'ExampleAttoDenom = "drop"' "Base denom constant"
check "testutil/constants/constants.go" "421018" "Chain ID in constants"

# Bech32 prefixes
echo "Bech32 prefixes..."
check "infinited/config/bech32.go" 'Bech32Prefix = "infinite"' "Bech32 prefix"

# Fork product extensions (canonical docs: docs/feature/infinite-bank/, docs/feature/hyperlane/)
echo "Fork product — Infinite Bank (github.com/cosmos/evm/x/bank)..."
check "x/bank/types/keys.go" 'ModuleName = "infinitebank"' "EVM x/bank extension module name"
check "infinited/app.go" '"github.com/cosmos/evm/x/bank"' "app imports EVM x/bank extension"
check "infinited/app.go" 'evmbanktypes.ModuleName' "app wires EVM x/bank module name (ordering)"
check "proto/cosmos/evm/bank/v1/tx.proto" 'MsgSetDenomMetadata' "bank extension Msg proto"

echo "Fork product — Hyperlane (hyperlane-cosmos)..."
check "infinited/go.mod" 'github.com/bcp-innovations/hyperlane-cosmos' "Hyperlane dependency in infinited/go.mod"
check "infinited/app.go" 'hyperlanecore.NewAppModule' "Hyperlane core AppModule registered"
check "infinited/app.go" 'hyperlanewarp.NewAppModule' "Hyperlane warp AppModule registered"
check "infinited/app.go" 'app.HyperlaneKeeper' "Hyperlane keeper field on App"
check "infinited/upgrades.go" 'hyperlanetypes.ModuleName' "upgrade plan includes Hyperlane store key"
check "infinited/upgrades.go" 'warptypes.ModuleName' "upgrade plan includes Warp store key"

# ⚠️ CRITICAL: Verify upstream compliance (package paths)
echo "⚠️  Upstream Compliance - Package Paths..."
if grep -r "deep-thought-labs/infinite" --include="*.go" --include="*.mod" . 2>/dev/null | grep -v "validate_customizations.sh" | grep -v ".git"; then
    echo "❌ Found incorrect package paths (should use github.com/cosmos/evm)"
    FAILED=1
else
    echo "✅ No incorrect package paths found"
fi

# Verify module paths are correct
echo "Module paths..."
check "go.mod" "^module github.com/cosmos/evm$" "Root module path (must be upstream)"
check "infinited/go.mod" "^module github.com/cosmos/evm/infinited$" "Submodule path (correct)"

# Rebranding - Binary names
echo "Rebranding - Binary names..."
check "Makefile" "test-infinited" "Makefile target"
check "Makefile" "infinited" "Binary name in Makefile"

# Copyright
echo "Copyright..."
check "NOTICE" "Deep Thought Labs" "Copyright in NOTICE"

# Genesis customization script (REQUIRED for proper genesis setup)
echo "Genesis customization script..."
check "scripts/customize_genesis.sh" "Deep Thought Labs" "Genesis customization script header"
check "scripts/customize_genesis.sh" "customize_genesis.sh" "Script file exists"
check "scripts/customize_genesis.sh" "Error.*--network flag is required" "Script requires --network flag"
check "scripts/customize_genesis.sh" "mainnet|testnet|creative" "Script supports all three networks"
check "scripts/customize_genesis.sh" "configure_staking_module" "Script configures staking module"
check "scripts/customize_genesis.sh" "configure_mint_module" "Script configures mint module"
check "scripts/customize_genesis.sh" "configure_governance_module" "Script configures governance module"
check "scripts/customize_genesis.sh" "configure_slashing_module" "Script configures slashing module"
check "scripts/customize_genesis.sh" "configure_fee_market_module" "Script configures fee market module"
check "scripts/customize_genesis.sh" "configure_distribution_module" "Script configures distribution module"
check "scripts/customize_genesis.sh" "load_config_file" "Script loads configuration from JSON files"
check "scripts/customize_genesis.sh" "genesis-configs" "Script references genesis-configs directory"
check "scripts/customize_genesis.sh" "configure_cosmos_chain_id" "Script configures Cosmos Chain ID"
check "scripts/customize_genesis.sh" "COSMOS_CHAIN_ID" "Script uses COSMOS_CHAIN_ID variable"

# Genesis configuration files (REQUIRED for script to work)
echo "Genesis configuration files..."
check "scripts/genesis-configs/mainnet.json" "mainnet" "Mainnet configuration file exists"
check "scripts/genesis-configs/mainnet.json" "base_denom" "Mainnet config contains base_denom"
check "scripts/genesis-configs/mainnet.json" "\"cosmos\"" "Mainnet config contains cosmos section"
check "scripts/genesis-configs/mainnet.json" "infinite_421018-1" "Mainnet config contains correct Cosmos Chain ID"
check "scripts/genesis-configs/testnet.json" "testnet" "Testnet configuration file exists"
check "scripts/genesis-configs/testnet.json" "base_denom" "Testnet config contains base_denom"
check "scripts/genesis-configs/testnet.json" "\"cosmos\"" "Testnet config contains cosmos section"
check "scripts/genesis-configs/testnet.json" "infinite_421018001-1" "Testnet config contains correct Cosmos Chain ID"
check "scripts/genesis-configs/creative.json" "creative" "Creative configuration file exists"
check "scripts/genesis-configs/creative.json" "base_denom" "Creative config contains base_denom"
check "scripts/genesis-configs/creative.json" "\"cosmos\"" "Creative config contains cosmos section"
check "scripts/genesis-configs/creative.json" "infinite_421018002-1" "Creative config contains correct Cosmos Chain ID"

# ModuleAccounts setup script
echo "ModuleAccounts setup script..."
check "scripts/setup_module_accounts.sh" "Deep Thought Labs" "ModuleAccounts setup script header"
check "scripts/setup_module_accounts.sh" "setup_module_accounts.sh" "Script file exists"
check "scripts/setup_module_accounts.sh" "Error.*--network flag is required" "Script requires --network flag"
check "scripts/setup_module_accounts.sh" "mainnet|testnet|creative" "Script supports all three networks"
check "scripts/setup_module_accounts.sh" "genesis-configs.*-module-accounts.json" "Script references module accounts config files"
check "scripts/setup_module_accounts.sh" "convert_to_atomic" "Script converts tokens to atomic units"
check "scripts/setup_module_accounts.sh" "create_module_account" "Script has create_module_account function"
check "scripts/setup_module_accounts.sh" "ModuleAccount" "Script creates ModuleAccounts"

# ModuleAccounts configuration files (REQUIRED for ModuleAccounts script to work)
echo "ModuleAccounts configuration files..."
check "scripts/genesis-configs/mainnet-module-accounts.json" "name" "Mainnet module accounts config exists"
check "scripts/genesis-configs/mainnet-module-accounts.json" "amount_tokens" "Mainnet module accounts config contains amount_tokens"
check "scripts/genesis-configs/testnet-module-accounts.json" "name" "Testnet module accounts config exists"
check "scripts/genesis-configs/testnet-module-accounts.json" "amount_tokens" "Testnet module accounts config contains amount_tokens"
check "scripts/genesis-configs/creative-module-accounts.json" "name" "Creative module accounts config exists"
check "scripts/genesis-configs/creative-module-accounts.json" "amount_tokens" "Creative module accounts config contains amount_tokens"

# Added files - Critical documentation
echo "Added files - Documentation..."
check "assets/pre-mainet-genesis.json" "Improbability" "Genesis template"

# Added files - Scripts
echo "Added files - Scripts..."
check "scripts/validate_customizations.sh" "validate_customizations" "Validation script"
check "scripts/infinite_health_check.sh" "infinite_health_check" "Health check script"
check "local_node.sh" "infinite_421018-1" "Local node script"

# Build configuration
echo "Build configuration..."
check ".goreleaser.yml" "infinite" "GoReleaser config"
check "Makefile" "infinited" "Makefile binary name"

# Optional: compare go.mod/go.sum to upstream/main (informational; fork graph often legitimately differs)
echo ""
echo "ℹ️  Upstream comparison (go.mod / go.sum vs upstream/main)..."
if command -v git >/dev/null 2>&1; then
    if git show-ref --verify --quiet "refs/remotes/upstream/main" 2>/dev/null; then
        # Check if go.mod differs from upstream (excluding module name and local replace)
        DEPS_NOTICE=0
        GO_MOD_DIFF=$(git diff upstream/main go.mod 2>/dev/null | grep -v "^module" | grep -v "^+++" | grep -v "^---" | grep -v "^@" | grep -v "^replace.*github.com/cosmos/evm => ./" | grep -v "^$" || true)
        if [ -n "$GO_MOD_DIFF" ]; then
            echo "⚠️  Notice: go.mod is not identical to upstream (after ignoring module line and evm replace)."
            echo "   This is often expected: fork-only deps (e.g. infinited/Hyperlane), go mod tidy, or pruned indirects."
            echo "   Spot-check merges: git diff upstream/main go.mod | head"
            DEPS_NOTICE=1
        else
            echo "✅ go.mod aligns with upstream for this coarse check (module + replace filtered)"
        fi
        
        # Check go.sum
        GO_SUM_DIFF=$(git diff upstream/main go.sum 2>/dev/null | head -20 || true)
        if [ -n "$GO_SUM_DIFF" ]; then
            echo "⚠️  Notice: go.sum differs from upstream."
            echo "   Normal when go.mod differs or after tidy; spot-check: git diff upstream/main go.sum | head"
            DEPS_NOTICE=1
        else
            echo "✅ go.sum matches upstream for this check"
        fi
        if [ "$DEPS_NOTICE" -eq 1 ]; then
            echo "   Tip: use '| head' on those diffs for a short preview, or run the same command without '| head' for the full output."
        fi
    else
        echo "⚠️  Warning: upstream/main not found. Cannot verify go.mod/go.sum compliance"
        echo "   Run: git fetch upstream (remote must point to https://github.com/cosmos/evm.git — docs/fork-maintenance/REFERENCE.md#remoto-git-upstream)"
    fi
else
    echo "⚠️  Warning: git not found. Cannot verify go.mod/go.sum compliance"
fi

echo ""
echo "=============================================="
if [ $FAILED -eq 0 ]; then
    echo "✅ Identity, tooling, and fork product wiring checks passed"
    echo "✅ Package paths OK (no deep-thought-labs/infinite in module paths)"
    exit 0
else
    echo "❌ Validation failed - review the errors above"
    echo ""
    echo "If you removed a fork feature on purpose, update docs/feature/ and this script."
    exit 1
fi

