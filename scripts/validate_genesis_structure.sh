#!/bin/bash
#
# Copyright (c) 2025 Deep Thought Labs
# All rights reserved.
#
# Purpose: Validate genesis.json structure against Cosmos SDK specifications
#          Checks ModuleAccounts, VestingAccounts, and overall structure
#
# Usage: ./scripts/validate_genesis_structure.sh <genesis_file_path>
#
# Exit codes:
#   0 - All validations passed
#   1 - Validation errors found

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}ℹ${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

GENESIS_FILE="${1:-}"
ERRORS=0

if [[ -z "$GENESIS_FILE" ]]; then
    print_error "Genesis file path required"
    echo "Usage: $0 <genesis_file_path>"
    exit 1
fi

if [[ ! -f "$GENESIS_FILE" ]]; then
    print_error "Genesis file not found: $GENESIS_FILE"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    print_error "jq is required but not installed"
    exit 1
fi

print_info "Validating genesis structure: $GENESIS_FILE"
echo ""

# Validation counters
VALIDATION_COUNT=0
PASSED_COUNT=0
FAILED_COUNT=0

# Validate function
validate() {
    local description="$1"
    local jq_expr="$2"
    VALIDATION_COUNT=$((VALIDATION_COUNT + 1))
    
    if jq -e "$jq_expr" "$GENESIS_FILE" > /dev/null 2>&1; then
        print_success "$description"
        PASSED_COUNT=$((PASSED_COUNT + 1))
        return 0
    else
        print_error "$description"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_info "Basic Structure Validation"
print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

validate "Genesis file is valid JSON" "."
validate "Has app_state field" ".app_state != null"
validate "Has chain_id field" ".chain_id != null and .chain_id != \"\""
validate "Has genesis_time field" ".genesis_time != null"

echo ""
print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_info "ModuleAccount Structure Validation"
print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check all ModuleAccounts have correct structure
validate "All ModuleAccounts have @type field" \
    '.app_state.auth.accounts[] | select(."@type" == "/cosmos.auth.v1beta1.ModuleAccount") | ."@type" != null'

validate "All ModuleAccounts have base_account" \
    '.app_state.auth.accounts[] | select(."@type" == "/cosmos.auth.v1beta1.ModuleAccount") | .base_account != null'

validate "All ModuleAccounts have base_account.address" \
    '.app_state.auth.accounts[] | select(."@type" == "/cosmos.auth.v1beta1.ModuleAccount") | .base_account.address != null and .base_account.address != ""'

validate "All ModuleAccounts have base_account.account_number" \
    '.app_state.auth.accounts[] | select(."@type" == "/cosmos.auth.v1beta1.ModuleAccount") | .base_account.account_number != null'

validate "All ModuleAccounts have base_account.sequence" \
    '.app_state.auth.accounts[] | select(."@type" == "/cosmos.auth.v1beta1.ModuleAccount") | .base_account.sequence != null'

validate "All ModuleAccounts have name field" \
    '.app_state.auth.accounts[] | select(."@type" == "/cosmos.auth.v1beta1.ModuleAccount") | .name != null and .name != ""'

validate "All ModuleAccounts have permissions field" \
    '.app_state.auth.accounts[] | select(."@type" == "/cosmos.auth.v1beta1.ModuleAccount") | .permissions != null'

validate "ModuleAccount base_account.pub_key is null (correct for ModuleAccounts)" \
    '.app_state.auth.accounts[] | select(."@type" == "/cosmos.auth.v1beta1.ModuleAccount") | .base_account.pub_key == null'

validate "ModuleAccount base_account.sequence is \"0\" (correct for genesis)" \
    '.app_state.auth.accounts[] | select(."@type" == "/cosmos.auth.v1beta1.ModuleAccount") | .base_account.sequence == "0"'

echo ""
print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_info "ContinuousVestingAccount Structure Validation"
print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check all ContinuousVestingAccounts have correct structure
validate "All ContinuousVestingAccounts have @type field" \
    '.app_state.auth.accounts[] | select(."@type" == "/cosmos.vesting.v1beta1.ContinuousVestingAccount") | ."@type" != null'

validate "All ContinuousVestingAccounts have base_vesting_account" \
    '.app_state.auth.accounts[] | select(."@type" == "/cosmos.vesting.v1beta1.ContinuousVestingAccount") | .base_vesting_account != null'

validate "All ContinuousVestingAccounts have base_vesting_account.base_account" \
    '.app_state.auth.accounts[] | select(."@type" == "/cosmos.vesting.v1beta1.ContinuousVestingAccount") | .base_vesting_account.base_account != null'

validate "All ContinuousVestingAccounts have base_vesting_account.base_account.address" \
    '.app_state.auth.accounts[] | select(."@type" == "/cosmos.vesting.v1beta1.ContinuousVestingAccount") | .base_vesting_account.base_account.address != null and .base_vesting_account.base_account.address != ""'

validate "All ContinuousVestingAccounts have base_vesting_account.base_account.account_number" \
    '.app_state.auth.accounts[] | select(."@type" == "/cosmos.vesting.v1beta1.ContinuousVestingAccount") | .base_vesting_account.base_account.account_number != null'

validate "All ContinuousVestingAccounts have base_vesting_account.base_account.sequence" \
    '.app_state.auth.accounts[] | select(."@type" == "/cosmos.vesting.v1beta1.ContinuousVestingAccount") | .base_vesting_account.base_account.sequence != null'

validate "All ContinuousVestingAccounts have base_vesting_account.original_vesting" \
    '.app_state.auth.accounts[] | select(."@type" == "/cosmos.vesting.v1beta1.ContinuousVestingAccount") | .base_vesting_account.original_vesting != null'

validate "All ContinuousVestingAccounts have base_vesting_account.end_time" \
    '.app_state.auth.accounts[] | select(."@type" == "/cosmos.vesting.v1beta1.ContinuousVestingAccount") | .base_vesting_account.end_time != null and .base_vesting_account.end_time != ""'

validate "All ContinuousVestingAccounts have start_time field" \
    '.app_state.auth.accounts[] | select(."@type" == "/cosmos.vesting.v1beta1.ContinuousVestingAccount") | .start_time != null and .start_time != ""'

validate "ContinuousVestingAccount start_time < end_time" \
    '.app_state.auth.accounts[] | select(."@type" == "/cosmos.vesting.v1beta1.ContinuousVestingAccount") | (.start_time | tonumber) < (.base_vesting_account.end_time | tonumber)'

validate "ContinuousVestingAccount base_account.pub_key is null (correct for vesting accounts)" \
    '.app_state.auth.accounts[] | select(."@type" == "/cosmos.vesting.v1beta1.ContinuousVestingAccount") | .base_vesting_account.base_account.pub_key == null'

validate "ContinuousVestingAccount base_account.sequence is \"0\" (correct for genesis)" \
    '.app_state.auth.accounts[] | select(."@type" == "/cosmos.vesting.v1beta1.ContinuousVestingAccount") | .base_vesting_account.base_account.sequence == "0"'

validate "ContinuousVestingAccount has delegated_free field" \
    '.app_state.auth.accounts[] | select(."@type" == "/cosmos.vesting.v1beta1.ContinuousVestingAccount") | .base_vesting_account.delegated_free != null'

validate "ContinuousVestingAccount has delegated_vesting field" \
    '.app_state.auth.accounts[] | select(."@type" == "/cosmos.vesting.v1beta1.ContinuousVestingAccount") | .base_vesting_account.delegated_vesting != null'

echo ""
print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_info "Account-Balance Consistency Validation"
print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check that all accounts in auth.accounts have corresponding balances
check_module_account_balances() {
    VALIDATION_COUNT=$((VALIDATION_COUNT + 1))
    local module_addrs
    module_addrs=$(jq -r '.app_state.auth.accounts[] | select(."@type" == "/cosmos.auth.v1beta1.ModuleAccount") | .base_account.address' "$GENESIS_FILE")
    local missing_balances=0
    while IFS= read -r addr; do
        [[ -z "$addr" ]] && continue
        if ! jq -e --arg addr "$addr" '.app_state.bank.balances[] | select(.address == $addr)' "$GENESIS_FILE" > /dev/null 2>&1; then
            print_error "ModuleAccount $addr missing bank balance"
            missing_balances=$((missing_balances + 1))
        fi
    done <<< "$module_addrs"
    if [[ $missing_balances -gt 0 ]]; then
        FAILED_COUNT=$((FAILED_COUNT + 1))
        ERRORS=$((ERRORS + 1))
        return 1
    else
        print_success "All ModuleAccounts have corresponding bank balances"
        PASSED_COUNT=$((PASSED_COUNT + 1))
        return 0
    fi
}

check_vesting_account_balances() {
    VALIDATION_COUNT=$((VALIDATION_COUNT + 1))
    local vesting_addrs
    vesting_addrs=$(jq -r '.app_state.auth.accounts[] | select(."@type" == "/cosmos.vesting.v1beta1.ContinuousVestingAccount") | .base_vesting_account.base_account.address' "$GENESIS_FILE")
    local missing_balances=0
    while IFS= read -r addr; do
        [[ -z "$addr" ]] && continue
        if ! jq -e --arg addr "$addr" '.app_state.bank.balances[] | select(.address == $addr)' "$GENESIS_FILE" > /dev/null 2>&1; then
            print_error "VestingAccount $addr missing bank balance"
            missing_balances=$((missing_balances + 1))
        fi
    done <<< "$vesting_addrs"
    if [[ $missing_balances -gt 0 ]]; then
        FAILED_COUNT=$((FAILED_COUNT + 1))
        ERRORS=$((ERRORS + 1))
        return 1
    else
        print_success "All ContinuousVestingAccounts have corresponding bank balances"
        PASSED_COUNT=$((PASSED_COUNT + 1))
        return 0
    fi
}

check_module_account_balances
check_vesting_account_balances

# Check balance amounts match original_vesting for vesting accounts
check_vesting_balance_amounts() {
    VALIDATION_COUNT=$((VALIDATION_COUNT + 1))
    local vesting_accounts
    vesting_accounts=$(jq -c '.app_state.auth.accounts[] | select(."@type" == "/cosmos.vesting.v1beta1.ContinuousVestingAccount")' "$GENESIS_FILE")
    local mismatch_count=0
    while IFS= read -r account; do
        [[ -z "$account" ]] && continue
        local addr
        addr=$(echo "$account" | jq -r '.base_vesting_account.base_account.address')
        local vesting_denom
        vesting_denom=$(echo "$account" | jq -r '.base_vesting_account.original_vesting[0].denom')
        local vesting_amount
        vesting_amount=$(echo "$account" | jq -r '.base_vesting_account.original_vesting[0].amount')
        local balance_denom
        balance_denom=$(jq -r --arg addr "$addr" '.app_state.bank.balances[] | select(.address == $addr) | .coins[0].denom' "$GENESIS_FILE")
        local balance_amount
        balance_amount=$(jq -r --arg addr "$addr" '.app_state.bank.balances[] | select(.address == $addr) | .coins[0].amount' "$GENESIS_FILE")
        
        if [[ "$vesting_denom" != "$balance_denom" ]] || [[ "$vesting_amount" != "$balance_amount" ]]; then
            print_error "VestingAccount $addr: original_vesting ($vesting_denom:$vesting_amount) != balance ($balance_denom:$balance_amount)"
            mismatch_count=$((mismatch_count + 1))
        fi
    done <<< "$vesting_accounts"
    if [[ $mismatch_count -gt 0 ]]; then
        FAILED_COUNT=$((FAILED_COUNT + 1))
        ERRORS=$((ERRORS + 1))
        return 1
    else
        print_success "All VestingAccount balances match original_vesting amounts"
        PASSED_COUNT=$((PASSED_COUNT + 1))
        return 0
    fi
}

check_vesting_balance_amounts

echo ""
print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_info "Data Type Validation"
print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Validate data types
validate "account_number fields are strings" \
    '.app_state.auth.accounts[] | .base_account.account_number? // .base_vesting_account.base_account.account_number? | type == "string"'

validate "sequence fields are strings" \
    '.app_state.auth.accounts[] | .base_account.sequence? // .base_vesting_account.base_account.sequence? | type == "string"'

validate "end_time is string (Unix timestamp)" \
    '.app_state.auth.accounts[] | select(."@type" == "/cosmos.vesting.v1beta1.ContinuousVestingAccount") | .base_vesting_account.end_time | type == "string"'

validate "start_time is string (Unix timestamp)" \
    '.app_state.auth.accounts[] | select(."@type" == "/cosmos.vesting.v1beta1.ContinuousVestingAccount") | .start_time | type == "string"'

validate "original_vesting amounts are strings" \
    '.app_state.auth.accounts[] | select(."@type" == "/cosmos.vesting.v1beta1.ContinuousVestingAccount") | .base_vesting_account.original_vesting[0].amount | type == "string"'

echo ""
print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_info "Summary"
print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

print_info "Total validations: $VALIDATION_COUNT"
print_success "Passed: $PASSED_COUNT"
if [[ $FAILED_COUNT -gt 0 ]]; then
    print_error "Failed: $FAILED_COUNT"
    echo ""
    exit 1
else
    print_success "All validations passed!"
    echo ""
    exit 0
fi
