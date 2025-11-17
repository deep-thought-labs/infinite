# Genesis Configuration for Production Mainnet

This document details all aspects you must consider when creating the definitive Genesis file for the stable Infinite Drive Mainnet, assuming no validators exist at this time.

**⚠️ IMPORTANT**: The examples in the guides show how to populate the genesis with dummy accounts or dummy transactions for development. This document focuses on what's needed for a **real production Mainnet**.

## Table of Contents

1. [Where are Genesis Parameters Configured?](#where-are-genesis-parameters-configured) - **READ THIS FIRST**
2. [Basic Chain Information](#basic-chain-information)
3. [Cosmos SDK Module Configuration](#cosmos-sdk-module-configuration)
4. [Infinite Drive Specific Module Configuration](#infinite-drive-specific-module-configuration)
5. [Consensus Parameters (CometBFT/Tendermint)](#consensus-parameters-cometbfttendermint)
6. [Initial Validator Configuration](#initial-validator-configuration)
7. [Account and Balance Configuration](#account-and-balance-configuration)
8. [Security and Economic Parameters](#security-and-economic-parameters)
9. [Genesis Verification](#genesis-verification)
10. [Recommended Creation Process](#recommended-creation-process)

---

## Where are Genesis Parameters Configured?

**⚠️ Critical Question**: Are configurations done in the project code or directly in the Genesis JSON file?

The answer is: **BOTH**. It depends on the type of parameter:

### 🔷 Parameters from Code (Default Values)

When you run `infinited init`, the system generates an initial Genesis using default values from the code:

1. **Cosmos SDK default values**:
   - Standard modules (staking, bank, governance, mint, slashing) have default values defined in Cosmos SDK
   - These values are hardcoded in Cosmos SDK source code
   - Example: `unbonding_time: "1814400s"`, `max_validators: 100`, governance periods of `172800s` (2 days)

2. **Infinite Drive specific values** (modified in code):
   - **EVM Precompiles**: Enabled automatically from `infinited/genesis.go`
   - **EVM Denomination**: The default denom for EVM is configured in code (`testutil/constants/constants.go`: `ExampleAttoDenom = "drop"`)
   - **ERC20 Token pairs**: Initial configuration in `infinited/genesis.go`

**Code location**:
- `infinited/app.go` → `DefaultGenesis()`: Generates base Genesis
- `infinited/genesis.go`: Defines specific values for EVM, ERC20, Mint, FeeMarket modules
- Cosmos SDK: Default values in standard modules

### 🔷 Parameters Configured in Genesis JSON

After running `infinited init`, you must **apply Infinite Drive customizations** to the `genesis.json` file:

**⚠️ RECOMMENDED APPROACH**: Use the dedicated script:
```bash
./scripts/customize_genesis.sh ~/.infinited/config/genesis.json
```

This automatically applies all required customizations (see below for details).

**ALTERNATIVE (Manual)**: If you prefer manual editing:

1. **Denominations (Denoms)**:
   ```bash
   # Example using jq (manual approach):
   jq '.app_state["staking"]["params"]["bond_denom"]="drop"' genesis.json > temp.json && mv temp.json genesis.json
   jq '.app_state["evm"]["params"]["evm_denom"]="drop"' genesis.json > temp.json && mv temp.json genesis.json
   jq '.app_state["mint"]["params"]["mint_denom"]="drop"' genesis.json > temp.json && mv temp.json genesis.json
   ```
   **Where**: Directly in the Genesis JSON file

2. **Governance Parameters**:
   - Voting periods (change from `172800s` to appropriate values)
   - Minimum deposits
   - Thresholds (quorum, threshold, veto_threshold)
   ```bash
   # Example: change governance periods
   sed -i.bak 's/"max_deposit_period": "172800s"/"max_deposit_period": "172800s"/g' genesis.json
   sed -i.bak 's/"voting_period": "172800s"/"voting_period": "172800s"/g' genesis.json
   ```
   **Where**: Directly in the Genesis JSON file

3. **Token Metadata**:
   ```bash
   jq '.app_state["bank"]["denom_metadata"]=[{...}]' genesis.json > temp.json && mv temp.json genesis.json
   ```
   **Where**: Directly in the Genesis JSON file

4. **Initial Balances and Accounts**:
   ```bash
   infinited genesis add-genesis-account ADDRESS AMOUNTdrop
   ```
   **Where**: Using CLI commands that modify the Genesis JSON

5. **Initial Validators**:
   ```bash
   infinited genesis gentx validator AMOUNT --chain-id CHAIN_ID
   infinited genesis collect-gentxs
   ```
   **Where**: Using CLI commands that add transactions to the Genesis JSON

6. **Consensus Parameters**:
   ```bash
   jq '.consensus.params.block.max_gas="10000000"' genesis.json > temp.json && mv temp.json genesis.json
   ```
   **Where**: Directly in the Genesis JSON file

### 📋 Summary: Configuration by Parameter Type

| Parameter Type | Where It's Configured | Can It Be Changed Without Recompiling? |
|----------------|----------------------|----------------------------------------|
| **Cosmos SDK default values** | Cosmos SDK source code | ❌ No (hardcoded in Cosmos SDK) |
| **Available module structure** | `infinited/app.go` | ❌ No (requires modifying code and recompiling) |
| **Enabled EVM precompiles** | `infinited/genesis.go` | ✅ Yes (modify JSON directly) |
| **Denominations (bond_denom, evm_denom)** | Genesis JSON | ✅ Yes (using jq or manual editing) |
| **Governance parameters** | Genesis JSON | ✅ Yes (using jq, sed or manual editing) |
| **Token metadata** | Genesis JSON | ✅ Yes (using jq or manual editing) |
| **Initial balances** | Genesis JSON (via CLI) | ✅ Yes (using `genesis add-genesis-account`) |
| **Initial validators** | Genesis JSON (via CLI) | ✅ Yes (using `genesis gentx` and `collect-gentxs`) |
| **Consensus parameters** | Genesis JSON | ✅ Yes (using jq or manual editing) |

### 🔧 Typical Configuration Process

1. **Generate initial Genesis**:
   ```bash
   infinited init my-moniker --chain-id infinite_421018-1
   ```
   This generates `~/.infinited/config/genesis.json` with default values from code.

2. **⚠️ REQUIRED: Apply Infinite Drive Customizations**:
   ```bash
   # Use the dedicated script to apply all Infinite Drive personalizations
   ./scripts/customize_genesis.sh ~/.infinited/config/genesis.json
   ```
   This script automatically applies:
   - All module denominations (staking, mint, gov, evm) → "drop"
   - Complete token metadata for Improbability (42) token
   - EVM static precompiles configuration
   - ERC20 native token pair
   - Consensus max_gas parameter
   - Creates automatic backup before modifications
   
   **⚠️ IMPORTANT**: This step is REQUIRED. The genesis generated by `infinited init` uses default Cosmos SDK values (like "stake" denomination). You MUST run `customize_genesis.sh` to apply Infinite Drive customizations.

3. **Add Accounts and Validators** (if needed):
   - Use CLI commands to add accounts: `infinited genesis add-genesis-account`
   - Use CLI commands to add validators: `infinited genesis gentx` and `collect-gentxs`
   - Manually edit governance periods if needed (for production, use longer periods than development)

4. **Validate**:
   ```bash
   infinited genesis validate-genesis
   ```

**Practical examples**:
- **Automated approach**: See `scripts/customize_genesis.sh` for the standalone customization script
- **Development setup**: See `local_node.sh` lines 233-256 for how genesis is customized in development (includes account creation)

### ⚠️ Important Limitations

1. **You cannot change**:
   - Which Cosmos SDK modules are available (requires modifying `app.go` and recompiling)
   - The basic Genesis structure (defined in code)
   - Available precompiles (though you can enable/disable them in JSON)

2. **You can change**:
   - Any parameter value within existing modules
   - Balances, accounts, validators
   - Metadata, denoms, periods

### 🎯 Recommendation for Mainnet

1. **DO NOT modify code** unless you need to add modules or new functionality
2. **DO modify the Genesis JSON** for all parameters specific to your Mainnet
3. **Document changes** you make manually for future reference
4. **Always validate** after each modification using `infinited genesis validate-genesis`

---

## Basic Chain Information

### 1. Chain ID

You must define two Chain IDs that must be consistent:

- **Cosmos Chain ID**: Format `{name}_####-{version}`
  - Example: `infinite_421018-1`
  - This is the chain identifier in Cosmos SDK

- **EVM Chain ID**: Integer according to EIP-155
  - Example: `421018`
  - This is the identifier used in EVM contracts and wallets

**Considerations**:
- The EVM Chain ID must be unique and not collide with other known networks
- Once established, it CANNOT change without a hard fork
- The Cosmos Chain ID can change the version (`-1`, `-2`, etc.) in upgrades

### 2. Denominations (Denoms)

Native token configuration:

- **Base Denom**: The smallest unit (equivalent to "wei" in Ethereum)
  - Example: `drop`
  - Used for all internal operations

- **Display Denom**: The unit shown to users
  - Example: `Improbability`
  - Equivalent to "ETH" in Ethereum
  - **IMPORTANT**: Must start with a letter (cannot start with a number)

- **Decimals**: Number of decimals
  - Example: `18` (standard for EVM compatibility)
  - 1 Improbability = 10^18 drop

**Token Metadata** (for Bank module):
```json
{
  "description": "Improbability Token — Project 42: Sovereign, Perpetual, DAO-Governed",
  "denom_units": [
    {
      "denom": "drop",
      "exponent": 0,
      "aliases": []
    },
    {
      "denom": "Improbability",
      "exponent": 18,
      "aliases": ["improbability"]
    }
  ],
  "base": "drop",
  "display": "Improbability",
  "name": "Improbability",
  "symbol": "42",
  "uri": "https://assets.infinitedrive.xyz/tokens/42/icon.png"
}
```

### 3. Bech32 Prefix

The prefix for Cosmos addresses:
- Example: `infinite`
- Used in addresses like: `infinite1abc...`

---

## Cosmos SDK Module Configuration

### 1. Staking Module

**Critical parameters**:

```json
{
  "app_state": {
    "staking": {
      "params": {
        "bond_denom": "drop",                    // MUST be the base denom
        "historical_entries": 10000,             // Delegation history
        "max_entries": 7,                        // Maximum entries per delegator
        "max_validators": 100,                   // Maximum active validators
        "min_commission_rate": "0.000000000000000000",  // Minimum commission (%)
        "unbonding_time": "1814400s"             // Unbonding time (21 days)
      }
    }
  }
}
```

**Production considerations**:
- `bond_denom`: Must exactly match the configured base denom
- `max_validators`: Defines how many validators can be active simultaneously
- `unbonding_time`: Time it takes for a stake to be available after undelegating
- `historical_entries`: Higher = more history but more disk space

### 2. Bank Module

**Configuration**:
```json
{
  "app_state": {
    "bank": {
      "params": {
        "send_enabled": [],                     // Empty list = all enabled
        "default_send_enabled": true            // Allows sending by default
      },
      "denom_metadata": [ /* token metadata here */ ],
      "supply": [ /* initial total supply */ ],
      "balances": [ /* account balances */ ]
    }
  }
}
```

**Considerations**:
- Total `supply` must equal the sum of all `balances`
- You must include the balance of the `bonded_tokens_pool` module account with initially staked tokens

### 3. Governance Module

**Critical parameters for production**:

```json
{
  "app_state": {
    "gov": {
      "params": {
        "min_deposit": [
          {
            "denom": "drop",
            "amount": "1000000000000000000"      // 1 TEA (adjust as needed)
          }
        ],
        "max_deposit_period": "172800s",        // 2 days (DO NOT use 30s as in dev)
        "voting_period": "172800s",             // 2 days (DO NOT use 30s as in dev)
        "quorum": "0.334000000000000000",       // 33.4% minimum participation
        "threshold": "0.500000000000000000",    // 50% to approve
        "veto_threshold": "0.334000000000000000", // 33.4% to veto
        "expedited_min_deposit": [
          {
            "denom": "drop",
            "amount": "5000000000000000000"      // 5 TEA for expedited proposals
          }
        ],
        "expedited_voting_period": "86400s"     // 1 day for expedited
      }
    }
  }
}
```

**⚠️ CRITICAL DIFFERENCES WITH DEVELOPMENT**:
- In development, 30s periods are used for quick testing
- In production you MUST use realistic periods (2 days is standard)
- `min_deposit` must be high enough to prevent spam but accessible
- Threshold values affect protocol governance

### 4. Mint Module

**Configuration**:
```json
{
  "app_state": {
    "mint": {
      "params": {
        "mint_denom": "drop",
        "inflation_rate_change": "0.130000000000000000",  // Annual inflation change
        "inflation_max": "0.200000000000000000",           // Maximum 20% annual
        "inflation_min": "0.070000000000000000",           // Minimum 7% annual
        "goal_bonded": "0.670000000000000000",             // 67% staked target
        "blocks_per_year": "6311520"                       // Blocks per year (approx)
      },
      "minter": {
        "inflation": "0.130000000000000000",
        "annual_provisions": "0"
      }
    }
  }
}
```

**Considerations**:
- If you don't want initial inflation, configure `inflation_min` and `inflation_max` to 0
- `blocks_per_year` is calculated based on target block time
- Inflation rewards validators and delegators

### 5. Slashing Module

**Critical security parameters**:

```json
{
  "app_state": {
    "slashing": {
      "params": {
        "signed_blocks_window": "10000",                    // Monitored block window
        "min_signed_per_window": "0.050000000000000000",   // 5% minimum signed
        "downtime_jail_duration": "600s",                  // 10 minutes jail for downtime
        "slash_fraction_double_sign": "0.050000000000000000", // 5% slash for double sign
        "slash_fraction_downtime": "0.000100000000000000"  // 0.01% slash for downtime
      }
    }
  }
}
```

**⚠️ SECURITY PARAMETERS**:
- `slash_fraction_double_sign`: Penalty for signing two blocks at the same height
- `slash_fraction_downtime`: Penalty for being offline
- `downtime_jail_duration`: Time a validator remains in jail
- Adjust these values according to your security policy

---

## Infinite Drive Specific Module Configuration

### 1. EVM Module (vm)

**Essential configuration**:

```json
{
  "app_state": {
    "evm": {
      "params": {
        "evm_denom": "drop",                    // MUST match base denom
        "enable_create": true,                  // Allows creating contracts
        "enable_call": true,                     // Allows calling contracts
        "chain_config": {
          "chain_id": "421018",                  // EVM Chain ID as string
          "homestead_block": "0",
          "dao_fork_support": false,
          "eip150_block": "0",
          "eip155_block": "0",
          "eip158_block": "0",
          "byzantium_block": "0",
          "constantinople_block": "0",
          "petersburg_block": "0",
          "istanbul_block": "0",
          "muir_glacier_block": "0",
          "berlin_block": "0",
          "london_block": "0",
          "arrow_glacier_block": "0",
          "gray_glacier_block": "0",
          "merge_netsplit_block": "0",
          "shanghai_time": "0",
          "cancun_time": "0"
        },
        "active_static_precompiles": [
          "0x0000000000000000000000000000000000000100",  // ECRecover
          "0x0000000000000000000000000000000000000400",  // SHA256
          "0x0000000000000000000000000000000000000800",  // Bank precompile
          "0x0000000000000000000000000000000000000801",  // Staking precompile
          "0x0000000000000000000000000000000000000802",  // Distribution precompile
          "0x0000000000000000000000000000000000000803",  // Governance precompile
          "0x0000000000000000000000000000000000000804",  // ERC20 precompile
          "0x0000000000000000000000000000000000000805",  // IBC precompile
          "0x0000000000000000000000000000000000000806",  // Slashing precompile
          "0x0000000000000000000000000000000000000807"   // Precision Bank precompile
        ]
      },
      "accounts": [],                              // Preinstalled contracts (if any)
      "preinstalls": []                            // Dynamic precompiles
    }
  }
}
```

**Considerations**:
- `evm_denom` MUST be exactly equal to staking's `bond_denom`
- Active precompiles define which Cosmos functionalities are available from EVM
- `chain_config` defines EVM version (should be compatible with Berlin/London)

### 2. ERC20 Module

**Configuration**:
```json
{
  "app_state": {
    "erc20": {
      "params": {
        "enable_erc20": true,                     // Enables ERC20 <-> Cosmos conversion
        "enable_evm_hook": true                   // Enables EVM hooks
      },
      "token_pairs": [],                          // Initial token pairs
      "native_precompiles": [
        "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"  // Native ETH address
      ],
      "dynamic_precompiles": []                   // Dynamic precompiles
    }
  }
}
```

**Considerations**:
- `native_precompiles` includes the special address to represent native token in EVM
- `token_pairs` can be added later via governance if needed

### 3. Fee Market Module

**Configuration**:
```json
{
  "app_state": {
    "feemarket": {
      "params": {
        "base_fee": "0",                         // Initial base fee (0 = no base fee)
        "learning_rate": "0.125000000000000000",  // Learning rate
        "max_priority_price": "0",                // Maximum priority price
        "min_base_fee": "0",                     // Minimum base fee
        "min_gas_multiplier": "0.500000000000000000",  // Minimum multiplier
        "no_base_fee": true                      // If true, no dynamic base fee
      },
      "block_gas": "0"
    }
  }
}
```

**Considerations**:
- If `no_base_fee: true`, there will be no EIP-1559 style fee market
- For production, you may want to enable dynamic base fee (`no_base_fee: false`)
- This affects how gas fees are calculated

### 4. Precision Bank Module

This module is configured automatically but may have specific parameters according to your setup.

---

## Consensus Parameters (CometBFT/Tendermint)

### 1. Block Parameters

```json
{
  "consensus_params": {
    "block": {
      "max_bytes": "22020096",                   // ~21MB max per block
      "max_gas": "10000000",                     // 10M gas per block
      "time_iota_ms": "1000"                     // Time precision
    }
  }
}
```

**Production considerations**:
- `max_gas`: Adjust according to expected processing capacity
- `max_bytes`: Higher = more transactions but more network load
- In development, lower values are used for faster blocks

### 2. Evidence

```json
{
  "consensus_params": {
    "evidence": {
      "max_age_num_blocks": "100000",           // Maximum age in blocks
      "max_age_duration": "172800000000000",    // Maximum age in nanoseconds
      "max_bytes": "1048576"                     // Maximum evidence size
    }
  }
}
```

### 3. Validators

```json
{
  "consensus_params": {
    "validator": {
      "pub_key_types": ["ed25519"]              // Validation key type
    }
  }
}
```

---

## Initial Validator Configuration

### ⚠️ IMPORTANT: No Existing Validators

Since you're creating a Mainnet without previous validators, you must:

1. **Do not include validators in initial genesis**:
   - Do not use `genesis gentx` to add validator transactions to genesis
   - Genesis must be "clean" without active validators

2. **Or create initial validators through launch process**:
   - Initial validators must be created **after** genesis launch
   - Use a `create-validator` transaction in the first block or via governance

3. **Expected structure**:
```json
{
  "app_state": {
    "staking": {
      "validators": [],                          // Empty initially
      "delegations": [],                         // Empty initially
      "unbonding_delegations": [],
      "redelegations": []
    }
  }
}
```

**Alternative: Genesis with Initial Validators**

If you need validators from block 0:

```bash
# For each initial validator:
# 1. Each operator must generate their keys
infinited keys add validator --keyring-backend file

# 2. Each operator creates their gentx
infinited genesis gentx validator \
  --amount 1000000000000000000000drop \
  --commission-rate "0.10" \
  --commission-max-rate "0.20" \
  --commission-max-change-rate "0.01" \
  --min-self-delegation "1" \
  --chain-id infinite_421018-1

# 3. Collect all gentxs
infinited genesis collect-gentxs
```

**Validator parameters**:
- `commission-rate`: Initial commission (e.g., 10%)
- `commission-max-rate`: Maximum allowed (e.g., 20%)
- `commission-max-change-rate`: Maximum change per time (e.g., 1%)
- `min-self-delegation`: Minimum validator must self-delegate

---

## Account and Balance Configuration

### 1. Initial Accounts

You must define which accounts will have initial balances:

```json
{
  "app_state": {
    "auth": {
      "accounts": [
        {
          "@type": "/cosmos.auth.v1beta1.BaseAccount",
          "address": "infinite1...",
          "pub_key": null,
          "account_number": "0",
          "sequence": "0"
        }
      ]
    },
    "bank": {
      "balances": [
        {
          "address": "infinite1...",
          "coins": [
            {
              "denom": "drop",
              "amount": "1000000000000000000000000"  // 1M TEA
            }
          ]
        }
      ],
      "supply": [
        {
          "denom": "drop",
          "amount": "10000000000000000000000000"     // Total sum
        }
      ]
    }
  }
}
```

**Critical considerations**:
- Total `supply` MUST equal the sum of all `balances`
- Include the `bonded_tokens_pool` account if there are initially staked tokens
- Only include accounts that really need initial funds
- **DO NOT use test/dummy accounts** as in development

### 2. Initial Token Distribution

You must decide:
- **How to distribute initial tokens**: Airdrops, sales, treasury, initial validators, etc.
- **Initial total supply**: How many tokens to create from the start
- **Development reserves**: Funds for future development (governance controlled)

### 3. Module Accounts

Automatic system accounts (you don't need to add them manually):
- `bonded_tokens_pool`: For staked tokens
- `not_bonded_tokens_pool`: For unbonding tokens
- `evm`: For EVM module
- `erc20`: For ERC20 module
- And other modules as needed

---

## Security and Economic Parameters

### 1. Gas Parameters

```json
{
  "app_state": {
    "evm": {
      "params": {
        // ... other parameters ...
      }
    }
  }
}
```

**Considerations**:
- Define `minimum-gas-prices` in each node's `app.toml` (not in genesis)
- Precompiles have internally configured gas costs

### 2. Limits and Security

- **Max gas per block**: Already configured in `consensus_params`
- **Unbonding times**: Already configured in `staking.params`
- **Slashing parameters**: Already configured in `slashing.params`

### 3. Inflation and Economy

- Configured in `mint.params`
- Decide if you want inflation from the start or start with 0

---

## Genesis Verification

### Validation Command

```bash
infinited genesis validate-genesis --home /path/to/config
```

This command verifies:
- ✅ Denom consistency
- ✅ Parameter validation
- ✅ Correct JSON structure
- ✅ Balance sums vs supply

### Manual Checklist

Before launching, verify:

- [ ] All denoms are consistent (`bond_denom`, `evm_denom`, `mint_denom`)
- [ ] Total `supply` equals sum of `balances`
- [ ] Chain IDs (Cosmos and EVM) are correctly configured
- [ ] Governance parameters are realistic (DO NOT copy 30s periods from dev)
- [ ] Slashing parameters are appropriate for production
- [ ] No dummy or test accounts
- [ ] Required precompiles are enabled
- [ ] Token metadata is complete and correct
- [ ] Voting periods are appropriate (days, not seconds)
- [ ] Initial validators (if any) are correctly configured

---

## Recommended Creation Process

### Step 1: Preparation

```bash
# 1. Initialize basic structure
infinited init my-moniker --chain-id infinite_421018-1

# This creates initial genesis in ~/.infinited/config/genesis.json
```

### Step 2: Apply Infinite Drive Customizations (REQUIRED)

**⚠️ CRITICAL**: After `infinited init`, the generated genesis uses default Cosmos SDK values (e.g., "stake" denomination). You MUST apply Infinite Drive customizations:

```bash
# Apply all Infinite Drive personalizations automatically
./scripts/customize_genesis.sh ~/.infinited/config/genesis.json
```

This script applies:
- All module denominations → "drop" (staking, mint, gov, evm)
- Complete token metadata for Improbability (42) token
- EVM static precompiles
- ERC20 native token pair
- Consensus max_gas parameter
- Creates automatic backup

**Alternative (manual)**: If you prefer manual editing, you can use `jq` commands as shown in the script, but using the script is recommended for consistency.

### Step 3: Add Initial Accounts

```bash
# For each account that needs funds:
infinited genesis add-genesis-account ADDRESS AMOUNTdrop \
  --keyring-backend file \
  --home /path/to/config
```

### Step 4: Configure Validators (if applicable)

If you want validators from block 0:
```bash
# Collect validator gentxs
infinited genesis collect-gentxs --home /path/to/config
```

If you DO NOT want initial validators:
- **DO NOT run `collect-gentxs`**
- Genesis will have no validators and they must be created later

### Step 5: Validate

```bash
infinited genesis validate-genesis --home /path/to/config
```

### Step 6: Distribute

The `genesis.json` file must be distributed to ALL network nodes before launch.

### Node Startup (always specifying both Chain IDs)

```bash
# Mainnet
infinited start \
  --chain-id infinite_421018-1 \
  --evm.evm-chain-id 421018

# Testnet
infinited start \
  --chain-id infinite_421018001-1 \
  --evm.evm-chain-id 421018001
```

---

## Key Differences: Development vs Production

| Aspect | Development | Production |
|--------|-------------|------------|
| Governance Periods | 30s (fast) | 2 days (secure) |
| Gas Prices | 0drop (free) | Realistic value |
| Initial Accounts | Dummy/test | Real/legitimate |
| Validators | Automatic scripts | Secure manual process |
| Precompiles | All enabled | Only necessary |
| Slashing | Low values | Production values |
| Token Metadata | Example | Real and complete |

---

## Additional Resources

- [Cosmos SDK Genesis Documentation](https://docs.cosmos.network/main/building-modules/genesis)
- [CometBFT Genesis Documentation](https://docs.cometbft.com/v0.38/core/genesis)
- Production Guide: `guides/deployment/PRODUCTION.md`
- Example file for development: `local_node.sh` (lines 233-256)

---

**Final Note**: This document is based on analysis of Infinite Drive source code. Always verify that these parameters are appropriate for your specific use case and consider security audits before Mainnet launch.
