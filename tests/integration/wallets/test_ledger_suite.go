package wallets

import (
	"encoding/hex"
	"fmt"
	"regexp"

	"github.com/stretchr/testify/suite"

	"github.com/cosmos/evm/testutil/constants"
	"github.com/cosmos/evm/testutil/integration/evm/network"
	"github.com/cosmos/evm/wallets/ledger"
	"github.com/cosmos/evm/wallets/ledger/mocks"
	"github.com/cosmos/evm/wallets/usbwallet"

	"cosmossdk.io/math"

	"github.com/cosmos/cosmos-sdk/codec"
	codectypes "github.com/cosmos/cosmos-sdk/codec/types"
	"github.com/cosmos/cosmos-sdk/crypto/keys/ed25519"
	cryptotypes "github.com/cosmos/cosmos-sdk/crypto/types"
	sdk "github.com/cosmos/cosmos-sdk/types"
	sdkbech32 "github.com/cosmos/cosmos-sdk/types/bech32"
	txTypes "github.com/cosmos/cosmos-sdk/types/tx"
	"github.com/cosmos/cosmos-sdk/types/tx/signing"
	"github.com/cosmos/cosmos-sdk/x/auth/tx"
	banktypes "github.com/cosmos/cosmos-sdk/x/bank/types"
)

type LedgerTestSuite struct {
	suite.Suite
	txAmino    []byte
	txProtobuf []byte
	ledger     ledger.CosmosEVMSECP256K1
	mockWallet *mocks.Wallet
	hrp        string

	create  network.CreateEvmApp
	options []network.ConfigOption
}

func NewLedgerTestSuite(create network.CreateEvmApp, options ...network.ConfigOption) *LedgerTestSuite {
	return &LedgerTestSuite{
		create:  create,
		options: options,
	}
}

func (suite *LedgerTestSuite) SetupTest() {
	// Load encoding config for sign doc encoding/decoding
	// This is done on app instantiation.
	// We use the testutil network to load the encoding config
	network.New(suite.create, suite.options...)

	suite.hrp = sdk.GetConfig().GetBech32AccountAddrPrefix()

	suite.txAmino = suite.getMockTxAmino()
	suite.txProtobuf = suite.getMockTxProtobuf()

	hub, err := usbwallet.NewLedgerHub()
	suite.Require().NoError(err)

	mockWallet := new(mocks.Wallet)
	suite.mockWallet = mockWallet
	suite.ledger = ledger.CosmosEVMSECP256K1{Hub: hub, PrimaryWallet: mockWallet}
}

func (suite *LedgerTestSuite) newPubKey(pk string) (res cryptotypes.PubKey) {
	pkBytes, err := hex.DecodeString(pk)
	suite.Require().NoError(err)

	pubkey := &ed25519.PubKey{Key: pkBytes}

	return pubkey
}

// accAddrFromCosmosRef decodes a reference cosmos-prefixed bech32; AccAddress.String() uses the
// process-global HRP (e.g. infinite on fork chains).
func (suite *LedgerTestSuite) accAddrFromCosmosRef(cosmosBech32 string) sdk.AccAddress {
	_, bz, err := sdkbech32.DecodeAndConvert(cosmosBech32)
	suite.Require().NoError(err)
	return sdk.AccAddress(bz)
}

func (suite *LedgerTestSuite) getMockTxAmino() []byte {
	whitespaceRegex := regexp.MustCompile(`\s+`)
	// Valid cosmos bech32 (same raw pair as getMockTxProtobuf).
	fromAddr := suite.accAddrFromCosmosRef("cosmos1r5sckdd808qvg7p8d0auaw896zcluqfd7djffp").String()
	toAddr := suite.accAddrFromCosmosRef("cosmos10t8ca2w09ykd6ph0agdz5stvgau47whhaggl9a").String()
	tmp := whitespaceRegex.ReplaceAllString(fmt.Sprintf(
		`{
			"account_number": "0",
			"chain_id":"%s",
			"fee":{
				"amount":[{"amount":"150","denom":"atom"}],
				"gas":"20000"
			},
			"memo":"memo",
			"msgs":[{
				"type":"cosmos-sdk/MsgSend",
				"value":{
					"amount":[{"amount":"150","denom":"atom"}],
					"from_address":"%s",
					"to_address":"%s"
				}
			}],
			"sequence":"6"
		}`, constants.ExampleChainID.ChainID, fromAddr, toAddr),
		"",
	)

	return []byte(tmp)
}

func (suite *LedgerTestSuite) getMockTxProtobuf() []byte {
	marshaler := codec.NewProtoCodec(codectypes.NewInterfaceRegistry())

	memo := "memo"
	msg := banktypes.NewMsgSend(
		suite.accAddrFromCosmosRef("cosmos1r5sckdd808qvg7p8d0auaw896zcluqfd7djffp"),
		suite.accAddrFromCosmosRef("cosmos10t8ca2w09ykd6ph0agdz5stvgau47whhaggl9a"),
		[]sdk.Coin{
			{
				Denom:  "atom",
				Amount: math.NewIntFromUint64(150),
			},
		},
	)

	msgAsAny, err := codectypes.NewAnyWithValue(msg)
	suite.Require().NoError(err)

	body := &txTypes.TxBody{
		Messages: []*codectypes.Any{
			msgAsAny,
		},
		Memo: memo,
	}

	pubKey := suite.newPubKey("0B485CFC0EECC619440448436F8FC9DF40566F2369E72400281454CB552AFB50")

	pubKeyAsAny, err := codectypes.NewAnyWithValue(pubKey)
	suite.Require().NoError(err)

	signingMode := txTypes.ModeInfo_Single_{
		Single: &txTypes.ModeInfo_Single{
			Mode: signing.SignMode_SIGN_MODE_DIRECT,
		},
	}

	signerInfo := &txTypes.SignerInfo{
		PublicKey: pubKeyAsAny,
		ModeInfo: &txTypes.ModeInfo{
			Sum: &signingMode,
		},
		Sequence: 6,
	}

	fee := txTypes.Fee{Amount: sdk.NewCoins(sdk.NewInt64Coin("atom", 150)), GasLimit: 20000}

	authInfo := &txTypes.AuthInfo{
		SignerInfos: []*txTypes.SignerInfo{signerInfo},
		Fee:         &fee,
	}

	bodyBytes := marshaler.MustMarshal(body)
	authInfoBytes := marshaler.MustMarshal(authInfo)

	signBytes, err := tx.DirectSignBytes(
		bodyBytes,
		authInfoBytes,
		constants.ExampleChainID.ChainID,
		0,
	)
	suite.Require().NoError(err)

	return signBytes
}
