package evmd

import (
	"context"

	storetypes "cosmossdk.io/store/types"

	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/cosmos-sdk/types/module"
	upgradetypes "github.com/cosmos/cosmos-sdk/x/upgrade/types"
)

// UpgradeName defines the on-chain upgrade name for the sample EVMD upgrade
// from v0.4.0 to v0.5.0.
//
// NOTE: This upgrade defines a reference implementation of what an upgrade
// could look like when an application is migrating from EVMD version
// v0.4.0 to v0.5.x
const UpgradeName = "v0.4.0-to-v0.5.0"

// UpgradeNameSystemTest is used by `TestChainUpgrade` so the legacy binary
// downloaded from releases is not required to share the same compiled-in upgrade
// handler name as the current branch binary.
//
// Rationale: some legacy artifacts may already register a handler for UpgradeName
// at process start, which can conflict with SDK `x/upgrade` PreBlock semantics
// when an on-chain plan is scheduled but not yet due.
const UpgradeNameSystemTest = "v0.4.0-to-v0.5.0-systemtest"

func (app EVMD) RegisterUpgradeHandlers() {
	register := func(name string) {
		app.UpgradeKeeper.SetUpgradeHandler(
			name,
			func(ctx context.Context, _ upgradetypes.Plan, fromVM module.VersionMap) (module.VersionMap, error) {
				sdkCtx := sdk.UnwrapSDKContext(ctx)
				sdkCtx.Logger().Debug("this is a debug level message to test that verbose logging mode has properly been enabled during a chain upgrade")
				return app.ModuleManager.RunMigrations(ctx, app.Configurator(), fromVM)
			},
		)
	}
	register(UpgradeName)
	register(UpgradeNameSystemTest)

	upgradeInfo, err := app.UpgradeKeeper.ReadUpgradeInfoFromDisk()
	if err != nil {
		panic(err)
	}

	if (upgradeInfo.Name == UpgradeName || upgradeInfo.Name == UpgradeNameSystemTest) &&
		!app.UpgradeKeeper.IsSkipHeight(upgradeInfo.Height) {
		storeUpgrades := storetypes.StoreUpgrades{
			Added: []string{},
		}
		app.SetStoreLoader(upgradetypes.UpgradeStoreLoader(upgradeInfo.Height, &storeUpgrades))
	}
}
