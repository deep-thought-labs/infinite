package types_test

import (
	"testing"

	"github.com/stretchr/testify/require"

	"github.com/cosmos/evm/x/bank/types"

	sdk "github.com/cosmos/cosmos-sdk/types"
)

func TestMsgSetDenomMetadata_TypeURL(t *testing.T) {
	m := &types.MsgSetDenomMetadata{}
	require.Equal(t, "/cosmos.evm.bank.v1.MsgSetDenomMetadata", sdk.MsgTypeURL(m))
}
