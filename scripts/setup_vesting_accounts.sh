#!/bin/bash
#
# Copyright (c) 2025 Deep Thought Labs
# All rights reserved.
#
# This file is part of the Infinite Drive blockchain tooling.
#
# Purpose: Configure Vesting Accounts in genesis.json for mainnet, testnet, or creative networks.
#          Adds accounts with vesting schedules using only public addresses (no keyring required).
#
# This script EXECUTES the commands directly and modifies the genesis file.
#
# Usage: ./scripts/setup_vesting_accounts.sh --network <mainnet|testnet|creative> [--genesis-dir <path>]
#
# Example:
#   ./scripts/setup_vesting_accounts.sh --network mainnet
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
VESTING_CONFIG_FILE=""
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
                echo ""
                echo "Example:"
                echo "  $0 --network mainnet"
                echo "  $0 --network testnet --genesis-dir ~/.infinited-testnet"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    if [[ -z "$network" ]]; then
        print_error "Network mode is required. Use --network <mainnet|testnet|creative>"
        exit 1
    fi
    
    case "$network" in
        mainnet|testnet|creative)
            NETWORK_MODE="$network"
            ;;
        *)
            print_error "Invalid network mode: $network. Must be one of: mainnet, testnet, creative"
            exit 1
            ;;
    esac
    
    if [[ -n "$genesis_dir" ]]; then
        GENESIS_DIR="$genesis_dir"
    fi
}

# Get script directory
get_script_dir() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
}

# Initialize configuration
init_config() {
    NETWORK_CONFIG_FILE="${SCRIPT_DIR}/genesis-configs/${NETWORK_MODE}.json"
    VESTING_CONFIG_FILE="${SCRIPT_DIR}/genesis-configs/${NETWORK_MODE}-vesting-accounts.json"
    GENESIS_FILE="${GENESIS_DIR}/config/genesis.json"
    
    if [[ ! -f "$NETWORK_CONFIG_FILE" ]]; then
        print_error "Network configuration file not found: $NETWORK_CONFIG_FILE"
        exit 1
    fi
    
    if [[ ! -f "$VESTING_CONFIG_FILE" ]]; then
        print_error "Vesting accounts configuration file not found: $VESTING_CONFIG_FILE"
        print_info "Create the file with the following structure:"
        echo '[{"address": "infinite1...", "amount_tokens": 1000000, "vesting_type": "continuous", "vesting_start_time": 1735689600, "vesting_end_time": 2208988800}]'
        exit 1
    fi
    
    if [[ ! -f "$GENESIS_FILE" ]]; then
        print_error "Genesis file not found: $GENESIS_FILE"
        print_info "Run 'infinited init' first to create the genesis file"
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

# Validate address format (basic bech32 check)
validate_address() {
    local address="$1"
    # Check for infinite1 prefix and valid bech32 format (38-59 chars after prefix)
    if [[ ! "$address" =~ ^infinite1[a-z0-9]{38,59}$ ]]; then
        return 1
    fi
    return 0
}

# Check if account already exists in genesis
account_exists() {
    local address="$1"
    jq -e --arg addr "$address" '.app_state.auth.accounts[] | select(.address == $addr or (.base_account.address == $addr))' "$GENESIS_FILE" > /dev/null 2>&1
}

# Create vesting account
create_vesting_account() {
    local address="$1"
    local amount_tokens="$2"
    local vesting_type="$3"
    local vesting_start_time="$4"
    local vesting_end_time="$5"
    
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
    
    print_info "Processing Vesting Account: $address"
    
    # Validate address
    if ! validate_address "$address"; then
        print_error "  Invalid address format: $address"
        ERRORS+=("Vesting Account $TOTAL_COUNT: Invalid address format")
        return 1
    fi
    
    # Check if account already exists
    if account_exists "$address"; then
        print_warning "  Account '$address' already exists, skipping..."
        return 0
    fi
    
    # Convert to atomic units
    local atomic_amount
    atomic_amount=$(convert_to_atomic "$amount_tokens")
    local amount_with_denom="${atomic_amount}${BASE_DENOM}"
    
    print_info "  Amount: $amount_tokens tokens ($amount_with_denom)"
    print_info "  Vesting Type: $vesting_type"
    print_info "  Start Time: $vesting_start_time ($(date -r "$vesting_start_time" 2>/dev/null || echo "invalid timestamp"))"
    print_info "  End Time: $vesting_end_time ($(date -r "$vesting_end_time" 2>/dev/null || echo "invalid timestamp"))"
    
    # Validate timestamps
    if [[ ! "$vesting_start_time" =~ ^[0-9]+$ ]] || [[ ! "$vesting_end_time" =~ ^[0-9]+$ ]]; then
        print_error "  Invalid timestamp format"
        ERRORS+=("Vesting Account '$address': Invalid timestamp format")
        return 1
    fi
    
    if [[ "$vesting_end_time" -le "$vesting_start_time" ]]; then
        print_error "  End time must be after start time"
        ERRORS+=("Vesting Account '$address': End time must be after start time")
        return 1
    fi
    
    # Build command based on vesting type
    # Note: Using array to avoid eval and ensure proper quoting
    local cmd_args=(
        "genesis" "add-genesis-account"
        "$address"
        "$amount_with_denom"
        "--vesting-amount" "$amount_with_denom"
    )
    
    if [[ "$vesting_type" == "continuous" ]]; then
        cmd_args+=("--vesting-start-time" "$vesting_start_time" "--vesting-end-time" "$vesting_end_time")
    elif [[ "$vesting_type" == "delayed" ]]; then
        cmd_args+=("--vesting-end-time" "$vesting_end_time")
    else
        print_error "  Invalid vesting type: $vesting_type (must be 'continuous' or 'delayed')"
        ERRORS+=("Vesting Account '$address': Invalid vesting type")
        return 1
    fi
    
    cmd_args+=("--home" "$GENESIS_DIR")
    
    # Execute command
    print_info "  Adding vesting account to genesis..."
    if ! infinited "${cmd_args[@]}" > /dev/null 2>&1; then
        print_error "  Failed to add vesting account"
        ERRORS+=("Vesting Account '$address': Failed to add account")
        return 1
    fi
    
    print_success "  Vesting account created successfully"
    
    # Verify the account was created
    if ! account_exists "$address"; then
        print_error "  Verification failed: Account not found after creation"
        ERRORS+=("Vesting Account '$address': Verification failed")
        return 1
    fi
    
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    return 0
}

# Validate final genesis file
validate_genesis() {
    print_section "Validating Genesis File"
    
    if ! infinited genesis validate-genesis --home "$GENESIS_DIR" > /dev/null 2>&1; then
        print_error "Genesis validation failed"
        print_info "Run 'infinited genesis validate-genesis --home $GENESIS_DIR' for details"
        return 1
    fi
    
    print_success "Genesis file is valid"
    return 0
}

# Main execution
main() {
    parse_arguments "$@"
    get_script_dir
    
    # Convert network mode to uppercase (compatible with all shells)
    local network_upper
    network_upper=$(echo "$NETWORK_MODE" | tr '[:lower:]' '[:upper:]')
    print_section "Vesting Accounts Setup for $network_upper"
    
    print_info "Network: $NETWORK_MODE"
    print_info "Genesis directory: $GENESIS_DIR"
    print_info "Genesis file: $GENESIS_FILE"
    print_info "Base denom: $BASE_DENOM"
    
    init_config
    
    print_section "Creating Vesting Accounts"
    
    # Read vesting accounts from JSON
    local accounts_count
    accounts_count=$(jq '. | length' "$VESTING_CONFIG_FILE")
    
    if [[ "$accounts_count" -eq 0 ]]; then
        print_warning "No vesting accounts found in configuration file"
        return 0
    fi
    
    print_info "Found $accounts_count vesting account(s) to configure"
    echo ""
    
    # Process each vesting account
    for ((i=0; i<accounts_count; i++)); do
        local address amount_tokens vesting_type vesting_start_time vesting_end_time
        
        address=$(jq -r ".[$i].address" "$VESTING_CONFIG_FILE")
        amount_tokens=$(jq -r ".[$i].amount_tokens" "$VESTING_CONFIG_FILE")
        vesting_type=$(jq -r ".[$i].vesting_type" "$VESTING_CONFIG_FILE")
        vesting_start_time=$(jq -r ".[$i].vesting_start_time" "$VESTING_CONFIG_FILE")
        vesting_end_time=$(jq -r ".[$i].vesting_end_time" "$VESTING_CONFIG_FILE")
        
        # Handle null values
        if [[ "$address" == "null" ]] || [[ -z "$address" ]]; then
            print_error "Account $((i+1)): Missing or invalid address"
            ERRORS+=("Account $((i+1)): Missing address")
            continue
        fi
        
        if [[ "$amount_tokens" == "null" ]]; then
            amount_tokens="0"
        fi
        
        if [[ "$vesting_type" == "null" ]]; then
            vesting_type="continuous"
        fi
        
        if [[ "$vesting_start_time" == "null" ]]; then
            print_error "Account '$address': Missing vesting_start_time"
            ERRORS+=("Account '$address': Missing vesting_start_time")
            continue
        fi
        
        if [[ "$vesting_end_time" == "null" ]]; then
            print_error "Account '$address': Missing vesting_end_time"
            ERRORS+=("Account '$address': Missing vesting_end_time")
            continue
        fi
        
        if ! create_vesting_account "$address" "$amount_tokens" "$vesting_type" "$vesting_start_time" "$vesting_end_time"; then
            # Error already logged in create_vesting_account
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
    echo "  - Total Vesting Accounts: $accounts_count"
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
        exit 1
    fi
    
    if [[ $SUCCESS_COUNT -gt 0 ]]; then
        print_success "Vesting accounts created successfully!"
        print_info "Next steps:"
        echo "  1. Review the genesis file: $GENESIS_FILE"
        echo "  2. Validate genesis: infinited genesis validate-genesis --home $GENESIS_DIR"
        echo "  3. Continue with validator setup or other genesis configuration"
    fi
}

# Run main function
main "$@"
