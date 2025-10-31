# Genesis Configuration Files

This directory contains YAML configuration files for generating genesis files for different networks.

## Files

- `mainnet.yaml` - Configuration for Mainnet production network
- `testnet.yaml` - Configuration for Testnet network

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


## Usage

Before running the commands below, review the sections on pre-configuration and customization to ensure the genesis parameters match your environment:
- See "Configuration Structure" and "Customization" in this document
- See guides/GENESIS_MAINNET_CONFIGURATION.md (network-specific guidance)
- Ensure you will use the official genesis files for production networks

Use these configuration files with the `setup_genesis.sh` script:

**Prerequisites:** The node must be initialized first with `infinited init`.

```bash
# Step 1: Initialize the node first
infinited init my-moniker --chain-id infinite_421018-1 --home ~/.infinited

# Step 2: Configure the genesis file using the script
./scripts/setup_genesis.sh mainnet ~/.infinited/config/genesis.json

# For Testnet:
infinited init test-moniker --chain-id infinite_421018001-1 --home ~/.infinited_testnet
./scripts/setup_genesis.sh testnet ~/.infinited_testnet/config/genesis.json

# Custom directory:
infinited init my-moniker --chain-id infinite_421018-1 --home /custom/path/.infinited
./scripts/setup_genesis.sh mainnet /custom/path/.infinited/config/genesis.json
```

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

## Ready to Use / Next Steps

At this point, your `genesis.json` is ready to be used. To launch nodes:

1. Distribute the final `genesis.json` to all nodes. Typical locations:
   - Mainnet: `~/.infinited/config/genesis.json`
   - Testnet: `~/.infinited_testnet/config/genesis.json`

2. Start the node specifying the expected Chain IDs via flags (recommended):
   - Always pass the Cosmos `--chain-id` and the EVM `--evm.evm-chain-id`.
   - If omitted:
     - Cosmos chain-id will be read from `genesis.json`.
     - EVM chain-id will default to Mainnet (`421018`).
     - Home will default to Mainnet path: `~/.infinited`.

3. Optionally set minimum gas prices in `app.toml`:
   - Mainnet (example): `minimum-gas-prices = "1000000000drop"`
   - Testnet: `minimum-gas-prices = "0drop"`

4. Start the node (examples):

   Default home (uses `~/.infinited/config/genesis.json`):
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

   Using a custom data directory.
   On this case, the testnet path.
   ```bash
   # Save in local variable the custom home
   HOME_DIR=~/.infinited_testnet
 
   # (Optional) You always can initialize a new node, it will create basic data structure with the base genesis file. After run it, you can edit the genesis file with the script, or replace it with another file.   
   infinited init my-node --chain-id infinite_421018001-1 --home "$HOME_DIR"

   # Start the node pointing to that data dir (always pass both chain IDs)
   infinited start \
     --home "$HOME_DIR" \
     --chain-id infinite_421018001-1 \
     --evm.evm-chain-id 421018001
   ```

5. Verify the node is running and connected (JSON-RPC/REST/Tendermint RPC).

Further guidance:
- Quick setup and health checks: `guides/GETTING_STARTED.md`
- Production rollout: `guides/PRODUCTION_DEPLOYMENT.md`
- Network parameters and differences: `config/genesis/COMPARISON_MAINNET_TESTNET.md`