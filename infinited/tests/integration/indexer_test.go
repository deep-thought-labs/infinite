package integration

import (
	"testing"

	"github.com/deep-thought-labs/infinite/tests/integration/indexer"
)

func TestKVIndexer(t *testing.T) {
	indexer.TestKVIndexer(t, CreateEvmd)
}
