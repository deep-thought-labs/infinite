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

# Network configuration variables (will be set based on --network flag)
BASE_DENOM=""
DISPLAY_DENOM=""
SYMBOL=""
TOKEN_NAME=""
TOKEN_DESCRIPTION=""
TOKEN_URI=""
EVM_CHAIN_ID=0
NETWORK_MODE=""

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

# Configure network-specific values
configure_network_values() {
    case "$NETWORK_MODE" in
        mainnet)
            BASE_DENOM="drop"
            DISPLAY_DENOM="Improbability"
            SYMBOL="42"
            TOKEN_NAME="Improbability"
            TOKEN_DESCRIPTION="Improbability Token — Project 42: Sovereign, Perpetual, DAO-Governed"
            TOKEN_URI=""
            EVM_CHAIN_ID=421018
            ;;
        testnet)
            BASE_DENOM="tdrop"
            DISPLAY_DENOM="TestImprobability"
            SYMBOL="TEST42"
            TOKEN_NAME="TestImprobability"
            TOKEN_DESCRIPTION="TestImprobability Token — Project 42 Testnet: Sovereign, Perpetual, DAO-Governed"
            TOKEN_URI=""
            EVM_CHAIN_ID=421018001
            ;;
        creative)
            BASE_DENOM="cdrop"
            DISPLAY_DENOM="CreativeImprobability"
            SYMBOL="CRE42"
            TOKEN_NAME="CreativeImprobability"
            TOKEN_DESCRIPTION="CreativeImprobability Token — Project 42 Creative: Experimental Playground Network"
            TOKEN_URI=""
            EVM_CHAIN_ID=421018002
            ;;
    esac
    
    print_info "Configuring for network: $NETWORK_MODE"
    print_info "Base denom: $BASE_DENOM"
    print_info "Display denom: $DISPLAY_DENOM"
    print_info "Symbol: $SYMBOL"
    print_info "EVM Chain ID: $EVM_CHAIN_ID"
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
    
    # Unbonding time: 21 days for mainnet/testnet, 1 day for creative
    local unbonding_time
    if [[ "$NETWORK_MODE" == "creative" ]]; then
        unbonding_time="86400s"  # 1 day
    else
        unbonding_time="1814400s"  # 21 days
    fi
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"staking\"][\"params\"][\"unbonding_time\"]=\"$unbonding_time\"" \
        "Staking unbonding_time → $unbonding_time"
    
    # Max validators: 100 for mainnet/testnet, 50 for creative
    local max_validators
    if [[ "$NETWORK_MODE" == "creative" ]]; then
        max_validators=50
    else
        max_validators=100
    fi
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"staking\"][\"params\"][\"max_validators\"]=$max_validators" \
        "Staking max_validators → $max_validators"
    
    # Historical entries: 10000 for mainnet/testnet, 1000 for creative
    local historical_entries
    if [[ "$NETWORK_MODE" == "creative" ]]; then
        historical_entries=1000
    else
        historical_entries=10000
    fi
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"staking\"][\"params\"][\"historical_entries\"]=$historical_entries" \
        "Staking historical_entries → $historical_entries"
    
    # Max entries: 7 for all networks
    apply_jq_modification "$genesis_file" \
        '.app_state["staking"]["params"]["max_entries"]=7' \
        "Staking max_entries → 7"
    
    # Min commission rate: 0% for all networks
    apply_jq_modification "$genesis_file" \
        '.app_state["staking"]["params"]["min_commission_rate"]="0.000000000000000000"' \
        "Staking min_commission_rate → 0%"
}

# Configure Mint Module parameters (inflation)
configure_mint_module() {
    local genesis_file="$1"
    
    print_info "Configuring Mint Module parameters (inflation)..."
    
    # Inflation parameters
    local inflation_min inflation_max inflation_rate_change goal_bonded initial_inflation
    
    if [[ "$NETWORK_MODE" == "creative" ]]; then
        # Creative: No inflation (0%)
        inflation_min="0.000000000000000000"
        inflation_max="0.000000000000000000"
        inflation_rate_change="0.000000000000000000"
        goal_bonded="0.500000000000000000"  # 50%
        initial_inflation="0.000000000000000000"
    else
        # Mainnet/Testnet: Standard inflation (7-20%)
        inflation_min="0.070000000000000000"  # 7%
        inflation_max="0.200000000000000000"  # 20%
        inflation_rate_change="0.130000000000000000"  # 13%
        goal_bonded="0.670000000000000000"  # 67%
        initial_inflation="0.130000000000000000"  # 13%
    fi
    
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
    
    # Blocks per year: 6311520 for all networks (based on ~5s block time)
    apply_jq_modification "$genesis_file" \
        '.app_state["mint"]["params"]["blocks_per_year"]="6311520"' \
        "Mint blocks_per_year → 6311520"
    
    # Initial inflation in minter
    apply_jq_modification "$genesis_file" \
        ".app_state[\"mint\"][\"minter\"][\"inflation\"]=\"$initial_inflation\"" \
        "Mint minter.inflation → $initial_inflation"
    
    # Annual provisions starts at 0
    apply_jq_modification "$genesis_file" \
        '.app_state["mint"]["minter"]["annual_provisions"]="0.000000000000000000"' \
        "Mint minter.annual_provisions → 0"
}

# Configure Governance Module parameters
configure_governance_module() {
    local genesis_file="$1"
    
    print_info "Configuring Governance Module parameters..."
    
    # Voting periods and deposits
    local max_deposit_period voting_period expedited_voting_period
    local min_deposit expedited_min_deposit
    local quorum threshold veto_threshold
    
    if [[ "$NETWORK_MODE" == "creative" ]]; then
        # Creative: Fast periods for experimentation
        max_deposit_period="3600s"  # 1 hour
        voting_period="3600s"  # 1 hour
        expedited_voting_period="1800s"  # 30 minutes
        min_deposit="100000000000000000"  # 0.1 token
        expedited_min_deposit="1000000000000000000"  # 1 token
        quorum="0.100000000000000000"  # 10%
        threshold="0.500000000000000000"  # 50%
        veto_threshold="0.200000000000000000"  # 20%
    else
        # Mainnet/Testnet: Standard production periods
        max_deposit_period="172800s"  # 2 days
        voting_period="172800s"  # 2 days
        expedited_voting_period="86400s"  # 1 day
        min_deposit="1000000000000000000"  # 1 token
        expedited_min_deposit="5000000000000000000"  # 5 tokens
        quorum="0.334000000000000000"  # 33.4%
        threshold="0.500000000000000000"  # 50%
        veto_threshold="0.334000000000000000"  # 33.4%
    fi
    
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
    
    # Slashing parameters
    local signed_blocks_window min_signed_per_window downtime_jail_duration
    local slash_fraction_double_sign slash_fraction_downtime
    
    if [[ "$NETWORK_MODE" == "creative" ]]; then
        # Creative: Lenient slashing for experimentation
        signed_blocks_window=5000
        min_signed_per_window="0.010000000000000000"  # 1%
        downtime_jail_duration="60s"  # 1 minute
        slash_fraction_double_sign="0.010000000000000000"  # 1%
        slash_fraction_downtime="0.000010000000000000"  # 0.001%
    else
        # Mainnet/Testnet: Standard security parameters
        signed_blocks_window=10000
        min_signed_per_window="0.050000000000000000"  # 5%
        downtime_jail_duration="600s"  # 10 minutes
        slash_fraction_double_sign="0.050000000000000000"  # 5%
        slash_fraction_downtime="0.000100000000000000"  # 0.01%
    fi
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"slashing\"][\"params\"][\"signed_blocks_window\"]=$signed_blocks_window" \
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
    
    # Fee market parameters
    local no_base_fee base_fee min_gas_multiplier
    
    if [[ "$NETWORK_MODE" == "creative" ]]; then
        # Creative: No base fee (free transactions)
        no_base_fee=true
        base_fee="0"
        min_gas_multiplier="0.100000000000000000"  # 10%
    else
        # Mainnet/Testnet: Standard fee market
        no_base_fee=false
        base_fee="1000000000"  # 1 gwei
        min_gas_multiplier="0.500000000000000000"  # 50%
    fi
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"feemarket\"][\"params\"][\"no_base_fee\"]=$no_base_fee" \
        "Fee Market no_base_fee → $no_base_fee"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"feemarket\"][\"params\"][\"base_fee\"]=\"$base_fee\"" \
        "Fee Market base_fee → $base_fee"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"feemarket\"][\"params\"][\"min_gas_price\"]=\"0\"" \
        "Fee Market min_gas_price → 0"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"feemarket\"][\"params\"][\"min_gas_multiplier\"]=\"$min_gas_multiplier\"" \
        "Fee Market min_gas_multiplier → $min_gas_multiplier"
    
    # Base fee change denominator: 8 (default)
    apply_jq_modification "$genesis_file" \
        '.app_state["feemarket"]["params"]["base_fee_change_denominator"]=8' \
        "Fee Market base_fee_change_denominator → 8"
    
    # Elasticity multiplier: 2 (default)
    apply_jq_modification "$genesis_file" \
        '.app_state["feemarket"]["params"]["elasticity_multiplier"]=2' \
        "Fee Market elasticity_multiplier → 2"
    
    # Enable height: 0 (enabled from start)
    apply_jq_modification "$genesis_file" \
        '.app_state["feemarket"]["params"]["enable_height"]=0' \
        "Fee Market enable_height → 0"
    
    # Block gas: 0 (initial)
    apply_jq_modification "$genesis_file" \
        '.app_state["feemarket"]["block_gas"]="0"' \
        "Fee Market block_gas → 0"
}

# Configure Distribution Module parameters (fee distribution)
configure_distribution_module() {
    local genesis_file="$1"
    
    print_info "Configuring Distribution Module parameters (fee distribution)..."
    
    # Distribution parameters
    local community_tax base_proposer_reward bonus_proposer_reward
    
    if [[ "$NETWORK_MODE" == "creative" ]]; then
        # Creative: Minimal fees, everything to validators
        community_tax="0.000000000000000000"  # 0%
        base_proposer_reward="0.000000000000000000"  # 0%
        bonus_proposer_reward="0.000000000000000000"  # 0%
    else
        # Mainnet/Testnet: Standard distribution
        community_tax="0.020000000000000000"  # 2% to community pool
        base_proposer_reward="0.010000000000000000"  # 1% to proposer
        bonus_proposer_reward="0.040000000000000000"  # 4% bonus to proposer
    fi
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"distribution\"][\"params\"][\"community_tax\"]=\"$community_tax\"" \
        "Distribution community_tax → $community_tax"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"distribution\"][\"params\"][\"base_proposer_reward\"]=\"$base_proposer_reward\"" \
        "Distribution base_proposer_reward → $base_proposer_reward"
    
    apply_jq_modification "$genesis_file" \
        ".app_state[\"distribution\"][\"params\"][\"bonus_proposer_reward\"]=\"$bonus_proposer_reward\"" \
        "Distribution bonus_proposer_reward → $bonus_proposer_reward"
    
    # Withdraw address enabled: true for all networks
    apply_jq_modification "$genesis_file" \
        '.app_state["distribution"]["params"]["withdraw_addr_enabled"]=true' \
        "Distribution withdraw_addr_enabled → true"
}

# Configure consensus parameters
configure_consensus_params() {
    local genesis_file="$1"
    
    print_info "Configuring consensus parameters..."
    
    # Max gas: 10M for mainnet/testnet, 20M for creative
    local max_gas
    if [[ "$NETWORK_MODE" == "creative" ]]; then
        max_gas="20000000"  # 20M
    else
        max_gas="10000000"  # 10M
    fi
    
    apply_jq_modification "$genesis_file" \
        ".consensus.params.block.max_gas=\"$max_gas\"" \
        "Consensus max_gas → $max_gas"
    
    # Max bytes: ~21MB for all networks
    apply_jq_modification "$genesis_file" \
        '.consensus.params.block.max_bytes="22020096"' \
        "Consensus max_bytes → 22020096"
    
    # Evidence max age: 2 days for mainnet/testnet, 1 day for creative
    local max_age_duration
    if [[ "$NETWORK_MODE" == "creative" ]]; then
        max_age_duration="86400000000000"  # 1 day in nanoseconds
    else
        max_age_duration="172800000000000"  # 2 days in nanoseconds
    fi
    
    apply_jq_modification "$genesis_file" \
        ".consensus.params.evidence.max_age_duration=\"$max_age_duration\"" \
        "Consensus evidence.max_age_duration → $max_age_duration"
    
    # Evidence max age num blocks: 100000 for mainnet/testnet, 50000 for creative
    local max_age_num_blocks
    if [[ "$NETWORK_MODE" == "creative" ]]; then
        max_age_num_blocks=50000
    else
        max_age_num_blocks=100000
    fi
    
    apply_jq_modification "$genesis_file" \
        ".consensus.params.evidence.max_age_num_blocks=$max_age_num_blocks" \
        "Consensus evidence.max_age_num_blocks → $max_age_num_blocks"
    
    # Evidence max bytes: 1MB for all networks
    apply_jq_modification "$genesis_file" \
        '.consensus.params.evidence.max_bytes="1048576"' \
        "Consensus evidence.max_bytes → 1048576"
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
