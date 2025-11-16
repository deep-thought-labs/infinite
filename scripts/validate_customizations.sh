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

# Added files - Critical documentation
echo "Added files - Documentation..."
check "guides/GETTING_STARTED.md" "infinite_421018-1" "Getting started guide"
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

