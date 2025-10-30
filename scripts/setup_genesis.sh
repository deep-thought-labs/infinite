#!/bin/bash
#
# Copyright (c) 2025 Deep Thought Labs
# All rights reserved.
#
# This file is part of the Infinite Drive blockchain tooling.
#
# Purpose: Generate and configure genesis files for Mainnet or Testnet
#          based on YAML configuration files.
#
# Usage: ./scripts/setup_genesis.sh [mainnet|testnet] [moniker] [output-dir]
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_DIR="$PROJECT_ROOT/config/genesis"

# Default values
NETWORK_TYPE="${1:-}"
MONIKER="${2:-}"
OUTPUT_DIR="${3:-}"

# Functions
print_error() {
    echo -e "${RED}ERROR:${NC} $1" >&2
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

usage() {
    cat << EOF
Usage: $0 [mainnet|testnet] <moniker> [output-dir]

Arguments:
  mainnet|testnet    Network type (required)
  moniker            Node moniker (required)
  output-dir         Output directory for genesis file (optional)
                     Default: ~/.infinited_<network>/

Examples:
  $0 mainnet my-node
  $0 testnet test-node ~/testnet-genesis
  $0 mainnet production-node ~/mainnet-genesis

Description:
  This script generates a complete genesis file for Infinite Drive.
  It reads configuration from config/genesis/<network>.yaml and applies
  all settings to the generated genesis.json file.

EOF
}

check_dependencies() {
    local missing=0
    
    if ! command -v infinited >/dev/null 2>&1 && ! command -v "$PROJECT_ROOT/build/infinited" >/dev/null 2>&1; then
        print_error "infinited binary not found. Please build it first with 'make build'"
        missing=1
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        print_error "jq is required but not installed. Install with: sudo apt install jq (or brew install jq)"
        missing=1
    fi
    
    if ! command -v yq >/dev/null 2>&1; then
        print_error "yq is required but not installed. Install with:"
        print_error "  macOS: brew install yq"
        print_error "  Linux: https://github.com/mikefarah/yq/releases"
        missing=1
    fi
    
    if [ $missing -eq 1 ]; then
        exit 1
    fi
}

get_binary_path() {
    if command -v infinited >/dev/null 2>&1; then
        echo "infinited"
    elif [ -f "$PROJECT_ROOT/build/infinited" ]; then
        echo "$PROJECT_ROOT/build/infinited"
    else
        print_error "infinited binary not found"
        exit 1
    fi
}

setup_genesis() {
    local network_type=$1
    local moniker=$2
    local output_dir=$3
    local config_file="$CONFIG_DIR/${network_type}.yaml"
    
    # Validate network type
    if [ "$network_type" != "mainnet" ] && [ "$network_type" != "testnet" ]; then
        print_error "Invalid network type: $network_type (must be 'mainnet' or 'testnet')"
        usage
        exit 1
    fi
    
    # Validate config file exists
    if [ ! -f "$config_file" ]; then
        print_error "Configuration file not found: $config_file"
        exit 1
    fi
    
    # Get binary path
    INFINITED=$(get_binary_path)
    
    # Set default output directory if not provided
    if [ -z "$output_dir" ]; then
        output_dir="$HOME/.infinited_${network_type}"
    fi
    
    # Clean up if directory exists
    if [ -d "$output_dir" ]; then
        print_warning "Directory $output_dir exists. Removing for fresh start..."
        rm -rf "$output_dir"
    fi
    
    print_info "Generating genesis for $network_type..."
    print_info "Moniker: $moniker"
    print_info "Output directory: $output_dir"
    
    # Extract configuration values
    local cosmos_chain_id=$(yq eval '.chain.cosmos_chain_id' "$config_file")
    local evm_chain_id=$(yq eval '.chain.evm_chain_id' "$config_file")
    local base_denom=$(yq eval '.denom.base' "$config_file")
    
    GENESIS_FILE="$output_dir/config/genesis.json"
    TMP_GENESIS="$output_dir/config/genesis.json.tmp"
    
    # Step 1: Initialize chain
    print_info "Initializing chain..."
    "$INFINITED" init "$moniker" --chain-id "$cosmos_chain_id" --home "$output_dir"
    
    # Ensure genesis file exists
    if [ ! -f "$GENESIS_FILE" ]; then
        print_error "Genesis file not found after init: $GENESIS_FILE"
        exit 1
    fi
    
    # Step 2: Configure denominations
    print_info "Configuring denominations..."
    jq --arg denom "$base_denom" \
       '.app_state.staking.params.bond_denom = $denom |
        .app_state.evm.params.evm_denom = $denom |
        .app_state.mint.params.mint_denom = $denom' \
       "$GENESIS_FILE" > "$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS_FILE"
    
    # Step 3: Configure EVM chain ID
    print_info "Configuring EVM chain ID..."
    jq --arg chain_id "$evm_chain_id" \
       '.app_state.evm.params.chain_config.chain_id = $chain_id' \
       "$GENESIS_FILE" > "$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS_FILE"
    
    # Step 4: Configure token metadata
    print_info "Configuring token metadata..."
    local token_name=$(yq eval '.token_metadata.name' "$config_file")
    local token_symbol=$(yq eval '.token_metadata.symbol' "$config_file")
    local token_desc=$(yq eval '.token_metadata.description' "$config_file")
    local token_uri=$(yq eval '.token_metadata.uri' "$config_file")
    local token_uri_hash=$(yq eval '.token_metadata.uri_hash' "$config_file")
    
    # Build denom_units JSON
    local base_aliases=$(yq eval -o json '.denom.aliases.base' "$config_file")
    local display_aliases=$(yq eval -o json '.denom.aliases.display' "$config_file")
    local display_denom=$(yq eval '.denom.display' "$config_file")
    
    # Build base unit JSON
    local base_unit=$(jq -n \
      --arg denom "$base_denom" \
      --argjson aliases "$base_aliases" \
      '{denom: $denom, exponent: 0, aliases: $aliases}')
    
    # Build display unit JSON
    local display_unit=$(jq -n \
      --arg denom "$display_denom" \
      --argjson aliases "$display_aliases" \
      '{denom: $denom, exponent: 18, aliases: $aliases}')
    
    jq --argjson base_unit "$base_unit" \
       --argjson display_unit "$display_unit" \
       --arg name "$token_name" \
       --arg symbol "$token_symbol" \
       --arg desc "$token_desc" \
       --arg uri "$token_uri" \
       --arg uri_hash "$token_uri_hash" \
       --arg base "$base_denom" \
       --arg display "$display_denom" \
       '.app_state.bank.denom_metadata = [{
         name: $name,
         symbol: $symbol,
         description: $desc,
         denom_units: [$base_unit, $display_unit],
         base: $base,
         display: $display,
         uri: $uri,
         uri_hash: $uri_hash
       }]' \
       "$GENESIS_FILE" > "$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS_FILE"
    
    # Step 5: Configure governance parameters
    print_info "Configuring governance parameters..."
    local min_deposit_denom=$(yq eval '.governance.min_deposit.denom' "$config_file")
    local min_deposit_amount=$(yq eval '.governance.min_deposit.amount' "$config_file")
    local max_deposit_period=$(yq eval '.governance.max_deposit_period' "$config_file")
    local voting_period=$(yq eval '.governance.voting_period' "$config_file")
    local quorum=$(yq eval '.governance.quorum' "$config_file")
    local threshold=$(yq eval '.governance.threshold' "$config_file")
    local veto_threshold=$(yq eval '.governance.veto_threshold' "$config_file")
    local expedited_denom=$(yq eval '.governance.expedited_min_deposit.denom' "$config_file")
    local expedited_amount=$(yq eval '.governance.expedited_min_deposit.amount' "$config_file")
    local expedited_period=$(yq eval '.governance.expedited_voting_period' "$config_file")
    
    # Update governance params
    jq --arg denom "$min_deposit_denom" \
       --arg amount "$min_deposit_amount" \
       --arg period "$max_deposit_period" \
       --arg vote_period "$voting_period" \
       --arg quorum_val "$quorum" \
       --arg threshold_val "$threshold" \
       --arg veto_val "$veto_threshold" \
       --arg exp_denom "$expedited_denom" \
       --arg exp_amount "$expedited_amount" \
       --arg expedited_per "$expedited_period" \
       '.app_state.gov.params.min_deposit = [{
         denom: $denom,
         amount: $amount
       }] |
       .app_state.gov.params.max_deposit_period = $period |
       .app_state.gov.params.voting_period = $vote_period |
       .app_state.gov.params.quorum = $quorum_val |
       .app_state.gov.params.threshold = $threshold_val |
       .app_state.gov.params.veto_threshold = $veto_val |
       .app_state.gov.params.expedited_min_deposit = [{
         denom: $exp_denom,
         amount: $exp_amount
       }] |
       .app_state.gov.params.expedited_voting_period = $expedited_per' \
       "$GENESIS_FILE" > "$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS_FILE"
    
    # Step 6: Configure staking parameters
    print_info "Configuring staking parameters..."
    local max_validators=$(yq eval '.staking.max_validators' "$config_file")
    local unbonding_time=$(yq eval '.staking.unbonding_time' "$config_file")
    
    jq --arg denom "$base_denom" \
       --arg max_val "$max_validators" \
       --arg unbond "$unbonding_time" \
       '.app_state.staking.params.bond_denom = $denom |
        .app_state.staking.params.max_validators = ($max_val | tonumber) |
        .app_state.staking.params.unbonding_time = $unbond' \
       "$GENESIS_FILE" > "$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS_FILE"
    
    # Step 7: Configure slashing parameters
    print_info "Configuring slashing parameters..."
    local signed_blocks_window=$(yq eval '.slashing.signed_blocks_window' "$config_file")
    local min_signed_per_window=$(yq eval '.slashing.min_signed_per_window' "$config_file")
    local downtime_jail=$(yq eval '.slashing.downtime_jail_duration' "$config_file")
    local slash_double=$(yq eval '.slashing.slash_fraction_double_sign' "$config_file")
    local slash_downtime=$(yq eval '.slashing.slash_fraction_downtime' "$config_file")
    
    jq --arg window "$signed_blocks_window" \
       --arg min_signed "$min_signed_per_window" \
       --arg jail "$downtime_jail" \
       --arg double_sign "$slash_double" \
       --arg downtime "$slash_downtime" \
       '.app_state.slashing.params.signed_blocks_window = ($window | tonumber) |
        .app_state.slashing.params.min_signed_per_window = $min_signed |
        .app_state.slashing.params.downtime_jail_duration = $jail |
        .app_state.slashing.params.slash_fraction_double_sign = $double_sign |
        .app_state.slashing.params.slash_fraction_downtime = $downtime' \
       "$GENESIS_FILE" > "$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS_FILE"
    
    # Step 8: Configure EVM precompiles
    print_info "Configuring EVM precompiles..."
    local precompiles=$(yq eval -o json '.evm.active_static_precompiles' "$config_file")
    
    jq --argjson precompiles "$precompiles" \
       '.app_state.evm.params.active_static_precompiles = $precompiles' \
       "$GENESIS_FILE" > "$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS_FILE"
    
    # Step 9: Configure ERC20 module (token pairs and native precompiles)
    print_info "Configuring ERC20 module..."
    local token_pairs=$(yq eval -o json '.erc20.token_pairs' "$config_file")
    local native_precompiles=$(yq eval -o json '.erc20.native_precompiles' "$config_file")
    
    jq --argjson pairs "$token_pairs" \
       --argjson precompiles "$native_precompiles" \
       '.app_state.erc20.token_pairs = $pairs |
        .app_state.erc20.native_precompiles = $precompiles' \
       "$GENESIS_FILE" > "$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS_FILE"
    
    # Step 10: Configure FeeMarket
    print_info "Configuring FeeMarket..."
    local no_base_fee=$(yq eval '.feemarket.no_base_fee' "$config_file")
    
    jq --arg no_fee "$no_base_fee" \
       '.app_state.feemarket.params.no_base_fee = ($no_fee == "true")' \
       "$GENESIS_FILE" > "$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS_FILE"
    
    # Step 11: Configure consensus parameters
    print_info "Configuring consensus parameters..."
    local max_gas=$(yq eval '.consensus.block.max_gas' "$config_file")
    local max_bytes=$(yq eval '.consensus.block.max_bytes' "$config_file")
    
    jq --arg max_gas_val "$max_gas" \
       --arg max_bytes_val "$max_bytes" \
       '.consensus_params.block.max_gas = $max_gas_val |
        .consensus_params.block.max_bytes = $max_bytes_val' \
       "$GENESIS_FILE" > "$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS_FILE"
    
    # Step 12: Validate genesis
    print_info "Validating genesis file..."
    if "$INFINITED" genesis validate-genesis --home "$output_dir" 2>&1; then
        print_success "Genesis file is valid!"
    else
        print_error "Genesis validation failed!"
        exit 1
    fi
    
    # Check if validators exist
    local validators_count=$(jq '.app_state.staking.validators | length' "$GENESIS_FILE" 2>/dev/null || echo "0")
    
    # Final summary
    echo ""
    print_success "Genesis file generated successfully!"
    print_info "Location: $GENESIS_FILE"
    print_info "Chain ID: $cosmos_chain_id (Cosmos) / $evm_chain_id (EVM)"
    echo ""
    
    if [ "$validators_count" = "0" ] || [ -z "$validators_count" ]; then
        print_warning "⚠️  IMPORTANT: This Genesis has NO VALIDATORS"
        echo ""
        echo "   A Cosmos chain REQUIRES at least one validator to produce blocks."
        echo "   Without validators, the chain will start but will NOT produce any blocks."
        echo ""
        echo "   You MUST add validators before launching the chain:"
        echo ""
    echo "   For each validator:"
    echo "   1. Create validator key:"
    echo "      infinited keys add validator-1 --keyring-backend file --home $output_dir"
    echo ""
    echo "   2. Add account with funds (creates tokens from nothing):"
    echo "      infinited genesis add-genesis-account validator-1 1000000000000000000000${base_denom} \\"
    echo "        --keyring-backend file --home $output_dir"
    echo "      # ↑ This creates 1000 TEA from nothing and assigns to validator-1"
    echo ""
    echo "   3. Create gentx (uses existing tokens for staking):"
    echo "      infinited genesis gentx validator-1 1000000000000000000000${base_denom} \\"
    echo "        --chain-id $cosmos_chain_id \\"
    echo "        --commission-rate \"0.10\" \\"
    echo "        --commission-max-rate \"0.20\" \\"
    echo "        --commission-max-change-rate \"0.01\" \\"
    echo "        --min-self-delegation \"1000000000000000000\" \\"
    echo "        --keyring-backend file --home $output_dir"
    echo "      # ↑ This uses the 1000 TEA already assigned to validator-1"
    echo ""
    echo "   4. Collect all gentxs:"
    echo "      infinited genesis collect-gentxs --home $output_dir"
    echo ""
    echo "   See guides/VALIDATORS_GENESIS.md and guides/TOKEN_SUPPLY_GENESIS.md for details."
        echo ""
    else
        print_success "✓ Genesis contains $validators_count validator(s)"
    fi
    
    echo ""
    print_info "Next steps:"
    echo "  1. Add initial accounts (if needed):"
    echo "     infinited genesis add-genesis-account ADDRESS AMOUNT${base_denom} \\"
    echo "       --keyring-backend file --home $output_dir"
    echo ""
    if [ "$validators_count" = "0" ] || [ -z "$validators_count" ]; then
        echo "  2. ⚠️  ADD VALIDATORS (REQUIRED for chain to produce blocks):"
        echo "     See instructions above or guides/VALIDATORS_GENESIS.md"
        echo ""
    else
        echo "  2. ✓ Validators are already configured"
        echo ""
    fi
    echo "  3. Verify final genesis:"
    echo "     infinited genesis validate-genesis --home $output_dir"
    echo ""
}

# Main execution
main() {
    # Check arguments
    if [ -z "$NETWORK_TYPE" ] || [ -z "$MONIKER" ]; then
        print_error "Missing required arguments"
        usage
        exit 1
    fi
    
    # Check dependencies
    check_dependencies
    
    # Setup genesis
    setup_genesis "$NETWORK_TYPE" "$MONIKER" "$OUTPUT_DIR"
}

main "$@"

