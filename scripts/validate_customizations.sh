#!/bin/bash
#
# Copyright (c) 2025 Deep Thought Labs
# All rights reserved.
#
# This file is part of the Infinite Drive blockchain tooling.
#
# Purpose: Quick validation script to verify all customizations are preserved.
#          Use this during merges to ensure no customizations are lost.
#
# Usage: ./scripts/validate_customizations.sh
#
# Exit codes:
#   0 - All customizations validated
#   1 - One or more customizations missing
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

echo "🔍 Validating Infinite Drive customizations..."
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

# Rebranding - Package paths
echo "Rebranding - Package paths..."
check "infinited/go.mod" "deep-thought-labs/infinite" "Package path in go.mod"

# Rebranding - Binary names
echo "Rebranding - Binary names..."
check "Makefile" "test-infinited" "Makefile target"
check "Makefile" "infinited" "Binary name in Makefile"

# Copyright
echo "Copyright..."
check "NOTICE" "Deep Thought Labs" "Copyright in NOTICE"

echo ""
if [ $FAILED -eq 0 ]; then
    echo "✅ All customizations validated"
    exit 0
else
    echo "❌ Some customizations are missing - review the errors above"
    exit 1
fi

