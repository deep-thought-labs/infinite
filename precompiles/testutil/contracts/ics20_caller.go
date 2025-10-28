package contracts

import (
	contractutils "github.com/deep-thought-labs/infinite/contracts/utils"
	evmtypes "github.com/deep-thought-labs/infinite/x/vm/types"
)

func LoadIcs20CallerContract() (evmtypes.CompiledContract, error) {
	return contractutils.LoadContractFromJSONFile("ICS20Caller.json")
}
