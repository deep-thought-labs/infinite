#!/bin/bash
#
# Copyright (c) 2025 Deep Thought Labs
# All rights reserved.
#
# This file is part of the Infinite Drive blockchain tooling.
#
# Purpose: Configure ModuleAccounts (pure, without vesting) in genesis.json
#          for mainnet, testnet, or creative networks.
#
# This script EXECUTES the commands directly and modifies the genesis file.
#
# Usage: ./scripts/setup_module_accounts.sh --network <mainnet|testnet|creative> [--genesis-dir <path>]
#
# Example:
#   ./scripts/setup_module_accounts.sh --network mainnet
#
# Exit codes:
#   0 - Success
#   1 - Error (invalid arguments, file not found, command execution failed, etc.)

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
MODULE_CONFIG_FILE=""
BASE_DENOM=""
GENESIS_FILE=""
ERRORS=()
SUCCESS_COUNT=0
TOTAL_COUNT=0

# Print colored messages
print_info() {
    echo -e "${GREEN}ℹ${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Error handling
handle_error() {
    local line_number=$1
    local error_message=$2
    print_error "Error at line $line_number: $error_message"
    ERRORS+=("Line $line_number: $error_message")
}

# Trap errors
trap 'handle_error $LINENO "Unexpected error"' ERR

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
                echo "This script configures ModuleAccounts directly in the genesis file."
                echo "It EXECUTES commands and modifies the genesis.json file."
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
    MODULE_CONFIG_FILE="${SCRIPT_DIR}/genesis-configs/${NETWORK_MODE}-module-accounts.json"
    GENESIS_FILE="${GENESIS_DIR}/config/genesis.json"
    
    # Validate network config file exists
    if [[ ! -f "$NETWORK_CONFIG_FILE" ]]; then
        print_error "Network configuration file not found: $NETWORK_CONFIG_FILE"
        exit 1
    fi
    
    # Validate module config file exists
    if [[ ! -f "$MODULE_CONFIG_FILE" ]]; then
        print_error "Module configuration file not found: $MODULE_CONFIG_FILE"
        exit 1
    fi
    
    # Validate genesis file exists
    if [[ ! -f "$GENESIS_FILE" ]]; then
        print_error "Genesis file not found: $GENESIS_FILE"
        print_error "Make sure you have run 'infinited init' and 'customize_genesis.sh' first"
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
    
    if ! jq empty "$MODULE_CONFIG_FILE" 2>/dev/null; then
        print_error "Invalid JSON in module configuration file: $MODULE_CONFIG_FILE"
        exit 1
    fi
    
    if ! jq empty "$GENESIS_FILE" 2>/dev/null; then
        print_error "Invalid JSON in genesis file: $GENESIS_FILE"
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

# Check if ModuleAccount already exists
module_account_exists() {
    local module_addr="$1"
    jq -e --arg addr "$module_addr" '.app_state.auth.accounts[] | select(.base_account.address == $addr or .address == $addr) | select(."@type" == "/cosmos.auth.v1beta1.ModuleAccount")' "$GENESIS_FILE" > /dev/null 2>&1
}

# Create ModuleAccount
# Note: Custom ModuleAccounts always have empty permissions array.
# Permissions are only effective when registered in permissions.go (requires code changes).
create_module_account() {
    local pool_name="$1"
    local pool_amount="$2"
    local pool_permissions="$3"  # Always empty for custom ModuleAccounts, kept for compatibility
    
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
    
    print_info "Processing ModuleAccount: $pool_name"
    
    # Validate pool_name
    if [[ -z "$pool_name" || "$pool_name" == "null" ]]; then
        print_error "Pool has invalid or missing name"
        ERRORS+=("ModuleAccount $TOTAL_COUNT: Invalid or missing name")
        return 1
    fi
    
    # Calculate deterministic address using Go program
    local module_addr
    if ! module_addr=$(go run "${SCRIPT_DIR}/calc_module_addr.go" "$pool_name" 2>/dev/null); then
        print_error "Failed to calculate deterministic address for module: $pool_name"
        ERRORS+=("ModuleAccount '$pool_name': Failed to calculate address")
        return 1
    fi
    
    print_info "  Address: $module_addr"
    
    # Check if ModuleAccount already exists
    if module_account_exists "$module_addr"; then
        print_warning "  ModuleAccount '$pool_name' already exists, skipping..."
        return 0
    fi
    
    # Convert to atomic units (even if amount is 0)
    local atomic_amount
    atomic_amount=$(convert_to_atomic "$pool_amount")
    local amount_with_denom="${atomic_amount}${BASE_DENOM}"
    
    print_info "  Amount: $pool_amount tokens ($amount_with_denom)"
    
    # Step 1: Add genesis account (even if amount is 0)
    print_info "  Step 1: Adding account to genesis..."
    if ! infinited genesis add-genesis-account "$module_addr" "$amount_with_denom" --home "$GENESIS_DIR" > /dev/null 2>&1; then
        print_error "  Failed to add genesis account for $pool_name"
        ERRORS+=("ModuleAccount '$pool_name': Failed to add genesis account")
        return 1
    fi
    print_success "  Account added successfully"
    
    # Step 2: Convert to ModuleAccount
    print_info "  Step 2: Converting to ModuleAccount..."
    
    # Custom ModuleAccounts always have empty permissions array
    # Permissions are only effective when registered in permissions.go (code changes required)
    local permissions_json="[]"
    
    # Create temporary file for jq modification
    local temp_file="${GENESIS_FILE}.tmp.$$"
    
    # jq command to replace the account with ModuleAccount
    if ! jq --arg addr "$module_addr" --arg name "$pool_name" --argjson perms "$permissions_json" \
        '(.app_state.auth.accounts[] | select(.address == $addr)) |= (. | del(."@type") | {"@type":"/cosmos.auth.v1beta1.ModuleAccount","base_account":.,"name":$name,"permissions":$perms})' \
        "$GENESIS_FILE" > "$temp_file" 2>/dev/null; then
        print_error "  Failed to convert account to ModuleAccount for $pool_name"
        rm -f "$temp_file"
        ERRORS+=("ModuleAccount '$pool_name': Failed to convert to ModuleAccount")
        return 1
    fi
    
    # Replace original file
    if ! mv "$temp_file" "$GENESIS_FILE"; then
        print_error "  Failed to update genesis file for $pool_name"
        rm -f "$temp_file"
        ERRORS+=("ModuleAccount '$pool_name': Failed to update genesis file")
        return 1
    fi
    
    print_success "  ModuleAccount created successfully"
    
    # Verify the ModuleAccount was created correctly
    if ! module_account_exists "$module_addr"; then
        print_error "  Verification failed: ModuleAccount not found after creation"
        ERRORS+=("ModuleAccount '$pool_name': Verification failed")
        return 1
    fi
    
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    return 0
}

# Validate genesis structure (Cosmos SDK specification compliance)
validate_genesis_structure() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local validate_script="${script_dir}/validate_genesis_structure.sh"
    
    if [[ ! -f "$validate_script" ]]; then
        print_warning "Structure validation script not found, skipping structure validation"
        return 0
    fi
    
    print_info "Validating genesis structure (Cosmos SDK compliance)..."
    if bash "$validate_script" "$GENESIS_FILE" > /dev/null 2>&1; then
        print_success "Genesis structure is valid (Cosmos SDK compliant)"
        return 0
    else
        print_error "Genesis structure validation failed"
        print_info "Run 'bash $validate_script $GENESIS_FILE' for details"
        ERRORS+=("Genesis structure validation failed")
        return 1
    fi
}

# Validate final genesis file (SDK validator)
validate_genesis() {
    print_section "Validating Genesis File"
    
    # First validate structure (Cosmos SDK compliance)
    validate_genesis_structure
    
    # Then validate using SDK validator
    print_info "Running SDK genesis validation..."
    if infinited genesis validate-genesis --home "$GENESIS_DIR" > /dev/null 2>&1; then
        print_success "Genesis file is valid (SDK validation passed)"
        return 0
    else
        print_error "Genesis file validation failed (SDK validation)"
        print_error "Run 'infinited genesis validate-genesis --home $GENESIS_DIR' for details"
        ERRORS+=("Genesis validation failed")
        return 1
    fi
}

# Main function
main() {
    parse_arguments "$@"
    
    local network_upper
    network_upper=$(echo "$NETWORK_MODE" | tr '[:lower:]' '[:upper:]')
    print_section "ModuleAccounts Setup for $network_upper"
    
    print_info "Network: $NETWORK_MODE"
    print_info "Genesis directory: $GENESIS_DIR"
    echo ""
    
    # Load configuration files
    load_config_files
    
    print_info "Genesis file: $GENESIS_FILE"
    
    print_info "Base denom: $BASE_DENOM"
    echo ""
    
    # Process each pool
    # Support both formats: array directly or object with "pools" key
    local pools_count
    if jq -e '.pools' "$MODULE_CONFIG_FILE" > /dev/null 2>&1; then
        # Old format: object with "pools" key
        pools_count=$(jq '.pools | length' "$MODULE_CONFIG_FILE")
        POOLS_SELECTOR='.pools'
    else
        # New format: array directly
        pools_count=$(jq '. | length' "$MODULE_CONFIG_FILE")
        POOLS_SELECTOR='.'
    fi
    
    if [[ $pools_count -eq 0 ]]; then
        print_error "No pools found in module configuration file"
        exit 1
    fi
    
    print_section "Creating ModuleAccounts"
    
    print_info "Found $pools_count ModuleAccount(s) to configure"
    echo ""
    
    for ((i=0; i<pools_count; i++)); do
        local pool_name pool_amount
        
        pool_name=$(jq -r "${POOLS_SELECTOR}[$i].name" "$MODULE_CONFIG_FILE")
        pool_amount=$(jq -r "${POOLS_SELECTOR}[$i].amount_tokens" "$MODULE_CONFIG_FILE")
        
        # Handle null values
        if [[ "$pool_amount" == "null" ]]; then
            pool_amount="0"
        fi
        
        # Custom ModuleAccounts always have empty permissions array
        # Permissions are only effective when registered in permissions.go
        if ! create_module_account "$pool_name" "$pool_amount" ""; then
            # Error already logged in create_module_account
            continue
        fi
        
        echo ""
    done
    
    # Validate genesis file
    validate_genesis
    
    # Print summary
    print_section "Summary"
    
    print_info "Configuration:"
    echo "  - Network: $NETWORK_MODE"
    echo "  - Base denom: $BASE_DENOM"
    echo "  - Total ModuleAccounts: $pools_count"
    echo "  - Successfully created: $SUCCESS_COUNT"
    echo "  - Skipped (already exist): $((TOTAL_COUNT - SUCCESS_COUNT - ${#ERRORS[@]}))"
    echo "  - Errors: ${#ERRORS[@]}"
    echo ""
    
    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        print_error "Errors encountered:"
        for error in "${ERRORS[@]}"; do
            echo "  - $error"
        done
        echo ""
    fi
    
    if [[ $SUCCESS_COUNT -gt 0 ]]; then
        print_success "ModuleAccounts created:"
        for ((i=0; i<pools_count; i++)); do
            local pool_name pool_amount
            pool_name=$(jq -r "${POOLS_SELECTOR}[$i].name" "$MODULE_CONFIG_FILE")
            pool_amount=$(jq -r "${POOLS_SELECTOR}[$i].amount_tokens" "$MODULE_CONFIG_FILE")
            
            if [[ "$pool_amount" == "null" ]]; then
                pool_amount="0"
            fi
            
            local module_addr
            if module_addr=$(go run "${SCRIPT_DIR}/calc_module_addr.go" "$pool_name" 2>/dev/null); then
                if module_account_exists "$module_addr"; then
                    echo "  ✓ $pool_name: $pool_amount tokens (address: $module_addr)"
                fi
            fi
        done
        echo ""
    fi
    
    # Exit with appropriate code
    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        print_error "Script completed with errors"
        exit 1
    elif [[ $SUCCESS_COUNT -eq 0 && $pools_count -gt 0 ]]; then
        print_warning "No ModuleAccounts were created (all may already exist)"
        exit 0
    else
        print_success "All ModuleAccounts configured successfully"
        exit 0
    fi
}

# Run main function
main "$@"
