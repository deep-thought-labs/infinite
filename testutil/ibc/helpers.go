package ibctesting

import (
	"math/big"
	"math/rand"
	"testing"
	"time"

	"github.com/stretchr/testify/require"

	abci "github.com/cometbft/cometbft/abci/types"

	"github.com/cosmos/evm/x/vm/types"

	bam "github.com/cosmos/cosmos-sdk/baseapp"
	"github.com/cosmos/cosmos-sdk/client"
	cryptotypes "github.com/cosmos/cosmos-sdk/crypto/types"
	simtestutil "github.com/cosmos/cosmos-sdk/testutil/sims"
	sdk "github.com/cosmos/cosmos-sdk/types"
)

const FeeAmt = 10000000000

func FeeCoins() sdk.Coins {
	// Note: evmChain requires for gas price higher than base fee (see fee_checker.go).
	sdkExp := new(big.Int).Exp(big.NewInt(10), big.NewInt(6), nil)
	return sdk.Coins{sdk.NewInt64Coin(types.DefaultEVMExtendedDenom, new(big.Int).Mul(big.NewInt(FeeAmt), sdkExp).Int64())}
}

// SimAppFeeCoins returns fees for ibc-go SimApp chains. SimApp mint BeginBlock moves
// collected fees in sdk.DefaultBondDenom; paying fees only in the EVM extended denom
// leaves the fee collector without stake and breaks BeginBlock on counterparty NextBlock.
func SimAppFeeCoins() sdk.Coins {
	sdkExp := new(big.Int).Exp(big.NewInt(10), big.NewInt(6), nil)
	return sdk.Coins{sdk.NewInt64Coin(sdk.DefaultBondDenom, new(big.Int).Mul(big.NewInt(FeeAmt), sdkExp).Int64())}
}

// SignAndDeliver signs and delivers a transaction. No simulation occurs as the
// ibc testing package causes checkState and deliverState to diverge in block time.
//
// CONTRACT: BeginBlock must be called before this function.
func SignAndDeliver(
	tb testing.TB, proposerAddress sdk.AccAddress, txCfg client.TxConfig, app *bam.BaseApp, msgs []sdk.Msg,
	fees sdk.Coins,
	chainID string, accNums, accSeqs []uint64, expPass bool, blockTime time.Time, nextValHash []byte, priv ...cryptotypes.PrivKey,
) (*abci.ResponseFinalizeBlock, error) {
	tb.Helper()
	tx, err := simtestutil.GenSignedMockTx(
		rand.New(rand.NewSource(time.Now().UnixNano())),
		txCfg,
		msgs,
		fees,
		simtestutil.DefaultGenTxGas,
		chainID,
		accNums,
		accSeqs,
		priv...,
	)
	require.NoError(tb, err)

	txBytes, err := txCfg.TxEncoder()(tx)
	require.NoError(tb, err)

	return app.FinalizeBlock(&abci.RequestFinalizeBlock{
		Height:             app.LastBlockHeight() + 1,
		Time:               blockTime,
		NextValidatorsHash: nextValHash,
		Txs:                [][]byte{txBytes},
		ProposerAddress:    proposerAddress,
	})
}
