package types

// GenesisState is the module genesis state (no on-chain store for this module).
type GenesisState struct{}

// DefaultGenesisState returns the default genesis state.
func DefaultGenesisState() GenesisState {
	return GenesisState{}
}

// Validate performs a stateless validation of the genesis state.
func (GenesisState) Validate() error {
	return nil
}
