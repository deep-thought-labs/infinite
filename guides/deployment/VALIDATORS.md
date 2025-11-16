# Validators in Genesis - Frequently Asked Questions

## Can a Chain Start Without Validators?

**❌ NO**. A Cosmos SDK chain **requires at least one validator** in Genesis to produce blocks.

---

## What Happens If Genesis Has No Validators?

If you try to start a chain with a Genesis without validators:

1. **Genesis is technically valid** - `infinited genesis validate-genesis` may pass ✅
2. **BUT the chain will NOT produce blocks** - CometBFT cannot reach consensus without a validator set
3. **The node will start** but will be "stuck" waiting for blocks that will never arrive

### Expected behavior:

```
$ infinited start \
  --chain-id infinite_421018-1 \
  --evm.evm-chain-id 421018
...
I[2025-01-XX|...] starting ABCI with CometBFT
I[2025-01-XX|...] Starting node
...
# ⚠️ Here the node is running but does NOT produce blocks
# CometBFT will wait infinitely for validators that will never appear
```

---

## What to Do to Make the Chain Work?

### Option 1: Validators from Block 0 (Recommended for Mainnet)

Add validators to Genesis **before launch**:

```bash
# 1. Initialize the node first
infinited init my-moniker --chain-id infinite_421018-1 --home ~/.infinited

# 2. Configure Genesis with setup_genesis.sh script
./scripts/setup_genesis.sh mainnet ~/.infinited/config/genesis.json

# 3. For each initial validator:
#    a. Create validator key
infinited keys add validator-1 --keyring-backend file

#    b. Add account with funds for staking
infinited genesis add-genesis-account validator-1 10000000000000000000000drop \
  --keyring-backend file

#    c. Create gentx (validator genesis transaction)
infinited genesis gentx validator-1 1000000000000000000000drop \
  --chain-id infinite_421018-1 \
  --commission-rate "0.10" \
  --commission-max-rate "0.20" \
  --commission-max-change-rate "0.01" \
  --min-self-delegation "1000000000000000000" \
  --keyring-backend file

# 3. Collect ALL gentxs from all validators
infinited genesis collect-gentxs

# This adds all validators to Genesis
# Now Genesis has validators and the chain can start producing blocks
```

**Advantages:**
- ✅ Chain can start immediately
- ✅ Initial validators are defined before launch
- ✅ Does not require governance proposals

**Disadvantages:**
- ⚠️ All validators must coordinate and send their gentxs BEFORE launch
- ⚠️ Requires trust and coordination between initial validators

---

### Option 2: Genesis Without Validators (Only for Special Cases)

If you really need a Genesis without initial validators:

1. **Generate Genesis** (as always)
2. **DO NOT run `collect-gentxs`**
3. **Distribute Genesis** to all nodes
4. **Problem**: Chain will NOT produce blocks until someone adds validators

**⚠️ WARNING**: This option has a fundamental problem:

- Without validators, there are no blocks
- Without blocks, transactions cannot be sent
- Without transactions, governance proposals cannot be created
- Without governance, validators cannot be added

**In summary**: This scenario creates a "deadlock" and the chain will never start.

**The only way out of this** would be to have at least one validator that can be added in a special way (outside governance), but this requires code changes, which is not practical for production.

---

## Recommendation for Infinite Drive

### For Mainnet:

**✅ Use Option 1**: Define initial validators before launch.

**Recommended process:**

1. **Preparation Phase** (before launch):
   - Identify initial validators (e.g., 5-10 trusted validators)
   - Each validator must:
     - Generate their keys securely
     - Create their gentx with the correct amount of tokens
     - Send the gentx to a coordinator
   - Coordinator collects all gentxs: `infinited genesis collect-gentxs`
   - Validate final Genesis: `infinited genesis validate-genesis`
   - Distribute final Genesis to ALL nodes

2. **Launch Day**:
   - All nodes use the same Genesis (with validators included)
   - Chain starts immediately producing blocks
   - Initial validators are active from block 0

3. **After Launch**:
   - New validators can join via:
     - Sending `create-validator` transactions (after accumulating enough tokens)
     - Governance processes to add institutional validators

### For Testnet:

Similar to Mainnet, but you can be more flexible:
- Fewer initial validators (3-5 is sufficient)
- Testnet tokens are easy to obtain
- You can have a "development" validator controlled by the team

---

## Improvements to `setup_genesis.sh` Script

The current script generates the base Genesis but **does not automatically add validators**. This is **intentional** because:

1. **Security**: Adding validators requires private keys and must be done manually
2. **Flexibility**: Each project has different requirements about who the initial validators are
3. **Coordination**: Validators must be collected from multiple sources

**The script MUST clearly document** that:
- ✅ It generates a valid Genesis
- ⚠️ BUT Genesis has NO validators
- ⚠️ Validators MUST be added before launch
- 📝 Provides clear instructions on how to add them

---

## Checklist: Preparing Genesis with Validators

Before launching:

- [ ] Genesis generated and configured (using `setup_genesis.sh`)
- [ ] All parameters configured (denoms, governance, etc.)
- [ ] Initial validators identified (list of addresses/operators)
- [ ] Each validator has generated their keys securely
- [ ] Each validator has created their gentx and sent it
- [ ] All gentxs collected: `infinited genesis collect-gentxs`
- [ ] Genesis validated: `infinited genesis validate-genesis`
- [ ] Final Genesis distributed to ALL nodes
- [ ] Verify Genesis has validators: `jq '.app_state.staking.validators | length' genesis.json` (must be > 0)
- [ ] Verify there are delegations: `jq '.app_state.staking.delegations | length' genesis.json` (must be > 0)

---

## Useful Commands

### Verify validators in Genesis:

```bash
# Count validators
jq '.app_state.staking.validators | length' genesis.json

# View validator list
jq '.app_state.staking.validators[].operator_address' genesis.json

# View power (staking) of each validator
jq '.app_state.staking.validators[] | {operator: .operator_address, tokens: .tokens}' genesis.json

# View delegations
jq '.app_state.staking.delegations | length' genesis.json
```

### Verify Genesis can start:

```bash
# Validate structure
infinited genesis validate-genesis

# Verify there are validators in validator set
jq '.validators | length' genesis.json  # Must be > 0
```

---

## Summary

| Scenario | Valid Genesis? | Produces Blocks? | Recommended? |
|----------|----------------|------------------|--------------|
| **Without validators** | ✅ Yes (technically) | ❌ NO | ❌ NO |
| **With 1+ validators** | ✅ Yes | ✅ Yes | ✅ YES |

**Conclusion**: You always need at least one validator in Genesis for the chain to work. The `setup_genesis.sh` script prepares the base Genesis, but **you must manually add validators** using `infinited genesis gentx` and `infinited genesis collect-gentxs` before launch.
