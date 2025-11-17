#!/bin/bash
#
# Copyright (c) 2025 Deep Thought Labs
# All rights reserved.
#
# This file is part of the Infinite Drive blockchain tooling.
#
# Purpose: Generate commands to configure ModuleAccounts with linear vesting
#          for mainnet, testnet, or creative networks.
#
# This script does NOT execute any commands. It only prints the commands you need to
# copy and paste in the correct order.
#
# Usage: ./scripts/setup_module_accounts.sh --network <mainnet|testnet|creative> [--genesis-dir <path>]
#
# Example:
#   ./scripts/setup_module_accounts.sh --network mainnet
#
# Exit codes:
#   0 - Success
#   1 - Error (invalid arguments, file not found, etc.)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variables
NETWORK_MODE=""
GENESIS_DIR="${HOME}/.infinited"
SCRIPT_DIR=""
NETWORK_CONFIG_FILE=""
VESTING_CONFIG_FILE=""
BASE_DENOM=""

# Print colored messages
print_info() {
    echo -e "${GREEN}ℹ${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_command() {
    echo -e "${CYAN}$1${NC}"
}

print_section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Parse command line arguments
parse_arguments() {
    local network=""
    local genesis_dir=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --network)
                network="$2"
                shift 2
                ;;
            --genesis-dir)
                genesis_dir="$2"
                shift 2
                ;;
            -h|--help)
                echo "Usage: $0 --network <mainnet|testnet|creative> [--genesis-dir <path>]"
                echo ""
                echo "Options:"
                echo "  --network <mainnet|testnet|creative>  Network to configure (REQUIRED)"
                echo "  --genesis-dir <path>                  Genesis directory (default: ~/.infinited)"
                echo "  -h, --help                            Show this help message"
                echo ""
                echo "This script generates commands for setting up ModuleAccounts with vesting."
                echo "It does NOT execute any commands - you must copy and paste them manually."
                exit 0
                ;;
            *)
                print_error "Unknown argument: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Validate network is provided
    if [[ -z "$network" ]]; then
        print_error "Error: --network flag is required"
        echo ""
        echo "Usage: $0 --network <mainnet|testnet|creative> [--genesis-dir <path>]"
        echo "Use --help for more information"
        exit 1
    fi
    
    # Validate network value
    if [[ "$network" != "mainnet" && "$network" != "testnet" && "$network" != "creative" ]]; then
        print_error "Error: Invalid network '$network'"
        echo ""
        echo "Valid networks: mainnet, testnet, creative"
        exit 1
    fi
    
    NETWORK_MODE="$network"
    
    if [[ -n "$genesis_dir" ]]; then
        GENESIS_DIR="$genesis_dir"
    fi
}

# Load configuration files
load_config_files() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    NETWORK_CONFIG_FILE="${SCRIPT_DIR}/genesis-configs/${NETWORK_MODE}.json"
    VESTING_CONFIG_FILE="${SCRIPT_DIR}/genesis-configs/${NETWORK_MODE}-vesting.json"
    
    # Validate network config file exists
    if [[ ! -f "$NETWORK_CONFIG_FILE" ]]; then
        print_error "Network configuration file not found: $NETWORK_CONFIG_FILE"
        exit 1
    fi
    
    # Validate vesting config file exists
    if [[ ! -f "$VESTING_CONFIG_FILE" ]]; then
        print_error "Vesting configuration file not found: $VESTING_CONFIG_FILE"
        exit 1
    fi
    
    # Validate JSON files
    if ! command -v jq &> /dev/null; then
        print_error "jq is required but not installed. Please install jq first."
        exit 1
    fi
    
    if ! jq empty "$NETWORK_CONFIG_FILE" 2>/dev/null; then
        print_error "Invalid JSON in network configuration file: $NETWORK_CONFIG_FILE"
        exit 1
    fi
    
    if ! jq empty "$VESTING_CONFIG_FILE" 2>/dev/null; then
        print_error "Invalid JSON in vesting configuration file: $VESTING_CONFIG_FILE"
        exit 1
    fi
    
    # Load base denom from network config
    BASE_DENOM=$(jq -r '.token.base_denom' "$NETWORK_CONFIG_FILE")
    
    if [[ -z "$BASE_DENOM" || "$BASE_DENOM" == "null" ]]; then
        print_error "Could not read base_denom from network configuration file"
        exit 1
    fi
}

# Convert tokens to atomic units (multiply by 10^18)
convert_to_atomic() {
    local tokens="$1"
    # Use bc for precise calculation: tokens * 10^18
    if command -v bc &> /dev/null; then
        echo "$tokens * 1000000000000000000" | bc
    else
        # Fallback: simple multiplication (may lose precision for very large numbers)
        echo "${tokens}000000000000000000"
    fi
}

# Main function
main() {
    parse_arguments "$@"
    
    local network_upper
    network_upper=$(echo "$NETWORK_MODE" | tr '[:lower:]' '[:upper:]')
    print_section "ModuleAccounts Setup Commands for $network_upper"
    
    print_info "Network: $NETWORK_MODE"
    print_info "Genesis directory: $GENESIS_DIR"
    echo ""
    
    # Load configuration files
    load_config_files
    
    print_info "Base denom: $BASE_DENOM"
    echo ""
    
    # Load vesting configuration
    local vesting_start vesting_end
    vesting_start=$(jq -r '.vesting_start_time' "$VESTING_CONFIG_FILE")
    vesting_end=$(jq -r '.vesting_end_time' "$VESTING_CONFIG_FILE")
    
    print_info "Vesting start time: $vesting_start"
    print_info "Vesting end time: $vesting_end"
    echo ""
    
    # Process each pool
    local pools_count
    pools_count=$(jq '.pools | length' "$VESTING_CONFIG_FILE")
    
    print_section "Commands to Execute"
    
    print_info "Copy and paste each command below in order:"
    echo ""
    
    for ((i=0; i<pools_count; i++)); do
        local pool_name pool_amount pool_permissions
        
        pool_name=$(jq -r ".pools[$i].name" "$VESTING_CONFIG_FILE")
        pool_amount=$(jq -r ".pools[$i].amount_tokens" "$VESTING_CONFIG_FILE")
        pool_permissions=$(jq -r ".pools[$i].permissions" "$VESTING_CONFIG_FILE")
        
        # Convert to atomic units
        local atomic_amount
        atomic_amount=$(convert_to_atomic "$pool_amount")
        local amount_with_denom="${atomic_amount}${BASE_DENOM}"
        
        # Generate command
        print_command "infinited genesis add-module-vesting-account $pool_name --module-name $pool_name --vesting-amount $amount_with_denom --vesting-start-time $vesting_start --vesting-end-time $vesting_end --permissions $pool_permissions --home $GENESIS_DIR"
        echo ""
    done
    
    print_section "Summary"
    
    print_info "Configuration:"
    echo "  - Network: $NETWORK_MODE"
    echo "  - Base denom: $BASE_DENOM"
    echo "  - Module accounts: $pools_count"
    echo "  - Vesting start: $vesting_start"
    echo "  - Vesting end: $vesting_end"
    echo ""
    
    print_info "Next steps:"
    echo "  1. Copy and paste each command above in order"
    echo "  2. Validate the genesis file: infinited genesis validate --home $GENESIS_DIR"
    echo ""
}

# Run main function
main "$@"
