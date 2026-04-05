package types_test

import (
	"testing"

	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/stretchr/testify/require"

	"github.com/cosmos/evm/x/bank/types"
)

func TestMsgSetDenomMetadata_TypeURL(t *testing.T) {
	m := &types.MsgSetDenomMetadata{}
	require.Equal(t, "/cosmos.evm.bank.v1.MsgSetDenomMetadata", sdk.MsgTypeURL(m))
}
