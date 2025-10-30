# Genesis Configuration Files

This directory contains YAML configuration files for generating genesis files for different networks.

## Files

- `mainnet.yaml` - Configuration for Mainnet production network
- `testnet.yaml` - Configuration for Testnet network

## Usage

Use these configuration files with the `setup_genesis.sh` script:

```bash
# Generate Mainnet genesis
./scripts/setup_genesis.sh mainnet my-moniker

# Generate Testnet genesis
./scripts/setup_genesis.sh testnet test-moniker

# Generate to custom directory
./scripts/setup_genesis.sh mainnet my-moniker ~/custom-genesis
```

## Configuration Structure

Each YAML file contains:

- **chain**: Chain IDs (Cosmos and EVM), Bech32 prefix
- **denom**: Base and display denominations, decimals
- **token_metadata**: Token name, symbol, description, URI
- **staking**: Staking module parameters
- **governance**: Governance parameters (periods, thresholds, deposits)
- **mint**: Mint module parameters (inflation rates)
- **slashing**: Slashing parameters (penalties, jail duration)
- **evm**: EVM module configuration (chain ID, precompiles)
- **erc20**: ERC20 module configuration (token pairs, precompiles)
- **feemarket**: Fee market configuration
- **consensus**: Consensus parameters (block size, gas limits)

## Prerequisites

The `setup_genesis.sh` script requires:

- `infinited` binary (built or installed)
- `jq` - JSON processor
- `yq` - YAML processor

Install dependencies:
```bash
# macOS
brew install jq yq

# Ubuntu/Debian
sudo apt install jq
# yq: https://github.com/mikefarah/yq/releases
```

## Customization

1. Edit the appropriate YAML file (`mainnet.yaml` or `testnet.yaml`)
2. Run the setup script
3. The script will read your changes and apply them to the genesis file

## Important Notes

- **⚠️ VALIDATORS REQUIRED**: The script generates a valid Genesis, but **you MUST add at least one validator** before launching, or the chain will not produce blocks. See `guides/VALIDATORS_GENESIS.md` for details.
- Token pairs and native precompiles start empty by default
- Add them in the YAML files if Infinite Drive has wrapped token contracts
- Governance periods differ between mainnet (2 days) and testnet (1 hour)
- All denoms will be set to `drop` as configured in the YAML

## Adding Validators

After running the script, you must add validators:

```bash
# For each validator (repeat for all validators):

# 1. Create validator key
infinited keys add validator-1 --keyring-backend file

# 2. Add account with funds (creates tokens from nothing)
infinited genesis add-genesis-account validator-1 1000000000000000000000drop \
  --keyring-backend file
# ↑ This creates 1000 TEA from nothing and assigns to validator-1

# 3. Create gentx (uses existing tokens for staking)
infinited genesis gentx validator-1 1000000000000000000000drop \
  --chain-id infinite_421018-1 \
  --commission-rate "0.10" \
  --keyring-backend file
# ↑ This uses the 1000 TEA already assigned to validator-1

# 4. Collect all gentxs (run after ALL validators have created their gentxs)
infinited genesis collect-gentxs

# Verify validators were added
jq '.app_state.staking.validators | length' ~/.infinited/config/genesis.json
```

See `guides/VALIDATORS_GENESIS.md` and `guides/TOKEN_SUPPLY_GENESIS.md` for complete instructions.

