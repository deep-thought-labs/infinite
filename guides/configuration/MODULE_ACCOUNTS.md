# ModuleAccounts Configuration

**Objective**: Understand how ModuleAccounts are structured and configured for Infinite Drive networks according to the project's tokenomics.

---

## Overview

ModuleAccounts are special accounts managed by modules in the Cosmos SDK. In Infinite Drive, they represent the tokenomics pools defined in the project's economic model. All tokens are locked at genesis and released gradually over 42 years, controlled by the DAO.

---

## ModuleAccounts Structure

### Mainnet and Testnet

The following ModuleAccounts are configured for mainnet and testnet networks:

| ModuleAccount Name | Pool | Percentage | Purpose | Initial Amount* |
|-------------------|------|------------|---------|-----------------|
| `strategic_delegation` | A | 40% | Never spent — only delegated | 40 tokens |
| `security_rewards` | B | 25% | Validator + staker rewards | 25 tokens |
| `perpetual_rd` | C | 15% | Institutional funding (Deep Thought Labs) | 15 tokens |
| `fish_bootstrap` | D | 10% | Seed liquidity pools | 10 tokens |
| `privacy_resistance` | E | 7% | ZK, anti-censura R&D | 7 tokens |
| `community_growth` | F | 3% | Grants, education, integrations | 3 tokens |
| **TOTAL** | - | **100%** | - | **100 tokens** |

*Note: Initial amounts shown are for reference (100 tokens total). Actual genesis amounts may differ based on tokenomics requirements.

### Creative Network

The creative network uses a simplified structure:

| ModuleAccount Name | Purpose | Initial Amount |
|-------------------|---------|----------------|
| `faucet` | Development faucet for testing | 10,000,000 tokens |

---

## Configuration Files

### Location

ModuleAccounts are configured in JSON files located at:

```
scripts/genesis-configs/
├── mainnet-module-accounts.json
├── testnet-module-accounts.json
└── creative-module-accounts.json
```

### File Structure

Each configuration file follows this structure:

```json
[
  {
    "name": "strategic_delegation",
    "amount_tokens": 40
  },
  {
    "name": "security_rewards",
    "amount_tokens": 25
  },
  {
    "name": "perpetual_rd",
    "amount_tokens": 15
  },
  {
    "name": "fish_bootstrap",
    "amount_tokens": 10
  },
  {
    "name": "privacy_resistance",
    "amount_tokens": 7
  },
  {
    "name": "community_growth",
    "amount_tokens": 3
  }
]
```

### Field Descriptions

- **`name`**: The module account name (used to calculate deterministic address)
  - Must be lowercase with underscores
  - Must match Cosmos SDK naming conventions
  - Example: `strategic_delegation`, `security_rewards`

- **`amount_tokens`**: Initial balance in full token units
  - Specified as a number (not string)
  - Will be automatically converted to atomic units (× 10^18) by the script
  - Example: `40` means 40 full tokens

---

## Token Denomination

### How It Works

1. **In JSON files**: Use full token units (e.g., `40`)
2. **Script conversion**: Automatically multiplies by `10^18` to get atomic units
3. **Denom addition**: Automatically adds the base denom based on network:
   - Mainnet: `drop`
   - Testnet: `tdrop`
   - Creative: `cdrop`
4. **Final format**: `40000000000000000000drop` (40 tokens in atomic units)

### Example Conversion

```bash
# Input in JSON:
{
  "name": "strategic_delegation",
  "amount_tokens": 40
}

# Script converts to:
atomic_amount = 40 * 10^18 = 40000000000000000000
final_amount = "40000000000000000000drop"
```

---

## Creating ModuleAccounts

### Using the Setup Script

ModuleAccounts are created automatically using the `setup_module_accounts.sh` script:

```bash
# For mainnet
./scripts/setup_module_accounts.sh --network mainnet --genesis-dir ~/.infinited

# For testnet
./scripts/setup_module_accounts.sh --network testnet --genesis-dir ~/.infinited

# For creative
./scripts/setup_module_accounts.sh --network creative --genesis-dir ~/.infinited
```

### What the Script Does

1. Reads the configuration file for the specified network
2. Calculates deterministic addresses for each ModuleAccount (using SHA256 of the name)
3. Converts token amounts to atomic units
4. Adds accounts to genesis using `infinited genesis add-genesis-account`
5. Converts accounts to ModuleAccount type using `jq`
6. Validates the final genesis file

### Process Flow

```
JSON Config → Read amount_tokens → Convert to atomic (×10^18) → 
Add denom → Create BaseAccount → Convert to ModuleAccount → Validate
```

---

## ModuleAccount Structure in Genesis

After creation, ModuleAccounts appear in `genesis.json` as:

```json
{
  "@type": "/cosmos.auth.v1beta1.ModuleAccount",
  "base_account": {
    "address": "infinite1<deterministic_address>",
    "account_number": "3",
    "sequence": "0",
    "pub_key": null
  },
  "name": "strategic_delegation",
  "permissions": []
}
```

### Key Points

- **`@type`**: Always `/cosmos.auth.v1beta1.ModuleAccount`
- **`base_account.address`**: Deterministically calculated from the name
- **`name`**: The module account name (matches JSON config)
- **`permissions`**: Always empty array `[]` for custom ModuleAccounts
  - Permissions are only effective when registered in `infinited/config/permissions.go`
  - Requires code changes to enable minting/burning capabilities

---

## Referencing ModuleAccounts On-Chain

### By Name

ModuleAccounts are identified by their name:

- `strategic_delegation`
- `security_rewards`
- `perpetual_rd`
- `fish_bootstrap`
- `privacy_resistance`
- `community_growth`

### By Address

Each ModuleAccount has a deterministic address calculated from its name:

```bash
# Calculate address (using internal SDK function)
name = "strategic_delegation"
hash = SHA256(name)
address = bech32_encode("infinite", hash[:20])
```

### Querying ModuleAccounts

```bash
# Query all module accounts
infinited query auth module-accounts

# Query balance of a specific ModuleAccount
infinited query bank balances infinite1<module_address>

# Query community pool (distribution module)
infinited query distribution community-pool
```

### Using in Governance Proposals

```json
{
  "messages": [
    {
      "@type": "/cosmos.bank.v1beta1.MsgSend",
      "from_address": "infinite1<strategic_delegation_address>",
      "to_address": "infinite1<recipient>",
      "amount": [{"denom": "drop", "amount": "1000000000000000000"}]
    }
  ]
}
```

---

## Permissions and Capabilities

### Current Status

All custom ModuleAccounts have **empty permissions** (`[]`) by default because they are not registered in `infinited/config/permissions.go`.

### What This Means

- ❌ **Cannot mint tokens** (no `minter` permission)
- ❌ **Cannot burn tokens** (no `burner` permission)
- ✅ **Can hold tokens** (standard account functionality)
- ✅ **Can send/receive tokens** (via governance or direct transfers)

### Enabling Permissions

To enable minting or burning capabilities:

1. **Register in code**: Add to `infinited/config/permissions.go`:
   ```go
   var maccPerms = map[string][]string{
       // ... existing modules ...
       "strategic_delegation": {authtypes.Minter, authtypes.Burner},
   }
   ```

2. **Rebuild**: Recompile the binary with the new permissions

3. **Note**: This requires a code change and cannot be done via configuration alone

---

## Special Considerations

### Strategic Delegation Pool

The `strategic_delegation` pool has a special restriction: **"Never spent — only delegated"**.

This means:
- ✅ Can delegate tokens to validators
- ❌ Should not transfer tokens directly
- ⚠️ Requires custom logic to enforce this restriction (not enforced by default)

### Token Release Schedule

According to tokenomics:
- All tokens are **locked at genesis**
- Released gradually over **42 years**
- Controlled by the **DAO** from block 1
- At launch: **practically 0% liquid tokens** in circulation

The ModuleAccounts represent the total allocation, but actual liquid supply is managed separately through the release mechanism.

---

## Integration with Genesis Creation

ModuleAccounts are typically created as part of the genesis setup process:

### Complete Workflow

1. **Initialize genesis**:
   ```bash
   infinited init my-moniker --chain-id infinite_421018-1
   ```

2. **Customize genesis**:
   ```bash
   ./scripts/customize_genesis.sh --network mainnet
   ```

3. **Create ModuleAccounts**:
   ```bash
   ./scripts/setup_module_accounts.sh --network mainnet
   ```

4. **Validate genesis**:
   ```bash
   infinited genesis validate-genesis
   ```

### Order Matters

ModuleAccounts should be created **after** running `customize_genesis.sh` but **before** adding validator accounts, to ensure proper account numbering.

---

## Troubleshooting

### ModuleAccount Already Exists

If you see "ModuleAccount already exists, skipping...":

- This is normal if running the script multiple times
- The script is idempotent and skips existing accounts
- To recreate, remove the account from genesis.json first

### Invalid JSON Format

If you get JSON parsing errors:

- Verify the JSON syntax is valid
- Ensure `amount_tokens` is a number (not a string)
- Check for trailing commas

### Address Calculation Fails

If address calculation fails:

- Ensure Go is installed (`go version`)
- Verify `calc_module_addr.go` exists in the scripts directory
- Check that the module name follows naming conventions (lowercase, underscores)

---

## Related Documentation

- **[GENESIS.md](GENESIS.md)** - Complete genesis creation guide
- **[TOKEN_SUPPLY.md](TOKEN_SUPPLY.md)** - Understanding how tokens are created in Genesis and the supply/balance relationship
- **[development/SCRIPTS.md](../development/SCRIPTS.md)** - Script documentation
- **Tokenomics**: See project documentation for complete tokenomics details

---

## Summary

| Aspect | Details |
|--------|---------|
| **Configuration Location** | `scripts/genesis-configs/*-module-accounts.json` |
| **Creation Script** | `scripts/setup_module_accounts.sh` |
| **Total ModuleAccounts** | 6 (mainnet/testnet), 1 (creative) |
| **Permissions** | Empty by default (requires code changes) |
| **Token Format** | Full units in JSON, converted to atomic automatically |
| **Address Calculation** | Deterministic (SHA256 of name) |
| **Integration** | Part of genesis creation workflow |

---

**Last Updated**: 2025-01-27
