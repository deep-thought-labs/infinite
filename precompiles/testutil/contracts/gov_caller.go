package contracts

import (
	contractutils "github.com/deep-thought-labs/infinite/contracts/utils"
	evmtypes "github.com/deep-thought-labs/infinite/x/vm/types"
)

func LoadGovCallerContract() (evmtypes.CompiledContract, error) {
	return contractutils.LoadContractFromJSONFile("GovCaller.json")
}
