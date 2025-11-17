# Customizations Reference

> Quick reference for all Infinite Drive customizations. Use this to validate during merges.

## ⚠️ CRITICAL RULES - READ FIRST

### Core Principle: Identity Only, Technical Upstream Priority

**We ONLY customize identity-related aspects. All technical and operational aspects MUST prioritize the upstream repository.**

### What We Customize (Identity Only)

✅ **Token Configuration**:** Denominations, symbols, names, metadata  
✅ **Chain IDs**: Cosmos Chain ID and EVM Chain ID  
✅ **Bech32 Prefixes**: Account, validator, consensus prefixes  
✅ **Binary/Directory Names**: `infinited` instead of `evmd`  
✅ **Branding**: Copyright, README, documentation  
✅ **Custom Files**: Scripts, guides, configuration files we added

### What We DO NOT Customize (Upstream Priority)

❌ **Go Modules**: `go.mod` and `go.sum` must match upstream (except module name in `infinited/go.mod`)  
❌ **Dependencies**: All dependencies must match upstream versions  
❌ **Package Paths**: Use `github.com/cosmos/evm` (upstream), NOT `github.com/deep-thought-labs/infinite`  
❌ **Functional Code**: Core application logic, features, bug fixes from upstream  
❌ **Technical Configuration**: Build systems, CI/CD (except branding), technical parameters

### Module Path Rules

- **Root `go.mod`**: Must be `github.com/cosmos/evm` (upstream)
- **`infinited/go.mod`**: Must be `module github.com/cosmos/evm/infinited` (submodule, like upstream's `evmd`)
- **All imports**: Must use `github.com/cosmos/evm/...` (upstream paths)
- **Replace directive**: `github.com/cosmos/evm => ./` (for local development only)

### During Merges

1. **Always prioritize upstream** for technical/functional changes
2. **Only preserve identity** customizations (tokens, chain IDs, bech32, names)
3. **Revert everything else** to match upstream exactly
4. **Validate** using `./scripts/validate_customizations.sh` after merge
5. **Compare** using `./scripts/list_all_customizations.sh main` to see current differences

### Expected Change Statistics

Based on comparison between `migration` and `main`:
- **Identity files:** 7 files (token config, chain IDs, bech32)
- **Custom files added:** 55 files (guides, scripts, config)
- **Renamed files:** 55 files (evmd/ → infinited/)
- **Branding files:** 5 files (Makefile, NOTICE, README.md, go.mod, go.sum)
- **Total expected differences:** ~122 files

If you see significantly more or different files, generate a fresh comparison report:
```bash
./scripts/list_all_customizations.sh main
```

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
- `infinited/genesis.go`: Genesis state functions that set denoms to "drop":
  - `NewMintGenesisState()`: Sets `mint.params.mint_denom` to "drop"
  - `NewStakingGenesisState()`: Sets `staking.params.bond_denom` to "drop"
  - `NewGovGenesisState()`: Sets `gov.params.min_deposit[].denom` and `gov.params.expedited_min_deposit[].denom` to "drop"
- `infinited/app.go`: `DefaultGenesis()` function that applies the custom genesis states above
- `infinited/tests/integration/create_app.go`: Test app creation with identity configuration
- `scripts/customize_genesis.sh`: **Network Genesis Configuration Script** - Standalone script to customize generated genesis.json with all Infinite Drive personalizations for mainnet, testnet, or creative networks. **Used specifically for network genesis creation process** (not required for regular users running local chains). Applies:
  - All module denominations (staking, mint, gov, evm) → network-specific denom (drop/tdrop/cdrop)
  - Complete token metadata for network-specific token (Improbability/TestImprobability/CreativeImprobability)
  - EVM static precompiles configuration
  - ERC20 native token pair
  - Complete Staking Module configuration (unbonding_time, max_validators, etc.)
  - Complete Mint Module configuration (inflation rates per network)
  - Complete Governance Module configuration (voting periods, thresholds, deposits)
  - Complete Slashing Module configuration (penalties, windows, jail duration)
  - Complete Fee Market Module configuration (base fees, multipliers)
  - Complete Distribution Module configuration (community_tax, proposer rewards)
  - Consensus parameters (max_gas, evidence windows)
  - Creates automatic backup before modifications
  - **Usage**: `./scripts/customize_genesis.sh <genesis_file_path> --network <mainnet|testnet|creative>`
  - **When**: During network genesis creation process, after `infinited init` and before adding accounts/validators
  - **Note**: Regular users running local development chains should use `local_node.sh` instead, which includes this customization automatically
- `local_node.sh`: Development script that includes genesis customization (uses same logic as customize_genesis.sh) plus account creation, funding, and node startup
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

### ⚠️ IMPORTANT: Package Paths
- **Module Path**: `github.com/cosmos/evm` (upstream - DO NOT CHANGE)
- **Submodule Path**: `github.com/cosmos/evm/infinited` (like upstream's `evmd`)
- **All imports**: Must use `github.com/cosmos/evm/...` (upstream paths)
- **NOT**: `github.com/deep-thought-labs/infinite` (this is incorrect)

### Binary/Directory Names
- Old: `evmd`, `evmd/`
- New: `infinited`, `infinited/`
- **Total renamed:** 55 files from `evmd/` to `infinited/`

### Files
- `Makefile`: test-infinited, INFINITED_DIR, EXAMPLE_BINARY
- `NOTICE`: Copyright Deep Thought Labs
- `README.md`: Branding and project description

### Renamed Files Summary
All files in `evmd/` directory were renamed to `infinited/`:
- `evmd/app.go` → `infinited/app.go`
- `evmd/cmd/evmd/` → `infinited/cmd/infinited/`
- `evmd/config/` → `infinited/config/`
- `evmd/tests/` → `infinited/tests/`
- `evmd/go.mod` → `infinited/go.mod`
- And 50+ more files

**Note:** Files appearing as "deleted" in `evmd/tests/integration/` are actually renamed to `infinited/tests/integration/`.

## Technical Configuration

### Power Reduction
- File: `infinited/app.go`
- Value: `sdk.DefaultPowerReduction = utils.AttoPowerReduction`
- Comment: `1 42 = 10^18 drop`

### Genesis State Customization
- File: `infinited/genesis.go`
- Functions that customize default genesis state to use "drop" denom:
  - `NewMintGenesisState()`: Overrides default "stake" with "drop" for mint module
  - `NewStakingGenesisState()`: Overrides default "stake" with "drop" for staking module
  - `NewGovGenesisState()`: Overrides default "stake" with "drop" for governance module
- File: `infinited/app.go`
- Function: `DefaultGenesis()` applies the custom genesis states to ensure all modules use "drop" instead of default "stake"

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
- `infinited/tests/integration/create_app.go` - **Contains identity changes** (uses Improbability token config)
- `infinited/tests/integration/*` (30+ test files) - Renamed from `evmd/tests/integration/*`
- `tests/integration/ante/test_evm_fee_market.go`
- `tests/integration/ante/test_evm_unit_10_gas_wanted.go`
- `tests/systemtests/mempool/interface.go`

### Other
- `ante/evm/10_gas_wanted.go` (deleted in upstream, kept in fork)
- `CUSTOMIZATIONS.md` (this file)

## Complete File List

### Quick Comparison Script

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

### Generating Comparison Reports

To generate a detailed comparison report when needed, use:
```bash
# Compare current branch vs main (your fork's base)
./scripts/list_all_customizations.sh main

# Compare current branch vs upstream/main (original repository)
./scripts/list_all_customizations.sh upstream/main

# Save to file if needed
./scripts/list_all_customizations.sh main > comparison_report.txt
```

**Expected Statistics** (based on migration vs main):
- **Total files different:** ~141
- **Added:** ~55 files
- **Modified:** ~9 files
- **Renamed:** ~55 files (evmd/ → infinited/)
- **Deleted:** ~22 files (renamed, not actually deleted)

**Breakdown:**
- Identity files: 7 files
- Custom files added: 55 files
- Renamed files: 55 files
- Branding files: 5 files (Makefile, NOTICE, README.md, go.mod, go.sum)

**Note:** These statistics are based on a snapshot comparison. Use the script above to generate current statistics.

## Validation Commands

### Identity Customizations
```bash
# Token values
grep -r "Improbability\|drop\|42" --include="*.go" --include="*.sh" --include="*.json"

# Chain IDs
grep -r "421018\|infinite_421018" --include="*.go" --include="*.sh"

# Bech32
grep -r "infinitevaloper\|infinitevalcons" --include="*.go"

# Binary names
grep -r "infinited" --include="Makefile" --include="*.sh"
```

### ⚠️ Critical: Verify Upstream Compliance
```bash
# Verify NO incorrect package paths (should find nothing)
grep -r "deep-thought-labs/infinite" --include="*.go" --include="*.mod" || echo "✅ No incorrect paths found"

# Verify go.mod matches upstream (except module name)
git diff upstream/main go.mod | grep -v "^module" | grep -v "^+++" | grep -v "^---" || echo "✅ go.mod matches upstream"

# Verify go.sum matches upstream
git diff upstream/main go.sum | head -5 || echo "✅ go.sum matches upstream"
```

## Quick Validation

Run the validation script:
```bash
./scripts/validate_customizations.sh
```

This script checks all critical customizations and reports any missing values.

**Note**: This script does NOT depend on branch names. It validates values in files directly, so it works regardless of which branch you're on or which branch you compare against.
