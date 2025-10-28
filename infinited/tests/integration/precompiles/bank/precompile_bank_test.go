package bank

import (
	"testing"

	"github.com/stretchr/testify/suite"

	"github.com/deep-thought-labs/infinite/infinited/tests/integration"
	"github.com/deep-thought-labs/infinite/tests/integration/precompiles/bank"
)

func TestBankPrecompileTestSuite(t *testing.T) {
	s := bank.NewPrecompileTestSuite(integration.CreateEvmd)
	suite.Run(t, s)
}

func TestBankPrecompileIntegrationTestSuite(t *testing.T) {
	bank.TestIntegrationSuite(t, integration.CreateEvmd)
}
