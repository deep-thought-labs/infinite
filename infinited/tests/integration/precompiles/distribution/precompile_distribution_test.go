package distribution

import (
	"testing"

	"github.com/stretchr/testify/suite"

	"github.com/deep-thought-labs/infinite/infinited/tests/integration"
	"github.com/deep-thought-labs/infinite/tests/integration/precompiles/distribution"
)

func TestDistributionPrecompileTestSuite(t *testing.T) {
	s := distribution.NewPrecompileTestSuite(integration.CreateEvmd)
	suite.Run(t, s)
}

func TestDistributionPrecompileIntegrationTestSuite(t *testing.T) {
	distribution.TestPrecompileIntegrationTestSuite(t, integration.CreateEvmd)
}
