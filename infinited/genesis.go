package evmd

import (
	"encoding/json"
	testconstants "github.com/cosmos/evm/testutil/constants"
	erc20types "github.com/cosmos/evm/x/erc20/types"
	feemarkettypes "github.com/cosmos/evm/x/feemarket/types"
	evmtypes "github.com/cosmos/evm/x/vm/types"

	minttypes "github.com/cosmos/cosmos-sdk/x/mint/types"
)

// GenesisState of the blockchain is represented here as a map of raw json
// messages key'd by an identifier string.
// The identifier is used to determine which module genesis information belongs
// to so it may be appropriately routed during init chain.
// Within this application default genesis information is retrieved from
// the ModuleBasicManager which populates json from each BasicModule
// object provided to it during init.
type GenesisState map[string]json.RawMessage

// NewEVMGenesisState returns the default genesis state for the EVM module.
//
// NOTE: Sets the default EVM denomination, enables ALL precompiles,
// and includes default preinstalls for Infinite Drive.
func NewEVMGenesisState() *evmtypes.GenesisState {
	evmGenState := evmtypes.DefaultGenesisState()
	evmGenState.Params.ActiveStaticPrecompiles = evmtypes.AvailableStaticPrecompiles
	evmGenState.Preinstalls = evmtypes.DefaultPreinstalls

	return evmGenState
}

// NewErc20GenesisState returns the default genesis state for the ERC20 module.
//
// NOTE: By default, token pairs and native precompiles are empty.
// These should be configured explicitly for each network (mainnet, testnet, etc.)
// via the genesis JSON file or governance proposals after launch.
func NewErc20GenesisState() *erc20types.GenesisState {
	erc20GenState := erc20types.DefaultGenesisState()
	// Token pairs and native precompiles are intentionally empty by default.
	// They should be configured during genesis setup for production networks.
	erc20GenState.TokenPairs = []erc20types.TokenPair{}
	erc20GenState.NativePrecompiles = []string{}

	return erc20GenState
}

// NewMintGenesisState returns the default genesis state for the mint module.
//
// NOTE: Sets the mint denomination to the base denom (drop) for Infinite Drive.
func NewMintGenesisState() *minttypes.GenesisState {
	mintGenState := minttypes.DefaultGenesisState()

	mintGenState.Params.MintDenom = testconstants.ExampleAttoDenom
	return mintGenState
}

// NewFeeMarketGenesisState returns the default genesis state for the feemarket module.
//
// NOTE: Disables the base fee by default. This can be enabled later via governance
// or by configuring the genesis JSON for production networks.
func NewFeeMarketGenesisState() *feemarkettypes.GenesisState {
	feeMarketGenState := feemarkettypes.DefaultGenesisState()
	feeMarketGenState.Params.NoBaseFee = true

	return feeMarketGenState
}
