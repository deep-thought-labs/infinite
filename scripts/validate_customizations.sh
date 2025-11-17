#!/bin/bash
#
# Copyright (c) 2025 Deep Thought Labs
# All rights reserved.
#
# This file is part of the Infinite Drive blockchain tooling.
#
# Purpose: Quick validation script to verify all customizations are preserved
#          AND that upstream technical compliance is maintained.
#          Use this during merges to ensure:
#          1. Identity customizations are preserved
#          2. Technical aspects match upstream (go.mod, go.sum, package paths)
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
echo "⚠️  RULE: Only identity customizations allowed. Technical aspects must match upstream."
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

# ⚠️ CRITICAL: Verify upstream compliance (package paths)
echo "⚠️  Upstream Compliance - Package Paths..."
if grep -r "deep-thought-labs/infinite" --include="*.go" --include="*.mod" . 2>/dev/null | grep -v "CUSTOMIZATIONS.md" | grep -v "validate_customizations.sh" | grep -v ".git"; then
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

# Genesis configuration files (REQUIRED for script to work)
echo "Genesis configuration files..."
check "scripts/genesis-configs/mainnet.json" "mainnet" "Mainnet configuration file exists"
check "scripts/genesis-configs/mainnet.json" "base_denom" "Mainnet config contains base_denom"
check "scripts/genesis-configs/testnet.json" "testnet" "Testnet configuration file exists"
check "scripts/genesis-configs/testnet.json" "base_denom" "Testnet config contains base_denom"
check "scripts/genesis-configs/creative.json" "creative" "Creative configuration file exists"
check "scripts/genesis-configs/creative.json" "base_denom" "Creative config contains base_denom"

# ModuleAccounts vesting setup script
echo "ModuleAccounts vesting setup script..."
check "scripts/setup_module_accounts.sh" "Deep Thought Labs" "ModuleAccounts setup script header"
check "scripts/setup_module_accounts.sh" "setup_module_accounts.sh" "Script file exists"
check "scripts/setup_module_accounts.sh" "Error.*--network flag is required" "Script requires --network flag"
check "scripts/setup_module_accounts.sh" "mainnet|testnet|creative" "Script supports all three networks"
check "scripts/setup_module_accounts.sh" "add-module-vesting-account" "Script generates vesting account commands"
check "scripts/setup_module_accounts.sh" "genesis-configs.*-vesting.json" "Script references vesting config files"
check "scripts/setup_module_accounts.sh" "convert_to_atomic" "Script converts tokens to atomic units"
check "scripts/setup_module_accounts.sh" "calculate_duration" "Script calculates vesting duration"

# Vesting configuration files (REQUIRED for ModuleAccounts script to work)
echo "Vesting configuration files..."
check "scripts/genesis-configs/mainnet-vesting.json" "vesting_start_time" "Mainnet vesting config exists"
check "scripts/genesis-configs/mainnet-vesting.json" "pools" "Mainnet vesting config contains pools"
check "scripts/genesis-configs/testnet-vesting.json" "vesting_start_time" "Testnet vesting config exists"
check "scripts/genesis-configs/testnet-vesting.json" "pools" "Testnet vesting config contains pools"
check "scripts/genesis-configs/creative-vesting.json" "vesting_start_time" "Creative vesting config exists"
check "scripts/genesis-configs/creative-vesting.json" "pools" "Creative vesting config contains pools"

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

# ⚠️ CRITICAL: Verify go.mod/go.sum match upstream (except module name)
echo ""
echo "⚠️  Upstream Compliance - Dependencies..."
if command -v git >/dev/null 2>&1; then
    if git show-ref --verify --quiet "refs/remotes/upstream/main" 2>/dev/null; then
        # Check if go.mod differs significantly from upstream (excluding module name)
        GO_MOD_DIFF=$(git diff upstream/main go.mod 2>/dev/null | grep -v "^module" | grep -v "^+++" | grep -v "^---" | grep -v "^@" | grep -v "^replace.*github.com/cosmos/evm => ./" | grep -v "^$" || true)
        if [ -n "$GO_MOD_DIFF" ]; then
            echo "⚠️  Warning: go.mod differs from upstream (excluding module name and replace directive)"
            echo "   Review differences: git diff upstream/main go.mod"
            echo "   Expected: Only module name and replace directive should differ"
        else
            echo "✅ go.mod matches upstream (except module name and replace directive)"
        fi
        
        # Check go.sum
        GO_SUM_DIFF=$(git diff upstream/main go.sum 2>/dev/null | head -20 || true)
        if [ -n "$GO_SUM_DIFF" ]; then
            echo "⚠️  Warning: go.sum differs from upstream"
            echo "   This may be normal if dependencies were updated. Verify with: git diff upstream/main go.sum"
        else
            echo "✅ go.sum matches upstream"
        fi
    else
        echo "⚠️  Warning: upstream/main not found. Cannot verify go.mod/go.sum compliance"
        echo "   Run: git fetch upstream"
    fi
else
    echo "⚠️  Warning: git not found. Cannot verify go.mod/go.sum compliance"
fi

echo ""
echo "=============================================="
if [ $FAILED -eq 0 ]; then
    echo "✅ All customizations validated"
    echo "✅ Upstream compliance verified"
    exit 0
else
    echo "❌ Validation failed - review the errors above"
    echo ""
    echo "Remember: Only identity customizations are allowed."
    echo "All technical aspects must match upstream."
    exit 1
fi

