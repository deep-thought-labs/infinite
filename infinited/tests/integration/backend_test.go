package integration

import (
	"testing"

	"github.com/stretchr/testify/suite"

	"github.com/deep-thought-labs/infinite/tests/integration/rpc/backend"
)

func TestBackend(t *testing.T) {
	s := backend.NewTestSuite(CreateEvmd)
	suite.Run(t, s)
}
