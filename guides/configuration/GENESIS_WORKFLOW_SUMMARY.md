# Genesis Creation Workflow - Complete Summary

**Objective**: Quick reference for the complete genesis creation workflow with all steps.

---

## Complete Workflow Steps

### Step 1: Initialize Genesis
```bash
infinited init my-moniker --chain-id infinite_421018-1 --home ~/.infinited
```

### Step 2: Apply Infinite Drive Customizations
```bash
./scripts/customize_genesis.sh --network mainnet
```
- Configures all module parameters
- Sets network-specific chain ID
- Configures staking, governance, mint, distribution, etc.

### Step 3: Configure ModuleAccounts (Optional)
```bash
./scripts/setup_module_accounts.sh --network mainnet
```
- Creates tokenomics pools (strategic_delegation, security_rewards, etc.)
- Configuration: `scripts/genesis-configs/mainnet-module-accounts.json`
- See: [MODULE_ACCOUNTS.md](MODULE_ACCOUNTS.md)

### Step 3.5: Configure Vesting Accounts (Optional)
```bash
./scripts/setup_vesting_accounts.sh --network mainnet
```
- Creates vesting accounts (multisig wallets with locked tokens)
- Configuration: `scripts/genesis-configs/mainnet-vesting-accounts.json`
- Can use only public address (no keyring required)
- See: [VESTING_ACCOUNTS.md](VESTING_ACCOUNTS.md)

### Step 4: Create and Fund Regular Accounts
```bash
# Create account
infinited keys add my-account --keyring-backend file --home ~/.infinited

# Fund account
infinited genesis add-genesis-account my-account 100000000000000000000drop \
  --keyring-backend file --home ~/.infinited
```

### Step 5: Create Validator
```bash
# Create gentx
infinited genesis gentx my-account 1000000000000000000drop \
  --chain-id infinite_421018-1 \
  --commission-rate "0.10" \
  --keyring-backend file --home ~/.infinited

# Collect gentxs
infinited genesis collect-gentxs --home ~/.infinited
```

### Step 6: Validate Genesis
```bash
infinited genesis validate-genesis --home ~/.infinited
```

### Step 7: Distribute Genesis File
- Copy `genesis.json` to all nodes
- All nodes must have the same genesis file

### Step 8: Start the Network
```bash
infinited start --chain-id infinite_421018-1 --evm.evm-chain-id 421018
```

---

## Account Types Summary

| Account Type | Script/Command | Configuration File | Key Feature |
|--------------|---------------|-------------------|-------------|
| **ModuleAccounts** | `setup_module_accounts.sh` | `*-module-accounts.json` | Tokenomics pools, deterministic addresses |
| **Vesting Accounts** | `setup_vesting_accounts.sh` | `*-vesting-accounts.json` | Locked tokens, gradual unlock, public address only |
| **Regular Accounts** | `infinited genesis add-genesis-account` | Manual (keyring) | Standard accounts, require keyring |
| **Validators** | `infinited genesis gentx` | Manual (keyring) | Validator accounts with staking |

---

## Quick Reference: When to Use Each

- **ModuleAccounts**: Tokenomics pools (strategic_delegation, security_rewards, etc.)
- **Vesting Accounts**: Multisig wallets or accounts needing locked tokens
- **Regular Accounts**: Team wallets, validators (before gentx), test accounts
- **Validators**: After funding regular accounts, create gentx and collect

---

**See [GENESIS.md](GENESIS.md) for complete detailed guide.**
