package keeper_test

import (
	"context"
	"testing"

	storetypes "cosmossdk.io/store/types"
	"github.com/stretchr/testify/require"

	"github.com/cosmos/cosmos-sdk/testutil"
	sdk "github.com/cosmos/cosmos-sdk/types"
	authtypes "github.com/cosmos/cosmos-sdk/x/auth/types"
	banktypes "github.com/cosmos/cosmos-sdk/x/bank/types"
	govtypes "github.com/cosmos/cosmos-sdk/x/gov/types"

	"github.com/cosmos/evm/x/bank/keeper"
	evmbanktypes "github.com/cosmos/evm/x/bank/types"
)

type recordingBank struct {
	setCalls []banktypes.Metadata
}

func (r *recordingBank) SetDenomMetaData(ctx context.Context, md banktypes.Metadata) {
	r.setCalls = append(r.setCalls, md)
}

func validMetadata() banktypes.Metadata {
	return banktypes.Metadata{
		Description: "test",
		DenomUnits: []*banktypes.DenomUnit{
			{Denom: "ufoo", Exponent: 0},
			{Denom: "FOO", Exponent: 6},
		},
		Base:    "ufoo",
		Display: "FOO",
		Name:    "Foo",
		Symbol:  "FOO",
	}
}

func wrapFreshCtx(t *testing.T) context.Context {
	t.Helper()
	key := storetypes.NewKVStoreKey("bank_ext_test")
	tkey := storetypes.NewTransientStoreKey("bank_ext_test_t")
	ctx := testutil.DefaultContext(key, tkey).WithEventManager(sdk.NewEventManager())
	return sdk.WrapSDKContext(ctx)
}

func TestMsgServer_SetDenomMetadata_Authority(t *testing.T) {
	authority := authtypes.NewModuleAddress(govtypes.ModuleName)
	otherAddr := authtypes.NewModuleAddress("other")

	bank := &recordingBank{}
	srv := keeper.NewMsgServer(bank, authority)
	_, err := srv.SetDenomMetadata(wrapFreshCtx(t), &evmbanktypes.MsgSetDenomMetadata{
		Authority: otherAddr.String(),
		Metadata:  validMetadata(),
	})
	require.Error(t, err)
	require.ErrorIs(t, err, govtypes.ErrInvalidSigner)
	require.Empty(t, bank.setCalls)
}

func TestMsgServer_SetDenomMetadata_InvalidMetadata(t *testing.T) {
	authority := authtypes.NewModuleAddress(govtypes.ModuleName)
	bank := &recordingBank{}
	srv := keeper.NewMsgServer(bank, authority)
	_, err := srv.SetDenomMetadata(wrapFreshCtx(t), &evmbanktypes.MsgSetDenomMetadata{
		Authority: authority.String(),
		Metadata: banktypes.Metadata{
			Name:   "",
			Symbol: "X",
			Base:   "ufoo",
		},
	})
	require.Error(t, err)
	require.Contains(t, err.Error(), "name field cannot be blank")
	require.Empty(t, bank.setCalls)
}

func TestMsgServer_SetDenomMetadata_Success(t *testing.T) {
	authority := authtypes.NewModuleAddress(govtypes.ModuleName)
	bank := &recordingBank{}
	srv := keeper.NewMsgServer(bank, authority)
	md := validMetadata()
	goCtx := wrapFreshCtx(t)
	_, err := srv.SetDenomMetadata(goCtx, &evmbanktypes.MsgSetDenomMetadata{
		Authority: authority.String(),
		Metadata:  md,
	})
	require.NoError(t, err)
	require.Len(t, bank.setCalls, 1)
	require.Equal(t, md, bank.setCalls[0])

	events := sdk.UnwrapSDKContext(goCtx).EventManager().Events()
	require.NotEmpty(t, events)
	require.Equal(t, "set_denom_metadata", events[len(events)-1].Type)
	attrs := events[len(events)-1].Attributes
	require.Len(t, attrs, 3)
	require.Equal(t, "denom", string(attrs[0].Key))
	require.Equal(t, md.Base, string(attrs[0].Value))
	require.Equal(t, "name", string(attrs[1].Key))
	require.Equal(t, md.Name, string(attrs[1].Value))
	require.Equal(t, "symbol", string(attrs[2].Key))
	require.Equal(t, md.Symbol, string(attrs[2].Value))
}
