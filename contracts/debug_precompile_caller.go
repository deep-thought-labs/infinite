package contracts

import (
	_ "embed"

	contractutils "github.com/deep-thought-labs/infinite/contracts/utils"
	evmtypes "github.com/deep-thought-labs/infinite/x/vm/types"
)

var (
	//go:embed solidity/DebugPrecompileCaller.json
	DebugPrecompileCallerJSON []byte

	// GreeterContract is the compiled Greeter contract
	DebugPrecompileCallerContract evmtypes.CompiledContract
)

func init() {
	var err error
	if DebugPrecompileCallerContract, err = contractutils.ConvertHardhatBytesToCompiledContract(
		DebugPrecompileCallerJSON,
	); err != nil {
		panic(err)
	}
}

// LoadGreeter loads the Greeter contract
func LoadDebugPrecompileCaller() (evmtypes.CompiledContract, error) {
	return DebugPrecompileCallerContract, nil
}
