package bank

import (
	"encoding/json"
	"fmt"

	"github.com/gorilla/mux"
	"github.com/grpc-ecosystem/grpc-gateway/runtime"
	"github.com/spf13/cobra"

	abci "github.com/cometbft/cometbft/abci/types"

	"cosmossdk.io/core/appmodule"

	"github.com/cosmos/evm/x/bank/keeper"
	"github.com/cosmos/evm/x/bank/types"

	"github.com/cosmos/cosmos-sdk/client"
	"github.com/cosmos/cosmos-sdk/codec"
	codectypes "github.com/cosmos/cosmos-sdk/codec/types"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/cosmos-sdk/types/module"
	simtypes "github.com/cosmos/cosmos-sdk/types/simulation"
	bankkeeper "github.com/cosmos/cosmos-sdk/x/bank/keeper"
)

const consensusVersion = 1

var (
	_ module.AppModule           = AppModule{}
	_ module.AppModuleBasic      = AppModuleBasic{}
	_ appmodule.AppModule        = AppModule{}
	_ module.HasABCIGenesis      = AppModule{}
)

// AppModuleBasic defines the basic application module for the infinite bank extension.
type AppModuleBasic struct{}

// Name returns the module name.
func (AppModuleBasic) Name() string {
	return types.ModuleName
}

// RegisterLegacyAminoCodec registers the amino codec.
func (AppModuleBasic) RegisterLegacyAminoCodec(cdc *codec.LegacyAmino) {
	types.RegisterLegacyAminoCodec(cdc)
}

// ConsensusVersion implements AppModuleBasic.
func (AppModuleBasic) ConsensusVersion() uint64 {
	return consensusVersion
}

// RegisterInterfaces registers interfaces and implementations.
func (AppModuleBasic) RegisterInterfaces(registry codectypes.InterfaceRegistry) {
	types.RegisterInterfaces(registry)
}

// DefaultGenesis returns default genesis (empty object).
func (AppModuleBasic) DefaultGenesis(_ codec.JSONCodec) json.RawMessage {
	bz, err := json.Marshal(types.DefaultGenesisState())
	if err != nil {
		panic(err)
	}
	return bz
}

// ValidateGenesis validates genesis JSON.
func (AppModuleBasic) ValidateGenesis(_ codec.JSONCodec, _ client.TxEncodingConfig, bz json.RawMessage) error {
	var gs types.GenesisState
	if err := json.Unmarshal(bz, &gs); err != nil {
		return fmt.Errorf("failed to unmarshal %s genesis state: %w", types.ModuleName, err)
	}
	return gs.Validate()
}

// RegisterRESTRoutes is a no-op.
func (AppModuleBasic) RegisterRESTRoutes(_ client.Context, _ *mux.Router) {}

// RegisterGRPCGatewayRoutes is a no-op (no gRPC-gateway for Msg-only module).
func (AppModuleBasic) RegisterGRPCGatewayRoutes(_ client.Context, _ *runtime.ServeMux) {}

// GetTxCmd returns nil (governance-only Msg for now).
func (AppModuleBasic) GetTxCmd() *cobra.Command {
	return nil
}

// GetQueryCmd returns nil.
func (AppModuleBasic) GetQueryCmd() *cobra.Command {
	return nil
}

// AppModule implements an application module for the infinite bank extension.
type AppModule struct {
	AppModuleBasic
	bankKeeper bankkeeper.Keeper
	authority  sdk.AccAddress
}

// NewAppModule creates a new AppModule.
func NewAppModule(bk bankkeeper.Keeper, authority sdk.AccAddress) AppModule {
	return AppModule{
		AppModuleBasic: AppModuleBasic{},
		bankKeeper:     bk,
		authority:      authority,
	}
}

// Name returns the module name.
func (AppModule) Name() string {
	return types.ModuleName
}

// RegisterServices registers the gRPC Msg service.
func (am AppModule) RegisterServices(cfg module.Configurator) {
	types.RegisterMsgServer(cfg.MsgServer(), keeper.NewMsgServer(am.bankKeeper, am.authority))
}

// InitGenesis is a no-op beyond JSON validation.
func (AppModule) InitGenesis(_ sdk.Context, _ codec.JSONCodec, data json.RawMessage) []abci.ValidatorUpdate {
	var genesisState types.GenesisState
	if err := json.Unmarshal(data, &genesisState); err != nil {
		panic(err)
	}
	if err := genesisState.Validate(); err != nil {
		panic(err)
	}
	return []abci.ValidatorUpdate{}
}

// ExportGenesis exports the default empty genesis.
func (AppModule) ExportGenesis(_ sdk.Context, _ codec.JSONCodec) json.RawMessage {
	bz, err := json.Marshal(types.DefaultGenesisState())
	if err != nil {
		panic(err)
	}
	return bz
}

// RegisterStoreDecoder is a no-op.
func (AppModule) RegisterStoreDecoder(_ simtypes.StoreDecoderRegistry) {}

// GenerateGenesisState is unused.
func (AppModule) GenerateGenesisState(_ *module.SimulationState) {}

// WeightedOperations returns no simulation ops.
func (AppModule) WeightedOperations(_ module.SimulationState) []simtypes.WeightedOperation {
	return nil
}

// IsAppModule implements appmodule.AppModule.
func (am AppModule) IsAppModule() {}

// IsOnePerModuleType implements depinject tagging.
func (am AppModule) IsOnePerModuleType() {}
