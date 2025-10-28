package contracts

import (
	contractutils "github.com/deep-thought-labs/infinite/contracts/utils"
	evmtypes "github.com/deep-thought-labs/infinite/x/vm/types"
)

func LoadERC20RecursiveNonReverting() (evmtypes.CompiledContract, error) {
	return contractutils.LoadContractFromJSONFile("solidity/ERC20RecursiveNonRevertingPrecompileCall.json")
}
