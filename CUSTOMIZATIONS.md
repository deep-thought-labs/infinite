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

## Added Files (Not in upstream)

### Documentation
- `guides/*.md` (14 files: BUILDING_AND_RELEASES, DEVELOPMENT_GUIDE, DOCKER_*, GENESIS_MAINNET_CONFIGURATION, GETTING_STARTED, GITHUB_*, LOCAL_BUILD_TESTING, NODE_HEALTH_SCRIPTS, PRODUCTION_DEPLOYMENT, TOKEN_SUPPLY_GENESIS, TROUBLESHOOTING, VALIDATORS_GENESIS)

### Scripts
- `scripts/audit_command_name.sh`
- `scripts/check_build_prerequisites.sh`
- `scripts/compare_outputs.sh`
- `scripts/infinite_health_check.sh`
- `scripts/list_all_customizations.sh`
- `scripts/test_outputs_before.sh`
- `scripts/validate_customizations.sh`
- `scripts/validate_token_config.sh`
- `scripts/verify_command_name.sh`
- `scripts/README_SCRIPTS.md`

### Configuration
- `assets/pre-mainet-genesis.json`
- `.goreleaser.yml`
- `.goreleaser.linux-only.yml`
- `.github/workflows/release.yml`
- `local_node.sh`

### Test Files
- `infinited/interfaces.go`
- `infinited/tests/integration/*` (30+ test files)
- `tests/integration/ante/test_evm_fee_market.go`
- `tests/integration/ante/test_evm_unit_10_gas_wanted.go`
- `tests/systemtests/mempool/interface.go`

### Other
- `ante/evm/10_gas_wanted.go` (deleted in upstream, kept in fork)
- `CUSTOMIZATIONS.md` (this file)

## Complete File List

To see complete list of all files that differ from upstream repository:
```bash
./scripts/list_all_customizations.sh [upstream-branch]
```

Default: compares against `upstream/main` (original repository)
Example: `./scripts/list_all_customizations.sh upstream/main`

This will show:
- All added files (A)
- All modified files (M)
- Files deleted in upstream but kept in fork (D)

**Note**: This script compares against the upstream remote (original repository), not your fork's main branch. This ensures accurate comparison even after merging your customizations to main.

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

**Note**: This script does NOT depend on branch names. It validates values in files directly, so it works regardless of which branch you're on or which branch you compare against.
