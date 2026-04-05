package keeper

import (
	"context"

	sdkerrors "cosmossdk.io/errors"
	sdk "github.com/cosmos/cosmos-sdk/types"
	bankkeeper "github.com/cosmos/cosmos-sdk/x/bank/keeper"
	govtypes "github.com/cosmos/cosmos-sdk/x/gov/types"

	"github.com/cosmos/evm/x/bank/types"
)

var _ types.MsgServer = (*msgServer)(nil)

type msgServer struct {
	bankKeeper bankkeeper.Keeper
	authority  sdk.AccAddress
}

// NewMsgServer returns a Msg server backed by the SDK x/bank keeper.
func NewMsgServer(bankKeeper bankkeeper.Keeper, authority sdk.AccAddress) types.MsgServer {
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
