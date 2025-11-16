package interfaces

import (
	feemarkettypes "github.com/deep-thought-labs/infinite/x/feemarket/types"
	"github.com/deep-thought-labs/infinite/x/vm/statedb"
	evmtypes "github.com/deep-thought-labs/infinite/x/vm/types"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core"
	"github.com/ethereum/go-ethereum/core/tracing"
	"github.com/ethereum/go-ethereum/core/vm"
	"github.com/holiman/uint256"

	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/cosmos-sdk/types/tx"
)

// EVMKeeper exposes the required EVM keeper interface required for ante handlers
type EVMKeeper interface {
	statedb.Keeper

	NewEVM(ctx sdk.Context, msg core.Message, cfg *statedb.EVMConfig, tracer *tracing.Hooks,
		stateDB vm.StateDB) *vm.EVM
	DeductTxCostsFromUserBalance(ctx sdk.Context, fees sdk.Coins, from common.Address) error
	SpendableCoin(ctx sdk.Context, addr common.Address) *uint256.Int
	GetParams(ctx sdk.Context) evmtypes.Params
}

// FeeMarketKeeper exposes the required feemarket keeper interface required for ante handlers
type FeeMarketKeeper interface {
	GetParams(ctx sdk.Context) (params feemarkettypes.Params)
}

type ProtoTxProvider interface {
	GetProtoTx() *tx.Tx
}
