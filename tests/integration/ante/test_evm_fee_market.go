package ante

import (
	"math/big"

	"github.com/cosmos/evm/ante/evm"
	"github.com/cosmos/evm/ante/types"
	"github.com/cosmos/evm/server/config"
	"github.com/cosmos/evm/testutil"
	testconstants "github.com/cosmos/evm/testutil/constants"
	utiltx "github.com/cosmos/evm/testutil/tx"
	evmtypes "github.com/cosmos/evm/x/vm/types"
	ethtypes "github.com/ethereum/go-ethereum/core/types"

	sdkmath "cosmossdk.io/math"

	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/cosmos-sdk/types/bech32"
	banktypes "github.com/cosmos/cosmos-sdk/x/bank/types"
)

func reencodeBech32ToPrefix(hrp, address string) string {
	_, data, err := bech32.DecodeAndConvert(address)
	if err != nil {
		panic(err)
	}
	out, err := bech32.ConvertAndEncode(hrp, data)
	if err != nil {
		panic(err)
	}
	return out
}

func (s *EvmAnteTestSuite) TestGasWantedDecorator() {
	s.WithFeemarketEnabled(true)
	s.SetupTest()
	ctx := s.GetNetwork().GetContext()
	feeMarketKeeper := s.GetNetwork().App.GetFeeMarketKeeper()
	params := feeMarketKeeper.GetParams(ctx)
	dec := evm.NewGasWantedDecorator(s.GetNetwork().App.GetEVMKeeper(), feeMarketKeeper, &params)
	from, fromPrivKey := utiltx.NewAddrKey()
	to := utiltx.GenerateAddress()
	denom := evmtypes.GetEVMCoinDenom()
	accFrom := reencodeBech32ToPrefix(testconstants.ExampleBech32Prefix, "cosmos1x8fhpj9nmhqk8z9kpgjt95ck2xwyue0ptzkucp")
	accTo := reencodeBech32ToPrefix(testconstants.ExampleBech32Prefix, "cosmos1dx67l23hz9l0k9hcher8xz04uj7wf3yu26l2yn")

	testCases := []struct {
		name     string
		malleate func() sdk.Tx
		expPass  bool
	}{
		{
			"Cosmos Tx",
			func() sdk.Tx {
				testMsg := banktypes.MsgSend{
					FromAddress: accFrom,
					ToAddress:   accTo,
					Amount:      sdk.Coins{sdk.Coin{Amount: sdkmath.NewInt(10), Denom: denom}},
				}
				txBuilder := s.CreateTestCosmosTxBuilder(sdkmath.NewInt(10), denom, &testMsg)
				return txBuilder.GetTx()
			},
			true,
		},
		{
			"Ethereum Legacy Tx",
			func() sdk.Tx {
				txArgs := evmtypes.EvmTxArgs{
					To:       &to,
					GasPrice: big.NewInt(0),
					GasLimit: TestGasLimit,
				}
				return s.CreateTxBuilder(fromPrivKey, txArgs).GetTx()
			},
			true,
		},
		{
			"Ethereum Access List Tx",
			func() sdk.Tx {
				emptyAccessList := ethtypes.AccessList{}
				txArgs := evmtypes.EvmTxArgs{
					To:       &to,
					GasPrice: big.NewInt(0),
					GasLimit: TestGasLimit,
					Accesses: &emptyAccessList,
				}
				return s.CreateTxBuilder(fromPrivKey, txArgs).GetTx()
			},
			true,
		},
		{
			"Ethereum Dynamic Fee Tx (EIP1559)",
			func() sdk.Tx {
				emptyAccessList := ethtypes.AccessList{}
				txArgs := evmtypes.EvmTxArgs{
					To:        &to,
					GasPrice:  big.NewInt(0),
					GasFeeCap: big.NewInt(100),
					GasLimit:  TestGasLimit,
					GasTipCap: big.NewInt(50),
					Accesses:  &emptyAccessList,
				}
				return s.CreateTxBuilder(fromPrivKey, txArgs).GetTx()
			},
			true,
		},
		{
			"EIP712 message",
			func() sdk.Tx {
				amount := sdk.NewCoins(sdk.NewCoin(testconstants.ExampleAttoDenom, sdkmath.NewInt(20)))
				gas := uint64(200000)
				acc := s.GetNetwork().App.GetAccountKeeper().NewAccountWithAddress(ctx, from.Bytes())
				s.Require().NoError(acc.SetSequence(1))
				s.GetNetwork().App.GetAccountKeeper().SetAccount(ctx, acc)
				builder, err := s.CreateTestEIP712TxBuilderMsgSend(acc.GetAddress(), fromPrivKey, ctx.ChainID(), config.DefaultEVMChainID, gas, amount)
				s.Require().NoError(err)
				return builder.GetTx()
			},
			true,
		},
		{
			"Cosmos Tx - gasWanted > max block gas",
			func() sdk.Tx {
				denom := testconstants.ExampleAttoDenom
				testMsg := banktypes.MsgSend{
					FromAddress: accFrom,
					ToAddress:   accTo,
					Amount:      sdk.Coins{sdk.Coin{Amount: sdkmath.NewInt(10), Denom: denom}},
				}
				txBuilder := s.CreateTestCosmosTxBuilder(sdkmath.NewInt(10), testconstants.ExampleAttoDenom, &testMsg)
				limit := types.BlockGasLimit(ctx)
				txBuilder.SetGasLimit(limit + 5)
				return txBuilder.GetTx()
			},
			false,
		},
	}

	for _, tc := range testCases {
		s.Run(tc.name, func() {
			_, err := dec.AnteHandle(ctx, tc.malleate(), false, testutil.NoOpNextFn)
			if tc.expPass {
				s.Require().NoError(err)
			} else {
				// TODO: check for specific error message
				s.Require().Error(err)
			}
		})
	}
}
