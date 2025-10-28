package ante

import (
	"testing"

	"github.com/stretchr/testify/suite"

	"github.com/deep-thought-labs/infinite/infinited/tests/integration"
	"github.com/deep-thought-labs/infinite/tests/integration/ante"
)

func TestEvmUnitAnteTestSuite(t *testing.T) {
	suite.Run(t, ante.NewEvmUnitAnteTestSuite(integration.CreateEvmd))
}
