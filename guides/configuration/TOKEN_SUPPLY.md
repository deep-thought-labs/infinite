# Token Creation in Genesis - Understanding Supply

**Objective**: Understand how tokens are created in Genesis and the fundamental relationship between supply and balances in the Cosmos SDK.

## The Key Question

> **Where do the tokens assigned to accounts in Genesis come from?**

---

## Answer: Tokens Are "Created from Nothing" in Genesis

### ✅ **Tokens Do NOT Come from Any Previous Place**

In Genesis, tokens are created **ex nihilo** (from nothing). There is no previous "central bank" or external source.

---

## Context: Project Tokenomics

**Important**: This document explains the **technical mechanism** of how tokens are created in Genesis. 

For information about:
- **Actual tokenomics structure** (6 pools: strategic_delegation, security_rewards, etc.)
- **ModuleAccounts configuration** and their purposes
- **Token distribution** according to the project's economic model

See **[MODULE_ACCOUNTS.md](MODULE_ACCOUNTS.md)**.

**Note**: In Infinite Drive, all tokens are **locked at genesis** and released gradually over **42 years**, controlled by the DAO. The ModuleAccounts represent the total allocation pools, but actual liquid supply is managed separately through the release mechanism.

### How it works:

1. **`infinited init`** creates an **empty** Genesis (no supply, no balances)
2. **`infinited genesis add-genesis-account`** adds accounts with tokens
3. **The command automatically updates total `supply`**

---

## Practical Example

### Step 1: Initial Genesis (empty)
```json
{
  "app_state": {
    "bank": {
      "supply": [],           // ← Empty
      "balances": []          // ← Empty
    }
  }
}
```

### Step 2: Add account with tokens
```bash
infinited genesis add-genesis-account validator-1 1000000000000000000000drop
```

### Step 3: Genesis automatically updated
```json
{
  "app_state": {
    "bank": {
      "supply": [
        {
          "denom": "drop",
          "amount": "1000000000000000000000"  // ← Created automatically
        }
      ],
      "balances": [
        {
          "address": "infinite1...",
          "coins": [
            {
              "denom": "drop",
              "amount": "1000000000000000000000"  // ← Assigned to account
            }
          ]
        }
      ]
    }
  }
}
```

---

## How Does It Work Internally?

### 1. `add-genesis-account` does three things:

1. **Adds the account** to `app_state.auth.accounts`
2. **Adds the balance** to `app_state.bank.balances`
3. **Updates the supply** in `app_state.bank.supply`

### 2. Supply is calculated automatically:

```go
// Pseudocode of what add-genesis-account does
func addGenesisAccount(address, amount) {
    // 1. Add account
    genesis.Auth.Accounts = append(genesis.Auth.Accounts, newAccount(address))
    
    // 2. Add balance
    genesis.Bank.Balances = append(genesis.Bank.Balances, Balance{
        Address: address,
        Coins:   []Coin{{Denom: "drop", Amount: amount}}
    })
    
    // 3. Update total supply
    genesis.Bank.Supply = calculateTotalSupply(genesis.Bank.Balances)
}
```

---

## Supply Rules

### ✅ **Fundamental Rule**: `supply = sum of all balances`

```json
{
  "supply": [
    {"denom": "drop", "amount": "5000000000000000000000"}  // Total
  ],
  "balances": [
    {"address": "addr1", "coins": [{"denom": "drop", "amount": "2000000000000000000000"}]},
    {"address": "addr2", "coins": [{"denom": "drop", "amount": "3000000000000000000000"}]}
  ]
}
// 2000 + 3000 = 5000 ✓
```

### ❌ **Common error**: Supply ≠ sum of balances
If this occurs, `infinited genesis validate-genesis` will fail.

---

## Complete Process for Validators

### 1. Create validator account
```bash
infinited keys add validator-1 --keyring-backend file
```

### 2. Add account with funds (creates tokens from nothing)
```bash
infinited genesis add-genesis-account validator-1 1000000000000000000000drop
# ↑ This creates 1000 42 from nothing and assigns them to validator-1
```

### 3. Create gentx (uses existing tokens)
```bash
infinited genesis gentx validator-1 1000000000000000000000drop \
  --chain-id infinite_421018-1
# ↑ This uses the 1000 42 that validator-1 already has for staking
```

### 4. Collect gentxs
```bash
infinited genesis collect-gentxs
# ↑ This adds the validator to Genesis using already assigned tokens
```

---

## How Many Tokens to Create Initially?

### ModuleAccounts (Tokenomics Pools)

For mainnet and testnet, ModuleAccounts are configured according to the project's tokenomics structure. These are created using the `setup_module_accounts.sh` script:

```bash
# ModuleAccounts are configured in JSON files:
# - scripts/genesis-configs/mainnet-module-accounts.json
# - scripts/genesis-configs/testnet-module-accounts.json

# Create ModuleAccounts automatically:
./scripts/setup_module_accounts.sh --network mainnet
```

**ModuleAccounts configured** (see [MODULE_ACCOUNTS.md](MODULE_ACCOUNTS.md) for details):
- `strategic_delegation` (40%) - Never spent, only delegated
- `security_rewards` (25%) - Validator + staker rewards
- `perpetual_rd` (15%) - Institutional funding
- `fish_bootstrap` (10%) - Seed liquidity pools
- `privacy_resistance` (7%) - ZK, anti-censura R&D
- `community_growth` (3%) - Grants, education, integrations

**Note**: All tokens are locked at genesis and released gradually over 42 years. The ModuleAccounts represent the total allocation pools.

### Regular Accounts (Validators, Team, etc.)

For regular accounts (validators, team wallets, etc.), you add them manually:

```bash
# Example: Validator account
infinited genesis add-genesis-account validator-1 1000000000000000000000000drop   # 1M tokens

# Example: Team account
infinited genesis add-genesis-account team-wallet 10000000000000000000000000drop  # 10M tokens
```

**Important**: 
- Decide token amounts carefully based on your network's needs
- Validators need tokens to create `gentx` for staking
- Total supply will be automatically calculated from all balances

---

## Important Considerations

### 1. **No initial inflation**
- Tokens are created once in Genesis
- After that, there's only inflation if configured in the `mint` module
- In Infinite Drive, tokens are locked at genesis and released gradually over 42 years

### 2. **Initial distribution**
- Carefully decide who receives how many tokens
- Genesis tokens are the only ones that will exist initially
- ModuleAccounts represent tokenomics pools (see [MODULE_ACCOUNTS.md](MODULE_ACCOUNTS.md))
- Regular accounts (validators, team) are added separately

### 3. **Validators need tokens for staking**
- A validator must have tokens to make `gentx`
- Tokens are "burned" (go to staking module) during `gentx`
- Validators receive tokens through inflation rewards over time

### 4. **Total supply must be realistic**
- Don't create too many tokens (future inflation)
- Don't create too few (insufficient liquidity)
- In Infinite Drive, ModuleAccounts hold the total allocation (100M tokens), but most are locked initially

### 5. **ModuleAccounts vs Regular Accounts**
- **ModuleAccounts**: Created via `setup_module_accounts.sh`, represent tokenomics pools
- **Regular Accounts**: Created via `add-genesis-account`, for validators, team, etc.
- Both contribute to total supply: `supply = sum of all balances`

---

## Useful Commands

### View current supply:
```bash
jq '.app_state.bank.supply' genesis.json
```

### View balances:
```bash
jq '.app_state.bank.balances' genesis.json
```

### Verify that supply = sum of balances:
```bash
# Sum all balances
jq '[.app_state.bank.balances[].coins[] | select(.denom=="drop") | .amount | tonumber] | add' genesis.json

# Compare with supply
jq '.app_state.bank.supply[] | select(.denom=="drop") | .amount | tonumber' genesis.json
```

### Count accounts:
```bash
jq '.app_state.bank.balances | length' genesis.json
```

---

## Summary

| Question | Answer |
|----------|--------|
| **Where do tokens come from?** | Created from nothing in Genesis |
| **Who creates them?** | The `add-genesis-account` command |
| **When are they created?** | When you run `add-genesis-account` |
| **Is there a limit?** | No, but you must be responsible with the amount |
| **Can they be created later?** | Only via inflation (mint module) or new modules |

**Conclusion**: Genesis tokens are the "initial currency" of your blockchain. They are created when you assign them to accounts, and that's the only way to have tokens from block 0.

---

## Related Documentation

- **[MODULE_ACCOUNTS.md](MODULE_ACCOUNTS.md)** - Complete ModuleAccounts structure and tokenomics configuration
- **[GENESIS.md](GENESIS.md)** - Step-by-step guide for creating genesis files
- **[development/SCRIPTS.md](../development/SCRIPTS.md)** - Scripts documentation including `setup_module_accounts.sh`

---

**Last Updated**: 2025-01-27
