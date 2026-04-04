package integration

import (
	"slices"
	"testing"

	hyperlanetypes "github.com/bcp-innovations/hyperlane-cosmos/x/core/types"
	warptypes "github.com/bcp-innovations/hyperlane-cosmos/x/warp/types"
	evmd "github.com/cosmos/evm/infinited"
	"github.com/cosmos/evm/testutil/constants"
	"github.com/stretchr/testify/require"
)

// TestHyperlane_ModuleStoresAndKeepers builds the app via CreateEvmd (same path as IBC/ERC-20 integration)
// and asserts Hyperlane wiring: store keys, keeper, module registration, init-genesis order (core before warp).
func TestHyperlane_ModuleStoresAndKeepers(t *testing.T) {
	// Not parallel: NewExampleApp touches package-level encoding/amino state (race under -race).

	app := CreateEvmd(constants.ExampleChainID.ChainID, constants.EighteenDecimalsChainID, false)

	require.NotNil(t, app.GetKey(hyperlanetypes.ModuleName))
	require.NotNil(t, app.GetKey(warptypes.ModuleName))

	evmdApp, ok := app.(*evmd.EVMD)
	require.True(t, ok, "CreateEvmd must return *evmd.EVMD for Hyperlane internal checks")

	require.NotNil(t, evmdApp.HyperlaneKeeper, "HyperlaneKeeper must be set")

	_, hasCore := evmdApp.ModuleManager.Modules[hyperlanetypes.ModuleName]
	_, hasWarp := evmdApp.ModuleManager.Modules[warptypes.ModuleName]
	require.True(t, hasCore, "x/core module must be registered")
	require.True(t, hasWarp, "x/warp module must be registered")

	order := evmdApp.ModuleManager.OrderInitGenesis
	iCore := slices.Index(order, hyperlanetypes.ModuleName)
	iWarp := slices.Index(order, warptypes.ModuleName)
	require.NotEqual(t, -1, iCore, "hyperlane must appear in OrderInitGenesis")
	require.NotEqual(t, -1, iWarp, "warp must appear in OrderInitGenesis")
	require.Less(t, iCore, iWarp, "hyperlane init must run before warp (warp registers on core AppRouter)")
}

// TestHyperlane_DefaultGenesisContainsModules ensures DefaultGenesis includes hyperlane and warp.
func TestHyperlane_DefaultGenesisContainsModules(t *testing.T) {
	app := CreateEvmd(constants.ExampleChainID.ChainID, constants.EighteenDecimalsChainID, false)

	gen := app.DefaultGenesis()
	require.Contains(t, gen, hyperlanetypes.ModuleName)
	require.Contains(t, gen, warptypes.ModuleName)
}
