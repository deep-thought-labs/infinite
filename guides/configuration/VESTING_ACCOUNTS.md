# Vesting Accounts Configuration

**Objective**: Configure vesting accounts in genesis for accounts that need tokens locked with gradual unlock schedules (e.g., multisig wallets).

---

## Overview

Vesting accounts are regular accounts (not ModuleAccounts) with a vesting schedule that controls when tokens can be transferred. Tokens unlock gradually over time according to the configured schedule.

**Key Features**:
- ✅ Can be added using **only the public address** (no keyring required)
- ✅ Perfect for **multisig wallets** where you only have the public address
- ✅ Supports **continuous vesting** (linear unlock) and **delayed vesting** (all at end time)
- ✅ Tokens are locked at genesis and unlock gradually over the configured period

---

## Vesting Account Types

### Continuous Vesting

Tokens unlock **linearly** from `start_time` to `end_time`:

```
Start Time ──────────────────────────> End Time
  0% unlocked                   100% unlocked
```

**Use case**: Gradual release over a period (e.g., 5 years)

### Delayed Vesting

All tokens unlock **at once** when `end_time` is reached:

```
Start ──────────────────────────> End Time
  0% unlocked                   100% unlocked (all at once)
```

**Use case**: All tokens unlock at a specific future date

---

## Configuration Files

### Location

Vesting accounts are configured in JSON files located at:

```
scripts/genesis-configs/
├── mainnet-vesting-accounts.json
├── testnet-vesting-accounts.json
└── creative-vesting-accounts.json
```

### File Structure

Each configuration file follows this structure:

```json
[
  {
    "address": "infinite1<multisig_wallet_address>",
    "amount_tokens": 100000000,
    "vesting_type": "continuous",
    "vesting_start_time": 1735689600,
    "vesting_end_time": 2208988800
  }
]
```

### Field Descriptions

- **`address`**: Public address of the account (bech32 format)
  - Example: `infinite1abc123...`
  - Can be a multisig wallet address
  - **No keyring required** - only the public address is needed

- **`amount_tokens`**: Total amount of tokens to be vested
  - Specified in full token units (not atomic)
  - Will be automatically converted to atomic units (× 10^18) by the script
  - Example: `100000000` means 100 million tokens

- **`vesting_type`**: Type of vesting schedule
  - `"continuous"`: Linear vesting from start_time to end_time
  - `"delayed"`: All tokens unlock at end_time

- **`vesting_start_time`**: Unix timestamp when vesting starts
  - Required for `continuous` vesting
  - Optional for `delayed` vesting (can be 0 or genesis time)
  - Format: Unix epoch seconds (e.g., `1735689600`)

- **`vesting_end_time`**: Unix timestamp when vesting ends
  - Required for both vesting types
  - Format: Unix epoch seconds (e.g., `2208988800`)

---

## Creating Vesting Accounts

### Using the Setup Script

Vesting accounts are created automatically using the `setup_vesting_accounts.sh` script:

```bash
# For mainnet
./scripts/setup_vesting_accounts.sh --network mainnet --genesis-dir ~/.infinited

# For testnet
./scripts/setup_vesting_accounts.sh --network testnet --genesis-dir ~/.infinited

# For creative
./scripts/setup_vesting_accounts.sh --network creative --genesis-dir ~/.infinited
```

### What the Script Does

1. Reads the configuration file for the specified network
2. Validates each address format (bech32)
3. Converts token amounts to atomic units (× 10^18)
4. Validates timestamps (end_time > start_time)
5. Creates vesting accounts using `infinited genesis add-genesis-account` with vesting flags
6. Validates the final genesis file

### Process Flow

```
JSON Config → Validate Address → Convert to atomic (×10^18) → 
Validate Timestamps → Create VestingAccount → Validate Genesis
```

---

## Vesting Account Structure in Genesis

After creation, vesting accounts appear in `genesis.json` as:

### Continuous Vesting Account

```json
{
  "@type": "/cosmos.vesting.v1beta1.ContinuousVestingAccount",
  "base_vesting_account": {
    "base_account": {
      "address": "infinite1<address>",
      "account_number": "3",
      "sequence": "0",
      "pub_key": null
    },
    "original_vesting": [
      {
        "denom": "drop",
        "amount": "100000000000000000000000000"
      }
    ],
    "delegated_free": null,
    "delegated_vesting": null,
    "end_time": "2208988800"
  },
  "start_time": "1735689600"
}
```

### Delayed Vesting Account

```json
{
  "@type": "/cosmos.vesting.v1beta1.DelayedVestingAccount",
  "base_vesting_account": {
    "base_account": {
      "address": "infinite1<address>",
      "account_number": "3",
      "sequence": "0",
      "pub_key": null
    },
    "original_vesting": [
      {
        "denom": "drop",
        "amount": "100000000000000000000000000"
      }
    ],
    "delegated_free": null,
    "delegated_vesting": null,
    "end_time": "2208988800"
  }
}
```

---

## Calculating Timestamps

### Example Timestamps

| Date | Unix Timestamp |
|------|----------------|
| 2025-01-01 00:00:00 UTC | `1735689600` |
| 2025-06-01 00:00:00 UTC | `1751328000` |
| 2030-01-01 00:00:00 UTC | `2208988800` |
| 2035-01-01 00:00:00 UTC | `2682288000` |

### ⚠️ Important: Start Time vs Chain Launch

**Best Practice**: Set `vesting_start_time` to match or be after the **chain launch date**:

- ✅ **Recommended**: `vesting_start_time` = chain launch date (or later)
  - Ensures uniform distribution over the full vesting period
  - No tokens are unlocked at launch
  
- ⚠️ **If start_time < launch_date**:
  - Tokens will be **partially unlocked** at chain launch
  - The remaining tokens unlock over the **remaining time** (not the full period)
  - Example: If 20% of the period has passed, 20% of tokens are unlocked at launch

### Calculating on macOS

```bash
# Calculate timestamp for a specific date
date -j -f "%Y-%m-%d %H:%M:%S" "2025-01-01 00:00:00" "+%s"

# Calculate timestamp for current time + 5 years
date -v+5y "+%s"
```

### Calculating on Linux

```bash
# Calculate timestamp for a specific date
date -d "2025-01-01 00:00:00" +%s

# Calculate timestamp for current time + 5 years
date -d "+5 years" +%s
```

### Online Tools

You can also use online Unix timestamp converters:
- https://www.epochconverter.com/
- https://unixtimestamp.com/

---

## Example: Multisig Wallet with 5-Year Vesting

### Configuration

```json
[
  {
    "address": "infinite1abc123def456ghi789jkl012mno345pqr678stu901vwx234yz",
    "amount_tokens": 100000000,
    "vesting_type": "continuous",
    "vesting_start_time": 1735689600,
    "vesting_end_time": 2208988800
  }
]
```

**Details**:
- **Address**: Multisig wallet public address
- **Amount**: 100 million tokens
- **Type**: Continuous (linear unlock)
- **Start**: 2025-01-01 00:00:00 UTC
- **End**: 2030-01-01 00:00:00 UTC (5 years)

**Unlock Schedule**:
- At start: 0% unlocked
- After 1 year: ~20% unlocked
- After 2.5 years: ~50% unlocked
- At end: 100% unlocked

### Creating the Account

```bash
# 1. Edit the configuration file
vim scripts/genesis-configs/mainnet-vesting-accounts.json

# 2. Run the script
./scripts/setup_vesting_accounts.sh --network mainnet

# 3. Verify in genesis.json
jq '.app_state.auth.accounts[] | select(.base_vesting_account.base_account.address == "infinite1abc...")' ~/.infinited/config/genesis.json
```

---

## Integration with Genesis Creation

Vesting accounts are typically created as part of the genesis setup process:

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

4. **Create Vesting Accounts** (this step):
   ```bash
   ./scripts/setup_vesting_accounts.sh --network mainnet
   ```

5. **Add regular accounts** (validators, team, etc.):
   ```bash
   infinited genesis add-genesis-account validator-1 1000000000000000000000000drop
   ```

6. **Create validators**:
   ```bash
   infinited genesis gentx validator-1 1000000000000000000000000drop --chain-id infinite_421018-1
   infinited genesis collect-gentxs
   ```

7. **Validate genesis**:
   ```bash
   infinited genesis validate-genesis
   ```

### Order Matters

Vesting accounts should be created:
- **After** `customize_genesis.sh` and `setup_module_accounts.sh`
- **Before** adding regular accounts and validators
- This ensures proper account numbering

---

## Vesting Account Behavior

### What Vesting Accounts Can Do

- ✅ **Delegate tokens** to validators (even while locked)
- ✅ **Undelegate tokens** from validators
- ✅ **Receive rewards** from staking
- ✅ **Receive incoming transfers** (tokens are added to the account)

### What Vesting Accounts Cannot Do

- ❌ **Transfer tokens** until they are unlocked
- ❌ **Send tokens** to other accounts until unlocked
- ⚠️ **Withdraw rewards** may be restricted depending on vesting schedule

### Unlock Process

For **continuous vesting**:
- Tokens unlock linearly over time
- At any point, the percentage unlocked = `(current_time - start_time) / (end_time - start_time)`
- Example: If 50% of time has passed, 50% of tokens are unlocked
- **Important**: The calculation uses **block time** (current chain time), not genesis time

For **delayed vesting**:
- 0% unlocked until `end_time`
- 100% unlocked at `end_time` (all at once)

### Start Time Before Chain Launch

**⚠️ IMPORTANT**: If `vesting_start_time` is set to a date **before the chain launch**, the vesting calculation **automatically adjusts**:

**Behavior**:
- ✅ **Vesting begins calculating from the start_time**, even if it's in the past
- ✅ **Distribution is NOT uniform** - it uses the **remaining time** in the vesting period
- ✅ The formula adjusts: `unlocked_percentage = (current_block_time - start_time) / (end_time - start_time)`

**Example Scenario**:
- Chain launches: 2025-06-01 (timestamp: 1751328000)
- Vesting start: 2025-01-01 (timestamp: 1735689600) - **5 months before launch**
- Vesting end: 2030-01-01 (timestamp: 2208988800) - 5 years from start

**What happens**:
- At chain launch (2025-06-01): ~8.3% of tokens are already unlocked (5 months / 60 months)
- Tokens continue unlocking linearly from launch date
- The remaining ~91.7% unlock over the remaining ~54.5 months
- **The vesting period is NOT extended** - it still ends at 2030-01-01

**Recommendation**:
- ✅ **Best practice**: Set `vesting_start_time` to the **chain launch date** or later
- ✅ This ensures vesting begins at launch and distributes uniformly over the full period
- ⚠️ If you set it before launch, tokens will be partially unlocked at launch

---

## Troubleshooting

### Invalid Address Format

**Error**: "Invalid address format"

**Solution**:
- Ensure address is in bech32 format: `infinite1...`
- Address must start with `infinite1` (mainnet/testnet) or `infinite1` (creative)
- Check address length (should be 38-59 characters after prefix)

### End Time Before Start Time

**Error**: "End time must be after start time"

**Solution**:
- Verify `vesting_end_time` > `vesting_start_time`
- Check that timestamps are Unix epoch seconds (not milliseconds)

### Account Already Exists

**Warning**: "Account already exists, skipping..."

**Solution**:
- This is normal if running the script multiple times
- The script is idempotent and skips existing accounts
- To recreate, remove the account from genesis.json first

### Invalid Timestamp Format

**Error**: "Invalid timestamp format"

**Solution**:
- Ensure timestamps are integers (Unix epoch seconds)
- Do not use date strings - convert to Unix timestamp first
- Use the calculation methods shown above

---

## Use Cases

### Multisig Wallet

Perfect for multisig wallets where you only have the public address:

```json
{
  "address": "infinite1<multisig_address>",
  "amount_tokens": 50000000,
  "vesting_type": "continuous",
  "vesting_start_time": 1735689600,
  "vesting_end_time": 2208988800
}
```

### Team/Foundation Wallet

Gradual unlock for team or foundation wallets:

```json
{
  "address": "infinite1<foundation_address>",
  "amount_tokens": 20000000,
  "vesting_type": "continuous",
  "vesting_start_time": 1735689600,
  "vesting_end_time": 2208988800
}
```

### Delayed Release

All tokens unlock at a specific future date:

```json
{
  "address": "infinite1<delayed_address>",
  "amount_tokens": 10000000,
  "vesting_type": "delayed",
  "vesting_start_time": 0,
  "vesting_end_time": 2208988800
}
```

---

## Related Documentation

- **[GENESIS.md](GENESIS.md)** - Complete genesis creation guide
- **[MODULE_ACCOUNTS.md](MODULE_ACCOUNTS.md)** - ModuleAccounts configuration (different from vesting)
- **[TOKEN_SUPPLY.md](TOKEN_SUPPLY.md)** - Understanding token creation
- **[development/SCRIPTS.md](../development/SCRIPTS.md)** - Script documentation

---

## Summary

| Aspect | Details |
|--------|---------|
| **Configuration Location** | `scripts/genesis-configs/*-vesting-accounts.json` |
| **Creation Script** | `scripts/setup_vesting_accounts.sh` |
| **Account Type** | Regular accounts (not ModuleAccounts) |
| **Key Feature** | Can use only public address (no keyring) |
| **Vesting Types** | `continuous` (linear) or `delayed` (all at end) |
| **Token Format** | Full units in JSON, converted to atomic automatically |
| **Integration** | Part of genesis creation workflow (Step 3.5) |

---

**Last Updated**: 2025-01-27
