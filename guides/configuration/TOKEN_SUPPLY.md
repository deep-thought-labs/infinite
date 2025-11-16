# Token Supply in Genesis - Where Do Tokens Come From?

## The Key Question

> **Where do the tokens assigned to accounts in Genesis come from?**

---

## Answer: Tokens Are "Created from Nothing" in Genesis

### ✅ **Tokens Do NOT Come from Any Previous Place**

In Genesis, tokens are created **ex nihilo** (from nothing). There is no previous "central bank" or external source.

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

### For Mainnet (example):

```bash
# Main team account (for operations)
infinited genesis add-genesis-account team-wallet 10000000000000000000000000drop  # 10M 42

# Validator 1
infinited genesis add-genesis-account validator-1 1000000000000000000000000drop   # 1M 42

# Validator 2  
infinited genesis add-genesis-account validator-2 1000000000000000000000000drop   # 1M 42

# Validator 3
infinited genesis add-genesis-account validator-3 1000000000000000000000000drop   # 1M 42

# Total supply: 13M 42
```

### For Testnet (example):

```bash
# Test accounts (more generous)
infinited genesis add-genesis-account test-account-1 100000000000000000000000000drop  # 100M 42
infinited genesis add-genesis-account test-account-2 100000000000000000000000000drop  # 100M 42
infinited genesis add-genesis-account validator-1 10000000000000000000000000drop     # 10M 42
```

---

## Important Considerations

### 1. **No initial inflation**
- Tokens are created once in Genesis
- After that, there's only inflation if configured in the `mint` module

### 2. **Initial distribution**
- Carefully decide who receives how many tokens
- Genesis tokens are the only ones that will exist initially

### 3. **Validators need tokens for staking**
- A validator must have tokens to make `gentx`
- Tokens are "burned" (go to staking module) during `gentx`

### 4. **Total supply must be realistic**
- Don't create too many tokens (future inflation)
- Don't create too few (insufficient liquidity)

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
