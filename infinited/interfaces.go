package evmd

import (
	cmn "github.com/deep-thought-labs/infinite/precompiles/common"
	evmtypes "github.com/deep-thought-labs/infinite/x/vm/types"
)

type BankKeeper interface {
	evmtypes.BankKeeper
	cmn.BankKeeper
}
