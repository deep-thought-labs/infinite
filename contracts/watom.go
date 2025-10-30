package contracts

import (
	contractutils "github.com/deep-thought-labs/infinite/contracts/utils"
	evmtypes "github.com/deep-thought-labs/infinite/x/vm/types"

	_ "embed"
)

var (
	// WATOMJSON are the compiled bytes of the WATOMContract
	//
	//go:embed solidity/WATOM.json
	WATOMJSON []byte

	// WATOMContract is the compiled watom contract
	WATOMContract evmtypes.CompiledContract
)

func init() {
	var err error
	if WATOMContract, err = contractutils.ConvertHardhatBytesToCompiledContract(
		WATOMJSON,
	); err != nil {
		panic(err)
	}
}
