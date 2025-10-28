package mempool

import (
	"testing"

	"github.com/deep-thought-labs/infinite/infinited/tests/integration"

	"github.com/stretchr/testify/suite"

	"github.com/deep-thought-labs/infinite/tests/integration/mempool"
)

func TestMempoolIntegrationTestSuite(t *testing.T) {
	suite.Run(t, mempool.NewMempoolIntegrationTestSuite(integration.CreateEvmd))
}
