package mempool

import (
	"testing"

	"github.com/cosmos/evm/infinited/tests/integration"

	"github.com/stretchr/testify/suite"

	evmnetwork "github.com/cosmos/evm/testutil/integration/evm/network"
	"github.com/cosmos/evm/tests/integration/mempool"
)

func TestMempoolIntegrationTestSuite(t *testing.T) {
	suite.Run(t, mempool.NewMempoolIntegrationTestSuite(integration.CreateEvmd))
}

func TestKrakatoaMempoolIntegrationTestSuite(t *testing.T) {
	suite.Run(t, mempool.NewMempoolIntegrationTestSuite(integration.CreateEvmd, evmnetwork.WithExclusiveMempool()))
}
