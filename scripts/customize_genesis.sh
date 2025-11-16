#!/bin/bash
#
# Copyright (c) 2025 Deep Thought Labs
# All rights reserved.
#
# This file is part of the Infinite Drive blockchain tooling.
#
# Purpose: Customize a generated genesis.json file with all Infinite Drive
#          personalizations (denominations, token metadata, EVM config, etc.)
#
# Usage: ./scripts/customize_genesis.sh <genesis_file_path>
#
# Example:
#   ./scripts/customize_genesis.sh ~/.infinited/config/genesis.json
#
# Exit codes:
#   0 - Success
#   1 - Error (invalid arguments, file not found, jq not available, etc.)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Infinite Drive constants
BASE_DENOM="drop"
DISPLAY_DENOM="Improbability"
SYMBOL="42"
TOKEN_NAME="Improbability"
TOKEN_DESCRIPTION="Improbability Token — Project 42: Sovereign, Perpetual, DAO-Governed"
TOKEN_URI="https://assets.infinitedrive.xyz/tokens/42/icon.png"
EVM_CHAIN_ID=421018

# Print colored messages
print_info() {
    echo -e "${GREEN}ℹ${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    if ! command -v jq &> /dev/null; then
        print_error "jq is required but not installed. Please install jq first."
        exit 1
    fi
}

# Validate genesis file
validate_genesis_file() {
    local genesis_file="$1"
    
    if [[ ! -f "$genesis_file" ]]; then
        print_error "Genesis file not found: $genesis_file"
        exit 1
    fi
    
    if ! jq empty "$genesis_file" 2>/dev/null; then
        print_error "Invalid JSON file: $genesis_file"
        exit 1
    fi
    
    if ! jq -e '.app_state' "$genesis_file" >/dev/null 2>&1; then
        print_error "Invalid genesis file: missing app_state"
        exit 1
    fi
}

# Apply jq modification safely
apply_jq_modification() {
    local genesis_file="$1"
    local jq_expr="$2"
    local description="$3"
    
    local tmp_file
    tmp_file=$(mktemp)
    
    if jq "$jq_expr" "$genesis_file" > "$tmp_file" 2>/dev/null; then
        mv "$tmp_file" "$genesis_file"
        print_info "$description"
        return 0
    else
        rm -f "$tmp_file"
        print_error "Failed to apply: $description"
        return 1
    fi
}

# Customize module denominations
customize_denominations() {
    local genesis_file="$1"
    
    print_info "Customizing module denominations to '$BASE_DENOM'..."
    
    # Staking module
    apply_jq_modification "$genesis_file" \
        '.app_state["staking"]["params"]["bond_denom"]="drop"' \
        "Staking bond_denom → drop"
    
    # Mint module
    apply_jq_modification "$genesis_file" \
        '.app_state["mint"]["params"]["mint_denom"]="drop"' \
        "Mint mint_denom → drop"
    
    # Governance module - min_deposit
    apply_jq_modification "$genesis_file" \
        '.app_state["gov"]["params"]["min_deposit"][0]["denom"]="drop"' \
        "Governance min_deposit → drop"
    
    # Governance module - expedited_min_deposit
    apply_jq_modification "$genesis_file" \
        '.app_state["gov"]["params"]["expedited_min_deposit"][0]["denom"]="drop"' \
        "Governance expedited_min_deposit → drop"
    
    # EVM module
    apply_jq_modification "$genesis_file" \
        '.app_state["evm"]["params"]["evm_denom"]="drop"' \
        "EVM evm_denom → drop"
}

# Add token metadata
add_token_metadata() {
    local genesis_file="$1"
    
    print_info "Adding token metadata for Improbability (42) token..."
    
    local metadata_json="{
        \"description\": \"$TOKEN_DESCRIPTION\",
        \"denom_units\": [
            {
                \"denom\": \"$BASE_DENOM\",
                \"exponent\": 0,
                \"aliases\": []
            },
            {
                \"denom\": \"$DISPLAY_DENOM\",
                \"exponent\": 18,
                \"aliases\": [\"improbability\"]
            }
        ],
        \"base\": \"$BASE_DENOM\",
        \"display\": \"$DISPLAY_DENOM\",
        \"name\": \"$TOKEN_NAME\",
        \"symbol\": \"$SYMBOL\",
        \"uri\": \"$TOKEN_URI\",
        \"uri_hash\": \"\"
    }"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"bank\"][\"denom_metadata\"]=[$metadata_json]" \
        "Token metadata added"
}

# Configure EVM precompiles
configure_evm_precompiles() {
    local genesis_file="$1"
    
    print_info "Configuring EVM static precompiles..."
    
    local precompiles='[
        "0x0000000000000000000000000000000000000100",
        "0x0000000000000000000000000000000000000400",
        "0x0000000000000000000000000000000000000800",
        "0x0000000000000000000000000000000000000801",
        "0x0000000000000000000000000000000000000802",
        "0x0000000000000000000000000000000000000803",
        "0x0000000000000000000000000000000000000804",
        "0x0000000000000000000000000000000000000805",
        "0x0000000000000000000000000000000000000806",
        "0x0000000000000000000000000000000000000807"
    ]'
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"evm\"][\"params\"][\"active_static_precompiles\"]=$precompiles" \
        "EVM static precompiles enabled"
}

# Configure ERC20 native token pair
configure_erc20_native_pair() {
    local genesis_file="$1"
    
    print_info "Configuring ERC20 native token pair..."
    
    # Native precompiles
    apply_jq_modification "$genesis_file" \
        '.app_state["erc20"]["native_precompiles"]=["0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"]' \
        "ERC20 native precompiles configured"
    
    # Token pair
    local token_pair='{
        "contract_owner": 1,
        "erc20_address": "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
        "denom": "drop",
        "enabled": true
    }'
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"erc20\"][\"token_pairs\"]=[$token_pair]" \
        "ERC20 native token pair configured"
}

# Configure consensus parameters
configure_consensus_params() {
    local genesis_file="$1"
    
    print_info "Configuring consensus parameters..."
    
    apply_jq_modification "$genesis_file" \
        '.consensus.params.block.max_gas="10000000"' \
        "Consensus max_gas → 10000000"
}

# Main function
main() {
    local genesis_file="${1:-}"
    
    if [[ -z "$genesis_file" ]]; then
        print_error "Usage: $0 <genesis_file_path>"
        echo ""
        echo "Example:"
        echo "  $0 ~/.infinited/config/genesis.json"
        exit 1
    fi
    
    print_info "Customizing Genesis file: $genesis_file"
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Validate genesis file
    validate_genesis_file "$genesis_file"
    
    # Create backup
    local backup_file="${genesis_file}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$genesis_file" "$backup_file"
    print_info "Backup created: $backup_file"
    echo ""
    
    # Apply customizations
    customize_denominations "$genesis_file"
    add_token_metadata "$genesis_file"
    configure_evm_precompiles "$genesis_file"
    configure_erc20_native_pair "$genesis_file"
    configure_consensus_params "$genesis_file"
    
    echo ""
    print_info "Genesis file customized successfully!"
    print_info "Backup saved at: $backup_file"
    echo ""
    print_info "Next steps:"
    echo "  1. Validate the genesis file: infinited genesis validate-genesis"
    echo "  2. Review the changes if needed"
    echo "  3. Remove the backup file when satisfied: rm $backup_file"
}

# Run main function
main "$@"

