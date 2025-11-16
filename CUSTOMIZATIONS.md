# Customizations Reference

> Quick reference for all Infinite Drive customizations. Use this to validate during merges.

## Token Configuration

### Values
- Base Denom: `drop`
- Display Denom: `Improbability`
- Symbol: `42`
- Name: `Improbability`
- Description: `Improbability Token — Project 42: Sovereign, Perpetual, DAO-Governed`
- Decimals: `18`
- URI: `https://assets.infinitedrive.xyz/tokens/42/icon.png`

### Files
- `x/vm/types/params.go`: DefaultEVMDenom, DefaultEVMDisplayDenom, DefaultEVMChainID
- `testutil/constants/constants.go`: ExampleAttoDenom, ExampleDisplayDenom, ChainsCoinInfo[421018]
- `testutil/integration/evm/network/chain_id_modifiers.go`: GenerateBankGenesisMetadata (chain ID 421018)
- `local_node.sh`: Token metadata in genesis
- `assets/pre-mainet-genesis.json`: Token metadata

## Chain IDs

### Values
- Cosmos Chain ID: `infinite_421018-1`
- EVM Chain ID: `421018` (decimal), `0x66c9a` (hex)

### Files
- `testutil/constants/constants.go`: ExampleChainID, EighteenDecimalsChainID
- `x/vm/types/params.go`: DefaultEVMChainID
- `local_node.sh`: CHAINID, EVM_CHAIN_ID

## Bech32 Prefixes

### Values
- Account: `infinite`
- Validator: `infinitevaloper`
- Consensus: `infinitevalcons`

### Files
- `infinited/config/bech32.go`: Bech32Prefix constants

## Rebranding

### Package Paths
- Old: `github.com/cosmos/evm`
- New: `github.com/deep-thought-labs/infinite`

### Binary/Directory Names
- Old: `evmd`, `evmd/`
- New: `infinited`, `infinited/`

### Files (All Go files with imports)
- All `.go` files importing `github.com/deep-thought-labs/infinite`
- `Makefile`: test-infinited, INFINITED_DIR, EXAMPLE_BINARY
- `NOTICE`: Copyright Deep Thought Labs

## Technical Configuration

### Power Reduction
- File: `infinited/app.go`
- Value: `sdk.DefaultPowerReduction = utils.AttoPowerReduction`
- Comment: `1 42 = 10^18 drop`

## Validation Commands

```bash
# Token values
grep -r "Improbability\|drop\|42" --include="*.go" --include="*.sh" --include="*.json"

# Chain IDs
grep -r "421018\|infinite_421018" --include="*.go" --include="*.sh"

# Bech32
grep -r "infinitevaloper\|infinitevalcons" --include="*.go"

# Package paths
grep -r "deep-thought-labs/infinite" --include="*.go" --include="*.mod"

# Binary names
grep -r "infinited" --include="Makefile" --include="*.sh"
```

## Quick Validation

Run the validation script:
```bash
./scripts/validate_customizations.sh
```

This script checks all critical customizations and reports any missing values.

