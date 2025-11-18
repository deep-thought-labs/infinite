package main

import (
	"crypto/sha256"
	"fmt"
	"os"
	"github.com/cosmos/cosmos-sdk/types/bech32"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintf(os.Stderr, "Usage: %s <module_name>\n", os.Args[0])
		os.Exit(1)
	}
	name := os.Args[1]
	hash := sha256.Sum256([]byte(name))
	addrBytes := hash[:20]
	bech32Addr, err := bech32.ConvertAndEncode("infinite", addrBytes)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error encoding bech32 address: %v\n", err)
		os.Exit(1)
	}
	fmt.Println(bech32Addr)
}