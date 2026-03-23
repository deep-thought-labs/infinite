package ante

import (
	"fmt"

	cmtproto "github.com/cometbft/cometbft/proto/tendermint/types"

	"github.com/cosmos/evm/ante/evm"
	testconstants "github.com/cosmos/evm/testutil/constants"
	"github.com/cosmos/evm/testutil/integration/evm/factory"
	"github.com/cosmos/evm/testutil/integration/evm/grpc"
	"github.com/cosmos/evm/testutil/integration/evm/network"
	"github.com/cosmos/evm/testutil/integration/evm/utils"
	testkeyring "github.com/cosmos/evm/testutil/keyring"
	evmtypes "github.com/cosmos/evm/x/vm/types"

	storetypes "cosmossdk.io/store/types"

	sdktypes "github.com/cosmos/cosmos-sdk/types"
	errortypes "github.com/cosmos/cosmos-sdk/types/errors"
)

func (s *EvmUnitAnteTestSuite) TestCheckGasWanted() {
	keyring := testkeyring.New(1)
	unitNetwork := network.NewUnitTestNetwork(
		s.create,
		network.WithChainID(testconstants.ChainID{
			ChainID:    s.ChainID,
			EVMChainID: s.EvmChainID,
		}),
		network.WithPreFundedAccounts(keyring.GetAllAccAddrs()...),
	)
	grpcHandler := grpc.NewIntegrationHandler(unitNetwork)
	txFactory := factory.New(unitNetwork, grpcHandler)
	commonGasLimit := uint64(100_000)

	testCases := []struct {
		name          string
		expectedError error
		getCtx        func() sdktypes.Context
		isLondon      bool
	}{
		{
			name:          "success: if isLondon false it should not error",
			expectedError: nil,
			getCtx: func() sdktypes.Context {
				// Even if the gasWanted is more than the blockGasLimit, it should not error
				blockMeter := storetypes.NewGasMeter(commonGasLimit - 10000)
				return unitNetwork.GetContext().WithBlockGasMeter(blockMeter)
			},
			isLondon: false,
		},
		{
			name:          "success: gasWanted is less than blockGasLimit",
			expectedError: nil,
			getCtx: func() sdktypes.Context {
				blockMeter := storetypes.NewGasMeter(commonGasLimit + 10000)
				return unitNetwork.GetContext().WithBlockGasMeter(blockMeter)
			},
			isLondon: true,
		},
		{
			name:          "fail: gasWanted is more than blockGasLimit",
			expectedError: errortypes.ErrOutOfGas,
			getCtx: func() sdktypes.Context {
				// BlockGasLimit reads consensus Block.MaxGas, not ctx.BlockGasMeter (see ante/types/block.go).
				base := unitNetwork.GetContext()
				cp := base.ConsensusParams()
				// Shallow copy of ConsensusParams still aliases cp.Block; copy Block before mutating MaxGas.
				block := cmtproto.BlockParams{}
				if cp.Block != nil {
					block = *cp.Block
				}
				block.MaxGas = int64(commonGasLimit - 10000) //nolint:gosec // G115: test fixture; commonGasLimit is 100_000
				cp.Block = &block
				return base.WithConsensusParams(cp)
			},
			isLondon: true,
		},
		{
			name:          "success: gasWanted is less than blockGasLimit and basefee param is disabled",
			expectedError: nil,
			getCtx: func() sdktypes.Context {
				// Set basefee param to false
				feeMarketParams, err := grpcHandler.GetFeeMarketParams()
				s.Require().NoError(err)

				feeMarketParams.Params.NoBaseFee = true
				err = utils.UpdateFeeMarketParams(utils.UpdateParamsInput{
					Tf:      txFactory,
					Network: unitNetwork,
					Pk:      keyring.GetPrivKey(0),
					Params:  feeMarketParams.Params,
				})
				s.Require().NoError(err, "expected no error when updating fee market params")

				blockMeter := storetypes.NewGasMeter(commonGasLimit + 10_000)
				return unitNetwork.GetContext().WithBlockGasMeter(blockMeter)
			},
			isLondon: true,
		},
	}

	for _, tc := range testCases {
		s.Run(fmt.Sprintf("%v_%v_%v", evmtypes.GetTxTypeName(s.EthTxType), s.ChainID, tc.name), func() {
			sender := keyring.GetKey(0)
			txArgs, err := txFactory.GenerateDefaultTxTypeArgs(
				sender.Addr,
				s.EthTxType,
			)
			s.Require().NoError(err)
			txArgs.GasLimit = commonGasLimit
			tx, err := txFactory.GenerateSignedEthTx(sender.Priv, txArgs)
			s.Require().NoError(err)

			ctx := tc.getCtx()
			feemarketkeeper := unitNetwork.App.GetFeeMarketKeeper()
			feemarketParam := feemarketkeeper.GetParams(ctx)
			// Function under test
			err = evm.CheckGasWanted(
				ctx,
				feemarketkeeper,
				tx,
				tc.isLondon,
				&feemarketParam,
			)

			if tc.expectedError != nil {
				s.Require().Error(err)
				s.Contains(err.Error(), tc.expectedError.Error())
			} else {
				s.Require().NoError(err)
			}

			// Start from a fresh block and ctx
			err = unitNetwork.NextBlock()
			s.Require().NoError(err)
		})
	}
}
