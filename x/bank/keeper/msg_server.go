package keeper

import (
	"context"

	sdkerrors "cosmossdk.io/errors"
	sdk "github.com/cosmos/cosmos-sdk/types"
	banktypes "github.com/cosmos/cosmos-sdk/x/bank/types"
	govtypes "github.com/cosmos/cosmos-sdk/x/gov/types"

	"github.com/cosmos/evm/x/bank/types"
)

var _ types.MsgServer = (*msgServer)(nil)

// DenomMetaDataSetter is the subset of bankkeeper.Keeper used by the Msg server.
// bankkeeper.Keeper implements it; tests may pass a small fake that only stubs SetDenomMetaData.
type DenomMetaDataSetter interface {
	SetDenomMetaData(ctx context.Context, denomMetaData banktypes.Metadata)
}

type msgServer struct {
	bankKeeper DenomMetaDataSetter
	authority  sdk.AccAddress
}

// NewMsgServer returns a Msg server backed by the SDK x/bank keeper (or any DenomMetaDataSetter).
func NewMsgServer(bankKeeper DenomMetaDataSetter, authority sdk.AccAddress) types.MsgServer {
	return &msgServer{
		bankKeeper: bankKeeper,
		authority:  authority,
	}
}

// SetDenomMetadata implements MsgServer.
func (s *msgServer) SetDenomMetadata(ctx context.Context, msg *types.MsgSetDenomMetadata) (*types.MsgSetDenomMetadataResponse, error) {
	if s.authority.String() != msg.Authority {
		return nil, sdkerrors.Wrapf(govtypes.ErrInvalidSigner, "invalid authority; expected %s, got %s", s.authority, msg.Authority)
	}

	if err := msg.Metadata.Validate(); err != nil {
		return nil, err
	}

	s.bankKeeper.SetDenomMetaData(ctx, msg.Metadata)

	sdkCtx := sdk.UnwrapSDKContext(ctx)
	sdkCtx.EventManager().EmitEvent(sdk.NewEvent(
		"set_denom_metadata",
		sdk.NewAttribute("denom", msg.Metadata.Base),
		sdk.NewAttribute("name", msg.Metadata.Name),
		sdk.NewAttribute("symbol", msg.Metadata.Symbol),
	))

	return &types.MsgSetDenomMetadataResponse{}, nil
}
