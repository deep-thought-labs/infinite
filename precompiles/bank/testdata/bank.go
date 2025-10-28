package testdata

import (
	contractutils "github.com/deep-thought-labs/infinite/contracts/utils"
	evmtypes "github.com/deep-thought-labs/infinite/x/vm/types"
)

func LoadBankCallerContract() (evmtypes.CompiledContract, error) {
	return contractutils.LoadContractFromJSONFile("BankCaller.json")
}
