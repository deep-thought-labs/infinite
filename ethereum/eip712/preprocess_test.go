package eip712_test

import (
	"encoding/hex"
	"os"
	"strings"
	"testing"

	"github.com/stretchr/testify/require"

	"github.com/cosmos/evm/encoding"
	evmaddress "github.com/cosmos/evm/encoding/address"
	"github.com/cosmos/evm/ethereum/eip712"
	"github.com/cosmos/evm/testutil/constants"
	utiltx "github.com/cosmos/evm/testutil/tx"
	evmtypes "github.com/cosmos/evm/x/vm/types"

	"cosmossdk.io/math"

	"github.com/cosmos/cosmos-sdk/client"
	codectypes "github.com/cosmos/cosmos-sdk/codec/types"
	"github.com/cosmos/cosmos-sdk/crypto/keyring"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/cosmos-sdk/types/bech32"
	"github.com/cosmos/cosmos-sdk/types/tx/signing"
	"github.com/cosmos/cosmos-sdk/x/auth/ante"
	banktypes "github.com/cosmos/cosmos-sdk/x/bank/types"
)

// Testing Constants
var (
	// chainID is used in EIP-712 tests.
	chainID = uint64(constants.EighteenDecimalsChainID)

	// ctx is initialized in TestMain after global bech32 prefixes match the fork (encoding.MakeConfig reads them).
	ctx client.Context

	// feePayerAddress: same 20-byte payload as upstream cosmos1 test address, re-encoded for ExampleBech32Prefix.
	feePayerAddress string
)

func init() {
	_, data, err := bech32.DecodeAndConvert("cosmos17xpfvakm2amg962yls6f84z3kell8c5lserqta")
	if err != nil {
		panic(err)
	}
	feePayerAddress, err = bech32.ConvertAndEncode(constants.ExampleBech32Prefix, data)
	if err != nil {
		panic(err)
	}
}

func TestMain(m *testing.M) {
	p := constants.ExampleBech32Prefix
	cfg := sdk.GetConfig()
	cfg.SetBech32PrefixForAccount(p, p+sdk.PrefixPublic)
	cfg.SetBech32PrefixForValidator(p+sdk.PrefixValidator+sdk.PrefixOperator, p+sdk.PrefixValidator+sdk.PrefixOperator+sdk.PrefixPublic)
	cfg.SetBech32PrefixForConsensusNode(p+sdk.PrefixValidator+sdk.PrefixConsensus, p+sdk.PrefixValidator+sdk.PrefixConsensus+sdk.PrefixPublic)
	ctx = client.Context{}.WithTxConfig(encoding.MakeConfig(chainID).TxConfig)
	os.Exit(m.Run())
}

type TestCaseStruct struct {
	txBuilder              client.TxBuilder
	expectedFeePayer       string
	expectedGas            uint64
	expectedFee            math.Int
	expectedMemo           string
	expectedMsg            string
	expectedSignatureBytes []byte
}

func TestLedgerPreprocessing(t *testing.T) {
	evmConfigurator := evmtypes.NewEVMConfigurator().
		WithEVMCoinInfo(constants.ExampleChainCoinInfo[constants.ExampleChainID])
	err := evmConfigurator.Configure()
	require.NoError(t, err)

	testCases := []TestCaseStruct{
		createBasicTestCase(t),
		createPopulatedTestCase(t),
	}

	for _, tc := range testCases {
		// Run pre-processing
		err := eip712.PreprocessLedgerTx(
			chainID,
			keyring.TypeLedger,
			tc.txBuilder,
		)

		require.NoError(t, err)

		// Verify Web3 extension matches expected
		hasExtOptsTx, ok := tc.txBuilder.(ante.HasExtensionOptionsTx)
		require.True(t, ok)
		require.True(t, len(hasExtOptsTx.GetExtensionOptions()) == 1)

		expectedExt := eip712.ExtensionOptionsWeb3Tx{
			TypedDataChainID: chainID,
			FeePayer:         feePayerAddress,
			FeePayerSig:      tc.expectedSignatureBytes,
		}

		expectedExtAny, err := codectypes.NewAnyWithValue(&expectedExt)
		require.NoError(t, err)

		actualExtAny := hasExtOptsTx.GetExtensionOptions()[0]
		require.Equal(t, expectedExtAny, actualExtAny)

		// Verify signature type matches expected
		signatures, err := tc.txBuilder.GetTx().GetSignaturesV2()
		require.NoError(t, err)
		require.Equal(t, len(signatures), 1)

		txSig := signatures[0].Data.(*signing.SingleSignatureData)
		require.Equal(t, txSig.SignMode, signing.SignMode_SIGN_MODE_LEGACY_AMINO_JSON)

		// Verify signature is blank
		require.Equal(t, len(txSig.Signature), 0)

		// Verify tx fields are unchanged
		tx := tc.txBuilder.GetTx()

		addrCodec := evmaddress.NewEvmCodec(sdk.GetConfig().GetBech32AccountAddrPrefix())

		txFeePayer, err := addrCodec.BytesToString(tx.FeePayer())
		require.NoError(t, err)

		require.Equal(t, txFeePayer, tc.expectedFeePayer)
		require.Equal(t, tx.GetGas(), tc.expectedGas)
		require.Equal(t, tx.GetFee().AmountOf(evmtypes.GetEVMCoinDenom()), tc.expectedFee)
		require.Equal(t, tx.GetMemo(), tc.expectedMemo)

		// Verify message is unchanged
		if tc.expectedMsg != "" {
			require.Equal(t, len(tx.GetMsgs()), 1)
			require.Equal(t, tx.GetMsgs()[0].String(), tc.expectedMsg)
		} else {
			require.Equal(t, len(tx.GetMsgs()), 0)
		}
	}
}

func TestBlankTxBuilder(t *testing.T) {
	txBuilder := ctx.TxConfig.NewTxBuilder()

	err := eip712.PreprocessLedgerTx(
		chainID,
		keyring.TypeLedger,
		txBuilder,
	)

	require.Error(t, err)
}

func TestNonLedgerTxBuilder(t *testing.T) {
	txBuilder := ctx.TxConfig.NewTxBuilder()

	err := eip712.PreprocessLedgerTx(
		chainID,
		keyring.TypeLocal,
		txBuilder,
	)

	require.NoError(t, err)
}

func TestInvalidChainId(t *testing.T) {
	txBuilder := ctx.TxConfig.NewTxBuilder()

	err := eip712.PreprocessLedgerTx(
		0,
		keyring.TypeLedger,
		txBuilder,
	)

	require.Error(t, err)
}

func createBasicTestCase(t *testing.T) TestCaseStruct {
	t.Helper()
	txBuilder := ctx.TxConfig.NewTxBuilder()

	feePayer, err := sdk.AccAddressFromBech32(feePayerAddress)
	require.NoError(t, err)

	txBuilder.SetFeePayer(feePayer)

	// Create signature unrelated to payload for testing
	signatureHex := strings.Repeat("01", 65)
	signatureBytes, err := hex.DecodeString(signatureHex)
	require.NoError(t, err)

	_, privKey := utiltx.NewAddrKey()
	sigsV2 := signing.SignatureV2{
		PubKey: privKey.PubKey(), // Use unrelated public key for testing
		Data: &signing.SingleSignatureData{
			SignMode:  signing.SignMode_SIGN_MODE_DIRECT,
			Signature: signatureBytes,
		},
		Sequence: 0,
	}

	err = txBuilder.SetSignatures(sigsV2)
	require.NoError(t, err)

	return TestCaseStruct{
		txBuilder:              txBuilder,
		expectedFeePayer:       feePayer.String(),
		expectedGas:            0,
		expectedFee:            math.NewInt(0),
		expectedMemo:           "",
		expectedMsg:            "",
		expectedSignatureBytes: signatureBytes,
	}
}

func createPopulatedTestCase(t *testing.T) TestCaseStruct {
	t.Helper()
	basicTestCase := createBasicTestCase(t)
	txBuilder := basicTestCase.txBuilder

	gasLimit := uint64(200000)
	memo := ""
	feeAmount := math.NewInt(2000)

	txBuilder.SetFeeAmount(sdk.NewCoins(
		sdk.NewCoin(
			evmtypes.GetEVMCoinDenom(),
			feeAmount,
		)))

	txBuilder.SetGasLimit(gasLimit)
	txBuilder.SetMemo(memo)

	toAddr := sdk.MustBech32ifyAddressBytes(constants.ExampleBech32Prefix, []byte{
		1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
	})
	msgSend := banktypes.MsgSend{
		FromAddress: feePayerAddress,
		ToAddress:   toAddr,
		Amount: sdk.NewCoins(
			sdk.NewCoin(
				evmtypes.GetEVMCoinDenom(),
				math.NewInt(10000000),
			),
		),
	}

	err := txBuilder.SetMsgs(&msgSend)
	require.NoError(t, err)

	return TestCaseStruct{
		txBuilder:              txBuilder,
		expectedFeePayer:       basicTestCase.expectedFeePayer,
		expectedGas:            gasLimit,
		expectedFee:            feeAmount,
		expectedMemo:           memo,
		expectedMsg:            msgSend.String(),
		expectedSignatureBytes: basicTestCase.expectedSignatureBytes,
	}
}
