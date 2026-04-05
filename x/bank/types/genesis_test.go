package types_test

import (
	"testing"

	"github.com/stretchr/testify/require"

	"github.com/cosmos/evm/x/bank/types"
)

func TestGenesis_DefaultAndValidate(t *testing.T) {
	gs := types.DefaultGenesisState()
	require.NoError(t, gs.Validate())
}
