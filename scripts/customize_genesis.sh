#!/bin/bash
#
# Copyright (c) 2025 Deep Thought Labs
# All rights reserved.
#
# This file is part of the Infinite Drive blockchain tooling.
#
# Purpose: Customize a generated genesis.json file with all Infinite Drive
#          personalizations (denominations, token metadata, EVM config, etc.)
#          for mainnet, testnet, or creative networks.
#
# Usage: ./scripts/customize_genesis.sh <genesis_file_path> --network <mainnet|testnet|creative>
#
# Example:
#   ./scripts/customize_genesis.sh ~/.infinited/config/genesis.json --network mainnet
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

# Network configuration variables (will be loaded from config file)
BASE_DENOM=""
DISPLAY_DENOM=""
SYMBOL=""
TOKEN_NAME=""
TOKEN_DESCRIPTION=""
TOKEN_URI=""
EVM_CHAIN_ID=0
COSMOS_CHAIN_ID=""
NETWORK_MODE=""
CONFIG_FILE=""

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

# Parse command line arguments
parse_arguments() {
    local genesis_file=""
    local network=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --network)
                network="$2"
                shift 2
                ;;
            *)
                if [[ -z "$genesis_file" ]]; then
                    genesis_file="$1"
                else
                    print_error "Unknown argument: $1"
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Validate network is provided
    if [[ -z "$network" ]]; then
        print_error "Error: --network flag is required"
        echo ""
        echo "Usage: $0 <genesis_file_path> --network <mainnet|testnet|creative>"
        echo ""
        echo "Valid networks:"
        echo "  mainnet   - Production network"
        echo "  testnet   - Testing network (similar to mainnet)"
        echo "  creative  - Creative/playground network (low fees, experimental)"
        exit 1
    fi
    
    # Validate network value
    if [[ "$network" != "mainnet" && "$network" != "testnet" && "$network" != "creative" ]]; then
        print_error "Error: Invalid network '$network'"
        echo ""
        echo "Valid networks: mainnet, testnet, creative"
        exit 1
    fi
    
    # Validate genesis file is provided
    if [[ -z "$genesis_file" ]]; then
        print_error "Error: Genesis file path is required"
        echo ""
        echo "Usage: $0 <genesis_file_path> --network <mainnet|testnet|creative>"
        exit 1
    fi
    
    GENESIS_FILE="$genesis_file"
    NETWORK_MODE="$network"
}

# Load configuration from JSON file
load_config_file() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    CONFIG_FILE="${script_dir}/genesis-configs/${NETWORK_MODE}.json"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_error "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
    
    if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
        print_error "Invalid JSON configuration file: $CONFIG_FILE"
        exit 1
    fi
    
    print_info "Loading configuration from: $CONFIG_FILE"
}

# Configure network-specific values from config file
configure_network_values() {
    load_config_file
    
    # Load token configuration
    BASE_DENOM=$(jq -r '.token.base_denom' "$CONFIG_FILE")
    DISPLAY_DENOM=$(jq -r '.token.display_denom' "$CONFIG_FILE")
    SYMBOL=$(jq -r '.token.symbol' "$CONFIG_FILE")
    TOKEN_NAME=$(jq -r '.token.name' "$CONFIG_FILE")
    TOKEN_DESCRIPTION=$(jq -r '.token.description' "$CONFIG_FILE")
    TOKEN_URI=$(jq -r '.token.uri' "$CONFIG_FILE")
    EVM_CHAIN_ID=$(jq -r '.evm.chain_id' "$CONFIG_FILE")
    COSMOS_CHAIN_ID=$(jq -r '.cosmos.chain_id' "$CONFIG_FILE")
    
    print_info "Configuring for network: $NETWORK_MODE"
    print_info "Base denom: $BASE_DENOM"
    print_info "Display denom: $DISPLAY_DENOM"
    print_info "Symbol: $SYMBOL"
    print_info "EVM Chain ID: $EVM_CHAIN_ID"
    print_info "Cosmos Chain ID: $COSMOS_CHAIN_ID"
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

# Configure Cosmos Chain ID
configure_cosmos_chain_id() {
    local genesis_file="$1"
    
    print_info "Configuring Cosmos Chain ID to '$COSMOS_CHAIN_ID'..."
    
    apply_jq_modification "$genesis_file" \
        ".chain_id=\"$COSMOS_CHAIN_ID\"" \
        "Cosmos Chain ID → $COSMOS_CHAIN_ID"
}

# Customize module denominations
customize_denominations() {
    local genesis_file="$1"
    
    print_info "Customizing module denominations to '$BASE_DENOM'..."
    
    # Staking module
    apply_jq_modification "$genesis_file" \
        ".app_state[\"staking\"][\"params\"][\"bond_denom\"]=\"$BASE_DENOM\"" \
        "Staking bond_denom → $BASE_DENOM"
    
    # Mint module
    apply_jq_modification "$genesis_file" \
        ".app_state[\"mint\"][\"params\"][\"mint_denom\"]=\"$BASE_DENOM\"" \
        "Mint mint_denom → $BASE_DENOM"
    
    # Governance module - min_deposit
    apply_jq_modification "$genesis_file" \
        ".app_state[\"gov\"][\"params\"][\"min_deposit\"][0][\"denom\"]=\"$BASE_DENOM\"" \
        "Governance min_deposit → $BASE_DENOM"
    
    # Governance module - expedited_min_deposit
    apply_jq_modification "$genesis_file" \
        ".app_state[\"gov\"][\"params\"][\"expedited_min_deposit\"][0][\"denom\"]=\"$BASE_DENOM\"" \
        "Governance expedited_min_deposit → $BASE_DENOM"
    
    # EVM module
    apply_jq_modification "$genesis_file" \
        ".app_state[\"evm\"][\"params\"][\"evm_denom\"]=\"$BASE_DENOM\"" \
        "EVM evm_denom → $BASE_DENOM"
}

# Add token metadata
add_token_metadata() {
    local genesis_file="$1"
    
    print_info "Adding token metadata for $TOKEN_NAME ($SYMBOL) token..."
    
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
    local token_pair="{
        \"contract_owner\": 1,
        \"erc20_address\": \"0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE\",
        \"denom\": \"$BASE_DENOM\",
        \"enabled\": true
    }"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"erc20\"][\"token_pairs\"]=[$token_pair]" \
        "ERC20 native token pair configured"
}

# Configure Staking Module parameters
configure_staking_module() {
    local genesis_file="$1"
    
    print_info "Configuring Staking Module parameters..."
    
    local unbonding_time max_validators historical_entries max_entries min_commission_rate
    
    unbonding_time=$(jq -r '.staking.unbonding_time' "$CONFIG_FILE")
    max_validators=$(jq -r '.staking.max_validators' "$CONFIG_FILE")
    historical_entries=$(jq -r '.staking.historical_entries' "$CONFIG_FILE")
    max_entries=$(jq -r '.staking.max_entries' "$CONFIG_FILE")
    min_commission_rate=$(jq -r '.staking.min_commission_rate' "$CONFIG_FILE")
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"staking\"][\"params\"][\"unbonding_time\"]=\"$unbonding_time\"" \
        "Staking unbonding_time → $unbonding_time"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"staking\"][\"params\"][\"max_validators\"]=$max_validators" \
        "Staking max_validators → $max_validators"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"staking\"][\"params\"][\"historical_entries\"]=$historical_entries" \
        "Staking historical_entries → $historical_entries"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"staking\"][\"params\"][\"max_entries\"]=$max_entries" \
        "Staking max_entries → $max_entries"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"staking\"][\"params\"][\"min_commission_rate\"]=\"$min_commission_rate\"" \
        "Staking min_commission_rate → $min_commission_rate"
}

# Configure Mint Module parameters (inflation)
configure_mint_module() {
    local genesis_file="$1"
    
    print_info "Configuring Mint Module parameters (inflation)..."
    
    local inflation_min inflation_max inflation_rate_change goal_bonded blocks_per_year
    local initial_inflation initial_annual_provisions
    
    inflation_min=$(jq -r '.mint.inflation_min' "$CONFIG_FILE")
    inflation_max=$(jq -r '.mint.inflation_max' "$CONFIG_FILE")
    inflation_rate_change=$(jq -r '.mint.inflation_rate_change' "$CONFIG_FILE")
    goal_bonded=$(jq -r '.mint.goal_bonded' "$CONFIG_FILE")
    blocks_per_year=$(jq -r '.mint.blocks_per_year' "$CONFIG_FILE")
    initial_inflation=$(jq -r '.mint.initial_inflation' "$CONFIG_FILE")
    initial_annual_provisions=$(jq -r '.mint.initial_annual_provisions' "$CONFIG_FILE")
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"mint\"][\"params\"][\"inflation_min\"]=\"$inflation_min\"" \
        "Mint inflation_min → $inflation_min"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"mint\"][\"params\"][\"inflation_max\"]=\"$inflation_max\"" \
        "Mint inflation_max → $inflation_max"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"mint\"][\"params\"][\"inflation_rate_change\"]=\"$inflation_rate_change\"" \
        "Mint inflation_rate_change → $inflation_rate_change"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"mint\"][\"params\"][\"goal_bonded\"]=\"$goal_bonded\"" \
        "Mint goal_bonded → $goal_bonded"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"mint\"][\"params\"][\"blocks_per_year\"]=\"$blocks_per_year\"" \
        "Mint blocks_per_year → $blocks_per_year"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"mint\"][\"minter\"][\"inflation\"]=\"$initial_inflation\"" \
        "Mint minter.inflation → $initial_inflation"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"mint\"][\"minter\"][\"annual_provisions\"]=\"$initial_annual_provisions\"" \
        "Mint minter.annual_provisions → $initial_annual_provisions"
}

# Configure Governance Module parameters
configure_governance_module() {
    local genesis_file="$1"
    
    print_info "Configuring Governance Module parameters..."
    
    local max_deposit_period voting_period expedited_voting_period
    local min_deposit expedited_min_deposit
    local quorum threshold veto_threshold
    
    max_deposit_period=$(jq -r '.governance.max_deposit_period' "$CONFIG_FILE")
    voting_period=$(jq -r '.governance.voting_period' "$CONFIG_FILE")
    expedited_voting_period=$(jq -r '.governance.expedited_voting_period' "$CONFIG_FILE")
    min_deposit=$(jq -r '.governance.min_deposit' "$CONFIG_FILE")
    expedited_min_deposit=$(jq -r '.governance.expedited_min_deposit' "$CONFIG_FILE")
    quorum=$(jq -r '.governance.quorum' "$CONFIG_FILE")
    threshold=$(jq -r '.governance.threshold' "$CONFIG_FILE")
    veto_threshold=$(jq -r '.governance.veto_threshold' "$CONFIG_FILE")
    
    # Update min_deposit amount (denom already set in customize_denominations)
    apply_jq_modification "$genesis_file" \
        ".app_state[\"gov\"][\"params\"][\"min_deposit\"][0][\"amount\"]=\"$min_deposit\"" \
        "Governance min_deposit amount → $min_deposit"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"gov\"][\"params\"][\"max_deposit_period\"]=\"$max_deposit_period\"" \
        "Governance max_deposit_period → $max_deposit_period"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"gov\"][\"params\"][\"voting_period\"]=\"$voting_period\"" \
        "Governance voting_period → $voting_period"
    
    # Update expedited_min_deposit amount (denom already set)
    apply_jq_modification "$genesis_file" \
        ".app_state[\"gov\"][\"params\"][\"expedited_min_deposit\"][0][\"amount\"]=\"$expedited_min_deposit\"" \
        "Governance expedited_min_deposit amount → $expedited_min_deposit"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"gov\"][\"params\"][\"expedited_voting_period\"]=\"$expedited_voting_period\"" \
        "Governance expedited_voting_period → $expedited_voting_period"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"gov\"][\"params\"][\"quorum\"]=\"$quorum\"" \
        "Governance quorum → $quorum"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"gov\"][\"params\"][\"threshold\"]=\"$threshold\"" \
        "Governance threshold → $threshold"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"gov\"][\"params\"][\"veto_threshold\"]=\"$veto_threshold\"" \
        "Governance veto_threshold → $veto_threshold"
}

# Configure Slashing Module parameters
configure_slashing_module() {
    local genesis_file="$1"
    
    print_info "Configuring Slashing Module parameters..."
    
    local signed_blocks_window min_signed_per_window downtime_jail_duration
    local slash_fraction_double_sign slash_fraction_downtime
    
    signed_blocks_window=$(jq -r '.slashing.signed_blocks_window' "$CONFIG_FILE")
    min_signed_per_window=$(jq -r '.slashing.min_signed_per_window' "$CONFIG_FILE")
    downtime_jail_duration=$(jq -r '.slashing.downtime_jail_duration' "$CONFIG_FILE")
    slash_fraction_double_sign=$(jq -r '.slashing.slash_fraction_double_sign' "$CONFIG_FILE")
    slash_fraction_downtime=$(jq -r '.slashing.slash_fraction_downtime' "$CONFIG_FILE")
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"slashing\"][\"params\"][\"signed_blocks_window\"]=\"$signed_blocks_window\"" \
        "Slashing signed_blocks_window → $signed_blocks_window"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"slashing\"][\"params\"][\"min_signed_per_window\"]=\"$min_signed_per_window\"" \
        "Slashing min_signed_per_window → $min_signed_per_window"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"slashing\"][\"params\"][\"downtime_jail_duration\"]=\"$downtime_jail_duration\"" \
        "Slashing downtime_jail_duration → $downtime_jail_duration"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"slashing\"][\"params\"][\"slash_fraction_double_sign\"]=\"$slash_fraction_double_sign\"" \
        "Slashing slash_fraction_double_sign → $slash_fraction_double_sign"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"slashing\"][\"params\"][\"slash_fraction_downtime\"]=\"$slash_fraction_downtime\"" \
        "Slashing slash_fraction_downtime → $slash_fraction_downtime"
}

# Configure Fee Market Module parameters
configure_fee_market_module() {
    local genesis_file="$1"
    
    print_info "Configuring Fee Market Module parameters..."
    
    local no_base_fee base_fee min_gas_price min_gas_multiplier
    local base_fee_change_denominator elasticity_multiplier enable_height block_gas
    
    no_base_fee=$(jq -r '.fee_market.no_base_fee' "$CONFIG_FILE")
    base_fee=$(jq -r '.fee_market.base_fee' "$CONFIG_FILE")
    min_gas_price=$(jq -r '.fee_market.min_gas_price' "$CONFIG_FILE")
    min_gas_multiplier=$(jq -r '.fee_market.min_gas_multiplier' "$CONFIG_FILE")
    base_fee_change_denominator=$(jq -r '.fee_market.base_fee_change_denominator' "$CONFIG_FILE")
    elasticity_multiplier=$(jq -r '.fee_market.elasticity_multiplier' "$CONFIG_FILE")
    enable_height=$(jq -r '.fee_market.enable_height' "$CONFIG_FILE")
    block_gas=$(jq -r '.fee_market.block_gas' "$CONFIG_FILE")
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"feemarket\"][\"params\"][\"no_base_fee\"]=$no_base_fee" \
        "Fee Market no_base_fee → $no_base_fee"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"feemarket\"][\"params\"][\"base_fee\"]=\"$base_fee\"" \
        "Fee Market base_fee → $base_fee"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"feemarket\"][\"params\"][\"min_gas_price\"]=\"$min_gas_price\"" \
        "Fee Market min_gas_price → $min_gas_price"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"feemarket\"][\"params\"][\"min_gas_multiplier\"]=\"$min_gas_multiplier\"" \
        "Fee Market min_gas_multiplier → $min_gas_multiplier"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"feemarket\"][\"params\"][\"base_fee_change_denominator\"]=$base_fee_change_denominator" \
        "Fee Market base_fee_change_denominator → $base_fee_change_denominator"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"feemarket\"][\"params\"][\"elasticity_multiplier\"]=$elasticity_multiplier" \
        "Fee Market elasticity_multiplier → $elasticity_multiplier"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"feemarket\"][\"params\"][\"enable_height\"]=\"$enable_height\"" \
        "Fee Market enable_height → $enable_height"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"feemarket\"][\"block_gas\"]=\"$block_gas\"" \
        "Fee Market block_gas → $block_gas"
}

# Configure Distribution Module parameters (fee distribution)
configure_distribution_module() {
    local genesis_file="$1"
    
    print_info "Configuring Distribution Module parameters (fee distribution)..."
    
    local community_tax base_proposer_reward bonus_proposer_reward withdraw_addr_enabled
    
    community_tax=$(jq -r '.distribution.community_tax' "$CONFIG_FILE")
    base_proposer_reward=$(jq -r '.distribution.base_proposer_reward' "$CONFIG_FILE")
    bonus_proposer_reward=$(jq -r '.distribution.bonus_proposer_reward' "$CONFIG_FILE")
    withdraw_addr_enabled=$(jq -r '.distribution.withdraw_addr_enabled' "$CONFIG_FILE")
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"distribution\"][\"params\"][\"community_tax\"]=\"$community_tax\"" \
        "Distribution community_tax → $community_tax"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"distribution\"][\"params\"][\"base_proposer_reward\"]=\"$base_proposer_reward\"" \
        "Distribution base_proposer_reward → $base_proposer_reward"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"distribution\"][\"params\"][\"bonus_proposer_reward\"]=\"$bonus_proposer_reward\"" \
        "Distribution bonus_proposer_reward → $bonus_proposer_reward"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"distribution\"][\"params\"][\"withdraw_addr_enabled\"]=$withdraw_addr_enabled" \
        "Distribution withdraw_addr_enabled → $withdraw_addr_enabled"
}

# Configure consensus parameters
configure_consensus_params() {
    local genesis_file="$1"
    
    print_info "Configuring consensus parameters..."
    
    local max_gas max_bytes evidence_max_age_duration evidence_max_age_num_blocks evidence_max_bytes
    
    max_gas=$(jq -r '.consensus.max_gas' "$CONFIG_FILE")
    max_bytes=$(jq -r '.consensus.max_bytes' "$CONFIG_FILE")
    evidence_max_age_duration=$(jq -r '.consensus.evidence_max_age_duration' "$CONFIG_FILE")
    evidence_max_age_num_blocks=$(jq -r '.consensus.evidence_max_age_num_blocks' "$CONFIG_FILE")
    evidence_max_bytes=$(jq -r '.consensus.evidence_max_bytes' "$CONFIG_FILE")
    
    apply_jq_modification "$genesis_file" \
        ".consensus.params.block.max_gas=\"$max_gas\"" \
        "Consensus max_gas → $max_gas"
    
    apply_jq_modification "$genesis_file" \
        ".consensus.params.block.max_bytes=\"$max_bytes\"" \
        "Consensus max_bytes → $max_bytes"
    
    apply_jq_modification "$genesis_file" \
        ".consensus.params.evidence.max_age_duration=\"$evidence_max_age_duration\"" \
        "Consensus evidence.max_age_duration → $evidence_max_age_duration"
    
    apply_jq_modification "$genesis_file" \
        ".consensus.params.evidence.max_age_num_blocks=\"$evidence_max_age_num_blocks\"" \
        "Consensus evidence.max_age_num_blocks → $evidence_max_age_num_blocks"
    
    apply_jq_modification "$genesis_file" \
        ".consensus.params.evidence.max_bytes=\"$evidence_max_bytes\"" \
        "Consensus evidence.max_bytes → $evidence_max_bytes"
}

# Main function
main() {
    parse_arguments "$@"
    
    print_info "Customizing Genesis file: $GENESIS_FILE"
    print_info "Network: $NETWORK_MODE"
    echo ""
    
    # Configure network-specific values
    configure_network_values
    
    # Check prerequisites
    check_prerequisites
    
    # Validate genesis file
    validate_genesis_file "$GENESIS_FILE"
    
    # Create backup
    local backup_file="${GENESIS_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$GENESIS_FILE" "$backup_file"
    print_info "Backup created: $backup_file"
    echo ""
    
    # Apply customizations
    configure_cosmos_chain_id "$GENESIS_FILE"
    customize_denominations "$GENESIS_FILE"
    add_token_metadata "$GENESIS_FILE"
    configure_evm_precompiles "$GENESIS_FILE"
    configure_erc20_native_pair "$GENESIS_FILE"
    configure_staking_module "$GENESIS_FILE"
    configure_mint_module "$GENESIS_FILE"
    configure_governance_module "$GENESIS_FILE"
    configure_slashing_module "$GENESIS_FILE"
    configure_fee_market_module "$GENESIS_FILE"
    configure_distribution_module "$GENESIS_FILE"
    configure_consensus_params "$GENESIS_FILE"
    
    echo ""
    print_info "Genesis file customized successfully for $NETWORK_MODE!"
    print_info "Backup saved at: $backup_file"
    echo ""
    print_info "Next steps:"
    echo "  1. Validate the genesis file: infinited genesis validate-genesis"
    echo "  2. Review the changes if needed"
    echo "  3. Remove the backup file when satisfied: rm $backup_file"
    echo ""
    print_info "Note: Use setup_genesis_accounts.sh to configure accounts and balances"
}

# Run main function
main "$@"
